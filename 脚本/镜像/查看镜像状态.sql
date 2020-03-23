
-- =============================================
-- Create date: <2015/8/18>
-- Description: 查看所有镜像数据库当前状态
-- =============================================

SELECT
DB_NAME(database_id) AS DatabaseName,
dm.mirroring_role AS MirroringRole,
(CASE dm.mirroring_role
   WHEN 1 THEN '主体'
   WHEN 2 THEN '镜像'
   END) AS MirroringRoleDesc,
dm.mirroring_partner_name AS MirroringPartnerName,
(CASE WHEN dm.mirroring_witness_name IS NULL
   THEN '--'
   ELSE dm.mirroring_witness_name
END)AS MirroringWitnessName,
dm.mirroring_state AS MirroringState,
(CASE dm.mirroring_state
   WHEN 0 THEN '已挂起'
   WHEN 1 THEN '与其他伙伴断开'
   WHEN 2 THEN '正在同步'
   WHEN 3 THEN '挂起故障转移'
   WHEN 4 THEN '已同步'
   WHEN 5 THEN '伙伴未同步'
   WHEN 6 THEN '伙伴已同步'
   WHEN NULL THEN '无镜像'
END) AS MirroringStateDesc,
dm.mirroring_safety_level AS MirroringSafetyLevel,
(CASE dm.mirroring_safety_level
   WHEN 0 THEN '未知'
   WHEN 1 THEN '异步'
   WHEN 2 THEN '同步'
   WHEN NULL THEN '无镜像'
END) AS MirroringSafetyLevelDesc,
dm.mirroring_witness_state AS MirroringWitnessState,
(CASE dm.mirroring_witness_state
   WHEN 0 THEN '见证未知'
   WHEN 1 THEN '见证连接'
   WHEN 2 THEN '见证断开'
   WHEN NULL THEN '无见证'
END) AS MirroringWitnessStateDesc
FROM sys.database_mirroring dm
WHERE dm.mirroring_guid IS NOT NULL


