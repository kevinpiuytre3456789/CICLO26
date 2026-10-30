"""Pruebas reales de SQL Server. Revierte todos los datos creados al terminar.

Las secuencias IDENTITY pueden avanzar aunque se revierta la transacción.
Ejecutar sin otros usuarios escribiendo durante la prueba.
"""
import decimal
import json
import app


def scalar(cur, sql, *params):
    cur.execute(sql, *params)
    while cur.description is None:
        if not cur.nextset():
            raise AssertionError('Sin resultado SQL')
    return cur.fetchone()[0]


def fingerprint(cur):
    tables = ['Clientes', 'Ventas', 'DetalleVenta', 'Productos', 'MovimientosInventario', 'AuditoriaProductos']
    return {t: app.rows(cur, f'SELECT * FROM dbo.{t}') for t in tables}


def main():
    cn = app.connect()
    results = []
    try:
        cur = cn.cursor()
        before = fingerprint(cur)
        data = app.snapshot(cur)
        assert all(k in data for k in ('critical', 'frequent', 'audit', 'objects'))
        assert len([o for o in data['objects'] if o['Tipo'] == 'P']) >= 7
        assert len([o for o in data['objects'] if o['Tipo'] == 'V']) >= 8
        triggers = [o for o in data['objects'] if o['Tipo'] == 'TR']
        assert len(triggers) >= 4 and not any(t['Deshabilitado'] for t in triggers)
        results.append('8 vistas consultadas; 7 procedimientos y 4 triggers detectados y habilitados')
        products = data['products'][:2]
        assert len(products) == 2 and data['employees'], 'Se requieren dos productos y un empleado activos.'
        p1, p2 = products
        original_price = decimal.Decimal(str(p1['PrecioVenta']))
        new_price = original_price + decimal.Decimal('0.01')
        app.mutate(cur, '/api/clients', {'Nombres': 'Prueba transaccional', 'Apellidos': 'Buen Día', 'Correo': None})
        # Find the test client inside this transaction; the procedure owns its IDENTITY scope.
        client = scalar(cur, "SELECT MAX(IdCliente) FROM dbo.Clientes WHERE Nombres=N'Prueba transaccional' AND Apellidos=N'Buen Día'")
        assert client
        app.mutate(cur, '/api/price', {'IdProducto': p1['IdProducto'], 'NuevoPrecio': str(new_price)})
        assert scalar(cur, 'SELECT PrecioVenta FROM dbo.Productos WHERE IdProducto=?', p1['IdProducto']) == new_price
        for p in products:
            app.mutate(cur, '/api/inventory', {'IdProducto': p['IdProducto'], 'Cantidad': 3, 'CostoUnitario': '0'})
        sale = app.mutate(cur, '/api/sales', {'IdEmpleado': data['employees'][0]['IdEmpleado'], 'IdCliente': client,
                                           'items': [{'IdProducto': p['IdProducto'], 'Cantidad': 1} for p in products]})
        assert sale['Estado'] == 'CONFIRMADA'
        expected = new_price + p2['PrecioVenta']
        assert sale['Subtotal'] == expected
        assert sale['IVA'] == (expected * decimal.Decimal('.13')).quantize(decimal.Decimal('.01'), rounding=decimal.ROUND_HALF_UP)
        assert sale['Total'] == sale['Subtotal'] + sale['IVA']
        assert len(app.rows(cur, 'SELECT * FROM dbo.vw_DetalleVentas WHERE IdVenta=?', sale['IdVenta'])) == 2
        for p in products:
            assert scalar(cur, 'SELECT Stock FROM dbo.Productos WHERE IdProducto=?', p['IdProducto']) == p['Stock'] + 2
        app.mutate(cur, '/api/sales/cancel', {'IdVenta': sale['IdVenta']})
        assert scalar(cur, 'SELECT Estado FROM dbo.Ventas WHERE IdVenta=?', sale['IdVenta']) == 'ANULADA'
        for p in products:
            assert scalar(cur, 'SELECT Stock FROM dbo.Productos WHERE IdProducto=?', p['IdProducto']) == p['Stock'] + 3
        assert scalar(cur, 'SELECT COUNT(*) FROM dbo.MovimientosInventario WHERE IdVenta=?', sale['IdVenta']) == 4
        assert scalar(cur, 'SELECT COUNT(*) FROM dbo.AuditoriaProductos') > len(before['AuditoriaProductos'])
        results.append('7 procedimientos ejecutados: cliente, precio, entrada con costo cero, venta de dos productos, confirmación y anulación')
        results.append('Stock, IVA, total, detalle, movimientos y auditoría verificados')
        cn.rollback()
        assert fingerprint(cur) == before, 'Los datos deben quedar exactamente iguales después del rollback.'
        results.append('Todos los datos de prueba revertidos; contenido original verificado')
        # Each trigger rejection is tested in its own transaction because THROW can roll back the entire transaction.
        active_sale = next((s for s in data['sales'] if s['Estado'] == 'CONFIRMADA'), None)
        if active_sale:
            for sql, code in [
                ('UPDATE dbo.DetalleVenta SET Cantidad=Cantidad WHERE IdVenta=?', '51004'),
                ("UPDATE dbo.Ventas SET Estado='BORRADOR' WHERE IdVenta=?", '51005'),
            ]:
                rejected = False
                try:
                    cur.execute(sql, active_sale['IdVenta'])
                except Exception as exc:
                    rejected = code in str(exc)
                finally:
                    cn.rollback()
                assert rejected, f'No se recibió el rechazo esperado {code}'
            results.append('Triggers bloquean edición de detalle y transición inválida de venta')
        try:
            app.mutate(cur, '/api/sales', {'IdEmpleado': data['employees'][0]['IdEmpleado'], 'items': [
                {'IdProducto': p1['IdProducto'], 'Cantidad': 1},
                {'IdProducto': p2['IdProducto'], 'Cantidad': p2['Stock'] + 1}]})
        except Exception as exc:
            assert '51003' in str(exc), str(exc)
        else:
            raise AssertionError('Debió rechazarse la venta sin stock suficiente.')
        finally:
            cn.rollback()
        assert fingerprint(cur) == before, 'La venta fallida no debe dejar cabecera, detalles, movimientos ni cambios de stock.'
        results.append('Venta con segundo producto sin stock rechazada y revertida por completo')
        print(json.dumps({'resultado': 'CORRECTO', 'verificaciones': results}, ensure_ascii=False, indent=2))
    finally:
        cn.rollback()
        cn.close()


if __name__ == '__main__':
    main()
