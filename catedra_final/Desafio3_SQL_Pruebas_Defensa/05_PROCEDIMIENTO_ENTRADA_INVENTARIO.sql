USE BuenPan_ASB404;
GO
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
BEGIN TRANSACTION;
SELECT N'Antes de ingresar 12 unidades' AS Demostracion, Codigo, Nombre, Stock
FROM dbo.Productos WHERE IdProducto=@Producto;
EXEC dbo.usp_RegistrarEntradaInventario @IdProducto=@Producto, @Cantidad=12;
SELECT N'Después de ingresar inventario' AS Demostracion, Codigo, Nombre, Stock
FROM dbo.Productos WHERE IdProducto=@Producto;
SELECT N'Movimiento ENTRADA registrado' AS Demostracion;
SELECT TOP (5) * FROM dbo.MovimientosInventario
WHERE IdProducto=@Producto ORDER BY IdMovimiento DESC;
ROLLBACK TRANSACTION;
SELECT N'Inventario restaurado para repetir la prueba' AS Demostracion, Stock
FROM dbo.Productos WHERE IdProducto=@Producto;
GO
