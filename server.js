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
        
        // Calcular fecha prevista (30 días por defecto si no viene)
        const dias = cierre_planificado_valor || 30;
        
        await sql.query(`
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
                activo
            ) VALUES (
                '${numero_oportunidad}',
                N'${nombre_oportunidad.replace(/'/g, "''")}',
                ${id_cliente},
                ${id_empleado_vendedor},
                1,  -- Gerente por defecto (ID 1)
                ${id_tipo_oportunidad || 1},
                1,  -- Estado: Abierto
                ${dias},
                ${id_unidad_cierre || 1},
                DATEADD(DAY, ${dias}, GETDATE()),
                ${monto_potencial || 0},
                1
            )
        `);
        
        console.log(`Oportunidad creada: ${numero_oportunidad}`);
        res.json({ success: true, numero_oportunidad });
        
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

// ========== INICIAR SERVIDOR ==========
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`
    Inicio del server JS en http://localhost:${PORT}
    `);
});