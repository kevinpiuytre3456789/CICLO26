USE BuenPan_ASB404;
GO
SELECT N'1. OBJETOS DEL PROYECTO' AS Etapa;
SELECT o.type_desc AS Tipo,COUNT(*) AS Cantidad FROM sys.objects AS o
WHERE o.is_ms_shipped=0 AND o.type IN ('U','V','P','TR') GROUP BY o.type_desc;
SELECT N'2. REPORTE DE PRODUCTOS' AS Etapa;
SELECT TOP(6) * FROM dbo.vw_CatalogoProductos ORDER BY Codigo;
SELECT N'3. VENTAS Y REPORTES' AS Etapa;
SELECT * FROM dbo.vw_ResumenVentasDiarias;
SELECT TOP(5) * FROM dbo.vw_TopProductos ORDER BY UnidadesVendidas DESC;
GO
DECLARE @Venta INT;
DECLARE @Empleado INT=(SELECT IdEmpleado FROM dbo.Empleados WHERE Codigo=N'EMP001');
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
DECLARE @Antes INT=(SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto);
BEGIN TRANSACTION;
SELECT N'4. INVENTARIO ANTES DE VENDER' AS Etapa,@Antes AS Stock;
EXEC dbo.usp_RegistrarVenta @IdCliente=NULL,@IdEmpleado=@Empleado,
    @IdProducto=@Producto,@Cantidad=2,@IdVenta=@Venta OUTPUT;
SELECT N'5. EL TRIGGER DESCONTÓ DOS UNIDADES' AS Etapa, @Antes AS Antes,Stock AS Despues
FROM dbo.Productos WHERE IdProducto=@Producto;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@Venta;
SELECT N'6. VENTA CONFIRMADA' AS Etapa;
SELECT IdVenta,Estado,Subtotal,IVA,Total FROM dbo.Ventas WHERE IdVenta=@Venta;
SELECT N'7. AUDITORIA Y MOVIMIENTO' AS Etapa;
SELECT TOP(2) Campo,ValorAnterior,ValorNuevo FROM dbo.AuditoriaProductos
WHERE IdProducto=@Producto ORDER BY IdAuditoria DESC;
SELECT Tipo,Cantidad FROM dbo.MovimientosInventario WHERE IdVenta=@Venta;
ROLLBACK TRANSACTION;
SELECT N'8. DATOS RESTAURADOS AL TERMINAR' AS Etapa,Stock FROM dbo.Productos WHERE IdProducto=@Producto;
GO
