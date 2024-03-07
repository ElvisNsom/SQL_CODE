-- Get count of all logins
SELECT COUNT(*) AS TotalLogins
FROM sys.server_principals
WHERE type IN ('S', 'U', 'G');


--------------------------------------------
----------------------------------------------

USE YourDatabaseName; -- Replace with the name of your database

SELECT 
    database_name AS DatabaseName,
    type AS BackupType,
    backup_start_date AS BackupStartDate,
    backup_finish_date AS BackupFinishDate,
    physical_device_name AS BackupLocation
FROM 
    msdb.dbo.backupset
WHERE 
    database_name = 'YourDatabaseName'
    AND type = 'D' -- D represents a full database backup
ORDER BY 
    backup_finish_date DESC;
