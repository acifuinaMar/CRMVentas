/* ============================================================
   DATA WAREHOUSE CRMVENTAS + ETL
   Base transaccional: CRMVentas
   Base analítica: DW_CRMVentas
   ============================================================ */

IF DB_ID('DW_CRMVentas') IS NULL
BEGIN
    CREATE DATABASE DW_CRMVentas;
END;
GO

USE DW_CRMVentas;
GO

IF OBJECT_ID('dbo.FactOportunidades', 'U') IS NOT NULL DROP TABLE dbo.FactOportunidades;
IF OBJECT_ID('dbo.DimFecha', 'U') IS NOT NULL DROP TABLE dbo.DimFecha;
IF OBJECT_ID('dbo.DimCliente', 'U') IS NOT NULL DROP TABLE dbo.DimCliente;
IF OBJECT_ID('dbo.DimEmpleado', 'U') IS NOT NULL DROP TABLE dbo.DimEmpleado;
IF OBJECT_ID('dbo.DimResultado', 'U') IS NOT NULL DROP TABLE dbo.DimResultado;
GO

CREATE TABLE dbo.DimCliente (
    cliente_key INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT,
    nombre_comercial NVARCHAR(150),
    tipo_cliente NVARCHAR(100)
);
GO

CREATE TABLE dbo.DimEmpleado (
    empleado_key INT IDENTITY(1,1) PRIMARY KEY,
    id_empleado INT,
    nombre_completo NVARCHAR(150),
    rol NVARCHAR(100)
);
GO

CREATE TABLE dbo.DimResultado (
    resultado_key INT IDENTITY(1,1) PRIMARY KEY,
    id_resultado INT,
    resultado NVARCHAR(100)
);
GO

CREATE TABLE dbo.DimFecha (
    fecha_key INT PRIMARY KEY,
    fecha DATE,
    anio INT,
    mes INT,
    nombre_mes NVARCHAR(20),
    dia INT
);
GO

CREATE TABLE dbo.FactOportunidades (
    fact_key INT IDENTITY(1,1) PRIMARY KEY,
    fecha_key INT,
    cliente_key INT,
    empleado_key INT,
    resultado_key INT,
    id_oportunidad INT,
    monto_potencial DECIMAL(18,2),
    monto_ponderado DECIMAL(18,2),
    porcentaje_avance DECIMAL(5,2),
    CONSTRAINT FK_Fact_Fecha FOREIGN KEY (fecha_key) REFERENCES dbo.DimFecha(fecha_key),
    CONSTRAINT FK_Fact_Cliente FOREIGN KEY (cliente_key) REFERENCES dbo.DimCliente(cliente_key),
    CONSTRAINT FK_Fact_Empleado FOREIGN KEY (empleado_key) REFERENCES dbo.DimEmpleado(empleado_key),
    CONSTRAINT FK_Fact_Resultado FOREIGN KEY (resultado_key) REFERENCES dbo.DimResultado(resultado_key)
);
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_CargarDW_CRMVentas
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.FactOportunidades;
        DELETE FROM dbo.DimFecha;
        DELETE FROM dbo.DimCliente;
        DELETE FROM dbo.DimEmpleado;
        DELETE FROM dbo.DimResultado;

        DBCC CHECKIDENT ('dbo.FactOportunidades', RESEED, 0);
        DBCC CHECKIDENT ('dbo.DimCliente', RESEED, 0);
        DBCC CHECKIDENT ('dbo.DimEmpleado', RESEED, 0);
        DBCC CHECKIDENT ('dbo.DimResultado', RESEED, 0);

        INSERT INTO dbo.DimCliente (id_cliente, nombre_comercial, tipo_cliente)
        SELECT C.id_cliente, C.nombre_comercial, TC.nombre
        FROM CRMVentas.dbo.Cliente C
        LEFT JOIN CRMVentas.dbo.TipoCliente TC
            ON C.id_tipo_cliente = TC.id_tipo_cliente;

        INSERT INTO dbo.DimEmpleado (id_empleado, nombre_completo, rol)
        SELECT E.id_empleado, E.nombre_completo, R.nombre
        FROM CRMVentas.dbo.Empleado E
        LEFT JOIN CRMVentas.dbo.RolEmpleado R
            ON E.id_rol = R.id_rol;

        INSERT INTO dbo.DimResultado (id_resultado, resultado)
        SELECT id_resultado, nombre
        FROM CRMVentas.dbo.ResultadoOportunidad;

        INSERT INTO dbo.DimFecha (fecha_key, fecha, anio, mes, nombre_mes, dia)
        SELECT DISTINCT
            CONVERT(INT, FORMAT(CAST(O.fecha_inicio AS DATE), 'yyyyMMdd')),
            CAST(O.fecha_inicio AS DATE),
            YEAR(O.fecha_inicio),
            MONTH(O.fecha_inicio),
            DATENAME(MONTH, O.fecha_inicio),
            DAY(O.fecha_inicio)
        FROM CRMVentas.dbo.Oportunidad O
        WHERE O.fecha_inicio IS NOT NULL;

        INSERT INTO dbo.FactOportunidades (
            fecha_key,
            cliente_key,
            empleado_key,
            resultado_key,
            id_oportunidad,
            monto_potencial,
            monto_ponderado,
            porcentaje_avance
        )
        SELECT
            DF.fecha_key,
            DC.cliente_key,
            DE.empleado_key,
            DR.resultado_key,
            O.id_oportunidad,
            ISNULL(O.monto_potencial, 0),
            ISNULL(O.monto_ponderado, 0),
            ISNULL(O.porcentaje_avance, 0)
        FROM CRMVentas.dbo.Oportunidad O
        INNER JOIN dbo.DimFecha DF
            ON DF.fecha = CAST(O.fecha_inicio AS DATE)
        INNER JOIN dbo.DimCliente DC
            ON DC.id_cliente = O.id_cliente
        INNER JOIN dbo.DimEmpleado DE
            ON DE.id_empleado = O.id_empleado_vendedor
        LEFT JOIN dbo.DimResultado DR
            ON DR.id_resultado = O.id_resultado;

        COMMIT TRANSACTION;

        SELECT 'ETL ejecutado correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER VIEW dbo.vw_DashboardDW
AS
SELECT
    E.nombre_completo AS Vendedor,
    R.resultado AS Resultado,
    COUNT(F.id_oportunidad) AS TotalOportunidades,
    SUM(F.monto_potencial) AS MontoPotencial,
    SUM(F.monto_ponderado) AS MontoPonderado
FROM dbo.FactOportunidades F
INNER JOIN dbo.DimEmpleado E
    ON F.empleado_key = E.empleado_key
LEFT JOIN dbo.DimResultado R
    ON F.resultado_key = R.resultado_key
GROUP BY E.nombre_completo, R.resultado;
GO

EXEC dbo.sp_ETL_CargarDW_CRMVentas;
GO

SELECT * FROM dbo.vw_DashboardDW;
GO
