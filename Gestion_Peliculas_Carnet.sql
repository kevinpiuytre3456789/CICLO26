USE master;
GO

IF DB_ID('Gestion_Peliculas_Carnet') IS NOT NULL
BEGIN
    ALTER DATABASE Gestion_Peliculas_Carnet SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Gestion_Peliculas_Carnet;
END
GO

CREATE DATABASE Gestion_Peliculas_Carnet;
GO

USE Gestion_Peliculas_Carnet;
GO

CREATE TABLE Estudio
(
    Codigo CHAR(5) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Direccion VARCHAR(150) NOT NULL,
    Ciudad VARCHAR(50) NOT NULL,
    Pais VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Estudio PRIMARY KEY (Codigo)
);
GO

CREATE TABLE Pelicula
(
    Codigo CHAR(5) NOT NULL,
    Titulo VARCHAR(150) NOT NULL,
    Direccion VARCHAR(100) NOT NULL,
    CodigoEstudio CHAR(5) NOT NULL,
    CONSTRAINT PK_Pelicula PRIMARY KEY (Codigo),
    CONSTRAINT FK_Pelicula_Estudio FOREIGN KEY (CodigoEstudio)
        REFERENCES Estudio(Codigo)
);
GO

CREATE TABLE Actor
(
    Codigo CHAR(5) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    PrimerNombre VARCHAR(50) NOT NULL,
    PrimerApellido VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Actor PRIMARY KEY (Codigo)
);
GO

CREATE TABLE Actua
(
    CodigoPelicula CHAR(5) NOT NULL,
    CodigoActor CHAR(5) NOT NULL,
    CONSTRAINT PK_Actua PRIMARY KEY (CodigoPelicula, CodigoActor),
    CONSTRAINT FK_Actua_Pelicula FOREIGN KEY (CodigoPelicula)
        REFERENCES Pelicula(Codigo),
    CONSTRAINT FK_Actua_Actor FOREIGN KEY (CodigoActor)
        REFERENCES Actor(Codigo)
);
GO

INSERT INTO Estudio (Codigo, Nombre, Direccion, Ciudad, Pais)
VALUES
('ES001', 'Warner Bros', '4000 Warner Blvd', 'Burbank', 'Estados Unidos'),
('ES002', 'Universal Pictures', '100 Universal City Plaza', 'Universal City', 'Estados Unidos'),
('ES003', 'Paramount Pictures', '5555 Melrose Avenue', 'Los Angeles', 'Estados Unidos');
GO

INSERT INTO Pelicula (Codigo, Titulo, Direccion, CodigoEstudio)
VALUES
('PE001', 'La Gran Aventura', 'Carlos Mendoza', 'ES001'),
('PE002', 'Mision Final', 'Ana Torres', 'ES002'),
('PE003', 'El Ultimo Viaje', 'Luis Ramirez', 'ES003');
GO

INSERT INTO Actor (Codigo, FechaNacimiento, Telefono, Email, PrimerNombre, PrimerApellido)
VALUES
('AC001', '1985-04-12', '7000-1001', 'actor1@email.com', 'Juan', 'Perez'),
('AC002', '1990-08-25', '7000-1002', 'actor2@email.com', 'Maria', 'Lopez'),
('AC003', '1982-11-03', '7000-1003', 'actor3@email.com', 'Carlos', 'Gomez');
GO

INSERT INTO Actua (CodigoPelicula, CodigoActor)
VALUES
('PE001', 'AC001'),
('PE001', 'AC002'),
('PE002', 'AC002'),
('PE002', 'AC003'),
('PE003', 'AC001'),
('PE003', 'AC003');
GO

SELECT * FROM Estudio;
SELECT * FROM Pelicula;
SELECT * FROM Actor;
SELECT * FROM Actua;
GO

SELECT
    P.Codigo AS CodigoPelicula,
    P.Titulo,
    P.Direccion,
    E.Nombre AS Estudio,
    E.Ciudad,
    E.Pais
FROM Pelicula P
INNER JOIN Estudio E
    ON P.CodigoEstudio = E.Codigo;
GO

SELECT
    P.Titulo AS Pelicula,
    A.PrimerNombre + ' ' + A.PrimerApellido AS Actor
FROM Actua AC
INNER JOIN Pelicula P
    ON AC.CodigoPelicula = P.Codigo
INNER JOIN Actor A
    ON AC.CodigoActor = A.Codigo
ORDER BY P.Titulo;
GO
