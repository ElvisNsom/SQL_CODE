USE AfrikDB; -- Replace 'YourDatabaseName' with the name of your database

-- Get total record count for each table
SELECT 
    t.name AS TableName,
    SUM(p.rows) AS TotalRecords
FROM 
    sys.tables t
INNER JOIN 
    sys.partitions p ON t.object_id = p.object_id
WHERE 
    t.is_ms_shipped = 0
    AND index_id IN (0, 1)
GROUP BY 
    t.name
ORDER BY 
    TotalRecords DESC;
