const sql = require('mssql');

async function test() {
    // Usar driver tedious que funciona mejor con Windows Auth
    const config = {
        server: 'localhost\\SQLEXPRESS',
        database: 'CRMVentas',
        driver: 'tedious',
        options: {
            trustServerCertificate: true,
            trustedConnection: true
        }
    };
    
    try {
        console.log('Conectando con driver tedious...');
        const pool = await sql.connect(config);
        console.log('✅ CONECTADO!');
        
        const result = await pool.request().query('SELECT SUSER_NAME() as usuario, DB_NAME() as bd');
        console.log('Usuario:', result.recordset[0].usuario);
        console.log('Base de datos:', result.recordset[0].bd);
        
        await sql.close();
    } catch (err) {
        console.error('Error:', err.message);
    }
}

test();