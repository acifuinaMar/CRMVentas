/* ============================================================
   DATABASE MIRRORING - ALTA DISPONIBILIDAD
   Instancias:
   Principal: DESKTOP-MNIT0ES\SQL1
   Mirror:    DESKTOP-MNIT0ES\SQL2
   ============================================================ */

/* En SQL1 */
USE master;
GO

ALTER DATABASE CRMVentas SET RECOVERY FULL;
GO
ALTER DATABASE CRMVentas SET AUTO_CLOSE OFF;
GO

BACKUP DATABASE CRMVentas
TO DISK = 'C:\MirrorBackup\CRMVentas_SQL1.bak'
WITH INIT;
GO

BACKUP LOG CRMVentas
TO DISK = 'C:\MirrorBackup\CRMVentas_SQL1.trn'
WITH INIT;
GO

/* En SQL2 */
USE master;
GO

RESTORE DATABASE CRMVentas
FROM DISK = 'C:\MirrorBackup\CRMVentas_SQL1.bak'
WITH 
    MOVE 'CRMVentas' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2\MSSQL\DATA\CRMVentas.mdf',
    MOVE 'CRMVentas_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQL2\MSSQL\DATA\CRMVentas_log.ldf',
    NORECOVERY,
    REPLACE;
GO

RESTORE LOG CRMVentas
FROM DISK = 'C:\MirrorBackup\CRMVentas_SQL1.trn'
WITH NORECOVERY;
GO

/* Endpoint en SQL1 */
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'Endpoint_Mirroring')
BEGIN
    CREATE ENDPOINT Endpoint_Mirroring
    STATE = STARTED
    AS TCP (LISTENER_PORT = 7022)
    FOR DATABASE_MIRRORING (ROLE = PARTNER);
END;
GO

/* Endpoint en SQL2 */
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'Endpoint_Mirroring')
BEGIN
    CREATE ENDPOINT Endpoint_Mirroring
    STATE = STARTED
    AS TCP (LISTENER_PORT = 7023)
    FOR DATABASE_MIRRORING (ROLE = PARTNER);
END;
GO

/* Primero en SQL2 */
ALTER DATABASE CRMVentas
SET PARTNER = 'TCP://DESKTOP-MNIT0ES:7022';
GO

/* Luego en SQL1 */
ALTER DATABASE CRMVentas
SET PARTNER = 'TCP://DESKTOP-MNIT0ES:7023';
GO

/* Verificación */
SELECT 
    DB_NAME(database_id) AS BaseDatos,
    mirroring_role_desc,
    mirroring_state_desc,
    mirroring_partner_name,
    mirroring_safety_level_desc
FROM sys.database_mirroring
WHERE database_id = DB_ID('CRMVentas');
GO

/* Failover manual: para ejecutar desde la instancia principal al momento*/
-- ALTER DATABASE CRMVentas SET PARTNER FAILOVER;
-- GO
