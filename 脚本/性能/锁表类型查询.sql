-- =============================================
-- Create date: <2014/4/18>
-- Description: 锁表类型查询
-- =============================================

use dbname  --★Do 要查询锁表类型的数据库
go

select request_session_id sessionid,
resource_type type,
convert(varchar(20), db_name(resource_database_id)) as db_name,
OBJECT_NAME(resource_associated_entity_id, resource_database_id) objectname,
request_mode rmode,
request_status rstatus
from sys.dm_tran_locks
where resource_type in ('OBJECT')