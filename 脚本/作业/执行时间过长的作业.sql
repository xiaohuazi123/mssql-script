-- =============================================
-- Create date: <2014/4/18>
-- Description: 查询执行时间过长的作业
-- =============================================

use msdb
GO

SELECT sj.name
   , sja.start_execution_date,DATEDIFF (SECOND ,sja.start_execution_date,GETDATE() ) AS ExecutedMin,ja.AvgRuntimeOnSucceed
FROM msdb.dbo.sysjobactivity AS sja
INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id INNER
join
(
    SELECT job_id,
    AVG
    ((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100)
    +
    NULLIF(0,STDEV
    ((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100)) AS 'AvgRuntimeOnSucceed'
     FROM msdb.dbo.sysjobhistory
    WHERE step_id = 0 AND run_status = 1
    GROUP BY job_id) ja 
    ON sj.job_id = ja.job_id
WHERE sja.start_execution_date IS NOT NULL --作业有开始
   AND sja.stop_execution_date IS NULL --作业没结束
   AND sja.start_execution_date>DATEADD(DAY,-2,GETDATE()) --作业2天内开始
  -- AND DATEDIFF (SECOND ,sja.start_execution_date,GETDATE() )>ja.AvgRuntimeOnSucceed *1.5 --作业执行时间比历史平均时间超了50%"