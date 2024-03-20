USE AfrikDB; -- Replace 'YourDatabaseName' with the name of your database

-- Get total record count for the entire database
SELECT 
    SUM(p.rows) AS TotalRecords
FROM 
    sys.tables t
INNER JOIN 
    sys.partitions p ON t.object_id = p.object_id
WHERE 
    t.is_ms_shipped = 0
    AND index_id IN (0, 1);
