USE BuenPan_ASB404;
GO
SET XACT_ABORT OFF;
DECLARE @Venta INT=(SELECT TOP(1) IdVenta FROM dbo.Ventas WHERE Estado='CONFIRMADA' ORDER BY IdVenta);
SELECT N'Estado original' AS Demostracion, IdVenta, Estado, Subtotal, IVA, Total FROM dbo.Ventas WHERE IdVenta=@Venta;
BEGIN TRY
    UPDATE dbo.Ventas SET Estado='BORRADOR' WHERE IdVenta=@Venta;
    SELECT N'ERROR: se permitió transición inválida' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: no puede volver de CONFIRMADA a BORRADOR' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
BEGIN TRY
    UPDATE dbo.Ventas SET Subtotal=Subtotal+1, Total=Total+1 WHERE IdVenta=@Venta;
    SELECT N'ERROR: se modificó una venta cerrada' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: importes de venta cerrada protegidos' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
SELECT N'Venta sin cambios' AS Demostracion, IdVenta, Estado, Subtotal, IVA, Total FROM dbo.Ventas WHERE IdVenta=@Venta;
GO
