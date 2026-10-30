/*
============================================================
UNIVERSIDAD DON BOSCO
ASB404 - Guía de Laboratorio Nº 9
Tema: Procedimientos Almacenados y Vistas
Carnet usado: FC260104
Motor: Microsoft SQL Server / SQL Server Management Studio
============================================================
*/

------------------------------------------------------------
-- PARTE 1 - NORTHWIND
------------------------------------------------------------
USE Northwind;
GO

/* ========================================================
   EJERCICIO 1
   Procedimiento para insertar categorías solo si no existe
   el código o el nombre recibido.
   ======================================================== */

IF OBJECT_ID('dbo.sp_Insertar_CategoriasFC260104', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Insertar_CategoriasFC260104;
GO

CREATE PROCEDURE dbo.sp_Insertar_CategoriasFC260104
    @ID INT,
    @NombreCategoria VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM dbo.Categories
        WHERE CategoryID = @ID
           OR CategoryName = @NombreCategoria
    ) = 0
    BEGIN
        INSERT INTO dbo.Categories(CategoryName)
        VALUES (@NombreCategoria);

        PRINT 'Categoría insertada correctamente';
    END
    ELSE
    BEGIN
        PRINT 'Error, la categoría ya existe';
    END
END;
GO

-- Pruebas del ejercicio 1
EXEC dbo.sp_Insertar_CategoriasFC260104 1, 'Alimentos';
GO
EXEC dbo.sp_Insertar_CategoriasFC260104 9, 'Alimentos';
GO
EXEC dbo.sp_Insertar_CategoriasFC260104 10, 'Alimentos';
GO

SELECT * FROM dbo.Categories;
GO


/* ========================================================
   EJERCICIO 2
   Verificar si existen clientes en una ciudad.
   ======================================================== */

IF OBJECT_ID('dbo.sp_HayClientesFC260104', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HayClientesFC260104;
GO

CREATE PROCEDURE dbo.sp_HayClientesFC260104
    @ciudad VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE
            WHEN (SELECT COUNT(*) FROM dbo.Customers WHERE City = @ciudad) = 0
                THEN 'No hay clientes en la ciudad de ' + @ciudad
            ELSE 'Hay clientes en la ciudad de ' + @ciudad
        END AS Resultado;
END;
GO

-- Pruebas del ejercicio 2
EXEC dbo.sp_HayClientesFC260104 'Barcelona';
GO
EXEC dbo.sp_HayClientesFC260104 @ciudad = 'New York';
GO


/* ========================================================
   EJERCICIO 3
   Total de ventas por pedido.
   ======================================================== */

IF OBJECT_ID('dbo.sp_Total_Ventas_FC260104', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Total_Ventas_FC260104;
GO

-- Primera versión: total de todos los pedidos
CREATE PROCEDURE dbo.sp_Total_Ventas_FC260104
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OrderID,
        SUM(CONVERT(MONEY, (UnitPrice * Quantity * (1 - Discount) / 100)) * 100) AS Total
    FROM dbo.[Order Details]
    GROUP BY OrderID;
END;
GO

EXEC dbo.sp_Total_Ventas_FC260104;
GO


-- Segunda versión: recibe un código de pedido
ALTER PROCEDURE dbo.sp_Total_Ventas_FC260104
    @Cod_orden INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OrderID,
        SUM(CONVERT(MONEY, (UnitPrice * Quantity * (1 - Discount) / 100)) * 100) AS Total
    FROM dbo.[Order Details]
    WHERE OrderID = @Cod_orden
    GROUP BY OrderID;
END;
GO

-- Pedido existente
EXEC dbo.sp_Total_Ventas_FC260104 10248;
GO

-- Pedido que normalmente no existe según la guía
EXEC dbo.sp_Total_Ventas_FC260104 10242;
GO


-- Tercera versión: valida si la orden existe
ALTER PROCEDURE dbo.sp_Total_Ventas_FC260104
    @Cod_orden INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.[Order Details]
    WHERE OrderID = @Cod_orden;

    IF (@total >= 1)
    BEGIN
        SELECT
            OrderID,
            SUM(CONVERT(MONEY, (UnitPrice * Quantity * (1 - Discount) / 100)) * 100) AS Total
        FROM dbo.[Order Details]
        WHERE OrderID = @Cod_orden
        GROUP BY OrderID;
    END
    ELSE
    BEGIN
        PRINT 'La orden no existe, el código es: ' + CONVERT(VARCHAR(10), @Cod_orden);
    END
END;
GO

EXEC dbo.sp_Total_Ventas_FC260104 10248;
GO
EXEC dbo.sp_Total_Ventas_FC260104 10242;
GO


------------------------------------------------------------
-- CREACIÓN DE VISTAS
------------------------------------------------------------

/* Vista A:
   Código del producto, nombre y precio por unidad.
*/
IF OBJECT_ID('dbo.vw_Productos_Precio_FC260104', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Productos_Precio_FC260104;
GO

CREATE VIEW dbo.vw_Productos_Precio_FC260104
AS
SELECT
    ProductID AS CodigoProducto,
    ProductName AS NombreProducto,
    UnitPrice AS PrecioUnidad
FROM dbo.Products;
GO

SELECT * FROM dbo.vw_Productos_Precio_FC260104;
GO


/* Vista B:
   Productos cuya categoría sea Beverages.
*/
IF OBJECT_ID('dbo.vw_Productos_Beverages_FC260104', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Productos_Beverages_FC260104;
GO

CREATE VIEW dbo.vw_Productos_Beverages_FC260104
AS
SELECT
    P.ProductID,
    P.ProductName,
    P.SupplierID,
    P.CategoryID,
    P.QuantityPerUnit,
    P.UnitPrice,
    P.UnitsInStock,
    P.UnitsOnOrder,
    P.ReorderLevel,
    P.Discontinued
FROM dbo.Products AS P
INNER JOIN dbo.Categories AS C
    ON P.CategoryID = C.CategoryID
WHERE C.CategoryName = 'Beverages';
GO

SELECT * FROM dbo.vw_Productos_Beverages_FC260104;
GO


/* Vista C:
   Datos del cliente y fechas de las órdenes realizadas.
*/
IF OBJECT_ID('dbo.vw_Clientes_Ordenes_FC260104', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Clientes_Ordenes_FC260104;
GO

CREATE VIEW dbo.vw_Clientes_Ordenes_FC260104
AS
SELECT
    C.CustomerID,
    C.CompanyName,
    C.ContactName,
    C.ContactTitle,
    C.Address,
    C.City,
    C.Region,
    C.PostalCode,
    C.Country,
    C.Phone,
    O.OrderID,
    O.OrderDate,
    O.RequiredDate,
    O.ShippedDate
FROM dbo.Customers AS C
INNER JOIN dbo.Orders AS O
    ON C.CustomerID = O.CustomerID;
GO

SELECT * FROM dbo.vw_Clientes_Ordenes_FC260104;
GO


/* Vista D:
   Cantidad de productos por cada categoría.
*/
IF OBJECT_ID('dbo.vw_Cantidad_Productos_Categoria_FC260104', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Cantidad_Productos_Categoria_FC260104;
GO

CREATE VIEW dbo.vw_Cantidad_Productos_Categoria_FC260104
AS
SELECT
    C.CategoryID,
    C.CategoryName,
    COUNT(P.ProductID) AS CantidadProductos
FROM dbo.Categories AS C
LEFT JOIN dbo.Products AS P
    ON C.CategoryID = P.CategoryID
GROUP BY C.CategoryID, C.CategoryName;
GO

SELECT * FROM dbo.vw_Cantidad_Productos_Categoria_FC260104;
GO


/* Vista E:
   Promedio de precios unitarios de Produce y Confections.
*/
IF OBJECT_ID('dbo.vw_Promedio_Precios_Categorias_FC260104', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Promedio_Precios_Categorias_FC260104;
GO

CREATE VIEW dbo.vw_Promedio_Precios_Categorias_FC260104
AS
SELECT
    C.CategoryName,
    CAST(AVG(CAST(P.UnitPrice AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS PromedioPrecio
FROM dbo.Categories AS C
INNER JOIN dbo.Products AS P
    ON C.CategoryID = P.CategoryID
WHERE C.CategoryName IN ('Produce', 'Confections')
GROUP BY C.CategoryName;
GO

SELECT * FROM dbo.vw_Promedio_Precios_Categorias_FC260104;
GO


------------------------------------------------------------
-- EJERCICIO COMPLEMENTARIO 2
-- Procedimiento que calcula la edad de un empleado
------------------------------------------------------------

IF OBJECT_ID('dbo.sp_Edad_Empleado_FC260104', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Edad_Empleado_FC260104;
GO

CREATE PROCEDURE dbo.sp_Edad_Empleado_FC260104
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.Employees
        WHERE EmployeeID = @EmployeeID
    )
    BEGIN
        SELECT
            EmployeeID,
            FirstName,
            LastName,
            BirthDate,
            CAST(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25 AS INT) AS Edad,
            CASE
                WHEN CAST(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25 AS INT) > 70
                    THEN 'El empleado ya está jubilado'
                WHEN CAST(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25 AS INT) > 60
                     AND CAST(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25 AS INT) <= 70
                    THEN 'El empleado está por retirarse'
                ELSE 'Al empleado todavía le faltan años para retirarse'
            END AS EstadoLaboral
        FROM dbo.Employees
        WHERE EmployeeID = @EmployeeID;
    END
    ELSE
    BEGIN
        PRINT 'El empleado con código ' + CONVERT(VARCHAR(10), @EmployeeID) + ' no existe';
    END
END;
GO

-- Pruebas
EXEC dbo.sp_Edad_Empleado_FC260104 1;
GO
EXEC dbo.sp_Edad_Empleado_FC260104 999;
GO


------------------------------------------------------------
-- EJEMPLO TRY - CATCH DE LA GUÍA
------------------------------------------------------------
BEGIN TRY
    DECLARE @valor INT;
    SET @valor = 7;
    SELECT @valor / 0;
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS Numero_de_Error,
        ERROR_SEVERITY() AS Gravedad_del_Error,
        ERROR_STATE() AS Estado_del_Error,
        ERROR_PROCEDURE() AS Procedimiento_del_Error,
        ERROR_LINE() AS Linea_de_Error,
        ERROR_MESSAGE() AS Mensaje_de_Error;
END CATCH;
GO


------------------------------------------------------------
-- PARTE 2 - BASE DE DATOS BODEGA
------------------------------------------------------------

IF DB_ID('Bodega') IS NOT NULL
BEGIN
    ALTER DATABASE Bodega SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Bodega;
END;
GO

CREATE DATABASE Bodega;
GO

USE Bodega;
GO


------------------------------------------------------------
-- TABLAS
------------------------------------------------------------
CREATE TABLE dbo.PRODUCTO
(
    idprod CHAR(7) PRIMARY KEY,
    descripcion VARCHAR(25) NOT NULL,
    existencias INT NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    preciov DECIMAL(10,2) NOT NULL,
    ganancia AS (preciov - precio),
    CONSTRAINT CK_PRODUCTO_EXISTENCIAS CHECK (existencias >= 0),
    CONSTRAINT CK_PRODUCTO_PRECIOS CHECK (preciov > precio)
);
GO

CREATE TABLE dbo.PEDIDO
(
    idpedido CHAR(7) NOT NULL,
    idprod CHAR(7) NOT NULL,
    cantidad INT NOT NULL,
    CONSTRAINT PK_PEDIDO PRIMARY KEY (idpedido),
    CONSTRAINT FK_PEDIDO_PRODUCTO FOREIGN KEY(idprod)
        REFERENCES dbo.PRODUCTO(idprod),
    CONSTRAINT CK_PEDIDO_CANTIDAD CHECK (cantidad > 0)
);
GO


------------------------------------------------------------
-- DATOS DE PRUEBA
------------------------------------------------------------
INSERT INTO dbo.PRODUCTO(idprod, descripcion, existencias, precio, preciov)
VALUES
('P000001', 'Arroz 1 lb',       50, 0.80, 1.10),
('P000002', 'Frijol 1 lb',      40, 1.00, 1.35),
('P000003', 'Aceite 750 ml',    25, 2.00, 2.65),
('P000004', 'Azucar 1 lb',      60, 0.70, 1.00),
('P000005', 'Cafe 200 g',       20, 2.50, 3.25);
GO

SELECT * FROM dbo.PRODUCTO;
GO


------------------------------------------------------------
-- BODEGA - EJERCICIO 1
-- Insertar productos verificando código y descripción
------------------------------------------------------------

CREATE PROCEDURE dbo.sp_Insertar_Producto_FC260104
    @idprod CHAR(7),
    @descripcion VARCHAR(25),
    @existencias INT,
    @precio DECIMAL(10,2),
    @preciov DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.PRODUCTO
        WHERE idprod = @idprod
           OR descripcion = @descripcion
    )
    BEGIN
        PRINT 'ESTE PRODUCTO YA HA SIDO INGRESADO';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO dbo.PRODUCTO(idprod, descripcion, existencias, precio, preciov)
        VALUES (@idprod, @descripcion, @existencias, @precio, @preciov);

        PRINT 'PRODUCTO INGRESADO CORRECTAMENTE';
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS NumeroError,
            ERROR_MESSAGE() AS MensajeError;
    END CATCH
END;
GO

-- Pruebas
EXEC dbo.sp_Insertar_Producto_FC260104
    'P000006', 'Galletas', 30, 0.50, 0.75;
GO

-- Prueba duplicada
EXEC dbo.sp_Insertar_Producto_FC260104
    'P000006', 'Galletas', 30, 0.50, 0.75;
GO

SELECT * FROM dbo.PRODUCTO;
GO


------------------------------------------------------------
-- BODEGA - EJERCICIO 2
-- Realizar pedidos y actualizar existencias
------------------------------------------------------------

CREATE PROCEDURE dbo.sp_Realizar_Pedido_FC260104
    @idpedido CHAR(7),
    @idprod CHAR(7),
    @cantidad INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar código de pedido duplicado
    IF EXISTS (
        SELECT 1
        FROM dbo.PEDIDO
        WHERE idpedido = @idpedido
    )
    BEGIN
        PRINT 'EL CÓDIGO DEL PEDIDO YA EXISTE';
        RETURN;
    END;

    -- Validar que el producto exista
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.PRODUCTO
        WHERE idprod = @idprod
    )
    BEGIN
        PRINT 'ESTE PRODUCTO NO EXISTE';
        RETURN;
    END;

    -- Validar cantidad
    IF @cantidad <= 0
    BEGIN
        PRINT 'LA CANTIDAD DEBE SER MAYOR QUE CERO';
        RETURN;
    END;

    DECLARE @existenciaActual INT;

    SELECT @existenciaActual = existencias
    FROM dbo.PRODUCTO
    WHERE idprod = @idprod;

    IF @cantidad > @existenciaActual
    BEGIN
        PRINT 'EXISTENCIA DEL PRODUCTO INSUFICIENTE';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PEDIDO(idpedido, idprod, cantidad)
        VALUES (@idpedido, @idprod, @cantidad);

        UPDATE dbo.PRODUCTO
        SET existencias = existencias - @cantidad
        WHERE idprod = @idprod;

        COMMIT TRANSACTION;

        PRINT 'PEDIDO REGISTRADO CORRECTAMENTE';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT
            ERROR_NUMBER() AS NumeroError,
            ERROR_MESSAGE() AS MensajeError;
    END CATCH
END;
GO

-- Prueba 1: producto existente y existencia suficiente
EXEC dbo.sp_Realizar_Pedido_FC260104
    'PD00001', 'P000001', 5;
GO

-- Prueba 2: producto que no existe
EXEC dbo.sp_Realizar_Pedido_FC260104
    'PD00002', 'P999999', 2;
GO

-- Prueba 3: existencia insuficiente
EXEC dbo.sp_Realizar_Pedido_FC260104
    'PD00003', 'P000003', 1000;
GO

-- Ver resultados finales
SELECT * FROM dbo.PEDIDO;
GO

SELECT * FROM dbo.PRODUCTO;
GO


------------------------------------------------------------
-- ANÁLISIS DE RESULTADOS (consultas de apoyo)
------------------------------------------------------------

-- 1. Los procedimientos permiten encapsular lógica SQL y reutilizarla.
-- 2. IF/ELSE permite validar existencia de datos antes de insertar.
-- 3. CASE permite devolver resultados diferentes según una condición.
-- 4. TRY/CATCH permite capturar errores de ejecución.
-- 5. Las vistas permiten guardar consultas para reutilizarlas.
-- 6. En Bodega, el procedimiento de pedido descuenta existencias solo
--    cuando el producto existe y hay cantidad suficiente.
-- 7. La transacción del pedido evita que se inserte el pedido sin
--    actualizar correctamente las existencias.

PRINT 'Guía 9 ejecutada. Revise la pestaña Results y Messages.';
GO
