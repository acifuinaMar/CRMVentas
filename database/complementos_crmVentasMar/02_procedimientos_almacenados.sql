USE CRMVentas;
GO

/* ============================================================
   PROCEDIMIENTO: Cambiar etapa de oportunidad
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_CambiarEtapaOportunidad
    @id_oportunidad INT,
    @id_tipo_etapa INT,
    @comentario NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @monto DECIMAL(18,2);
        DECLARE @id_vendedor INT;
        DECLARE @porcentaje DECIMAL(5,2);
        DECLARE @importe DECIMAL(18,2);

        SELECT 
            @monto = monto_potencial,
            @id_vendedor = id_empleado_vendedor
        FROM Oportunidad
        WHERE id_oportunidad = @id_oportunidad;

        IF @monto IS NULL
        BEGIN
            RAISERROR('La oportunidad no existe.', 16, 1);
        END;

        SELECT @porcentaje = porcentaje
        FROM TipoEtapa
        WHERE id_tipo_etapa = @id_tipo_etapa;

        IF @porcentaje IS NULL
        BEGIN
            RAISERROR('La etapa no existe.', 16, 1);
        END;

        SET @importe = dbo.fn_CalcularImportePonderado(@monto, @porcentaje);

        INSERT INTO Etapa_Oportunidad (
            id_oportunidad,
            id_tipo_etapa,
            id_empleado_ventas,
            fecha_inicio_etapa,
            monto_potencial_etapa,
            importe_ponderado_etapa,
            comentario
        )
        VALUES (
            @id_oportunidad,
            @id_tipo_etapa,
            @id_vendedor,
            GETDATE(),
            @monto,
            @importe,
            ISNULL(@comentario, 'Cambio de etapa desde procedimiento almacenado')
        );

        COMMIT TRANSACTION;

        SELECT 
            'OK' AS estado,
            'Etapa actualizada correctamente' AS mensaje,
            @id_oportunidad AS id_oportunidad,
            @id_tipo_etapa AS id_tipo_etapa,
            @porcentaje AS nuevo_porcentaje,
            @importe AS nuevo_importe_ponderado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* ============================================================
   PROCEDIMIENTO: Cerrar oportunidad como ganada o perdida
   id_resultado: 2 = Ganada, 3 = Perdida
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_CerrarOportunidad
    @id_oportunidad INT,
    @id_resultado INT,
    @comentario NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @id_resultado NOT IN (2, 3)
        BEGIN
            RAISERROR('El resultado debe ser 2 = Ganada o 3 = Perdida.', 16, 1);
        END;

        IF NOT EXISTS (
            SELECT 1 
            FROM Oportunidad 
            WHERE id_oportunidad = @id_oportunidad
        )
        BEGIN
            RAISERROR('La oportunidad no existe.', 16, 1);
        END;

        UPDATE Oportunidad
        SET 
            id_estado_oportunidad = 2,
            id_resultado = @id_resultado,
            fecha_cierre_real = GETDATE(),
            porcentaje_avance = CASE 
                WHEN @id_resultado = 2 THEN 100
                ELSE porcentaje_avance
            END
        WHERE id_oportunidad = @id_oportunidad;

        INSERT INTO BitacoraCambios (
            tabla_afectada,
            id_registro,
            accion,
            usuario,
            fecha_cambio,
            valor_anterior,
            valor_nuevo
        )
        VALUES (
            'Oportunidad',
            @id_oportunidad,
            'CIERRE',
            SUSER_SNAME(),
            GETDATE(),
            NULL,
            CONCAT(
                'Oportunidad cerrada como ',
                CASE WHEN @id_resultado = 2 THEN 'GANADA' ELSE 'PERDIDA' END,
                ' | Comentario: ',
                ISNULL(@comentario, 'Sin comentario')
            )
        );

        COMMIT TRANSACTION;

        SELECT 
            'OK' AS estado,
            CASE 
                WHEN @id_resultado = 2 THEN 'Oportunidad cerrada como ganada'
                ELSE 'Oportunidad cerrada como perdida'
            END AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
