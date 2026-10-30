USE BuenPan_ASB404;
GO
CREATE OR ALTER VIEW dbo.vw_CatalogoProductos
AS
SELECT p.IdProducto, p.Codigo, p.Nombre AS Producto, c.Nombre AS Categoria,
       p.PrecioVenta, p.Stock, p.StockMinimo,
       CASE WHEN p.Stock <= p.StockMinimo THEN N'REPOSICIÓN' ELSE N'DISPONIBLE' END AS EstadoInventario
FROM dbo.Productos AS p
INNER JOIN dbo.Categorias AS c ON c.IdCategoria = p.IdCategoria
WHERE p.Activo = 1;
GO
CREATE OR ALTER VIEW dbo.vw_ResumenVentasDiarias
AS
SELECT CONVERT(DATE, Fecha) AS Fecha,
       COUNT(*) AS NumeroVentas,
       SUM(Subtotal) AS Subtotal,
       SUM(IVA) AS IVA,
       SUM(Total) AS Total,
       CONVERT(DECIMAL(14,2), AVG(Total)) AS TicketPromedio
FROM dbo.Ventas
WHERE Estado = 'CONFIRMADA'
GROUP BY CONVERT(DATE, Fecha);
GO
CREATE OR ALTER VIEW dbo.vw_DetalleVentas
AS
SELECT v.IdVenta, v.Fecha, v.Estado,
       COALESCE(c.Nombres + N' ' + c.Apellidos, N'Consumidor final') AS Cliente,
       e.Nombres + N' ' + e.Apellidos AS Empleado,
       p.Codigo, p.Nombre AS Producto,
       d.Cantidad, d.PrecioUnitario, d.Subtotal AS TotalLinea,
       v.Total AS TotalVenta
FROM dbo.DetalleVenta AS d
INNER JOIN dbo.Ventas AS v ON v.IdVenta = d.IdVenta
INNER JOIN dbo.Empleados AS e ON e.IdEmpleado = v.IdEmpleado
LEFT JOIN dbo.Clientes AS c ON c.IdCliente = v.IdCliente
INNER JOIN dbo.Productos AS p ON p.IdProducto = d.IdProducto;
GO
CREATE OR ALTER VIEW dbo.vw_StockCritico
AS
SELECT p.IdProducto, p.Codigo, p.Nombre AS Producto, c.Nombre AS Categoria,
       p.Stock, p.StockMinimo,
       p.StockMinimo - p.Stock AS UnidadesPorReponer
FROM dbo.Productos AS p
INNER JOIN dbo.Categorias AS c ON c.IdCategoria = p.IdCategoria
WHERE p.Activo = 1 AND p.Stock <= p.StockMinimo;
GO
CREATE OR ALTER VIEW dbo.vw_TopProductos
AS
SELECT p.IdProducto, p.Codigo, p.Nombre AS Producto,
       SUM(d.Cantidad) AS UnidadesVendidas,
       SUM(d.Subtotal) AS VentaSinIVA,
       COUNT(DISTINCT v.IdVenta) AS VentasDistintas
FROM dbo.DetalleVenta AS d
INNER JOIN dbo.Ventas AS v ON v.IdVenta = d.IdVenta
INNER JOIN dbo.Productos AS p ON p.IdProducto = d.IdProducto
WHERE v.Estado = 'CONFIRMADA'
GROUP BY p.IdProducto, p.Codigo, p.Nombre;
GO
CREATE OR ALTER VIEW dbo.vw_ClientesFrecuentes
AS
SELECT c.IdCliente, c.Nombres + N' ' + c.Apellidos AS Cliente,
       COUNT(v.IdVenta) AS ComprasRealizadas,
       SUM(v.Total) AS TotalComprado,
       CONVERT(DECIMAL(14,2), AVG(v.Total)) AS CompraPromedio
FROM dbo.Clientes AS c
INNER JOIN dbo.Ventas AS v ON v.IdCliente = c.IdCliente
WHERE v.Estado = 'CONFIRMADA'
GROUP BY c.IdCliente, c.Nombres, c.Apellidos;
GO
CREATE OR ALTER VIEW dbo.vw_MovimientosInventario
AS
SELECT m.IdMovimiento, m.Fecha, p.Codigo, p.Nombre AS Producto,
       m.Tipo, m.Cantidad, m.IdVenta, m.UsuarioBD
FROM dbo.MovimientosInventario AS m
INNER JOIN dbo.Productos AS p ON p.IdProducto = m.IdProducto;
GO
CREATE OR ALTER VIEW dbo.vw_RentabilidadProductos
AS
SELECT p.Codigo, p.Nombre AS Producto, p.CostoUnitario, p.PrecioVenta,
       p.PrecioVenta - p.CostoUnitario AS MargenUnitario,
       CONVERT(DECIMAL(7,2), (p.PrecioVenta - p.CostoUnitario) * 100.0 / p.PrecioVenta) AS MargenPorcentaje
FROM dbo.Productos AS p
WHERE p.Activo = 1;
GO
