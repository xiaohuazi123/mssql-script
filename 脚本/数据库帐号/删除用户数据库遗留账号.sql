

-- =============================================
-- Create date: <2015/4/18>
-- Description: 删除所有数据库的用户遗留账号
-- 功能：
-- @dbsauser 要删除的数据库用户名
-- =============================================




-- 环境变量
SET NOCOUNT ON

DECLARE @sql		NVARCHAR(4000)
DECLARE @dbTable	TABLE (dbname SYSNAME,dblog SYSNAME,bkdbname SYSNAME)

DECLARE @dbsauser	SYSNAME

DECLARE @dbname		SYSNAME
DECLARE @dblog		SYSNAME
DECLARE @bkdbname	SYSNAME
DECLARE @dbnamePrefix		NVARCHAR(8)


-- 初始变量
SET @dbsauser='AWMntDBUser'



-- 列表所有数据库
declare tb cursor local for
select [name] from master..sysdatabases where [name] not in('master','tempdb','model','msdb')
ORDER BY [name]

-- 查询数据库下用户名
open tb
fetch next from tb into @dbname
while @@fetch_status=0
begin
	 SET @sql =	'USE ' + @dbname + ';'
			  + 'IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'''+@dbsauser+''')'
			  + ' DROP USER '+@dbsauser+';';
	 EXEC (@sql)

	fetch next from tb into @dbname
end
close tb
deallocate tb

