---CPU Utilization---

SELECT 
    cpu_count AS TotalCPUs,
    hyperthread_ratio AS HyperthreadRatio,
    cpu_count / hyperthread_ratio AS PhysicalCPUs,
    (100 - (cpu_idle / (cpu_busy + cpu_idle + 0.0) * 100)) AS CPUUtilizationPercentage
FROM 
    sys.dm_os_sys_info;
----------------------------------------------
---------------------------------------------


---Memory uasage----
SELECT 
    total_physical_memory_kb / 1024.0 AS TotalPhysicalMemory_GB,
    available_physical_memory_kb / 1024.0 AS AvailablePhysicalMemory_GB,
    total_page_file_kb / 1024.0 AS TotalPageFile_GB,
    available_page_file_kb / 1024.0 AS AvailablePageFile_GB
FROM 
    sys.dm_os_sys_memory;

	-------------------------------------------------------------
	--------------------------------------------------------

	------Database File Sizes and Space Used-------

	SELECT 
    DB_NAME(database_id) AS DatabaseName,
    type_desc AS FileType,
    name AS FileName,
    size/128.0 AS TotalSize_MB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') AS float)/128.0 AS UsedSpace_MB,
    (size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS float))/128.0 AS FreeSpace_MB
FROM 
    sys.master_files;

-------TempDB Space Usage:-----
	USE tempdb;
GO

EXEC sp_spaceused;
---------------------------------------------------------
-------------------------------------------------------

-----------------------Longest Running Queries:------------------------------

SELECT TOP 10
    qs.creation_time AS StartTime,
    qs.execution_count AS ExecutionCount,
    qs.total_worker_time AS TotalWorkerTime,
    qs.total_elapsed_time AS TotalElapsedTime,
    qs.total_logical_reads AS TotalLogicalReads,
    qs.total_logical_writes AS TotalLogicalWrites,
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1, 
            ((CASE qs.statement_end_offset 
                WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS SQLText
FROM 
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY 
    qs.total_elapsed_time DESC;


