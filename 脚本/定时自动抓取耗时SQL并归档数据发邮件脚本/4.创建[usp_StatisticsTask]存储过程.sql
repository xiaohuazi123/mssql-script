USE [MonitorElapsedHighSQL]
GO
/****** Object:  StoredProcedure [dbo].[usp_StatisticsTask]    Script Date: 2015/6/24 18:05:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--创建存储过程
CREATE   PROCEDURE [dbo].[usp_StatisticsTask]
AS
    BEGIN

        IF ( ( SELECT   OBJECT_ID('MonitorElapsedHighSQL.dbo.SQLCountStatisticsByDay')
             ) IS NULL
             AND ( SELECT   OBJECT_ID('MonitorElapsedHighSQL.dbo.MostElapsedStatisticsByDay')
                 ) IS NULL
             AND ( SELECT   OBJECT_ID('MonitorElapsedHighSQL.dbo.MostIOReadStatisticsByDay')
                 ) IS NULL
             AND ( SELECT   OBJECT_ID('MonitorElapsedHighSQL.dbo.MostIOWriteStatisticsByDay')
                 ) IS NULL
             AND ( SELECT   OBJECT_ID('MonitorElapsedHighSQL.dbo.sp_executesqlCountStatisticsByDay')
                 ) IS NULL
           )
            BEGIN
                RETURN 1
                 
            END
        ELSE
            BEGIN
                --最耗时SQL
                INSERT  INTO [dbo].[MostElapsedStatisticsByDay]
                        ( [ElapsedMS] ,
                          [IOReads] ,
                          [IOWrites] ,
                          [DBName] ,
                          [paramlist] ,
                          [planstmttext] ,
                          [stmttext] ,
                          [xmlplan] ,
                          [gettime]
                        )
                        SELECT  [ElapsedMS] ,
                                [IOReads] ,
                                [IOWrites] ,
                                [DBName] ,
                                [paramlist] ,
                                [planstmttext] ,
                                [stmttext] ,
                                [xmlplan] ,
                                GETDATE()
                        FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY spid ORDER BY [ElapsedMS] DESC ) rowid ,
                                            *
                                  FROM      [ElapsedHigh]
                                  WHERE     [DBName] NOT IN ( 'MASTER',
                                                              'MODEL', 'MSDB',
                                                              'ReportServer',
                                                              'ReportServerTempDB',
                                                              'distribution' )
                                ) t
                        WHERE   rowid = 1



--读IO最多SQL
                INSERT  INTO [dbo].[MostIOReadStatisticsByDay]
                        ( [IOReads] ,
                          [DBName] ,
                          [paramlist] ,
                          [planstmttext] ,
                          [stmttext] ,
                          [xmlplan] ,
                          [gettime]
                        )
                        SELECT  [IOReads] ,
                                [DBName] ,
                                [paramlist] ,
                                [planstmttext] ,
                                [stmttext] ,
                                [xmlplan] ,
                                GETDATE()
                        FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY spid ORDER BY [IOReads] DESC ) rowid ,
                                            *
                                  FROM      [ElapsedHigh]
                                  WHERE     [DBName] NOT IN ( 'MASTER',
                                                              'MODEL', 'MSDB',
                                                              'ReportServer',
                                                              'ReportServerTempDB',
                                                              'distribution' )
                                ) t
                        WHERE   rowid = 1



--写IO最多SQL
                INSERT  INTO [dbo].[MostIOWriteStatisticsByDay]
                        ( [IOWrites] ,
                          [DBName] ,
                          [paramlist] ,
                          [planstmttext] ,
                          [stmttext] ,
                          [xmlplan] ,
                          [gettime]
                        )
                        SELECT  [IOWrites] ,
                                [DBName] ,
                                [paramlist] ,
                                [planstmttext] ,
                                [stmttext] ,
                                [xmlplan] ,
                                GETDATE()
                        FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY spid ORDER BY [IOWrites] DESC ) rowid ,
                                            *
                                  FROM      [ElapsedHigh]
                                  WHERE     [DBName] NOT IN ( 'MASTER',
                                                              'MODEL', 'MSDB',
                                                              'ReportServer',
                                                              'ReportServerTempDB',
                                                              'distribution' )
                                ) t
                        WHERE   rowid = 1



--统计sp_executesql次数
                DECLARE @tbsp_executesqlCountStatisticsByDay TABLE
                    (
                      [DBName] [nvarchar](128) ,
                      [planstmttext] [nvarchar](MAX)
                    )
                DECLARE @sp_executesqlCount INT

                INSERT  INTO @tbsp_executesqlCountStatisticsByDay
                        ( [DBName] ,
                          [planstmttext] 
                        )
                        SELECT  [DBName] ,
                                [planstmttext]
                        FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY spid ORDER BY [IOWrites] DESC ) rowid ,
                                            *
                                  FROM      [ElapsedHigh]
                                  WHERE     [planstmttext] LIKE '(@%'
                                            AND [DBName] NOT IN ( 'MASTER',
                                                              'MODEL', 'MSDB',
                                                              'ReportServer',
                                                              'ReportServerTempDB',
                                                              'distribution' )
                                ) t
                        WHERE   rowid = 1

                SELECT  @sp_executesqlCount = COUNT(*)
                FROM    @tbsp_executesqlCountStatisticsByDay

                INSERT  INTO [dbo].[sp_executesqlCountStatisticsByDay]
                        ( [sp_executesqlCount] ,
                          [DBName] ,
                          [planstmttext] ,
                          [gettime]
                        )
                        SELECT  @sp_executesqlCount ,
                                [DBName] ,
                                [planstmttext] ,
                                GETDATE()
                        FROM    @tbsp_executesqlCountStatisticsByDay



--统计一共有多少SQL被抓取
                INSERT  INTO [dbo].[SQLCountStatisticsByDay]
                        ( [SQLCount] ,
                          [gettime]
                        )
                        SELECT  COUNT(DISTINCT ( [planstmttext] )) ,
                                GETDATE()
                        FROM    [dbo].[ElapsedHigh]
                        WHERE   [DBName] NOT IN ( 'MASTER', 'MODEL', 'MSDB',
                                                  'ReportServer',
                                                  'ReportServerTempDB',
                                                  'distribution' )


            END


   
    END