USE DemoDB; -- Replace with the name of your database

-- Find orphaned users
SELECT 
    dp.name AS DatabaseUserName,
    dp.sid AS DatabaseUserSID
FROM 
    sys.database_principals dp
LEFT JOIN 
    sys.server_principals sp ON dp.sid = sp.sid
WHERE 
    dp.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP') AND
    sp.sid IS NULL;
