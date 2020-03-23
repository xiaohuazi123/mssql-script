


-- =============================================
-- Create date: <2014/4/18>
-- Description: KILL掉所有数据库的阻塞源头
-- =============================================

DECLARE @DBNAME NVARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SPID NVARCHAR(100);



DECLARE CurDBName CURSOR FOR
    SELECT SPID = er.session_id
    FROM   sys.dm_exec_requests er
           LEFT JOIN sys.dm_exec_sessions ses ON ses.session_id = er.session_id
           LEFT JOIN sys.dm_exec_connections con ON con.session_id = ses.session_id
           OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
           OUTER APPLY (   SELECT execution_count = MAX(cp.usecounts)
                           FROM   sys.dm_exec_cached_plans cp
                           WHERE  cp.plan_handle = er.plan_handle ) ec
           OUTER APPLY (   SELECT lead_blocker = 1
                           FROM   master.dbo.sysprocesses sp
                           WHERE  sp.spid IN (   SELECT blocked
                                                 FROM   master.dbo.sysprocesses )
                                  AND sp.blocked = 0
                                  AND sp.spid = er.session_id ) lb
    WHERE  er.sql_handle IS NOT NULL
           AND er.session_id != @@SPID
           AND lead_blocker = 1; --blkby=-1



OPEN CurDBName;
FETCH NEXT FROM CurDBName
INTO @SPID;

WHILE @@FETCH_STATUS = 0
    BEGIN
        --kill process
        SET @SQL = N'kill ' + @SPID;
        EXEC ( @SQL );

        FETCH NEXT FROM CurDBName
        INTO @SPID;
    END;
CLOSE CurDBName;
DEALLOCATE CurDBName;










