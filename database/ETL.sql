USE CRMVentas_DW;
GO

/* ============================================================
   0. VALIDACIONES Y AJUSTES DE ESTRUCTURA
   ============================================================ */

IF DB_ID('CRMVentas') IS NULL
BEGIN
    THROW 50000, 'No existe la base de datos origen CRMVentas. Ejecute primero los scripts de la BD transaccional.', 1;
END;
GO

IF OBJECT_ID('dbo.DimCliente', 'U') IS NULL
   OR OBJECT_ID('dbo.DimEmpleado', 'U') IS NULL
   OR OBJECT_ID('dbo.DimEtapa', 'U') IS NULL
   OR OBJECT_ID('dbo.DimFecha', 'U') IS NULL
   OR OBJECT_ID('dbo.FactOportunidades', 'U') IS NULL
BEGIN
    THROW 50001, 'Faltan tablas base del Data Warehouse. Ejecute primero 01_creacion_datawarehouse.sql.', 1;
END;
GO
IF OBJECT_ID('dbo.FactActividades', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactActividades (
        id_fact_actividad INT IDENTITY(1,1) PRIMARY KEY,
        id_cliente_dw INT NOT NULL,
        id_empleado_dw INT NOT NULL,
        id_fecha INT NOT NULL,
        numero_actividad VARCHAR(20) NOT NULL,
        asunto VARCHAR(200) NOT NULL,
        tipo_actividad VARCHAR(50) NULL,
        prioridad VARCHAR(50) NULL,
        estado_actividad VARCHAR(50) NULL,
        duracion_minutos INT NULL,

        CONSTRAINT FK_FactActividades_DimCliente
            FOREIGN KEY (id_cliente_dw) REFERENCES dbo.DimCliente(id_cliente_dw),

        CONSTRAINT FK_FactActividades_DimEmpleado
            FOREIGN KEY (id_empleado_dw) REFERENCES dbo.DimEmpleado(id_empleado_dw),

        CONSTRAINT FK_FactActividades_DimFecha
            FOREIGN KEY (id_fecha) REFERENCES dbo.DimFecha(id_fecha)
    );
END;
GO

/* ============================================================
   1. CARGA DE DIMENSIONES
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.sp_CargarDimensiones
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Limpiar hechos primero para no romper FK
    DELETE FROM dbo.FactActividades;
    DELETE FROM dbo.FactOportunidades;

    -- Luego limpiar dimensiones
    DELETE FROM dbo.DimFecha;
    DELETE FROM dbo.DimEtapa;
    DELETE FROM dbo.DimEmpleado;
    DELETE FROM dbo.DimCliente;

    -- Reiniciar IDs identity para que el DW quede limpio
    DBCC CHECKIDENT ('dbo.DimCliente', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimEmpleado', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimEtapa', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.FactOportunidades', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.FactActividades', RESEED, 0) WITH NO_INFOMSGS;

    -- Dimensión Cliente
    INSERT INTO dbo.DimCliente
    (
        id_cliente_origen,
        nombre_comercial,
        tipo_cliente,
        telefono,
        email
    )
    SELECT
        C.id_cliente,
        ISNULL(C.nombre_comercial, 'Sin nombre') AS nombre_comercial,
        ISNULL(TC.nombre, 'Sin tipo') AS tipo_cliente,
        C.telefono,
        C.email
    FROM CRMVentas.dbo.Cliente C
    LEFT JOIN CRMVentas.dbo.TipoCliente TC
        ON C.id_tipo_cliente = TC.id_tipo_cliente;

    -- Dimensión Empleado
    INSERT INTO dbo.DimEmpleado
    (
        id_empleado_origen,
        nombre_completo,
        rol,
        email
    )
    SELECT
        E.id_empleado,
        ISNULL(E.nombre_completo, 'Sin nombre') AS nombre_completo,
        ISNULL(RE.nombre_rol, 'Sin rol') AS rol,
        E.email
    FROM CRMVentas.dbo.Empleado E
    LEFT JOIN CRMVentas.dbo.RolEmpleado RE
        ON E.id_rol = RE.id_rol;

    -- Dimensión Etapa
    INSERT INTO dbo.DimEtapa
    (
        id_tipo_etapa_origen,
        nombre_etapa,
        porcentaje,
        orden
    )
    SELECT
        TE.id_tipo_etapa,
        TE.nombre_etapa,
        TE.porcentaje,
        TE.orden
    FROM CRMVentas.dbo.TipoEtapa TE;

    -- Dimensión Fecha: se cargan fechas desde oportunidades y actividades
    INSERT INTO dbo.DimFecha
    (
        id_fecha,
        fecha,
        anio,
        mes,
        dia
    )
    SELECT DISTINCT
        YEAR(F.fecha) * 10000 + MONTH(F.fecha) * 100 + DAY(F.fecha) AS id_fecha,
        F.fecha,
        YEAR(F.fecha) AS anio,
        MONTH(F.fecha) AS mes,
        DAY(F.fecha) AS dia
    FROM
    (
        SELECT CAST(fecha_inicio AS DATE) AS fecha
        FROM CRMVentas.dbo.Oportunidad
        WHERE fecha_inicio IS NOT NULL

        UNION

        SELECT CAST(fecha AS DATE) AS fecha
        FROM CRMVentas.dbo.Actividad
        WHERE fecha IS NOT NULL
    ) F;
END;
GO

/* ============================================================
   2. CARGA DE FACT OPORTUNIDADES
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.sp_CargarFactOportunidades
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

INSERT INTO FactOportunidades (
    id_cliente_dw,
    id_empleado_dw,
    id_etapa_dw,
    id_fecha,
    numero_oportunidad,
    nombre_oportunidad,
    monto_potencial,
    monto_ponderado,
    porcentaje_avance,
    estado_oportunidad,
    resultado_oportunidad
)
SELECT
    DC.id_cliente_dw,
    DE.id_empleado_dw,
    DETA.id_etapa_dw,
    DF.id_fecha,
    O.numero_oportunidad,
    O.nombre_oportunidad,
    O.monto_potencial,
    O.monto_ponderado,
    O.porcentaje_avance,
    CASE 
        WHEN O.id_estado_oportunidad = 1 THEN 'Abierta'
        WHEN O.id_estado_oportunidad = 2 THEN 'Ganada'
        WHEN O.id_estado_oportunidad = 3 THEN 'Perdida'
        ELSE 'Desconocido'
    END AS estado_oportunidad,
    CASE 
        WHEN O.id_resultado = 1 THEN 'Sin resultado'
        WHEN O.id_resultado = 2 THEN 'Ganada'
        WHEN O.id_resultado = 3 THEN 'Perdida'
        ELSE NULL
    END AS resultado_oportunidad
FROM CRMVentas.dbo.Oportunidad O
INNER JOIN DimCliente DC
    ON DC.id_cliente = O.id_cliente
INNER JOIN DimEmpleado DE
    ON DE.id_empleado = O.id_empleado_vendedor
LEFT JOIN DimEtapa DETA
    ON DETA.porcentaje = O.porcentaje_avance
INNER JOIN DimFecha DF
    ON DF.fecha = CAST(O.fecha_inicio AS DATE)
WHERE O.activo = 1;
GO

/* ============================================================
   3. CARGA DE FACT ACTIVIDADES
   ============================================================ */

USE CRMVentas_DW;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CargarFactOportunidades
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM FactOportunidades;

    INSERT INTO FactOportunidades (
        id_cliente_dw,
        id_empleado_dw,
        id_etapa_dw,
        id_fecha,
        numero_oportunidad,
        nombre_oportunidad,
        monto_potencial,
        monto_ponderado,
        porcentaje_avance,
        estado_oportunidad,
        resultado_oportunidad
    )
    SELECT
        DC.id_cliente_dw,
        DE.id_empleado_dw,
        DETA.id_etapa_dw,
        DF.id_fecha,
        O.numero_oportunidad,
        O.nombre_oportunidad,
        O.monto_potencial,
        O.monto_ponderado,
        O.porcentaje_avance,
        CASE 
            WHEN O.id_estado_oportunidad = 1 THEN 'Abierta'
            WHEN O.id_estado_oportunidad = 2 THEN 'Ganada'
            WHEN O.id_estado_oportunidad = 3 THEN 'Perdida'
            ELSE 'Desconocida'
        END AS estado_oportunidad,
        CASE 
            WHEN O.id_resultado = 2 THEN 'Ganada'
            WHEN O.id_resultado = 3 THEN 'Perdida'
            ELSE 'Sin resultado'
        END AS resultado_oportunidad
    FROM CRMVentas.dbo.Oportunidad O
    INNER JOIN DimCliente DC
        ON DC.id_cliente_origen = O.id_cliente
    INNER JOIN DimEmpleado DE
        ON DE.id_empleado_origen = O.id_empleado_vendedor
    INNER JOIN DimFecha DF
        ON DF.fecha = CAST(O.fecha_inicio AS DATE)
    LEFT JOIN DimEtapa DETA
        ON DETA.porcentaje = O.porcentaje_avance
    WHERE O.activo = 1;
END;
GO
GO

/* ============================================================
   4. ETL COMPLETO CON TRANSACCIÓN Y MANEJO DE ERRORES
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.sp_Ejecutar_ETL_Completo
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT 'Iniciando ETL CRMVentas -> CRMVentas_DW...';

        EXEC dbo.sp_CargarDimensiones;
        EXEC dbo.sp_CargarFactOportunidades;
        EXEC dbo.sp_CargarFactActividades;

        COMMIT TRANSACTION;

        PRINT 'ETL completado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @Severidad INT = ERROR_SEVERITY();
        DECLARE @Estado INT = ERROR_STATE();

        RAISERROR(@MensajeError, @Severidad, @Estado);
    END CATCH;
END;
GO

/* ============================================================
   5. EJECUCIÓN Y VALIDACIÓN
   ============================================================ */

EXEC dbo.sp_Ejecutar_ETL_Completo;
GO

SELECT COUNT(*) AS Clientes FROM dbo.DimCliente;
SELECT COUNT(*) AS Empleados FROM dbo.DimEmpleado;
SELECT COUNT(*) AS Etapas FROM dbo.DimEtapa;
SELECT COUNT(*) AS Fechas FROM dbo.DimFecha;
SELECT COUNT(*) AS Oportunidades FROM dbo.FactOportunidades;
SELECT COUNT(*) AS Actividades FROM dbo.FactActividades;
GO

SELECT TOP 20 * FROM dbo.FactOportunidades ORDER BY id_fact_oportunidad DESC;
SELECT TOP 20 * FROM dbo.FactActividades ORDER BY id_fact_actividad DESC;
GO
