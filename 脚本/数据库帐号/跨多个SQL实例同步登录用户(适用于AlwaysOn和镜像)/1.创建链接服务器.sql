--1.创建链接服务器，AlwaysOn集群里的所有节点都要创建链接服务器，非当前节点



--create  linkedserver
USE [master]
GO

DECLARE @IP NVARCHAR(MAX)
DECLARE @Login NVARCHAR(MAX)
DECLARE @PWD NVARCHAR(MAX)

SET @Login = N'sa' --★Do
SET @PWD = N'xxxxxx'  --★Do
SET  @IP ='192.168.10.11,1433'    --★Do


EXEC master.dbo.sp_addlinkedserver @server = @IP,@srvproduct = N'SQL Server'

EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'collation compatible', @optvalue = N'false'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'data access', @optvalue = N'true'
EXEC master.dbo.sp_serveroption @server = @IP, @optname = N'dist',@optvalue = N'false'
EXEC master.dbo.sp_serveroption @server = @IP, @optname = N'pub',@optvalue = N'false'
EXEC master.dbo.sp_serveroption @server = @IP, @optname = N'rpc',@optvalue = N'true'
EXEC master.dbo.sp_serveroption @server = @IP, @optname = N'rpc out',@optvalue = N'true'
EXEC master.dbo.sp_serveroption @server = @IP, @optname = N'sub',@optvalue = N'false'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'connect timeout', @optvalue = N'0'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'collation name', @optvalue = NULL
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'lazy schema validation', @optvalue = N'false'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'query timeout', @optvalue = N'0'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'use remote collation', @optvalue = N'true'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'connect timeout', @optvalue = N'120'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'query timeout', @optvalue = N'120'
EXEC master.dbo.sp_serveroption @server = @IP,@optname = N'remote proc transaction promotion',@optvalue = N'true'

USE [master]
EXEC master.dbo.sp_addlinkedsrvlogin 
@rmtsrvname = @IP,
@locallogin = NULL, 
@useself = N'False', 
@rmtuser = @Login,
@rmtpassword = @PWD

