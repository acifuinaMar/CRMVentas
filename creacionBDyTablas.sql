/* =================================================================================================
   PROYECTO FINAL - BASE DE DATOS II
   Sistema: CRMVentas
   Archivo: 01_creacion_base_crmventas_limpio.sql

   Descripción:
   Script limpio y ordenado para crear la base de datos transaccional CRMVentas.
   Incluye creación de base, tablas, PK, FK, UNIQUE, CHECK, DEFAULT y datos iniciales.
================================================================================================= */

USE master;
GO

IF DB_ID('CRMVentas') IS NULL
BEGIN
    CREATE DATABASE CRMVentas;
END;
GO

ALTER DATABASE CRMVentas SET RECOVERY FULL;
GO
ALTER DATABASE CRMVentas SET AUTO_CLOSE OFF;
GO

USE CRMVentas;
GO

/* ================================================================================================
   LIMPIEZA OPCIONAL PARA INSTALACIÓN LIMPIA
================================================================================================ */

DROP TABLE IF EXISTS dbo.Actividad;
DROP TABLE IF EXISTS dbo.Etapa_Oportunidad;
DROP TABLE IF EXISTS dbo.Oportunidad;
DROP TABLE IF EXISTS dbo.BitacoraCambios;
DROP TABLE IF EXISTS dbo.Cliente;
DROP TABLE IF EXISTS dbo.Empleado;
DROP TABLE IF EXISTS dbo.EstadoActividad;
DROP TABLE IF EXISTS dbo.EstadoOportunidad;
DROP TABLE IF EXISTS dbo.Prioridad;
DROP TABLE IF EXISTS dbo.ResultadoOportunidad;
DROP TABLE IF EXISTS dbo.RolEmpleado;
DROP TABLE IF EXISTS dbo.TipoActividad;
DROP TABLE IF EXISTS dbo.TipoCliente;
DROP TABLE IF EXISTS dbo.TipoDocumento;
DROP TABLE IF EXISTS dbo.TipoEtapa;
DROP TABLE IF EXISTS dbo.TipoOportunidad;
DROP TABLE IF EXISTS dbo.UnidadCierre;
GO

/* ================================================================================================
   TABLAS DE CATÁLOGO
================================================================================================ */

CREATE TABLE dbo.TipoCliente (
    id_tipo_cliente INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT PK_TipoCliente PRIMARY KEY CLUSTERED (id_tipo_cliente),
    CONSTRAINT UQ_TipoCliente_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.RolEmpleado (
    id_rol INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    CONSTRAINT PK_RolEmpleado PRIMARY KEY CLUSTERED (id_rol),
    CONSTRAINT UQ_RolEmpleado_Nombre UNIQUE (nombre)
);
GO

CREATE TABLE dbo.TipoOportunidad (
    id_tipo_oportunidad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    CONSTRAINT PK_TipoOportunidad PRIMARY KEY CLUSTERED (id_tipo_oportunidad),
    CONSTRAINT UQ_TipoOportunidad_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.EstadoOportunidad (
    id_estado_oportunidad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(20) NOT NULL,
    CONSTRAINT PK_EstadoOportunidad PRIMARY KEY CLUSTERED (id_estado_oportunidad),
    CONSTRAINT UQ_EstadoOportunidad_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.ResultadoOportunidad (
    id_resultado INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(20) NOT NULL,
    CONSTRAINT PK_ResultadoOportunidad PRIMARY KEY CLUSTERED (id_resultado),
    CONSTRAINT UQ_ResultadoOportunidad_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.UnidadCierre (
    id_unidad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(15) NOT NULL,
    CONSTRAINT PK_UnidadCierre PRIMARY KEY CLUSTERED (id_unidad),
    CONSTRAINT UQ_UnidadCierre_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.TipoEtapa (
    id_tipo_etapa INT IDENTITY(1,1) NOT NULL,
    nombre_etapa VARCHAR(50) NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,
    orden INT NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT PK_TipoEtapa PRIMARY KEY CLUSTERED (id_tipo_etapa),
    CONSTRAINT UQ_TipoEtapa_Nombre UNIQUE (nombre_etapa),
    CONSTRAINT CHK_TipoEtapa_Porcentaje CHECK (porcentaje >= 0 AND porcentaje <= 100)
);
GO

CREATE TABLE dbo.TipoDocumento (
    id_tipo_documento INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    CONSTRAINT PK_TipoDocumento PRIMARY KEY CLUSTERED (id_tipo_documento),
    CONSTRAINT UQ_TipoDocumento_Nombre UNIQUE (nombre)
);
GO

CREATE TABLE dbo.TipoActividad (
    id_tipo_actividad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    CONSTRAINT PK_TipoActividad PRIMARY KEY CLUSTERED (id_tipo_actividad),
    CONSTRAINT UQ_TipoActividad_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.Prioridad (
    id_prioridad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(15) NOT NULL,
    CONSTRAINT PK_Prioridad PRIMARY KEY CLUSTERED (id_prioridad),
    CONSTRAINT UQ_Prioridad_Codigo UNIQUE (codigo)
);
GO

CREATE TABLE dbo.EstadoActividad (
    id_estado_actividad INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(15) NOT NULL,
    nombre VARCHAR(20) NOT NULL,
    CONSTRAINT PK_EstadoActividad PRIMARY KEY CLUSTERED (id_estado_actividad),
    CONSTRAINT UQ_EstadoActividad_Codigo UNIQUE (codigo)
);
GO

/* ================================================================================================
   TABLAS PRINCIPALES
================================================================================================ */

CREATE TABLE dbo.Cliente (
    id_cliente INT IDENTITY(1,1) NOT NULL,
    nombre_comercial VARCHAR(100) NOT NULL,
    razon_social VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(20) NULL,
    celular VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    contacto_nombre VARCHAR(100) NULL,
    id_tipo_cliente INT NOT NULL,
    fecha_registro DATETIME NOT NULL CONSTRAINT DF_Cliente_FechaRegistro DEFAULT (GETDATE()),
    activo BIT NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT (1),
    CONSTRAINT PK_Cliente PRIMARY KEY CLUSTERED (id_cliente),
    CONSTRAINT FK_Cliente_TipoCliente FOREIGN KEY (id_tipo_cliente) REFERENCES dbo.TipoCliente(id_tipo_cliente)
);
GO

CREATE TABLE dbo.Empleado (
    id_empleado INT IDENTITY(1,1) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NULL,
    id_rol INT NOT NULL,
    fecha_contratacion DATE NOT NULL CONSTRAINT DF_Empleado_FechaContratacion DEFAULT (CONVERT(DATE, GETDATE())),
    activo BIT NOT NULL CONSTRAINT DF_Empleado_Activo DEFAULT (1),
    CONSTRAINT PK_Empleado PRIMARY KEY CLUSTERED (id_empleado),
    CONSTRAINT UQ_Empleado_Email UNIQUE (email),
    CONSTRAINT FK_Empleado_RolEmpleado FOREIGN KEY (id_rol) REFERENCES dbo.RolEmpleado(id_rol)
);
GO

CREATE TABLE dbo.Oportunidad (
    id_oportunidad INT IDENTITY(1,1) NOT NULL,
    numero_oportunidad VARCHAR(20) NOT NULL,
    nombre_oportunidad VARCHAR(150) NOT NULL,
    id_cliente INT NOT NULL,
    id_empleado_vendedor INT NOT NULL,
    id_empleado_gerente INT NOT NULL,
    id_tipo_oportunidad INT NOT NULL,
    id_estado_oportunidad INT NOT NULL,
    id_resultado INT NULL,
    fecha_inicio DATE NOT NULL CONSTRAINT DF_Oportunidad_FechaInicio DEFAULT (CONVERT(DATE, GETDATE())),
    fecha_cierre_real DATE NULL,
    cierre_planificado_valor INT NOT NULL,
    id_unidad_cierre INT NOT NULL,
    fecha_cierre_prevista DATE NOT NULL,
    monto_potencial DECIMAL(18,2) NOT NULL,
    monto_ponderado DECIMAL(18,2) NULL,
    porcentaje_avance DECIMAL(5,2) NULL,
    activo BIT NOT NULL CONSTRAINT DF_Oportunidad_Activo DEFAULT (1),
    CONSTRAINT PK_Oportunidad PRIMARY KEY CLUSTERED (id_oportunidad),
    CONSTRAINT UQ_Oportunidad_Numero UNIQUE (numero_oportunidad),
    CONSTRAINT FK_Oportunidad_Cliente FOREIGN KEY (id_cliente) REFERENCES dbo.Cliente(id_cliente),
    CONSTRAINT FK_Oportunidad_EmpleadoVendedor FOREIGN KEY (id_empleado_vendedor) REFERENCES dbo.Empleado(id_empleado),
    CONSTRAINT FK_Oportunidad_EmpleadoGerente FOREIGN KEY (id_empleado_gerente) REFERENCES dbo.Empleado(id_empleado),
    CONSTRAINT FK_Oportunidad_TipoOportunidad FOREIGN KEY (id_tipo_oportunidad) REFERENCES dbo.TipoOportunidad(id_tipo_oportunidad),
    CONSTRAINT FK_Oportunidad_EstadoOportunidad FOREIGN KEY (id_estado_oportunidad) REFERENCES dbo.EstadoOportunidad(id_estado_oportunidad),
    CONSTRAINT FK_Oportunidad_ResultadoOportunidad FOREIGN KEY (id_resultado) REFERENCES dbo.ResultadoOportunidad(id_resultado),
    CONSTRAINT FK_Oportunidad_UnidadCierre FOREIGN KEY (id_unidad_cierre) REFERENCES dbo.UnidadCierre(id_unidad),
    CONSTRAINT CHK_Oportunidad_MontoPotencial CHECK (monto_potencial >= 0),
    CONSTRAINT CHK_Oportunidad_PorcentajeAvance CHECK (porcentaje_avance IS NULL OR (porcentaje_avance >= 0 AND porcentaje_avance <= 100))
);
GO

CREATE TABLE dbo.Etapa_Oportunidad (
    id_etapa_oportunidad INT IDENTITY(1,1) NOT NULL,
    id_oportunidad INT NOT NULL,
    id_tipo_etapa INT NOT NULL,
    id_empleado_ventas INT NOT NULL,
    fecha_inicio_etapa DATE NOT NULL CONSTRAINT DF_EtapaOportunidad_FechaInicio DEFAULT (CONVERT(DATE, GETDATE())),
    fecha_cierre_etapa DATE NULL,
    monto_potencial_etapa DECIMAL(18,2) NOT NULL,
    importe_ponderado_etapa DECIMAL(18,2) NOT NULL,
    id_tipo_documento INT NULL,
    num_documento VARCHAR(50) NULL,
    comentario VARCHAR(MAX) NULL,
    CONSTRAINT PK_EtapaOportunidad PRIMARY KEY CLUSTERED (id_etapa_oportunidad),
    CONSTRAINT FK_EtapaOportunidad_Oportunidad FOREIGN KEY (id_oportunidad) REFERENCES dbo.Oportunidad(id_oportunidad),
    CONSTRAINT FK_EtapaOportunidad_TipoEtapa FOREIGN KEY (id_tipo_etapa) REFERENCES dbo.TipoEtapa(id_tipo_etapa),
    CONSTRAINT FK_EtapaOportunidad_Empleado FOREIGN KEY (id_empleado_ventas) REFERENCES dbo.Empleado(id_empleado),
    CONSTRAINT FK_EtapaOportunidad_TipoDocumento FOREIGN KEY (id_tipo_documento) REFERENCES dbo.TipoDocumento(id_tipo_documento)
);
GO

CREATE TABLE dbo.Actividad (
    id_actividad INT IDENTITY(1,1) NOT NULL,
    numero_actividad VARCHAR(20) NOT NULL,
    id_cliente INT NOT NULL,
    id_empleado_responsable INT NOT NULL,
    id_tipo_actividad INT NOT NULL,
    asunto VARCHAR(200) NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME(7) NOT NULL,
    hora_fin TIME(7) NULL,
    duracion_minutos INT NULL,
    id_prioridad INT NOT NULL,
    comentario VARCHAR(MAX) NULL,
    id_estado_actividad INT NOT NULL,
    calle VARCHAR(150) NULL,
    ciudad VARCHAR(100) NULL,
    sala VARCHAR(50) NULL,
    fecha_creacion DATETIME NOT NULL CONSTRAINT DF_Actividad_FechaCreacion DEFAULT (GETDATE()),
    id_oportunidad INT NULL,
    CONSTRAINT PK_Actividad PRIMARY KEY CLUSTERED (id_actividad),
    CONSTRAINT UQ_Actividad_Numero UNIQUE (numero_actividad),
    CONSTRAINT FK_Actividad_Cliente FOREIGN KEY (id_cliente) REFERENCES dbo.Cliente(id_cliente),
    CONSTRAINT FK_Actividad_EmpleadoResponsable FOREIGN KEY (id_empleado_responsable) REFERENCES dbo.Empleado(id_empleado),
    CONSTRAINT FK_Actividad_TipoActividad FOREIGN KEY (id_tipo_actividad) REFERENCES dbo.TipoActividad(id_tipo_actividad),
    CONSTRAINT FK_Actividad_Prioridad FOREIGN KEY (id_prioridad) REFERENCES dbo.Prioridad(id_prioridad),
    CONSTRAINT FK_Actividad_EstadoActividad FOREIGN KEY (id_estado_actividad) REFERENCES dbo.EstadoActividad(id_estado_actividad),
    CONSTRAINT FK_Actividad_Oportunidad FOREIGN KEY (id_oportunidad) REFERENCES dbo.Oportunidad(id_oportunidad)
);
GO

CREATE TABLE dbo.BitacoraCambios (
    id_bitacora INT IDENTITY(1,1) NOT NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    usuario VARCHAR(100) NOT NULL CONSTRAINT DF_BitacoraCambios_Usuario DEFAULT (SUSER_NAME()),
    fecha_cambio DATETIME NOT NULL CONSTRAINT DF_BitacoraCambios_Fecha DEFAULT (GETDATE()),
    valor_anterior VARCHAR(MAX) NULL,
    valor_nuevo VARCHAR(MAX) NULL,
    CONSTRAINT PK_BitacoraCambios PRIMARY KEY CLUSTERED (id_bitacora)
);
GO

/* ================================================================================================
   DATOS INICIALES DE CATÁLOGOS
================================================================================================ */

INSERT INTO dbo.TipoCliente (codigo, nombre, descripcion)
VALUES ('POTENCIAL', 'Potencial', 'Cliente potencial'), ('FINAL', 'Final', 'Cliente final');
GO

INSERT INTO dbo.RolEmpleado (nombre)
VALUES ('Vendedor'), ('Gerente'), ('Administrador');
GO

INSERT INTO dbo.TipoOportunidad (codigo, nombre)
VALUES ('NUEVA', 'Nueva'), ('RENOV', 'Renovación'), ('UPSELL', 'Venta adicional');
GO

INSERT INTO dbo.EstadoOportunidad (codigo, nombre)
VALUES ('ABIERTO', 'Abierto'), ('CERRADO', 'Cerrado');
GO

INSERT INTO dbo.ResultadoOportunidad (codigo, nombre)
VALUES ('ABIERTA', 'Abierta'), ('GANADA', 'Ganada'), ('PERDIDA', 'Perdida');
GO

INSERT INTO dbo.UnidadCierre (codigo, nombre)
VALUES ('DIAS', 'Días'), ('SEMANAS', 'Semanas'), ('MESES', 'Meses');
GO

INSERT INTO dbo.TipoEtapa (nombre_etapa, porcentaje, orden, descripcion)
VALUES
('Calificación', 10.00, 1, 'Identificación y calificación inicial'),
('Necesidad', 25.00, 2, 'Levantamiento de necesidades'),
('Propuesta', 50.00, 3, 'Presentación de propuesta comercial'),
('Negociación', 70.00, 4, 'Negociación de condiciones'),
('Acuerdo de cierre', 90.00, 5, 'Etapa previa al cierre'),
('Ganada', 100.00, 6, 'Oportunidad cerrada exitosamente'),
('Perdida', 0.00, 7, 'Oportunidad cerrada sin éxito');
GO

INSERT INTO dbo.TipoDocumento (nombre)
VALUES ('Cotización'), ('Propuesta'), ('Contrato'), ('Orden de compra');
GO

INSERT INTO dbo.TipoActividad (codigo, nombre)
VALUES ('LLAMADA', 'Llamada'), ('REUNION', 'Reunión'), ('CORREO', 'Correo'), ('VISITA', 'Visita');
GO

INSERT INTO dbo.Prioridad (codigo, nombre)
VALUES ('BAJA', 'Baja'), ('NORMAL', 'Normal'), ('ALTA', 'Alto');
GO

INSERT INTO dbo.EstadoActividad (codigo, nombre)
VALUES
('PROCESO', 'En Proceso'),
('ESPERA', 'En Espera'),
('CONCLUIDO', 'Concluido'),
('NO_INICIADO', 'No Iniciado'),
('INACTIVO', 'Inactivo'),
('CERRADO', 'Cerrado');
GO

/* ================================================================================================
   DATOS DEMO MÍNIMOS
================================================================================================ */

INSERT INTO dbo.Empleado (nombre_completo, email, telefono, id_rol)
VALUES
('Administrador CRM', 'admin@crmventas.local', '0000-0000', 3),
('Vendedor Demo', 'vendedor@crmventas.local', '1111-1111', 1),
('Gerente Demo', 'gerente@crmventas.local', '2222-2222', 2);
GO

INSERT INTO dbo.Cliente (nombre_comercial, razon_social, direccion, telefono, celular, email, contacto_nombre, id_tipo_cliente)
VALUES ('Cliente Demo', 'Cliente Demo S.A.', 'Ciudad de Guatemala', '2222-2222', '5555-5555', 'cliente@demo.com', 'Contacto Demo', 1);
GO

INSERT INTO dbo.Oportunidad (
    numero_oportunidad, nombre_oportunidad, id_cliente, id_empleado_vendedor, id_empleado_gerente,
    id_tipo_oportunidad, id_estado_oportunidad, id_resultado, cierre_planificado_valor,
    id_unidad_cierre, fecha_cierre_prevista, monto_potencial, monto_ponderado, porcentaje_avance, activo
)
VALUES (
    'OP-1', 'Oportunidad Demo', 1, 2, 3,
    1, 1, 1, 30,
    1, DATEADD(DAY, 30, CONVERT(DATE, GETDATE())), 10000.00, 1000.00, 10.00, 1
);
GO

INSERT INTO dbo.Etapa_Oportunidad (
    id_oportunidad, id_tipo_etapa, id_empleado_ventas,
    monto_potencial_etapa, importe_ponderado_etapa, comentario
)
VALUES (1, 1, 2, 10000.00, 1000.00, 'Etapa inicial de oportunidad demo');
GO

/* ================================================================================================
   VALIDACIÓN FINAL
================================================================================================ */

SELECT 'Base CRMVentas creada correctamente' AS mensaje;
GO

SELECT name AS tabla
FROM sys.tables
ORDER BY name;
GO
