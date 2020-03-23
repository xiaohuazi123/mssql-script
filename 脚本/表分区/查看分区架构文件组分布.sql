-- =============================================
-- Create date: <2019/4/18>
-- Description: 查看分区架构文件组分布
-- =============================================



use DBNAME
GO

SELECT  CONVERT(VARCHAR(MAX), ps.name) AS partition_scheme ,
        p.partition_number ,
        CONVERT(VARCHAR(MAX), ds2.name) AS filegroup ,
        CONVERT(VARCHAR(MAX), ISNULL(v.value, ''), 120) AS range_boundary ,
        STR(p.rows, 9) AS rows
FROM    sys.indexes i
        JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
        JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id
        JOIN sys.data_spaces ds2 ON dds.data_space_id = ds2.data_space_id
        JOIN sys.partitions p ON dds.destination_id = p.partition_number
                                 AND p.object_id = i.object_id
                                 AND p.index_id = i.index_id
        JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
        LEFT JOIN sys.Partition_Range_values v ON pf.function_id = v.function_id
                                                  AND v.boundary_id = p.partition_number
                                                  - pf.boundary_value_on_right
WHERE   i.object_id = OBJECT_ID('tablename')  --tablename
        AND i.index_id IN ( 0, 1 )
ORDER BY p.partition_number

