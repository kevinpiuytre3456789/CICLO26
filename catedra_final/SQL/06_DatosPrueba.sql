USE BuenPan_ASB404;
GO
INSERT INTO dbo.Categorias (Nombre, Descripcion)
VALUES (N'Panes', N'Panes artesanales y tradicionales'),
       (N'Repostería', N'Postres frescos y pasteles'),
       (N'Bebidas', N'Bebidas calientes y frías'),
       (N'Galletas', N'Galletas de elaboración diaria');
GO
INSERT INTO dbo.Productos (IdCategoria, Codigo, Nombre, PrecioVenta, CostoUnitario, Stock, StockMinimo)
VALUES (1,N'PAN001',N'Pan francés',0.20,0.10,160,20),
       (1,N'PAN002',N'Pan dulce surtido',0.45,0.22,90,15),
       (1,N'PAN003',N'Pan integral',1.30,0.75,25,8),
       (1,N'PAN004',N'Baguette artesanal',1.75,0.95,15,6),
       (2,N'REP001',N'Porción de pastel de chocolate',2.75,1.40,20,5),
       (2,N'REP002',N'Quesadilla salvadoreña',1.50,0.80,8,8),
       (3,N'BEB001',N'Café americano',1.10,0.40,70,10),
       (3,N'BEB002',N'Chocolate caliente',1.60,0.65,30,8),
       (4,N'GAL001',N'Galleta de avena',0.70,0.30,55,10),
       (4,N'GAL002',N'Galleta de mantequilla',0.60,0.24,45,10);
GO
INSERT INTO dbo.Clientes(Nombres, Apellidos, Telefono, Correo)
VALUES (N'Ana',N'Martínez',N'7010-1001',N'ana.martinez@example.com'),
       (N'Carlos',N'Pérez',N'7010-1002',N'carlos.perez@example.com'),
       (N'María',N'López',N'7010-1003',N'maria.lopez@example.com'),
       (N'José',N'Ramírez',N'7010-1004',N'jose.ramirez@example.com'),
       (N'Lucía',N'Hernández',N'7010-1005',N'lucia.hernandez@example.com'),
       (N'Daniel',N'Morales',N'7010-1006',N'daniel.morales@example.com');
GO
INSERT INTO dbo.Empleados(Codigo, Nombres, Apellidos, Cargo)
VALUES (N'EMP001',N'Sofía',N'Gómez',N'Cajera'),
       (N'EMP002',N'Luis',N'Rivera',N'Cajero'),
       (N'EMP003',N'Valeria',N'Torres',N'Encargada de inventario'),
       (N'EMP004',N'Óscar',N'Mendoza',N'Gerente');
GO
DECLARE @VentaA INT, @VentaB INT, @VentaC INT, @VentaD INT;
EXEC dbo.usp_RegistrarVenta @IdCliente=1, @IdEmpleado=1, @IdProducto=1, @Cantidad=10, @IdVenta=@VentaA OUTPUT;
EXEC dbo.usp_AgregarProductoVenta @IdVenta=@VentaA, @IdProducto=7, @Cantidad=2;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@VentaA;
EXEC dbo.usp_RegistrarVenta @IdCliente=2, @IdEmpleado=2, @IdProducto=5, @Cantidad=2, @IdVenta=@VentaB OUTPUT;
EXEC dbo.usp_AgregarProductoVenta @IdVenta=@VentaB, @IdProducto=9, @Cantidad=4;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@VentaB;
EXEC dbo.usp_RegistrarVenta @IdCliente=1, @IdEmpleado=1, @IdProducto=2, @Cantidad=6, @IdVenta=@VentaC OUTPUT;
EXEC dbo.usp_AgregarProductoVenta @IdVenta=@VentaC, @IdProducto=6, @Cantidad=1;
EXEC dbo.usp_ConfirmarVenta @IdVenta=@VentaC;
EXEC dbo.usp_RegistrarVenta @IdCliente=3, @IdEmpleado=2, @IdProducto=8, @Cantidad=2, @IdVenta=@VentaD OUTPUT;
EXEC dbo.usp_AnularVenta @IdVenta=@VentaD;
EXEC dbo.usp_RegistrarEntradaInventario @IdProducto=6, @Cantidad=12, @CostoUnitario=0.85;
GO
SELECT (SELECT COUNT(*) FROM dbo.Categorias) AS Categorias,
       (SELECT COUNT(*) FROM dbo.Productos) AS Productos,
       (SELECT COUNT(*) FROM dbo.Clientes) AS Clientes,
       (SELECT COUNT(*) FROM dbo.Empleados) AS Empleados,
       (SELECT COUNT(*) FROM dbo.Ventas) AS Ventas,
       (SELECT COUNT(*) FROM dbo.MovimientosInventario) AS Movimientos,
       (SELECT COUNT(*) FROM dbo.AuditoriaProductos) AS Auditorias;
GO
