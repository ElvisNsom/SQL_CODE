

----disable all sqk server jobs----



USE msdb;

DECLARE @JobName NVARCHAR(128);

DECLARE DisableJobs CURSOR FOR
SELECT name
FROM dbo.sysjobs;

OPEN DisableJobs;
FETCH NEXT FROM DisableJobs INTO @JobName;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_update_job 
        @job_name = @JobName,
        @enabled = 0; -- 0 means disabled

    FETCH NEXT FROM DisableJobs INTO @JobName;
END

CLOSE DisableJobs;
DEALLOCATE DisableJobs;



--------Sql server query to Disable SQL server agent---

USE master;

EXEC msdb.dbo.sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC msdb.dbo.sp_configure 'Agent XPs', 0;
RECONFIGURE;
