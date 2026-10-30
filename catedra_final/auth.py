"""Autenticación local con usuarios SQL, claves derivadas y sesiones HttpOnly."""
import hashlib
import re
import secrets
import threading
import time
from http.cookies import SimpleCookie

ROLE_USERS = {'gerencia': 'demo_gerencia', 'cajero': 'demo_cajero', 'inventario': 'demo_inventario'}
PAGES = {'gerencia': ['home','pos','inventory','sales','clients','reports','database','users'],
         'cajero': ['pos','sales','clients'], 'inventario': ['inventory']}
WRITES = {'/api/sales': {'gerencia','cajero'}, '/api/clients': {'gerencia','cajero'},
          '/api/inventory': {'gerencia','inventario'}, '/api/price': {'gerencia','inventario'},
          '/api/sales/cancel': {'gerencia'}}
SESSIONS = {}
ATTEMPTS = {}
LOCK = threading.Lock()
TTL = 8 * 60 * 60


def public(row):
    return dict(zip(('id','username','name','role','active'), row))


def password_hash(password, salt):
    return hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 600000).hex()


def password_fields(password):
    if not isinstance(password, str) or not 10 <= len(password) <= 128 or not password.strip():
        raise ValueError('La contraseña debe tener entre 10 y 128 caracteres.')
    salt = secrets.token_hex(32)
    return password_hash(password, salt), salt


def add_user(cur, data, bootstrap=False):
    username = str(data.get('username','')).strip().lower()
    name = str(data.get('name','')).strip()
    role = 'gerencia' if bootstrap else data.get('role')
    if not re.fullmatch(r'[a-z0-9_.-]{3,40}', username):
        raise ValueError('Usuario: usa de 3 a 40 letras minúsculas, números, punto, guion o guion bajo.')
    if not name or len(name) > 100 or role not in ROLE_USERS:
        raise ValueError('Ingresa un nombre válido y selecciona un rol.')
    digest, salt = password_fields(data.get('password'))
    cur.execute('SELECT COUNT(*) FROM dbo.UsuariosApp WITH (UPDLOCK,HOLDLOCK)')
    count = cur.fetchone()[0]
    if bootstrap and count:
        raise PermissionError('La cuenta inicial ya fue creada. Inicia sesión.')
    cur.execute('SELECT 1 FROM dbo.UsuariosApp WHERE Usuario=?', username)
    if cur.fetchone():
        raise ValueError('Ese nombre de usuario ya está registrado.')
    cur.execute('INSERT dbo.UsuariosApp(Usuario,Nombre,Rol,ClaveHash,Sal) OUTPUT inserted.IdUsuario VALUES(?,?,?,?,?)', username,name,role,digest,salt)
    return {'id':cur.fetchone()[0], 'username':username,'name':name,'role':role,'active':True}


def verify(cur, username, password):
    cur.execute('SELECT IdUsuario,Usuario,Nombre,Rol,Activo,ClaveHash,Sal FROM dbo.UsuariosApp WHERE Usuario=?', username.strip().lower())
    row = cur.fetchone()
    # Perform the same expensive operation when the account does not exist.
    digest = password_hash(password, row[6] if row else '00' * 32)
    if not row or not row[4] or not secrets.compare_digest(digest, row[5]):
        raise PermissionError('Usuario o contraseña incorrectos.')
    return public(row[:5])


def issue(user):
    sid = secrets.token_urlsafe(32)
    session = {'user_id':user['id'],'expires':time.monotonic()+TTL,'csrf':secrets.token_urlsafe(32)}
    with LOCK:
        expired = [k for k,v in SESSIONS.items() if v['expires'] < time.monotonic()]
        for k in expired:
            SESSIONS.pop(k, None)
        SESSIONS[sid] = session
    return sid, session


def session_cookie(headers):
    try:
        cookie = SimpleCookie(headers.get('Cookie',''))
        return cookie['buen_dia_session'].value if 'buen_dia_session' in cookie else None
    except Exception:
        return None


def resolve(headers, connect):
    sid = session_cookie(headers)
    with LOCK:
        session = SESSIONS.get(sid)
        if not session or session['expires'] < time.monotonic():
            SESSIONS.pop(sid, None)
            return None
        session = session.copy()
    cn = connect()
    try:
        cur = cn.cursor()
        cur.execute('SELECT IdUsuario,Usuario,Nombre,Rol,Activo FROM dbo.UsuariosApp WHERE IdUsuario=?', session['user_id'])
        row = cur.fetchone()
        if not row or not row[4]:
            return None
        session['user'] = public(row)
        return session
    finally:
        cn.close()


def revoke(user_id):
    with LOCK:
        for sid in [k for k,v in SESSIONS.items() if v['user_id'] == user_id]:
            SESSIONS.pop(sid, None)


def check_attempt(ip, username):
    key = (ip, username.lower())
    now = time.monotonic()
    with LOCK:
        for k in [k for k,v in ATTEMPTS.items() if now-v[-1] > 300]:
            ATTEMPTS.pop(k,None)
        recent = [v for v in ATTEMPTS.get(key,[]) if now-v < 300]
        ip_recent = [v for (addr,_),values in ATTEMPTS.items() if addr==ip for v in values if now-v < 300]
        if len(recent) >= 5 or len(ip_recent) >= 30:
            raise PermissionError('Demasiados intentos. Espera cinco minutos e inténtalo de nuevo.')
        ATTEMPTS[key] = recent+[now]


def impersonate(cur, role):
    # Static allowlist: no user-supplied SQL identifier is interpolated.
    cur.execute("EXECUTE AS USER = '" + ROLE_USERS[role] + "'")
