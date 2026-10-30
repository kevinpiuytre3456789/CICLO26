USE BuenPan_ASB404;
GO
CREATE OR ALTER TRIGGER dbo.trg_DetalleVenta_DescontarInventario
ON dbo.DetalleVenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Ventas AS v ON v.IdVenta = i.IdVenta
        WHERE v.Estado <> 'BORRADOR'
    )
        THROW 51001, N'Solo es posible agregar productos a ventas en borrador.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.Productos AS p ON p.IdProducto = i.IdProducto
        WHERE p.Activo = 0
    )
        THROW 51002, N'No es posible vender productos inactivos.', 1;

    ;WITH Consumo AS
    (
        SELECT IdProducto, SUM(Cantidad) AS Cantidad
        FROM inserted
        GROUP BY IdProducto
    )
    UPDATE p
       SET p.Stock = p.Stock - c.Cantidad
    FROM dbo.Productos AS p
    INNER JOIN Consumo AS c ON c.IdProducto = p.IdProducto
    WHERE p.Stock >= c.Cantidad AND p.Activo = 1;

    IF @@ROWCOUNT <> (SELECT COUNT(DISTINCT IdProducto) FROM inserted)
        THROW 51003, N'Inventario insuficiente para completar la operación.', 1;

    INSERT INTO dbo.MovimientosInventario(IdProducto, IdVenta, Tipo, Cantidad, UsuarioBD)
    SELECT IdProducto, IdVenta, 'SALIDA', SUM(Cantidad), USER_NAME()
    FROM inserted
    GROUP BY IdProducto, IdVenta;
END;
GO
CREATE OR ALTER TRIGGER dbo.trg_DetalleVenta_BloquearEdicion
ON dbo.DetalleVenta
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 51004, N'Las líneas de venta no pueden modificarse ni borrarse; anula la venta para devolver existencias.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.trg_Productos_Auditoria
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditoriaProductos
    (
        IdProducto, Campo, ValorAnterior, ValorNuevo, UsuarioBD
    )
    SELECT i.IdProducto, cambios.Campo, cambios.Anterior, cambios.Nuevo, USER_NAME()
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.IdProducto = i.IdProducto
    CROSS APPLY
    (
        VALUES
        (N'Stock', CONVERT(NVARCHAR(100), d.Stock), CONVERT(NVARCHAR(100), i.Stock)),
        (N'PrecioVenta', CONVERT(NVARCHAR(100), d.PrecioVenta), CONVERT(NVARCHAR(100), i.PrecioVenta)),
        (N'CostoUnitario', CONVERT(NVARCHAR(100), d.CostoUnitario), CONVERT(NVARCHAR(100), i.CostoUnitario)),
        (N'Activo', CONVERT(NVARCHAR(100), d.Activo), CONVERT(NVARCHAR(100), i.Activo))
    ) AS cambios(Campo, Anterior, Nuevo)
    WHERE cambios.Anterior <> cambios.Nuevo;
END;
GO
CREATE OR ALTER TRIGGER dbo.trg_Ventas_ValidarEstados
ON dbo.Ventas
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN deleted AS d ON d.IdVenta = i.IdVenta
        WHERE i.Estado <> d.Estado
          AND NOT
          (
              (d.Estado = 'BORRADOR' AND i.Estado IN ('CONFIRMADA', 'ANULADA'))
              OR (d.Estado = 'CONFIRMADA' AND i.Estado = 'ANULADA')
          )
    )
        THROW 51005, N'Transición de estado no permitida.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN deleted AS d ON d.IdVenta = i.IdVenta
        WHERE d.Estado <> 'BORRADOR'
          AND (i.Subtotal <> d.Subtotal OR i.IVA <> d.IVA OR i.Total <> d.Total)
    )
        THROW 51006, N'No se pueden modificar los importes de ventas cerradas.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN deleted AS d ON d.IdVenta = i.IdVenta
        WHERE i.Estado = 'CONFIRMADA'
          AND d.Estado = 'BORRADOR'
          AND NOT EXISTS
          (
              SELECT 1 FROM dbo.DetalleVenta AS dv WHERE dv.IdVenta = i.IdVenta
          )
    )
        THROW 51007, N'No se puede confirmar una venta sin productos.', 1;
END;
GO
