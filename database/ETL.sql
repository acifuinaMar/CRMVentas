USE CRMVentas_DW;
GO

-- ==========================================
-- 1. DESACTIVAR RESTRICCIONES
-- ==========================================
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- ==========================================
-- 2. CARGAR DIMENSIONES
-- ==========================================
CREATE OR ALTER PROCEDURE sp_CargarDimensiones
AS
BEGIN
    SET NOCOUNT ON;

    -- Limpiar tablas
    DELETE FROM FactOportunidades;
    DELETE FROM FactActividades;
    DELETE FROM DimFecha;
    DELETE FROM DimEmpleado;
    DELETE FROM DimCliente;

    -- =========================
    -- DIM CLIENTE
    -- =========================
    INSERT INTO DimCliente
    (
        id_cliente_origen,
        nombre_comercial,
        tipo_cliente
    )
    SELECT
        id_cliente,
        ISNULL(nombre_comercial, 'Sin Nombre'),
        'Potencial'
    FROM CRMVentas.dbo.Cliente;

    -- =========================
    -- DIM EMPLEADO
    -- =========================
    INSERT INTO DimEmpleado
    (
        id_empleado_origen,
        nombre_completo,
        rol
    )
    SELECT
        id_empleado,
        ISNULL(nombre_completo, 'Sin Nombre'),
        'Vendedor'
    FROM CRMVentas.dbo.Empleado;

    -- =========================
    -- DIM FECHA
    -- =========================
    INSERT INTO DimFecha
    (
        id_fecha,
        fecha,
        anio,
        mes,
        dia
    )
    SELECT DISTINCT
        YEAR(fecha_inicio) * 10000
        + MONTH(fecha_inicio) * 100
        + DAY(fecha_inicio) AS id_fecha,

        fecha_inicio,
        YEAR(fecha_inicio),
        MONTH(fecha_inicio),
        DAY(fecha_inicio)

    FROM CRMVentas.dbo.Oportunidad
    WHERE fecha_inicio IS NOT NULL;

END;
GO

-- ==========================================
-- 3. CARGAR FACT OPORTUNIDADES
-- ==========================================
CREATE OR ALTER PROCEDURE sp_CargarDataWarehouse
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO FactOportunidades
    (
        id_cliente_dw,
        id_empleado_dw,
        id_fecha,
        numero_oportunidad,
        nombre_oportunidad,
        monto_potencial,
        estado_oportunidad
    )
    SELECT
        DC.id_cliente_dw,
        DE.id_empleado_dw,
        DF.id_fecha,
        O.numero_oportunidad,
        O.nombre_oportunidad,
        O.monto_potencial,
        'Activa'

    FROM CRMVentas.dbo.Oportunidad O

    LEFT JOIN DimCliente DC
        ON O.id_cliente = DC.id_cliente_origen

    LEFT JOIN DimEmpleado DE
        ON O.id_empleado_vendedor = DE.id_empleado_origen

    INNER JOIN DimFecha DF
        ON O.fecha_inicio = DF.fecha;

END;
GO

-- ==========================================
-- 4. CARGAR FACT ACTIVIDADES
-- ==========================================
CREATE OR ALTER PROCEDURE sp_CargarActividades
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO FactActividades
    (
        id_cliente_dw,
        id_empleado_dw,
        tipo_actividad,
        estado_actividad,
        fecha_actividad
    )
    SELECT
        DC.id_cliente_dw,
        DE.id_empleado_dw,
        A.id_tipo_actividad,
        A.id_estado_actividad,
        A.fecha

    FROM CRMVentas.dbo.Actividad A

    LEFT JOIN DimCliente DC
        ON A.id_cliente = DC.id_cliente_origen

    LEFT JOIN DimEmpleado DE
        ON A.id_empleado_responsable = DE.id_empleado_origen;

END;
GO

-- ==========================================
-- 5. ETL COMPLETO
-- ==========================================
CREATE OR ALTER PROCEDURE sp_Ejecutar_ETL_Completo
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Iniciando carga segura...';

    EXEC sp_CargarDimensiones;
    EXEC sp_CargarDataWarehouse;
    EXEC sp_CargarActividades;

    PRINT 'ETL completado exitosamente.';
END;
GO

-- ==========================================
-- 6. EJECUTAR ETL
-- ==========================================
EXEC sp_Ejecutar_ETL_Completo;
GO

-- ==========================================
-- 7. REACTIVAR RESTRICCIONES
-- ==========================================
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

SELECT * FROM DimFecha;

SELECT COUNT(*) AS Clientes FROM DimCliente;

SELECT COUNT(*) AS Empleados FROM DimEmpleado;

SELECT COUNT(*) AS Fechas FROM DimFecha;

SELECT COUNT(*) AS Oportunidades FROM FactOportunidades;

SELECT COUNT(*) AS Actividades FROM FactActividades;