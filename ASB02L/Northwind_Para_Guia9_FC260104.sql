/*
============================================================
NORTHWIND COMPATIBLE PARA ASB404 - GUIA 9
Carnet: FC260104
Motor: Microsoft SQL Server
IMPORTANTE: Este script BORRA la base Northwind si existe
y la vuelve a crear desde cero con datos suficientes para
realizar los ejercicios de la Guia 9.
============================================================
*/

USE master;
GO

IF DB_ID('Northwind') IS NOT NULL
BEGIN
    ALTER DATABASE Northwind SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Northwind;
END;
GO

CREATE DATABASE Northwind;
GO

USE Northwind;
GO

/* ===========================
   TABLA CATEGORIES
   =========================== */
CREATE TABLE dbo.Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(15) NOT NULL UNIQUE,
    Description NTEXT NULL
);
GO

INSERT INTO dbo.Categories(CategoryName, Description)
VALUES
('Beverages', 'Soft drinks, coffees, teas, beers, and ales'),
('Condiments', 'Sweet and savory sauces'),
('Confections', 'Desserts, candies, and sweet breads'),
('Dairy Products', 'Cheeses'),
('Grains/Cereals', 'Breads, crackers, pasta, and cereal'),
('Meat/Poultry', 'Prepared meats'),
('Produce', 'Dried fruit and bean curd'),
('Seafood', 'Seaweed and fish');
GO


/* ===========================
   TABLA CUSTOMERS
   =========================== */
CREATE TABLE dbo.Customers
(
    CustomerID NCHAR(5) PRIMARY KEY,
    CompanyName NVARCHAR(40) NOT NULL,
    ContactName NVARCHAR(30) NULL,
    ContactTitle NVARCHAR(30) NULL,
    Address NVARCHAR(60) NULL,
    City NVARCHAR(15) NULL,
    Region NVARCHAR(15) NULL,
    PostalCode NVARCHAR(10) NULL,
    Country NVARCHAR(15) NULL,
    Phone NVARCHAR(24) NULL
);
GO

INSERT INTO dbo.Customers
(CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone)
VALUES
('ALFKI', 'Alfreds Futterkiste', 'Maria Anders', 'Sales Representative',
 'Obere Str. 57', 'Berlin', NULL, '12209', 'Germany', '030-0074321'),

('LON01', 'London Market', 'John Smith', 'Owner',
 '10 King Street', 'London', NULL, 'SW1A1AA', 'UK', '020-100000'),

('NYC01', 'New York Foods', 'Susan Brown', 'Manager',
 '120 Madison Ave', 'New York', 'NY', '10010', 'USA', '212-555-0101'),

('MAD01', 'Madrid Gourmet', 'Carlos Ruiz', 'Owner',
 'Calle Mayor 10', 'Madrid', NULL, '28013', 'Spain', '91-555-0101');
GO


/* ===========================
   TABLA PRODUCTS
   =========================== */
CREATE TABLE dbo.Products
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(40) NOT NULL,
    SupplierID INT NULL,
    CategoryID INT NULL,
    QuantityPerUnit NVARCHAR(20) NULL,
    UnitPrice MONEY NULL,
    UnitsInStock SMALLINT NULL,
    UnitsOnOrder SMALLINT NULL,
    ReorderLevel SMALLINT NULL,
    Discontinued BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Products_Categories
        FOREIGN KEY(CategoryID) REFERENCES dbo.Categories(CategoryID)
);
GO

INSERT INTO dbo.Products
(ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued)
VALUES
('Chai', 1, 1, '10 boxes x 20 bags', 18.00, 39, 0, 10, 0),
('Chang', 1, 1, '24 - 12 oz bottles', 19.00, 17, 40, 25, 0),
('Chocolate Biscuits', 2, 3, '10 boxes x 12 pieces', 12.50, 30, 0, 10, 0),
('Gummy Bears', 2, 3, '20 bags x 10 pieces', 15.00, 22, 0, 5, 0),
('Dried Pears', 3, 7, '12 boxes', 30.00, 15, 0, 5, 0),
('Green Apples', 3, 7, '20 kg box', 25.00, 40, 0, 10, 0),
('Cheddar Cheese', 4, 4, '10 packs', 22.00, 18, 0, 5, 0),
('Salmon', 5, 8, '12 fillets', 35.00, 12, 0, 5, 0);
GO


/* ===========================
   TABLA EMPLOYEES
   =========================== */
CREATE TABLE dbo.Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    LastName NVARCHAR(20) NOT NULL,
    FirstName NVARCHAR(10) NOT NULL,
    Title NVARCHAR(30) NULL,
    BirthDate DATETIME NULL,
    HireDate DATETIME NULL,
    Address NVARCHAR(60) NULL,
    City NVARCHAR(15) NULL,
    Country NVARCHAR(15) NULL
);
GO

INSERT INTO dbo.Employees
(LastName, FirstName, Title, BirthDate, HireDate, Address, City, Country)
VALUES
('Davolio', 'Nancy', 'Sales Representative', '1948-12-08', '1992-05-01',
 '507 - 20th Ave. E.', 'Seattle', 'USA'),
('Fuller', 'Andrew', 'Vice President', '1952-02-19', '1992-08-14',
 '908 W. Capital Way', 'Tacoma', 'USA'),
('Leverling', 'Janet', 'Sales Representative', '1963-08-30', '1992-04-01',
 '722 Moss Bay Blvd.', 'Kirkland', 'USA');
GO


/* ===========================
   TABLA ORDERS
   =========================== */
CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    CustomerID NCHAR(5) NULL,
    EmployeeID INT NULL,
    OrderDate DATETIME NULL,
    RequiredDate DATETIME NULL,
    ShippedDate DATETIME NULL,
    ShipName NVARCHAR(40) NULL,
    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY(CustomerID) REFERENCES dbo.Customers(CustomerID),
    CONSTRAINT FK_Orders_Employees
        FOREIGN KEY(EmployeeID) REFERENCES dbo.Employees(EmployeeID)
);
GO

INSERT INTO dbo.Orders
(OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate, ShipName)
VALUES
(10248, 'ALFKI', 1, '1996-07-04', '1996-08-01', '1996-07-16', 'Alfreds Futterkiste'),
(10249, 'LON01', 2, '1996-07-05', '1996-08-16', '1996-07-10', 'London Market'),
(10250, 'NYC01', 1, '1996-07-08', '1996-08-05', '1996-07-12', 'New York Foods'),
(10251, 'MAD01', 3, '1996-07-08', '1996-08-05', '1996-07-15', 'Madrid Gourmet');
GO


/* ===========================
   TABLA ORDER DETAILS
   =========================== */
CREATE TABLE dbo.[Order Details]
(
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice MONEY NOT NULL,
    Quantity SMALLINT NOT NULL,
    Discount REAL NOT NULL DEFAULT 0,
    CONSTRAINT PK_OrderDetails PRIMARY KEY(OrderID, ProductID),
    CONSTRAINT FK_OrderDetails_Orders
        FOREIGN KEY(OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products
        FOREIGN KEY(ProductID) REFERENCES dbo.Products(ProductID)
);
GO

INSERT INTO dbo.[Order Details]
(OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES
(10248, 1, 18.00, 12, 0),
(10248, 3, 12.50, 10, 0),
(10248, 5, 30.00, 5, 0.10),

(10249, 2, 19.00, 10, 0),
(10249, 7, 22.00, 6, 0),

(10250, 1, 18.00, 8, 0.05),
(10250, 6, 25.00, 4, 0),

(10251, 4, 15.00, 10, 0),
(10251, 8, 35.00, 3, 0.10);
GO


/* ===========================
   COMPROBACIONES
   =========================== */
PRINT 'Northwind creada correctamente.';
GO

SELECT * FROM dbo.Categories;
SELECT * FROM dbo.Customers;
SELECT * FROM dbo.Products;
SELECT * FROM dbo.Employees;
SELECT * FROM dbo.Orders;
SELECT * FROM dbo.[Order Details];
GO
