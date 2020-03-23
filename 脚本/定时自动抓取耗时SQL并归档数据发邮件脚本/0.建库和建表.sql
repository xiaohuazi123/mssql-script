USE [master]
GO

CREATE DATABASE [MonitorElapsedHighSQL]
GO
--建表

USE [MonitorElapsedHighSQL]
GO


 --1、表[SQLCountStatisticsByDay]
  --抓取到的sql语句数量
CREATE TABLE [dbo].[SQLCountStatisticsByDay]
    (
      id INT IDENTITY(1, 1)  PRIMARY KEY ,
      [SQLCount] INT ,
      [gettime] DATETIME
    )

CREATE INDEX [Idx_SQLCountStatisticsByDay_SQLCount] ON [MonitorElapsedHighSQL].[dbo].[SQLCountStatisticsByDay]([SQLCount])
CREATE INDEX [Idx_SQLCountStatisticsByDay_gettime] ON [MonitorElapsedHighSQL].[dbo].[SQLCountStatisticsByDay]([gettime])
GO



 --2、表[MostElapsedStatisticsByDay]
 --每条不同的sql耗时最多
CREATE TABLE [dbo].[MostElapsedStatisticsByDay]
    (
      id INT IDENTITY(1, 1)
             PRIMARY KEY ,
      [ElapsedMS] INT ,
      [IOReads] BIGINT ,
      [IOWrites] BIGINT ,
      [DBName] NVARCHAR(128) ,
      [paramlist] NVARCHAR(MAX) ,
      [planstmttext] NVARCHAR(MAX) ,
      [stmttext] NVARCHAR(MAX) ,
      [xmlplan] XML ,
      [gettime] DATETIME
    )

CREATE INDEX [Idx_MostElapsedStatisticsByDay_ElapsedMS] ON [MonitorElapsedHighSQL].[dbo].[MostElapsedStatisticsByDay]([ElapsedMS])
CREATE INDEX [Idx_MostElapsedStatisticsByDay_gettime] ON [MonitorElapsedHighSQL].[dbo].[MostElapsedStatisticsByDay]([gettime])
GO


 --3、表[MostIOReadStatisticsByDay]
--每条不同的sql的IOread最多
CREATE TABLE [dbo].[MostIOReadStatisticsByDay]
    (
      id INT IDENTITY(1, 1)
             PRIMARY KEY ,
      [IOReads] BIGINT ,
      [DBName] NVARCHAR(128) ,
      [paramlist] NVARCHAR(MAX) ,
      [planstmttext] NVARCHAR(MAX) ,
      [stmttext] NVARCHAR(MAX) ,
      [xmlplan] XML ,
      [gettime] DATETIME
    )

CREATE INDEX [Idx_MostIOReadStatisticsByDay_IOReads] ON [MonitorElapsedHighSQL].[dbo].[MostIOReadStatisticsByDay]([IOReads])
CREATE INDEX [Idx_MostIOReadStatisticsByDay_gettime] ON [MonitorElapsedHighSQL].[dbo].[MostIOReadStatisticsByDay]([gettime])
GO


 --4、表[MostIOWriteStatisticsByDay]
--每条不同的sql的IOwrite最多
CREATE TABLE [dbo].[MostIOWriteStatisticsByDay]
    (
      id INT IDENTITY(1, 1)
             PRIMARY KEY ,
      [IOWrites] BIGINT ,
      [DBName] NVARCHAR(128) ,
      [paramlist] NVARCHAR(MAX) ,
      [planstmttext] NVARCHAR(MAX) ,
      [stmttext] NVARCHAR(MAX) ,
      [xmlplan] XML ,
      [gettime] DATETIME
    )

CREATE INDEX [Idx_MostIOWriteStatisticsByDay_IOWrites] ON [MonitorElapsedHighSQL].[dbo].[MostIOWriteStatisticsByDay]([IOWrites])
CREATE INDEX [Idx_MostIOWriteStatisticsByDay_gettime] ON [MonitorElapsedHighSQL].[dbo].[MostIOWriteStatisticsByDay]([gettime])
GO


 --5、表[sp_executesqlCountStatisticsByDay]
--使用sp_executesql的sql有多少条
CREATE TABLE [dbo].[sp_executesqlCountStatisticsByDay]
    (
      id INT IDENTITY(1, 1)
             PRIMARY KEY ,
      [sp_executesqlCount] INT ,
      [DBName] NVARCHAR(128) ,
      [planstmttext] NVARCHAR(MAX) ,
      [gettime] DATETIME
    )

CREATE INDEX [Idx_sp_executesqlCountStatisticsByDay_sp_executesqlCount] ON [MonitorElapsedHighSQL].[dbo].[sp_executesqlCountStatisticsByDay]([sp_executesqlCount])
CREATE INDEX [Idx_sp_executesqlCountStatisticsByDay_gettime] ON [MonitorElapsedHighSQL].[dbo].[sp_executesqlCountStatisticsByDay]([gettime])
GO