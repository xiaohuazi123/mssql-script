-- =============================================
-- Create date: <2014/4/18>
-- Description: 批量完整备份库
-- =============================================
DECLARE @DBNAME NVARCHAR(100)
DECLARE @DriveName NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

SET @DriveName='D'  --★Do 备份到的盘符

PRINT 'DECLARE @CurrentTime VARCHAR(50), @FileName VARCHAR(200)'+CHAR(10)+
'SET @CurrentTime = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120 ),''-'',''_''),'' '',''_''),'':'','''')'


DECLARE CurDBName CURSOR
FOR
    SELECT  name
    FROM    sys.[databases]
    WHERE   name  LIKE '%%' AND
    [name] NOT IN ('MASTER','MODEL','TEMPDB','MSDB','ReportServer','ReportServerTempDB','distribution')

OPEN CurDBName
FETCH NEXT FROM CurDBName INTO @DBNAME

WHILE @@FETCH_STATUS = 0
    BEGIN  
        SET @SQL = N'
        
--('+@DBNAME+' 数据库完整备份)
SET @FileName = '''+@DriveName+':\DBBackup\' + @DBNAME + '_FullBackup_'' + @CurrentTime+''.bak''  --★Do 路径要预先建好
BACKUP DATABASE [' + @DBNAME + ']
TO DISK=@FileName WITH FORMAT ,COMPRESSION,stats=5
'
        PRINT @SQL


  
        FETCH NEXT FROM CurDBName INTO @DBNAME
    END
CLOSE CurDBName
DEALLOCATE CurDBName