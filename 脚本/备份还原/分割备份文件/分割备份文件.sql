
-- =============================================
-- Create date: <2014/4/18>
-- Description: 分割备份文件，分开两个或多个TO DISK，备份文件就会分开多个
-- =============================================



DECLARE @CurrentTime VARCHAR(50), @FileName VARCHAR(200),@FileName2 VARCHAR(200)
SET @CurrentTime = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120 ),'-','_'),' ','_'),':','')

        
--(Temp2 数据库完整备份)
SET @FileName = 'D:\Temp2_FullBackup_Partial1_' + @CurrentTime+'.bak'
SET @FileName2 = 'D:\Temp2_FullBackup_Partial2_' + @CurrentTime+'.bak'

BACKUP DATABASE [Temp2]
TO 
DISK=@FileName,
DISK=@FileName2
WITH FORMAT 


