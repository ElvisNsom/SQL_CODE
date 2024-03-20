USE AfrikDB; -- Replace 'YourDatabaseName' with the name of your database

-- Get database size in MB and GB
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    SUM(size) * 8 / 1024 AS Size_MB,
    SUM(size) * 8 / 1024 / 1024 AS Size_GB
FROM 
    sys.master_files
WHERE 
    type_desc = 'ROWS'
GROUP BY 
    database_id;
