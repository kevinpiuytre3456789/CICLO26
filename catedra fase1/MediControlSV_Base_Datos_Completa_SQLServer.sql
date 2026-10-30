IF DB_ID(N'MediControlSV') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE MediControlSV');
END;
GO

USE MediControlSV;
GO

CREATE TABLE Roles (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(250) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Roles_Estado DEFAULT N'Activo',
    CONSTRAINT CK_Roles_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Permisos (
    id_permiso INT IDENTITY(1,1) PRIMARY KEY,
    codigo NVARCHAR(80) NOT NULL UNIQUE,
    nombre NVARCHAR(120) NOT NULL,
    modulo NVARCHAR(80) NOT NULL,
    descripcion NVARCHAR(250) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Permisos_Estado DEFAULT N'Activo',
    CONSTRAINT CK_Permisos_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Roles_Permisos (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT FK_RolesPermisos_Roles FOREIGN KEY (id_rol) REFERENCES Roles(id_rol),
    CONSTRAINT FK_RolesPermisos_Permisos FOREIGN KEY (id_permiso) REFERENCES Permisos(id_permiso)
);
GO

CREATE TABLE Usuarios (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    id_rol INT NOT NULL,
    nombres NVARCHAR(80) NOT NULL,
    apellidos NVARCHAR(80) NOT NULL,
    correo NVARCHAR(150) NOT NULL UNIQUE,
    password_hash NVARCHAR(500) NOT NULL,
    telefono NVARCHAR(20) NULL,
    foto_url NVARCHAR(700) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Usuarios_Estado DEFAULT N'Activo',
    intentos_fallidos SMALLINT NOT NULL CONSTRAINT DF_Usuarios_Intentos DEFAULT 0,
    bloqueado_hasta DATETIME2 NULL,
    ultimo_acceso DATETIME2 NULL,
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (id_rol) REFERENCES Roles(id_rol),
    CONSTRAINT CK_Usuarios_Estado CHECK (estado IN (N'Activo', N'Inactivo', N'Bloqueado'))
);
GO

CREATE TABLE Tokens_Recuperacion (
    id_token BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL,
    token_hash NVARCHAR(500) NOT NULL UNIQUE,
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Tokens_FechaCreacion DEFAULT SYSDATETIME(),
    fecha_expiracion DATETIME2 NOT NULL,
    fecha_uso DATETIME2 NULL,
    usado BIT NOT NULL CONSTRAINT DF_Tokens_Usado DEFAULT 0,
    CONSTRAINT FK_Tokens_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Tokens_Fechas CHECK (fecha_expiracion > fecha_creacion)
);
GO

CREATE TABLE Configuracion_Consultorio (
    id_configuracion INT IDENTITY(1,1) PRIMARY KEY,
    nombre_consultorio NVARCHAR(160) NOT NULL,
    direccion NVARCHAR(300) NULL,
    telefono NVARCHAR(30) NULL,
    correo NVARCHAR(150) NULL,
    logo_url NVARCHAR(700) NULL,
    hora_apertura TIME NULL,
    hora_cierre TIME NULL,
    duracion_consulta_minutos INT NOT NULL CONSTRAINT DF_Config_Duracion DEFAULT 30,
    anticipacion_minima_horas INT NOT NULL CONSTRAINT DF_Config_Anticipacion DEFAULT 2,
    dias_maximos_agendamiento INT NOT NULL CONSTRAINT DF_Config_DiasMax DEFAULT 90,
    permite_cancelacion_paciente BIT NOT NULL CONSTRAINT DF_Config_Cancelacion DEFAULT 1,
    horas_limite_cancelacion INT NOT NULL CONSTRAINT DF_Config_HorasCancelar DEFAULT 4,
    notificaciones_activas BIT NOT NULL CONSTRAINT DF_Config_Notificaciones DEFAULT 1,
    fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_Config_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Config_Duracion CHECK (duracion_consulta_minutos > 0),
    CONSTRAINT CK_Config_Anticipacion CHECK (anticipacion_minima_horas >= 0),
    CONSTRAINT CK_Config_DiasMax CHECK (dias_maximos_agendamiento > 0),
    CONSTRAINT CK_Config_HorasCancelar CHECK (horas_limite_cancelacion >= 0)
);
GO

CREATE TABLE Especialidades (
    id_especialidad INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    descripcion NVARCHAR(400) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Especialidades_Estado DEFAULT N'Activo',
    CONSTRAINT CK_Especialidades_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Pacientes (
    id_paciente INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NULL UNIQUE,
    codigo NVARCHAR(30) NOT NULL UNIQUE,
    nombres NVARCHAR(80) NOT NULL,
    apellidos NVARCHAR(80) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo NVARCHAR(20) NULL,
    tipo_documento NVARCHAR(30) NULL,
    numero_documento NVARCHAR(40) NULL,
    telefono NVARCHAR(20) NOT NULL,
    correo NVARCHAR(150) NULL,
    direccion NVARCHAR(300) NULL,
    observaciones NVARCHAR(1000) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Pacientes_Estado DEFAULT N'Activo',
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_Pacientes_FechaRegistro DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT FK_Pacientes_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Pacientes_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE UNIQUE INDEX UX_Pacientes_NumeroDocumento ON Pacientes(numero_documento) WHERE numero_documento IS NOT NULL;
GO

CREATE TABLE Contactos_Emergencia (
    id_contacto INT IDENTITY(1,1) PRIMARY KEY,
    id_paciente INT NOT NULL,
    nombre_completo NVARCHAR(160) NOT NULL,
    parentesco NVARCHAR(60) NOT NULL,
    telefono NVARCHAR(20) NOT NULL,
    es_principal BIT NOT NULL CONSTRAINT DF_Contactos_Principal DEFAULT 1,
    CONSTRAINT FK_Contactos_Pacientes FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente)
);
GO

CREATE TABLE Medicos (
    id_medico INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    numero_jvpm NVARCHAR(40) NOT NULL UNIQUE,
    telefono_profesional NVARCHAR(20) NULL,
    biografia NVARCHAR(1000) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Medicos_Estado DEFAULT N'Activo',
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_Medicos_FechaRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Medicos_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Medicos_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Medicos_Especialidades (
    id_medico INT NOT NULL,
    id_especialidad INT NOT NULL,
    es_principal BIT NOT NULL CONSTRAINT DF_MedEsp_Principal DEFAULT 0,
    PRIMARY KEY (id_medico, id_especialidad),
    CONSTRAINT FK_MedicosEspecialidades_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT FK_MedicosEspecialidades_Especialidades FOREIGN KEY (id_especialidad) REFERENCES Especialidades(id_especialidad)
);
GO

CREATE TABLE Servicios (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    id_especialidad INT NULL,
    nombre NVARCHAR(120) NOT NULL,
    descripcion NVARCHAR(500) NULL,
    precio DECIMAL(12,2) NOT NULL,
    duracion_minutos INT NOT NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Servicios_Estado DEFAULT N'Activo',
    CONSTRAINT FK_Servicios_Especialidades FOREIGN KEY (id_especialidad) REFERENCES Especialidades(id_especialidad),
    CONSTRAINT CK_Servicios_Precio CHECK (precio >= 0),
    CONSTRAINT CK_Servicios_Duracion CHECK (duracion_minutos > 0),
    CONSTRAINT CK_Servicios_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Medicos_Servicios (
    id_medico INT NOT NULL,
    id_servicio INT NOT NULL,
    precio_personalizado DECIMAL(12,2) NULL,
    duracion_personalizada_minutos INT NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_MedServ_Estado DEFAULT N'Activo',
    PRIMARY KEY (id_medico, id_servicio),
    CONSTRAINT FK_MedicosServicios_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT FK_MedicosServicios_Servicios FOREIGN KEY (id_servicio) REFERENCES Servicios(id_servicio),
    CONSTRAINT CK_MedicosServicios_Precio CHECK (precio_personalizado IS NULL OR precio_personalizado >= 0),
    CONSTRAINT CK_MedicosServicios_Duracion CHECK (duracion_personalizada_minutos IS NULL OR duracion_personalizada_minutos > 0),
    CONSTRAINT CK_MedicosServicios_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE Horarios_Medico (
    id_horario INT IDENTITY(1,1) PRIMARY KEY,
    id_medico INT NOT NULL,
    dia_semana TINYINT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Horarios_Estado DEFAULT N'Activo',
    CONSTRAINT FK_Horarios_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Horarios_Dia CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT CK_Horarios_Rango CHECK (hora_fin > hora_inicio),
    CONSTRAINT CK_Horarios_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE INDEX IX_Horarios_Medico_Dia ON Horarios_Medico(id_medico, dia_semana);
GO

CREATE TABLE Bloqueos_Agenda (
    id_bloqueo INT IDENTITY(1,1) PRIMARY KEY,
    id_medico INT NOT NULL,
    fecha_hora_inicio DATETIME2 NOT NULL,
    fecha_hora_fin DATETIME2 NOT NULL,
    motivo NVARCHAR(300) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Bloqueos_Estado DEFAULT N'Activo',
    CONSTRAINT FK_Bloqueos_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Bloqueos_Rango CHECK (fecha_hora_fin > fecha_hora_inicio),
    CONSTRAINT CK_Bloqueos_Estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE INDEX IX_Bloqueos_Medico_Fecha ON Bloqueos_Agenda(id_medico, fecha_hora_inicio, fecha_hora_fin);
GO

CREATE TABLE Citas (
    id_cita BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    id_servicio INT NOT NULL,
    id_usuario_creacion INT NOT NULL,
    fecha_hora_inicio DATETIME2 NOT NULL,
    fecha_hora_fin DATETIME2 NOT NULL,
    motivo NVARCHAR(800) NOT NULL,
    estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Citas_Estado DEFAULT N'Solicitada',
    canal_origen NVARCHAR(30) NOT NULL CONSTRAINT DF_Citas_Canal DEFAULT N'Recepcion',
    observaciones NVARCHAR(1000) NULL,
    motivo_cancelacion NVARCHAR(600) NULL,
    id_usuario_cancelacion INT NULL,
    fecha_cancelacion DATETIME2 NULL,
    fecha_llegada DATETIME2 NULL,
    fecha_inicio_atencion DATETIME2 NULL,
    fecha_fin_atencion DATETIME2 NULL,
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Citas_FechaCreacion DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT FK_Citas_Pacientes FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    CONSTRAINT FK_Citas_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT FK_Citas_Servicios FOREIGN KEY (id_servicio) REFERENCES Servicios(id_servicio),
    CONSTRAINT FK_Citas_UsuarioCreacion FOREIGN KEY (id_usuario_creacion) REFERENCES Usuarios(id_usuario),
    CONSTRAINT FK_Citas_UsuarioCancelacion FOREIGN KEY (id_usuario_cancelacion) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Citas_Rango CHECK (fecha_hora_fin > fecha_hora_inicio),
    CONSTRAINT CK_Citas_Estado CHECK (estado IN (N'Solicitada', N'Confirmada', N'En espera', N'En consulta', N'Finalizada', N'Cancelada', N'No asistio')),
    CONSTRAINT CK_Citas_Canal CHECK (canal_origen IN (N'Recepcion', N'Paciente', N'Medico', N'Administrador'))
);
GO

CREATE UNIQUE INDEX UX_Citas_Medico_HoraInicio ON Citas(id_medico, fecha_hora_inicio) WHERE estado NOT IN (N'Cancelada', N'No asistio');
GO

CREATE INDEX IX_Citas_Medico_Fecha ON Citas(id_medico, fecha_hora_inicio, fecha_hora_fin);
GO

CREATE INDEX IX_Citas_Paciente_Fecha ON Citas(id_paciente, fecha_hora_inicio);
GO

CREATE INDEX IX_Citas_Estado_Fecha ON Citas(estado, fecha_hora_inicio);
GO

CREATE TABLE Historial_Citas (
    id_historial BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_cita BIGINT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_evento NVARCHAR(40) NOT NULL,
    estado_anterior NVARCHAR(30) NULL,
    estado_nuevo NVARCHAR(30) NULL,
    fecha_hora_anterior DATETIME2 NULL,
    fecha_hora_nueva DATETIME2 NULL,
    descripcion NVARCHAR(700) NULL,
    fecha_evento DATETIME2 NOT NULL CONSTRAINT DF_HistCitas_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT FK_HistorialCitas_Citas FOREIGN KEY (id_cita) REFERENCES Citas(id_cita),
    CONSTRAINT FK_HistorialCitas_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_HistorialCitas_Tipo CHECK (tipo_evento IN (N'Creacion', N'Confirmacion', N'Reprogramacion', N'Cancelacion', N'Llegada', N'Inicio consulta', N'Finalizacion', N'No asistio', N'Otro'))
);
GO

CREATE INDEX IX_HistorialCitas_Cita_Fecha ON Historial_Citas(id_cita, fecha_evento DESC);
GO

CREATE TABLE Consultas (
    id_consulta BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_cita BIGINT NOT NULL UNIQUE,
    id_medico INT NOT NULL,
    motivo_consulta NVARCHAR(1000) NOT NULL,
    sintomas_observaciones NVARCHAR(MAX) NULL,
    antecedentes_relevantes NVARCHAR(MAX) NULL,
    evaluacion_medica NVARCHAR(MAX) NULL,
    diagnostico NVARCHAR(MAX) NULL,
    tratamiento NVARCHAR(MAX) NULL,
    recomendaciones NVARCHAR(MAX) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Consultas_Estado DEFAULT N'En curso',
    fecha_inicio DATETIME2 NOT NULL CONSTRAINT DF_Consultas_FechaInicio DEFAULT SYSDATETIME(),
    fecha_fin DATETIME2 NULL,
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT FK_Consultas_Citas FOREIGN KEY (id_cita) REFERENCES Citas(id_cita),
    CONSTRAINT FK_Consultas_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Consultas_Estado CHECK (estado IN (N'En curso', N'Finalizada', N'Anulada')),
    CONSTRAINT CK_Consultas_Fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
GO

CREATE INDEX IX_Consultas_Medico_Fecha ON Consultas(id_medico, fecha_inicio DESC);
GO

CREATE TABLE Signos_Vitales (
    id_signos BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_consulta BIGINT NOT NULL,
    presion_sistolica SMALLINT NULL,
    presion_diastolica SMALLINT NULL,
    temperatura_c DECIMAL(4,1) NULL,
    peso_kg DECIMAL(6,2) NULL,
    altura_m DECIMAL(4,2) NULL,
    frecuencia_cardiaca SMALLINT NULL,
    saturacion_oxigeno DECIMAL(5,2) NULL,
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_Signos_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Signos_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    CONSTRAINT CK_Signos_PresionSistolica CHECK (presion_sistolica IS NULL OR presion_sistolica BETWEEN 40 AND 300),
    CONSTRAINT CK_Signos_PresionDiastolica CHECK (presion_diastolica IS NULL OR presion_diastolica BETWEEN 20 AND 200),
    CONSTRAINT CK_Signos_Temperatura CHECK (temperatura_c IS NULL OR temperatura_c BETWEEN 25 AND 45),
    CONSTRAINT CK_Signos_Peso CHECK (peso_kg IS NULL OR peso_kg > 0),
    CONSTRAINT CK_Signos_Altura CHECK (altura_m IS NULL OR altura_m > 0),
    CONSTRAINT CK_Signos_FC CHECK (frecuencia_cardiaca IS NULL OR frecuencia_cardiaca BETWEEN 20 AND 300),
    CONSTRAINT CK_Signos_Saturacion CHECK (saturacion_oxigeno IS NULL OR saturacion_oxigeno BETWEEN 0 AND 100)
);
GO

CREATE INDEX IX_Signos_Consulta_Fecha ON Signos_Vitales(id_consulta, fecha_registro DESC);
GO

CREATE TABLE Recetas (
    id_receta BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_consulta BIGINT NOT NULL,
    id_medico INT NOT NULL,
    indicaciones_generales NVARCHAR(MAX) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Recetas_Estado DEFAULT N'Vigente',
    fecha_emision DATETIME2 NOT NULL CONSTRAINT DF_Recetas_Fecha DEFAULT SYSDATETIME(),
    fecha_anulacion DATETIME2 NULL,
    CONSTRAINT FK_Recetas_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    CONSTRAINT FK_Recetas_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Recetas_Estado CHECK (estado IN (N'Vigente', N'Anulada'))
);
GO

CREATE INDEX IX_Recetas_Consulta_Fecha ON Recetas(id_consulta, fecha_emision DESC);
GO

CREATE TABLE Detalle_Receta (
    id_detalle_receta BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_receta BIGINT NOT NULL,
    medicamento NVARCHAR(180) NOT NULL,
    presentacion NVARCHAR(120) NULL,
    dosis NVARCHAR(120) NULL,
    via_administracion NVARCHAR(80) NULL,
    frecuencia NVARCHAR(120) NULL,
    duracion NVARCHAR(120) NULL,
    indicaciones NVARCHAR(700) NOT NULL,
    observaciones NVARCHAR(700) NULL,
    CONSTRAINT FK_DetalleReceta_Recetas FOREIGN KEY (id_receta) REFERENCES Recetas(id_receta)
);
GO

CREATE TABLE Estudios_Medicos (
    id_estudio BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_consulta BIGINT NOT NULL,
    id_medico_solicitante INT NOT NULL,
    tipo_estudio NVARCHAR(160) NOT NULL,
    descripcion NVARCHAR(700) NULL,
    indicaciones NVARCHAR(700) NULL,
    estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Estudios_Estado DEFAULT N'Solicitado',
    fecha_solicitud DATETIME2 NOT NULL CONSTRAINT DF_Estudios_Fecha DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT FK_Estudios_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    CONSTRAINT FK_Estudios_Medicos FOREIGN KEY (id_medico_solicitante) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Estudios_Estado CHECK (estado IN (N'Solicitado', N'Pendiente', N'Resultado disponible', N'Revisado', N'Cancelado'))
);
GO

CREATE INDEX IX_Estudios_Consulta_Fecha ON Estudios_Medicos(id_consulta, fecha_solicitud DESC);
GO

CREATE TABLE Resultados_Estudio (
    id_resultado BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_estudio BIGINT NOT NULL UNIQUE,
    id_usuario_registro INT NOT NULL,
    descripcion_resultado NVARCHAR(MAX) NULL,
    observaciones NVARCHAR(MAX) NULL,
    archivo_url NVARCHAR(900) NULL,
    nombre_archivo NVARCHAR(250) NULL,
    tipo_archivo NVARCHAR(30) NULL,
    fecha_resultado DATETIME2 NOT NULL CONSTRAINT DF_Resultados_Fecha DEFAULT SYSDATETIME(),
    revisado BIT NOT NULL CONSTRAINT DF_Resultados_Revisado DEFAULT 0,
    id_medico_revision INT NULL,
    fecha_revision DATETIME2 NULL,
    CONSTRAINT FK_Resultados_Estudios FOREIGN KEY (id_estudio) REFERENCES Estudios_Medicos(id_estudio),
    CONSTRAINT FK_Resultados_UsuarioRegistro FOREIGN KEY (id_usuario_registro) REFERENCES Usuarios(id_usuario),
    CONSTRAINT FK_Resultados_MedicoRevision FOREIGN KEY (id_medico_revision) REFERENCES Medicos(id_medico),
    CONSTRAINT CK_Resultados_TipoArchivo CHECK (tipo_archivo IS NULL OR tipo_archivo IN (N'PDF', N'JPG', N'JPEG', N'PNG'))
);
GO

CREATE TABLE Seguimientos (
    id_seguimiento BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_consulta BIGINT NOT NULL,
    id_medico INT NOT NULL,
    id_cita_seguimiento BIGINT NULL,
    fecha_recomendada DATE NOT NULL,
    motivo NVARCHAR(700) NOT NULL,
    indicaciones NVARCHAR(MAX) NULL,
    observaciones NVARCHAR(MAX) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Seguimientos_Estado DEFAULT N'Pendiente',
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_Seguimientos_Fecha DEFAULT SYSDATETIME(),
    fecha_completado DATETIME2 NULL,
    CONSTRAINT FK_Seguimientos_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    CONSTRAINT FK_Seguimientos_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico),
    CONSTRAINT FK_Seguimientos_Citas FOREIGN KEY (id_cita_seguimiento) REFERENCES Citas(id_cita),
    CONSTRAINT CK_Seguimientos_Estado CHECK (estado IN (N'Pendiente', N'Programado', N'Completado', N'Vencido', N'Cancelado'))
);
GO

CREATE INDEX IX_Seguimientos_Medico_Fecha ON Seguimientos(id_medico, fecha_recomendada, estado);
GO

CREATE TABLE Documentos_Paciente (
    id_documento BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_consulta BIGINT NULL,
    id_usuario_carga INT NOT NULL,
    nombre NVARCHAR(220) NOT NULL,
    categoria NVARCHAR(80) NOT NULL,
    descripcion NVARCHAR(500) NULL,
    archivo_url NVARCHAR(900) NOT NULL,
    tipo_archivo NVARCHAR(30) NOT NULL,
    visible_para_paciente BIT NOT NULL CONSTRAINT DF_Documentos_Visible DEFAULT 1,
    fecha_carga DATETIME2 NOT NULL CONSTRAINT DF_Documentos_Fecha DEFAULT SYSDATETIME(),
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Documentos_Estado DEFAULT N'Activo',
    CONSTRAINT FK_Documentos_Pacientes FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    CONSTRAINT FK_Documentos_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    CONSTRAINT FK_Documentos_Usuarios FOREIGN KEY (id_usuario_carga) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Documentos_TipoArchivo CHECK (tipo_archivo IN (N'PDF', N'JPG', N'JPEG', N'PNG')),
    CONSTRAINT CK_Documentos_Estado CHECK (estado IN (N'Activo', N'Archivado'))
);
GO

CREATE INDEX IX_Documentos_Paciente_Fecha ON Documentos_Paciente(id_paciente, fecha_carga DESC);
GO

CREATE TABLE Pagos (
    id_pago BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_cita BIGINT NOT NULL,
    id_usuario_registro INT NOT NULL,
    numero_comprobante NVARCHAR(60) NULL UNIQUE,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago NVARCHAR(30) NOT NULL,
    referencia NVARCHAR(120) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT N'Pendiente',
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_Pagos_FechaRegistro DEFAULT SYSDATETIME(),
    fecha_pago DATETIME2 NULL,
    fecha_anulacion DATETIME2 NULL,
    motivo_anulacion NVARCHAR(500) NULL,
    CONSTRAINT FK_Pagos_Citas FOREIGN KEY (id_cita) REFERENCES Citas(id_cita),
    CONSTRAINT FK_Pagos_Usuarios FOREIGN KEY (id_usuario_registro) REFERENCES Usuarios(id_usuario),
    CONSTRAINT CK_Pagos_Monto CHECK (monto >= 0),
    CONSTRAINT CK_Pagos_Metodo CHECK (metodo_pago IN (N'Efectivo', N'Tarjeta', N'Transferencia')),
    CONSTRAINT CK_Pagos_Estado CHECK (estado IN (N'Pendiente', N'Pagado', N'Anulado'))
);
GO

CREATE INDEX IX_Pagos_Cita_Fecha ON Pagos(id_cita, fecha_registro DESC);
GO

CREATE TABLE Preferencias_Notificacion (
    id_preferencia INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    citas_confirmadas BIT NOT NULL CONSTRAINT DF_Pref_CitasConfirmadas DEFAULT 1,
    recordatorios_cita BIT NOT NULL CONSTRAINT DF_Pref_Recordatorios DEFAULT 1,
    citas_reprogramadas BIT NOT NULL CONSTRAINT DF_Pref_Reprogramadas DEFAULT 1,
    citas_canceladas BIT NOT NULL CONSTRAINT DF_Pref_Canceladas DEFAULT 1,
    documentos_disponibles BIT NOT NULL CONSTRAINT DF_Pref_Documentos DEFAULT 1,
    resultados_disponibles BIT NOT NULL CONSTRAINT DF_Pref_Resultados DEFAULT 1,
    seguimientos_proximos BIT NOT NULL CONSTRAINT DF_Pref_Seguimientos DEFAULT 1,
    CONSTRAINT FK_Preferencias_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);
GO

CREATE TABLE Notificaciones (
    id_notificacion BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_cita BIGINT NULL,
    tipo NVARCHAR(50) NOT NULL,
    titulo NVARCHAR(180) NOT NULL,
    mensaje NVARCHAR(1000) NOT NULL,
    leida BIT NOT NULL CONSTRAINT DF_Notificaciones_Leida DEFAULT 0,
    fecha_envio DATETIME2 NOT NULL CONSTRAINT DF_Notificaciones_Fecha DEFAULT SYSDATETIME(),
    fecha_lectura DATETIME2 NULL,
    CONSTRAINT FK_Notificaciones_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
    CONSTRAINT FK_Notificaciones_Citas FOREIGN KEY (id_cita) REFERENCES Citas(id_cita),
    CONSTRAINT CK_Notificaciones_Tipo CHECK (tipo IN (N'Cita confirmada', N'Cita proxima', N'Cita reprogramada', N'Cita cancelada', N'Documento disponible', N'Resultado disponible', N'Seguimiento proximo', N'Sistema'))
);
GO

CREATE INDEX IX_Notificaciones_Usuario_Leida_Fecha ON Notificaciones(id_usuario, leida, fecha_envio DESC);
GO

CREATE TABLE Auditoria (
    id_auditoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NULL,
    modulo NVARCHAR(80) NOT NULL,
    accion NVARCHAR(120) NOT NULL,
    entidad NVARCHAR(100) NULL,
    id_entidad NVARCHAR(80) NULL,
    descripcion NVARCHAR(1000) NULL,
    ip_origen NVARCHAR(64) NULL,
    fecha_hora DATETIME2 NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Auditoria_Usuarios FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);
GO

CREATE INDEX IX_Auditoria_Fecha ON Auditoria(fecha_hora DESC);
GO

CREATE INDEX IX_Auditoria_Usuario_Fecha ON Auditoria(id_usuario, fecha_hora DESC);
GO

INSERT INTO Roles(nombre, descripcion) VALUES
(N'Administrador', N'Administracion general del sistema'),
(N'Medico', N'Gestion clinica, expedientes, recetas, estudios y seguimientos'),
(N'Recepcionista', N'Gestion de pacientes, citas, sala de espera y pagos'),
(N'Paciente', N'Portal de consulta de informacion propia y gestion de citas');
GO

INSERT INTO Permisos(codigo, nombre, modulo) VALUES
(N'DASHBOARD_ADMIN_VER', N'Ver dashboard administrativo', N'Dashboard'),
(N'PACIENTES_VER', N'Ver pacientes', N'Pacientes'),
(N'PACIENTES_CREAR', N'Crear pacientes', N'Pacientes'),
(N'PACIENTES_EDITAR', N'Editar pacientes', N'Pacientes'),
(N'MEDICOS_VER', N'Ver medicos', N'Medicos'),
(N'MEDICOS_GESTIONAR', N'Gestionar medicos', N'Medicos'),
(N'CITAS_VER', N'Ver citas', N'Citas'),
(N'CITAS_CREAR', N'Crear citas', N'Citas'),
(N'CITAS_REPROGRAMAR', N'Reprogramar citas', N'Citas'),
(N'CITAS_CANCELAR', N'Cancelar citas', N'Citas'),
(N'SALA_ESPERA_GESTIONAR', N'Gestionar sala de espera', N'Citas'),
(N'EXPEDIENTE_VER', N'Ver expediente clinico', N'Expediente'),
(N'CONSULTAS_REGISTRAR', N'Registrar consultas', N'Consultas'),
(N'RECETAS_GESTIONAR', N'Gestionar recetas', N'Recetas'),
(N'ESTUDIOS_GESTIONAR', N'Gestionar estudios', N'Estudios'),
(N'SEGUIMIENTOS_GESTIONAR', N'Gestionar seguimientos', N'Seguimientos'),
(N'PAGOS_GESTIONAR', N'Gestionar pagos', N'Pagos'),
(N'REPORTES_VER', N'Ver reportes', N'Reportes'),
(N'USUARIOS_GESTIONAR', N'Gestionar usuarios', N'Usuarios'),
(N'ROLES_PERMISOS_GESTIONAR', N'Gestionar roles y permisos', N'Seguridad'),
(N'AUDITORIA_VER', N'Ver auditoria', N'Auditoria'),
(N'CONFIGURACION_GESTIONAR', N'Gestionar configuracion', N'Configuracion'),
(N'PORTAL_PROPIO_VER', N'Ver informacion propia del paciente', N'Portal paciente'),
(N'PORTAL_CITAS_GESTIONAR', N'Gestionar citas propias', N'Portal paciente'),
(N'PORTAL_RECETAS_VER', N'Ver recetas propias', N'Portal paciente'),
(N'PORTAL_ESTUDIOS_VER', N'Ver estudios propios', N'Portal paciente'),
(N'PORTAL_SEGUIMIENTOS_VER', N'Ver seguimientos propios', N'Portal paciente');
GO

INSERT INTO Roles_Permisos(id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM Roles r
CROSS JOIN Permisos p
WHERE r.nombre = N'Administrador';
GO

INSERT INTO Roles_Permisos(id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM Roles r
JOIN Permisos p ON p.codigo IN (
    N'PACIENTES_VER',
    N'CITAS_VER',
    N'CITAS_CREAR',
    N'CITAS_REPROGRAMAR',
    N'CITAS_CANCELAR',
    N'SALA_ESPERA_GESTIONAR',
    N'EXPEDIENTE_VER',
    N'CONSULTAS_REGISTRAR',
    N'RECETAS_GESTIONAR',
    N'ESTUDIOS_GESTIONAR',
    N'SEGUIMIENTOS_GESTIONAR',
    N'REPORTES_VER'
)
WHERE r.nombre = N'Medico';
GO

INSERT INTO Roles_Permisos(id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM Roles r
JOIN Permisos p ON p.codigo IN (
    N'PACIENTES_VER',
    N'PACIENTES_CREAR',
    N'PACIENTES_EDITAR',
    N'CITAS_VER',
    N'CITAS_CREAR',
    N'CITAS_REPROGRAMAR',
    N'CITAS_CANCELAR',
    N'SALA_ESPERA_GESTIONAR',
    N'PAGOS_GESTIONAR'
)
WHERE r.nombre = N'Recepcionista';
GO

INSERT INTO Roles_Permisos(id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM Roles r
JOIN Permisos p ON p.codigo IN (
    N'PORTAL_PROPIO_VER',
    N'PORTAL_CITAS_GESTIONAR',
    N'PORTAL_RECETAS_VER',
    N'PORTAL_ESTUDIOS_VER',
    N'PORTAL_SEGUIMIENTOS_VER'
)
WHERE r.nombre = N'Paciente';
GO

INSERT INTO Configuracion_Consultorio(
    nombre_consultorio,
    direccion,
    telefono,
    correo,
    hora_apertura,
    hora_cierre,
    duracion_consulta_minutos,
    anticipacion_minima_horas,
    dias_maximos_agendamiento,
    permite_cancelacion_paciente,
    horas_limite_cancelacion,
    notificaciones_activas
)
VALUES (
    N'MediControl SV',
    NULL,
    NULL,
    NULL,
    '08:00',
    '17:00',
    30,
    2,
    90,
    1,
    4,
    1
);
GO
