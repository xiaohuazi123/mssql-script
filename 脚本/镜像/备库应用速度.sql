


-- =============================================
-- Create date: <2014/4/18>
-- Description: 备库的应用速度
-- =============================================


BEGIN TRAN
DECLARE @value BIGINT
DECLARE @value2 BIGINT
SELECT  @value = CONVERT

(BIGINT, cntr_value) * 1. / 1024 / 1024
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Redo Bytes/sec'
        AND instance_name = '***';

WAITFOR DELAY '00:00:01'

SELECT  @value2 = CONVERT(BIGINT, cntr_value) * 1. / 1024 / 1024
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Redo Bytes/sec'
        AND instance_name = '******scard';

SELECT  ( @value2 - @value ) AS speed_MB

COMMIT TRAN