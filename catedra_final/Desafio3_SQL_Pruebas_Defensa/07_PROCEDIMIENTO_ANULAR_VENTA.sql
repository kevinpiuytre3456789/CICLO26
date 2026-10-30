USE BuenPan_ASB404;
GO
DECLARE @Venta INT;
DECLARE @Empleado INT=(SELECT IdEmpleado FROM dbo.Empleados WHERE Codigo=N'EMP001');
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
DECLARE @StockInicial INT=(SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto);
BEGIN TRANSACTION;
SELECT N'Existencias antes de vender' AS Demostracion, @StockInicial AS StockInicial;
EXEC dbo.usp_RegistrarVenta @IdCliente=NULL, @IdEmpleado=@Empleado,
    @IdProducto=@Producto, @Cantidad=3, @IdVenta=@Venta OUTPUT;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@Venta;
SELECT N'Venta confirmada y stock reducido' AS Demostracion, @Venta AS IdVenta,
       (SELECT Estado FROM dbo.Ventas WHERE IdVenta=@Venta) AS Estado,
       (SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto) AS StockActual;
EXEC dbo.usp_AnularVenta @IdVenta=@Venta;
SELECT N'Venta anulada y unidades devueltas' AS Demostracion, @Venta AS IdVenta,
       (SELECT Estado FROM dbo.Ventas WHERE IdVenta=@Venta) AS Estado,
       (SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto) AS StockActual,
       @StockInicial AS StockInicial;
SELECT N'SALIDA y DEVOLUCION documentadas' AS Demostracion;
SELECT Tipo, Cantidad, IdVenta FROM dbo.MovimientosInventario WHERE IdVenta=@Venta ORDER BY IdMovimiento;
ROLLBACK TRANSACTION;
GO
