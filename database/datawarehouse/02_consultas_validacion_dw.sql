-- Archivo para revisar que el Data Warehouse fue creado correctamente
-- Parte trabajada por Steve

USE CRMVentas_DW;
GO

-- Consulta para ver las tablas creadas en el Data Warehouse

SELECT 
    name AS nombre_tabla
FROM sys.tables
ORDER BY name;
GO

-- Consulta para revisar la estructura de las dimensiones

SELECT 
    TABLE_NAME AS tabla,
    COLUMN_NAME AS columna,
    DATA_TYPE AS tipo_dato
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('DimCliente', 'DimEmpleado', 'DimEtapa', 'DimFecha')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

-- Consulta para revisar la estructura de la tabla principal de hechos

SELECT 
    TABLE_NAME AS tabla,
    COLUMN_NAME AS columna,
    DATA_TYPE AS tipo_dato
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FactOportunidades'
ORDER BY ORDINAL_POSITION;
GO

-- Consulta para verificar cuántos registros tiene cada tabla del Data Warehouse
-- Por ahora pueden aparecer en cero, porque esta parte solo valida la estructura del DW

SELECT 'DimCliente' AS tabla, COUNT(*) AS total_registros FROM DimCliente
UNION ALL
SELECT 'DimEmpleado', COUNT(*) FROM DimEmpleado
UNION ALL
SELECT 'DimEtapa', COUNT(*) FROM DimEtapa
UNION ALL
SELECT 'DimFecha', COUNT(*) FROM DimFecha
UNION ALL
SELECT 'FactOportunidades', COUNT(*) FROM FactOportunidades;
GO