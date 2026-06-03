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
    R.nombre AS Resultado,
    COUNT(O.id_oportunidad) AS TotalOportunidades,
    SUM(ISNULL(O.monto_potencial, 0)) AS MontoPotencial,
    SUM(ISNULL(O.monto_ponderado, 0)) AS MontoPonderado
FROM Oportunidad O
INNER JOIN ResultadoOportunidad R
    ON O.id_resultado = R.id_resultado
WHERE O.activo = 1
GROUP BY R.nombre;
GO
