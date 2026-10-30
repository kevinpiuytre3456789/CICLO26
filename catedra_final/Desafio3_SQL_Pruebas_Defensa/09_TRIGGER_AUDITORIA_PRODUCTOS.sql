USE BuenPan_ASB404;
GO
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN002');
BEGIN TRANSACTION;
SELECT N'Valor antes del cambio' AS Demostracion, Codigo, PrecioVenta FROM dbo.Productos WHERE IdProducto=@Producto;
UPDATE dbo.Productos SET PrecioVenta=PrecioVenta+0.15 WHERE IdProducto=@Producto;
SELECT N'Valor después del cambio' AS Demostracion, Codigo, PrecioVenta FROM dbo.Productos WHERE IdProducto=@Producto;
SELECT N'El trigger guardó valor anterior y nuevo' AS Demostracion;
SELECT TOP(5) Campo, ValorAnterior, ValorNuevo, UsuarioBD, Fecha
FROM dbo.AuditoriaProductos
WHERE IdProducto=@Producto AND Campo=N'PrecioVenta'
ORDER BY IdAuditoria DESC;
ROLLBACK TRANSACTION;
SELECT N'Valor original restaurado' AS Demostracion, PrecioVenta FROM dbo.Productos WHERE IdProducto=@Producto;
GO
