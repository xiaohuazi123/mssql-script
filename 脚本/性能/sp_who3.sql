
-- =============================================
-- Create date: <2014/4/18>
-- Description:sp_who3存储过程，查看当前数据库性能情况 http://sqlserverplanet.com/dba/a-better-sp_who2-using-dmvs-sp_who3
-- =============================================



use master
go

CREATE PROCEDURE [dbo].[sp_who3] 

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
    SPID                = er.session_id
    ,BlkBy              = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
    ,ElapsedMS          = er.total_elapsed_time
    ,CPU                = er.cpu_time
    ,IOReads            = er.logical_reads + er.reads
    ,IOWrites           = er.writes     
    ,Executions         = ec.execution_count  
    ,CommandType        = er.command         
    ,LastWaitType       = er.last_wait_type    
    ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)  
    ,SQLStatement       =
        SUBSTRING
        (
            qt.text,
            er.statement_start_offset/2,
            (CASE WHEN er.statement_end_offset = -1
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
                ELSE er.statement_end_offset
                END - er.statement_start_offset)/2
        )        
    ,STATUS             = ses.STATUS
    ,[Login]            = ses.login_name
    ,Host               = ses.host_name
    ,DBName             = DB_Name(er.database_id)
    ,StartTime          = er.start_time
    ,Protocol           = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'Read Uncommitted'
            WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads
    ,ClientAddress      = con.client_net_address
    ,Authentication     = con.auth_scheme
    ,DatetimeSnapshot   = GETDATE()
    ,plan_handle        = er.plan_handle
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
ON con.session_id = ses.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY 
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
OUTER APPLY
(
    SELECT
        lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses)
    AND sp.blocked = 0
    AND sp.spid = er.session_id
) lb
WHERE er.sql_handle IS NOT NULL
AND er.session_id != @@SPID
ORDER BY
    CASE WHEN lead_blocker = 1 THEN -1 * 1000 ELSE -er.blocking_session_id END,
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id

END