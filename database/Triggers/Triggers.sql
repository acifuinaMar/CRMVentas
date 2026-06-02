-- ======================== TRIGGERS ===========================
-- ------------------------------------------------------------
-- TRIGGER 1: trg_Cliente_Auditoria
-- Registra en BitacoraCambios cualquier INSERT o UPDATE
-- realizado sobre la tabla Cliente.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Cliente_Auditoria
ON Cliente
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_nuevo)
        SELECT
            'Cliente',
            i.id_cliente,
            'INSERT',
            'Nombre: '     + i.nombre_comercial +
            ' | Tipo: '    + CAST(i.id_tipo_cliente AS VARCHAR(5)) +
            ' | Email: '   + ISNULL(i.email, 'N/A') +
            ' | Activo: '  + CAST(i.activo AS VARCHAR(1))
        FROM inserted i;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_anterior, valor_nuevo)
        SELECT
            'Cliente',
            i.id_cliente,
            'UPDATE',
            'Nombre: '    + d.nombre_comercial +
            ' | Tipo: '   + CAST(d.id_tipo_cliente AS VARCHAR(5)) +
            ' | Activo: ' + CAST(d.activo AS VARCHAR(1)),
            'Nombre: '    + i.nombre_comercial +
            ' | Tipo: '   + CAST(i.id_tipo_cliente AS VARCHAR(5)) +
            ' | Activo: ' + CAST(i.activo AS VARCHAR(1))
        FROM inserted i
        INNER JOIN deleted d ON i.id_cliente = d.id_cliente;
    END
END;
GO

-- ------------------------------------------------------------
-- TRIGGER 2: trg_Empleado_Auditoria
-- Registra en BitacoraCambios los INSERT, UPDATE y DELETE
-- sobre la tabla Empleado.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Empleado_Auditoria
ON Empleado
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_nuevo)
        SELECT
            'Empleado',
            i.id_empleado,
            'INSERT',
            'Nombre: '  + i.nombre_completo +
            ' | Email: ' + i.email +
            ' | Rol: '  + CAST(i.id_rol AS VARCHAR(5))
        FROM inserted i;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_anterior, valor_nuevo)
        SELECT
            'Empleado',
            i.id_empleado,
            'UPDATE',
            'Nombre: '   + d.nombre_completo +
            ' | Rol: '   + CAST(d.id_rol AS VARCHAR(5)) +
            ' | Activo: '+ CAST(d.activo AS VARCHAR(1)),
            'Nombre: '   + i.nombre_completo +
            ' | Rol: '   + CAST(i.id_rol AS VARCHAR(5)) +
            ' | Activo: '+ CAST(i.activo AS VARCHAR(1))
        FROM inserted i
        INNER JOIN deleted d ON i.id_empleado = d.id_empleado;
    END

    -- DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_anterior)
        SELECT
            'Empleado',
            d.id_empleado,
            'DELETE',
            'Nombre: '  + d.nombre_completo +
            ' | Email: ' + d.email
        FROM deleted d;
    END
END;
GO

-- ------------------------------------------------------------
-- TRIGGER 3: trg_Oportunidad_Auditoria
-- Registra en BitacoraCambios los INSERT y UPDATE
-- sobre la tabla Oportunidad, capturando cambios de estado,
-- resultado, porcentaje y montos.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Oportunidad_Auditoria
ON Oportunidad
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_nuevo)
        SELECT
            'Oportunidad',
            i.id_oportunidad,
            'INSERT',
            'N: '         + i.numero_oportunidad +
            ' | Nombre: ' + i.nombre_oportunidad +
            ' | Monto: '  + CAST(i.monto_potencial AS VARCHAR(20)) +
            ' | Cliente: '+ CAST(i.id_cliente AS VARCHAR(10))
        FROM inserted i;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_anterior, valor_nuevo)
        SELECT
            'Oportunidad',
            i.id_oportunidad,
            'UPDATE',
            'Estado: '    + CAST(d.id_estado_oportunidad AS VARCHAR(5)) +
            ' | Resultado:'+ ISNULL(CAST(d.id_resultado  AS VARCHAR(5)), 'NULL') +
            ' | %: '      + ISNULL(CAST(d.porcentaje_avance AS VARCHAR(10)), '0') +
            ' | Monto: '  + CAST(d.monto_potencial AS VARCHAR(20)),
            'Estado: '    + CAST(i.id_estado_oportunidad AS VARCHAR(5)) +
            ' | Resultado:'+ ISNULL(CAST(i.id_resultado  AS VARCHAR(5)), 'NULL') +
            ' | %: '      + ISNULL(CAST(i.porcentaje_avance AS VARCHAR(10)), '0') +
            ' | Monto: '  + CAST(i.monto_potencial AS VARCHAR(20))
        FROM inserted i
        INNER JOIN deleted d ON i.id_oportunidad = d.id_oportunidad;
    END
END;
GO

-- ------------------------------------------------------------
-- TRIGGER 4: trg_EtapaOportunidad_SyncOportunidad
-- AUTOMATIZACION: Cada vez que se inserta una nueva fila en
-- Etapa_Oportunidad, actualiza automaticamente los campos
-- porcentaje_avance y monto_ponderado en la tabla Oportunidad.
-- Esto garantiza consistencia sin depender del codigo de la API.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_EtapaOportunidad_SyncOportunidad
ON Etapa_Oportunidad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE O
    SET
        porcentaje_avance   = TE.porcentaje,
        monto_ponderado     = i.importe_ponderado_etapa
    FROM Oportunidad O
    INNER JOIN inserted  i  ON O.id_oportunidad = i.id_oportunidad
    INNER JOIN TipoEtapa TE ON i.id_tipo_etapa  = TE.id_tipo_etapa;
END;
GO

-- ------------------------------------------------------------
-- TRIGGER 5: trg_Actividad_Auditoria
-- Registra en BitacoraCambios INSERT y UPDATE relevantes
-- sobre la tabla Actividad (cambios de estado o asunto).
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Actividad_Auditoria
ON Actividad
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_nuevo)
        SELECT
            'Actividad',
            i.id_actividad,
            'INSERT',
            'N: '          + i.numero_actividad +
            ' | Asunto: '  + i.asunto +
            ' | Cliente: ' + CAST(i.id_cliente AS VARCHAR(10)) +
            ' | Tipo: '    + CAST(i.id_tipo_actividad AS VARCHAR(5))
        FROM inserted i;
    END

    -- UPDATE: solo si cambio el estado o el asunto
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO BitacoraCambios (tabla_afectada, id_registro, accion, valor_anterior, valor_nuevo)
        SELECT
            'Actividad',
            i.id_actividad,
            'UPDATE',
            'Estado: '  + CAST(d.id_estado_actividad AS VARCHAR(5)) +
            ' | Asunto: '+ d.asunto,
            'Estado: '  + CAST(i.id_estado_actividad AS VARCHAR(5)) +
            ' | Asunto: '+ i.asunto
        FROM inserted i
        INNER JOIN deleted d ON i.id_actividad = d.id_actividad
        WHERE i.id_estado_actividad <> d.id_estado_actividad
           OR i.asunto              <> d.asunto;
    END
END;
GO

-- ------------------------------------------------------------
-- TRIGGER 6: trg_Oportunidad_ValidarCierreGanada
-- REGLA DE NEGOCIO: Impide que una oportunidad sea marcada
-- como GANADA si su porcentaje_avance es menor a 100%.
-- Actua como segunda linea de defensa ademas del SP.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Oportunidad_ValidarCierreGanada
ON Oportunidad
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(id_resultado)
    BEGIN
        DECLARE @id_resultado_ganada INT;
        SELECT @id_resultado_ganada = id_resultado
        FROM ResultadoOportunidad WHERE codigo = 'GANADA';

        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON i.id_oportunidad = d.id_oportunidad
            WHERE i.id_resultado = @id_resultado_ganada
              AND i.porcentaje_avance < 100
        )
        BEGIN
            RAISERROR(
                'REGLA DE NEGOCIO: No se puede marcar como GANADA sin haber completado el Acuerdo de Cierre (100%%).',
                16, 1
            );
            ROLLBACK TRANSACTION;
        END
    END
END;
GO
