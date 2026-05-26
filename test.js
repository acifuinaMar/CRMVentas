// server-sql-auth.js
const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Configuración con usuario 'sa'
const config = {
    server: 'localhost\\SQLEXPRESS',
    database: 'CRMVentas',
    user: 'sa',
    password: 'Panchito1310!',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

sql.connect(config).then(() => {
    console.log('✅ Conectado a SQL Server con usuario sa');
}).catch(err => {
    console.error('❌ Error:', err.message);
});

app.listen(3000, () => console.log('Servidor en http://localhost:3000'));