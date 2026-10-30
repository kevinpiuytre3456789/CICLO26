-- Complemento para la aplicación. No elimina datos ni modifica los permisos de escritura existentes.
USE BuenPan_ASB404;
GO
IF OBJECT_ID(N'dbo.UsuariosApp', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UsuariosApp (
        IdUsuario INT IDENTITY PRIMARY KEY,
        Usuario NVARCHAR(40) NOT NULL UNIQUE,
        Nombre NVARCHAR(100) NOT NULL,
        Rol VARCHAR(15) NOT NULL CHECK (Rol IN ('gerencia','cajero','inventario')),
        ClaveHash VARCHAR(64) NOT NULL,
        Sal VARCHAR(64) NOT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO
CREATE OR ALTER VIEW dbo.vw_AppClientes AS
SELECT IdCliente,Nombres,Apellidos,Telefono,Correo FROM dbo.Clientes WHERE Activo=1;
GO
CREATE OR ALTER VIEW dbo.vw_AppEmpleados AS
SELECT IdEmpleado,Nombres,Apellidos,Cargo FROM dbo.Empleados WHERE Activo=1;
GO
CREATE OR ALTER VIEW dbo.vw_AppVentas AS
SELECT v.IdVenta,v.Fecha,v.Estado,v.Subtotal,v.IVA,v.Total,
 COALESCE(c.Nombres+N' '+c.Apellidos,N'Consumidor final') Cliente,
 e.Nombres+N' '+e.Apellidos Empleado
FROM dbo.Ventas v LEFT JOIN dbo.Clientes c ON c.IdCliente=v.IdCliente
JOIN dbo.Empleados e ON e.IdEmpleado=v.IdEmpleado;
GO
CREATE OR ALTER VIEW dbo.vw_AppAuditoria AS
SELECT a.*,p.Nombre Producto FROM dbo.AuditoriaProductos a
JOIN dbo.Productos p ON p.IdProducto=a.IdProducto;
GO
GRANT SELECT ON dbo.vw_AppClientes TO rol_cajero,rol_gerencia;
GRANT SELECT ON dbo.vw_AppEmpleados TO rol_cajero,rol_gerencia;
GRANT SELECT ON dbo.vw_AppVentas TO rol_cajero,rol_gerencia;
GRANT SELECT ON dbo.vw_AppAuditoria TO rol_gerencia;
-- Solo gerencia necesita comprobar la disponibilidad de los triggers y procedimientos.
GRANT VIEW DEFINITION TO rol_gerencia;
GO
