CREATE DATABASE PracticaSQL;
GO

USE PracticaSQL;
GO

CREATE TABLE Estudiantes (
    IdEstudiante INT IDENTITY(1,1) PRIMARY KEY,
    Carnet VARCHAR(20) NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Edad INT,
    Carrera VARCHAR(100),
    Ciudad VARCHAR(50)
);
GO


INSERT INTO Estudiantes
(Carnet, Nombre, Apellido, Edad, Carrera, Ciudad)
VALUES
('FC260104', 'Jerusalen', 'Arce', 18, 'Ingenieria en Sistemas', 'Santa Ana'),
('FC260105', 'Carlos', 'Martinez', 20, 'Ingenieria en Sistemas', 'San Salvador'),
('FC260106', 'Maria', 'Lopez', 19, 'Administracion de Empresas', 'Santa Tecla'),
('FC260107', 'Jose', 'Hernandez', 21, 'Contaduria', 'Sonsonate'),
('FC260108', 'Ana', 'Ramirez', 18, 'Ingenieria en Sistemas', 'La Libertad');
GO