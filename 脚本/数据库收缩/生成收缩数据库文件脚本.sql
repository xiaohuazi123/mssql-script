
-- =============================================
-- Create date: <2014/4/18>
-- Description: 自动生成收缩数据库文件脚本
-- =============================================


USE [dbname]   --★Do 设置要收缩的数据库
GO
SET nocount ON
CREATE TABLE #Data
    (
      ID BIGINT IDENTITY(1, 1) ,
      DBNAME NVARCHAR(30) ,
      FileID BIGINT NOT NULL ,
      [FileGroupId] BIGINT NOT NULL ,
      TotalExtents BIGINT NOT NULL ,
      UsedExtents BIGINT NOT NULL ,
      [FileName] SYSNAME NOT NULL ,
      [FilePath] NVARCHAR(MAX) NOT NULL ,
      [FileGroup] NVARCHAR(MAX) NULL
    )

INSERT  #Data
        ( FileID ,
          [FileGroupId] ,
          TotalExtents ,
          UsedExtents ,
          [FileName] ,
          [FilePath]
        )
        EXEC ( 'DBCC showfilestats WITH NO_INFOMSGS')

UPDATE  #Data
SET     #Data.FileGroup = sysfilegroups.groupname ,
        [#Data].[DBNAME] = DB_NAME()
FROM    #Data ,
        sysfilegroups
WHERE   #Data.FileGroupId = sysfilegroups.groupid

SELECT  ID ,
        DBNAME ,
        [FileGroup] ,
        'Data' FileType ,
        [FileName] ,
        TotalExtents * 64. / 1024 TotalMB ,
        UsedExtents * 64. / 1024 UsedMB ,
        [FilePath] ,
        FileID
FROM    #Data
ORDER BY [ID]



DECLARE @i BIGINT   --用于循环
SET @i = 1
DECLARE @dbname NVARCHAR(100)
DECLARE @filegroup NVARCHAR(200)
DECLARE @filename NVARCHAR(200)
DECLARE @fileid NVARCHAR(10)
DECLARE @totalMB DECIMAL(20, 1)   --总大小
DECLARE @UsedMB DECIMAL(20, 1)    --已使用大小
DECLARE @CanshrinkSizeStr NVARCHAR(100)   --可收缩到的大小

DECLARE @COUNT BIGINT    --保存#Data表的总行数值


SELECT  @COUNT = COUNT(*)  --获取#Data表的总行数
FROM    #Data

SELECT TOP 1     @dbname = [DBNAME]
FROM    [#Data] 
PRINT 'USE [' + @dbname+']'
PRINT 'GO'
WHILE @i <= @COUNT
    BEGIN
        SELECT  @filegroup = [FileGroup] ,
                @filename = [FileName] ,
                @fileid = [FileID] ,
                @totalMB = TotalExtents * 64. / 1024 ,
                @UsedMB = UsedExtents * 64. / 1024
        FROM    #Data
        WHERE   [ID] = @i
        PRINT '--文件组:' + @filegroup + ';文件id:' + @fileid + ';总大小:'
            + CAST(@totalMB AS VARCHAR(100)) + 'MB;已使用大小:'
            + CAST(@UsedMB AS VARCHAR(100)) + 'MB;'
			
			
        DECLARE @UsedMBINT  BIGINT 
		SET @UsedMBINT = CAST(@UsedMB  AS BIGINT)   
		
		DECLARE @CanshrinkSize BIGINT  --用于循环
		SET @CanshrinkSize =  CAST(@totalMB AS BIGINT)
		
        
		WHILE @CanshrinkSize > @UsedMBINT   --循环收缩，直到小于已使用大小为止
            BEGIN
				    SET @CanshrinkSize = @CanshrinkSize - 10240  --循环收缩，每次收缩10GB
				    IF  @CanshrinkSize > @UsedMBINT 
				    BEGIN
					    SET @CanshrinkSizeStr = CAST(@CanshrinkSize  AS NVARCHAR(100))
                        PRINT 'DBCC SHRINKFILE ([' + @filename + '],' + @CanshrinkSizeStr + ') WITH WAIT_AT_LOW_PRIORITY (ABORT_AFTER_WAIT = SELF);'+ '    --每次收缩10GB，WAIT_AT_LOW_PRIORITY为SQL2022新增参数' 
				        PRINT 'GO'			
				    END
		    END
		 
		--SET @CanshrinkSizeStr = CAST(CAST(@UsedMB + 1024 AS BIGINT) AS NVARCHAR(100))
        --PRINT 'DBCC SHRINKFILE ([' + @filename + '],' + @CanshrinkSizeStr + ') WITH WAIT_AT_LOW_PRIORITY (ABORT_AFTER_WAIT = SELF);'   + '   --可收缩到的值为已使用的大小加1G' + CHAR(10)
        SET @i = @i + 1
		PRINT CHAR(10)	

    END

DROP TABLE #Data




