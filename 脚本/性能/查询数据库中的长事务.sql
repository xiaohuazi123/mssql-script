

-- =============================================
-- Create date: <2014/4/18>
-- Description: 查询数据库中的长事务
-- =============================================


SELECT  b.[session_id] , 
        b.[open_transaction_count],
		b.[total_elapsed_time],
        a.[name] AS 'transaction_name',
        b.[command] ,
        a.[transaction_begin_time] ,
        b.[blocking_session_id] ,
        DB_NAME(b.[database_id]) AS 'current_dbname'
FROM    sys.[dm_tran_active_transactions] AS a
        INNER JOIN sys.[dm_exec_requests] AS b ON a.[transaction_id] = b.[transaction_id]
		WHERE [b].[database_id]=DB_ID()


