


-- =============================================
-- Create date: <2014/4/18>
-- Description: KILL掉某个数据库的所有连接
-- =============================================

DECLARE @DBNAME NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @SPID NVARCHAR(100)

SET @DBNAME='dbname'  --★Do 要kill掉连接的数据库名


DECLARE CurDBName CURSOR
FOR
    SELECT  [spid]
    FROM    sys.sysprocesses WHERE [spid]>=50 
    AND   DBID =DB_ID(@DBNAME)

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
