USE MSDB
SELECT bs.[database_name], cast(bs.[backup_size]/1024/1024 as decimal(38,2)) 
AS Backup_Size_MB, bs.[backup_finish_date], bs.[user_name], mf.device_type, mf.physical_device_name, bs.[type], ms.[software_name],
DATEDIFF(hour, bs.[backup_finish_date], GETDATE()) AS "Hours Since"
FROM dbo.backupset bs
JOIN dbo.backupmediaset ms ON bs.media_set_id = ms.media_set_id
JOIN dbo.backupmediafamily mf ON ms.media_set_id = mf.media_set_id
WHERE type = 'D' --AND database_name = ''
ORDER BY backup_finish_date DESC
