-- ============================================
-- Crear base de datos
-- ============================================
CREATE DATABASE CRMVentas;
GO

USE CRMVentas;
GO

-- ============================================
-- TABLAS DE CATÁLOGO
-- ============================================

-- 1. Catálogo: Tipo de cliente
CREATE TABLE TipoCliente (
    id_tipo_cliente INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255) NULL
);
GO

INSERT INTO TipoCliente (codigo, nombre) VALUES 
('POT', 'Cliente Potencial'),
('FIN', 'Cliente Final');
GO

-- 2. Catálogo: Tipo de oportunidad
CREATE TABLE TipoOportunidad (
    id_tipo_oportunidad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(30) NOT NULL
);
GO

INSERT INTO TipoOportunidad (codigo, nombre) VALUES 
('VENTA', 'Venta'),
('COMPRA', 'Compra');
GO

-- 3. Catálogo: Estado de oportunidad
CREATE TABLE EstadoOportunidad (
    id_estado_oportunidad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL
);
GO

INSERT INTO EstadoOportunidad (codigo, nombre) VALUES 
('ABIERTO', 'Abierto'),
('CERRADO', 'Cerrado');
GO

-- 4. Catálogo: Resultado de oportunidad
CREATE TABLE ResultadoOportunidad (
    id_resultado INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL
);
GO

INSERT INTO ResultadoOportunidad (codigo, nombre) VALUES 
('ABIERTA', 'Abierta'),
('GANADA', 'Ganada'),
('PERDIDA', 'Perdida');
GO

-- 5. Catálogo: Tipo de etapa
CREATE TABLE TipoEtapa (
    id_tipo_etapa INT IDENTITY(1,1) PRIMARY KEY,
    nombre_etapa VARCHAR(50) NOT NULL UNIQUE,
    porcentaje DECIMAL(5,2) NOT NULL,
    orden INT NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT CHK_Porcentaje_Etapa CHECK (porcentaje BETWEEN 0 AND 100)
);
GO

INSERT INTO TipoEtapa (nombre_etapa, porcentaje, orden) VALUES 
('Calificación de la oportunidad', 30, 1),
('Toma de Decisión', 20, 2),
('Proceso de Toma de Decisión', 30, 3),
('Análisis de Proyecto', 50, 4),
('Presentación de Cotización', 80, 5),
('Validación de Propuesta', 95, 6),
('Acuerdo de Cierre', 100, 7);
GO

-- 6. Catálogo: Tipo de actividad
CREATE TABLE TipoActividad (
    id_tipo_actividad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(30) NOT NULL
);
GO

INSERT INTO TipoActividad (codigo, nombre) VALUES 
('LLAMADA', 'Llamada Telefónica'),
('REUNION', 'Reunión'),
('TAREA', 'Tarea'),
('NOTA', 'Nota'),
('VISITA', 'Agendar Visita'),
('PROYECTO', 'Proyecto Nuevo'),
('RECLAMO', 'Reclamo de Cliente');
GO

-- 7. Catálogo: Prioridad
CREATE TABLE Prioridad (
    id_prioridad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(15) NOT NULL
);
GO

INSERT INTO Prioridad (codigo, nombre) VALUES 
('ALTA', 'Alto'),
('NORMAL', 'Normal'),
('BAJA', 'Bajo');
GO

-- 8. Catálogo: Estado de actividad
CREATE TABLE EstadoActividad (
    id_estado_actividad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL
);
GO

INSERT INTO EstadoActividad (codigo, nombre) VALUES 
('PROCESO', 'En Proceso'),
('ESPERA', 'En Espera'),
('CONCLUIDO', 'Concluido'),
('NO_INICIADO', 'No Iniciado'),
('INACTIVO', 'Inactivo'),
('CERRADO', 'Cerrado');
GO

-- 9. Catálogo: Tipo de documento comercial
CREATE TABLE TipoDocumento (
    id_tipo_documento INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
GO

INSERT INTO TipoDocumento (nombre) VALUES 
('Ofertas de ventas'),
('Pedidos de cliente');
GO

-- 10. Catálogo: Rol de empleado
CREATE TABLE RolEmpleado (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);
GO

INSERT INTO RolEmpleado (nombre) VALUES 
('Vendedor'),
('Gerente Comercial'),
('Asistente Comercial');
GO

-- 11. Catálogo: Unidad de cierre planificado
CREATE TABLE UnidadCierre (
    id_unidad INT IDENTITY(1,1) PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(15) NOT NULL
);
GO

INSERT INTO UnidadCierre (codigo, nombre) VALUES 
('DIA', 'Días'),
('SEM', 'Semanas'),
('MES', 'Meses');
GO


-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- 12. Empleado (Personal Comercial)
CREATE TABLE Empleado (
    id_empleado INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL, --Normalizar el nombre even though va a tener mas campos
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL,
    id_rol INT NOT NULL,
    fecha_contratacion DATE NOT NULL DEFAULT GETDATE(),
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_rol) REFERENCES RolEmpleado(id_rol)
);
GO

-- 13. Cliente
CREATE TABLE Cliente (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_comercial VARCHAR(100) NOT NULL,
    razon_social VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(20) NULL,
    celular VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    contacto_nombre VARCHAR(100) NULL,
    id_tipo_cliente INT NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT GETDATE(),
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_tipo_cliente) REFERENCES TipoCliente(id_tipo_cliente)
);
GO

-- 14. Oportunidad
CREATE TABLE Oportunidad (
    id_oportunidad INT IDENTITY(1,1) PRIMARY KEY,
    numero_oportunidad VARCHAR(20) NOT NULL UNIQUE,
    nombre_oportunidad VARCHAR(150) NOT NULL,
    id_cliente INT NOT NULL,
    id_empleado_vendedor INT NOT NULL,     -- Asistente Comercial
    id_empleado_gerente INT NOT NULL,      -- Gerente Comercial
    id_tipo_oportunidad INT NOT NULL,
    id_estado_oportunidad INT NOT NULL,
    id_resultado INT NULL,                  -- Siempre que la oportunidad ya este cerrada
    fecha_inicio DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    fecha_cierre_real DATE NULL,
    -- cierre_planificado_valor + id_unidad_cierre = 2 semanas || 8 días || 2 meses
    cierre_planificado_valor INT NOT NULL,  -- Valor numérico
    id_unidad_cierre INT NOT NULL,          -- si van a ser días, semanas, meses
    fecha_cierre_prevista DATE NOT NULL,    -- fecha_inicio + cierre_planificado
    monto_potencial DECIMAL(18,2) NOT NULL CHECK (monto_potencial >= 0),
    monto_ponderado DECIMAL(18,2) NULL,     -- Se actualiza según etapa actual
    porcentaje_avance DECIMAL(5,2) NULL,    -- % según etapa actual
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    FOREIGN KEY (id_empleado_vendedor) REFERENCES Empleado(id_empleado),
    FOREIGN KEY (id_empleado_gerente) REFERENCES Empleado(id_empleado),
    FOREIGN KEY (id_tipo_oportunidad) REFERENCES TipoOportunidad(id_tipo_oportunidad),
    FOREIGN KEY (id_estado_oportunidad) REFERENCES EstadoOportunidad(id_estado_oportunidad),
    FOREIGN KEY (id_resultado) REFERENCES ResultadoOportunidad(id_resultado),
    FOREIGN KEY (id_unidad_cierre) REFERENCES UnidadCierre(id_unidad)
);
GO

-- 15. Etapa_Oportunidad (bitácora de oportunidad x si auditan)
CREATE TABLE Etapa_Oportunidad (
    id_etapa_oportunidad INT IDENTITY(1,1) PRIMARY KEY,
    id_oportunidad INT NOT NULL,
    id_tipo_etapa INT NOT NULL,
    id_empleado_ventas INT NOT NULL,
    fecha_inicio_etapa DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    fecha_cierre_etapa DATE NULL,
    monto_potencial_etapa DECIMAL(18,2) NOT NULL,
    importe_ponderado_etapa DECIMAL(18,2) NOT NULL,
    id_tipo_documento INT NULL,
    num_documento VARCHAR(50) NULL,
    comentario VARCHAR(MAX) NULL,
    FOREIGN KEY (id_oportunidad) REFERENCES Oportunidad(id_oportunidad),
    FOREIGN KEY (id_tipo_etapa) REFERENCES TipoEtapa(id_tipo_etapa),
    FOREIGN KEY (id_empleado_ventas) REFERENCES Empleado(id_empleado),
    FOREIGN KEY (id_tipo_documento) REFERENCES TipoDocumento(id_tipo_documento)
);
GO

-- 16. Actividad
CREATE TABLE Actividad (
    id_actividad INT IDENTITY(1,1) PRIMARY KEY,
    numero_actividad VARCHAR(20) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    id_empleado_responsable INT NOT NULL,
    id_tipo_actividad INT NOT NULL,
    asunto VARCHAR(200) NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NULL,
    duracion_minutos INT NULL,  -- Calculado
    id_prioridad INT NOT NULL,
    comentario VARCHAR(MAX) NULL,
    id_estado_actividad INT NOT NULL,
    -- Campos específicos para reunión
    calle VARCHAR(150) NULL,
    ciudad VARCHAR(100) NULL,
    sala VARCHAR(50) NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    FOREIGN KEY (id_empleado_responsable) REFERENCES Empleado(id_empleado),
    FOREIGN KEY (id_tipo_actividad) REFERENCES TipoActividad(id_tipo_actividad),
    FOREIGN KEY (id_prioridad) REFERENCES Prioridad(id_prioridad),
    FOREIGN KEY (id_estado_actividad) REFERENCES EstadoActividad(id_estado_actividad)
);
GO

-- ============================================
-- 17. TABLA PARA BITÁCORA
-- ============================================
CREATE TABLE BitacoraCambios (
    id_bitacora INT IDENTITY(1,1) PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro INT NOT NULL,
    accion VARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    usuario VARCHAR(100) NOT NULL DEFAULT SUSER_NAME(),
    fecha_cambio DATETIME NOT NULL DEFAULT GETDATE(),
    valor_anterior VARCHAR(MAX) NULL,
    valor_nuevo VARCHAR(MAX) NULL
);
GO