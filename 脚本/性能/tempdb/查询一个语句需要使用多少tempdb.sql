
-- =============================================
-- Create date: <2014/4/18>
-- Description: 使用tempdb空间最多的语句
-- =============================================

DECLARE @read   BIGINT, 
        @write  BIGINT
;        
SELECT  @read = SUM(num_of_bytes_read), 
        @write = SUM(num_of_bytes_written) 
FROM    tempdb.sys.database_files AS DBF
JOIN    sys.dm_io_virtual_file_stats(2, NULL) AS FS
        ON FS.file_id = DBF.file_id
WHERE   DBF.type_desc = 'ROWS'

--这里放入需要测量的语句

SELECT  tempdb_read_MB = (SUM(num_of_bytes_read) - @read) / 1024. / 1024., 
        tempdb_write_MB = (SUM(num_of_bytes_written) - @write) / 1024. / 1024.,
        internal_use_MB = 
            (
            SELECT  internal_objects_alloc_page_count / 128.0
            FROM    sys.dm_db_task_space_usage
            WHERE   session_id = @@SPID
            )
FROM    tempdb.sys.database_files AS DBF
JOIN    sys.dm_io_virtual_file_stats(2, NULL) AS FS
        ON FS.file_id = DBF.file_id
WHERE   DBF.type_desc = 'ROWS'