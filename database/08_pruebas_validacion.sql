USE CRMVentas;
GO

/* Probar cambio de etapa */
EXEC dbo.sp_CambiarEtapaOportunidad
    @id_oportunidad = 1,
    @id_tipo_etapa = 2,
    @comentario = 'Prueba de cambio de etapa con transacción explícita';
GO

/* Validar historial de etapas */
SELECT TOP 10 *
FROM Etapa_Oportunidad
ORDER BY fecha_inicio_etapa DESC;
GO

/* Validar actualización por trigger */
SELECT id_oportunidad, nombre_oportunidad, monto_potencial, monto_ponderado, porcentaje_avance
FROM Oportunidad
WHERE id_oportunidad = 1;
GO

/* Cerrar oportunidad como ganada */
EXEC dbo.sp_CerrarOportunidad
    @id_oportunidad = 1,
    @id_resultado = 2,
    @comentario = 'Cliente aceptó la propuesta';
GO

/* Validar bitácora */
SELECT TOP 20 *
FROM BitacoraCambios
ORDER BY fecha_cambio DESC;
GO

/* Validar reportes */
SELECT * FROM dbo.vw_OportunidadesPorGestor;
SELECT * FROM dbo.vw_OportunidadesPorMes;
SELECT * FROM dbo.vw_OportunidadesGanadasPerdidas;
SELECT * FROM dbo.vw_AuditoriaCRM;
GO

/* Prueba de transacción implícita */
SET IMPLICIT_TRANSACTIONS ON;
GO

UPDATE Oportunidad
SET porcentaje_avance = porcentaje_avance
WHERE id_oportunidad = 1;
GO

SELECT @@TRANCOUNT AS TransaccionesAbiertas;
GO

ROLLBACK;
GO

SET IMPLICIT_TRANSACTIONS OFF;
GO
