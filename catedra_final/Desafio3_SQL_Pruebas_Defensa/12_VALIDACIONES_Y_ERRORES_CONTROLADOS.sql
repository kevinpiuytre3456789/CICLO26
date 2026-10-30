USE BuenPan_ASB404;
GO
DECLARE @Venta INT;
DECLARE @Cliente INT=(SELECT TOP(1) IdCliente FROM dbo.Clientes ORDER BY IdCliente);
DECLARE @Empleado INT=(SELECT IdEmpleado FROM dbo.Empleados WHERE Codigo=N'EMP001');
DECLARE @Producto INT=(SELECT IdProducto FROM dbo.Productos WHERE Codigo=N'PAN001');
DECLARE @StockOriginal INT=(SELECT Stock FROM dbo.Productos WHERE IdProducto=@Producto);
BEGIN TRY
    EXEC dbo.usp_RegistrarVenta @IdCliente=@Cliente,@IdEmpleado=@Empleado,
        @IdProducto=@Producto,@Cantidad=2000000,@IdVenta=@Venta OUTPUT;
    SELECT N'ERROR: venta sin inventario fue aceptada' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: inventario insuficiente rechazado' AS Resultado, ERROR_NUMBER() AS Codigo, ERROR_MESSAGE() AS Mensaje;
END CATCH;
BEGIN TRY
    EXEC dbo.usp_RegistrarVenta @IdCliente=@Cliente,@IdEmpleado=@Empleado,
        @IdProducto=@Producto,@Cantidad=0,@IdVenta=@Venta OUTPUT;
    SELECT N'ERROR: se aceptó cantidad cero' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: cantidad inválida rechazada' AS Resultado, ERROR_NUMBER() AS Codigo, ERROR_MESSAGE() AS Mensaje;
END CATCH;
BEGIN TRY
    EXEC dbo.usp_ActualizarPrecioProducto @IdProducto=@Producto,@NuevoPrecio=-5.00;
    SELECT N'ERROR: se aceptó precio negativo' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: precio inválido rechazado' AS Resultado, ERROR_NUMBER() AS Codigo, ERROR_MESSAGE() AS Mensaje;
END CATCH;
BEGIN TRY
    DECLARE @NuevoCliente INT;
    EXEC dbo.usp_RegistrarCliente @Nombres=N'Prueba',@Apellidos=N'Defensa',
        @Correo=N'correo-mal-escrito',@IdCliente=@NuevoCliente OUTPUT;
    SELECT N'ERROR: se aceptó un correo inválido' AS Resultado;
END TRY
BEGIN CATCH
    SELECT N'CORRECTO: correo inválido rechazado' AS Resultado, ERROR_NUMBER() AS Codigo, ERROR_MESSAGE() AS Mensaje;
END CATCH;
SELECT N'Stock no cambió tras operaciones rechazadas' AS Demostracion,
       @StockOriginal AS Antes, Stock AS Despues
FROM dbo.Productos WHERE IdProducto=@Producto;
GO
