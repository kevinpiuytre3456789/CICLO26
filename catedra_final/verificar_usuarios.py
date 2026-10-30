"""Prueba cuentas temporales, sesiones y permisos reales; limpia solo sus cuentas al terminar."""
import http.cookiejar
import json
import secrets
import threading
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer
import app
import auth


def request(client, base, path, data=None, token=None):
    headers = {}
    if token:
        headers['X-App-Token'] = token
    body = None if data is None else json.dumps(data).encode()
    if body:
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(base+path, data=body, headers=headers)
    try:
        with client.open(req,timeout=15) as response:
            return response.status,json.load(response),response.headers
    except urllib.error.HTTPError as response:
        return response.code,json.load(response),response.headers


def browser():
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def main():
    prefix = 'prueba_'+secrets.token_hex(6)
    password = secrets.token_urlsafe(20)
    ids = []
    users = {}
    server = ThreadingHTTPServer(('127.0.0.1',0),app.Handler)
    threading.Thread(target=server.serve_forever,daemon=True).start()
    base = f'http://127.0.0.1:{server.server_port}'
    checks = []
    cn = app.connect()
    try:
        cur = cn.cursor()
        cur.execute('SELECT COUNT(*) FROM dbo.UsuariosApp')
        existing = cur.fetchone()[0]
        if not existing:
            initial = auth.add_user(cur,{'username':prefix+'_inicial','name':'Inicial temporal','role':'cajero','password':password},bootstrap=True)
            assert initial['role'] == 'gerencia'
        rejected = False
        try:
            auth.add_user(cur,{'username':prefix+'_otro','name':'Inicial duplicado','password':password},bootstrap=True)
        except PermissionError:
            rejected = True
        assert rejected, 'No debe poder crearse una segunda cuenta inicial.'
        cn.rollback()
        checks.append('Primera cuenta asignada a gerencia; creación inicial adicional bloqueada')
        # User creation and verification use real SQL storage, never clear-text passwords.
        for role in auth.ROLE_USERS:
            user = auth.add_user(cur,{'username':prefix+'_'+role,'name':'Cuenta temporal de prueba','role':role,'password':password})
            ids.append(user['id']); users[role] = user
            assert auth.verify(cur,user['username'],password)['role'] == role
        cur.execute('SELECT ClaveHash FROM dbo.UsuariosApp WHERE IdUsuario=?',ids[0])
        assert cur.fetchone()[0] != password
        cn.commit()
        checks.append('Cuentas SQL con claves derivadas y verificación de contraseña')
        anon = browser()
        assert request(anon,base,'/api/data')[0] == 401
        assert request(anon,base,'/api/users')[0] == 401
        assert request(anon,base,'/api/sales',{})[0] == 401
        checks.append('Lectura y escritura bloqueadas sin sesión')
        clients = {}
        for role,user in users.items():
            client = browser()
            _,session,_ = request(client,base,'/api/session')
            code,result,headers = request(client,base,'/api/auth/login',{'username':user['username'],'password':password},session['token'])
            assert code == 200,(role,code,result)
            assert 'HttpOnly' in headers['Set-Cookie'] and 'SameSite=Strict' in headers['Set-Cookie']
            csrf = result['token']
            clients[role] = (client,csrf)
            assert result['pages'] == auth.PAGES[role]
            code,data,_ = request(client,base,'/api/data')
            assert code == 200,(role,data)
            assert data['products']
            if role != 'gerencia':
                assert data['profit'] == [] and data['audit'] == [] and data['daily'] == []
                assert request(client,base,'/api/users')[0] == 403
                assert request(client,base,'/api/sales/cancel',{'IdVenta':1},csrf)[0] == 403
            if role == 'inventario':
                assert data['clients'] == [] and data['sales'] == [] and data['employees'] == []
                assert request(client,base,'/api/sales',{},csrf)[0] == 403
                assert request(client,base,'/api/clients',{},csrf)[0] == 403
                assert request(client,base,'/api/sales/1')[0] == 403
            if role == 'cajero':
                assert data['clients'] and data['employees']
                assert request(client,base,'/api/price',{},csrf)[0] == 403
                assert request(client,base,'/api/inventory',{},csrf)[0] == 403
            assert request(client,base,'/api/auth/logout',{},'incorrecto')[0] == 403
        checks.append('Sesiones HttpOnly, CSRF y permisos de gerencia, cajero e inventario verificados por HTTP')
        manager,manager_token = clients['gerencia']
        assert request(manager,base,'/api/users')[0] == 200
        assert request(manager,base,'/api/users/status',{'id':users['gerencia']['id'],'active':False},manager_token)[0] == 400
        cashier,cashier_token = clients['cajero']
        assert request(manager,base,'/api/users/status',{'id':users['cajero']['id'],'active':False},manager_token)[0] == 200
        assert request(cashier,base,'/api/data')[0] == 401
        assert request(manager,base,'/api/users/status',{'id':users['cajero']['id'],'active':True},manager_token)[0] == 200
        stock,stock_token = clients['inventario']
        new_password = secrets.token_urlsafe(20)
        assert request(stock,base,'/api/auth/password',{'current_password':password,'password':new_password},stock_token)[0] == 200
        assert request(stock,base,'/api/data')[0] == 401
        _,session,_=request(stock,base,'/api/session')
        assert request(stock,base,'/api/auth/login',{'username':users['inventario']['username'],'password':password},session['token'])[0] == 403
        code,result,_=request(stock,base,'/api/auth/login',{'username':users['inventario']['username'],'password':new_password},session['token'])
        assert code == 200
        assert request(stock,base,'/api/auth/logout',{},result['token'])[0] == 200
        assert request(stock,base,'/api/data')[0] == 401
        checks.append('Desactivación, revocación de sesiones, cambio de contraseña y cierre de sesión verificados')
        # SQL permissions are enforced independently of the HTTP checks.
        for role in auth.ROLE_USERS:
            role_cn = app.connect()
            try:
                role_cur = role_cn.cursor()
                auth.impersonate(role_cur,role)
                role_cur.execute('SELECT USER_NAME()')
                assert role_cur.fetchone()[0] == auth.ROLE_USERS[role]
                for path,roles in auth.WRITES.items():
                    proc = {'/api/sales':'usp_RegistrarVenta','/api/clients':'usp_RegistrarCliente',
                            '/api/inventory':'usp_RegistrarEntradaInventario','/api/price':'usp_ActualizarPrecioProducto',
                            '/api/sales/cancel':'usp_AnularVenta'}[path]
                    role_cur.execute("SELECT HAS_PERMS_BY_NAME(?, 'OBJECT', 'EXECUTE')",'dbo.'+proc)
                    assert bool(role_cur.fetchone()[0]) == (role in roles),(role,path)
                role_cur.execute("SELECT HAS_PERMS_BY_NAME('dbo.UsuariosApp','OBJECT','SELECT')")
                assert not role_cur.fetchone()[0]
                stock_data = app.snapshot(role_cur,role)
                available = [p for p in stock_data['products'] if p['Stock'] >= 1]
                assert len(available) >= 2
                if role in ('gerencia','cajero'):
                    app.mutate(role_cur,'/api/clients',{'Nombres':prefix,'Apellidos':'Temporal'})
                    sale = app.mutate(role_cur,'/api/sales',{'IdEmpleado':stock_data['employees'][0]['IdEmpleado'],
                        'items':[{'IdProducto':p['IdProducto'],'Cantidad':1} for p in available[:2]]})
                    assert sale['Estado'] == 'CONFIRMADA'
                    if role == 'gerencia':
                        app.mutate(role_cur,'/api/sales/cancel',{'IdVenta':sale['IdVenta']})
                if role in ('gerencia','inventario'):
                    p = available[0]
                    app.mutate(role_cur,'/api/inventory',{'IdProducto':p['IdProducto'],'Cantidad':1})
                    app.mutate(role_cur,'/api/price',{'IdProducto':p['IdProducto'],'NuevoPrecio':str(p['PrecioVenta'])})
            finally:
                role_cn.rollback()
                role_cn.close()
        checks.append('Usuarios demo_* usados realmente; permisos SQL coinciden con la app y no exponen hashes')
        checks.append('Ventas y clientes como cajero; entradas y precios como inventario; anulación como gerencia, con rollback')
        print(json.dumps({'resultado':'CORRECTO','verificaciones':checks},ensure_ascii=False,indent=2))
    finally:
        server.shutdown();server.server_close()
        cn.rollback()
        for user_id in ids:
            auth.revoke(user_id)
            cn.cursor().execute('DELETE dbo.UsuariosApp WHERE IdUsuario=? AND Usuario LIKE ?',user_id,prefix+'%')
        cn.commit()
        cn.close()


if __name__ == '__main__':
    main()
