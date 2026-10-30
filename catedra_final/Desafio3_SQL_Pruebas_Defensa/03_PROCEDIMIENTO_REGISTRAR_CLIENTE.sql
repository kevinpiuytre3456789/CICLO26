USE BuenPan_ASB404;
GO
DECLARE @IdCliente INT;
DECLARE @Correo NVARCHAR(150)=N'defensa_' + REPLACE(CONVERT(NVARCHAR(36),NEWID()),N'-',N'') + N'@example.com';
BEGIN TRANSACTION;
SELECT N'Antes: el correo no existe' AS Demostracion;
SELECT * FROM dbo.Clientes WHERE Correo=@Correo;
EXEC dbo.usp_RegistrarCliente
    @Nombres=N'Prueba', @Apellidos=N'Defensa',
    @Telefono=N'7000-0000', @Correo=@Correo,
    @IdCliente=@IdCliente OUTPUT;
SELECT N'Después: nuevo cliente y parámetro de salida' AS Demostracion, @IdCliente AS IdClienteGenerado;
SELECT * FROM dbo.Clientes WHERE IdCliente=@IdCliente;
ROLLBACK TRANSACTION;
SELECT N'Prueba revertida, sin cambios permanentes' AS Demostracion;
SELECT * FROM dbo.Clientes WHERE IdCliente=@IdCliente;
GO
