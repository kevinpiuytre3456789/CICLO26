USE BuenPan_ASB404;
GO
CREATE ROLE rol_cajero AUTHORIZATION dbo;
CREATE ROLE rol_inventario AUTHORIZATION dbo;
CREATE ROLE rol_gerencia AUTHORIZATION dbo;
GO
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarVenta TO rol_cajero;
GRANT EXECUTE ON OBJECT::dbo.usp_AgregarProductoVenta TO rol_cajero;
GRANT EXECUTE ON OBJECT::dbo.usp_ConfirmarVenta TO rol_cajero;
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarCliente TO rol_cajero;
GRANT SELECT ON OBJECT::dbo.vw_CatalogoProductos TO rol_cajero;
GRANT SELECT ON OBJECT::dbo.vw_DetalleVentas TO rol_cajero;
GO
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarEntradaInventario TO rol_inventario;
GRANT EXECUTE ON OBJECT::dbo.usp_ActualizarPrecioProducto TO rol_inventario;
GRANT SELECT ON OBJECT::dbo.vw_CatalogoProductos TO rol_inventario;
GRANT SELECT ON OBJECT::dbo.vw_StockCritico TO rol_inventario;
GRANT SELECT ON OBJECT::dbo.vw_MovimientosInventario TO rol_inventario;
GO
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarVenta TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_AgregarProductoVenta TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_ConfirmarVenta TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarEntradaInventario TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_AnularVenta TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_ActualizarPrecioProducto TO rol_gerencia;
GRANT EXECUTE ON OBJECT::dbo.usp_RegistrarCliente TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_CatalogoProductos TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_ResumenVentasDiarias TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_DetalleVentas TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_StockCritico TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_TopProductos TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_ClientesFrecuentes TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_MovimientosInventario TO rol_gerencia;
GRANT SELECT ON OBJECT::dbo.vw_RentabilidadProductos TO rol_gerencia;
GO
CREATE USER demo_cajero WITHOUT LOGIN;
CREATE USER demo_inventario WITHOUT LOGIN;
CREATE USER demo_gerencia WITHOUT LOGIN;
GO
ALTER ROLE rol_cajero ADD MEMBER demo_cajero;
ALTER ROLE rol_inventario ADD MEMBER demo_inventario;
ALTER ROLE rol_gerencia ADD MEMBER demo_gerencia;
GO
