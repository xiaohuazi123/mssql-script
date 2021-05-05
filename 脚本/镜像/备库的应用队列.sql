

-- =============================================
-- Create date: <2014/4/18>
-- Description: 备库的应用redo log的队列长度
-- =============================================

BEGIN TRAN
DECLARE @value INT
DECLARE @value2 INT
SELECT  @value = CONVERT(INT, cntr_value)
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Redo Queue KB'
        AND instance_name = '***'

WAITFOR DELAY '00:00:01'

SELECT  @value2 = CONVERT(INT, cntr_value)
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Redo Queue KB'
        AND instance_name = '***';

SELECT  @value * 1. / 1024 AS first_second_MB ,
        @value2 * 1. / 1024 AS second_second_MB ,
        ( @value2 - @value ) * 1. / 1024 AS diff_MB

COMMIT TRAN