const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// ========== CONFIGURACIÓN ==========
const config = {
    user: 'sa',
    password: 'CrmVentas2024!',
    server: 'localhost\\SQLEXPRESS',
    database: 'CRMVentas',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

// Conectar al iniciar
sql.connect(config).then(() => {
    console.log('Conectado a SQL Server');
    console.log('Base de datos: CRMVentas');
}).catch(err => {
    console.error('Error de conexión:', err.message);
});

// ========== HEALTH CHECK ==========
app.get('/api/health', async (req, res) => {
    try {
        const result = await sql.query('SELECT DB_NAME() as bd, GETDATE() as fecha');
        res.json({ 
            status: 'ok', 
            message: 'Conectado a SQL Server',
            base_datos: result.recordset[0].bd
        });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
});

// ========== API: CLIENTES ==========

// GET - Listar clientes
app.get('/api/clientes', async (req, res) => {
    try {
        const result = await sql.query(`
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
                T.nombre as tipo_cliente_nombre
            FROM Cliente C
            INNER JOIN TipoCliente T ON C.id_tipo_cliente = T.id_tipo_cliente
            WHERE C.activo = 1
            ORDER BY C.id_cliente DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /clientes:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// POST - Crear cliente (adaptado a tu esquema)
app.post('/api/clientes', async (req, res) => {
    try {
        const { 
            nombre_comercial, 
            razon_social,
            contacto_nombre, 
            telefono,
            celular,
            email,
            direccion,
            id_tipo_cliente 
        } = req.body;
        
        if (!nombre_comercial) {
            return res.status(400).json({ error: 'El nombre comercial es requerido' });
        }
        
        // Si no viene id_tipo_cliente, usar 1 (Potencial por defecto)
        const tipoCliente = id_tipo_cliente || 1;
        
        await sql.query(`
            INSERT INTO Cliente (
                nombre_comercial, 
                razon_social,
                contacto_nombre, 
                telefono,
                celular,
                email,
                direccion,
                id_tipo_cliente,
                activo
            ) VALUES (
                N'${nombre_comercial.replace(/'/g, "''")}',
                N'${(razon_social || '').replace(/'/g, "''")}',
                N'${(contacto_nombre || '').replace(/'/g, "''")}',
                '${(telefono || '').replace(/'/g, "''")}',
                '${(celular || '').replace(/'/g, "''")}',
                '${(email || '').replace(/'/g, "''")}',
                N'${(direccion || '').replace(/'/g, "''")}',
                ${tipoCliente},
                1
            )
        `);
        
        console.log(`Cliente creado: ${nombre_comercial}`);
        res.json({ success: true, message: 'Cliente creado correctamente' });
        
    } catch (err) {
        console.error('Error POST /clientes:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// ========== API: EMPLEADOS ==========

// POST - Crear empleado
app.post('/api/empleados', async (req, res) => {
    try {
        console.log('Body recibido:', req.body);
        
        const { nombre_completo, email, telefono, id_rol, fecha_contratacion } = req.body;
        
        // Validación
        if (!nombre_completo || !email) {
            console.log('Faltan campos requeridos');
            return res.status(400).json({ error: 'Nombre y email son requeridos' });
        }
        
        // Verificar email único
        const existCheck = await sql.query(`
            SELECT COUNT(*) as count FROM Empleado WHERE email = '${email.replace(/'/g, "''")}'
        `);
        
        if (existCheck.recordset[0].count > 0) {
            console.log('Email ya existe');
            return res.status(400).json({ error: 'Ya existe un empleado con ese email' });
        }
        
        const fecha = fecha_contratacion || new Date().toISOString().split('T')[0];
        
        // Insertar empleado
        const result = await sql.query(`
            INSERT INTO Empleado (nombre_completo, email, telefono, id_rol, fecha_contratacion, activo)
            VALUES (
                N'${nombre_completo.replace(/'/g, "''")}',
                '${email.replace(/'/g, "''")}',
                '${(telefono || '').replace(/'/g, "''")}',
                ${id_rol || 1},
                '${fecha}',
                1
            );
            
            -- Obtener el ID insertado
            SELECT SCOPE_IDENTITY() AS id;
        `);
        
        // Obtener el ID del empleado insertado
        const nuevoId = result.recordset[0]?.id || result.recordset[0]?.id_empleado;
        
        console.log(`Empleado creado: ${nombre_completo} (ID: ${nuevoId})`);
        
        res.status(200).json({ 
            success: true, 
            message: 'Empleado creado correctamente',
            id: nuevoId
        });
        
    } catch (err) {
        console.error('Error POST /empleados:', err.message);
        console.error('Detalle completo:', err);
        
        // Verificar si es error de duplicado
        if (err.message.includes('duplicate') || err.message.includes('UNIQUE')) {
            return res.status(400).json({ error: 'Ya existe un empleado con ese email' });
        }
        
        res.status(500).json({ error: err.message });
    }
});

// ========== API: OPORTUNIDADES ==========

// GET - Listar oportunidades
app.get('/api/oportunidades', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                O.id_oportunidad,
                O.numero_oportunidad,
                O.nombre_oportunidad,
                C.nombre_comercial AS cliente,
                E.nombre_completo AS vendedor,
                O.monto_potencial,
                O.porcentaje_avance,
                O.fecha_inicio,
                O.fecha_cierre_prevista,
                T.nombre as tipo_oportunidad
            FROM Oportunidad O
            LEFT JOIN Cliente C ON O.id_cliente = C.id_cliente
            LEFT JOIN Empleado E ON O.id_empleado_vendedor = E.id_empleado
            LEFT JOIN TipoOportunidad T ON O.id_tipo_oportunidad = T.id_tipo_oportunidad
            WHERE O.activo = 1
            ORDER BY O.id_oportunidad DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /oportunidades:', err.message);
        res.json([]);
    }
});

    // POST - Crear oportunidad
    app.post('/api/oportunidades', async (req, res) => {
        try {
            const { 
                nombre_oportunidad, 
                id_cliente, 
                id_empleado_vendedor,
                id_tipo_oportunidad,
                monto_potencial,
                cierre_planificado_valor,
                id_unidad_cierre
            } = req.body;
            
            // Generar número de oportunidad
            const numResult = await sql.query(`
                SELECT ISNULL(MAX(CAST(REPLACE(numero_oportunidad, 'OP-', '') AS INT)), 0) + 1 AS nextNum 
                FROM Oportunidad
            `);
            const numero_oportunidad = `OP-${numResult.recordset[0].nextNum}`;
            
            const dias = cierre_planificado_valor || 30;
            
            // Insertar oportunidad
            const insertResult = await sql.query(`
                INSERT INTO Oportunidad (
                    numero_oportunidad,
                    nombre_oportunidad,
                    id_cliente,
                    id_empleado_vendedor,
                    id_empleado_gerente,
                    id_tipo_oportunidad,
                    id_estado_oportunidad,
                    cierre_planificado_valor,
                    id_unidad_cierre,
                    fecha_cierre_prevista,
                    monto_potencial,
                    porcentaje_avance,
                    activo
                ) VALUES (
                    '${numero_oportunidad}',
                    N'${nombre_oportunidad.replace(/'/g, "''")}',
                    ${id_cliente},
                    ${id_empleado_vendedor},
                    1,
                    ${id_tipo_oportunidad || 1},
                    1,
                    ${dias},
                    ${id_unidad_cierre || 1},
                    DATEADD(DAY, ${dias}, GETDATE()),
                    ${monto_potencial || 0},
                    0,
                    1
                );
                SELECT SCOPE_IDENTITY() AS id;
            `);
            
            const nuevaId = insertResult.recordset[0].id;
            
            // Agregar etapa inicial (Calificación - 30%)
            await sql.query(`
                INSERT INTO Etapa_Oportunidad (
                    id_oportunidad,
                    id_tipo_etapa,
                    id_empleado_ventas,
                    fecha_inicio_etapa,
                    monto_potencial_etapa,
                    importe_ponderado_etapa,
                    comentario
                ) VALUES (
                    ${nuevaId},
                    1,  -- Calificación de la oportunidad
                    ${id_empleado_vendedor},
                    GETDATE(),
                    ${monto_potencial || 0},
                    ${(monto_potencial || 0) * 0.30},
                    'Oportunidad creada'
                )
            `);
            
            console.log(`Oportunidad creada: ${numero_oportunidad}`);
            res.json({ success: true, numero_oportunidad, id: nuevaId });
            
        } catch (err) {
            console.error('Error POST /oportunidades:', err.message);
            res.status(500).json({ error: err.message });
        }
    });

// ========== API: CATÁLOGOS ==========

app.get('/api/tipos-cliente', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_tipo_cliente, codigo, nombre FROM TipoCliente');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

app.get('/api/tipos-oportunidad', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_tipo_oportunidad, codigo, nombre FROM TipoOportunidad');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

app.get('/api/unidades-cierre', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_unidad, codigo, nombre FROM UnidadCierre');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

// ========== API: EMPLEADOS ==========
// GET - Listar todos los empleados
app.get('/api/empleados', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                E.id_empleado,
                E.nombre_completo,
                E.email,
                E.telefono,
                E.id_rol,
                R.nombre as rol_nombre,
                E.fecha_contratacion,
                E.activo
            FROM Empleado E
            INNER JOIN RolEmpleado R ON E.id_rol = R.id_rol
            ORDER BY E.id_empleado DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Empleados activos (para selects)
app.get('/api/empleados/activos', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT id_empleado, nombre_completo, email
            FROM Empleado
            WHERE activo = 1
            ORDER BY nombre_completo
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET - Empleado por ID
app.get('/api/empleados/:id', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                id_empleado, nombre_completo, email, telefono, id_rol, fecha_contratacion, activo
            FROM Empleado
            WHERE id_empleado = ${req.params.id}
        `);
        res.json(result.recordset[0] || null);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST - Crear empleado
app.post('/api/empleados', async (req, res) => {
    try {
        const { nombre_completo, email, telefono, id_rol, fecha_contratacion } = req.body;
        
        if (!nombre_completo || !email) {
            return res.status(400).json({ error: 'Nombre y email son requeridos' });
        }
        
        // Verificar email único
        const existCheck = await sql.query(`
            SELECT COUNT(*) as count FROM Empleado WHERE email = '${email.replace(/'/g, "''")}'
        `);
        
        if (existCheck.recordset[0].count > 0) {
            return res.status(400).json({ error: 'Ya existe un empleado con ese email' });
        }
        
        const fecha = fecha_contratacion || new Date().toISOString().split('T')[0];
        
        await sql.query(`
            INSERT INTO Empleado (nombre_completo, email, telefono, id_rol, fecha_contratacion, activo)
            VALUES (
                N'${nombre_completo.replace(/'/g, "''")}',
                '${email.replace(/'/g, "''")}',
                '${(telefono || '').replace(/'/g, "''")}',
                ${id_rol || 1},
                '${fecha}',
                1
            )
        `);
        
        console.log(`Empleado creado: ${nombre_completo}`);
        res.json({ success: true, message: 'Empleado creado correctamente' });
        
    } catch (err) {
        console.error('Error POST /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// PUT - Actualizar empleado
app.put('/api/empleados/:id', async (req, res) => {
    try {
        const { nombre_completo, email, telefono, id_rol, activo } = req.body;
        const id = req.params.id;
        
        await sql.query(`
            UPDATE Empleado SET
                nombre_completo = N'${nombre_completo.replace(/'/g, "''")}',
                email = '${email.replace(/'/g, "''")}',
                telefono = '${(telefono || '').replace(/'/g, "''")}',
                id_rol = ${id_rol},
                activo = ${activo ? 1 : 0}
            WHERE id_empleado = ${id}
        `);
        
        console.log(`Empleado actualizado: ID ${id}`);
        res.json({ success: true, message: 'Empleado actualizado' });
        
    } catch (err) {
        console.error('Error PUT /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// DELETE - Eliminar empleado (desactivar)
app.delete('/api/empleados/:id', async (req, res) => {
    try {
        await sql.query(`UPDATE Empleado SET activo = 0 WHERE id_empleado = ${req.params.id}`);
        res.json({ success: true, message: 'Empleado desactivado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET - Roles de empleados
app.get('/api/roles', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_rol, nombre FROM RolEmpleado');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ========== API: ETAPAS Y PIPELINE ==========

// GET - Obtener todas las etapas
app.get('/api/etapas', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT id_tipo_etapa, nombre_etapa, porcentaje, orden
            FROM TipoEtapa
            ORDER BY orden
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /etapas:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Oportunidades con su etapa actual (para Kanban)
app.get('/api/oportunidades/kanban', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                O.id_oportunidad,
                O.numero_oportunidad,
                O.nombre_oportunidad,
                C.nombre_comercial AS cliente,
                E.nombre_completo AS vendedor,
                O.monto_potencial,
                O.porcentaje_avance,
                ISNULL(TE.id_tipo_etapa, 1) AS id_etapa_actual,
                ISNULL(TE.nombre_etapa, 'Calificación de la oportunidad') AS etapa_nombre,
                ISNULL(TE.orden, 1) AS etapa_orden
            FROM Oportunidad O
            INNER JOIN Cliente C ON O.id_cliente = C.id_cliente
            INNER JOIN Empleado E ON O.id_empleado_vendedor = E.id_empleado
            LEFT JOIN (
                SELECT id_oportunidad, MAX(id_tipo_etapa) as id_tipo_etapa
                FROM Etapa_Oportunidad
                GROUP BY id_oportunidad
            ) UltimaEtapa ON O.id_oportunidad = UltimaEtapa.id_oportunidad
            LEFT JOIN TipoEtapa TE ON UltimaEtapa.id_tipo_etapa = TE.id_tipo_etapa
            WHERE O.activo = 1
            ORDER BY O.id_oportunidad DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /oportunidades/kanban:', err.message);
        res.json([]);
    }
});

// POST - Cambiar etapa de una oportunidad
app.post('/api/oportunidades/:id/cambiar-etapa', async (req, res) => {
    try {
        const { id } = req.params;
        const { id_tipo_etapa, comentario } = req.body;
        
        // Obtener información de la etapa
        const etapaResult = await sql.query(`
            SELECT porcentaje, nombre_etapa FROM TipoEtapa WHERE id_tipo_etapa = ${id_tipo_etapa}
        `);
        
        if (etapaResult.recordset.length === 0) {
            return res.status(400).json({ error: 'Etapa no válida' });
        }
        
        const porcentaje = etapaResult.recordset[0].porcentaje;
        const etapaNombre = etapaResult.recordset[0].nombre_etapa;
        
        // Obtener monto potencial actual de la oportunidad
        const oppResult = await sql.query(`
            SELECT monto_potencial, id_empleado_vendedor FROM Oportunidad WHERE id_oportunidad = ${id}
        `);
        
        if (oppResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Oportunidad no encontrada' });
        }
        
        const montoPotencial = oppResult.recordset[0].monto_potencial;
        const idVendedor = oppResult.recordset[0].id_empleado_vendedor;
        const importePonderado = montoPotencial * (porcentaje / 100);
        
        // 1. Insertar en el historial de etapas
        await sql.query(`
            INSERT INTO Etapa_Oportunidad (
                id_oportunidad, 
                id_tipo_etapa, 
                id_empleado_ventas,
                fecha_inicio_etapa,
                monto_potencial_etapa,
                importe_ponderado_etapa,
                comentario
            ) VALUES (
                ${id},
                ${id_tipo_etapa},
                ${idVendedor},
                GETDATE(),
                ${montoPotencial},
                ${importePonderado},
                '${(comentario || 'Cambio de etapa').replace(/'/g, "''")}'
            )
        `);
        
        // 2. Actualizar la oportunidad con el nuevo % y monto ponderado
        await sql.query(`
            UPDATE Oportunidad 
            SET porcentaje_avance = ${porcentaje},
                monto_ponderado = ${importePonderado}
            WHERE id_oportunidad = ${id}
        `);
        
        console.log(`Oportunidad ${id} movida a etapa: ${etapaNombre} (${porcentaje}%)`);
        
        res.json({ 
            success: true, 
            message: `Oportunidad movida a "${etapaNombre}"`,
            nuevoPorcentaje: porcentaje,
            nuevaEtapa: etapaNombre
        });
        
    } catch (err) {
        console.error('Error POST /cambiar-etapa:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Oportunidades agrupadas por etapa (para estadísticas)
app.get('/api/pipeline/stats', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                TE.nombre_etapa,
                TE.porcentaje,
                TE.orden,
                COUNT(O.id_oportunidad) AS cantidad,
                ISNULL(SUM(O.monto_potencial), 0) AS monto_total
            FROM TipoEtapa TE
            LEFT JOIN (
                SELECT DISTINCT O.id_oportunidad, O.monto_potencial, TE2.id_tipo_etapa
                FROM Oportunidad O
                LEFT JOIN Etapa_Oportunidad EO ON O.id_oportunidad = EO.id_oportunidad
                LEFT JOIN TipoEtapa TE2 ON EO.id_tipo_etapa = TE2.id_tipo_etapa
                WHERE O.activo = 1
            ) O ON TE.id_tipo_etapa = O.id_tipo_etapa
            GROUP BY TE.id_tipo_etapa, TE.nombre_etapa, TE.porcentaje, TE.orden
            ORDER BY TE.orden
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /pipeline/stats:', err.message);
        res.json([]);
    }
});

// ========== API: ACTIVIDADES ==========

// GET - Listar actividades
app.get('/api/actividades', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                A.id_actividad,
                A.numero_actividad,
                A.asunto,
                A.fecha,
                A.hora_inicio,
                A.hora_fin,
                A.duracion_minutos,
                C.nombre_comercial AS cliente,
                E.nombre_completo AS responsable,
                TA.nombre AS tipo_actividad,
                P.nombre AS prioridad,
                EA.nombre AS estado
            FROM Actividad A
            INNER JOIN Cliente C ON A.id_cliente = C.id_cliente
            INNER JOIN Empleado E ON A.id_empleado_responsable = E.id_empleado
            INNER JOIN TipoActividad TA ON A.id_tipo_actividad = TA.id_tipo_actividad
            INNER JOIN Prioridad P ON A.id_prioridad = P.id_prioridad
            INNER JOIN EstadoActividad EA ON A.id_estado_actividad = EA.id_estado_actividad
            WHERE A.fecha_creacion IS NOT NULL
            ORDER BY A.fecha DESC, A.hora_inicio DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /actividades:', err.message);
        res.json([]);
    }
});

// GET - Actividades por oportunidad
app.get('/api/actividades/oportunidad/:id', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                A.id_actividad,
                A.numero_actividad,
                A.asunto,
                A.fecha,
                A.hora_inicio,
                TA.nombre AS tipo_actividad,
                EA.nombre AS estado
            FROM Actividad A
            INNER JOIN TipoActividad TA ON A.id_tipo_actividad = TA.id_tipo_actividad
            INNER JOIN EstadoActividad EA ON A.id_estado_actividad = EA.id_estado_actividad
            WHERE A.id_cliente IN (
                SELECT id_cliente FROM Oportunidad WHERE id_oportunidad = ${req.params.id}
            )
            ORDER BY A.fecha DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /actividades/oportunidad:', err.message);
        res.json([]);
    }
});

// POST - Crear actividad
app.post('/api/actividades', async (req, res) => {
    try {
        const { 
            id_cliente, 
            id_empleado_responsable,
            id_tipo_actividad,
            asunto,
            fecha,
            hora_inicio,
            hora_fin,
            id_prioridad,
            comentario,
            id_estado_actividad
        } = req.body;
        
        // Validar campos requeridos
        if (!id_cliente || !id_empleado_responsable || !asunto || !fecha || !hora_inicio) {
            return res.status(400).json({ error: 'Faltan campos requeridos' });
        }
        
        // Generar número de actividad
        const numResult = await sql.query(`
            SELECT ISNULL(MAX(CAST(REPLACE(numero_actividad, 'ACT-', '') AS INT)), 0) + 1 AS nextNum 
            FROM Actividad
        `);
        const numero_actividad = `ACT-${numResult.recordset[0].nextNum}`;
        
        // Calcular duración si hay hora_fin
        let duracion = null;
        if (hora_inicio && hora_fin) {
            duracion = `DATEDIFF(MINUTE, '${hora_inicio}', '${hora_fin}')`;
        }
        
        await sql.query(`
            INSERT INTO Actividad (
                numero_actividad,
                id_cliente,
                id_empleado_responsable,
                id_tipo_actividad,
                asunto,
                fecha,
                hora_inicio,
                hora_fin,
                duracion_minutos,
                id_prioridad,
                comentario,
                id_estado_actividad
            ) VALUES (
                '${numero_actividad}',
                ${id_cliente},
                ${id_empleado_responsable},
                ${id_tipo_actividad || 1},
                N'${asunto.replace(/'/g, "''")}',
                '${fecha}',
                '${hora_inicio}',
                ${hora_fin ? `'${hora_fin}'` : 'NULL'},
                ${duracion || 'NULL'},
                ${id_prioridad || 2},
                N'${(comentario || '').replace(/'/g, "''")}',
                ${id_estado_actividad || 1}
            )
        `);
        
        console.log(`Actividad creada: ${numero_actividad}`);
        res.json({ success: true, message: 'Actividad creada correctamente', numero_actividad });
        
    } catch (err) {
        console.error('Error POST /actividades:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// PUT - Actualizar estado de actividad
app.put('/api/actividades/:id/estado', async (req, res) => {
    try {
        const { id_estado_actividad } = req.body;
        
        await sql.query(`
            UPDATE Actividad SET id_estado_actividad = ${id_estado_actividad}
            WHERE id_actividad = ${req.params.id}
        `);
        
        res.json({ success: true, message: 'Estado actualizado' });
    } catch (err) {
        console.error('Error PUT /actividades/estado:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Catálogos para actividades
app.get('/api/tipos-actividad', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_tipo_actividad, codigo, nombre FROM TipoActividad');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

app.get('/api/estados-actividad', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_estado_actividad, codigo, nombre FROM EstadoActividad');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

app.get('/api/prioridades', async (req, res) => {
    try {
        const result = await sql.query('SELECT id_prioridad, codigo, nombre FROM Prioridad');
        res.json(result.recordset);
    } catch (err) {
        res.json([]);
    }
});

// ========== INICIAR SERVIDOR ==========
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`
    Inicio del server JS en http://localhost:${PORT}
    `);
});