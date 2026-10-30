USE BuenPan_ASB404;
GO
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'GAL001');
DECLARE @PrecioAnterior DECIMAL(12,2)=(SELECT PrecioVenta FROM dbo.Productos WHERE IdProducto=@Producto);
DECLARE @PrecioNuevo DECIMAL(12,2)=@PrecioAnterior+0.10;
BEGIN TRANSACTION;
SELECT N'Precio original' AS Demostracion, Codigo, Nombre, PrecioVenta
FROM dbo.Productos WHERE IdProducto=@Producto;
EXEC dbo.usp_ActualizarPrecioProducto @IdProducto=@Producto, @NuevoPrecio=@PrecioNuevo;
SELECT N'Precio actualizado con procedimiento' AS Demostracion, Codigo, Nombre, PrecioVenta
FROM dbo.Productos WHERE IdProducto=@Producto;
SELECT N'Auditoría automática del cambio de precio' AS Demostracion;
SELECT TOP (5) * FROM dbo.AuditoriaProductos
WHERE IdProducto=@Producto AND Campo=N'PrecioVenta' ORDER BY IdAuditoria DESC;
ROLLBACK TRANSACTION;
SELECT N'Precio restaurado para repetir la prueba' AS Demostracion, PrecioVenta
FROM dbo.Productos WHERE IdProducto=@Producto;
GO
