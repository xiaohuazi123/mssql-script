
-- =============================================
-- Create date: <2016/9/18>
-- Description: 彻底清除镜像环境
-- =============================================
USE master;
GO



--删除镜像端点
select * from sys.endpoints
drop endpoint Endpoint_Mirroring

-- 删除镜像证书
select * from sys.certificates
drop certificate HOST_A_cert
drop certificate HOST_B_cert

--删除master key
select * from sys.symmetric_keys
drop master key

--删除登陆名
select * from sys.syslogins
drop login HOST_B_login

--删除登陆用户
select * from sys.sysusers
--drop user HOST_A_user
drop user HOST_B_user


--删除镜像
alter database <dbname> set partner off

--修改数据库还原类型（norecovery 一直等待还原）
restore database <dbname> with recovery










