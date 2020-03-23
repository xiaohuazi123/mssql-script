
-- =============================================
-- Create date: <2014/4/18>
-- Description: 查看等待类型
-- =============================================



SELECT wait_type,COUNT(1) FROM sys.dm_exec_requests
GROUP BY wait_type
ORDER BY COUNT(1) DESC