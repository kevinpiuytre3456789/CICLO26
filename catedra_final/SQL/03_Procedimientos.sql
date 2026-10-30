USE BuenPan_ASB404;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarVenta
    @IdCliente INT = NULL,
    @IdEmpleado INT,
    @IdProducto INT,
    @Cantidad INT,
    @IdVenta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 51101, N'La cantidad debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Empleados WHERE IdEmpleado = @IdEmpleado AND Activo = 1)
            THROW 51102, N'El empleado no existe o está inactivo.', 1;

        IF @IdCliente IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Clientes WHERE IdCliente = @IdCliente AND Activo = 1
        )
            THROW 51103, N'El cliente no existe o está inactivo.', 1;

        DECLARE @Precio DECIMAL(12,2);
        SELECT @Precio = PrecioVenta FROM dbo.Productos WHERE IdProducto = @IdProducto AND Activo = 1;

        IF @Precio IS NULL
            THROW 51104, N'El producto no existe o está inactivo.', 1;

        INSERT INTO dbo.Ventas(IdCliente, IdEmpleado)
        VALUES (@IdCliente, @IdEmpleado);

        SET @IdVenta = CONVERT(INT, SCOPE_IDENTITY());

        INSERT INTO dbo.DetalleVenta(IdVenta, IdProducto, Cantidad, PrecioUnitario)
        VALUES (@IdVenta, @IdProducto, @Cantidad, @Precio);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_AgregarProductoVenta
    @IdVenta INT,
    @IdProducto INT,
    @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 51105, N'La cantidad debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Ventas WITH (UPDLOCK, HOLDLOCK)
            WHERE IdVenta = @IdVenta AND Estado = 'BORRADOR'
        )
            THROW 51106, N'La venta no existe o ya está cerrada.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.DetalleVenta
            WHERE IdVenta = @IdVenta AND IdProducto = @IdProducto
        )
            THROW 51107, N'El producto ya está en esta venta.', 1;

        DECLARE @Precio DECIMAL(12,2);
        SELECT @Precio = PrecioVenta FROM dbo.Productos WHERE IdProducto = @IdProducto AND Activo = 1;

        IF @Precio IS NULL
            THROW 51108, N'El producto no existe o está inactivo.', 1;

        INSERT INTO dbo.DetalleVenta(IdVenta, IdProducto, Cantidad, PrecioUnitario)
        VALUES (@IdVenta, @IdProducto, @Cantidad, @Precio);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ConfirmarVenta
    @IdVenta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Ventas WITH (UPDLOCK, HOLDLOCK)
            WHERE IdVenta = @IdVenta AND Estado = 'BORRADOR'
        )
            THROW 51109, N'La venta no existe o no está en borrador.', 1;

        DECLARE @Subtotal DECIMAL(14,2);
        DECLARE @IVA DECIMAL(14,2);

        SELECT @Subtotal = SUM(Subtotal)
        FROM dbo.DetalleVenta
        WHERE IdVenta = @IdVenta;

        IF @Subtotal IS NULL OR @Subtotal <= 0
            THROW 51110, N'No se puede confirmar una venta sin detalle.', 1;

        SET @IVA = CONVERT(DECIMAL(14,2), ROUND(@Subtotal * 0.13, 2));

        UPDATE dbo.Ventas
           SET Subtotal = @Subtotal,
               IVA = @IVA,
               Total = @Subtotal + @IVA,
               Estado = 'CONFIRMADA'
        WHERE IdVenta = @IdVenta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarEntradaInventario
    @IdProducto INT,
    @Cantidad INT,
    @CostoUnitario DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 51111, N'La entrada debe ser mayor que cero.', 1;
        IF @CostoUnitario IS NOT NULL AND @CostoUnitario < 0
            THROW 51112, N'El costo no puede ser negativo.', 1;

        BEGIN TRANSACTION;

        UPDATE dbo.Productos
           SET Stock = Stock + @Cantidad,
               CostoUnitario = COALESCE(@CostoUnitario, CostoUnitario)
        WHERE IdProducto = @IdProducto AND Activo = 1;

        IF @@ROWCOUNT <> 1
            THROW 51113, N'No se encontró un producto activo para ingresar inventario.', 1;

        INSERT INTO dbo.MovimientosInventario(IdProducto, Tipo, Cantidad, UsuarioBD)
        VALUES (@IdProducto, 'ENTRADA', @Cantidad, USER_NAME());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_AnularVenta
    @IdVenta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Ventas WITH (UPDLOCK, HOLDLOCK)
            WHERE IdVenta = @IdVenta AND Estado IN ('BORRADOR','CONFIRMADA')
        )
            THROW 51114, N'La venta no existe o ya fue anulada.', 1;

        ;WITH Devolucion AS
        (
            SELECT IdProducto, SUM(Cantidad) AS Cantidad
            FROM dbo.DetalleVenta
            WHERE IdVenta = @IdVenta
            GROUP BY IdProducto
        )
        UPDATE p
           SET p.Stock = p.Stock + d.Cantidad
        FROM dbo.Productos AS p
        INNER JOIN Devolucion AS d ON d.IdProducto = p.IdProducto;

        INSERT INTO dbo.MovimientosInventario(IdProducto, IdVenta, Tipo, Cantidad, UsuarioBD)
        SELECT IdProducto, @IdVenta, 'DEVOLUCION', SUM(Cantidad), USER_NAME()
        FROM dbo.DetalleVenta
        WHERE IdVenta = @IdVenta
        GROUP BY IdProducto;

        UPDATE dbo.Ventas SET Estado = 'ANULADA' WHERE IdVenta = @IdVenta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ActualizarPrecioProducto
    @IdProducto INT,
    @NuevoPrecio DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @NuevoPrecio IS NULL OR @NuevoPrecio <= 0
        THROW 51115, N'El precio debe ser mayor que cero.', 1;

    UPDATE dbo.Productos
       SET PrecioVenta = @NuevoPrecio
    WHERE IdProducto = @IdProducto AND Activo = 1;

    IF @@ROWCOUNT <> 1
        THROW 51116, N'No existe el producto activo.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarCliente
    @Nombres NVARCHAR(100),
    @Apellidos NVARCHAR(100),
    @Telefono NVARCHAR(20) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @IdCliente INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@Nombres)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Apellidos)), N'') IS NULL
        THROW 51117, N'Debes ingresar nombres y apellidos.', 1;

    IF @Correo IS NOT NULL AND (@Correo NOT LIKE N'%_@_%._%' OR @Correo LIKE N'% %')
        THROW 51118, N'El formato del correo no es válido.', 1;

    INSERT INTO dbo.Clientes(Nombres, Apellidos, Telefono, Correo)
    VALUES (LTRIM(RTRIM(@Nombres)), LTRIM(RTRIM(@Apellidos)), @Telefono, NULLIF(LTRIM(RTRIM(@Correo)), N''));

    SET @IdCliente = CONVERT(INT, SCOPE_IDENTITY());
END;
GO
