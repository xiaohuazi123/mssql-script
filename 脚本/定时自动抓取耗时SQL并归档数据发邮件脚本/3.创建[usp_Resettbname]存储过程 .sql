USE [MonitorElapsedHighSQL]
GO
--重设ElapsedHigh表名，进行归档
CREATE  PROCEDURE [dbo].[usp_Resettbname]
AS
    BEGIN
       
         IF EXISTS ( SELECT  OBJECT_ID('MonitorElapsedHighSQL.dbo.ElapsedHigh') )
            BEGIN
               --kill掉数据库所有连接
                DECLARE @DBNAME NVARCHAR(100)
                DECLARE @SQL NVARCHAR(MAX)
                DECLARE @SPID NVARCHAR(100)
                DECLARE @OwnSPID NVARCHAR(100)
                DECLARE @TBNAME NVARCHAR(1000)

                SELECT  @OwnSPID = @@SPID
                SET @DBNAME = 'MonitorElapsedHighSQL'  


                DECLARE CurDBName CURSOR
                FOR
                    SELECT  [spid]
                    FROM    sys.sysprocesses
                    WHERE   [spid] >= 50
                            AND DBID = DB_ID(@DBNAME)

                OPEN CurDBName
                FETCH NEXT FROM CurDBName INTO @SPID

                WHILE @@FETCH_STATUS = 0
                    BEGIN  
        --kill process 不kill掉本存储过程的spid
                        IF ( @SPID <> @OwnSPID )
                            BEGIN
                                SET @SQL = N'kill ' + @SPID
                                EXEC (@SQL)
                            END 

                        FETCH NEXT FROM CurDBName INTO @SPID
                    END
                CLOSE CurDBName
                DEALLOCATE CurDBName

                SET @TBNAME='ElapsedHigh'+CONVERT(NVARCHAR(200), GETDATE(), 112) 

                EXEC sys.[sp_rename] @objname = N'ElapsedHigh', -- nvarchar(1035)
                    @newname =@TBNAME    -- sysname

                

            END
 

    END