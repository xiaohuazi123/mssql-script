-- =============================================
-- Create date: <2014/4/18>
-- Description: 查询备份文件信息，备份文件为：bak 或 trn
-- =============================================


declare @DbBackFile nvarchar(4000)
set @DbBackFile=N'D:\文件备份\databases\testDB_log.trn' 

RESTORE LABELONLY
FROM DISK = @DbBackFile

RESTORE HEADERONLY
FROM DISK = @DbBackFile

RESTORE FILELISTONLY
FROM DISK = @DbBackFile
WITH FILE = 1