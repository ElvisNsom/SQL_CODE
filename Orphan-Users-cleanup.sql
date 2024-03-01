USE YourDatabaseName; -- Replace with the name of your database

-- Generate DROP USER statements for orphaned users
SELECT 
    'USE ' + QUOTENAME(DB_NAME()) + '; ' +
    'DROP USER ' + QUOTENAME(name) + ';' AS DropUserStatement
FROM 
    sys.database_principals dp
LEFT JOIN 
    sys.server_principals sp ON dp.sid = sp.sid
WHERE 
    dp.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP') AND
    sp.sid IS NULL;
