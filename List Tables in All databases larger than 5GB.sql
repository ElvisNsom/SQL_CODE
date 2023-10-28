--Perfect for collecting Data
Use master
GO

DECLARE @dbname VARCHAR(50)   
DECLARE @statement NVARCHAR(max)

DECLARE db_cursor CURSOR 
LOCAL FAST_FORWARD
FOR  
SELECT name
FROM dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb','distribution', 'DBA')  
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @dbname  
WHILE @@FETCH_STATUS = 0  
BEGIN  

SELECT @statement = 'use '+@dbname +';'+ 'create table #Size (Name varchar(255), [rows] bigint, reserved varchar(255), data varchar(255), index_size varchar(255), unused varchar(255))
create table #TableSize (TableName varchar(255), NoOfRows bigint, ReservedSizeMB bigint, DatSizeMB bigint, ReservedIndexSizeMB bigint, UnusedSizeMB bigint)

EXEC sp_MSforeachtable @command1="insert into #Size EXEC sp_spaceused ''?''"
insert into #TableSize (TableName, NoOfRows, ReservedSizeMB, DatSizeMB, ReservedIndexSizeMB, UnusedSizeMB)
select name, [rows],
SUBSTRING(reserved, 0, LEN(reserved)-2)/1024,
SUBSTRING(data, 0, LEN(data)-2)/1024,
SUBSTRING(index_size, 0, LEN(index_size)-2)/1024,
SUBSTRING(unused, 0, LEN(unused)-2)/1024
from #Size



SELECT DB_NAME() AS [Database_name], *,TotalSpaceGB=((DatSizeMB+ReservedIndexSizeMB)/1024)
from #TableSize
where ((DatSizeMB+ReservedIndexSizeMB)/1024) >= 5
order by TotalSpaceGB desc



drop table #Size
drop table #TableSize'

exec sp_executesql @statement
print @statement
FETCH NEXT FROM db_cursor INTO @dbname  
END  
CLOSE db_cursor  
DEALLOCATE db_cursor
