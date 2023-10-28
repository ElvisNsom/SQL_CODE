
SET NOCOUNT ON

    CREATE TABLE #temp

        (

          SERVER_name SYSNAME NULL ,

          Database_name SYSNAME NULL ,

          UserName SYSNAME ,

          GroupName SYSNAME ,

          LoginName SYSNAME NULL ,

          DefDBName SYSNAME NULL ,

          DefSchemaName SYSNAME NULL ,

          UserID INT ,

          [SID] VARBINARY(85)

        )

 

    CREATE TABLE #temp2

        (

              Name  SYSNAME NULL ,

              ServerRoleName SYSNAME NULL,

              type_desc SYSNAME NULL,

              is_disabled SYSNAME NULL,

              create_date SYSNAME NULL,

              modify_date SYSNAME NULL,

              default_database_name SYSNAME NULL)

 

 

    DECLARE @command VARCHAR(MAX)

    --this will contain all the databases (and their sizes!)

    --on a server

    DECLARE @databases TABLE

        (

          Database_name VARCHAR(128) ,

          Database_size INT ,

          remarks VARCHAR(255)

        )

    INSERT  INTO @databases--stock the table with the list of databases

            EXEC sp_databases

 

    SELECT  @command = COALESCE(@command, '') + '

    USE ' + database_name + '

    insert into #temp (UserName,GroupName, LoginName,

                        DefDBName, DefSchemaName,UserID,[SID])

         Execute sp_helpuser

    UPDATE #TEMP SET database_name=DB_NAME(),

                     server_name=@@ServerName

    where database_name is null

    '

    FROM    @databases

    EXECUTE ( @command )

 

 

       select a.SERVER_name ,

          a.Database_name ,

          a.UserName ,

          a.GroupName as 'Role' ,

          a.LoginName ,

          a.DefDBName ,

--         a.DefSchemaName ,

--        a.UserID ,

--         a.[SID] ,

                p.is_disabled,

                p.create_date ,

                p.modify_date

                FROM    #temp a

                INNER JOIN sys.server_principals p ON

                p.name = a.UserName

                order by a.UserName

 

 

-- To collect logins with server's roles

 

insert into #temp2 (Name, ServerRoleName, type_desc, is_disabled, create_date, modify_date, default_database_name)

SELECT

p.name AS [Name] ,r.name AS [ServerRoleName], r.type_desc,p.is_disabled,p.create_date , p.modify_date,p.default_database_name

FROM

sys.server_principals r

INNER JOIN sys.server_role_members m ON r.principal_id = m.role_principal_id

INNER JOIN sys.server_principals p ON p.principal_id = m.member_principal_id

WHERE r.type = 'R' --and r.name = N'sysadmin'

 

 

 

-- SQL Server Logins without mapping on user databases.

 

SELECT @@SERVERNAME AS 'Server Name' , r.name AS [Name] ,'public' AS [ServerRoleName], r.type_desc,r.is_disabled,r.create_date , r.modify_date,r.default_database_name

FROM

sys.server_principals r

where r.name not in ( select Name from #temp2) and  (r.type <> 'R' and r.type <> 'C' )and r.name not in ( select UserName from #temp)

union

SELECT

@@SERVERNAME AS 'Server Name' , p.name AS [Name] ,r.name AS [ServerRoleName], p.type_desc,p.is_disabled,p.create_date , p.modify_date,p.default_database_name

FROM

sys.server_principals r

INNER JOIN sys.server_role_members m ON r.principal_id = m.role_principal_id

INNER JOIN sys.server_principals p ON p.principal_id = m.member_principal_id

WHERE r.type = 'R' --and r.name = N'sysadmin'

 

 

drop table  #temp;

drop table #temp2;