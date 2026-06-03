USE CRMVentas;
GO

/* ============================================================
   TRIGGER: Actualiza automáticamente avance y monto ponderado
   cuando se inserta una nueva etapa.
   ============================================================ */
CREATE OR ALTER TRIGGER dbo.trg_ActualizarOportunidadPorEtapa
ON dbo.Etapa_Oportunidad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE O
    SET 
        O.porcentaje_avance = TE.porcentaje,
        O.monto_ponderado = dbo.fn_CalcularImportePonderado(O.monto_potencial, TE.porcentaje)
    FROM Oportunidad O
    INNER JOIN inserted I 
        ON O.id_oportunidad = I.id_oportunidad
    INNER JOIN TipoEtapa TE 
        ON I.id_tipo_etapa = TE.id_tipo_etapa;
END;
GO

/* ============================================================
   TRIGGER: Auditoría de cambios de etapa
   Registra movimientos del Kanban en BitacoraCambios.
   ============================================================ */
CREATE OR ALTER TRIGGER dbo.trg_AuditarCambioEtapa
ON dbo.Etapa_Oportunidad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BitacoraCambios (
        tabla_afectada,
        id_registro,
        accion,
        usuario,
        fecha_cambio,
        valor_anterior,
        valor_nuevo
    )
    SELECT
        'Etapa_Oportunidad',
        I.id_oportunidad,
        'INSERT',
        SUSER_SNAME(),
        GETDATE(),
        NULL,
        CONCAT(
            'Oportunidad: ', I.id_oportunidad,
            ' | Nueva etapa: ', TE.nombre_etapa,
            ' | Porcentaje: ', TE.porcentaje, '%',
            ' | Comentario: ', ISNULL(I.comentario, 'Sin comentario')
        )
    FROM inserted I
    INNER JOIN TipoEtapa TE
        ON I.id_tipo_etapa = TE.id_tipo_etapa;
END;
GO

/* ============================================================
   TRIGGER: Auditoría de actualizaciones en Oportunidad
   Registra valores anteriores y nuevos.
   ============================================================ */
CREATE OR ALTER TRIGGER dbo.trg_AuditarActualizacionOportunidad
ON dbo.Oportunidad
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BitacoraCambios (
        tabla_afectada,
        id_registro,
        accion,
        usuario,
        fecha_cambio,
        valor_anterior,
        valor_nuevo
    )
    SELECT
        'Oportunidad',
        I.id_oportunidad,
        'UPDATE',
        SUSER_SNAME(),
        GETDATE(),
        CONCAT(
            'Estado anterior: ', D.id_estado_oportunidad,
            ' | Resultado anterior: ', ISNULL(CAST(D.id_resultado AS VARCHAR), 'NULL'),
            ' | Monto anterior: ', ISNULL(CAST(D.monto_potencial AS VARCHAR), 'NULL'),
            ' | Avance anterior: ', ISNULL(CAST(D.porcentaje_avance AS VARCHAR), 'NULL')
        ),
        CONCAT(
            'Estado nuevo: ', I.id_estado_oportunidad,
            ' | Resultado nuevo: ', ISNULL(CAST(I.id_resultado AS VARCHAR), 'NULL'),
            ' | Monto nuevo: ', ISNULL(CAST(I.monto_potencial AS VARCHAR), 'NULL'),
            ' | Avance nuevo: ', ISNULL(CAST(I.porcentaje_avance AS VARCHAR), 'NULL')
        )
    FROM inserted I
    INNER JOIN deleted D
        ON I.id_oportunidad = D.id_oportunidad;
END;
GO
