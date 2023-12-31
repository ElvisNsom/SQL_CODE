
 /* ****************************************** STEPS TO RUN **************************************************** 
 #	- Determine the name of the specific database you wish to look at if relevant
 #
 #	- Configure all relevant variable in the "CONFIGURATION" sections below
 #		- If you are looking for very deep information, consider options under the "ADVANCED CONFIGURATION" section
 #
 #	- Use the Ctrl + T option prior to running. Output for this script is optimized for "Results to Text"
 #
 # ************************************************************************************************************* */
															     
 
/* ***************************************** GLOBAL VARIABLES ************************************************** */
DECLARE @DB sysname, @infoGEN VARCHAR(5), @WAITSTATS VARCHAR(5), @waitsCLEAR VARCHAR(5), @infoBAK VARCHAR(5), @infoIO VARCHAR(5), @infoCPU VARCHAR(5), @infoMEM VARCHAR(5), @infoJOBS VARCHAR(5), @infoSEC VARCHAR(5), @infoFRAG VARCHAR(5), @infoSTAT VARCHAR(5), @infoQUERY VARCHAR(5), @Inventory VARCHAR(5), @Version as VARCHAR(128), @VersionMajor DECIMAL(10,2), @VersionMinor DECIMAL(10,2), @BufferSpecific VARCHAR(5)

/* ******************************************* CONFIGURATION *************************************************** */

SET @DB   		= null;				-- Name of database to review

SET @Inventory	= 'TRUE';				-- TRUE / FALSE

SET @infoGEN 	= 'TRUE';				-- TRUE / FALSE
	
SET @WAITSTATS	= 'TRUE';				-- TRUE / FALSE   
	SET @waitsCLEAR = 'FALSE';      		-- TRUE / FALSE: Set to TRUE if you want to clear stored wait info. Will wait 10 seconds after clear before running waits.

SET @infoBAK 	= 'TRUE';				-- TRUE / FALSE

SET @infoIO  	= 'TRUE';				-- TRUE / FALSE

SET @infoCPU 	= 'TRUE';				-- TRUE / FALSE

SET @infoMEM 	= 'TRUE';				-- TRUE / FALSE

SET @infoQUERY	= 'TRUE';				-- TRUE / FALSE

SET @infoJOBS 	= 'TRUE';				-- TRUE / FALSE

SET @infoSEC 	= 'TRUE';				-- TRUE / FALSE

SET @infoFRAG 	= 'TRUE';				-- TRUE / FALSE: May take awhile to run

SET @infoSTAT 	= 'TRUE';				-- TRUE / FALSE

SET @Version 	= CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(128));  	

/* ************************************ CONFIGURATION EXPLANATIONS ********************************************* */

/* 
@Inventory provides the following information:
		@infoGEN
		@infoHIST
		@infoFRAG
		@infoSTAT
	This section is designed to replace the existing SQL Inventory Script

@infoGEN provides the following information:
		Machine Name, Instance Name, Edition, Product Version
		Recovery Model, Log size, Log utilization, Compatibility Mode
		Current Connections
		All enabled traceflags
		Windows OS information
		SQL Services information
		SQL NUMA information
		Hardware basics
		Model/manufacturer of server
		Processor description
		File names and paths
		Last DBCC CHECKDB
		
 @WAITSTATS
		Grabs wait stats as seen by MSSQL
		Full list of all wait stat values can be found at
	
		
 @infoBAK provides the following information:
		Last MSSQL backup for database @DB [***NOTE***: if customer is using different software to backup the database, this will not be correct]
		Last 5 transaction log backups for @DB
		Backup throughput speed
		Backup history for database file growth
		Compression factor (if being used for backups)
		
 @infoIO provides the following information:
		Volume info for all LUNS that have DB files on the current instance
		I/O Utilization by database
		Average stalls (I/O bottlenecks)
		Missing indexes identifier (Do NOT add indexes based on these recommendations. Conduct additional investigation if an index is warranted.)
		Autogrowth events
		VLF Counts

 @infoCPU provides the following information:
		CPU utilization for MSSQL in last 256 minutes
		Signal waits
		CPU utilization by database

 @infoMEM provides the following information:
		Page life expectancy (PLE)
		Memory grants outstanding
		Total buffer usage by database
		OS memory

 @infoQUERY provides the following information:
		Top 10 Query information by CPU time
			Stats on the queries
			 
 @infoJOBS provides the following information:
		failed jobs
		jobs currently running 

 @infoSEC provides the following information:
		Who has SYSADMIN role?
		Who has SecADMIN role?

 @infoFRAG provides the following information:
		Fragmentation Levels across @DB

 @infoSTAT provides the following information:
		Date statistics were last updated across @DB
		Most volatile indexes based on modification counts for @DB
*/

/* *************************************** Advanced Config *********************************************** */
/* ********************* Leave default if you do not know what a variable is for ************************* */

	-- Under @infoMEM
	SET @BufferSpecific = 'TRUE';			-- TRUE / FALSE: Set to TRUE if you need more specific information on the exact objects in buffer. (Specific to @DB)
	
/* ************************************ ADV CONFIGURATION EXPLANATIONS *********************************** */
/*

@BufferSpecific provides the following information:
	Using @DB, this section will allow you to see the name of the objects in buffer pool and how many pages from that object are in memory.

*/

/* ************************************ Variables for Queries *********************************** */
/*
Variables in here are required for use by specific operations throughout the script.
*/

DECLARE @v_query_text nvarchar(max), @v_execution_count bigint, @v_total_logical_reads bigint, @v_last_logical_reads bigint, @v_total_worker_time bigint, @v_last_worker_time bigint, @v_total_elapsed_time bigint, @v_last_elapsed_time bigint, @v_last_execution_time datetime;

/* ************************************ And so it begins...  ********************************************* */

/* ************************************ Limitations Check  *********************************************** */

SET @VersionMajor = SUBSTRING(@Version, 1,CHARINDEX('.', @Version) + 1 )
SET @VersionMinor = PARSENAME(CONVERT(varchar(32), @Version), 2)

IF @VersionMajor IN ('8.00', '9.00', '10.00') BEGIN

	PRINT 'We have detected you are on a version of MSSQL that is not support by this script. Script requires MSSQL 2008R2 SP2 or newer editions.'
	RAISERROR ('WARNING:  Version of SQL Server is not compatible with this script.', 20, 1) WITH LOG;
END

IF @VersionMajor = '10.50' AND @VersionMinor > '3999' BEGIN

	PRINT 'We have detected you are on a version of MSSQL that is not support by this script. Script requires MSSQL 2008R2 SP2 or newer editions.'
	RAISERROR ('WARNING:  Version of SQL Server is not compatible with this script.', 20, 1) WITH LOG;
END

/* ************************************ Start the core script ********************************************* */

PRINT CHAR(13)
PRINT 'Database Performance Data'
PRINT CHAR(13) + + CHAR(13);
PRINT '########## Date Run #############'
PRINT 'Date Ran : ' + CONVERT(CHAR(19),GETDATE(), 100)


IF @infoGEN = 'TRUE' or @Inventory = 'TRUE' BEGIN
	
	-- Get selected server properties 
	PRINT '########## Selected Server Properties #############'
	SELECT RTRIM(CAST (SERVERPROPERTY('MachineName') AS VARCHAR)) AS [MachineName], 
		RTRIM(CAST (SERVERPROPERTY('ServerName')AS VARCHAR(50))) AS [ServerName],  
		RTRIM(CAST (SERVERPROPERTY('InstanceName')AS VARCHAR)) AS [Instance], 
		RTRIM(CAST (SERVERPROPERTY('IsClustered')AS VARCHAR)) AS [IsClustered], 
		RTRIM(CAST (SERVERPROPERTY('ComputerNamePhysicalNetBIOS')AS VARCHAR)) AS [ComputerNamePhysicalNetBIOS], 
		RTRIM(CAST (SERVERPROPERTY('Edition')AS VARCHAR)) AS [Edition], 
		RTRIM(CAST (SERVERPROPERTY('ProductLevel')AS VARCHAR)) AS [ProductLevel], 
		RTRIM(CAST (SERVERPROPERTY('ProductVersion')AS VARCHAR)) AS [ProductVersion], 
		RTRIM(CAST (SERVERPROPERTY('ProcessID')AS VARCHAR)) AS [ProcessID],
		RTRIM(CAST (SERVERPROPERTY('IsHadrEnabled')AS VARCHAR)) AS [IsHadrEnabled], 
		RTRIM(CAST (SERVERPROPERTY('HadrManagerStatus')AS VARCHAR)) AS [HadrManagerStatus]

	-- Get System Configurations
	PRINT '########## System Configurations #############'
	SELECT NAME, VALUE_IN_USE
		FROM SYS.CONFIGURATIONS 
	ORDER BY NAME
		
	IF @VersionMajor IN ('13.0')
	BEGIN
	
	PRINT '########## Scoped Configuration for Database Level Parameters #############'
	EXEC('
	SELECT * FROM SYS.DATABASE_SCOPED_CONFIGURATIONS
	')
	END
	
	-- Recovery model, log reuse wait description, log file size, log usage size  
	-- and compatibility level for all databases on instance
	
	IF @VersionMajor = '10.50'
	BEGIN
	
	PRINT '########## Recovery Model, Log Size/Usage, Compatibility Level, Database Settings #############'
	EXEC('
	SELECT RTRIM(CAST (db.[name] AS VARCHAR)) AS [Database Name], 
		RTRIM(CAST (db.recovery_model_desc AS VARCHAR)) AS [Recovery Model], 
		RTRIM(CAST (db.state_desc AS VARCHAR)) AS [State Desc], 
		RTRIM(CAST (db.log_reuse_wait_desc AS VARCHAR)) AS [Log Reuse Wait Description], 
		RTRIM(CAST (CONVERT(DECIMAL(18,2), ls.cntr_value/1024.0) AS VARCHAR)) AS [Log Size (MB)], 
		RTRIM(CAST (CONVERT(DECIMAL(18,2), lu.cntr_value/1024.0) AS VARCHAR)) AS [Log Used (MB)],
		RTRIM(CAST (CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS VARCHAR)) AS [Log Used %], 
		RTRIM(CAST (db.[compatibility_level] AS VARCHAR)) AS [DB Compatibility Level], 
		RTRIM(CAST (db.page_verify_option_desc AS VARCHAR)) AS [Page Verify Option], 
		RTRIM(CAST (db.is_auto_create_stats_on AS VARCHAR)) AS [Auto Create Stats On], 
		RTRIM(CAST (db.is_auto_update_stats_on AS VARCHAR)) AS [Auto Update Stats On],
		RTRIM(CAST (db.is_auto_update_stats_async_on AS VARCHAR)) AS [Auto Update Stats Async On], 
		RTRIM(CAST (db.is_parameterization_forced AS VARCHAR)) AS [Forced Parameterization], 
		RTRIM(CAST (db.snapshot_isolation_state_desc AS VARCHAR)) AS [Snapshot Isolation Level], 
		RTRIM(CAST (db.is_read_committed_snapshot_on AS VARCHAR)) AS [Read Committed Snapshot],
		RTRIM(CAST (db.is_auto_close_on AS VARCHAR)) AS [Auto Close On], 
		RTRIM(CAST (db.is_auto_shrink_on AS VARCHAR)) AS [Auto Shrink On], 
		RTRIM(CAST (db.is_cdc_enabled AS VARCHAR)) AS [CDC Enabled]
	FROM sys.databases AS db WITH (NOLOCK)
		INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
		ON db.name = lu.instance_name
		INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
		ON db.name = ls.instance_name
	WHERE lu.counter_name LIKE N''Log File(s) Used Size (KB)%'' 
		AND ls.counter_name LIKE N''Log File(s) Size (KB)%''
		AND ls.cntr_value > 0 OPTION (RECOMPILE);
	')
	END
	
	IF @VersionMajor IN ('11.00', '12.00', '13.0')
	BEGIN
	
	PRINT '########## Recovery Model, Log Size/Usage, Compatibility Level, Database Settings #############'
	EXEC ('
	SELECT RTRIM(CAST (db.[name] AS VARCHAR)) AS [Database Name], 
		RTRIM(CAST (db.recovery_model_desc AS VARCHAR)) AS [Recovery Model], 
		RTRIM(CAST (db.state_desc AS VARCHAR)) AS [State Desc], 
		RTRIM(CAST (db.log_reuse_wait_desc AS VARCHAR)) AS [Log Reuse Wait Description], 
		RTRIM(CAST (CONVERT(DECIMAL(18,2), ls.cntr_value/1024.0) AS VARCHAR)) AS [Log Size (MB)], 
		RTRIM(CAST (CONVERT(DECIMAL(18,2), lu.cntr_value/1024.0) AS VARCHAR)) AS [Log Used (MB)],
		RTRIM(CAST (CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS VARCHAR)) AS [Log Used %], 
		RTRIM(CAST (db.[compatibility_level] AS VARCHAR)) AS [DB Compatibility Level], 
		RTRIM(CAST (db.page_verify_option_desc AS VARCHAR)) AS [Page Verify Option], 
		RTRIM(CAST (db.is_auto_create_stats_on AS VARCHAR)) AS [Auto Create Stats On], 
		RTRIM(CAST (db.is_auto_update_stats_on AS VARCHAR)) AS [Auto Update Stats On],
		RTRIM(CAST (db.is_auto_update_stats_async_on AS VARCHAR)) AS [Auto Update Stats Async On], 
		RTRIM(CAST (db.is_parameterization_forced AS VARCHAR)) AS [Forced Parameterization], 
		RTRIM(CAST (db.snapshot_isolation_state_desc AS VARCHAR)) AS [Snapshot Isolation Level], 
		RTRIM(CAST (db.is_read_committed_snapshot_on AS VARCHAR)) AS [Read Committed Snapshot],
		RTRIM(CAST (db.is_auto_close_on AS VARCHAR)) AS [Auto Close On], 
		RTRIM(CAST (db.is_auto_shrink_on AS VARCHAR)) AS [Auto Shrink On], 
		RTRIM(CAST (db.target_recovery_time_in_seconds AS VARCHAR)) AS [Target Recovery Time(s)], 
		RTRIM(CAST (db.is_cdc_enabled AS VARCHAR)) AS [CDC Enabled]
	FROM sys.databases AS db WITH (NOLOCK)
		INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
		ON db.name = lu.instance_name
		INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
		ON db.name = ls.instance_name
	WHERE lu.counter_name LIKE N''Log File(s) Used Size (KB)%'' 
		AND ls.counter_name LIKE N''Log File(s) Size (KB)%''
		AND ls.cntr_value > 0 OPTION (RECOMPILE);
	')
	
	END

	--  Get logins that are connected and how many sessions they have
	PRINT '########## Connection Information #############'
	SELECT RTRIM(CAST (login_name AS VARCHAR(50))) AS [Login Name], 
		RTRIM(CAST ([program_name] AS VARCHAR(80))) AS [Program Name], 
		COUNT(session_id) AS [session_count] 
	FROM sys.dm_exec_sessions WITH (NOLOCK)
		GROUP BY login_name, [program_name]
		ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

	-- Returns a list of all global trace flags that are enabled 
	PRINT '########## Global Trace Flags #############'
	DBCC TRACESTATUS (-1)
	
	-- Windows information 
	PRINT '########## Windows Information #############'
	EXEC ('
	SELECT RTRIM(CAST (windows_release AS VARCHAR)) AS [Windows Release], 
		RTRIM(CAST (windows_service_pack_level AS VARCHAR)) AS [Service Pack Level], 
        RTRIM(CAST (windows_sku AS VARCHAR)) AS [Windows SKU], 
		RTRIM(CAST (os_language_version AS VARCHAR)) AS [Windows Language]
	FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);
	')

	-- Gives you major OS version, Service Pack, Edition, and language info for the operating system 
	-- 6.3 is either Windows 8.1 or Windows Server 2012 R2
	-- 6.2 is either Windows 8 or Windows Server 2012
	-- 6.1 is either Windows 7 or Windows Server 2008 R2
	-- 6.0 is either Windows Vista or Windows Server 2008

	-- Windows SKU codes
	-- 4  is Enterprise Edition
	-- 48 is Professional Edition

	-- 1033 for os_language_version is US-English
	
	-- SQL Server Services information 
	PRINT '########## SQL Services Information #############'
	EXEC ('
	SELECT RTRIM(CAST (servicename AS VARCHAR(50))) AS [Service Name], 
		RTRIM(CAST (process_id AS VARCHAR)) AS [Process ID],
		RTRIM(CAST (startup_type_desc AS VARCHAR)) AS [Startup Type], 
		RTRIM(CAST (status_desc AS VARCHAR)) AS [Status Description], 
		RTRIM(CAST (last_startup_time AS VARCHAR(50))) AS [Last Startup Time], 
		RTRIM(CAST (service_account AS VARCHAR(50))) AS [Service Account], 
		RTRIM(CAST (is_clustered AS VARCHAR)) AS [Is Clustered], 
		RTRIM(CAST (cluster_nodename AS VARCHAR)) AS [Cluster Node Name], 
		RTRIM(CAST ([filename] AS VARCHAR(172))) AS [Filename]
	FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);
	')

	-- SQL Server NUMA Node information  
	PRINT '########## SQL Numa Information #############'
	SELECT RTRIM(CAST (node_id AS VARCHAR)) AS [Node ID], 
		RTRIM(CAST (node_state_desc AS VARCHAR)) AS [Node State Desc], 
		RTRIM(CAST (memory_node_id AS VARCHAR)) AS [Memory Node ID], 
		RTRIM(CAST (processor_group AS VARCHAR)) AS [Processor Group], 
		RTRIM(CAST (online_scheduler_count AS VARCHAR)) AS [(Online Schedulers], 
        RTRIM(CAST (active_worker_count AS VARCHAR)) AS [Active Workers], 
		RTRIM(CAST (avg_load_balance AS VARCHAR)) AS [Average Load Balance], 
		RTRIM(CAST (resource_monitor_state AS VARCHAR)) AS [Resource Monitor Stats]
	FROM sys.dm_os_nodes WITH (NOLOCK) 
	WHERE node_state_desc <> N'ONLINE DAC' OPTION (RECOMPILE);
	
	IF @VersionMajor = '10.50'
	BEGIN
	
	-- Hardware information from SQL Server 2008 
	-- (Cannot distinguish between HT and multi-core)
	PRINT '########## Hardware Information #############'
	EXEC ('
	SELECT RTRIM(CAST (cpu_count AS VARCHAR)) AS [Logical CPU Count], 
		RTRIM(CAST (scheduler_count AS VARCHAR)) AS [Scheduler Count], 
		RTRIM(CAST (hyperthread_ratio AS VARCHAR)) AS [Hyperthread Ratio],
		RTRIM(CAST (cpu_count/hyperthread_ratio AS VARCHAR)) AS [Physical CPU Count], 
		RTRIM(CAST (physical_memory_in_bytes/1024/1024 AS VARCHAR)) AS [Physical Memory (MB)], 
		RTRIM(CAST (max_workers_count AS VARCHAR)) AS [Max Workers Count], 
		RTRIM(CAST (affinity_type_desc AS VARCHAR)) AS [Affinity Type], 
		RTRIM(CAST (sqlserver_start_time AS VARCHAR)) AS [SQL Server Start Time], 
		RTRIM(CAST (virtual_machine_type_desc AS VARCHAR)) AS [Virtual Machine Type]  
	FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
	')
	
	END
	
	IF @VersionMajor IN ('11.00', '12.00', '13.0')
	BEGIN
	
	-- Hardware information from SQL Server 2012, 2014, and 2016 
	-- (Cannot distinguish between HT and multi-core)
	PRINT '########## Hardware Information #############'
	EXEC ('
	SELECT RTRIM(CAST (cpu_count AS VARCHAR)) AS [Logical CPU Count], 
		RTRIM(CAST (scheduler_count AS VARCHAR)) AS [Scheduler Count], 
		RTRIM(CAST (hyperthread_ratio AS VARCHAR)) AS [Hyperthread Ratio],
		RTRIM(CAST (cpu_count/hyperthread_ratio AS VARCHAR)) AS [Physical CPU Count], 
		RTRIM(CAST (physical_memory_kb/1024 AS VARCHAR)) AS [Physical Memory (MB)], 
		RTRIM(CAST (max_workers_count AS VARCHAR)) AS [Max Workers Count], 
		RTRIM(CAST (affinity_type_desc AS VARCHAR)) AS [Affinity Type], 
		RTRIM(CAST (sqlserver_start_time AS VARCHAR)) AS [SQL Server Start Time], 
		RTRIM(CAST (virtual_machine_type_desc AS VARCHAR)) AS [Virtual Machine Type]  
	FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
	')
	
	END

	-- Get System Manufacturer and model number from
	PRINT '########## Manufacturer Information #############'
	EXEC  xp_readerrorlog 0, 1, N'Manufacturer'; 

	-- Get processor description from Windows Registry 
	PRINT '########## Processor Description #############'
	EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\CentralProcessor\0', N'ProcessorNameString';
	
	-- File names and paths for TempDB and all user databases in instance 
	PRINT '########## File Names and Paths #############'
	SELECT RTRIM(CAST (DB_NAME([database_id]) AS VARCHAR)) AS [Database Name], 
       RTRIM(CAST ([file_id] AS VARCHAR)) AS [File ID], 
	   RTRIM(CAST (name AS VARCHAR)) AS [Name], 
	   RTRIM(CAST (physical_name AS VARCHAR(172))) AS [Physical Name], 
	   RTRIM(CAST (type_desc AS VARCHAR)) AS [Type Desc], 
	   RTRIM(CAST (state_desc AS VARCHAR)) AS [State Desc],
	   RTRIM(CAST (is_percent_growth AS VARCHAR)) AS [Is Percent Growth], 
	   RTRIM(CAST (growth AS VARCHAR)) AS [Growth],
	   RTRIM(CAST (CONVERT(bigint, growth/128.0) AS VARCHAR)) AS [Growth in MB], 
       RTRIM(CAST (CONVERT(bigint, size/128.0) AS VARCHAR)) AS [Total Size in MB]
	FROM sys.master_files WITH (NOLOCK)
	WHERE [database_id] > 4 
	AND [database_id] <> 32767
	OR [database_id] = 2
	ORDER BY DB_NAME([database_id]) OPTION (RECOMPILE);
	
	-- Last DBCC CheckDB execution
	PRINT '########## Last CheckDB Run #############'
	CREATE TABLE #temp
		(
		  ParentObject VARCHAR(255) ,
		  [Object] VARCHAR(255) ,
		  Field VARCHAR(255) ,
		  [Value] VARCHAR(255)
		)   
	 
	CREATE TABLE #DBCCResults
		(
		  ServerName VARCHAR(255) ,
		  DBName VARCHAR(255) ,
		  LastCleanDBCCDate DATETIME
		)   
	 
	EXEC master.dbo.sp_MSforeachdb @command1 = 'USE [?]; INSERT INTO #temp EXECUTE (''DBCC DBINFO WITH TABLERESULTS'')',
		@command2 = 'INSERT INTO #DBCCResults SELECT @@SERVERNAME, ''?'', Value FROM #temp WHERE Field = ''dbi_dbccLastKnownGood''',
		@command3 = 'TRUNCATE TABLE #temp'   
	    --Delete duplicates due to a bug in SQL Server 2008
		;
	WITH    DBCC_CTE
			  AS ( SELECT   ROW_NUMBER() OVER ( PARTITION BY ServerName, DBName,
												LastCleanDBCCDate ORDER BY LastCleanDBCCDate ) RowID
				   FROM     #DBCCResults
				 )
		DELETE  FROM DBCC_CTE
		WHERE   RowID > 1 ;
	 
	SELECT  RTRIM(CAST (ServerName AS VARCHAR)) AS [Server Name] ,
			RTRIM(CAST (DBName AS VARCHAR)) AS [Database Name] ,
			CASE LastCleanDBCCDate
			  WHEN '1900-01-01 00:00:00.000' THEN 'Never ran DBCC CHECKDB'
			  ELSE CAST(LastCleanDBCCDate AS VARCHAR)
			END AS LastCleanDBCCDate
	FROM    #DBCCResults
	WHERE DBName = @DB
	ORDER BY 3
	 
	DROP TABLE #temp, #DBCCResults;
	
/* 	--Show Max DOP
	EXEC sp_configure 'Show Advanced Options', 1;
	GO
	RECONFIGURE WITH OVERRIDE;
	GO
	EXEC sp_configure;
	GO */

END

IF @WAITSTATS = 'TRUE' BEGIN

	IF @waitsCLEAR = 'TRUE' BEGIN
	-- Clear current wait stats
	PRINT '########## Wait Stats Clear #############'
	DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
	
	WAITFOR DELAY '00:00:10'
	
	END
	
	-- Clear Wait Stats 
	-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

	-- Isolate top waits for server instance since last restart or statistics clear 
	
	IF @VersionMajor = '10.50'
	BEGIN
	
	-- Version of WAIT_STATS that supports 2008 R2 SP2
	PRINT '########## Wait Stats 2008 #############';
	WITH [Waits] 
		AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],
          (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
           signal_wait_time_ms / 1000.0 AS [SignalS],
           waiting_tasks_count AS [WaitCount],
           100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],
           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]
	FROM sys.dm_os_wait_stats WITH (NOLOCK)
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 
		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
    AND waiting_tasks_count > 0)
	SELECT
		MAX (W1.wait_type) AS [WaitType],
		CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],
		CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],
		CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],
		MAX (W1.WaitCount) AS [Wait Count],
		CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],
		CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],
		CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],
		CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec]
	FROM Waits AS W1
		INNER JOIN Waits AS W2
		ON W2.RowNum <= W1.RowNum
	GROUP BY W1.RowNum
		HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold
	OPTION (RECOMPILE);
	
	END
	
	IF @VersionMajor IN ('11.00', '12.00')
	BEGIN
	
	-- Wait Stats Data
	PRINT '########## Wait Stats 2012/2014 #############';
	WITH [Waits] 
	AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],
          (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
           signal_wait_time_ms / 1000.0 AS [SignalS],
           waiting_tasks_count AS [WaitCount],
           100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],
           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats WITH (NOLOCK)
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 
		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT', N'PREEMPTIVE_HADR_LEASE_MECHANISM', N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS')
    AND waiting_tasks_count > 0)
	SELECT
		MAX (W1.wait_type) AS [WaitType],
		CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],
		CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],
		CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],
		MAX (W1.WaitCount) AS [Wait Count],
		CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],
		CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],
		CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],
		CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec]
	FROM Waits AS W1
		INNER JOIN Waits AS W2
		ON W2.RowNum <= W1.RowNum
	GROUP BY W1.RowNum
		HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold
	OPTION (RECOMPILE);
	
	END
	
	IF @VersionMajor IN ('13.0')
	BEGIN
	
	-- Wait Stats Data
	PRINT '########## Wait Stats 2016 #############';
	-- Last updated November 27, 2017
	WITH [Waits] AS
		(SELECT
			[wait_type],
			[wait_time_ms] / 1000.0 AS [WaitS],
			([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
			[signal_wait_time_ms] / 1000.0 AS [SignalS],
			[waiting_tasks_count] AS [WaitCount],
			100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
			ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM sys.dm_os_wait_stats
		WHERE [wait_type] NOT IN (
			-- These wait types are almost 100% never a problem and so they are
			-- filtered out to avoid them skewing the results. Click on the URL
			-- for more information.
			N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
			N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
			N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
			N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
			N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
			N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
			N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
			N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
			N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
			N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
	 
			-- Maybe comment these four out if you have mirroring issues
			N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
			N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
			N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
			N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
	 
			N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
			N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
			N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
			N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
			N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
			N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
	 
			-- Maybe comment these six out if you have AG issues
			N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
			N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
			N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
			N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
			N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
			N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
	 
			N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
			N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
			N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
			N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
			N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
			N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
			N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
			N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
			N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
				-- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
			N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
			N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
			N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
			N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
			N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
			N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
			N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
			N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
			N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
			N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
			N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
			N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
			N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
			N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
			N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
			N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
			N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
			N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
			N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
			N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
			N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
			N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
			N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
			N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
			N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
			N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
			N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
			N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
			N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
			)
		AND [waiting_tasks_count] > 0
		)
	SELECT
		MAX ([W1].[wait_type]) AS [WaitType],
		CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
		CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
		CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
		MAX ([W1].[WaitCount]) AS [WaitCount],
		CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
		CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
		CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
		CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
		CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
	FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
	GROUP BY [W1].[RowNum]
	HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
	
	END

END

IF @infoBAK = 'TRUE' BEGIN

	/* Last backup
			
	If physical_device_name is local to the server, make recommendation to move it to a network share.  This would provide several things:
		1.	Get the data off the server faster
		2.	Restore to dev/QA faster
		3.	Faster writes to tape
		
	Information taken from http://www.brentozar.com/archive/2008/09/back-up-your-database-to-the-network-not-local-disk/
	*/	
	PRINT '########## Last Backup #############';
	WITH full_backups AS
	(
	SELECT
		ROW_NUMBER() OVER(PARTITION BY database_name ORDER BY database_name ASC, backup_finish_date DESC) AS [Row Number]
		, database_name
		, backup_set_id
		, backup_finish_date
	FROM msdb.dbo.[backupset]
	WHERE [type] = 'D'
	)
	 
	SELECT
		RTRIM(CAST (BS.server_name AS VARCHAR)) AS [Server Name], 
		RTRIM(CAST (BS.database_name AS VARCHAR)) AS [Database Name],
		RTRIM(CAST (FB.backup_finish_date AS VARCHAR)) AS [Backup Date], 
		RTRIM(CAST (BMF.physical_device_name AS VARCHAR(100))) AS [Physical Device Name], 
		RTRIM(CAST (BMF.logical_device_name AS VARCHAR)) AS [Logical Device Name]
	FROM full_backups FB
		INNER JOIN msdb.dbo.[backupset] BS ON FB.backup_set_id = BS.backup_set_id
		INNER JOIN msdb.dbo.backupmediafamily BMF ON BS.media_set_id = BMF.media_set_id
	WHERE FB.[Row Number] = 1
	AND BS.database_name = @DB 
	ORDER BY FB.database_name;

	/* Transaction log backup

	If physical_device_name is local to the server, make recommendation to move it to a network share.  This would provide several things:
		1.	Get the data off the server faster
		2.	Restore to dev/QA faster
		3.	Faster writes to tape
		
	Information taken from http://www.brentozar.com/archive/2008/09/back-up-your-database-to-the-network-not-local-disk/
	*/	
	PRINT '########## Transaction Log Backup #############';
	WITH log_backups AS
	(
	SELECT
		ROW_NUMBER() OVER(PARTITION BY database_name ORDER BY database_name ASC, backup_finish_date DESC) AS [Row Number]
		, database_name
		, backup_set_id
		, backup_finish_date
	FROM msdb.dbo.[backupset]
	WHERE [type] = 'L'
	)
	 
	SELECT TOP 5
		RTRIM(CAST (BS.server_name AS VARCHAR)) AS [Server Name], 
		RTRIM(CAST (BS.database_name AS VARCHAR)) AS [Database Name],
		RTRIM(CAST (FB.backup_finish_date AS VARCHAR)) AS [Backup Date], 
		RTRIM(CAST (BMF.physical_device_name AS VARCHAR(100))) AS [Physical Device Name], 
		RTRIM(CAST (BMF.logical_device_name AS VARCHAR)) AS [Logical Device Name]
	FROM log_backups FB
	 INNER JOIN msdb.dbo.[backupset] BS ON FB.backup_set_id = BS.backup_set_id
	 INNER JOIN msdb.dbo.backupmediafamily BMF ON BS.media_set_id = BMF.media_set_id
	WHERE BS.database_name = @DB
	ORDER BY bs.database_name, FB.backup_finish_date DESC;

	-- If throughput changes, ask the SAN team what changed.  
	PRINT '########## Backup Throughput #############'
	SELECT  RTRIM(CAST (@@SERVERNAME AS VARCHAR(50))) AS [Server Name] ,
			YEAR(backup_finish_date) AS backup_year ,
			MONTH(backup_finish_date) AS backup_month ,
			CAST(AVG(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
												bset.backup_finish_date) )
					   / 1048576 )) AS INT) AS throughput_MB_sec_avg ,
			CAST(MIN(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
												bset.backup_finish_date) )
					   / 1048576 )) AS INT) AS throughput_MB_sec_min ,
			CAST(MAX(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
												bset.backup_finish_date) )
					   / 1048576 )) AS INT) AS throughput_MB_sec_max
	FROM    msdb.dbo.backupset bset
	WHERE   bset.type = 'D' -- full backups only 
			AND bset.backup_size > 5368709120 -- 5GB or larger 
			AND DATEDIFF(ss, bset.backup_start_date, bset.backup_finish_date) > 1 -- backups lasting over a second
	GROUP BY YEAR(backup_finish_date) ,
			MONTH(backup_finish_date)
	ORDER BY @@SERVERNAME ,
			YEAR(backup_finish_date) DESC ,
			MONTH(backup_finish_date) DESC
		 	
	-- Use Backup History to Examine Database File Growth 
	PRINT '########## Database file Growth #############';
	SELECT 
		RTRIM(CAST (BS.database_name AS VARCHAR)) AS [Database Name]
		,RTRIM(CAST(BF.file_size/1024/1024 AS bigint)) AS file_size_mb
		,RTRIM(CAST(BF.backup_size/1024/1024 AS bigint)) AS consumed_size_mb
		,RTRIM(CAST (BF.logical_name AS VARCHAR(50))) AS [Logical Name]
		,RTRIM(CAST (BF.physical_name AS VARCHAR(80))) AS [Physical Name]
		,RTRIM(CAST (BS.backup_finish_date AS VARCHAR)) AS polling_date
	FROM msdb.dbo.backupset BS
		INNER JOIN msdb.dbo.backupfile BF ON BS.backup_set_id = BF.backup_set_id
	WHERE  BS.type = 'D'
	AND BS.database_name = @DB
	ORDER BY BS.database_name
		, BS.backup_finish_date DESC
		, BF.logical_name;

	-- Determine Compression Factor for Individual Databases 
	PRINT '########## Compression Ratios #############';
	WITH full_backups AS
	(
	SELECT
		ROW_NUMBER() OVER(PARTITION BY BS.database_name ORDER BY BS.database_name ASC, BS.backup_finish_date DESC) AS [Row Number]
		, BS.database_name
		, BS.backup_set_id
		, BS.backup_size AS uncompressed_size
		, BS.backup_finish_date
	FROM msdb.dbo.[backupset] BS
	WHERE BS.[type] = 'D'
	)
	 
	SELECT
		RTRIM(CAST (FB.database_name AS VARCHAR)) AS [Database Name]
		, RTRIM(CAST (FB.backup_finish_date AS VARCHAR)) AS [Backup Finish Date]
		, RTRIM(CAST (FB.uncompressed_size AS VARCHAR)) AS [Uncompressed Size]
	FROM full_backups FB
	 INNER JOIN msdb.dbo.[backupset] BS ON FB.backup_set_id = BS.backup_set_id
	 INNER JOIN msdb.dbo.backupmediafamily BMF ON BS.media_set_id = BMF.media_set_id
	WHERE FB.[Row Number] = 1
	AND BS.database_name = @DB
	ORDER BY FB.database_name;
	
END

IF @infoIO = 'TRUE' BEGIN
	-- Volume info for all LUNS that have database files on the current instance 
	PRINT '########## Volume Information for LUNs with DB files #############';
	EXEC ('
	SELECT DISTINCT RTRIM( CAST(vs.volume_mount_point AS VARCHAR)) AS [Volume Mount Point], 
		RTRIM( CAST(vs.file_system_type AS VARCHAR)) AS [FS Type], 
		RTRIM( CAST(vs.logical_volume_name AS VARCHAR)) AS [Logical Volume Name], 
		CONVERT(DECIMAL(18,2),vs.total_bytes/1073741824.0) AS [Total Size (GB)],
		CONVERT(DECIMAL(18,2),vs.available_bytes/1073741824.0) AS [Available Size (GB)],  
		CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 
	FROM sys.master_files AS f WITH (NOLOCK)
		CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs OPTION (RECOMPILE);
	')

	--Shows you the total and free space on the LUNs where you have database files


	-- Get I/O utilization by database
	PRINT '########## IO Utilization by Database #############';
	WITH Aggregate_IO_Statistics
	AS
	(SELECT DB_NAME(database_id) AS [Database Name],
	CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS io_in_mb
	FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
	GROUP BY database_id)
	SELECT RTRIM(CAST (ROW_NUMBER() OVER(ORDER BY io_in_mb DESC)AS VARCHAR)) AS [I/O Rank], 
		RTRIM(CAST ([Database Name] AS VARCHAR)) AS [Database Name], 
		RTRIM(CAST (io_in_mb AS VARCHAR)) AS [Total I/O (MB)],
		RTRIM(CAST (io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2))) AS [I/O Percent]
	FROM Aggregate_IO_Statistics
	ORDER BY [I/O Rank] OPTION (RECOMPILE);
	
	-- Calculates average stalls per read, per write, and per total input/output for each database file. 
	PRINT '########## Stall Information #############';
	SELECT RTRIM(CAST (DB_NAME(fs.database_id) AS VARCHAR)) AS [Database Name], 
		RTRIM(CAST (mf.physical_name AS VARCHAR(172))) AS [Physical Name], 
		RTRIM(CAST (io_stall_read_ms AS VARCHAR)) AS [IO Stall Read ms], 
		RTRIM(CAST (num_of_reads AS VARCHAR)) AS [Number of Reads],
		RTRIM(CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1))) AS [Avg Read Stall ms],
		RTRIM(CAST (io_stall_write_ms AS VARCHAR)) AS [IO Stall Write ms], 
		RTRIM(CAST (num_of_writes AS VARCHAR)) AS [Number of Writes],
		RTRIM(CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1))) AS [Avg Write Stall ms],
		RTRIM(CAST (io_stall_read_ms + io_stall_write_ms AS VARCHAR)) AS [IO Stalls], 
		RTRIM(CAST (num_of_reads + num_of_writes AS VARCHAR)) AS [Total IO],
		RTRIM(CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1))) AS [Avg IO Stall ms]
	FROM sys.dm_io_virtual_file_stats(null,null) AS fs
	INNER JOIN sys.master_files AS mf
	ON fs.database_id = mf.database_id
	AND fs.[file_id] = mf.[file_id]
	ORDER BY io_stall_read_ms + io_stall_write_ms DESC OPTION (RECOMPILE);
	-- Helps you determine which database files on the entire instance have the most I/O bottlenecks
	
	-- Missing Indexes current database by Index Advantage
	PRINT '########## Potential Index Additions #############';
	SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], 
		migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
		mid.equality_columns, mid.inequality_columns, mid.included_columns,
		migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
	FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
	INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
	ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
	ON mig.index_handle = mid.index_handle
	WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
	ORDER BY index_advantage DESC OPTION (RECOMPILE);

	-- Look at index advantage, last user seek time, number of user seeks to help determine source and importance
	-- SQL Server is overly eager to add included columns, so beware
	-- Do not just blindly add indexes that show up from this query!!!

	--	Autogrowth events
	PRINT '########## AutoGrowth Events #############';
	DECLARE @filename NVARCHAR(1000), @bc INT, @ec INT, @bfn VARCHAR(1000), @efn VARCHAR(10)
	SELECT  @filename = CAST(value AS NVARCHAR(1000))
	FROM    ::
			FN_TRACE_GETINFO(DEFAULT)
	WHERE   traceid = 1
			AND property = 2;

	-- rip apart file name into pieces
	SET @filename = REVERSE(@filename);
	SET @bc = CHARINDEX('.', @filename);
	SET @ec = CHARINDEX('_', @filename) + 1;
	SET @efn = REVERSE(SUBSTRING(@filename, 1, @bc));
	SET @bfn = REVERSE(SUBSTRING(@filename, @ec, LEN(@filename)));

	-- set filename without rollover number
	SET @filename = @bfn + @efn

	-- process all trace files
	SELECT  ftg.StartTime ,
			te.name AS EventName ,
			RTRIM(CAST(DB_NAME(ftg.databaseid)AS VARCHAR)) AS DatabaseName ,
			RTRIM(CAST(ftg.Filename AS VARCHAR)) AS [Filename] ,
			( ftg.IntegerData * 8 ) / 1024.0 AS GrowthMB ,
			( ftg.duration / 1000 ) AS DurMS
	FROM    ::
			FN_TRACE_GETTABLE(@filename, DEFAULT) AS ftg
			INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id
	WHERE   ( ftg.EventClass = 92		-- Date File Auto-grow
			  OR ftg.EventClass = 93	-- Log File Auto-grow
			)
			AND DB_NAME(ftg.databaseid) = @DB
	ORDER BY ftg.StartTime
	
	IF @VersionMajor = '10.50'
	BEGIN
	
	-- For version 2008
	-- Get VLF Counts for all databases on the instance
	PRINT '########## VLF Counts #############';
	Create Table #stage(
    FileID      int
  , FileSize    bigint
  , StartOffset bigint
  , FSeqNo      bigint
  , [Status]    bigint
  , Parity      bigint
  , CreateLSN   numeric(38)
	);
 
	Create Table #results(
		Database_Name   sysname
		, VLF_count       int 
	);
 
	Exec sp_msforeachdb N'Use ?; 
            Insert Into #stage 
            Exec sp_executeSQL N''DBCC LOGINFO(?)''; 
 
            Insert Into #results 
            Select DB_Name(), Count(*) 
            From #stage; 
 
            Truncate Table #stage;'
 
	Select * 
	From #results
		Order By VLF_count Desc;
 
	Drop Table #stage;
	Drop Table #results;
	
	END
	
	IF @VersionMajor IN ('11.00', '12.00', '13.0')
	BEGIN
	
		-- For version 2012/2014/2016
		-- Get VLF Counts for all databases on the instance
	PRINT '########## VLF Counts #############';
	CREATE TABLE #VLFInfo (RecoveryUnitID int, FileID  int,
					   FileSize bigint, StartOffset bigint,
					   FSeqNo      bigint, [Status]    bigint,
					   Parity      bigint, CreateLSN   numeric(38));
	 
	CREATE TABLE #VLFCountResults(DatabaseName sysname, VLFCount int);
	 
	EXEC sp_MSforeachdb N'Use [?]; 

				INSERT INTO #VLFInfo 
				EXEC sp_executesql N''DBCC LOGINFO([?])''; 
	 
				INSERT INTO #VLFCountResults 
				SELECT DB_NAME(), COUNT(*) 
				FROM #VLFInfo; 

				TRUNCATE TABLE #VLFInfo;'
	 
	SELECT RTRIM(CAST (DatabaseName AS VARCHAR)) AS [Database Name], 
		RTRIM(CAST (VLFCount AS VARCHAR)) AS [VLF Count] 
	FROM #VLFCountResults
		ORDER BY VLFCount DESC;
	 
	DROP TABLE #VLFInfo;
	DROP TABLE #VLFCountResults;	
	
	END
END

IF @infoCPU = 'TRUE' BEGIN

	-- Recent CPU Utilization History 
	-- Get CPU Utilization History for last 256 minutes (in one minute intervals)
	PRINT '########## CPU Utilization #############';
	DECLARE @ts_now bigint
	SELECT @ts_now = cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info;

	SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
				   SystemIdle AS [System Idle Process], 
				   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
				   DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
	FROM ( 
		  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
				AS [SystemIdle], 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
				'int') 
				AS [SQLProcessUtilization], [timestamp] 
		  FROM ( 
				SELECT [timestamp], CONVERT(xml, record) AS [record] 
				FROM sys.dm_os_ring_buffers WITH (NOLOCK)
				WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
				AND record LIKE N'%<SystemHealth>%') AS x 
		  ) AS y 
	ORDER BY record_id DESC OPTION (RECOMPILE);

	-- Signal Waits for instance
	PRINT '########## Signat Waits #############';
	SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [% Signal (CPU) Waits],
		CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [% Resource Waits]
	FROM sys.dm_os_wait_stats WITH (NOLOCK)
	WHERE wait_type NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 
		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT') OPTION (RECOMPILE);

	-- Signal Waits above 10-15% is usually a sign of CPU pressure
	
	-- Get CPU utilization by database 
	PRINT '########## CPU Utilization by Database #############';
	WITH DB_CPU_Stats
	AS
		(SELECT DatabaseID, DB_Name(DatabaseID) AS [Database Name], SUM(total_worker_time) AS [CPU_Time_Ms]
	FROM sys.dm_exec_query_stats AS qs
		CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
		GROUP BY DatabaseID)
	SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
       RTRIM(CAST ([Database Name] AS VARCHAR)) AS [Database Name], 
	   [CPU_Time_Ms] AS [CPU Time (ms)], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
	FROM DB_CPU_Stats
	WHERE DatabaseID <> 32767 -- ResourceDB
		ORDER BY [CPU Rank] OPTION (RECOMPILE);
	

END

IF @infoMEM = 'TRUE' BEGIN

	-- Page Life Expectancy (PLE) value for current instance
	PRINT '########## Page Life Expectancy #############';
	SELECT RTRIM(CAST(ServerProperty('servername') AS VARCHAR(50))) AS [Server Name], 
		RTRIM(CAST([object_name] AS VARCHAR(50))) AS [Object Name], 
		cntr_value AS [Page Life Expectancy]
	FROM sys.dm_os_performance_counters WITH (NOLOCK)
	WHERE [object_name] LIKE N'%Buffer Manager%' -- Handles named instances
	AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);

	-- PLE is a good measurement of memory pressure.
	-- Higher PLE is better. Watch the trend, not the absolute value.
	
	-- Memory Grants Pending value for current instance
	-- Run several times in quick succession
	DECLARE @COUNTER INT
	DECLARE @PARAM1 VARCHAR(72)
	DECLARE @PARAM2 VARCHAR(72)
	DECLARE @PARAM3 VARCHAR(10)

	PRINT CHAR(13) + + CHAR(13)
	PRINT '######### MEMORY GRANTS PENDING	##########'
	SET @COUNTER = 0
	DECLARE my_cursor CURSOR FOR
		SELECT CAST(ServerProperty('servername') AS VARCHAR(50)) AS [Server Name], 
			[object_name], 
			cntr_value AS [Memory Grants Pending]                                                                                                       
		FROM sys.dm_os_performance_counters WITH (NOLOCK)
		WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
		AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE)

	OPEN my_cursor

	FETCH NEXT FROM my_cursor
	INTO @PARAM1, @PARAM2, @PARAM3;

	WHILE @@FETCH_STATUS = 0
		WHILE @COUNTER <=15
			BEGIN
				PRINT @PARAM1 + '          ' + @PARAM2 + @PARAM3
				SET @COUNTER = @COUNTER + 1
				FETCH NEXT FROM my_cursor
				INTO @PARAM1, @PARAM2, @PARAM3
			END

	CLOSE my_cursor
	DEALLOCATE my_cursor

	-- Memory Grants Outstanding above zero for a sustained period is a very strong indicator of memory pressure
	-- Specifies the total number of processes that have successfully acquired a workspace memory grant.
	
	-- Get total buffer usage by database for current instance
	-- This make take some time to run on a busy instance
	
	PRINT CHAR(13);
	PRINT '########## Total Buffer Usage by DB #############';
	
	SELECT RTRIM(CAST(DB_NAME(database_id) AS VARCHAR)) AS [Database Name],
		COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
	FROM sys.dm_os_buffer_descriptors
	WHERE database_id > 4 -- system databases
	AND database_id <> 32767 -- ResourceDB
	GROUP BY DB_NAME(database_id)
	ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);

	-- Information about what specifically is in the buffer for @DB
	IF @BufferSpecific = 'TRUE' BEGIN
	PRINT '########## Objects in buffer for @DB #############';
	
	EXEC ('USE ' + @DB + '
	SELECT COUNT(*) AS cached_pages_count, 
			RTRIM(CAST (name AS VARCHAR)) AS [BaseTableName], 
			RTRIM(CAST (IndexName AS VARCHAR(50))) AS [IndexName], 
			RTRIM(CAST (IndexTypeDesc AS VARCHAR)) AS [IndexTypeDesc]
	FROM sys.dm_os_buffer_descriptors AS bd
		INNER JOIN
		(
	SELECT s_obj.name, 
			s_obj.index_id, 
			s_obj.allocation_unit_id, 
			s_obj.OBJECT_ID,
			i.name IndexName, 
			i.type_desc IndexTypeDesc
	FROM
		(
	SELECT OBJECT_NAME(OBJECT_ID) AS name, 
			index_id, 
			allocation_unit_id, 
			OBJECT_ID
	FROM sys.allocation_units AS au
		INNER JOIN sys.partitions AS p
		ON au.container_id = p.hobt_id
		AND (au.type = 1 OR au.type = 3)
		UNION ALL
	SELECT OBJECT_NAME(OBJECT_ID) AS name,
		index_id, 
		allocation_unit_id, 
		OBJECT_ID
	FROM sys.allocation_units AS au
		INNER JOIN sys.partitions AS p
		ON au.container_id = p.partition_id
		AND au.type = 2
		) AS s_obj
		LEFT JOIN sys.indexes i ON i.index_id = s_obj.index_id
		AND i.OBJECT_ID = s_obj.OBJECT_ID ) AS obj
		ON bd.allocation_unit_id = obj.allocation_unit_id
	WHERE database_id = DB_ID()
		GROUP BY name, index_id, IndexName, IndexTypeDesc
		ORDER BY cached_pages_count DESC;
	')
	
	END
	
	-- Good basic information about operating system memory amounts and state
	PRINT '########## OS Memory #############';
	SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       total_page_file_kb/1024 AS [Total Page File (MB)], 
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
	FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

	-- You want to see "Available physical memory is high"
	-- This indicates that you are not under external memory pressure

	-- SQL Server Process Address space info 
	--(shows whether locked pages is enabled, among other things)
	PRINT '########## Process Address Space Info #############';
	SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
		   page_fault_count, memory_utilization_percentage, 
		   available_commit_limit_kb, process_physical_memory_low, 
		   process_virtual_memory_low
	FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);

	-- You want to see 0 for process_physical_memory_low
	-- You want to see 0 for process_virtual_memory_low
	-- This indicates that you are not under internal memory pressure

	-- Tells you how much memory (in the buffer pool) is being used by each database on the instance
	PRINT '########## Instance Memory Settings #############';
	SELECT  RTRIM(CAST(c.minimum AS VARCHAR)) AS [Min Memory (MB)], 
			RTRIM(CAST(c.value_in_use AS VARCHAR)) AS [Max Memory (MB)] ,
			( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) [Server Memory (MB)]
	FROM    sys.dm_os_sys_memory m
			INNER JOIN sys.configurations c ON c.name = 'max server memory (MB)'
	WHERE   CAST(m.total_physical_memory_kb AS BIGINT) < ( CAST(c.value_in_use AS BIGINT) * 1024 )

END

IF @infoQuery = 'TRUE' BEGIN
	-- Returns the top 10 queries and associated info by CPU time
	-- Had to remove a function that gave the explain plan in XML due to limitations in output. May revisit.
	DECLARE GET_QUERY_PLAN_INFO CURSOR READ_ONLY FOR 
	SELECT top 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
		((CASE qs.statement_end_offset
	WHEN -1 THEN DATALENGTH(qt.TEXT)
		ELSE qs.statement_end_offset
	END - 	qs.statement_start_offset)/2)+1) [Query_Text], 
			qs.execution_count, 
			qs.total_logical_reads, 
			qs.last_logical_reads, 
			qs.total_worker_time,
			qs.last_worker_time,
			qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
			qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
			qs.last_execution_time
	FROM sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
	ORDER BY qs.total_worker_time DESC -- CPU time;

OPEN GET_QUERY_PLAN_INFO

PRINT '########## Top Running Queries by CPU Time #############';
PRINT '';

	FETCH NEXT FROM GET_QUERY_PLAN_INFO INTO 
			@v_query_text,
			@v_execution_count,
			@v_total_logical_reads,
			@v_last_logical_reads,
			@v_total_worker_time,
			@v_last_worker_time,
			@v_total_elapsed_time,
			@v_last_elapsed_time,
			@v_last_execution_time
	WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT '########## Query Info #############';
	PRINT '';
	PRINT CAST(@v_query_text AS nvarchar(max));
	PRINT '';
	PRINT 'Execution Count       = ' + CAST(@v_execution_count AS nvarchar);
	PRINT 'Last Logical Reads    = ' + CAST(@v_last_logical_reads AS nvarchar);
	PRINT 'Total Logical Reads   = ' + CAST(@v_total_logical_reads AS nvarchar);
	PRINT 'Last Worker Time      = ' + CAST(@v_last_worker_time AS nvarchar);
	PRINT 'Total Worker Time     = ' + CAST(@v_total_worker_time AS nvarchar);
	PRINT 'Last Elapsed Seconds  = ' + CAST(@v_last_elapsed_time AS nvarchar);
	PRINT 'Total Elapsed Seconds = ' + CAST(@v_total_elapsed_time AS nvarchar);
	PRINT 'Last Execution Time   = ' + CAST(@v_last_execution_time AS nvarchar);
	PRINT '';

	FETCH NEXT FROM GET_QUERY_PLAN_INFO 
	INTO 	@v_query_text,
			@v_execution_count,
			@v_total_logical_reads,
			@v_last_logical_reads,
			@v_total_worker_time,
			@v_last_worker_time,
			@v_total_elapsed_time,
			@v_last_elapsed_time,
			@v_last_execution_time

END
CLOSE GET_QUERY_PLAN_INFO
DEALLOCATE GET_QUERY_PLAN_INFO
END;

IF @infoJOBS = 'TRUE' BEGIN

	-- Get SQL Server Agent jobs and Category information 
	PRINT '########## SQL Agent Jobs #############';
	SELECT RTRIM(CAST(sj.name AS VARCHAR(50))) AS [JobName],
		SUBSTRING(sj.[description], 1, 87) AS [JobDescription],
		RTRIM(CAST(SUSER_SNAME(sj.owner_sid) AS VARCHAR)) AS [JobOwner],
		sj.date_created, 
		sj.[enabled], 
		sj.notify_email_operator_id, 
		RTRIM(CAST(sc.name AS VARCHAR)) AS [CategoryName]
	FROM msdb.dbo.sysjobs AS sj WITH (NOLOCK)
		INNER JOIN msdb.dbo.syscategories AS sc WITH (NOLOCK)
		ON sj.category_id = sc.category_id
		ORDER BY sj.name OPTION (RECOMPILE);

END


IF @infoSEC = 'TRUE' BEGIN
	-- Who has sysadmin privileges	
	PRINT '########## Who has Sysadmin Privileges #############';
	SELECT  'Sysadmins'[Sysadmins],
			( 'Login: [' + RTRIM(CAST(l.name as varchar(50))) + ']') AS [Details]
	FROM    master.sys.syslogins l
	WHERE   l.sysadmin = 1
			AND l.name <> SUSER_SNAME(0x01)
			AND l.denylogin = 0;

	-- Who has security admin privileges 
	-- With security admin, this user can give other users (INCLUDING THEMSELVES) permissions to do everything	
	PRINT '########## Who has security admin privileges #############';
	SELECT  RTRIM(CAST('Security Admin' AS VARCHAR)) AS [SECAdmin], 
			RTRIM(CAST(l.name AS VARCHAR(50))) AS [Login]   
    FROM    master.sys.syslogins l
    WHERE   l.securityadmin = 1
			AND l.name <> SUSER_SNAME(0x01)
            AND l.denylogin = 0 ;

END

IF @infoFRAG = 'TRUE' or @Inventory = 'TRUE' BEGIN
    -- Check Fragmentation on all indexes in @DB 
	PRINT '##########  Index Fragmentation #############';
	EXEC ('USE ' + @DB +'
	
	SELECT RTRIM(CAST(t.name AS VARCHAR)) AS TableName, 
		RTRIM(CAST(b.name AS VARCHAR)) AS IndexName, 
		i.rowcnt, 
		ps.avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS ps
		INNER JOIN sys.indexes AS b ON ps.OBJECT_ID = b.OBJECT_ID
		INNER JOIN sys.tables AS t on ps.OBJECT_ID = t.OBJECT_ID
		INNER JOIN sysindexes i on b.name = i.name
		AND ps.index_id = b.index_id
	WHERE ps.database_id = DB_ID()
		AND b.name is not null
		AND ps.page_count > 5000
	ORDER BY t.name, b.name
	')

END

IF @infoSTAT = 'TRUE' or @Inventory = 'TRUE' BEGIN
   -- Check when statistics were last gathered on indexes
   PRINT '########## Last Statistice Gather Date #############';
	EXEC ('USE ' + @DB + '
	SELECT RTRIM(CAST(t.name AS VARCHAR)) AS TABLE_NAME, 
		RTRIM(CAST(i.name AS VARCHAR)) AS INDEX_NAME, 
		STATS_DATE(i.OBJECT_ID, INDEX_ID) AS StatsUpdated
	FROM SYS.INDEXES i
	INNER JOIN SYS.TABLES t on t.OBJECT_ID = i.OBJECT_ID
	ORDER BY t.name
	')
	
	-- Looks at most volatile indexes
    PRINT '########## Most Volatile Indexes #############';
	EXEC ('USE ' + @DB + '
	SELECT TOP 100 RTRIM(CAST(o.name AS VARCHAR(50))) AS [Object_Name], 
		o.[object_id], 
		RTRIM(CAST(o.type_desc AS VARCHAR)) AS [Type_Desc],
		RTRIM(CAST(s.name AS VARCHAR(50))) AS [Statistics_Name], 
        s.stats_id, s.no_recompute, s.auto_created, 
	    sp.modification_counter, sp.rows, sp.rows_sampled, sp.last_updated,
		(sp.rows_sampled * 100.00)/sp.rows AS [percentage]
	FROM sys.objects AS o WITH (NOLOCK)
	INNER JOIN sys.stats AS s WITH (NOLOCK)
		ON s.object_id = o.object_id
		CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
	WHERE sp.modification_counter > 0
	ORDER BY sp.modification_counter DESC, o.name OPTION (RECOMPILE);
	')

END
