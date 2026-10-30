USE BuenPan_ASB404;
GO
DECLARE @Venta INT;
DECLARE @Empleado INT=(SELECT IdEmpleado FROM dbo.Empleados WHERE Codigo=N'EMP001');
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
DECLARE @StockAnterior INT=(SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto);
DECLARE @Precio DECIMAL(12,2)=(SELECT PrecioVenta FROM dbo.Productos WHERE IdProducto=@Producto);
BEGIN TRANSACTION;
INSERT INTO dbo.Ventas(IdCliente, IdEmpleado) VALUES (NULL, @Empleado);
SET @Venta=CONVERT(INT,SCOPE_IDENTITY());
SELECT N'ANTES del INSERT de detalle' AS Demostracion, @StockAnterior AS StockInicial;
INSERT INTO dbo.DetalleVenta(IdVenta, IdProducto, Cantidad, PrecioUnitario)
VALUES (@Venta, @Producto, 4, @Precio);
SELECT N'DESPUES: el trigger descontó cuatro unidades' AS Demostracion,
       @StockAnterior AS Antes, p.Stock AS Despues, @StockAnterior-p.Stock AS Descuento
FROM dbo.Productos AS p WHERE p.IdProducto=@Producto;
SELECT N'Movimiento SALIDA generado automáticamente' AS Demostracion;
SELECT Tipo, Cantidad, IdVenta FROM dbo.MovimientosInventario WHERE IdVenta=@Venta;
ROLLBACK TRANSACTION;
SELECT N'Restauración tras la demostración' AS Demostracion, Stock FROM dbo.Productos WHERE IdProducto=@Producto;
GO
