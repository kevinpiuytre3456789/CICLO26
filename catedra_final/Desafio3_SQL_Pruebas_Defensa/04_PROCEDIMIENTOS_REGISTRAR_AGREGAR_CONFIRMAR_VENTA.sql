USE BuenPan_ASB404;
GO
DECLARE @Venta INT;
DECLARE @Cliente INT=(SELECT TOP(1) IdCliente FROM dbo.Clientes ORDER BY IdCliente);
DECLARE @Empleado INT=(SELECT TOP(1) IdEmpleado FROM dbo.Empleados WHERE Codigo=N'EMP001');
DECLARE @Pan INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
DECLARE @Cafe INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'BEB001');
DECLARE @StockPan INT=(SELECT Stock FROM dbo.Productos WHERE IdProducto=@Pan);
BEGIN TRANSACTION;
SELECT N'Antes de vender: stock de pan francés' AS Demostracion, @StockPan AS StockInicial;
EXEC dbo.usp_RegistrarVenta @IdCliente=@Cliente, @IdEmpleado=@Empleado,
    @IdProducto=@Pan, @Cantidad=2, @IdVenta=@Venta OUTPUT;
SELECT N'Procedimiento 1: venta creada en borrador' AS Demostracion;
SELECT IdVenta, Estado, Subtotal, IVA, Total FROM dbo.Ventas WHERE IdVenta=@Venta;
EXEC dbo.usp_AgregarProductoVenta @IdVenta=@Venta, @IdProducto=@Cafe, @Cantidad=1;
SELECT N'Procedimiento 2: segundo artículo agregado' AS Demostracion;
SELECT IdProducto, Cantidad, PrecioUnitario, Subtotal FROM dbo.DetalleVenta WHERE IdVenta=@Venta;
SELECT N'Stock descontado automáticamente' AS Demostracion,
       @StockPan AS StockAnterior, p.Stock AS StockActual, @StockPan-p.Stock AS UnidadesDescontadas
FROM dbo.Productos AS p WHERE p.IdProducto=@Pan;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@Venta;
SELECT N'Procedimiento 3: venta confirmada con IVA del 13 por ciento' AS Demostracion;
SELECT IdVenta, Estado, Subtotal, IVA, Total FROM dbo.Ventas WHERE IdVenta=@Venta;
SELECT * FROM dbo.vw_DetalleVentas WHERE IdVenta=@Venta;
ROLLBACK TRANSACTION;
SELECT N'Prueba revertida: stock restaurado' AS Demostracion, Stock FROM dbo.Productos WHERE IdProducto=@Pan;
GO
