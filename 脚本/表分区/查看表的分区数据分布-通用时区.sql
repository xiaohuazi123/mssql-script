USE [master]
GO
/****** Object:  StoredProcedure [dbo].[View_Partition]    Script Date: 2021/8/5 12:00:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<华仔>
-- Create date: <2019-12-02>
-- Description:	<View_Partition查看某个表的分区数据分布>
-- exec:        <[dbo].[View_Partition] @DBNAME=gposdb,@TABLE=mail>
-- =============================================
CREATE PROCEDURE [dbo].[View_Partition]
    -- Add the parameters for the stored procedure here
    @DBNAME NVARCHAR(32),
    @TABLE NVARCHAR(32)
AS
BEGIN
    DECLARE @UtcDate DATETIME;
    DECLARE @SQL NVARCHAR(MAX);
    set @UtcDate= dateadd(mi,datediff(mi,GetUtcDate(),GetDate()),'1970-01-01')
    SET @SQL = N'USE [' + @DBNAME + '];' + CHAR(10);
    SET @SQL
        = @SQL
          + 'SELECT p.partition_number,
           ps.[name] AS partition_scheme,
           pf.[name] AS partition_function,
           ds2.[name] AS [filegroup],
           CONVERT(VARCHAR(32), ISNULL(V.VALUE,''''), 120) AS range_boundary, 
           DATEADD(ss, CAST(v.value AS BIGINT), '''+CONVERT(varchar(1000), @UtcDate, 120)+''') AS range_boundary,
           STR(p.rows, 13) AS [rows]
    FROM sys.indexes i
        JOIN sys.partition_schemes ps
            ON i.data_space_id = ps.data_space_id
        JOIN sys.destination_data_spaces dds
            ON ps.data_space_id = dds.partition_scheme_id
        JOIN sys.data_spaces ds2
            ON dds.data_space_id = ds2.data_space_id
        JOIN sys.partitions p
            ON dds.destination_id = p.partition_number
               AND p.object_id = i.object_id
               AND p.index_id = i.index_id
        JOIN sys.partition_functions pf
            ON ps.function_id = pf.function_id
        LEFT JOIN sys.partition_range_values v
            ON pf.function_id = v.function_id
               AND v.boundary_id = p.partition_number - pf.boundary_value_on_right
    WHERE i.object_id = OBJECT_ID(''[dbo].' + @TABLE
          + ''') 
          AND i.index_id IN ( 0, 1 )
    ORDER BY p.partition_number;';
    EXEC (@SQL);
END;






