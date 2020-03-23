
-- =============================================
-- Create date: <2014/4/18>
-- Description: 还原时候，指定所有备份文件的文件路径即可
-- =============================================



USE [master]
RESTORE DATABASE [Temp2] 
FROM  
DISK = N'D:\Temp2_FullBackup_Partial1_2014_12_19_150533.bak',
DISK = N'D:\Temp2_FullBackup_Partial2_2014_12_19_150533.bak' 
WITH  FILE = 1,  
MOVE N'Temp' TO N'E:\DataBase\Temp2.mdf',  
MOVE N'Temp_log' TO N'E:\DataBase\Temp2_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 5

GO