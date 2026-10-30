-- ============================================================
-- UNIVERSIDAD DON BOSCO
-- ASB404 - Desafío Práctico #2
-- Sistema de Gestión para Supermercado “SuperAhorro”
-- Carnets: FC260104
-- Motor: Microsoft SQL Server / SQL Server Management Studio (SSMS)
-- ============================================================

IF DB_ID('SuperAhorro_C260104') IS NOT NULL
BEGIN
    ALTER DATABASE SuperAhorro_C260104 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SuperAhorro_C260104;
END;
GO

CREATE DATABASE SuperAhorro_C260104;
GO

USE SuperAhorro_C260104;
GO

-- ============================================================
-- 1. CREACIÓN DE TABLAS
-- ============================================================

CREATE TABLE Categoria (
    CategoriaID VARCHAR(10) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE Proveedor (
    ProveedorID VARCHAR(10) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL UNIQUE,
    Telefono VARCHAR(20) NOT NULL UNIQUE,
    Direccion NVARCHAR(200) NOT NULL
);

CREATE TABLE Producto (
    ProductoID VARCHAR(10) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL UNIQUE,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    CategoriaID VARCHAR(10) NOT NULL,
    ProveedorID VARCHAR(10) NOT NULL,
    CONSTRAINT chk_producto_precio CHECK (Precio > 0),
    CONSTRAINT chk_producto_stock CHECK (Stock >= 0),
    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (CategoriaID) REFERENCES Categoria(CategoriaID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_producto_proveedor
        FOREIGN KEY (ProveedorID) REFERENCES Proveedor(ProveedorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Cliente (
    ClienteID VARCHAR(10) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL,
    Apellido NVARCHAR(80) NOT NULL,
    Email VARCHAR(120) NOT NULL UNIQUE,
    Telefono VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Empleado (
    EmpleadoID VARCHAR(10) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL,
    Apellido NVARCHAR(80) NOT NULL,
    Cargo NVARCHAR(80) NOT NULL DEFAULT N'Cajero',
    Salario DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_empleado_salario CHECK (Salario > 0)
);

CREATE TABLE Venta (
    VentaID VARCHAR(10) PRIMARY KEY,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ClienteID VARCHAR(10) NOT NULL,
    EmpleadoID VARCHAR(10) NOT NULL,
    Total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT chk_venta_total CHECK (Total >= 0),
    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (ClienteID) REFERENCES Cliente(ClienteID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_venta_empleado
        FOREIGN KEY (EmpleadoID) REFERENCES Empleado(EmpleadoID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE DetalleVenta (
    VentaID VARCHAR(10) NOT NULL,
    ProductoID VARCHAR(10) NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (VentaID, ProductoID),
    CONSTRAINT chk_detalle_cantidad CHECK (Cantidad > 0),
    CONSTRAINT chk_detalle_precio CHECK (PrecioUnitario > 0),
    CONSTRAINT chk_detalle_subtotal CHECK (Subtotal >= 0),
    CONSTRAINT fk_detalle_venta
        FOREIGN KEY (VentaID) REFERENCES Venta(VentaID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (ProductoID) REFERENCES Producto(ProductoID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Índices auxiliares para mejorar consultas y JOINs frecuentes.
CREATE INDEX idx_producto_categoria ON Producto(CategoriaID);
CREATE INDEX idx_producto_proveedor ON Producto(ProveedorID);
CREATE INDEX idx_venta_fecha ON Venta(Fecha);
CREATE INDEX idx_venta_empleado ON Venta(EmpleadoID);
CREATE INDEX idx_detalle_producto ON DetalleVenta(ProductoID);

-- ============================================================
-- 2. INSERCIÓN DE DATOS (>5 registros por tabla)
-- ============================================================

INSERT INTO Categoria (CategoriaID, Nombre) VALUES
('CAT01', N'Abarrotes'),
('CAT02', N'Bebidas'),
('CAT03', N'Lácteos'),
('CAT04', N'Limpieza'),
('CAT05', N'Cuidado Personal'),
('CAT06', N'Panadería'),
('CAT07', N'Frutas y Verduras');

INSERT INTO Proveedor (ProveedorID, Nombre, Telefono, Direccion) VALUES
('PROV01', N'Distribuidora Centroamericana', '2201-1001', N'San Salvador'),
('PROV02', N'Bebidas del Pacífico', '2201-1002', N'Santa Tecla'),
('PROV03', N'Lácteos Salvadoreños', '2201-1003', N'Antiguo Cuscatlán'),
('PROV04', N'Higiene y Hogar SV', '2201-1004', N'Soyapango'),
('PROV05', N'Panificadora Nacional', '2201-1005', N'Mejicanos'),
('PROV06', N'AgroMercado El Salvador', '2201-1006', N'La Libertad');

INSERT INTO Producto (ProductoID, Nombre, Precio, Stock, CategoriaID, ProveedorID) VALUES
('PROD01', N'Arroz Premium 1 kg',       1.35,  80, 'CAT01', 'PROV01'),
('PROD02', N'Frijol Rojo 1 kg',         1.60,  55, 'CAT01', 'PROV01'),
('PROD03', N'Azúcar Blanca 1 kg',       1.20,  40, 'CAT01', 'PROV01'),
('PROD04', N'Gaseosa Cola 2 L',         2.10,  35, 'CAT02', 'PROV02'),
('PROD05', N'Agua Purificada 1.5 L',    0.85,   8, 'CAT02', 'PROV02'),
('PROD06', N'Leche Entera 1 L',         1.45,  25, 'CAT03', 'PROV03'),
('PROD07', N'Queso Fresco 1 lb',        3.75,   9, 'CAT03', 'PROV03'),
('PROD08', N'Detergente 1 kg',          2.95,  18, 'CAT04', 'PROV04'),
('PROD09', N'Jabón de Baño',            0.95,   7, 'CAT05', 'PROV04'),
('PROD10', N'Shampoo 400 ml',           4.50,  22, 'CAT05', 'PROV04'),
('PROD11', N'Pan de Caja',              2.25,  15, 'CAT06', 'PROV05'),
('PROD12', N'Manzana Roja Unidad',      0.50,  60, 'CAT07', 'PROV06'),
('PROD13', N'Banano Unidad',            0.20, 100, 'CAT07', 'PROV06'),
('PROD14', N'Jugo de Naranja 1 L',      1.95,  14, 'CAT02', 'PROV02'),
('PROD15', N'Suavizante 1 L',           2.80,   6, 'CAT04', 'PROV04');

INSERT INTO Cliente (ClienteID, Nombre, Apellido, Email, Telefono) VALUES
('CLI01', 'Ana',     N'Martínez',  'ana.martinez@email.com',   '7000-1001'),
('CLI02', 'Carlos',  N'Hernández', 'carlos.hernandez@email.com','7000-1002'),
('CLI03', N'María',   N'López',     'maria.lopez@email.com',     '7000-1003'),
('CLI04', N'José',    N'Ramírez',   'jose.ramirez@email.com',    '7000-1004'),
('CLI05', N'Sofía',   N'Gómez',     'sofia.gomez@email.com',     '7000-1005'),
('CLI06', 'Daniel',  'Flores',    'daniel.flores@email.com',   '7000-1006'),
('CLI07', 'Valeria', 'Castro',    'valeria.castro@email.com',  '7000-1007');

INSERT INTO Empleado (EmpleadoID, Nombre, Apellido, Cargo, Salario) VALUES
('EMP01', 'Luis',    N'Pérez',    N'Cajero',      500.00),
('EMP02', 'Andrea',  N'Méndez',   N'Cajero',      500.00),
('EMP03', 'Roberto', N'García',   N'Supervisor',  750.00),
('EMP04', 'Paola',   'Rivas',    N'Cajero',      525.00),
('EMP05', 'Miguel',  'Torres',   N'Bodeguero',   575.00),
('EMP06', 'Elena',   N'Vásquez',  N'Gerente',    1100.00);

-- Las ventas incluyen registros de abril de 2026 para la consulta solicitada.
INSERT INTO Venta (VentaID, Fecha, ClienteID, EmpleadoID, Total) VALUES
('V001', '2026-04-02 09:15:00', 'CLI01', 'EMP01',  8.60),
('V002', '2026-04-05 11:40:00', 'CLI02', 'EMP02', 10.75),
('V003', '2026-04-10 15:20:00', 'CLI03', 'EMP01', 15.30),
('V004', '2026-04-18 17:05:00', 'CLI01', 'EMP04', 13.35),
('V005', '2026-04-25 10:30:00', 'CLI05', 'EMP01', 18.85),
('V006', '2026-05-03 13:10:00', 'CLI04', 'EMP02', 12.60),
('V007', '2026-05-08 18:25:00', 'CLI06', 'EMP03', 11.70),
('V008', '2026-06-01 08:50:00', 'CLI07', 'EMP04',  9.75),
('V009', '2026-06-06 16:45:00', 'CLI01', 'EMP01', 22.55),
('V010', '2026-06-12 19:05:00', 'CLI02', 'EMP05', 17.35);

INSERT INTO DetalleVenta (VentaID, ProductoID, Cantidad, PrecioUnitario, Subtotal) VALUES
-- V001 = 8.60
('V001', 'PROD01', 2, 1.35, 2.70),
('V001', 'PROD04', 1, 2.10, 2.10),
('V001', 'PROD12', 4, 0.50, 2.00),
('V001', 'PROD09', 1, 0.95, 0.95),
('V001', 'PROD05', 1, 0.85, 0.85),
-- V002 = 10.75
('V002', 'PROD06', 2, 1.45, 2.90),
('V002', 'PROD07', 1, 3.75, 3.75),
('V002', 'PROD11', 1, 2.25, 2.25),
('V002', 'PROD13', 5, 0.20, 1.00),
('V002', 'PROD05', 1, 0.85, 0.85),
-- V003 = 15.30
('V003', 'PROD10', 2, 4.50, 9.00),
('V003', 'PROD08', 1, 2.95, 2.95),
('V003', 'PROD03', 2, 1.20, 2.40),
('V003', 'PROD09', 1, 0.95, 0.95),
-- V004 = 13.35
('V004', 'PROD02', 2, 1.60, 3.20),
('V004', 'PROD14', 2, 1.95, 3.90),
('V004', 'PROD11', 1, 2.25, 2.25),
('V004', 'PROD12', 4, 0.50, 2.00),
('V004', 'PROD13', 10, 0.20, 2.00),
-- V005 = 18.85
('V005', 'PROD04', 3, 2.10, 6.30),
('V005', 'PROD06', 3, 1.45, 4.35),
('V005', 'PROD10', 1, 4.50, 4.50),
('V005', 'PROD01', 2, 1.35, 2.70),
('V005', 'PROD13', 5, 0.20, 1.00),
-- V006 = 12.60
('V006', 'PROD08', 2, 2.95, 5.90),
('V006', 'PROD15', 1, 2.80, 2.80),
('V006', 'PROD14', 2, 1.95, 3.90),
-- V007 = 11.70
('V007', 'PROD07', 2, 3.75, 7.50),
('V007', 'PROD12', 6, 0.50, 3.00),
('V007', 'PROD13', 6, 0.20, 1.20),
-- V008 = 9.75
('V008', 'PROD11', 2, 2.25, 4.50),
('V008', 'PROD06', 2, 1.45, 2.90),
('V008', 'PROD09', 1, 0.95, 0.95),
('V008', 'PROD13', 7, 0.20, 1.40),
-- V009 = 22.55
('V009', 'PROD10', 2, 4.50, 9.00),
('V009', 'PROD07', 2, 3.75, 7.50),
('V009', 'PROD04', 2, 2.10, 4.20),
('V009', 'PROD05', 1, 0.85, 0.85),
('V009', 'PROD13', 5, 0.20, 1.00),
-- V010 = 17.35
('V010', 'PROD01', 3, 1.35, 4.05),
('V010', 'PROD02', 3, 1.60, 4.80),
('V010', 'PROD03', 2, 1.20, 2.40),
('V010', 'PROD08', 2, 2.95, 5.90),
('V010', 'PROD13', 1, 0.20, 0.20);

-- ============================================================
-- 3. CONSULTAS SOLICITADAS
-- ============================================================

-- 1) Listar todos los productos con su categoría y proveedor.
SELECT
    p.ProductoID,
    p.Nombre AS Producto,
    c.Nombre AS Categoria,
    pr.Nombre AS Proveedor,
    p.Precio,
    p.Stock
FROM Producto p
INNER JOIN Categoria c ON p.CategoriaID = c.CategoriaID
INNER JOIN Proveedor pr ON p.ProveedorID = pr.ProveedorID
ORDER BY p.ProductoID;

-- 2) Mostrar las ventas realizadas por el empleado con ID 'EMP01'.
SELECT
    v.VentaID,
    v.Fecha,
    CONCAT(cl.Nombre, ' ', cl.Apellido) AS Cliente,
    CONCAT(e.Nombre, ' ', e.Apellido) AS Empleado,
    v.Total
FROM Venta v
INNER JOIN Cliente cl ON v.ClienteID = cl.ClienteID
INNER JOIN Empleado e ON v.EmpleadoID = e.EmpleadoID
WHERE v.EmpleadoID = 'EMP01'
ORDER BY v.Fecha;

-- 3) Contar cuántos productos hay por categoría.
SELECT
    c.CategoriaID,
    c.Nombre AS Categoria,
    COUNT(p.ProductoID) AS CantidadProductos
FROM Categoria c
LEFT JOIN Producto p ON c.CategoriaID = p.CategoriaID
GROUP BY c.CategoriaID, c.Nombre
ORDER BY CantidadProductos DESC, c.Nombre;

-- 4) Listar clientes que han comprado más de 3 productos diferentes.
SELECT
    cl.ClienteID,
    CONCAT(cl.Nombre, ' ', cl.Apellido) AS Cliente,
    COUNT(DISTINCT dv.ProductoID) AS ProductosDiferentes
FROM Cliente cl
INNER JOIN Venta v ON cl.ClienteID = v.ClienteID
INNER JOIN DetalleVenta dv ON v.VentaID = dv.VentaID
GROUP BY cl.ClienteID, cl.Nombre, cl.Apellido
HAVING COUNT(DISTINCT dv.ProductoID) > 3
ORDER BY ProductosDiferentes DESC;

-- 5) Mostrar el producto más vendido (en cantidad).
SELECT TOP 1
    p.ProductoID,
    p.Nombre AS Producto,
    SUM(dv.Cantidad) AS CantidadVendida
FROM Producto p
INNER JOIN DetalleVenta dv ON p.ProductoID = dv.ProductoID
GROUP BY p.ProductoID, p.Nombre
ORDER BY CantidadVendida DESC;

-- 6) Calcular el total de ventas del mes de abril de 2026.
SELECT
    ROUND(SUM(Total), 2) AS TotalVentasAbril2026
FROM Venta
WHERE Fecha >= '2026-04-01'
  AND Fecha <  '2026-05-01';

-- 7) Listar proveedores que suministran más de 2 productos.
SELECT
    pr.ProveedorID,
    pr.Nombre AS Proveedor,
    COUNT(p.ProductoID) AS ProductosSuministrados
FROM Proveedor pr
INNER JOIN Producto p ON pr.ProveedorID = p.ProveedorID
GROUP BY pr.ProveedorID, pr.Nombre
HAVING COUNT(p.ProductoID) > 2
ORDER BY ProductosSuministrados DESC, pr.Nombre;

-- 8) Actualizar el stock del producto 'PROD10' restando 5 unidades.
-- La condición Stock >= 5 evita que el stock quede negativo.
UPDATE Producto
SET Stock = Stock - 5
WHERE ProductoID = 'PROD10'
  AND Stock >= 5;

-- Verificación de la actualización.
SELECT ProductoID, Nombre, Stock
FROM Producto
WHERE ProductoID = 'PROD10';

-- 9) Mostrar el cliente que más ha gastado en total.
SELECT TOP 1
    cl.ClienteID,
    CONCAT(cl.Nombre, ' ', cl.Apellido) AS Cliente,
    ROUND(SUM(v.Total), 2) AS TotalGastado
FROM Cliente cl
INNER JOIN Venta v ON cl.ClienteID = v.ClienteID
GROUP BY cl.ClienteID, cl.Nombre, cl.Apellido
ORDER BY TotalGastado DESC;

-- 10) Listar productos con stock menor a 10 unidades.
SELECT
    ProductoID,
    Nombre,
    Stock,
    Precio
FROM Producto
WHERE Stock < 10
ORDER BY Stock ASC, Nombre;

-- ============================================================
-- 4. CONSULTAS DE CONTROL / VALIDACIÓN
-- ============================================================

-- Validar que el total guardado por venta coincide con la suma de sus detalles.
SELECT
    v.VentaID,
    v.Total AS TotalRegistrado,
    ROUND(SUM(dv.Subtotal), 2) AS TotalCalculado,
    ROUND(v.Total - SUM(dv.Subtotal), 2) AS Diferencia
FROM Venta v
INNER JOIN DetalleVenta dv ON v.VentaID = dv.VentaID
GROUP BY v.VentaID, v.Total
ORDER BY v.VentaID;

-- ============================================================
-- 5. DECLARACIÓN DE USO DE IA (solicitada en la guía)
-- ============================================================
-- Herramienta utilizada: ChatGPT (OpenAI).
-- Uso realizado: apoyo para estructurar el script T-SQL para SQL Server, validar relaciones,
-- restricciones, datos de prueba y consultas solicitadas en el desafío para ejecutarlo en SSMS.
-- Prompt utilizado:
-- "Crear el Desafío Práctico #2 de ASB404 en Microsoft SQL Server para el sistema de supermercado
-- SuperAhorro, incluyendo creación de base de datos, las 7 tablas indicadas,
-- PK, FK, CHECK, DEFAULT, UNIQUE, ON DELETE/UPDATE CASCADE, más de 5 registros
-- coherentes por tabla y las 10 consultas requeridas. Carnet: C260104."
-- ============================================================
