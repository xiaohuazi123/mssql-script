

-- =============================================
-- Create date: <2014/4/18>
-- Description: --日志文件损坏修复
-- =============================================



--方法一
--REBUILD重建
ALTER DATABASE test SET EMERGENCY
ALTER DATABASE test REBUILD LOG ON
(NAME='test_LOG',FILENAME='D:\TEMP\test_LOG.LDF')
ALTER DATABASE test SET MULTI_USER



--方法二
--推荐先用这种方法，把数据库改为简单模式，截断日志链，再改为完整模式
USE [master]
GO
ALTER DATABASE [test] SET RECOVERY SIMPLE WITH NO_WAIT
GO


USE [master]
GO
ALTER DATABASE [test] SET RECOVERY FULL WITH NO_WAIT
GO
