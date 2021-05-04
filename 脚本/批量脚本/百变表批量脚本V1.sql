
-- =============================================
-- Create date: <2015/2/18>
-- Description: 百变表批量脚本
-- =============================================

use dbname --★Do 切换到要执行的数据库
GO

DECLARE @fromdb varchar(100)
DECLARE @todb varchar(100)
DECLARE @tablename varchar(100)
DECLARE @sql nvarchar(max)
SET @todb = 'dbname'  --★Do 

PRINT ('USE ['+@todb+']' +CHAR(10)+'GO'+CHAR(10))


DECLARE @itemCur CURSOR
SET @itemCur = CURSOR FOR 
    SELECT name from sys.tables WHERE type='U' order by name

OPEN @itemCur
FETCH NEXT FROM @itemCur INTO @tablename
WHILE @@FETCH_STATUS=0
BEGIN
	PRINT ('--'+@tablename)
	SET @sql = 'truncate table ['+@todb+'].[dbo].['+@tablename+']' --★Do 根据要执行的命令修改
	PRINT(@sql)PRINT('GO')+CHAR(13)

    FETCH NEXT FROM @itemCur INTO @tablename
END 

CLOSE @itemCur
DEALLOCATE @itemCur
