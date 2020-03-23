
-- =============================================
-- Create date: <2014/4/18>
-- Description: 批量KILL掉数据库的所有连接
-- =============================================



DECLARE @SQL NVARCHAR(MAX)
DECLARE @SPID NVARCHAR(100)


DECLARE CurDBName CURSOR
FOR
    SELECT  [spid]
    FROM    sys.sysprocesses WHERE [spid]>=50 
    AND   DB_NAME(DBID) LIKE '%dbname%'  --★Do 要kill连接的数据库

OPEN CurDBName
FETCH NEXT FROM CurDBName INTO @SPID

WHILE @@FETCH_STATUS = 0
    BEGIN  
        --kill process
        SET @SQL = N'kill '+@SPID
        EXEC (@SQL)

        FETCH NEXT FROM CurDBName INTO @SPID
    END
CLOSE CurDBName
DEALLOCATE CurDBName
