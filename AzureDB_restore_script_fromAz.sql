-- Restore the DB to a new DB:--use the same URL as above-- WITH Moves to new file names RESTORE DATABASE AzureDB_restored --new database nameFROM URL = 'https://nsomtechstorage.blob.core.windows.net/sqlbackup/AzureDB.bak'WITH CREDENTIAL = 'SQLBackup',Move 'AzureDB' to 'C:\AzureDB\Data\AzureDB_restore.mdf',Move 'AzureDB_log' to 'C:\AzureDB\Log\AzureDB_Restored.ldf';
