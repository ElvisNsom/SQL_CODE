USE msdb;

SELECT 
    name AS JobName,
    CASE 
        WHEN enabled = 1 THEN 'Enabled'
        ELSE 'Disabled'
    END AS JobStatus
FROM 
    dbo.sysjobs
WHERE 
    enabled = 0;
