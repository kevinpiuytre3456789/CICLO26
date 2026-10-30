USE BuenPan_ASB404;
GO
SELECT o.type_desc AS TipoObjeto, COUNT(*) AS Cantidad
FROM sys.objects AS o
WHERE o.is_ms_shipped = 0 AND o.type IN ('U','V','P','TR')
GROUP BY o.type_desc
ORDER BY o.type_desc;
GO
SELECT * FROM dbo.vw_CatalogoProductos ORDER BY Producto;
SELECT * FROM dbo.vw_StockCritico ORDER BY UnidadesPorReponer DESC;
SELECT * FROM dbo.vw_ResumenVentasDiarias ORDER BY Fecha DESC;
SELECT * FROM dbo.vw_TopProductos ORDER BY UnidadesVendidas DESC;
SELECT * FROM dbo.vw_ClientesFrecuentes ORDER BY TotalComprado DESC;
SELECT TOP (15) * FROM dbo.vw_MovimientosInventario ORDER BY Fecha DESC, IdMovimiento DESC;
SELECT TOP (15) * FROM dbo.AuditoriaProductos ORDER BY IdAuditoria DESC;
GO
DECLARE @VentaDemostracion INT;
EXEC dbo.usp_RegistrarVenta @IdCliente=4, @IdEmpleado=1, @IdProducto=3, @Cantidad=2, @IdVenta=@VentaDemostracion OUTPUT;
EXEC dbo.usp_AgregarProductoVenta @IdVenta=@VentaDemostracion, @IdProducto=10, @Cantidad=3;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@VentaDemostracion;
SELECT IdVenta, Fecha, Estado, Subtotal, IVA, Total FROM dbo.Ventas WHERE IdVenta=@VentaDemostracion;
SELECT * FROM dbo.vw_DetalleVentas WHERE IdVenta=@VentaDemostracion;
GO
EXEC dbo.usp_RegistrarEntradaInventario @IdProducto=6, @Cantidad=5, @CostoUnitario=0.85;
EXEC dbo.usp_ActualizarPrecioProducto @IdProducto=9, @NuevoPrecio=0.75;
SELECT Codigo, Producto, PrecioVenta, Stock FROM dbo.vw_CatalogoProductos WHERE IdProducto IN (6,9);
SELECT TOP (10) * FROM dbo.AuditoriaProductos ORDER BY IdAuditoria DESC;
GO
BEGIN TRY
    DECLARE @VentaSinStock INT;
    EXEC dbo.usp_RegistrarVenta @IdCliente=2, @IdEmpleado=1, @IdProducto=1, @Cantidad=999999, @IdVenta=@VentaSinStock OUTPUT;
    SELECT N'ERROR: operación inesperadamente aceptada' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'Correcto: venta rechazada por inventario insuficiente' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
GO
BEGIN TRY
    EXEC dbo.usp_ActualizarPrecioProducto @IdProducto=9, @NuevoPrecio=-3.00;
    SELECT N'ERROR: precio negativo aceptado' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'Correcto: precio negativo rechazado' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
GO
EXECUTE AS USER = 'demo_cajero';
SELECT USER_NAME() AS UsuarioActual,
       HAS_PERMS_BY_NAME('dbo.usp_RegistrarVenta', 'OBJECT', 'EXECUTE') AS PuedeRegistrarVenta,
       HAS_PERMS_BY_NAME('dbo.usp_RegistrarEntradaInventario', 'OBJECT', 'EXECUTE') AS PuedeRegistrarEntrada,
       HAS_PERMS_BY_NAME('dbo.vw_CatalogoProductos', 'OBJECT', 'SELECT') AS PuedeConsultarCatalogo;
SELECT TOP (3) * FROM dbo.vw_CatalogoProductos;
REVERT;
GO
EXECUTE AS USER = 'demo_inventario';
SELECT USER_NAME() AS UsuarioActual,
       HAS_PERMS_BY_NAME('dbo.usp_RegistrarEntradaInventario', 'OBJECT', 'EXECUTE') AS PuedeRegistrarEntrada,
       HAS_PERMS_BY_NAME('dbo.usp_RegistrarVenta', 'OBJECT', 'EXECUTE') AS PuedeRegistrarVenta,
       HAS_PERMS_BY_NAME('dbo.vw_StockCritico', 'OBJECT', 'SELECT') AS PuedeConsultarStockCritico;
REVERT;
GO
EXECUTE AS USER = 'demo_gerencia';
SELECT USER_NAME() AS UsuarioActual,
       HAS_PERMS_BY_NAME('dbo.usp_AnularVenta', 'OBJECT', 'EXECUTE') AS PuedeAnularVenta,
       HAS_PERMS_BY_NAME('dbo.vw_RentabilidadProductos', 'OBJECT', 'SELECT') AS PuedeConsultarRentabilidad;
SELECT TOP (3) * FROM dbo.vw_RentabilidadProductos;
REVERT;
GO
SELECT r.name AS Rol, u.name AS UsuarioDemostracion
FROM sys.database_role_members AS m
JOIN sys.database_principals AS r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals AS u ON u.principal_id = m.member_principal_id
WHERE r.name IN (N'rol_cajero', N'rol_inventario', N'rol_gerencia')
ORDER BY r.name;
GO
