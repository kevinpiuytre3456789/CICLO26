USE BuenPan_ASB404;
GO
SELECT N'Vista 1: catálogo de productos' AS Demostracion;
SELECT * FROM dbo.vw_CatalogoProductos ORDER BY Producto;
SELECT N'Vista 2: resumen de ventas diarias' AS Demostracion;
SELECT * FROM dbo.vw_ResumenVentasDiarias ORDER BY Fecha DESC;
SELECT N'Vista 3: detalle de ventas' AS Demostracion;
SELECT TOP (20) * FROM dbo.vw_DetalleVentas ORDER BY IdVenta DESC;
SELECT N'Vista 4: stock crítico' AS Demostracion;
SELECT * FROM dbo.vw_StockCritico ORDER BY UnidadesPorReponer DESC;
SELECT N'Vista 5: productos más vendidos' AS Demostracion;
SELECT * FROM dbo.vw_TopProductos ORDER BY UnidadesVendidas DESC;
SELECT N'Vista 6: clientes frecuentes' AS Demostracion;
SELECT * FROM dbo.vw_ClientesFrecuentes ORDER BY TotalComprado DESC;
SELECT N'Vista 7: movimientos de inventario' AS Demostracion;
SELECT TOP (20) * FROM dbo.vw_MovimientosInventario ORDER BY IdMovimiento DESC;
SELECT N'Vista 8: rentabilidad por producto' AS Demostracion;
SELECT * FROM dbo.vw_RentabilidadProductos ORDER BY MargenPorcentaje DESC;
GO
