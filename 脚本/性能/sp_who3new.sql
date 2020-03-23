
-- =============================================
-- Create date: <2014/4/18>
-- Description:sp_who3new存储过程，查看当前数据库性能情况 http://sqlserverplanet.com/dba/a-better-sp_who2-using-dmvs-sp_who3
-- =============================================

use master
go
--sp_who3_new

IF OBJECT_ID('master.dbo.sp_who3') IS NOT NULL
BEGIN
	
	drop proc [dbo].[sp_who3]
END 
GO




CREATE PROCEDURE [dbo].[sp_who3] 

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT   SPID = er.session_id ,
         BlkBy = CASE WHEN lead_blocker = 1 THEN -1
                      ELSE er.blocking_session_id
                 END ,
         LastWaitType = er.last_wait_type ,
         ObjectName = OBJECT_SCHEMA_NAME(qt.objectid, qt.dbid) + '.'
                      + OBJECT_NAME(qt.objectid, qt.dbid) ,
         SPIDSQLStatement = SUBSTRING(
                                qt.text ,
                                er.statement_start_offset / 2,
                                ( CASE WHEN er.statement_end_offset = -1 THEN
                                           LEN(CONVERT(NVARCHAR(MAX), qt.text))
                                           * 2
                                       ELSE er.statement_end_offset
                                  END - er.statement_start_offset ) / 2) ,
		 BlockbyObjectName = ( CASE WHEN er.blocking_session_id <> 0
                                      AND er.blocking_session_id <> er.session_id
                                      AND er.blocking_session_id <> @@SPID THEN
                                 (   SELECT OBJECT_SCHEMA_NAME(est2.objectid, est2.dbid) + '.'+ OBJECT_NAME(est2.objectid, est2.dbid)
                                     FROM   sys.dm_exec_requests er2
                                            CROSS APPLY sys.dm_exec_sql_text(er2.plan_handle) AS est2
                                     WHERE  [er2].[session_id] = er.blocking_session_id )
                                 ELSE ''  END ) ,
         BlockbySQLText = ( CASE WHEN er.blocking_session_id <> 0
                                      AND er.blocking_session_id <> er.session_id
                                      AND er.blocking_session_id <> @@SPID THEN
                                 (   SELECT SUBSTRING(est2.[text] , er.statement_start_offset / 2,
                                                ( CASE WHEN er.statement_end_offset = -1 THEN
                                                           LEN(CONVERT(NVARCHAR(MAX) ,est2.[text])) * 2
                                                       ELSE  er.statement_end_offset
                                                  END  - er.statement_start_offset )/ 2)
                                     FROM   sys.dm_exec_requests er2
                                            CROSS APPLY sys.dm_exec_sql_text(er2.plan_handle) AS est2
                                     WHERE  [er2].[session_id] = er.blocking_session_id )
                                 ELSE ''  END ) ,
         STATUS = ses.status ,
         [Login] = ses.login_name ,
         Host = ses.host_name ,
         DBName = DB_NAME(er.database_id) ,
         StartTime = er.start_time ,
         Protocol = con.net_transport ,
         transaction_isolation = CASE ses.transaction_isolation_level
                                      WHEN 0 THEN 'Unspecified'
                                      WHEN 1 THEN 'Read Uncommitted'
                                      WHEN 2 THEN 'Read Committed'
                                      WHEN 3 THEN 'Repeatable'
                                      WHEN 4 THEN 'Serializable'
                                      WHEN 5 THEN 'Snapshot'
                                 END ,
         ConnectionWrites = con.num_writes ,
         ConnectionReads = con.num_reads ,
         ClientAddress = con.client_net_address ,
         Authentication = con.auth_scheme ,
         DatetimeSnapshot = GETDATE() ,
         plan_handle = er.plan_handle
FROM     sys.dm_exec_requests er
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
WHERE    er.sql_handle IS NOT NULL
         AND er.session_id != @@SPID
ORDER BY CASE WHEN lead_blocker = 1 THEN -1 * 1000
              ELSE -er.blocking_session_id
         END ,
         er.blocking_session_id DESC ,
         er.logical_reads + er.reads DESC ,
         er.session_id;
		 
		 
END