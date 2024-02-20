

----enable all sql server jobs

USE msdb;

DECLARE @JobName NVARCHAR(128);

DECLARE EnableJobs CURSOR FOR
SELECT name
FROM dbo.sysjobs;

OPEN EnableJobs;
FETCH NEXT FROM EnableJobs INTO @JobName;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_update_job 
        @job_name = @JobName,
        @enabled = 1; -- 1 means enabled

    FETCH NEXT FROM EnableJobs INTO @JobName;
END

CLOSE EnableJobs;
DEALLOCATE EnableJobs;


-------SQL query to enable SQL server Agent-----

USE master;

EXEC msdb.dbo.sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC msdb.dbo.sp_configure 'Agent XPs', 1;
RECONFIGURE;

