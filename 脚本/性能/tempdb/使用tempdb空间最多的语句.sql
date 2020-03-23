
-- =============================================
-- Create date: <2014/4/18>
-- Description: 查询一个语句需要使用多少tempdb空间
-- =============================================

SELECT  [ddssu].* ,
        [dest].[text]
FROM    sys.[dm_db_session_space_usage] AS ddssu
        JOIN sys.[dm_exec_requests] AS der ON [der].[database_id] = [ddssu].[database_id]
        CROSS APPLY sys.[dm_exec_sql_text]([der].[sql_handle]) AS dest
WHERE   [ddssu].[session_id] > 50
ORDER BY [ddssu].[user_objects_alloc_page_count]
        + [ddssu].[internal_objects_alloc_page_count] DESC