/* =====================================================================
   UNIVERSIDAD DON BOSCO
   ASB404 - GUIA DE LABORATORIO No. 5
   NORMALIZACION Y TABLAS RELACIONALES

   CARNET: FC260104

   SCRIPT COMPLETO:
   EJERCICIO 1
   EJERCICIO 2
   EJERCICIO 3
   EJERCICIO 4
   EJERCICIO 5
   EJERCICIO COMPLEMENTARIO - PELICULAS
   ANALISIS DE RESULTADOS - CLIENTE / PRODUCTO / COMPRA

   ===================================================================== */


/***********************************************************************
                     PARTE 1
             EJERCICIOS 1 AL 5 DE LA GUIA
                 GESTION DE LIBROS
************************************************************************/


/***********************************************************************
 EJERCICIO 1 - CREAR LA BASE DE DATOS

 La guía solicita:
 Gestion_Libros_SuCarnet

 Se utiliza el carnet del estudiante:
 FC260104

 Por tanto:
 Gestion_Libros_FC260104
************************************************************************/

USE master;
GO

IF DB_ID('Gestion_Libros_FC260104') IS NOT NULL
BEGIN
    ALTER DATABASE Gestion_Libros_FC260104
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE Gestion_Libros_FC260104;
END
GO

CREATE DATABASE Gestion_Libros_FC260104;
GO

USE Gestion_Libros_FC260104;
GO


/***********************************************************************
 EJERCICIO 2 - CREAR LAS TABLAS

 TABLAS:
    Autor
    Libro
    Editorial
    Detalle_AutorLibro

 Relaciones:
    Editorial 1 ---- N Libro
    Autor     1 ---- N Detalle_AutorLibro
    Libro     1 ---- N Detalle_AutorLibro
************************************************************************/


/* =========================
   TABLA AUTOR
   ========================= */

CREATE TABLE Autor
(
    CodigoAutor CHAR(5) NOT NULL,
    PrimerNombre VARCHAR(25) NULL,
    PrimerApellido VARCHAR(30) NULL,
    FechaNacimiento DATE NULL,
    Nacionalidad VARCHAR(35) NULL
);
GO


/* =========================
   TABLA LIBRO
   ========================= */

CREATE TABLE Libro
(
    CodigoLibro CHAR(10) NOT NULL,
    Titulo VARCHAR(MAX) NULL,
    ISBN VARCHAR(20) NOT NULL,
    AñoEdicion CHAR(4) NULL,
    CodigoEditorial CHAR(5) NULL
);
GO


/* =========================
   TABLA EDITORIAL
   ========================= */

CREATE TABLE Editorial
(
    CodigoEditorial CHAR(5) NOT NULL,
    Nombre VARCHAR(45) NULL,
    Pais VARCHAR(50) NULL
);
GO


/* =========================
   TABLA INTERMEDIA
   ========================= */

CREATE TABLE Detalle_AutorLibro
(
    CodigoAutor CHAR(5) NULL,
    CodigoLibro CHAR(10) NULL,
    Fecha DATE NULL
);
GO


/***********************************************************************
 EJERCICIO 3 - CLAVES PRIMARIAS
************************************************************************/


/* PRIMARY KEY DE AUTOR */

ALTER TABLE Autor
ADD CONSTRAINT PK_CodigoAutor
PRIMARY KEY (CodigoAutor);
GO


/* PRIMARY KEY DE LIBRO */

ALTER TABLE Libro
ADD CONSTRAINT PK_CodigoLibro
PRIMARY KEY (CodigoLibro);
GO


/* PRIMARY KEY DE EDITORIAL */

ALTER TABLE Editorial
ADD CONSTRAINT PK_CodigoEditorial
PRIMARY KEY (CodigoEditorial);
GO


/* PRIMARY KEY COMPUESTA DE LA TABLA INTERMEDIA

   La combinación Autor + Libro identifica una relación.
*/

ALTER TABLE Detalle_AutorLibro
ADD CONSTRAINT PK_Detalle_AutorLibro
PRIMARY KEY (CodigoAutor, CodigoLibro);
GO


/***********************************************************************
 EJERCICIO 3 - CLAVES FORANEAS
************************************************************************/


/* Relación Autor -> Detalle_AutorLibro */

ALTER TABLE Detalle_AutorLibro
ADD CONSTRAINT FK_Detalle_AutorLibro_Autor
FOREIGN KEY (CodigoAutor)
REFERENCES Autor(CodigoAutor);
GO


/* Relación Libro -> Detalle_AutorLibro */

ALTER TABLE Detalle_AutorLibro
ADD CONSTRAINT FK_Detalle_AutorLibro_Libro
FOREIGN KEY (CodigoLibro)
REFERENCES Libro(CodigoLibro);
GO


/* Relación Editorial -> Libro */

ALTER TABLE Libro
ADD CONSTRAINT FK_LibroEditorial
FOREIGN KEY (CodigoEditorial)
REFERENCES Editorial(CodigoEditorial);
GO


/***********************************************************************
 EJERCICIO 5 - AGREGAR DATOS
************************************************************************/


/* =========================
   DATOS DE AUTOR
   DATOS EXACTOS DE LA GUIA
   ========================= */

INSERT INTO Autor
(
    CodigoAutor,
    PrimerNombre,
    PrimerApellido,
    FechaNacimiento,
    Nacionalidad
)
VALUES
('PL001', 'Pablo',   'Lopez',     '1960-08-19', 'Colombiana'),
('CM002', 'Claudia', 'Martinez', '1970-06-10', 'Salvadoreña'),
('PM003', 'Patricio', 'Murry',   '1972-12-12', 'España'),
('NH004', 'Nuria',   'Hernandez', '1980-09-03', 'Colombiana');
GO


/* =========================
   DATOS DE EDITORIAL
   DATOS EXACTOS DE LA GUIA
   ========================= */

INSERT INTO Editorial
(
    CodigoEditorial,
    Nombre,
    Pais
)
VALUES
('ED001', 'Omega 2000',      'Colombia'),
('ED002', 'Anaya Multimedia', 'España'),
('ED003', 'McGrawHill',      'Inglaterra');
GO


/* =========================
   DATOS DE LIBRO
   DATOS EXACTOS DE LA GUIA
   ========================= */

INSERT INTO Libro
(
    CodigoLibro,
    Titulo,
    ISBN,
    AñoEdicion,
    CodigoEditorial
)
VALUES
(
    'BDCOL00001',
    'Fundamentos de base de datos',
    '12333-8999988',
    '2004',
    'ED001'
),
(
    'BDESP00002',
    'La Biblia de SQL Server 2008',
    '3444-99888-88',
    '2008',
    'ED002'
),
(
    'PRCOL00002',
    'Programación orientada a objetos',
    '8999-9999444',
    '2011',
    'ED001'
),
(
    'DWING00003',
    'Diseño Web y Hojas de estilo',
    '300096-99999',
    '2010',
    'ED003'
);
GO


/* =========================
   DATOS DETALLE_AUTORLIBRO
   DATOS EXACTOS DE LA GUIA
   ========================= */

INSERT INTO Detalle_AutorLibro
(
    CodigoAutor,
    CodigoLibro,
    Fecha
)
VALUES
('PL001', 'BDCOL00001', '2002-06-12'),
('NH004', 'BDCOL00001', '2002-06-12'),
('CM002', 'PRCOL00002', '2009-12-19'),
('PM003', 'BDESP00002', '2000-03-01'),
('PM003', 'DWING00003', '2009-03-23');
GO


/***********************************************************************
 PRUEBAS DEL EJERCICIO 5
************************************************************************/


SELECT * FROM Autor;
GO

SELECT * FROM Editorial;
GO

SELECT * FROM Libro;
GO

SELECT * FROM Detalle_AutorLibro;
GO


/* Mostrar todos los libros con su editorial */

SELECT
    L.CodigoLibro,
    L.Titulo,
    L.ISBN,
    L.AñoEdicion,
    E.Nombre AS Editorial,
    E.Pais
FROM Libro AS L
INNER JOIN Editorial AS E
    ON L.CodigoEditorial = E.CodigoEditorial;
GO


/* Mostrar libros y autores */

SELECT
    L.CodigoLibro,
    L.Titulo,
    A.CodigoAutor,
    A.PrimerNombre + ' ' + A.PrimerApellido AS Autor,
    D.Fecha
FROM Detalle_AutorLibro AS D
INNER JOIN Autor AS A
    ON D.CodigoAutor = A.CodigoAutor
INNER JOIN Libro AS L
    ON D.CodigoLibro = L.CodigoLibro
ORDER BY L.CodigoLibro;
GO


/* Contar libros por autor */

SELECT
    A.CodigoAutor,
    A.PrimerNombre + ' ' + A.PrimerApellido AS Autor,
    COUNT(D.CodigoLibro) AS CantidadLibros
FROM Autor AS A
LEFT JOIN Detalle_AutorLibro AS D
    ON A.CodigoAutor = D.CodigoAutor
GROUP BY
    A.CodigoAutor,
    A.PrimerNombre,
    A.PrimerApellido;
GO


/* Contar libros por editorial */

SELECT
    E.CodigoEditorial,
    E.Nombre AS Editorial,
    COUNT(L.CodigoLibro) AS CantidadLibros
FROM Editorial AS E
LEFT JOIN Libro AS L
    ON E.CodigoEditorial = L.CodigoEditorial
GROUP BY
    E.CodigoEditorial,
    E.Nombre;
GO


/***********************************************************************
 PRUEBA DE INTEGRIDAD REFERENCIAL

 La siguiente instrucción está comentada porque debe generar error.
 El código de editorial ED999 NO EXISTE.
************************************************************************/

-- INSERT INTO Libro
-- (
--     CodigoLibro,
--     Titulo,
--     ISBN,
--     AñoEdicion,
--     CodigoEditorial
-- )
-- VALUES
-- (
--     'PRUEBA9999',
--     'Libro de prueba',
--     '00000-00000',
--     '2026',
--     'ED999'
-- );
-- GO


/***********************************************************************
 FIN DE EJERCICIOS 1 AL 5
************************************************************************/


/***********************************************************************
                     PARTE 2
             EJERCICIO COMPLEMENTARIO
                    PELICULAS

 La guía solicita:

 Gestion_Peliculas_Carnet

 Modelo E-R:

 Pelicula N ---- M Actor

 Estudio 1 ---- N Pelicula

 Para romper la relación N:M se crea:
 Detalle_PeliculaActor
************************************************************************/


USE master;
GO

IF DB_ID('Gestion_Peliculas_FC260104') IS NOT NULL
BEGIN
    ALTER DATABASE Gestion_Peliculas_FC260104
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE Gestion_Peliculas_FC260104;
END
GO

CREATE DATABASE Gestion_Peliculas_FC260104;
GO

USE Gestion_Peliculas_FC260104;
GO


/***********************************************************************
 TABLA ESTUDIO

 Campos del modelo:
 Codigo
 Nombre
 Domicilio:
    Direccion
    Ciudad
    Pais
************************************************************************/

CREATE TABLE Estudio
(
    Codigo CHAR(5) NOT NULL,
    Nombre VARCHAR(60) NOT NULL,
    Direccion VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(50) NOT NULL,
    Pais VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Estudio
    PRIMARY KEY (Codigo)
);
GO


/***********************************************************************
 TABLA ACTOR

 Campos del modelo:
 Codigo
 FechaNacimiento
 Telefono
 Email
 Nombre:
    PrimerNombre
    PrimerApellido
************************************************************************/

CREATE TABLE Actor
(
    Codigo CHAR(5) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Telefono VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    PrimerNombre VARCHAR(50) NOT NULL,
    PrimerApellido VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Actor
    PRIMARY KEY (Codigo)
);
GO


/***********************************************************************
 TABLA PELICULA

 Campos:
 Codigo
 Titulo
 Direccion
 CodigoEstudio

 CodigoEstudio es FK porque:
 Estudio 1 ---- N Pelicula
************************************************************************/

CREATE TABLE Pelicula
(
    Codigo CHAR(5) NOT NULL,
    Titulo VARCHAR(100) NOT NULL,
    Direccion VARCHAR(100) NOT NULL,
    CodigoEstudio CHAR(5) NOT NULL,

    CONSTRAINT PK_Pelicula
    PRIMARY KEY (Codigo),

    CONSTRAINT FK_Pelicula_Estudio
    FOREIGN KEY (CodigoEstudio)
    REFERENCES Estudio(Codigo)
);
GO


/***********************************************************************
 TABLA INTERMEDIA PELICULA - ACTOR

 Relación:
 Pelicula N ---- M Actor

 Se transforma en:
 Pelicula 1 ---- N Detalle_PeliculaActor N ---- 1 Actor
************************************************************************/

CREATE TABLE Detalle_PeliculaActor
(
    CodigoPelicula CHAR(5) NOT NULL,
    CodigoActor CHAR(5) NOT NULL,

    CONSTRAINT PK_Detalle_PeliculaActor
    PRIMARY KEY (CodigoPelicula, CodigoActor),

    CONSTRAINT FK_Detalle_PeliculaActor_Pelicula
    FOREIGN KEY (CodigoPelicula)
    REFERENCES Pelicula(Codigo),

    CONSTRAINT FK_Detalle_PeliculaActor_Actor
    FOREIGN KEY (CodigoActor)
    REFERENCES Actor(Codigo)
);
GO


/***********************************************************************
 DATOS DE ESTUDIO
 MINIMO 3 REGISTROS
************************************************************************/

INSERT INTO Estudio
(
    Codigo,
    Nombre,
    Direccion,
    Ciudad,
    Pais
)
VALUES
('E0001', 'Warner Studios', '4000 Warner Blvd', 'Los Angeles', 'Estados Unidos'),
('E0002', 'Universal Pictures', '100 Universal City Plaza', 'Universal City', 'Estados Unidos'),
('E0003', 'Paramount Pictures', '5555 Melrose Avenue', 'Los Angeles', 'Estados Unidos');
GO


/***********************************************************************
 DATOS DE ACTOR
 MINIMO 3 REGISTROS
************************************************************************/

INSERT INTO Actor
(
    Codigo,
    FechaNacimiento,
    Telefono,
    Email,
    PrimerNombre,
    PrimerApellido
)
VALUES
('A0001', '1985-04-15', '7000-1001', 'carlos@cine.com', 'Carlos', 'Ramirez'),
('A0002', '1990-08-22', '7000-1002', 'daniela@cine.com', 'Daniela', 'Martinez'),
('A0003', '1982-11-10', '7000-1003', 'miguel@cine.com', 'Miguel', 'Hernandez'),
('A0004', '1993-02-18', '7000-1004', 'sofia@cine.com', 'Sofia', 'Castro');
GO


/***********************************************************************
 DATOS DE PELICULA
************************************************************************/

INSERT INTO Pelicula
(
    Codigo,
    Titulo,
    Direccion,
    CodigoEstudio
)
VALUES
('P0001', 'La Ultima Aventura', 'Robert Anderson', 'E0001'),
('P0002', 'El Misterio del Tiempo', 'Laura Thompson', 'E0002'),
('P0003', 'Guardianes de la Ciudad', 'Michael Johnson', 'E0001'),
('P0004', 'Destino Final', 'James Wilson', 'E0003');
GO


/***********************************************************************
 DATOS DE DETALLE_PELICULAACTOR
************************************************************************/

INSERT INTO Detalle_PeliculaActor
(
    CodigoPelicula,
    CodigoActor
)
VALUES
('P0001', 'A0001'),
('P0001', 'A0002'),
('P0002', 'A0002'),
('P0002', 'A0003'),
('P0003', 'A0001'),
('P0003', 'A0004'),
('P0004', 'A0003'),
('P0004', 'A0004');
GO


/***********************************************************************
 CONSULTAS DEL EJERCICIO COMPLEMENTARIO
************************************************************************/


SELECT * FROM Estudio;
GO

SELECT * FROM Actor;
GO

SELECT * FROM Pelicula;
GO

SELECT * FROM Detalle_PeliculaActor;
GO


/* Peliculas con estudio */

SELECT
    P.Codigo,
    P.Titulo,
    P.Direccion,
    E.Nombre AS Estudio,
    E.Ciudad,
    E.Pais
FROM Pelicula AS P
INNER JOIN Estudio AS E
    ON P.CodigoEstudio = E.Codigo;
GO


/* Peliculas con actores */

SELECT
    P.Titulo AS Pelicula,
    A.PrimerNombre + ' ' + A.PrimerApellido AS Actor
FROM Detalle_PeliculaActor AS D
INNER JOIN Pelicula AS P
    ON D.CodigoPelicula = P.Codigo
INNER JOIN Actor AS A
    ON D.CodigoActor = A.Codigo
ORDER BY P.Titulo;
GO


/* Cantidad de actores por pelicula */

SELECT
    P.Codigo,
    P.Titulo,
    COUNT(D.CodigoActor) AS CantidadActores
FROM Pelicula AS P
LEFT JOIN Detalle_PeliculaActor AS D
    ON P.Codigo = D.CodigoPelicula
GROUP BY
    P.Codigo,
    P.Titulo;
GO


/* Cantidad de peliculas por estudio */

SELECT
    E.Codigo,
    E.Nombre,
    COUNT(P.Codigo) AS CantidadPeliculas
FROM Estudio AS E
LEFT JOIN Pelicula AS P
    ON E.Codigo = P.CodigoEstudio
GROUP BY
    E.Codigo,
    E.Nombre;
GO


/***********************************************************************
                     PARTE 3
               ANALISIS DE RESULTADOS

 Modelo E-R de la pagina 19:

 Cliente N ---- N Producto

 Relacion Compra:
    Valor
    Fecha

 Se rompe la relacion N:M con tabla intermedia Compra.
************************************************************************/


USE master;
GO

IF DB_ID('Gestion_Compras_FC260104') IS NOT NULL
BEGIN
    ALTER DATABASE Gestion_Compras_FC260104
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE Gestion_Compras_FC260104;
END
GO

CREATE DATABASE Gestion_Compras_FC260104;
GO

USE Gestion_Compras_FC260104;
GO


/***********************************************************************
 TABLA CLIENTE

 Modelo:
 Dui
 Nombre
 Direccion
************************************************************************/

CREATE TABLE Cliente
(
    DUI CHAR(10) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Direccion VARCHAR(150) NOT NULL,

    CONSTRAINT PK_Cliente
    PRIMARY KEY (DUI)
);
GO


/***********************************************************************
 TABLA PRODUCTO

 Modelo:
 Codigo
 Descripcion
 Precio
************************************************************************/

CREATE TABLE Producto
(
    Codigo CHAR(6) NOT NULL,
    Descripcion VARCHAR(150) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_Producto
    PRIMARY KEY (Codigo),

    CONSTRAINT CK_Producto_Precio
    CHECK (Precio >= 0)
);
GO


/***********************************************************************
 TABLA COMPRA

 Relacion N:M:

 Cliente N ---- Compra ---- N Producto

 Atributos de la relacion:
 Valor
 Fecha

 Se agregan las FK:
 DUI
 CodigoProducto

 La combinacion:
 DUI + CodigoProducto + Fecha
 identifica una compra.
************************************************************************/

CREATE TABLE Compra
(
    DUI CHAR(10) NOT NULL,
    CodigoProducto CHAR(6) NOT NULL,
    Valor DECIMAL(10,2) NOT NULL,
    Fecha DATE NOT NULL,

    CONSTRAINT PK_Compra
    PRIMARY KEY (DUI, CodigoProducto, Fecha),

    CONSTRAINT FK_Compra_Cliente
    FOREIGN KEY (DUI)
    REFERENCES Cliente(DUI),

    CONSTRAINT FK_Compra_Producto
    FOREIGN KEY (CodigoProducto)
    REFERENCES Producto(Codigo),

    CONSTRAINT CK_Compra_Valor
    CHECK (Valor >= 0)
);
GO


/***********************************************************************
 DATOS CLIENTE
 MINIMO 3
************************************************************************/

INSERT INTO Cliente
(
    DUI,
    Nombre,
    Direccion
)
VALUES
('0123456789', 'Juan Perez', 'San Salvador'),
('0234567890', 'Maria Lopez', 'Santa Tecla'),
('0345678901', 'Carlos Hernandez', 'Soyapango'),
('0456789012', 'Ana Martinez', 'Mejicanos');
GO


/***********************************************************************
 DATOS PRODUCTO
 MINIMO 3
************************************************************************/

INSERT INTO Producto
(
    Codigo,
    Descripcion,
    Precio
)
VALUES
('P00001', 'Computadora Portatil', 750.00),
('P00002', 'Teclado Inalambrico', 35.50),
('P00003', 'Mouse Inalambrico', 20.00),
('P00004', 'Monitor LED 24 pulgadas', 180.00);
GO


/***********************************************************************
 DATOS COMPRA
 MINIMO 3
************************************************************************/

INSERT INTO Compra
(
    DUI,
    CodigoProducto,
    Valor,
    Fecha
)
VALUES
('0123456789', 'P00001', 750.00, '2026-01-15'),
('0123456789', 'P00002', 35.50, '2026-01-15'),
('0234567890', 'P00003', 20.00, '2026-02-10'),
('0345678901', 'P00004', 180.00, '2026-02-20'),
('0456789012', 'P00002', 35.50, '2026-03-05'),
('0456789012', 'P00003', 20.00, '2026-03-05');
GO


/***********************************************************************
 CONSULTAS DEL ANALISIS DE RESULTADOS
************************************************************************/


SELECT * FROM Cliente;
GO

SELECT * FROM Producto;
GO

SELECT * FROM Compra;
GO


/* Mostrar compras con cliente y producto */

SELECT
    C.DUI,
    C.Nombre AS Cliente,
    P.Codigo AS CodigoProducto,
    P.Descripcion AS Producto,
    P.Precio,
    CO.Valor,
    CO.Fecha
FROM Compra AS CO
INNER JOIN Cliente AS C
    ON CO.DUI = C.DUI
INNER JOIN Producto AS P
    ON CO.CodigoProducto = P.Codigo
ORDER BY CO.Fecha;
GO


/* Total comprado por cada cliente */

SELECT
    C.DUI,
    C.Nombre,
    SUM(CO.Valor) AS TotalComprado
FROM Cliente AS C
INNER JOIN Compra AS CO
    ON C.DUI = CO.DUI
GROUP BY
    C.DUI,
    C.Nombre;
GO


/* Cantidad de compras por cliente */

SELECT
    C.DUI,
    C.Nombre,
    COUNT(CO.CodigoProducto) AS CantidadCompras
FROM Cliente AS C
LEFT JOIN Compra AS CO
    ON C.DUI = CO.DUI
GROUP BY
    C.DUI,
    C.Nombre;
GO


/* Cantidad de veces que se ha comprado cada producto */

SELECT
    P.Codigo,
    P.Descripcion,
    COUNT(CO.DUI) AS CantidadCompras
FROM Producto AS P
LEFT JOIN Compra AS CO
    ON P.Codigo = CO.CodigoProducto
GROUP BY
    P.Codigo,
    P.Descripcion;
GO


/* Total vendido por producto */

SELECT
    P.Codigo,
    P.Descripcion,
    SUM(CO.Valor) AS TotalVendido
FROM Producto AS P
INNER JOIN Compra AS CO
    ON P.Codigo = CO.CodigoProducto
GROUP BY
    P.Codigo,
    P.Descripcion;
GO


/***********************************************************************
 VERIFICACION FINAL
************************************************************************/


/* Base de datos de libros */

USE Gestion_Libros_FC260104;
GO

SELECT
    'Autor' AS Tabla,
    COUNT(*) AS Registros
FROM Autor

UNION ALL

SELECT
    'Editorial',
    COUNT(*)
FROM Editorial

UNION ALL

SELECT
    'Libro',
    COUNT(*)
FROM Libro

UNION ALL

SELECT
    'Detalle_AutorLibro',
    COUNT(*)
FROM Detalle_AutorLibro;
GO


/* Base de datos de peliculas */

USE Gestion_Peliculas_FC260104;
GO

SELECT
    'Estudio' AS Tabla,
    COUNT(*) AS Registros
FROM Estudio

UNION ALL

SELECT
    'Actor',
    COUNT(*)
FROM Actor

UNION ALL

SELECT
    'Pelicula',
    COUNT(*)
FROM Pelicula

UNION ALL

SELECT
    'Detalle_PeliculaActor',
    COUNT(*)
FROM Detalle_PeliculaActor;
GO


/* Base de datos de compras */

USE Gestion_Compras_FC260104;
GO

SELECT
    'Cliente' AS Tabla,
    COUNT(*) AS Registros
FROM Cliente

UNION ALL

SELECT
    'Producto',
    COUNT(*)
FROM Producto

UNION ALL

SELECT
    'Compra',
    COUNT(*)
FROM Compra;
GO


/***********************************************************************
                 FIN DEL SCRIPT COMPLETO
************************************************************************/

PRINT '===============================================';
PRINT ' GUIA 5 COMPLETADA';
PRINT ' CARNET: FC260104';
PRINT '===============================================';
PRINT 'Gestion_Libros_FC260104';
PRINT 'Gestion_Peliculas_FC260104';
PRINT 'Gestion_Compras_FC260104';
PRINT '===============================================';
GO