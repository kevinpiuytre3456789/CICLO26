"""Buen Día: aplicación local para la base existente BuenPan_ASB404."""
import argparse
import datetime
import decimal
import json
import os
from pathlib import Path
import secrets
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading
import webbrowser
import auth

ROOT = Path(__file__).resolve().parent
TOKEN = secrets.token_urlsafe(32)


def connect():
    import pyodbc
    pyodbc.pooling = False  # Never reuse an impersonated SQL session for another role.
    config = json.loads((ROOT / 'config.example.json').read_text('utf-8'))
    local = ROOT / 'config.local.json'
    if local.exists():
        config.update(json.loads(local.read_text('utf-8')))
    def value(v):
        return '{' + str(v).replace('}', '}}') + '}'
    parts = [f'DRIVER={value(config["driver"])}',
             f'SERVER={value(os.getenv("DB_SERVER", config["server"]))}',
             f'DATABASE={value(os.getenv("DB_NAME", config["database"]))}',
             'Encrypt=' + ('yes' if config['encrypt'] else 'no'),
             'TrustServerCertificate=' + ('yes' if config['trust_server_certificate'] else 'no')]
    if config.get('trusted_connection', True):
        parts.append('Trusted_Connection=yes')
    else:
        parts.extend(['UID=' + value(os.environ['DB_USER']), 'PWD=' + value(os.environ['DB_PASSWORD'])])
    return pyodbc.connect(';'.join(parts), timeout=5, autocommit=False)


def rows(cursor, query, *params):
    cursor.execute(query, *params)
    names = [col[0] for col in cursor.description]
    return [dict(zip(names, row)) for row in cursor.fetchall()]


def integer(data, key, nullable=False):
    v = data.get(key)
    if nullable and (v is None or v == ''):
        return None
    if isinstance(v, bool) or not str(v).isdigit() or not 0 < int(v) <= 2147483647:
        raise ValueError(f'{key}: ingresa un número entero mayor que cero.')
    return int(v)


def amount(data, key):
    try:
        v = decimal.Decimal(str(data.get(key)))
        if not v.is_finite() or v <= 0 or v > decimal.Decimal('9999999999.99') or v.as_tuple().exponent < -2:
            raise ValueError()
        return v
    except (decimal.InvalidOperation, ValueError):
        raise ValueError(f'{key}: ingresa un monto positivo con hasta dos decimales.')


def text_field(data, key, limit, optional=False):
    v = str(data.get(key) or '').strip()
    if (not optional and not v) or len(v) > limit:
        raise ValueError(f'{key}: campo requerido, máximo {limit} caracteres.')
    return v or None


def snapshot(cur, role='gerencia'):
    # Each role reads only the data needed for its authorized screens.
    queries = {
        'products': ('SELECT * FROM dbo.vw_CatalogoProductos ORDER BY Producto', {'gerencia','cajero','inventario'}),
        'clients': ('SELECT * FROM dbo.vw_AppClientes ORDER BY Nombres', {'gerencia','cajero'}),
        'employees': ('SELECT * FROM dbo.vw_AppEmpleados ORDER BY Nombres', {'gerencia','cajero'}),
        'sales': ('SELECT TOP (100) * FROM dbo.vw_AppVentas ORDER BY IdVenta DESC', {'gerencia','cajero'}),
        'daily': ('SELECT TOP (14) * FROM dbo.vw_ResumenVentasDiarias ORDER BY Fecha DESC', {'gerencia'}),
        'top': ('SELECT TOP (6) * FROM dbo.vw_TopProductos ORDER BY UnidadesVendidas DESC', {'gerencia'}),
        'movements': ('SELECT TOP (100) * FROM dbo.vw_MovimientosInventario ORDER BY IdMovimiento DESC', {'gerencia','inventario'}),
        'profit': ('SELECT * FROM dbo.vw_RentabilidadProductos ORDER BY Producto', {'gerencia'}),
        'critical': ('SELECT * FROM dbo.vw_StockCritico ORDER BY Stock,Producto', {'gerencia','inventario'}),
        'frequent': ('SELECT * FROM dbo.vw_ClientesFrecuentes ORDER BY TotalComprado DESC', {'gerencia'}),
        'audit': ('SELECT TOP (100) * FROM dbo.vw_AppAuditoria ORDER BY IdAuditoria DESC', {'gerencia'}),
        'objects': ("SELECT name Nombre,RTRIM(type) Tipo,is_disabled Deshabilitado FROM sys.triggers WHERE parent_class=1 AND is_ms_shipped=0 UNION ALL SELECT name,RTRIM(type),CONVERT(bit,0) FROM sys.objects WHERE schema_id=SCHEMA_ID('dbo') AND type IN ('P','V') AND is_ms_shipped=0 ORDER BY Tipo,Nombre", {'gerencia'}),
        'today': ('SELECT * FROM dbo.vw_ResumenVentasDiarias WHERE Fecha=CONVERT(date,SYSDATETIME())', {'gerencia'}),
    }
    return {key: rows(cur, query) if role in roles else [] for key,(query,roles) in queries.items()}


def mutate(cur, path, data):
    if path == '/api/sales':
        employee = integer(data, 'IdEmpleado')
        client = integer(data, 'IdCliente', True)
        items = data.get('items')
        if not isinstance(items, list) or not 1 <= len(items) <= 100:
            raise ValueError('Agrega entre 1 y 100 productos.')
        parsed = [(integer(i, 'IdProducto'), integer(i, 'Cantidad')) for i in items if isinstance(i, dict)]
        if len(parsed) != len(items) or len({p for p, q in parsed}) != len(parsed):
            raise ValueError('El carrito contiene productos inválidos o repetidos.')
        p, q = parsed[0]
        cur.execute('DECLARE @id int; EXEC dbo.usp_RegistrarVenta @IdCliente=?,@IdEmpleado=?,@IdProducto=?,@Cantidad=?,@IdVenta=@id OUTPUT; SELECT @id AS IdVenta;', client, employee, p, q)
        while cur.description is None:
            if not cur.nextset():
                raise RuntimeError('No se recibió el identificador de venta.')
        sale_id = cur.fetchone()[0]
        for p, q in parsed[1:]:
            cur.execute('EXEC dbo.usp_AgregarProductoVenta @IdVenta=?,@IdProducto=?,@Cantidad=?', sale_id, p, q)
        cur.execute('EXEC dbo.usp_ConfirmarVenta @IdVenta=?', sale_id)
        return rows(cur, 'SELECT IdVenta,Subtotal,IVA,Total,Estado FROM dbo.vw_AppVentas WHERE IdVenta=?', sale_id)[0]
    if path == '/api/sales/cancel':
        cur.execute('EXEC dbo.usp_AnularVenta @IdVenta=?', integer(data, 'IdVenta'))
    elif path == '/api/inventory':
        cost = data.get('CostoUnitario')
        if cost is not None and cost != '':
            try:
                cost = decimal.Decimal(str(cost))
                if not cost.is_finite() or cost < 0 or cost > decimal.Decimal('9999999999.99') or cost.as_tuple().exponent < -2:
                    raise ValueError()
            except (ValueError, decimal.InvalidOperation):
                raise ValueError('El costo debe ser cero o mayor, con hasta dos decimales.')
        else:
            cost = None
        cur.execute('EXEC dbo.usp_RegistrarEntradaInventario @IdProducto=?,@Cantidad=?,@CostoUnitario=?', integer(data, 'IdProducto'), integer(data, 'Cantidad'), cost)
    elif path == '/api/price':
        cur.execute('EXEC dbo.usp_ActualizarPrecioProducto @IdProducto=?,@NuevoPrecio=?', integer(data, 'IdProducto'), amount(data, 'NuevoPrecio'))
    elif path == '/api/clients':
        names = text_field(data, 'Nombres', 100)
        last = text_field(data, 'Apellidos', 100)
        phone = text_field(data, 'Telefono', 20, True)
        email = text_field(data, 'Correo', 150, True)
        cur.execute('DECLARE @id int; EXEC dbo.usp_RegistrarCliente @Nombres=?,@Apellidos=?,@Telefono=?,@Correo=?,@IdCliente=@id OUTPUT;', names, last, phone, email)
    else:
        raise ValueError('Operación desconocida.')
    return {'ok': True}


def serialize(v):
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (datetime.datetime, datetime.date)):
        return v.isoformat()
    raise TypeError(type(v).__name__)


class Handler(BaseHTTPRequestHandler):
    def send(self, status, data, mime='application/json; charset=utf-8', cookie=None):
        content = json.dumps(data, default=serialize, ensure_ascii=False).encode() if not isinstance(data, bytes) else data
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(content)))
        self.send_header('Cache-Control', 'no-store')
        if cookie:
            self.send_header('Set-Cookie', cookie)
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self):
        session = None
        if self.path.startswith('/api/'):
            try:
                session = auth.resolve(self.headers, connect)
                if self.path == '/api/session':
                    cn = connect()
                    try:
                        setup = not rows(cn.cursor(), 'SELECT TOP (1) IdUsuario FROM dbo.UsuariosApp')
                    finally:
                        cn.close()
                    return self.send(200, {'token':session['csrf'] if session else TOKEN,
                                          'user':session['user'] if session else None,
                                          'pages':auth.PAGES[session['user']['role']] if session else [], 'setup':setup})
                if not session:
                    return self.send(401, {'error':'Inicia sesión para continuar.'})
            except Exception:
                return self.send(503, {'error':'No se pudo conectar al sistema de usuarios. Comprueba SQL Server y el complemento SQL/08_UsuariosApp.sql.'})
        if self.path == '/api/users':
            if session['user']['role'] != 'gerencia':
                return self.send(403, {'error':'Solo gerencia administra usuarios.'})
            cn = connect()
            try:
                users = rows(cn.cursor(), 'SELECT IdUsuario id,Usuario username,Nombre name,Rol role,Activo active FROM dbo.UsuariosApp ORDER BY IdUsuario')
            finally:
                cn.close()
            return self.send(200, users)
        if self.path.startswith('/api/sales/'):
            if session['user']['role'] not in ('gerencia','cajero'):
                return self.send(403, {'error':'Tu rol no permite consultar ventas.'})
            sale_id = self.path.removeprefix('/api/sales/')
            if not sale_id.isdigit():
                return self.send(400, {'error': 'Venta inválida.'})
            try:
                cn = connect()
                try:
                    cur = cn.cursor()
                    auth.impersonate(cur, session['user']['role'])
                    result = rows(cur, 'SELECT * FROM dbo.vw_DetalleVentas WHERE IdVenta=?', int(sale_id))
                finally:
                    cn.close()
                return self.send(200, result)
            except Exception:
                return self.send(503, {'error': 'No se pudo consultar el detalle de venta.'})
        if self.path == '/api/data':
            try:
                cn = connect()
                try:
                    cur = cn.cursor()
                    auth.impersonate(cur, session['user']['role'])
                    result = snapshot(cur, session['user']['role'])
                finally:
                    cn.close()
                return self.send(200, result)
            except Exception:
                return self.send(503, {'error': 'No se pudo conectar a BuenPan_ASB404. Comprueba que SQL Server esté iniciado y revisa config.local.json y los permisos de tu usuario de Windows.'})
        files = {'/': ('index.html', 'text/html'), '/app.js': ('app.js', 'text/javascript'), '/auth-ui.js': ('auth-ui.js','text/javascript'), '/style.css': ('style.css', 'text/css')}
        if self.path.startswith('/assets/'):
            asset = ROOT / 'web' / 'assets' / self.path.removeprefix('/assets/')
            base = (ROOT / 'web' / 'assets').resolve()
            if asset.resolve().parent == base and asset.is_file() and asset.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
                mime = {'.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp'}[asset.suffix.lower()]
                return self.send(200, asset.read_bytes(), mime)
            return self.send(404, {'error': 'Imagen no encontrada.'})
        if self.path in files:
            name, mime = files[self.path]
            return self.send(200, (ROOT / 'web' / name).read_bytes(), mime + '; charset=utf-8')
        self.send(404, {'error': 'No encontrado.'})

    def do_POST(self):
        try:
            session = auth.resolve(self.headers, connect)
            anonymous = self.path in ('/api/auth/login','/api/auth/setup')
            if not anonymous and not session:
                return self.send(401, {'error':'Inicia sesión para continuar.'})
            csrf = session['csrf'] if session else TOKEN
            if not secrets.compare_digest(self.headers.get('X-App-Token', ''), csrf):
                return self.send(403, {'error':'Sesión inválida. Recarga la página.'})
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 65536:
                raise ValueError('Solicitud inválida.')
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict):
                raise ValueError('Solicitud inválida.')
            if self.path.startswith('/api/auth/') or self.path.startswith('/api/users'):
                return self.handle_auth(data, session)
            if session['user']['role'] not in auth.WRITES.get(self.path,set()):
                return self.send(403, {'error':'Tu rol no tiene permiso para esta operación.'})
            cn = connect()
            try:
                cur = cn.cursor()
                auth.impersonate(cur, session['user']['role'])
                result = mutate(cur, self.path, data)
                cn.commit()
            except Exception:
                cn.rollback()
                raise
            finally:
                cn.close()
            self.send(200, result)
        except (ValueError, TypeError, KeyError) as e:
            self.send(400, {'error': str(e)})
        except PermissionError as e:
            self.send(403, {'error':str(e)})
        except Exception as e:
            message = str(e)
            if '51003' in message:
                message = 'Inventario insuficiente. Actualiza los datos y revisa el carrito.'
            elif '2601' in message or '2627' in message:
                message = 'Ya existe un registro con esos datos. Revisa el correo.'
            else:
                message = 'SQL Server rechazó la operación. Revisa los datos, la conexión y los permisos. No se guardaron cambios.'
            self.send(409, {'error': message})

    def handle_auth(self, data, session):
        path = self.path
        if path == '/api/auth/logout':
            with auth.LOCK:
                auth.SESSIONS.pop(auth.session_cookie(self.headers),None)
            return self.send(200, {'ok':True}, cookie='buen_dia_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0')
        cn = connect()
        revoke_id = None
        try:
            cur = cn.cursor()
            if path in ('/api/auth/login','/api/auth/setup'):
                username = text_field(data, 'username', 40)
                password = text_field(data, 'password', 128)
                # Passwords are not trimmed: spaces may be intentional.
                password = data['password']
                auth.check_attempt(self.client_address[0], username)
                if path.endswith('/setup'):
                    user = auth.add_user(cur,data,bootstrap=True)
                else:
                    user = auth.verify(cur,username,password)
                # Verify that the chosen SQL role actually works before issuing a session.
                auth.impersonate(cur,user['role'])
                cur.execute('SELECT TOP (1) IdProducto FROM dbo.vw_CatalogoProductos')
                cur.fetchall()
                cn.commit()
                sid, issued = auth.issue(user)
                return self.send(200, {'user':user,'token':issued['csrf'],'pages':auth.PAGES[user['role']]},
                                 cookie=f'buen_dia_session={sid}; HttpOnly; SameSite=Strict; Path=/; Max-Age={auth.TTL}')
            user = session['user']
            if path == '/api/auth/password':
                auth.verify(cur,user['username'],str(data.get('current_password','')))
                digest,salt = auth.password_fields(data.get('password'))
                cur.execute('UPDATE dbo.UsuariosApp SET ClaveHash=?,Sal=? WHERE IdUsuario=?',digest,salt,user['id'])
                revoke_id = user['id']
            elif path.startswith('/api/users'):
                if user['role'] != 'gerencia':
                    raise PermissionError('Solo gerencia administra usuarios.')
                if path == '/api/users':
                    auth.add_user(cur,data)
                elif path == '/api/users/status':
                    target = integer(data,'id')
                    if target == user['id']:
                        raise ValueError('No puedes desactivar tu propia cuenta.')
                    if not isinstance(data.get('active'),bool):
                        raise ValueError('Estado inválido.')
                    cur.execute('SELECT Rol,Activo FROM dbo.UsuariosApp WITH (UPDLOCK,HOLDLOCK) WHERE IdUsuario=?',target)
                    row = cur.fetchone()
                    if not row:
                        raise ValueError('El usuario no existe.')
                    if row[0] == 'gerencia' and row[1] and not data['active']:
                        cur.execute("SELECT COUNT(*) FROM dbo.UsuariosApp WITH (UPDLOCK,HOLDLOCK) WHERE Rol='gerencia' AND Activo=1")
                        if cur.fetchone()[0] <= 1:
                            raise ValueError('Debe quedar al menos una cuenta de gerencia activa.')
                    cur.execute('UPDATE dbo.UsuariosApp SET Activo=? WHERE IdUsuario=?',data['active'],target)
                    revoke_id = target
                else:
                    raise ValueError('Operación desconocida.')
            else:
                raise ValueError('Operación desconocida.')
            cn.commit()
            if revoke_id:
                auth.revoke(revoke_id)
            return self.send(200, {'ok':True})
        except Exception:
            cn.rollback()
            raise
        finally:
            cn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--open', action='store_true')
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    server = ThreadingHTTPServer(('127.0.0.1', args.port), Handler)
    print(f'Buen Día disponible en http://127.0.0.1:{args.port}. Ctrl+C para cerrar.', flush=True)
    if args.open:
        threading.Timer(0.8, lambda: webbrowser.open(f'http://127.0.0.1:{args.port}')).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
