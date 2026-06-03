-- ===================== STORED PROCEDURES =====================
-- SECCION 1: CLIENTES
-- ------------------------------------------------------------
-- sp_CrearCliente
-- Crea un nuevo cliente con validaciones de integridad.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CrearCliente
    @nombre_comercial   VARCHAR(100),
    @razon_social       VARCHAR(100)    = NULL,
    @direccion          VARCHAR(255)    = NULL,
    @telefono           VARCHAR(20)     = NULL,
    @celular            VARCHAR(20)     = NULL,
    @email              VARCHAR(100)    = NULL,
    @contacto_nombre    VARCHAR(100)    = NULL,
    @id_tipo_cliente    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF LTRIM(RTRIM(ISNULL(@nombre_comercial, ''))) = ''
        BEGIN
            RAISERROR('El nombre comercial es requerido.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM TipoCliente WHERE id_tipo_cliente = @id_tipo_cliente)
        BEGIN
            RAISERROR('El tipo de cliente no es valido.', 16, 1);
            RETURN;
        END

        INSERT INTO Cliente (
            nombre_comercial, razon_social, direccion,
            telefono, celular, email, contacto_nombre,
            id_tipo_cliente, activo
        )
        VALUES (
            @nombre_comercial, @razon_social, @direccion,
            @telefono, @celular, @email, @contacto_nombre,
            @id_tipo_cliente, 1
        );

        DECLARE @id_nuevo INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT @id_nuevo AS id_cliente, 'Cliente creado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerClientes
-- Lista clientes activos o inactivos segun parametro.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerClientes
    @activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.id_cliente,
        C.nombre_comercial,
        C.razon_social,
        C.direccion,
        C.telefono,
        C.celular,
        C.email,
        C.contacto_nombre,
        C.id_tipo_cliente,
        T.nombre    AS tipo_cliente_nombre,
        C.fecha_registro,
        C.activo
    FROM Cliente C
    INNER JOIN TipoCliente T ON C.id_tipo_cliente = T.id_tipo_cliente
    WHERE C.activo = @activo
    ORDER BY C.id_cliente DESC;
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerClientePorId
-- Retorna el detalle de un cliente por su ID.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerClientePorId
    @id_cliente INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.id_cliente,
        C.nombre_comercial,
        C.razon_social,
        C.direccion,
        C.telefono,
        C.celular,
        C.email,
        C.contacto_nombre,
        C.id_tipo_cliente,
        T.nombre    AS tipo_cliente_nombre,
        C.fecha_registro,
        C.activo
    FROM Cliente C
    INNER JOIN TipoCliente T ON C.id_tipo_cliente = T.id_tipo_cliente
    WHERE C.id_cliente = @id_cliente;
END;
GO

-- ------------------------------------------------------------
-- sp_ActualizarCliente
-- Actualiza los datos de un cliente existente.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ActualizarCliente
    @id_cliente         INT,
    @nombre_comercial   VARCHAR(100),
    @razon_social       VARCHAR(100)    = NULL,
    @direccion          VARCHAR(255)    = NULL,
    @telefono           VARCHAR(20)     = NULL,
    @celular            VARCHAR(20)     = NULL,
    @email              VARCHAR(100)    = NULL,
    @contacto_nombre    VARCHAR(100)    = NULL,
    @id_tipo_cliente    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE id_cliente = @id_cliente)
        BEGIN
            RAISERROR('Cliente no encontrado.', 16, 1);
            RETURN;
        END

        UPDATE Cliente SET
            nombre_comercial    = @nombre_comercial,
            razon_social        = @razon_social,
            direccion           = @direccion,
            telefono            = @telefono,
            celular             = @celular,
            email               = @email,
            contacto_nombre     = @contacto_nombre,
            id_tipo_cliente     = @id_tipo_cliente
        WHERE id_cliente = @id_cliente;

        COMMIT TRANSACTION;
        SELECT 'Cliente actualizado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_EliminarCliente
-- Baja logica del cliente (activo = 0).
-- Valida que no tenga oportunidades activas vinculadas.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_EliminarCliente
    @id_cliente INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE id_cliente = @id_cliente)
        BEGIN
            RAISERROR('Cliente no encontrado.', 16, 1);
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM Oportunidad
            WHERE id_cliente = @id_cliente AND activo = 1
        )
        BEGIN
            RAISERROR('No se puede eliminar: el cliente tiene oportunidades activas.', 16, 1);
            RETURN;
        END

        UPDATE Cliente SET activo = 0 WHERE id_cliente = @id_cliente;

        COMMIT TRANSACTION;
        SELECT 'Cliente desactivado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- ============================================================
-- SECCION 2: EMPLEADOS
-- ============================================================

-- ------------------------------------------------------------
-- sp_CrearEmpleado
-- Registra un nuevo empleado validando email unico y rol.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CrearEmpleado
    @nombre_completo    VARCHAR(100),
    @email              VARCHAR(100),
    @telefono           VARCHAR(20)     = NULL,
    @id_rol             INT,
    @fecha_contratacion DATE            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF LTRIM(RTRIM(ISNULL(@nombre_completo, ''))) = ''
        BEGIN
            RAISERROR('El nombre del empleado es requerido.', 16, 1);
            RETURN;
        END

        IF LTRIM(RTRIM(ISNULL(@email, ''))) = ''
        BEGIN
            RAISERROR('El email del empleado es requerido.', 16, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Empleado WHERE email = @email)
        BEGIN
            RAISERROR('Ya existe un empleado registrado con ese email.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM RolEmpleado WHERE id_rol = @id_rol)
        BEGIN
            RAISERROR('El rol especificado no es valido.', 16, 1);
            RETURN;
        END

        SET @fecha_contratacion = ISNULL(@fecha_contratacion, CAST(GETDATE() AS DATE));

        INSERT INTO Empleado (nombre_completo, email, telefono, id_rol, fecha_contratacion, activo)
        VALUES (@nombre_completo, @email, @telefono, @id_rol, @fecha_contratacion, 1);

        DECLARE @id_nuevo INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT @id_nuevo AS id_empleado, 'Empleado creado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerEmpleados
-- Lista empleados filtrados por estado activo/inactivo.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerEmpleados
    @activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        E.id_empleado,
        E.nombre_completo,
        E.email,
        E.telefono,
        E.id_rol,
        R.nombre    AS rol_nombre,
        E.fecha_contratacion,
        E.activo
    FROM Empleado E
    INNER JOIN RolEmpleado R ON E.id_rol = R.id_rol
    WHERE E.activo = @activo
    ORDER BY E.nombre_completo;
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerEmpleadoPorId
-- Retorna detalle de un empleado por ID.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerEmpleadoPorId
    @id_empleado INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        E.id_empleado,
        E.nombre_completo,
        E.email,
        E.telefono,
        E.id_rol,
        R.nombre    AS rol_nombre,
        E.fecha_contratacion,
        E.activo
    FROM Empleado E
    INNER JOIN RolEmpleado R ON E.id_rol = R.id_rol
    WHERE E.id_empleado = @id_empleado;
END;
GO

-- ------------------------------------------------------------
-- sp_ActualizarEmpleado
-- Actualiza datos del empleado, validando email unico.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ActualizarEmpleado
    @id_empleado        INT,
    @nombre_completo    VARCHAR(100),
    @email              VARCHAR(100),
    @telefono           VARCHAR(20)     = NULL,
    @id_rol             INT,
    @activo             BIT             = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @id_empleado)
        BEGIN
            RAISERROR('Empleado no encontrado.', 16, 1);
            RETURN;
        END

        -- Email unico excluyendo al mismo empleado
        IF EXISTS (
            SELECT 1 FROM Empleado
            WHERE email = @email AND id_empleado <> @id_empleado
        )
        BEGIN
            RAISERROR('Ya existe otro empleado con ese email.', 16, 1);
            RETURN;
        END

        UPDATE Empleado SET
            nombre_completo = @nombre_completo,
            email           = @email,
            telefono        = @telefono,
            id_rol          = @id_rol,
            activo          = @activo
        WHERE id_empleado = @id_empleado;

        COMMIT TRANSACTION;
        SELECT 'Empleado actualizado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_EliminarEmpleado
-- Baja logica del empleado.
-- Valida que no tenga oportunidades activas asignadas.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_EliminarEmpleado
    @id_empleado INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @id_empleado)
        BEGIN
            RAISERROR('Empleado no encontrado.', 16, 1);
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM Oportunidad
            WHERE (id_empleado_vendedor = @id_empleado OR id_empleado_gerente = @id_empleado)
              AND activo = 1
        )
        BEGIN
            RAISERROR('No se puede eliminar: el empleado tiene oportunidades activas asignadas.', 16, 1);
            RETURN;
        END

        UPDATE Empleado SET activo = 0 WHERE id_empleado = @id_empleado;

        COMMIT TRANSACTION;
        SELECT 'Empleado desactivado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- ============================================================
-- SECCION 3: OPORTUNIDADES
-- ============================================================

-- ------------------------------------------------------------
-- sp_CrearOportunidad
-- Registra una nueva oportunidad con numero auto-generado,
-- calcula fecha de cierre segun unidad (DIA/SEM/MES) y crea
-- automaticamente la etapa inicial de Calificacion (30%).
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CrearOportunidad
    @nombre_oportunidad         VARCHAR(150),
    @id_cliente                 INT,
    @id_empleado_vendedor       INT,
    @id_empleado_gerente        INT,
    @id_tipo_oportunidad        INT,
    @cierre_planificado_valor   INT,
    @id_unidad_cierre           INT,
    @monto_potencial            DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validaciones de existencia y estado
        IF NOT EXISTS (SELECT 1 FROM Cliente  WHERE id_cliente   = @id_cliente  AND activo = 1)
            RAISERROR('Cliente no encontrado o inactivo.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado  = @id_empleado_vendedor AND activo = 1)
            RAISERROR('Vendedor no encontrado o inactivo.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado  = @id_empleado_gerente  AND activo = 1)
            RAISERROR('Gerente no encontrado o inactivo.', 16, 1);

        IF @monto_potencial < 0
            RAISERROR('El monto potencial no puede ser negativo.', 16, 1);

        IF @cierre_planificado_valor <= 0
            RAISERROR('El valor de cierre planificado debe ser mayor a cero.', 16, 1);

        -- Generar numero de oportunidad: OP-{N}
        DECLARE @nextNum    INT;
        DECLARE @numero_op  VARCHAR(20);

        SELECT @nextNum = ISNULL(
            MAX(TRY_CAST(REPLACE(numero_oportunidad, 'OP-', '') AS INT)), 0
        ) + 1
        FROM Oportunidad
        WHERE numero_oportunidad LIKE 'OP-%';

        SET @numero_op = 'OP-' + CAST(@nextNum AS VARCHAR(10));

        -- Calcular fecha de cierre segun unidad (DIA / SEM / MES)
        DECLARE @codigo_unidad      VARCHAR(10);
        DECLARE @fecha_cierre_prev  DATE;

        SELECT @codigo_unidad = codigo FROM UnidadCierre WHERE id_unidad = @id_unidad_cierre;

        SET @fecha_cierre_prev = CASE @codigo_unidad
            WHEN 'DIA' THEN DATEADD(DAY,   @cierre_planificado_valor, CAST(GETDATE() AS DATE))
            WHEN 'SEM' THEN DATEADD(WEEK,  @cierre_planificado_valor, CAST(GETDATE() AS DATE))
            WHEN 'MES' THEN DATEADD(MONTH, @cierre_planificado_valor, CAST(GETDATE() AS DATE))
            ELSE             DATEADD(DAY,  @cierre_planificado_valor, CAST(GETDATE() AS DATE))
        END;

        -- IDs de estado inicial
        DECLARE @id_estado_abierto      INT;
        DECLARE @id_resultado_abierta   INT;
        DECLARE @id_etapa_inicial       INT;
        DECLARE @pct_inicial            DECIMAL(5,2);

        SELECT @id_estado_abierto    = id_estado_oportunidad FROM EstadoOportunidad    WHERE codigo = 'ABIERTO';
        SELECT @id_resultado_abierta = id_resultado          FROM ResultadoOportunidad WHERE codigo = 'ABIERTA';
        SELECT @id_etapa_inicial = id_tipo_etapa, @pct_inicial = porcentaje
        FROM TipoEtapa WHERE orden = 1; -- Calificacion de la oportunidad (30%)

        -- Insertar oportunidad
        INSERT INTO Oportunidad (
            numero_oportunidad,     nombre_oportunidad,
            id_cliente,             id_empleado_vendedor,   id_empleado_gerente,
            id_tipo_oportunidad,    id_estado_oportunidad,  id_resultado,
            cierre_planificado_valor, id_unidad_cierre,     fecha_cierre_prevista,
            monto_potencial,        monto_ponderado,        porcentaje_avance,
            activo
        )
        VALUES (
            @numero_op,             @nombre_oportunidad,
            @id_cliente,            @id_empleado_vendedor,  @id_empleado_gerente,
            @id_tipo_oportunidad,   @id_estado_abierto,     @id_resultado_abierta,
            @cierre_planificado_valor, @id_unidad_cierre,   @fecha_cierre_prev,
            @monto_potencial,       @monto_potencial * (@pct_inicial / 100), @pct_inicial,
            1
        );

        DECLARE @id_oportunidad INT = SCOPE_IDENTITY();

        -- Insertar etapa inicial (el trigger trg_EtapaOportunidad_SyncOportunidad
        -- actualizara porcentaje_avance y monto_ponderado automaticamente)
        INSERT INTO Etapa_Oportunidad (
            id_oportunidad,     id_tipo_etapa,          id_empleado_ventas,
            fecha_inicio_etapa, monto_potencial_etapa,  importe_ponderado_etapa,
            comentario
        )
        VALUES (
            @id_oportunidad,    @id_etapa_inicial,      @id_empleado_vendedor,
            CAST(GETDATE() AS DATE),
            @monto_potencial,   @monto_potencial * (@pct_inicial / 100),
            'Oportunidad creada - Etapa inicial: Calificacion'
        );

        COMMIT TRANSACTION;

        SELECT
            @id_oportunidad AS id_oportunidad,
            @numero_op      AS numero_oportunidad,
            'Oportunidad creada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerOportunidades
-- Lista oportunidades con filtros opcionales por estado
-- y por empleado. Incluye etapa actual via OUTER APPLY.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerOportunidades
    @activo         BIT = 1,
    @id_empleado    INT = NULL,
    @id_estado      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        O.id_oportunidad,
        O.numero_oportunidad,
        O.nombre_oportunidad,
        C.nombre_comercial          AS cliente,
        C.contacto_nombre,
        EV.nombre_completo          AS vendedor,
        EG.nombre_completo          AS gerente,
        O.monto_potencial,
        O.monto_ponderado,
        O.porcentaje_avance,
        O.fecha_inicio,
        O.fecha_cierre_prevista,
        O.fecha_cierre_real,
        O.cierre_planificado_valor,
        UC.nombre                   AS unidad_cierre,
        TIO.nombre                  AS tipo_oportunidad,
        EO.nombre                   AS estado_oportunidad,
        RO.nombre                   AS resultado,
        UE.nombre_etapa             AS etapa_actual,
        UE.porcentaje               AS etapa_porcentaje
    FROM Oportunidad O
    INNER JOIN Cliente              C   ON O.id_cliente             = C.id_cliente
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor   = EV.id_empleado
    INNER JOIN Empleado             EG  ON O.id_empleado_gerente    = EG.id_empleado
    INNER JOIN TipoOportunidad      TIO ON O.id_tipo_oportunidad    = TIO.id_tipo_oportunidad
    INNER JOIN EstadoOportunidad    EO  ON O.id_estado_oportunidad  = EO.id_estado_oportunidad
    INNER JOIN UnidadCierre         UC  ON O.id_unidad_cierre       = UC.id_unidad
    LEFT  JOIN ResultadoOportunidad RO  ON O.id_resultado           = RO.id_resultado
    OUTER APPLY (
        SELECT TOP 1 TE.nombre_etapa, TE.porcentaje
        FROM Etapa_Oportunidad EOP
        INNER JOIN TipoEtapa TE ON EOP.id_tipo_etapa = TE.id_tipo_etapa
        WHERE EOP.id_oportunidad = O.id_oportunidad
        ORDER BY EOP.fecha_inicio_etapa DESC, EOP.id_etapa_oportunidad DESC
    ) UE
    WHERE O.activo = @activo
      AND (@id_empleado IS NULL OR O.id_empleado_vendedor = @id_empleado
                                OR O.id_empleado_gerente  = @id_empleado)
      AND (@id_estado   IS NULL OR O.id_estado_oportunidad = @id_estado)
    ORDER BY O.id_oportunidad DESC;
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerOportunidadPorId
-- Retorna detalle de una oportunidad y su historial de etapas.
-- Devuelve dos resultsets: [0] oportunidad, [1] etapas.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerOportunidadPorId
    @id_oportunidad INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultset 1: Datos principales de la oportunidad
    SELECT
        O.id_oportunidad,
        O.numero_oportunidad,
        O.nombre_oportunidad,
        O.id_cliente,
        C.nombre_comercial          AS cliente,
        C.contacto_nombre,
        C.telefono                  AS cliente_telefono,
        O.id_empleado_vendedor,
        EV.nombre_completo          AS vendedor,
        O.id_empleado_gerente,
        EG.nombre_completo          AS gerente,
        O.id_tipo_oportunidad,
        TIO.nombre                  AS tipo_oportunidad,
        O.id_estado_oportunidad,
        EO.nombre                   AS estado_oportunidad,
        O.id_resultado,
        RO.nombre                   AS resultado,
        O.fecha_inicio,
        O.fecha_cierre_prevista,
        O.fecha_cierre_real,
        O.cierre_planificado_valor,
        O.id_unidad_cierre,
        UC.nombre                   AS unidad_cierre,
        O.monto_potencial,
        O.monto_ponderado,
        O.porcentaje_avance,
        O.activo
    FROM Oportunidad O
    INNER JOIN Cliente              C   ON O.id_cliente             = C.id_cliente
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor   = EV.id_empleado
    INNER JOIN Empleado             EG  ON O.id_empleado_gerente    = EG.id_empleado
    INNER JOIN TipoOportunidad      TIO ON O.id_tipo_oportunidad    = TIO.id_tipo_oportunidad
    INNER JOIN EstadoOportunidad    EO  ON O.id_estado_oportunidad  = EO.id_estado_oportunidad
    INNER JOIN UnidadCierre         UC  ON O.id_unidad_cierre       = UC.id_unidad
    LEFT  JOIN ResultadoOportunidad RO  ON O.id_resultado           = RO.id_resultado
    WHERE O.id_oportunidad = @id_oportunidad;

    -- Resultset 2: Historial de etapas (bitacora)
    SELECT
        EOP.id_etapa_oportunidad,
        EOP.fecha_inicio_etapa,
        EOP.fecha_cierre_etapa,
        TE.nombre_etapa,
        TE.porcentaje,
        EOP.monto_potencial_etapa,
        EOP.importe_ponderado_etapa,
        EOP.comentario,
        E.nombre_completo           AS empleado_ventas,
        TD.nombre                   AS tipo_documento,
        EOP.num_documento
    FROM Etapa_Oportunidad EOP
    INNER JOIN TipoEtapa    TE  ON EOP.id_tipo_etapa        = TE.id_tipo_etapa
    INNER JOIN Empleado     E   ON EOP.id_empleado_ventas   = E.id_empleado
    LEFT  JOIN TipoDocumento TD ON EOP.id_tipo_documento    = TD.id_tipo_documento
    WHERE EOP.id_oportunidad = @id_oportunidad
    ORDER BY EOP.fecha_inicio_etapa ASC, EOP.id_etapa_oportunidad ASC;
END;
GO

-- ------------------------------------------------------------
-- sp_AgregarEtapaOportunidad
-- Registra el avance de una oportunidad a una nueva etapa.
-- El trigger trg_EtapaOportunidad_SyncOportunidad actualiza
-- automaticamente porcentaje_avance y monto_ponderado.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AgregarEtapaOportunidad
    @id_oportunidad         INT,
    @id_tipo_etapa          INT,
    @id_empleado_ventas     INT,
    @monto_potencial_etapa  DECIMAL(18,2),
    @id_tipo_documento      INT             = NULL,
    @num_documento          VARCHAR(50)     = NULL,
    @comentario             VARCHAR(MAX)    = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que la oportunidad exista y este abierta
        DECLARE @cod_estado VARCHAR(10);
        SELECT @cod_estado = EO.codigo
        FROM Oportunidad O
        INNER JOIN EstadoOportunidad EO ON O.id_estado_oportunidad = EO.id_estado_oportunidad
        WHERE O.id_oportunidad = @id_oportunidad AND O.activo = 1;

        IF @cod_estado IS NULL
            RAISERROR('Oportunidad no encontrada o inactiva.', 16, 1);

        IF @cod_estado = 'CERRADO'
            RAISERROR('No se pueden agregar etapas a una oportunidad cerrada.', 16, 1);

        -- Validar que la etapa exista
        DECLARE @porcentaje DECIMAL(5,2);
        SELECT @porcentaje = porcentaje FROM TipoEtapa WHERE id_tipo_etapa = @id_tipo_etapa;

        IF @porcentaje IS NULL
            RAISERROR('La etapa especificada no es valida.', 16, 1);

        DECLARE @importe_ponderado DECIMAL(18,2) = @monto_potencial_etapa * (@porcentaje / 100.0);

        -- Cerrar fecha de la etapa anterior
        UPDATE Etapa_Oportunidad
        SET fecha_cierre_etapa = CAST(GETDATE() AS DATE)
        WHERE id_oportunidad = @id_oportunidad
          AND fecha_cierre_etapa IS NULL;

        -- Insertar nueva etapa
        -- El trigger trg_EtapaOportunidad_SyncOportunidad actualizara
        -- porcentaje_avance y monto_ponderado en Oportunidad automaticamente.
        INSERT INTO Etapa_Oportunidad (
            id_oportunidad,     id_tipo_etapa,          id_empleado_ventas,
            fecha_inicio_etapa, monto_potencial_etapa,  importe_ponderado_etapa,
            id_tipo_documento,  num_documento,           comentario
        )
        VALUES (
            @id_oportunidad,    @id_tipo_etapa,         @id_empleado_ventas,
            CAST(GETDATE() AS DATE),
            @monto_potencial_etapa, @importe_ponderado,
            @id_tipo_documento, @num_documento,          @comentario
        );

        COMMIT TRANSACTION;

        SELECT
            'Etapa registrada. Oportunidad actualizada.' AS mensaje,
            @porcentaje AS nuevo_porcentaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_CerrarOportunidad
-- Cierra una oportunidad como GANADA o PERDIDA.
-- REGLA: Solo se puede marcar GANADA si el porcentaje de
-- avance es 100% (Acuerdo de Cierre).
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CerrarOportunidad
    @id_oportunidad INT,
    @resultado      VARCHAR(10),    -- 'GANADA' o 'PERDIDA'
    @comentario     VARCHAR(MAX)    = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @resultado NOT IN ('GANADA', 'PERDIDA')
            RAISERROR('El resultado debe ser GANADA o PERDIDA.', 16, 1);

        DECLARE @porcentaje_avance  DECIMAL(5,2);
        DECLARE @cod_estado         VARCHAR(10);
        DECLARE @id_vendedor        INT;
        DECLARE @monto_pot          DECIMAL(18,2);
        DECLARE @monto_pond         DECIMAL(18,2);

        SELECT
            @porcentaje_avance  = O.porcentaje_avance,
            @cod_estado         = EO.codigo,
            @id_vendedor        = O.id_empleado_vendedor,
            @monto_pot          = O.monto_potencial,
            @monto_pond         = O.monto_ponderado
        FROM Oportunidad O
        INNER JOIN EstadoOportunidad EO ON O.id_estado_oportunidad = EO.id_estado_oportunidad
        WHERE O.id_oportunidad = @id_oportunidad;

        IF @porcentaje_avance IS NULL
            RAISERROR('Oportunidad no encontrada.', 16, 1);

        IF @cod_estado = 'CERRADO'
            RAISERROR('La oportunidad ya se encuentra cerrada.', 16, 1);

        -- Regla de negocio: GANADA solo con 100% de avance
        IF @resultado = 'GANADA' AND @porcentaje_avance < 100
            RAISERROR('Para marcar como GANADA, la oportunidad debe estar en Acuerdo de Cierre (100%%).', 16, 1);

        DECLARE @id_estado_cerrado  INT;
        DECLARE @id_resultado_final INT;

        SELECT @id_estado_cerrado  = id_estado_oportunidad FROM EstadoOportunidad    WHERE codigo = 'CERRADO';
        SELECT @id_resultado_final = id_resultado          FROM ResultadoOportunidad WHERE codigo = @resultado;

        -- Cerrar la oportunidad
        UPDATE Oportunidad SET
            id_estado_oportunidad   = @id_estado_cerrado,
            id_resultado            = @id_resultado_final,
            fecha_cierre_real       = CAST(GETDATE() AS DATE)
        WHERE id_oportunidad = @id_oportunidad;

        -- Cerrar la ultima etapa abierta
        UPDATE Etapa_Oportunidad
        SET fecha_cierre_etapa = CAST(GETDATE() AS DATE)
        WHERE id_oportunidad = @id_oportunidad
          AND fecha_cierre_etapa IS NULL;

        -- Registrar comentario de cierre como ultima entrada de etapa
        IF LTRIM(RTRIM(ISNULL(@comentario, ''))) <> ''
        BEGIN
            DECLARE @id_ultima_etapa INT;
            SELECT @id_ultima_etapa = id_tipo_etapa
            FROM Etapa_Oportunidad
            WHERE id_oportunidad = @id_oportunidad
            ORDER BY id_etapa_oportunidad DESC
            OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

            INSERT INTO Etapa_Oportunidad (
                id_oportunidad, id_tipo_etapa, id_empleado_ventas,
                fecha_inicio_etapa, fecha_cierre_etapa,
                monto_potencial_etapa, importe_ponderado_etapa, comentario
            )
            VALUES (
                @id_oportunidad, @id_ultima_etapa, @id_vendedor,
                CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE),
                @monto_pot, @monto_pond,
                'CIERRE ' + @resultado + ': ' + @comentario
            );
        END

        COMMIT TRANSACTION;
        SELECT 'Oportunidad cerrada como ' + @resultado + '.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- ============================================================
-- SECCION 4: ACTIVIDADES
-- ============================================================

-- ------------------------------------------------------------
-- sp_CrearActividad
-- Crea una actividad con numero auto-generado (ACT-N).
-- Calcula duracion_minutos si se provee hora_fin.
-- Habilita campos de reunion (calle, ciudad, sala) opcionalmente.
-- @id_oportunidad es opcional: vincula la actividad a una
-- oportunidad especifica (requerido por server.js).
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CrearActividad
    @id_cliente                 INT,
    @id_empleado_responsable    INT,
    @id_tipo_actividad          INT,
    @asunto                     VARCHAR(200),
    @fecha                      DATE,
    @hora_inicio                TIME,
    @hora_fin                   TIME            = NULL,
    @id_prioridad               INT,
    @comentario                 VARCHAR(MAX)    = NULL,
    @id_estado_actividad        INT,
    @id_oportunidad             INT             = NULL,
    -- Campos para reunion
    @calle                      VARCHAR(150)    = NULL,
    @ciudad                     VARCHAR(100)    = NULL,
    @sala                       VARCHAR(50)     = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Cliente  WHERE id_cliente   = @id_cliente             AND activo = 1)
            RAISERROR('Cliente no encontrado o inactivo.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado  = @id_empleado_responsable AND activo = 1)
            RAISERROR('Empleado responsable no encontrado o inactivo.', 16, 1);

        IF LTRIM(RTRIM(ISNULL(@asunto, ''))) = ''
            RAISERROR('El asunto de la actividad es requerido.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM TipoActividad   WHERE id_tipo_actividad   = @id_tipo_actividad)
            RAISERROR('Tipo de actividad no valido.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM EstadoActividad WHERE id_estado_actividad = @id_estado_actividad)
            RAISERROR('Estado de actividad no valido.', 16, 1);

        -- Validar oportunidad si se proporciona
        IF @id_oportunidad IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM Oportunidad WHERE id_oportunidad = @id_oportunidad AND activo = 1)
            RAISERROR('Oportunidad no encontrada o inactiva.', 16, 1);

        -- Generar numero de actividad: ACT-{N}
        DECLARE @nextNum    INT;
        DECLARE @numero_act VARCHAR(20);

        SELECT @nextNum = ISNULL(
            MAX(TRY_CAST(REPLACE(numero_actividad, 'ACT-', '') AS INT)), 0
        ) + 1
        FROM Actividad
        WHERE numero_actividad LIKE 'ACT-%';

        SET @numero_act = 'ACT-' + CAST(@nextNum AS VARCHAR(10));

        -- Calcular duracion en minutos
        DECLARE @duracion_minutos INT = NULL;
        IF @hora_fin IS NOT NULL
            SET @duracion_minutos = DATEDIFF(MINUTE, @hora_inicio, @hora_fin);

        INSERT INTO Actividad (
            numero_actividad,           id_cliente,
            id_empleado_responsable,    id_tipo_actividad,
            asunto,                     fecha,
            hora_inicio,                hora_fin,
            duracion_minutos,           id_prioridad,
            comentario,                 id_estado_actividad,
            id_oportunidad,
            calle,                      ciudad,                 sala
        )
        VALUES (
            @numero_act,                @id_cliente,
            @id_empleado_responsable,   @id_tipo_actividad,
            @asunto,                    @fecha,
            @hora_inicio,               @hora_fin,
            @duracion_minutos,          @id_prioridad,
            @comentario,                @id_estado_actividad,
            @id_oportunidad,
            @calle,                     @ciudad,                @sala
        );

        DECLARE @id_nuevo INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT
            @id_nuevo   AS id_actividad,
            @numero_act AS numero_actividad,
            'Actividad creada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_ObtenerActividades
-- Lista actividades con filtros opcionales por cliente,
-- empleado, estado y oportunidad vinculada.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ObtenerActividades
    @id_cliente         INT = NULL,
    @id_empleado        INT = NULL,
    @id_estado          INT = NULL,
    @id_oportunidad     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        A.id_actividad,
        A.numero_actividad,
        A.asunto,
        A.fecha,
        A.hora_inicio,
        A.hora_fin,
        A.duracion_minutos,
        C.nombre_comercial      AS cliente,
        C.contacto_nombre,
        E.nombre_completo       AS responsable,
        TA.nombre               AS tipo_actividad,
        TA.codigo               AS codigo_tipo_actividad,
        P.nombre                AS prioridad,
        EA.nombre               AS estado,
        A.comentario,
        A.calle,
        A.ciudad,
        A.sala,
        A.fecha_creacion,
        A.id_oportunidad,
        O.numero_oportunidad,
        O.nombre_oportunidad    AS oportunidad_nombre
    FROM Actividad A
    INNER JOIN Cliente          C   ON A.id_cliente              = C.id_cliente
    INNER JOIN Empleado         E   ON A.id_empleado_responsable = E.id_empleado
    INNER JOIN TipoActividad    TA  ON A.id_tipo_actividad       = TA.id_tipo_actividad
    INNER JOIN Prioridad        P   ON A.id_prioridad            = P.id_prioridad
    INNER JOIN EstadoActividad  EA  ON A.id_estado_actividad     = EA.id_estado_actividad
    LEFT  JOIN Oportunidad      O   ON A.id_oportunidad          = O.id_oportunidad
    WHERE (@id_cliente      IS NULL OR A.id_cliente              = @id_cliente)
      AND (@id_empleado     IS NULL OR A.id_empleado_responsable = @id_empleado)
      AND (@id_estado       IS NULL OR A.id_estado_actividad     = @id_estado)
      AND (@id_oportunidad  IS NULL OR A.id_oportunidad          = @id_oportunidad)
    ORDER BY A.fecha DESC, A.hora_inicio DESC;
END;
GO

-- ------------------------------------------------------------
-- sp_ActualizarActividad
-- Actualiza los datos completos de una actividad.
-- Recalcula duracion_minutos si se cambia hora_fin.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ActualizarActividad
    @id_actividad           INT,
    @id_tipo_actividad      INT,
    @asunto                 VARCHAR(200),
    @fecha                  DATE,
    @hora_inicio            TIME,
    @hora_fin               TIME            = NULL,
    @id_prioridad           INT,
    @comentario             VARCHAR(MAX)    = NULL,
    @id_estado_actividad    INT,
    @calle                  VARCHAR(150)    = NULL,
    @ciudad                 VARCHAR(100)    = NULL,
    @sala                   VARCHAR(50)     = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Actividad WHERE id_actividad = @id_actividad)
            RAISERROR('Actividad no encontrada.', 16, 1);

        DECLARE @duracion_minutos INT = NULL;
        IF @hora_fin IS NOT NULL
            SET @duracion_minutos = DATEDIFF(MINUTE, @hora_inicio, @hora_fin);

        UPDATE Actividad SET
            id_tipo_actividad   = @id_tipo_actividad,
            asunto              = @asunto,
            fecha               = @fecha,
            hora_inicio         = @hora_inicio,
            hora_fin            = @hora_fin,
            duracion_minutos    = @duracion_minutos,
            id_prioridad        = @id_prioridad,
            comentario          = @comentario,
            id_estado_actividad = @id_estado_actividad,
            calle               = @calle,
            ciudad              = @ciudad,
            sala                = @sala
        WHERE id_actividad = @id_actividad;

        COMMIT TRANSACTION;
        SELECT 'Actividad actualizada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_ActualizarEstadoActividad
-- Cambia unicamente el estado de una actividad.
-- Si se cierra/concluye y no hay hora_fin, la registra.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ActualizarEstadoActividad
    @id_actividad           INT,
    @id_estado_actividad    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Actividad       WHERE id_actividad        = @id_actividad)
            RAISERROR('Actividad no encontrada.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM EstadoActividad WHERE id_estado_actividad = @id_estado_actividad)
            RAISERROR('Estado de actividad no valido.', 16, 1);

        -- Si el estado es CONCLUIDO o CERRADO y no hay hora_fin, calcularla
        DECLARE @es_estado_cierre BIT = 0;
        IF EXISTS (
            SELECT 1 FROM EstadoActividad
            WHERE id_estado_actividad = @id_estado_actividad
              AND codigo IN ('CONCLUIDO', 'CERRADO')
        )
            SET @es_estado_cierre = 1;

        UPDATE Actividad SET
            id_estado_actividad = @id_estado_actividad,
            hora_fin = CASE
                WHEN @es_estado_cierre = 1 AND hora_fin IS NULL THEN CAST(GETDATE() AS TIME)
                ELSE hora_fin
            END,
            duracion_minutos = CASE
                WHEN @es_estado_cierre = 1 AND hora_fin IS NULL
                THEN DATEDIFF(MINUTE, hora_inicio, CAST(GETDATE() AS TIME))
                ELSE duracion_minutos
            END
        WHERE id_actividad = @id_actividad;

        COMMIT TRANSACTION;
        SELECT 'Estado de actividad actualizado.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- sp_EliminarActividad
-- Baja logica: cambia estado a INACTIVO.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_EliminarActividad
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Actividad WHERE id_actividad = @id_actividad)
            RAISERROR('Actividad no encontrada.', 16, 1);

        DECLARE @id_estado_inactivo INT;
        SELECT @id_estado_inactivo = id_estado_actividad FROM EstadoActividad WHERE codigo = 'INACTIVO';

        UPDATE Actividad SET id_estado_actividad = @id_estado_inactivo
        WHERE id_actividad = @id_actividad;

        COMMIT TRANSACTION;
        SELECT 'Actividad desactivada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- ============================================================
-- SECCION 5: REPORTES E INFORMES
-- ============================================================

-- ------------------------------------------------------------
-- sp_ReporteOportunidadesPorFecha
-- Informe de oportunidades dentro de un rango de fechas.
-- Devuelve: [0] detalle de oportunidades, [1] resumen por estado.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ReporteOportunidadesPorFecha
    @fecha_inicio   DATE,
    @fecha_fin      DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @fecha_inicio > @fecha_fin
        RAISERROR('La fecha de inicio no puede ser mayor a la fecha fin.', 16, 1);

    -- Resultset 1: Detalle
    SELECT
        O.numero_oportunidad,
        O.nombre_oportunidad,
        C.nombre_comercial          AS cliente,
        EV.nombre_completo          AS vendedor,
        EG.nombre_completo          AS gerente,
        O.fecha_inicio,
        O.fecha_cierre_prevista,
        O.fecha_cierre_real,
        O.cierre_planificado_valor,
        UC.nombre                   AS unidad_cierre,
        O.monto_potencial,
        O.monto_ponderado,
        O.porcentaje_avance,
        EO.nombre                   AS estado,
        RO.nombre                   AS resultado,
        TIO.nombre                  AS tipo_oportunidad,
        UE.nombre_etapa             AS etapa_actual
    FROM Oportunidad O
    INNER JOIN Cliente              C   ON O.id_cliente             = C.id_cliente
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor   = EV.id_empleado
    INNER JOIN Empleado             EG  ON O.id_empleado_gerente    = EG.id_empleado
    INNER JOIN TipoOportunidad      TIO ON O.id_tipo_oportunidad    = TIO.id_tipo_oportunidad
    INNER JOIN EstadoOportunidad    EO  ON O.id_estado_oportunidad  = EO.id_estado_oportunidad
    INNER JOIN UnidadCierre         UC  ON O.id_unidad_cierre       = UC.id_unidad
    LEFT  JOIN ResultadoOportunidad RO  ON O.id_resultado           = RO.id_resultado
    OUTER APPLY (
        SELECT TOP 1 TE.nombre_etapa
        FROM Etapa_Oportunidad EOP
        INNER JOIN TipoEtapa TE ON EOP.id_tipo_etapa = TE.id_tipo_etapa
        WHERE EOP.id_oportunidad = O.id_oportunidad
        ORDER BY EOP.fecha_inicio_etapa DESC, EOP.id_etapa_oportunidad DESC
    ) UE
    WHERE O.fecha_inicio BETWEEN @fecha_inicio AND @fecha_fin
    ORDER BY O.fecha_inicio DESC;

    -- Resultset 2: Totales por estado
    SELECT
        EO.nombre                       AS estado,
        COUNT(O.id_oportunidad)         AS cantidad,
        ISNULL(SUM(O.monto_potencial),0) AS monto_total_potencial,
        ISNULL(SUM(O.monto_ponderado), 0) AS monto_total_ponderado
    FROM Oportunidad O
    INNER JOIN EstadoOportunidad EO ON O.id_estado_oportunidad = EO.id_estado_oportunidad
    WHERE O.fecha_inicio BETWEEN @fecha_inicio AND @fecha_fin
    GROUP BY EO.nombre;
END;
GO

-- ------------------------------------------------------------
-- sp_ReporteOportunidadesPorGestor
-- Informe agrupado por gestor/vendedor comercial.
-- Parametros opcionales: empleado y rango de fechas.
-- Devuelve: [0] detalle por gestor, [1] resumen KPI por gestor.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ReporteOportunidadesPorGestor
    @id_empleado    INT     = NULL,
    @fecha_inicio   DATE    = NULL,
    @fecha_fin      DATE    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultset 1: Detalle
    SELECT
        EV.nombre_completo          AS gestor_comercial,
        O.numero_oportunidad,
        O.nombre_oportunidad,
        C.nombre_comercial          AS cliente,
        O.fecha_inicio,
        O.fecha_cierre_prevista,
        O.monto_potencial,
        O.monto_ponderado,
        O.porcentaje_avance,
        EO.nombre                   AS estado,
        RO.nombre                   AS resultado,
        UE.nombre_etapa             AS etapa_actual
    FROM Oportunidad O
    INNER JOIN Cliente              C   ON O.id_cliente             = C.id_cliente
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor   = EV.id_empleado
    INNER JOIN EstadoOportunidad    EO  ON O.id_estado_oportunidad  = EO.id_estado_oportunidad
    LEFT  JOIN ResultadoOportunidad RO  ON O.id_resultado           = RO.id_resultado
    OUTER APPLY (
        SELECT TOP 1 TE.nombre_etapa
        FROM Etapa_Oportunidad EOP
        INNER JOIN TipoEtapa TE ON EOP.id_tipo_etapa = TE.id_tipo_etapa
        WHERE EOP.id_oportunidad = O.id_oportunidad
        ORDER BY EOP.fecha_inicio_etapa DESC, EOP.id_etapa_oportunidad DESC
    ) UE
    WHERE (@id_empleado  IS NULL OR O.id_empleado_vendedor = @id_empleado)
      AND (@fecha_inicio IS NULL OR O.fecha_inicio >= @fecha_inicio)
      AND (@fecha_fin    IS NULL OR O.fecha_inicio <= @fecha_fin)
    ORDER BY EV.nombre_completo, O.fecha_inicio DESC;

    -- Resultset 2: KPI por gestor
    SELECT
        EV.nombre_completo                                              AS gestor_comercial,
        COUNT(O.id_oportunidad)                                         AS total_oportunidades,
        ISNULL(SUM(O.monto_potencial), 0)                               AS monto_total_potencial,
        ISNULL(SUM(O.monto_ponderado), 0)                               AS monto_total_ponderado,
        SUM(CASE WHEN RO.codigo = 'GANADA'  THEN 1 ELSE 0 END)         AS ganadas,
        SUM(CASE WHEN RO.codigo = 'PERDIDA' THEN 1 ELSE 0 END)         AS perdidas,
        SUM(CASE WHEN RO.codigo = 'ABIERTA' THEN 1 ELSE 0 END)         AS en_proceso,
        CASE WHEN COUNT(O.id_oportunidad) > 0
            THEN CAST(
                SUM(CASE WHEN RO.codigo = 'GANADA' THEN 1.0 ELSE 0 END)
                / COUNT(O.id_oportunidad) * 100 AS DECIMAL(5,2))
            ELSE 0
        END                                                             AS tasa_cierre_pct
    FROM Oportunidad O
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor = EV.id_empleado
    LEFT  JOIN ResultadoOportunidad RO  ON O.id_resultado         = RO.id_resultado
    WHERE (@id_empleado  IS NULL OR O.id_empleado_vendedor = @id_empleado)
      AND (@fecha_inicio IS NULL OR O.fecha_inicio >= @fecha_inicio)
      AND (@fecha_fin    IS NULL OR O.fecha_inicio <= @fecha_fin)
    GROUP BY EV.id_empleado, EV.nombre_completo
    ORDER BY monto_total_potencial DESC;
END;
GO

-- ------------------------------------------------------------
-- sp_ReporteOportunidadesGanadasPerdidas
-- Informe de oportunidades cerradas (ganadas y/o perdidas).
-- Devuelve: [0] detalle, [1] resumen comparativo.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ReporteOportunidadesGanadasPerdidas
    @fecha_inicio   DATE        = NULL,
    @fecha_fin      DATE        = NULL,
    @resultado      VARCHAR(10) = NULL  -- 'GANADA', 'PERDIDA' o NULL = ambas
AS
BEGIN
    SET NOCOUNT ON;

    IF @resultado IS NOT NULL AND @resultado NOT IN ('GANADA', 'PERDIDA')
        RAISERROR('El parametro resultado debe ser GANADA, PERDIDA o NULL.', 16, 1);

    -- Resultset 1: Detalle
    SELECT
        O.numero_oportunidad,
        O.nombre_oportunidad,
        C.nombre_comercial          AS cliente,
        EV.nombre_completo          AS vendedor,
        EG.nombre_completo          AS gerente,
        O.fecha_inicio,
        O.fecha_cierre_real,
        DATEDIFF(DAY, O.fecha_inicio, O.fecha_cierre_real) AS dias_negociacion,
        O.monto_potencial,
        O.monto_ponderado,
        RO.nombre                   AS resultado,
        TIO.nombre                  AS tipo_oportunidad
    FROM Oportunidad O
    INNER JOIN Cliente              C   ON O.id_cliente             = C.id_cliente
    INNER JOIN Empleado             EV  ON O.id_empleado_vendedor   = EV.id_empleado
    INNER JOIN Empleado             EG  ON O.id_empleado_gerente    = EG.id_empleado
    INNER JOIN TipoOportunidad      TIO ON O.id_tipo_oportunidad    = TIO.id_tipo_oportunidad
    INNER JOIN ResultadoOportunidad RO  ON O.id_resultado           = RO.id_resultado
    WHERE RO.codigo IN ('GANADA', 'PERDIDA')
      AND (@resultado    IS NULL OR RO.codigo = @resultado)
      AND (@fecha_inicio IS NULL OR O.fecha_cierre_real >= @fecha_inicio)
      AND (@fecha_fin    IS NULL OR O.fecha_cierre_real <= @fecha_fin)
    ORDER BY O.fecha_cierre_real DESC;

    -- Resultset 2: Resumen
    SELECT
        RO.nombre                                                           AS resultado,
        COUNT(O.id_oportunidad)                                             AS cantidad,
        ISNULL(SUM(O.monto_potencial), 0)                                   AS monto_total,
        ISNULL(AVG(CAST(DATEDIFF(DAY, O.fecha_inicio, O.fecha_cierre_real) AS DECIMAL(10,2))), 0)
                                                                            AS promedio_dias_cierre
    FROM Oportunidad O
    INNER JOIN ResultadoOportunidad RO ON O.id_resultado = RO.id_resultado
    WHERE RO.codigo IN ('GANADA', 'PERDIDA')
      AND (@resultado    IS NULL OR RO.codigo = @resultado)
      AND (@fecha_inicio IS NULL OR O.fecha_cierre_real >= @fecha_inicio)
      AND (@fecha_fin    IS NULL OR O.fecha_cierre_real <= @fecha_fin)
    GROUP BY RO.nombre;
END;
GO
