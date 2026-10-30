USE BuenPan_ASB404;
GO
SELECT N'Cantidad de objetos del proyecto' AS Demostracion;
SELECT o.type_desc AS TipoObjeto, COUNT(*) AS Cantidad
FROM sys.objects AS o
WHERE o.is_ms_shipped = 0 AND o.type IN ('U','V','P','TR')
GROUP BY o.type_desc
ORDER BY o.type_desc;
SELECT N'Ocho tablas y su número de registros' AS Demostracion;
SELECT N'Categorias' AS Tabla, COUNT(*) AS Registros FROM dbo.Categorias
UNION ALL SELECT N'Productos', COUNT(*) FROM dbo.Productos
UNION ALL SELECT N'Clientes', COUNT(*) FROM dbo.Clientes
UNION ALL SELECT N'Empleados', COUNT(*) FROM dbo.Empleados
UNION ALL SELECT N'Ventas', COUNT(*) FROM dbo.Ventas
UNION ALL SELECT N'DetalleVenta', COUNT(*) FROM dbo.DetalleVenta
UNION ALL SELECT N'MovimientosInventario', COUNT(*) FROM dbo.MovimientosInventario
UNION ALL SELECT N'AuditoriaProductos', COUNT(*) FROM dbo.AuditoriaProductos;
SELECT N'Productos relacionados con categorías' AS Demostracion;
SELECT TOP (10) p.Codigo, p.Nombre AS Producto, c.Nombre AS Categoria, p.PrecioVenta, p.Stock
FROM dbo.Productos AS p
INNER JOIN dbo.Categorias AS c ON c.IdCategoria=p.IdCategoria
ORDER BY p.IdProducto;
SELECT N'Llaves foráneas entre tablas' AS Demostracion;
SELECT fk.name AS Relacion, OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaReferenciada
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id IN
(
    SELECT object_id FROM sys.tables WHERE schema_id=SCHEMA_ID('dbo')
)
ORDER BY TablaHija, TablaReferenciada;
GO
