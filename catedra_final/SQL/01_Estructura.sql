IF DB_ID(N'BuenPan_ASB404') IS NOT NULL
    THROW 51000, N'La base BuenPan_ASB404 ya existe. Ejecuta este instalador solo en un entorno nuevo.', 1;
GO
CREATE DATABASE BuenPan_ASB404;
GO
USE BuenPan_ASB404;
GO
CREATE TABLE dbo.Categorias
(
    IdCategoria INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categorias PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL CONSTRAINT UQ_Categorias_Nombre UNIQUE,
    Descripcion NVARCHAR(240) NULL,
    Activa BIT NOT NULL CONSTRAINT DF_Categorias_Activa DEFAULT (1),
    CONSTRAINT CK_Categorias_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO
CREATE TABLE dbo.Productos
(
    IdProducto INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Productos PRIMARY KEY,
    IdCategoria INT NOT NULL,
    Codigo NVARCHAR(20) NOT NULL CONSTRAINT UQ_Productos_Codigo UNIQUE,
    Nombre NVARCHAR(120) NOT NULL,
    PrecioVenta DECIMAL(12,2) NOT NULL,
    CostoUnitario DECIMAL(12,2) NOT NULL,
    Stock INT NOT NULL CONSTRAINT DF_Productos_Stock DEFAULT (0),
    StockMinimo INT NOT NULL CONSTRAINT DF_Productos_StockMinimo DEFAULT (5),
    Activo BIT NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT (1),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Productos_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Productos_Categorias FOREIGN KEY (IdCategoria) REFERENCES dbo.Categorias (IdCategoria),
    CONSTRAINT CK_Productos_Precio CHECK (PrecioVenta > 0),
    CONSTRAINT CK_Productos_Costo CHECK (CostoUnitario >= 0),
    CONSTRAINT CK_Productos_Stock CHECK (Stock >= 0),
    CONSTRAINT CK_Productos_StockMinimo CHECK (StockMinimo >= 0),
    CONSTRAINT CK_Productos_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO
CREATE TABLE dbo.Clientes
(
    IdCliente INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clientes PRIMARY KEY,
    Nombres NVARCHAR(100) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    Telefono NVARCHAR(20) NULL,
    Correo NVARCHAR(150) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Clientes_Activo DEFAULT (1),
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Clientes_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Clientes_Nombres CHECK (LEN(LTRIM(RTRIM(Nombres))) > 0),
    CONSTRAINT CK_Clientes_Apellidos CHECK (LEN(LTRIM(RTRIM(Apellidos))) > 0),
    CONSTRAINT CK_Clientes_Correo CHECK (Correo IS NULL OR (Correo LIKE N'%_@_%._%' AND Correo NOT LIKE N'% %'))
);
GO
CREATE UNIQUE INDEX UX_Clientes_Correo ON dbo.Clientes(Correo) WHERE Correo IS NOT NULL;
GO
CREATE TABLE dbo.Empleados
(
    IdEmpleado INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Empleados PRIMARY KEY,
    Codigo NVARCHAR(15) NOT NULL CONSTRAINT UQ_Empleados_Codigo UNIQUE,
    Nombres NVARCHAR(100) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    Cargo NVARCHAR(60) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Empleados_Activo DEFAULT (1),
    CONSTRAINT CK_Empleados_Nombres CHECK (LEN(LTRIM(RTRIM(Nombres))) > 0),
    CONSTRAINT CK_Empleados_Apellidos CHECK (LEN(LTRIM(RTRIM(Apellidos))) > 0)
);
GO
CREATE TABLE dbo.Ventas
(
    IdVenta INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ventas PRIMARY KEY,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Ventas_Fecha DEFAULT (SYSDATETIME()),
    IdCliente INT NULL,
    IdEmpleado INT NOT NULL,
    Estado VARCHAR(12) NOT NULL CONSTRAINT DF_Ventas_Estado DEFAULT ('BORRADOR'),
    Subtotal DECIMAL(14,2) NOT NULL CONSTRAINT DF_Ventas_Subtotal DEFAULT (0),
    IVA DECIMAL(14,2) NOT NULL CONSTRAINT DF_Ventas_IVA DEFAULT (0),
    Total DECIMAL(14,2) NOT NULL CONSTRAINT DF_Ventas_Total DEFAULT (0),
    CONSTRAINT FK_Ventas_Clientes FOREIGN KEY (IdCliente) REFERENCES dbo.Clientes(IdCliente),
    CONSTRAINT FK_Ventas_Empleados FOREIGN KEY (IdEmpleado) REFERENCES dbo.Empleados(IdEmpleado),
    CONSTRAINT CK_Ventas_Estado CHECK (Estado IN ('BORRADOR','CONFIRMADA','ANULADA')),
    CONSTRAINT CK_Ventas_Montos CHECK (Subtotal >= 0 AND IVA >= 0 AND Total >= 0 AND Total = Subtotal + IVA)
);
GO
CREATE TABLE dbo.DetalleVenta
(
    IdDetalle INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DetalleVenta PRIMARY KEY,
    IdVenta INT NOT NULL,
    IdProducto INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(12,2) NOT NULL,
    Subtotal AS CONVERT(DECIMAL(14,2), Cantidad * PrecioUnitario) PERSISTED,
    CONSTRAINT FK_DetalleVenta_Ventas FOREIGN KEY (IdVenta) REFERENCES dbo.Ventas(IdVenta),
    CONSTRAINT FK_DetalleVenta_Productos FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT UQ_DetalleVenta_VentaProducto UNIQUE (IdVenta, IdProducto),
    CONSTRAINT CK_DetalleVenta_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleVenta_Precio CHECK (PrecioUnitario > 0)
);
GO
CREATE TABLE dbo.MovimientosInventario
(
    IdMovimiento BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MovimientosInventario PRIMARY KEY,
    IdProducto INT NOT NULL,
    IdVenta INT NULL,
    Tipo VARCHAR(12) NOT NULL,
    Cantidad INT NOT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Movimientos_Fecha DEFAULT (SYSDATETIME()),
    UsuarioBD SYSNAME NOT NULL CONSTRAINT DF_Movimientos_Usuario DEFAULT (USER_NAME()),
    CONSTRAINT FK_Movimientos_Productos FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT FK_Movimientos_Ventas FOREIGN KEY (IdVenta) REFERENCES dbo.Ventas(IdVenta),
    CONSTRAINT CK_Movimientos_Tipo CHECK (Tipo IN ('ENTRADA','SALIDA','DEVOLUCION')),
    CONSTRAINT CK_Movimientos_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_Movimientos_Venta CHECK ((Tipo = 'ENTRADA' AND IdVenta IS NULL) OR (Tipo IN ('SALIDA','DEVOLUCION') AND IdVenta IS NOT NULL))
);
GO
CREATE TABLE dbo.AuditoriaProductos
(
    IdAuditoria BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditoriaProductos PRIMARY KEY,
    IdProducto INT NOT NULL,
    Campo NVARCHAR(35) NOT NULL,
    ValorAnterior NVARCHAR(100) NULL,
    ValorNuevo NVARCHAR(100) NULL,
    UsuarioBD SYSNAME NOT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Auditoria_Productos FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto)
);
GO
CREATE INDEX IX_Productos_Categoria ON dbo.Productos(IdCategoria);
CREATE INDEX IX_Ventas_FechaEstado ON dbo.Ventas(Fecha, Estado) INCLUDE (Total, IdCliente, IdEmpleado);
CREATE INDEX IX_DetalleVenta_Producto ON dbo.DetalleVenta(IdProducto);
CREATE INDEX IX_Movimientos_ProductoFecha ON dbo.MovimientosInventario(IdProducto, Fecha);
CREATE INDEX IX_Auditoria_ProductoFecha ON dbo.AuditoriaProductos(IdProducto, Fecha);
GO
