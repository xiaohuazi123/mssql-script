

-- =============================================
-- Create date: <2014/4/18>
-- Description: 各个数据库的总大小V1
-- =============================================




SET NOCOUNT ON 
USE master
GO

DECLARE @DBNAME NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)



--临时表保存数据
CREATE TABLE #DataBaseServerData
(
  ID INT IDENTITY(1, 1) ,
  DBNAME NVARCHAR(MAX) ,
  TotalMB DECIMAL(18, 1) NOT NULL 
)



--游标
DECLARE @itemCur CURSOR
SET 
@itemCur = CURSOR FOR 
SELECT name from   SYS.[sysdatabases] WHERE [name] NOT IN ('MASTER','MODEL','TEMPDB','MSDB','ReportServer','ReportServerTempDB')

OPEN @itemCur
FETCH NEXT FROM @itemCur INTO @DBNAME
WHILE @@FETCH_STATUS = 0
    BEGIN
    SET @SQL=N'USE ['+@DBNAME+'];'+CHAR(10)
    +
    'INSERT  [#DataBaseServerData]
                ( [DBNAME] ,
                  [TotalMB] 
		        )
                SELECT '''+@DBNAME+''', str(sum(convert(dec(17,2),size)) / 128,10,2) AS TotalMB
                FROM    [dbo].sysfiles;'
        EXEC (@SQL)
        PRINT @SQL
        FETCH NEXT FROM @itemCur INTO @DBNAME
    END 

CLOSE @itemCur
DEALLOCATE @itemCur

SELECT  *  FROM    [#DataBaseServerData]
DROP TABLE [#DataBaseServerData]