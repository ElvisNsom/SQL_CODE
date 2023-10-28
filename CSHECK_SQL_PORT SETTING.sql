select * from sys.dm_database_encryption_keys 

-- you must connect remotely using TCP/IP
SELECT local_tcp_port
FROM   sys.dm_exec_connections
WHERE  session_id = @@SPID
GO


-- Execute below script if SQL Server is configured with dynamic port number
DECLARE       @portNo   NVARCHAR(10)
  
EXEC   xp_instance_regread
@rootkey    = 'HKEY_LOCAL_MACHINE',
@key        =
'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll',
@value_name = 'TcpDynamicPorts',
@value      = @portNo OUTPUT
  
SELECT [PortNumber] = @portNo
GO



DECLARE       @portNo   NVARCHAR(10)
  
EXEC   xp_instance_regread
@rootkey    = 'HKEY_LOCAL_MACHINE',
@key        =
'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll',
@value_name = 'TcpPort',
@value      = @portNo OUTPUT
  
SELECT [PortNumber] = @portNo
GO