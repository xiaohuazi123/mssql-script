
-- =============================================
-- Create date: <2014/4/18>
-- Description: 
  -- 功能：批量主备互换、删除镜像、改高安全同步模式、改高性能异步模式
  -- 执行： 在主库执行
-- =============================================


-- 声明变量
DECLARE
	@sql AS	NVARCHAR(4000),
    @dbname  AS NVARCHAR(2000),
	@dbnamePrefix AS NVARCHAR(100);

-- 初始变量
SET @dbnamePrefix=''
    
-- 声明游标
-- 列表所有数据库
DECLARE dbn CURSOR LOCAL FOR
SELECT name FROM master..sysdatabases WHERE name not in('master','tempdb','model','msdb')
AND [Name] LIKE @dbnamePrefix+'%'
ORDER BY name
    
OPEN dbn;

-- 取第一条记录
FETCH NEXT FROM dbn INTO @dbname;

WHILE @@FETCH_STATUS=0
BEGIN
    -- 操作
    SET @sql = 'USE master;'
--高安全，同步模式			 
--			 + 'ALTER DATABASE ' + @dbname + ' SET PARTNER SAFETY FULL;'	
--高性能，异步模式			 
--			 + 'ALTER DATABASE ' + @dbname + ' SET PARTNER SAFETY OFF;'
--主备互换
--			 + 'ALTER DATABASE ' + @dbname + ' SET PARTNER FAILOVER;'
--删除镜像
			 + 'ALTER DATABASE ' + @dbname + ' SET PARTNER OFF;'	

	print (@sql)	
    
    -- 取下一条记录
    FETCH NEXT FROM dbn INTO @dbname;
END

-- 关闭游标
CLOSE dbn;

-- 释放游标
DEALLOCATE dbn;