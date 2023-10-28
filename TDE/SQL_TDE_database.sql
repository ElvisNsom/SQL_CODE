SELECT
    d.name,
    d.is_encrypted,
    dmk.encryption_state,
    dmk.percent_complete,
    dmk.key_algorithm,
    dmk.key_length
FROM
    sys.databases d
    LEFT OUTER JOIN sys.dm_database_encryption_keys dmk
    ON d.database_id = dmk.database_id;



--Check if there’s a master key on the database 

SELECT * FROM   sys.symmetric_keys
WHERE  name LIKE '%DatabaseMasterKey%'


create database TDE_DB

--------------

 Use [TDE_DB]
Go
Create Master Key Encryption By Password ='Nsom1992@' 

--Step #2 Validate if  a master key has been created.

 USE TDE_DB;
  
select * from sys.symmetric_keys;


-- Create a Certificate protected by the Master Key

 USE [master]
GO
Create Certificate TDE_DB_Cert
With Subject = 'TDE_DB_Certificate'

--Step #4.  Validate that a Database Certificate has been created


Select * from sys.certificates

--- Backup Certificate to Remote Location(Network Path)

Backup Certificate TDE_DB_Cert  TO FILE = '\\DC-REDGATE\tde_bak\TDE_DB_Cert.cer'
 With Private Key (File = '\\DC-REDGATE\tde_bak\TDE_DB_Cert_key.pvk',
 Encryption By Password = 'Nsom1992@');


--- Create a DEK (Database Encryption Key) protected by Certificate



 USE [TDE_DB]

Create Database Encryption Key With Algorithm = AES_256 
Encryption By Server Certificate TDE_DB_Cert


Alter Database TDE_DB     
Set Encryption On;


----- Decrypting the Database Encrpted with TDE (run this on the Target Server)

--create a new master key--
Use [Master]
Go
Create Master Key Encryption By Password ='Password2' 
--Lets create a new Certificate with reference to the private key in DR and decrypt by 'Password1'--> in DR

USE [master]
GO
Create Certificate TDE_DB_Cert3
From File = '\\DC-REDGATE\tde_bak\TDE_DB_Cert.cer'
With Private Key (FILE = '\\DC-REDGATE\tde_bak\TDE_DB_Cert_key.pvk',
Decryption By Password = 'Nsom1992@'); 



-- Turn off TDE
USE master;
GO
ALTER DATABASE TDE_DB SET ENCRYPTION OFF;
GO
-- Remove Encryption Key from Database
USE TDE_DB;
GO
DROP DATABASE ENCRYPTION KEY;
GO


SELECT db_name(database_id), encryption_state 
FROM sys.dm_database_encryption_keys;____


DROP MASTER KEY  ___



DROP CERTIFICATE TDE_DB_Cert