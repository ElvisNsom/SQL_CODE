USE MSDB
SELECT name AS [Job Name]
         ,CONVERT(VARCHAR,DATEADD(S,(run_time/10000)*60*60 /* hours */ 
          +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */ 
          + (run_time - (run_time/100) * 100)  /* secs */
           ,CONVERT(DATETIME,RTRIM(run_date),113)),100) AS [Time Run]
         ,CASE WHEN enabled=1 THEN 'Enabled' 
               ELSE 'Disabled' 
          END [Job Status]
         ,CASE WHEN SJH.run_status=0 THEN 'Failed'
                     WHEN SJH.run_status=1 THEN 'Succeeded'
                     WHEN SJH.run_status=2 THEN 'Retry'
                     WHEN SJH.run_status=3 THEN 'Cancelled'
               ELSE 'Unknown' 
          END [Job Outcome]
FROM   sysjobhistory SJH 
JOIN   sysjobs SJ 
ON     SJH.job_id=sj.job_id 
WHERE  step_id=0 
AND    DATEADD(S, 
  (run_time/10000)*60*60 /* hours */ 
  +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */ 
  + (run_time - (run_time/100) * 100)  /* secs */, 
  CONVERT(DATETIME,RTRIM(run_date),113)) >= DATEADD(d,-1,GetDate()) 
ORDER BY name,run_date,run_time 




;WITH CTE_MostRecentJobRun AS 
 ( 
 -- For each job get the most recent run (this will be the one where Rnk=1) 
 SELECT job_id,run_status,run_date,run_time 
 ,RANK() OVER (PARTITION BY job_id ORDER BY run_date DESC,run_time DESC) AS Rnk 
 FROM sysjobhistory 
 WHERE step_id=0 
 ) 
SELECT  
  name  AS [Job Name]
 ,CONVERT(VARCHAR,DATEADD(S,(run_time/10000)*60*60 /* hours */ 
  +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */ 
  + (run_time - (run_time/100) * 100)  /* secs */, 
  CONVERT(DATETIME,RTRIM(run_date),113)),100) AS [Time Run]
 ,CASE WHEN enabled=1 THEN 'Enabled' 
     ELSE 'Disabled' 
  END [Job Status]
FROM     CTE_MostRecentJobRun MRJR 
JOIN     sysjobs SJ 
ON       MRJR.job_id=sj.job_id 
WHERE    Rnk=1 
AND      run_status=0 -- i.e. failed 
ORDER BY name 




exec msdb.dbo.sp_help_job @execution_status=1





-- Different version combining this query and my previous version together
USE msdb
GO
select j.name
,DATEADD(S,(MAX(run_time)/10000)*60*60 /* hours */
+((MAX(run_time) - (MAX(run_time)/10000) * 10000)/100) * 60 /* mins */
+ (MAX(run_time) - (MAX(run_time)/100) * 100) /* secs */
,CONVERT(DATETIME,RTRIM(run_date),113)) AS [Start time]
,DATEADD(S,((MAX(run_time) + MAX(run_duration))/10000)*60*60 /* hours */
+(((MAX(run_time) + MAX(run_duration)) - ((MAX(run_time) + MAX(run_duration))/10000) * 10000)/100) * 60 /* mins */
+ ((MAX(run_time) + MAX(run_duration)) - ((MAX(run_time) + MAX(run_duration))/100) * 100) /* secs */
,CONVERT(DATETIME,RTRIM(run_date),113)) AS [End time]
, ((MAX(run_duration)/10000*3600 + (MAX(run_duration)/100)%100*60 + MAX(run_duration)%100 + 31 ) / 60)
as [Run duration (min)]
,CASE WHEN enabled=1 THEN 'Enabled'
ELSE 'Disabled'
END [Job Status]
, j.category_id
, j.date_modified
, j.notify_email_operator_id
-- ,MAX(js.last_run_outcome) AS [Any failures]
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js
ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh
ON jh.job_id = j.job_id AND jh.step_id = js.step_id
WHERE j.category_id > 100 AND enabled=1
GROUP BY j.name,jh.run_date,j.enabled, j.category_id, j.date_modified, j.notify_email_operator_id--,jh.instance_id
ORDER BY jh.run_date DESC, MAX(run_time) DESC