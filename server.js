const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// ========== CONFIGURACIÓN ==========
const configs = [
    {
        user: process.env.DB_USER || 'sa',
        password: process.env.DB_PASSWORD || 'Panchito1310!',
        server: process.env.DB_SERVER_PRIMARY || 'localhost\\SQL1',
        database: process.env.DB_NAME || 'CRMVentas',
        options: { encrypt: false, trustServerCertificate: true, enableArithAbort: true }
    },
    {
        user: process.env.DB_USER || 'sa',
        password: process.env.DB_PASSWORD || 'Panchito1310!',
        server: process.env.DB_SERVER_SECONDARY || 'localhost\\SQL2',
        database: process.env.DB_NAME || 'CRMVentas',
        options: { encrypt: false, trustServerCertificate: true, enableArithAbort: true }
    }
];

async function conectarBD() {
    for (const cfg of configs) {
        try {
            await sql.connect(cfg);
            console.log('Conectado a SQL Server:', cfg.server);
            console.log('Base de datos:', cfg.database);
            return;
        } catch (err) {
            console.log('No conectó a', cfg.server, '-', err.message);
        }
    }
    console.error('No se pudo conectar a ninguna instancia configurada.');
}

conectarBD();

function boolToBit(value, defaultValue = true) {
    if (value === undefined || value === null) return defaultValue ? 1 : 0;
    return value ? 1 : 0;
}

function fechaOrNull(value) {
    return value ? value : null;
}

// ========== HELPERS PARA PROCEDIMIENTOS ALMACENADOS ==========
async function ejecutarSP(nombre, params = {}) {
    const request = new sql.Request();
    for (const [key, cfg] of Object.entries(params)) {
        request.input(key, cfg.type, cfg.value);
    }
    return await request.execute(nombre);
}

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

// GET - Listar clientes usando SP
app.get('/api/clientes', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerClientes', {
            activo: { type: sql.Bit, value: 1 }
        });
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /clientes:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// POST - Crear cliente usando SP
app.post('/api/clientes', async (req, res) => {
    try {
        const { nombre_comercial, razon_social, contacto_nombre, telefono, celular, email, direccion, id_tipo_cliente } = req.body;
        if (!nombre_comercial) return res.status(400).json({ error: 'El nombre comercial es requerido' });

        const result = await ejecutarSP('sp_CrearCliente', {
            nombre_comercial: { type: sql.VarChar(100), value: nombre_comercial },
            razon_social: { type: sql.VarChar(100), value: razon_social || null },
            direccion: { type: sql.VarChar(255), value: direccion || null },
            telefono: { type: sql.VarChar(20), value: telefono || null },
            celular: { type: sql.VarChar(20), value: celular || null },
            email: { type: sql.VarChar(100), value: email || null },
            contacto_nombre: { type: sql.VarChar(100), value: contacto_nombre || null },
            id_tipo_cliente: { type: sql.Int, value: Number(id_tipo_cliente || 1) }
        });

        res.json({ success: true, ...(result.recordset[0] || {}), message: 'Cliente creado correctamente' });
    } catch (err) {
        console.error('Error POST /clientes:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// ========== API: OPORTUNIDADES ==========

// GET - Listar oportunidades usando SP
app.get('/api/oportunidades', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerOportunidades', {
            activo: { type: sql.Bit, value: 1 },
            id_empleado: { type: sql.Int, value: null },
            id_estado: { type: sql.Int, value: null }
        });
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /oportunidades:', err.message);
        res.json([]);
    }
});

// POST - Crear oportunidad usando SP
app.post('/api/oportunidades', async (req, res) => {
    try {
        const { nombre_oportunidad, id_cliente, id_empleado_vendedor, id_empleado_gerente, id_tipo_oportunidad, monto_potencial, cierre_planificado_valor, id_unidad_cierre } = req.body;

        if (!nombre_oportunidad || !id_cliente || !id_empleado_vendedor) {
            return res.status(400).json({ error: 'Nombre, cliente y vendedor son requeridos' });
        }

        const gerente = Number(id_empleado_gerente || 1);
        const result = await ejecutarSP('sp_CrearOportunidad', {
            nombre_oportunidad: { type: sql.VarChar(150), value: nombre_oportunidad },
            id_cliente: { type: sql.Int, value: Number(id_cliente) },
            id_empleado_vendedor: { type: sql.Int, value: Number(id_empleado_vendedor) },
            id_empleado_gerente: { type: sql.Int, value: gerente },
            id_tipo_oportunidad: { type: sql.Int, value: Number(id_tipo_oportunidad || 1) },
            cierre_planificado_valor: { type: sql.Int, value: Number(cierre_planificado_valor || 30) },
            id_unidad_cierre: { type: sql.Int, value: Number(id_unidad_cierre || 1) },
            monto_potencial: { type: sql.Decimal(18, 2), value: Number(monto_potencial || 0) }
        });

        const data = result.recordset[0] || {};
        res.json({ success: true, ...data, numero_oportunidad: data.numero_oportunidad, id: data.id_oportunidad });
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
// GET - Listar todos los empleados usando SP
app.get('/api/empleados', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerEmpleados', {
            activo: { type: sql.Bit, value: 1 }
        });
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Empleados activos para selects usando SP
app.get('/api/empleados/activos', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerEmpleados', {
            activo: { type: sql.Bit, value: 1 }
        });
        res.json(result.recordset.map(e => ({ id_empleado: e.id_empleado, nombre_completo: e.nombre_completo, email: e.email })));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET - Empleado por ID usando SP
app.get('/api/empleados/:id', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerEmpleadoPorId', {
            id_empleado: { type: sql.Int, value: Number(req.params.id) }
        });
        res.json(result.recordset[0] || null);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST - Crear empleado usando SP
app.post('/api/empleados', async (req, res) => {
    try {
        const { nombre_completo, email, telefono, id_rol, fecha_contratacion } = req.body;
        if (!nombre_completo || !email) return res.status(400).json({ error: 'Nombre y email son requeridos' });

        const result = await ejecutarSP('sp_CrearEmpleado', {
            nombre_completo: { type: sql.VarChar(100), value: nombre_completo },
            email: { type: sql.VarChar(100), value: email },
            telefono: { type: sql.VarChar(20), value: telefono || null },
            id_rol: { type: sql.Int, value: Number(id_rol || 1) },
            fecha_contratacion: { type: sql.Date, value: fechaOrNull(fecha_contratacion) }
        });

        res.json({ success: true, ...(result.recordset[0] || {}), message: 'Empleado creado correctamente' });
    } catch (err) {
        console.error('Error POST /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// PUT - Actualizar empleado usando SP
app.put('/api/empleados/:id', async (req, res) => {
    try {
        const { nombre_completo, email, telefono, id_rol, activo } = req.body;
        const result = await ejecutarSP('sp_ActualizarEmpleado', {
            id_empleado: { type: sql.Int, value: Number(req.params.id) },
            nombre_completo: { type: sql.VarChar(100), value: nombre_completo },
            email: { type: sql.VarChar(100), value: email },
            telefono: { type: sql.VarChar(20), value: telefono || null },
            id_rol: { type: sql.Int, value: Number(id_rol || 1) },
            activo: { type: sql.Bit, value: boolToBit(activo, true) }
        });
        res.json({ success: true, ...(result.recordset[0] || {}), message: 'Empleado actualizado' });
    } catch (err) {
        console.error('Error PUT /empleados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// DELETE - Eliminar empleado usando SP
app.delete('/api/empleados/:id', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_EliminarEmpleado', {
            id_empleado: { type: sql.Int, value: Number(req.params.id) }
        });
        res.json({ success: true, ...(result.recordset[0] || {}), message: 'Empleado desactivado' });
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
            SELECT 
                id_tipo_etapa,
                nombre_etapa,
                porcentaje,
                orden,
                descripcion
            FROM TipoEtapa
            ORDER BY orden;
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /etapas:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET - Oportunidades para Kanban
app.get('/api/oportunidades/kanban', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT 
                O.id_oportunidad,
                O.numero_oportunidad,
                O.nombre_oportunidad,
                ISNULL(C.nombre_comercial, 'Sin cliente') AS cliente,
                ISNULL(E.nombre_completo, 'Sin vendedor') AS vendedor,
                ISNULL(O.monto_potencial, 0) AS monto_potencial,
                ISNULL(O.porcentaje_avance, 0) AS porcentaje_avance,
                ISNULL(TE.id_tipo_etapa, 1) AS id_etapa_actual,
                ISNULL(TE.nombre_etapa, 'Calificación') AS etapa_nombre,
                ISNULL(TE.orden, 1) AS etapa_orden
            FROM Oportunidad O
            LEFT JOIN Cliente C ON O.id_cliente = C.id_cliente
            LEFT JOIN Empleado E ON O.id_empleado_vendedor = E.id_empleado
            OUTER APPLY (
                SELECT TOP 1 EO.id_tipo_etapa
                FROM Etapa_Oportunidad EO
                WHERE EO.id_oportunidad = O.id_oportunidad
                ORDER BY EO.fecha_inicio_etapa DESC, EO.id_etapa_oportunidad DESC
            ) UltimaEtapa
            LEFT JOIN TipoEtapa TE ON UltimaEtapa.id_tipo_etapa = TE.id_tipo_etapa
            WHERE O.activo = 1
            ORDER BY O.id_oportunidad DESC;
        `);
        
        console.log('Kanban OK:', result.recordset.length, 'oportunidades');
        res.json(result.recordset);
        
    } catch (err) {
        console.error('Error kanban:', err.message);
        res.json([]);
    }
});
// POST - Cambiar etapa de una oportunidad usando SP
app.post('/api/oportunidades/:id/cambiar-etapa', async (req, res) => {
    try {
        const { id } = req.params;
        const { id_tipo_etapa, comentario } = req.body;

        // Procedimiento complementario tomado de crmVentasMar/baseDeDatos/02_procedimientos_almacenados.sql
        const result = await ejecutarSP('sp_CambiarEtapaOportunidad', {
            id_oportunidad: { type: sql.Int, value: Number(id) },
            id_tipo_etapa: { type: sql.Int, value: Number(id_tipo_etapa) },
            comentario: { type: sql.NVarChar(300), value: comentario || 'Cambio de etapa desde backend' }
        });

        const data = result.recordset[0] || {};
        res.json({
            success: true,
            message: data.mensaje || 'Etapa actualizada correctamente',
            nuevoPorcentaje: data.nuevo_porcentaje,
            nuevaEtapa: data.id_tipo_etapa
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

// GET - Listar actividades usando SP
app.get('/api/actividades', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerActividades', {
            id_cliente: { type: sql.Int, value: null },
            id_empleado: { type: sql.Int, value: null },
            id_estado: { type: sql.Int, value: null },
            id_oportunidad: { type: sql.Int, value: null }
        });
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /actividades:', err.message);
        res.json([]);
    }
});

// GET - Actividades por oportunidad usando SP
app.get('/api/oportunidades/:id/actividades', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerActividades', {
            id_cliente: { type: sql.Int, value: null },
            id_empleado: { type: sql.Int, value: null },
            id_estado: { type: sql.Int, value: null },
            id_oportunidad: { type: sql.Int, value: Number(req.params.id) }
        });
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /oportunidades/:id/actividades:', err.message);
        res.json([]);
    }
});

// POST - Crear actividad usando SP
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
            id_estado_actividad,
            id_oportunidad,
            calle,
            ciudad,
            sala
        } = req.body;

        if (!id_cliente || !id_empleado_responsable || !asunto || !fecha) {
            return res.status(400).json({ error: 'Faltan campos requeridos' });
        }

        function normalizarHora(valor) {
            if (!valor || String(valor).trim() === '') {
                return null;
            }

            let hora = String(valor).trim();

            if (hora.includes('T')) {
                hora = hora.split('T')[1];
            }

            if (hora.includes('.')) {
                hora = hora.split('.')[0];
            }

            if (hora.length === 5) {
                hora += ':00';
            }

            if (!/^\d{2}:\d{2}:\d{2}$/.test(hora)) {
                return null;
            }

            return hora;
        }

        let horaInicio = normalizarHora(hora_inicio);
        let horaFin = normalizarHora(hora_fin);

        if (!horaInicio) {
            horaInicio = new Date().toTimeString().slice(0, 8);
        }

        const result = await ejecutarSP('sp_CrearActividad', {
            id_cliente: { type: sql.Int, value: Number(id_cliente) },
            id_empleado_responsable: { type: sql.Int, value: Number(id_empleado_responsable) },
            id_tipo_actividad: { type: sql.Int, value: Number(id_tipo_actividad || 1) },
            asunto: { type: sql.VarChar(200), value: asunto },
            fecha: { type: sql.Date, value: fecha },
            hora_inicio: { type: sql.VarChar(8), value: horaInicio },
            hora_fin: { type: sql.VarChar(8), value: horaFin },
            id_prioridad: { type: sql.Int, value: Number(id_prioridad || 2) },
            comentario: { type: sql.VarChar(sql.MAX), value: comentario || null },
            id_estado_actividad: { type: sql.Int, value: Number(id_estado_actividad || 1) },
            id_oportunidad: { type: sql.Int, value: id_oportunidad ? Number(id_oportunidad) : null },
            calle: { type: sql.VarChar(150), value: calle || null },
            ciudad: { type: sql.VarChar(100), value: ciudad || null },
            sala: { type: sql.VarChar(50), value: sala || null }
        });

        res.json({
            success: true,
            ...(result.recordset?.[0] || {}),
            message: 'Actividad creada correctamente'
        });

    } catch (err) {
        console.error('Error POST /actividades:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// PUT - Actualizar estado de actividad usando SP
app.put('/api/actividades/:id/estado', async (req, res) => {
    try {
        const { id_estado_actividad } = req.body;
        const result = await ejecutarSP('sp_ActualizarEstadoActividad', {
            id_actividad: { type: sql.Int, value: Number(req.params.id) },
            id_estado_actividad: { type: sql.Int, value: Number(id_estado_actividad) }
        });
        res.json({ success: true, ...(result.recordset[0] || {}), message: 'Estado actualizado' });
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

// GET - Oportunidad por ID usando SP
app.get('/api/oportunidades/:id', async (req, res) => {
    try {
        const result = await ejecutarSP('sp_ObtenerOportunidadPorId', {
            id_oportunidad: { type: sql.Int, value: Number(req.params.id) }
        });

        const oportunidad = result.recordsets?.[0]?.[0] || result.recordset?.[0];
        if (!oportunidad) return res.status(404).json({ error: 'Oportunidad no encontrada' });
        res.json(oportunidad);
    } catch (err) {
        console.error('Error GET /oportunidades/:id:', err.message);
        res.status(500).json({ error: err.message });
    }
});



// ========== API: REPORTES Y CIERRE (tomado de crmVentasMar) ==========

// Reporte de oportunidades por gestor/vendedor
app.get('/api/reportes/gestor', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT *
            FROM vw_OportunidadesPorGestor
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /reportes/gestor:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// Reporte de oportunidades por mes
app.get('/api/reportes/mes', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT *
            FROM vw_OportunidadesPorMes
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /reportes/mes:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// Reporte de oportunidades ganadas/perdidas
app.get('/api/reportes/resultados', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT *
            FROM vw_OportunidadesGanadasPerdidas
        `);
        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /reportes/resultados:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// Dashboard desde Data Warehouse
app.get('/api/dw/dashboard', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT
                DE.nombre_completo AS Vendedor,
                FO.resultado_oportunidad AS Resultado,
                COUNT(*) AS Total,
                SUM(FO.monto_potencial) AS MontoPotencial,
                SUM(FO.monto_ponderado) AS MontoPonderado
            FROM CRMVentas_DW.dbo.FactOportunidades FO
            INNER JOIN CRMVentas_DW.dbo.DimEmpleado DE
                ON FO.id_empleado_dw = DE.id_empleado_dw
            GROUP BY
                DE.nombre_completo,
                FO.resultado_oportunidad
        `);

        res.json(result.recordset);
    } catch (err) {
        console.error('Error GET /dw/dashboard:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// Cerrar oportunidad usando SP complementario de crmVentasMar
app.post('/api/oportunidades/:id/cerrar', async (req, res) => {
    try {
        const { id } = req.params;
        const { id_resultado, comentario } = req.body;

        const result = await ejecutarSP('sp_CerrarOportunidad', {
            id_oportunidad: { type: sql.Int, value: Number(id) },
            id_resultado: { type: sql.Int, value: Number(id_resultado) },
            comentario: { type: sql.NVarChar(300), value: comentario || 'Cierre desde frontend' }
        });

        res.json({
            success: true,
            message: result.recordset?.[0]?.mensaje || 'Oportunidad cerrada correctamente',
            data: result.recordset?.[0] || null
        });
    } catch (err) {
        console.error('Error POST /oportunidades/:id/cerrar:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// ========== INICIAR SERVIDOR ==========
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`
    Inicio del server JS en http://localhost:${PORT}
    `);
});