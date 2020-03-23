-- =============================================
-- Create date: <2014/4/18>
-- Description: 删除分区方案模板，用时间戳来分区，统一使用UTC时间
-- =============================================



DECLARE @begin INT --开始值
DECLARE @end INT --结束值
DECLARE @add INT --分区分段值增量
DECLARE @next_time DATETIME 
DECLARE @utc_time DATETIME
DECLARE @sql NVARCHAR(max)
SET @begin = 1588262400 --填写开始删的时间戳-例如5月份的时间戳是1588262400=2020-05-01 00:00:00.000
SET @end = 1593532800 --填写结束的时间戳-例如最后的日期是7月份的时间戳1593532800=2020-07-01 00:00:00.000
SET @add = 0 --分区长度
set @utc_time='1970-01-01'

DECLARE @FunValueStr NVARCHAR(MAX) 
WHILE (@begin<@end)
BEGIN
	-- 时间计算
	set @next_time=dateadd(mm,1,dateadd(hh,8,dateadd(ss,@begin,@utc_time))) --一个月一个分区，得出下一个月的月份时间
	set @add=datediff(ss, @utc_time,dateadd(hh,-8,@next_time))-@begin  --得出月份 转换后的时间戳值
	
	SET @FunValueStr = convert(NVARCHAR(50),(@begin+@add))   --本月+下一个月秒数
	SET @sql = 'ALTER PARTITION FUNCTION [Fun_Archive_Id]() MERGE RANGE('+@FunValueStr+')'
	PRINT @sql
	PRINT ('GO')
	PRINT CHAR(13)
	SET @begin=@begin+@add
END

