
-- =============================================
-- Create date: <2014/4/18>
-- Description: 自动收缩数据库日志脚本，收缩数据库实例下所有数据库的ldf文件
-- =============================================

USE [master]
GO



CREATE PROC [dbo].[ShrinkUser_DATABASESLogFile]
AS
BEGIN
	DECLARE @DBNAME NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)



--临时表保存数据
CREATE TABLE #DataBaseServerData
(
  ID INT IDENTITY(1, 1) ,
  DBNAME NVARCHAR(MAX) ,
  Log_Total_MB DECIMAL(18, 1) NOT NULL ,
  Log_FREE_SPACE_MB DECIMAL(18, 1) NOT NULL 
)



--游标
DECLARE @itemCur CURSOR
SET 
@itemCur = CURSOR FOR 
SELECT name from   SYS.[databases] WHERE [name] NOT IN ('MASTER','MODEL','TEMPDB','MSDB','ReportServer','ReportServerTempDB','distribution')
and state=0

OPEN @itemCur
FETCH NEXT FROM @itemCur INTO @DBNAME
WHILE @@FETCH_STATUS = 0
    BEGIN
    SET @SQL=N'USE ['+@DBNAME+'];'+CHAR(10)
    +'
     DECLARE @TotalLogSpace DECIMAL(18, 1)
     DECLARE @FreeLogSpace DECIMAL(18, 1)
	 DECLARE @filename NVARCHAR(MAX)
	 DECLARE @CanshrinkSize BIGINT
	 DECLARE @SQL1 nvarchar(MAX)

SELECT  @TotalLogSpace=(SUM(CONVERT(dec(17, 2), sysfiles.size)) / 128) 
     FROM    dbo.sysfiles AS sysfiles  WHERE [groupid]=0

SELECT  @FreeLogSpace = ( SUM(( size - FILEPROPERTY(name, ''SpaceUsed'') )) )/ 128.0
     FROM    sys.database_files
     WHERE   [type] = 1

SELECT @filename=name  FROM sys.database_files WHERE [type]=1
SET @CanshrinkSize=CAST((@TotalLogSpace-@FreeLogSpace) AS BIGINT)



SET @SQL1 = ''USE ['+@DBNAME+']''
SET @SQL1 = @SQL1+
 ''DBCC SHRINKFILE (['' + @filename + ''],'' + CAST(@CanshrinkSize+1 AS NVARCHAR(MAX)) + '')''
  EXEC (@SQL1)'
   EXEC (@SQL)
        FETCH NEXT FROM @itemCur INTO @DBNAME
    END 

CLOSE @itemCur
DEALLOCATE @itemCur

SELECT  *  FROM    [#DataBaseServerData]
DROP TABLE [#DataBaseServerData]

END