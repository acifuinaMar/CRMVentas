
-- Archivo para crear el Data Warehouse del proyecto CRM Ventas
-- Parte trabajada por Steve

IF DB_ID('CRMVentas_DW') IS NULL
BEGIN
    CREATE DATABASE CRMVentas_DW;
END
GO

USE CRMVentas_DW;
GO

-- Se eliminan las tablas si ya existen para poder ejecutar el script otra vez sin problemas

IF OBJECT_ID('FactOportunidades', 'U') IS NOT NULL DROP TABLE FactOportunidades;
IF OBJECT_ID('DimFecha', 'U') IS NOT NULL DROP TABLE DimFecha;
IF OBJECT_ID('DimEtapa', 'U') IS NOT NULL DROP TABLE DimEtapa;
IF OBJECT_ID('DimEmpleado', 'U') IS NOT NULL DROP TABLE DimEmpleado;
IF OBJECT_ID('DimCliente', 'U') IS NOT NULL DROP TABLE DimCliente;
GO

-- Tabla para guardar la informacion principal de los clientes

CREATE TABLE DimCliente (
    id_cliente_dw INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente_origen INT NOT NULL,
    nombre_comercial VARCHAR(100) NOT NULL,
    tipo_cliente VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL
);
GO

-- Tabla para guardar los empleados que participan en las oportunidades

CREATE TABLE DimEmpleado (
    id_empleado_dw INT IDENTITY(1,1) PRIMARY KEY,
    id_empleado_origen INT NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    rol VARCHAR(30) NOT NULL,
    email VARCHAR(100) NULL
);
GO

-- Tabla para guardar las etapas de seguimiento de cada oportunidad

CREATE TABLE DimEtapa (
    id_etapa_dw INT IDENTITY(1,1) PRIMARY KEY,
    id_tipo_etapa_origen INT NOT NULL,
    nombre_etapa VARCHAR(50) NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,
    orden INT NOT NULL
);
GO

-- Tabla para manejar las fechas dentro de los reportes

CREATE TABLE DimFecha (
    id_fecha INT PRIMARY KEY,
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    dia INT NOT NULL
);
GO

-- Tabla principal donde se concentra la informacion de las oportunidades

CREATE TABLE FactOportunidades (
    id_fact_oportunidad INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente_dw INT NOT NULL,
    id_empleado_dw INT NOT NULL,
    id_etapa_dw INT NULL,
    id_fecha INT NOT NULL,
    numero_oportunidad VARCHAR(20) NOT NULL,
    nombre_oportunidad VARCHAR(150) NOT NULL,
    monto_potencial DECIMAL(18,2) NOT NULL,
    monto_ponderado DECIMAL(18,2) NULL,
    porcentaje_avance DECIMAL(5,2) NULL,
    estado_oportunidad VARCHAR(20) NOT NULL,
    resultado_oportunidad VARCHAR(20) NULL,

    FOREIGN KEY (id_cliente_dw) REFERENCES DimCliente(id_cliente_dw),
    FOREIGN KEY (id_empleado_dw) REFERENCES DimEmpleado(id_empleado_dw),
    FOREIGN KEY (id_etapa_dw) REFERENCES DimEtapa(id_etapa_dw),
    FOREIGN KEY (id_fecha) REFERENCES DimFecha(id_fecha)
);
GO