# Buen Día · Panadería

Aplicación web local conectada a la base **BuenPan_ASB404** de SQL Server. Usa la base existente y sus procedimientos y vistas; no ejecuta instaladores SQL ni sustituye tus datos.

## Iniciar

1. Mantén SQL Server iniciado en este equipo.
2. Abre **iniciar.bat**. La primera vez instala el conector `pyodbc` en `.venv`.
3. Se abre **http://127.0.0.1:8000** en tu navegador. Mantén abierta la ventana de la aplicación mientras la uses. Para detenerla, presiona Ctrl+C en esa ventana.

Requisitos: Python 3.12 o compatible, SQL Server y Microsoft ODBC Driver 18 for SQL Server. En este equipo se detectó una instancia predeterminada en `localhost` con la base existente.

## Conexión

Por defecto usa `localhost`, `BuenPan_ASB404` y autenticación de Windows. Se conecta con la cuenta que ejecuta la app; esa cuenta necesita consultar las tablas/vistas usadas y ejecutar los procedimientos de la aplicación.

Para cambiar la conexión, copia `config.example.json` como `config.local.json` y ajusta sus valores. Este archivo local se excluye de Git. Para autenticación SQL, establece `trusted_connection` en `false` y define `DB_USER` y `DB_PASSWORD` como variables de entorno antes de iniciar. No guardes contraseñas en el código. `DB_SERVER` y `DB_NAME` permiten sobreescribir servidor y base.

La configuración inicial confía en el certificado del SQL Server local. La app escucha únicamente en `127.0.0.1` y está pensada para uso local. Incluye cuentas, contraseñas y permisos por rol.

## Usuarios y permisos

En este equipo ya está instalado `SQL/08_UsuariosApp.sql`. En una instalación nueva, ejecútalo después de instalar la base y sus roles. Agrega `UsuariosApp` y cuatro vistas de lectura para la interfaz; no elimina los datos existentes.

Al abrir la app por primera vez, crea tu cuenta de **Gerencia**, con nombre, usuario y una contraseña de al menos diez caracteres. No hay contraseñas predeterminadas. Después entra a **Usuarios → Nuevo usuario** para crear las cuentas del equipo y asignarles un rol.

| Rol | Acceso |
| --- | --- |
| Gerencia | Todas las pantallas, anular ventas, crear y activar/desactivar cuentas |
| Cajero | Punto de venta, consulta de ventas y registro de clientes |
| Inventario | Existencias, entradas, precios, stock crítico y movimientos |

Cada persona tiene su cuenta web. Las operaciones de negocio usan `EXECUTE AS USER` con `demo_gerencia`, `demo_cajero` o `demo_inventario`, según el rol de su cuenta. Por eso SQL Server aplica los permisos de `SQL/05_Seguridad.sql`, además de los controles del servidor de la app. La auditoría SQL registra ese usuario de rol; el encabezado muestra la persona que inició sesión. El empleado seleccionado al vender sigue siendo el empleado responsable de la venta y es independiente de la cuenta web.

La conexión técnica de la app necesita leer y administrar `UsuariosApp` y poder suplantar los tres usuarios de rol. No se guardan contraseñas en texto plano: se usa PBKDF2-HMAC-SHA256 con sal aleatoria y 600 000 iteraciones. Las sesiones duran ocho horas, se guardan en memoria y usan cookies HttpOnly/SameSite=Strict y token contra solicitudes cruzadas. Reiniciar la app cierra las sesiones. Desactivar una cuenta o cambiar su contraseña revoca sus sesiones. Cada persona puede cambiar su contraseña en **Mi contraseña**.

La cuenta inicial solo se puede crear mientras no exista ninguna cuenta. Gerencia puede activar y desactivar usuarios, pero no desactivarse a sí misma. La app conserva al menos una cuenta de gerencia activa. No se borran cuentas desde la interfaz.

## Funciones

- Resumen con ventas de hoy, productos activos, alertas de stock y productos más vendidos.
- Punto de venta con carrito, empleado y cliente opcional. El total lo determina SQL Server, con IVA del 13 %.
- Ventas con consulta de detalle y anulación que devuelve existencias mediante `usp_AnularVenta`.
- Inventario con entradas, actualización de precios y movimientos recientes.
- Registro y listado de clientes.
- Reportes diarios y rentabilidad por producto.
- Stock crítico consultado desde `vw_StockCritico` y clientes frecuentes desde `vw_ClientesFrecuentes`.
- Pantalla **Base de datos** con los 19 objetos SQL detectados, su uso en cada pantalla y auditoría de productos.
- Seis imágenes ilustrativas locales de panadería, café, chocolate, galletas, pastel y quesadilla. Su generación está documentada en `web/assets/IMAGENES.md`.
- Las entradas de inventario permiten conservar el costo actual o indicar uno nuevo, incluido cero.

La creación y confirmación de una venta se ejecutan dentro de la misma transacción de conexión: un error revierte toda la operación. Los triggers existentes siguen descontando inventario y registrando auditoría. Los paneles muestran hasta 100 ventas y movimientos y 14 días con ventas; no son períodos consecutivos ni listados completos históricos.

Los formularios no crean productos, categorías ni empleados; usan los ya registrados en tu base. La app requiere los objetos definidos en `SQL/01_Estructura.sql` a `SQL/04_Vistas.sql`.

## Validaciones realizadas

Se verificó la sintaxis de Python y JavaScript y la carga de la interfaz en el navegador. Se ejecutó `verificar_integracion.py` contra SQL Server: los 7 procedimientos, las 8 vistas, el stock, el IVA, las anulaciones, los movimientos y la auditoría funcionaron correctamente. Se verificó el rechazo de ediciones de detalle, transiciones inválidas de estado y ventas con stock insuficiente en su segundo producto.

Las pruebas revierten sus cambios y comparan el contenido de las tablas antes y después. Los identificadores automáticos pueden avanzar aunque se reviertan las transacciones. Para repetirlas, ejecuta `.venv\Scripts\python.exe verificar_integracion.py` sin otros usuarios escribiendo durante la prueba.

La pantalla **Base de datos** informa la presencia y habilitación de los 19 objetos originales; no es un historial de cada ejecución. Los triggers se activan cuando se cumplen las condiciones de su evento. El complemento agrega cuatro vistas de lectura de clientes, empleados, ventas y auditoría para que cada rol obtenga solo los datos de sus pantallas, sin dar acceso directo a las tablas del negocio.

`verificar_usuarios.py` comprueba cuentas temporales, contraseñas, sesiones, cierre de sesión, desactivación y restricciones HTTP. También verifica permisos reales y ejecuta operaciones de negocio bajo los tres usuarios SQL, revirtiéndolas al terminar. Las cuentas temporales se eliminan al terminar la prueba. Los identificadores automáticos pueden avanzar.
