USE CRMVentas;
GO

CREATE OR ALTER VIEW dbo.vw_AuditoriaCRM
AS
SELECT
    id_bitacora,
    tabla_afectada,
    id_registro,
    accion,
    usuario,
    fecha_cambio,
    valor_anterior,
    valor_nuevo
FROM BitacoraCambios;
GO

CREATE OR ALTER VIEW dbo.vw_OportunidadesPorGestor
AS
SELECT
    E.nombre_completo AS Gestor,
    COUNT(O.id_oportunidad) AS TotalOportunidades,
    SUM(ISNULL(O.monto_potencial, 0)) AS MontoPotencial,
    SUM(ISNULL(O.monto_ponderado, 0)) AS MontoPonderado
FROM Oportunidad O
INNER JOIN Empleado E
    ON O.id_empleado_vendedor = E.id_empleado
WHERE O.activo = 1
GROUP BY E.nombre_completo;
GO

CREATE OR ALTER VIEW dbo.vw_OportunidadesPorMes
AS
SELECT
    YEAR(O.fecha_inicio) AS Anio,
    MONTH(O.fecha_inicio) AS Mes,
    COUNT(O.id_oportunidad) AS TotalOportunidades,
    SUM(ISNULL(O.monto_potencial, 0)) AS MontoPotencial,
    SUM(ISNULL(O.monto_ponderado, 0)) AS MontoPonderado
FROM Oportunidad O
WHERE O.activo = 1
GROUP BY YEAR(O.fecha_inicio), MONTH(O.fecha_inicio);
GO

CREATE OR ALTER VIEW dbo.vw_OportunidadesGanadasPerdidas
AS
SELECT
    CASE 
        WHEN O.id_estado_oportunidad = 2 THEN 'Ganada'
        WHEN O.id_estado_oportunidad = 3 THEN 'Perdida'
        ELSE 'Abierta'
    END AS Resultado,
    COUNT(O.id_oportunidad) AS TotalOportunidades,
    SUM(ISNULL(O.monto_potencial, 0)) AS MontoPotencial,
    SUM(
        CASE 
            WHEN O.id_estado_oportunidad = 2 THEN ISNULL(O.monto_potencial, 0)
            WHEN O.id_estado_oportunidad = 3 THEN 0
            ELSE ISNULL(O.monto_ponderado, 0)
        END
    ) AS MontoPonderado
FROM Oportunidad O
WHERE O.activo = 1
GROUP BY
    CASE 
        WHEN O.id_estado_oportunidad = 2 THEN 'Ganada'
        WHEN O.id_estado_oportunidad = 3 THEN 'Perdida'
        ELSE 'Abierta'
    END;
GO
