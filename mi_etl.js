const sql = require('mssql');
const fs = require('fs');

const config = {
    user: 'sa',
    password: '123456789',
    server: 'localhost',
    database: 'CRMVentas',
    options: { encrypt: false, trustServerCertificate: true }
};

async function ejecutarETL() {
    try {
        let pool = await sql.connect(config);
        
        // 1. LEER EL TXT
        const archivoTexto = fs.readFileSync('datos.txt', 'utf8');
        
        // 2. DIVIDIR EL TEXTO POR LÍNEAS
        const lineas = archivoTexto.split('\n');

        for (let linea of lineas) {
            if (!linea.trim()) continue; // Saltarse líneas vacías

            // 3. DIVIDIR POR COMAS (Transformación)
            const [nombre, tipo, email] = linea.split(',');

            await pool.request()
                .input('nombre', sql.VarChar, nombre.toUpperCase())
                .input('tipo', sql.Int, parseInt(tipo))
                .input('email', sql.VarChar, email.trim())
                .query(`INSERT INTO dbo.Cliente (nombre_comercial, id_tipo_cliente, email, fecha_registro, activo) 
                        VALUES (@nombre, @tipo, @email, GETDATE(), 1)`);
            
            console.log("Éxito: Cliente", nombre, "guardado desde TXT.");
        }
    } catch (err) {
        console.error("Error:", err);
    }
}

ejecutarETL();