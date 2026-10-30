USE BuenPan_ASB404;
GO
SET XACT_ABORT OFF;
DECLARE @Detalle INT=(SELECT TOP(1) d.IdDetalle FROM dbo.DetalleVenta AS d
    INNER JOIN dbo.Ventas AS v ON v.IdVenta=d.IdVenta
    WHERE v.Estado='CONFIRMADA' ORDER BY d.IdDetalle);
SELECT N'Detalle existente, no se modificará' AS Demostracion;
SELECT IdDetalle, IdVenta, IdProducto, Cantidad FROM dbo.DetalleVenta WHERE IdDetalle=@Detalle;
BEGIN TRY
    UPDATE dbo.DetalleVenta SET Cantidad=Cantidad+1 WHERE IdDetalle=@Detalle;
    SELECT N'ERROR: el trigger no bloqueó el UPDATE' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: UPDATE rechazado por trigger' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
BEGIN TRY
    DELETE FROM dbo.DetalleVenta WHERE IdDetalle=@Detalle;
    SELECT N'ERROR: el trigger no bloqueó el DELETE' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: DELETE rechazado por trigger' AS Resultado, ERROR_MESSAGE() AS Mensaje;
END CATCH;
SELECT N'Detalle permanece intacto' AS Demostracion;
SELECT IdDetalle, IdVenta, IdProducto, Cantidad FROM dbo.DetalleVenta WHERE IdDetalle=@Detalle;
GO
