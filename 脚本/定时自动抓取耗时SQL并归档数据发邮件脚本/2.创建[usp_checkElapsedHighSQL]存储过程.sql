USE [MonitorElapsedHighSQL]
GO
/****** Object:  StoredProcedure [dbo].[usp_checkElapsedHighSQL]    Script Date: 2015/6/23 17:16:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--创建存储过程
CREATE  PROCEDURE [dbo].[usp_checkElapsedHighSQL] ( @SessionID INT )
AS
    BEGIN

        IF  ( SELECT  OBJECT_ID('MonitorElapsedHighSQL.dbo.ElapsedHigh') ) IS NULL
            BEGIN
                 CREATE TABLE [MonitorElapsedHighSQL].[dbo].[ElapsedHigh]
                    (
                      id INT IDENTITY(1, 1)   PRIMARY KEY ,
                      [SPID] SMALLINT ,
                      [ElapsedMS] INT ,
                      [IOReads] BIGINT ,
                      [IOWrites] BIGINT ,
                      [DBName] NVARCHAR(128) ,
                      [plan_handle] VARBINARY(64) ,
                      [paramlist] NVARCHAR(MAX) ,
                      [planstmttext] NVARCHAR(MAX) ,
                      [stmttext] NVARCHAR(MAX) ,
                      [xmlplan] XML,
                      [gettime] DATETIME
                    )

                CREATE INDEX [Idx_ElapsedHigh_ElapsedMS] ON [MonitorElapsedHighSQL].[dbo].[ElapsedHigh]([ElapsedMS])
                CREATE INDEX [Idx_ElapsedHigh_IOReads] ON [MonitorElapsedHighSQL].[dbo].[ElapsedHigh]([IOReads])
                 
            END

        IF  ( SELECT  OBJECT_ID('MonitorElapsedHighSQL.dbo.ElapsedHigh') ) IS NOT NULL
            BEGIN
        
                SET NOCOUNT ON 

                SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

                DECLARE @Duration INT -- in milliseconds, 10000 = 10 sec
                DECLARE @now DATETIME
                DECLARE @plan_handle VARBINARY(64)
                DECLARE @ElapsedMS INT
                DECLARE @SPID INT
                DECLARE @IOReads BIGINT
                DECLARE @IOWrites BIGINT
                DECLARE @DBName NVARCHAR(128)
                DECLARE @planstmttext NVARCHAR(MAX)
                DECLARE @stmttext NVARCHAR(MAX)
                DECLARE @paramlist NVARCHAR(MAX)
                DECLARE @plan_xml XML
                DECLARE @paramtb TABLE
                    (
                      paramlist NVARCHAR(MAX) ,
                      planstmttext NVARCHAR(MAX)
                    )
                DECLARE @paramtb2 TABLE
                    (
                      paramlist NVARCHAR(MAX) ,
                      planstmttext NVARCHAR(MAX)
                    )

                SELECT  @Duration = 10000  --★Do -- in milliseconds, 10000 = 10 sec



                IF OBJECT_ID('tempdb..#ElapsedHigh') IS NOT NULL
                    BEGIN
                        DROP TABLE [#ElapsedHigh]  --删除临时表  
                    END 


--建临时表
                CREATE TABLE [#ElapsedHigh]
                    (
                      [SPID] SMALLINT ,
                      [BlkBy] INT ,
                      [ElapsedMS] INT ,
                      [CPU] INT ,
                      [IOReads] BIGINT ,
                      [IOWrites] BIGINT ,
                      [Executions] INT ,
                      [CommandType] NVARCHAR(40) ,
                      [LastWaitType] NVARCHAR(60) ,
                      [ObjectName] NVARCHAR(1000) ,
                      [SQLStatement] NVARCHAR(MAX) ,
                      [STATUS] NVARCHAR(30) ,
                      [Login] NVARCHAR(128) ,
                      [Host] NVARCHAR(128) ,
                      [DBName] NVARCHAR(128) ,
                      [StartTime] DATETIME ,
                      [Protocol] NVARCHAR(40) ,
                      [transaction_isolation] NVARCHAR(100) ,
                      [ConnectionWrites] INT ,
                      [ConnectionReads] INT ,
                      [ClientAddress] VARCHAR(48) ,
                      [AUTHENTICATION] NVARCHAR(40) ,
                      [DatetimeSnapshot] DATETIME ,
                      [plan_handle] VARBINARY(64)
                    )




--处理逻辑
                INSERT  INTO [#ElapsedHigh]
                        ( [SPID] ,
                          [BlkBy] ,
                          [ElapsedMS] ,
                          [CPU] ,
                          [IOReads] ,
                          [IOWrites] ,
                          [Executions] ,
                          [CommandType] ,
                          [LastWaitType] ,
                          [ObjectName] ,
                          [SQLStatement] ,
                          [STATUS] ,
                          [Login] ,
                          [Host] ,
                          [DBName] ,
                          [StartTime] ,
                          [Protocol] ,
                          [transaction_isolation] ,
                          [ConnectionWrites] ,
                          [ConnectionReads] ,
                          [ClientAddress] ,
                          [AUTHENTICATION] ,
                          [DatetimeSnapshot] ,
                          [plan_handle]
                        )
                        EXEC [MonitorElapsedHighSQL].[dbo].[sp_who3]

        --如果传入的是会话ID 只显示所在会话ID的信息
                IF ( @SessionID IS NOT NULL AND @SessionID <> 0 )
                    BEGIN 

                        SELECT TOP 1
                                @ElapsedMS = [ElapsedMS] ,
                                @SPID = [SPID] ,
                                @plan_handle = [plan_handle] ,
                                @IOReads = [IOReads] ,
                                @IOWrites = [IOWrites] ,
                                @DBName = [DBName]
                        FROM    [#ElapsedHigh]
                        WHERE   [#ElapsedHigh].[SPID] = @SessionID


                        SELECT  @stmttext = [text]  FROM    sys.fn_get_sql(@plan_handle)



                        BEGIN TRY
        -- convert may fail due to exceeding 128 depth limit
                            SELECT  @plan_xml = CONVERT(XML, query_plan)
                            FROM    sys.dm_exec_text_query_plan(@plan_handle, 0, -1)
                        END TRY
                        BEGIN CATCH 
                            SELECT  @plan_xml = NULL
                        END CATCH;

                        WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)
INSERT @paramtb ( [paramlist], [planstmttext] )
    SELECT 
        parameter_list.param_node.value('(./@Column)[1]', 'nvarchar(128)') +'='+ parameter_list.param_node.value('(./@ParameterCompiledValue)[1]', 'nvarchar(max)')  AS paramlist,
        ISNULL(@plan_xml.value('(//@StatementText)[1]', 'nvarchar(max)'), N'Unknown Statement') AS stmttext
    FROM (SELECT @plan_xml AS xml_showplan) AS t
        OUTER APPLY t.xml_showplan.nodes('//sp:ParameterList/sp:ColumnReference') AS parameter_list (param_node)
        
                        SELECT TOP 1
                                @SPID spid ,
                                @ElapsedMS ElapsedMS ,
                                @IOReads IOReads ,
                                @IOWrites IOReads ,
                                @DBName DBName ,
                                @plan_handle plan_handle ,
                                @plan_xml planxml,
                                @stmttext stmttext ,
                                [planstmttext] planstmttext ,
                                ( SELECT    [paramlist] + '  '
                                  FROM      @paramtb
                                  WHERE     [planstmttext] = A.[planstmttext]
                                FOR
                                  XML PATH('')
                                ) AS [paramlist]
                        FROM    @paramtb A
                        GROUP BY [planstmttext]

                    END
                ELSE
        --如果没有对存储过程传入参数，那么显示耗时最多的那条SQL的信息
                    BEGIN 

                        SELECT TOP 1
                                @ElapsedMS = [ElapsedMS] ,
                                @SPID = [SPID] ,
                                @plan_handle = [plan_handle] ,
                                @IOReads = [IOReads] ,
                                @IOWrites = [IOWrites] ,
                                @DBName = [DBName]
                        FROM    [#ElapsedHigh]
                        ORDER BY [ElapsedMS] DESC 

                        SELECT  @stmttext = [text]  FROM    sys.fn_get_sql(@plan_handle)



--抓取占用时间长的SQL
                        IF ( @ElapsedMS > @Duration )
                            BEGIN 
                                SELECT  @now = GETDATE()


                                BEGIN TRY
        -- convert may fail due to exceeding 128 depth limit
                                    SELECT  @plan_xml = CONVERT(XML, query_plan)
                                    FROM    sys.dm_exec_text_query_plan(@plan_handle,
                                                              0, -1)
                                END TRY
                                BEGIN CATCH
                                    SELECT  @plan_xml = NULL
                                END CATCH;

                                WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)
INSERT @paramtb ( [paramlist], [planstmttext] )
    SELECT 
        parameter_list.param_node.value('(./@Column)[1]', 'nvarchar(128)') +'='+ parameter_list.param_node.value('(./@ParameterCompiledValue)[1]', 'nvarchar(max)')  AS paramlist,
        ISNULL(@plan_xml.value('(//@StatementText)[1]', 'nvarchar(max)'), N'Unknown Statement') AS stmttext
    FROM (SELECT @plan_xml AS xml_showplan) AS t
        OUTER APPLY t.xml_showplan.nodes('//sp:ParameterList/sp:ColumnReference') AS parameter_list (param_node)
        

                                INSERT  @paramtb2( [planstmttext] , [paramlist])
                                        SELECT TOP 1
                                                [planstmttext] ,
                                                ( SELECT    [paramlist] + '  '
                                                  FROM      @paramtb
                                                  WHERE     [planstmttext] = A.[planstmttext]
                                                FOR
                                                  XML PATH('')
                                                ) AS [paramlist]
                                        FROM    @paramtb A
                                        GROUP BY [planstmttext]


                                SELECT TOP 1
                                        @planstmttext = [planstmttext] ,
                                        @paramlist = [paramlist]
                                FROM    @paramtb2

                                INSERT  INTO [MonitorElapsedHighSQL].[dbo].[ElapsedHigh]
                                        ( [SPID] ,
                                          [ElapsedMS] ,
                                          [IOReads] ,
                                          [IOWrites] ,
                                          [DBName] ,
                                          [plan_handle] ,
                                          [paramlist] ,
                                          [stmttext] ,
                                          [planstmttext] ,
                                          [xmlplan],
                                          [gettime]
                                        )
                                VALUES  ( @SPID , -- SPID - smallint
                                          @ElapsedMS , -- ElapsedMS - int
                                          @IOReads , -- IOReads - bigint
                                          @IOWrites , -- IOWrites - bigint
                                          @DBName , -- DBName - nvarchar(128)
                                          @plan_handle , -- plan_handle - varbinary(64)
                                          @paramlist , -- paramlist - nvarchar(max)
                                          @stmttext , -- stmttext - nvarchar(max)
                                          @planstmttext , -- planstmttext - nvarchar(max)
                                          @plan_xml ,  --plan_xml - xml
                                          @now  -- gettime - datetime
                                        )

                            END 
                    END

            END

    END