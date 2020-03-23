


-- =============================================
-- Create date: <2014/4/18>
-- Description: 批量生成Insert脚本>
-- =============================================

USE [dbname]  --★Do 根据fromdb来生成

DECLARE @fromdb VARCHAR(100)
DECLARE @todb VARCHAR(100)
DECLARE @tablename VARCHAR(100)
DECLARE @columnnames NVARCHAR(max)
DECLARE @isidentity NVARCHAR(30)
DECLARE @temsql NVARCHAR(max)
DECLARE @sql NVARCHAR(max)
SET @fromdb = 'dbname'
SET @todb = 'dbname'

IF (OBJECT_ID('#MyTempTable') IS NOT NULL)
drop table #MyTempTable


CREATE TABLE #MyTempTable (names varchar(500))
insert into #MyTempTable
SELECT name from sys.tables WHERE type='U' AND name not in (select OBJECT_NAME(parent_object_id) 'name' from sys.objects where type='F') 

insert into #MyTempTable
select OBJECT_NAME(parent_object_id) 'name' from sys.objects where type='F' order by object_id


--游标
DECLARE @itemCur CURSOR
SET @itemCur = CURSOR FOR 
    SELECT names from #MyTempTable

OPEN @itemCur
FETCH NEXT FROM @itemCur INTO @tablename
WHILE @@FETCH_STATUS=0

BEGIN
	
	SET @sql = ''

	--获取表字段
	SET @temsql = N'
	BEGIN
	SET @columnnamesOUT =''''
	SELECT @columnnamesOUT = @columnnamesOUT + '','' + ''['' + name + '']''
	From sys.columns where object_id=OBJECT_ID(''['+@fromdb+'].dbo.'+@tablename+''')
	order by column_id
	SELECT @columnnamesOUT=substring(@columnnamesOUT,2,len(@columnnamesOUT))
	END
	'
	EXEC sp_executesql @temsql,N'@columnnamesOUT NVARCHAR(max) OUTPUT',@columnnamesOUT=@columnnames OUTPUT

	PRINT ('--'+@tablename)
	PRINT ('--表名 '''+@tablename+'''')

	--判断是否有自增字段
	SET @temsql = N'
	BEGIN
	SET @isidentityOUT =''''
	SELECT @isidentityOUT = name 
	From sys.columns where object_id=OBJECT_ID(''['+@fromdb+'].dbo.'+@tablename+''')
	and is_identity = 1
	END
	'
	EXEC sp_executesql @temsql,N'@isidentityOUT NVARCHAR(30) OUTPUT',@isidentityOUT=@isidentity OUTPUT

	--IDENTITY_INSERT ON
	IF @isidentity != ''
	BEGIN
		SET @sql = 'SET IDENTITY_INSERT ['+@todb+'].[dbo].['+@tablename+'] ON
'
	END

	--INSERT
	SET @sql = @sql+'INSERT INTO ['+@todb+'].[dbo].['+@tablename+']('+@columnnames+')
SELECT * FROM ['+@fromdb+'].[dbo].['+@tablename+']'

	--IDENTITY_INSERT OFF
	IF @isidentity != ''
	BEGIN
		SET @sql = @sql+'
SET IDENTITY_INSERT ['+@todb+'].[dbo].['+@tablename+'] OFF'
	END

	--返回SQL
	PRINT(@sql)PRINT('GO')+CHAR(13)

    FETCH NEXT FROM @itemCur INTO @tablename
END 

CLOSE @itemCur
DEALLOCATE @itemCur
