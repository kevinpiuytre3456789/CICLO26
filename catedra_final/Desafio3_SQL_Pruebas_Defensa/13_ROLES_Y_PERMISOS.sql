USE BuenPan_ASB404;
GO
SELECT N'Los tres roles y usuarios de demostración' AS Demostracion;
SELECT r.name AS Rol, u.name AS Usuario
FROM sys.database_role_members AS m
INNER JOIN sys.database_principals AS r ON r.principal_id=m.role_principal_id
INNER JOIN sys.database_principals AS u ON u.principal_id=m.member_principal_id
WHERE r.name IN (N'rol_cajero',N'rol_inventario',N'rol_gerencia')
ORDER BY r.name;
SELECT N'Permisos configurados por objeto' AS Demostracion;
SELECT dp2.name AS Rol, o.name AS Objeto, p.permission_name AS Permiso
FROM sys.database_permissions AS p
INNER JOIN sys.database_principals AS dp2 ON dp2.principal_id=p.grantee_principal_id
INNER JOIN sys.objects AS o ON o.object_id=p.major_id
WHERE dp2.name IN (N'rol_cajero',N'rol_inventario',N'rol_gerencia')
ORDER BY dp2.name,o.name;
GO
EXECUTE AS USER=N'demo_cajero';
SELECT N'Prueba usuario CAJERO' AS Demostracion,USER_NAME() AS UsuarioActual,
    HAS_PERMS_BY_NAME(N'dbo.usp_RegistrarVenta',N'OBJECT',N'EXECUTE') AS PuedeRegistrarVentas,
    HAS_PERMS_BY_NAME(N'dbo.usp_RegistrarEntradaInventario',N'OBJECT',N'EXECUTE') AS PuedeIngresarStock,
    HAS_PERMS_BY_NAME(N'dbo.vw_CatalogoProductos',N'OBJECT',N'SELECT') AS PuedeVerCatalogo;
SELECT TOP(2) * FROM dbo.vw_CatalogoProductos;
REVERT;
GO
EXECUTE AS USER=N'demo_inventario';
SELECT N'Prueba usuario INVENTARIO' AS Demostracion,USER_NAME() AS UsuarioActual,
    HAS_PERMS_BY_NAME(N'dbo.usp_RegistrarVenta',N'OBJECT',N'EXECUTE') AS PuedeRegistrarVentas,
    HAS_PERMS_BY_NAME(N'dbo.usp_RegistrarEntradaInventario',N'OBJECT',N'EXECUTE') AS PuedeIngresarStock,
    HAS_PERMS_BY_NAME(N'dbo.vw_StockCritico',N'OBJECT',N'SELECT') AS PuedeConsultarStock;
REVERT;
GO
EXECUTE AS USER=N'demo_gerencia';
SELECT N'Prueba usuario GERENCIA' AS Demostracion,USER_NAME() AS UsuarioActual,
    HAS_PERMS_BY_NAME(N'dbo.usp_AnularVenta',N'OBJECT',N'EXECUTE') AS PuedeAnularVentas,
    HAS_PERMS_BY_NAME(N'dbo.vw_RentabilidadProductos',N'OBJECT',N'SELECT') AS PuedeVerRentabilidad;
SELECT TOP(2) * FROM dbo.vw_RentabilidadProductos;
REVERT;
GO
