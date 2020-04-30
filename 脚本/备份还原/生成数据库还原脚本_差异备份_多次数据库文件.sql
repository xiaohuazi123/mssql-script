

-- =============================================
-- Create date: <2015/4/18>
-- Description: 
-- 功能：
-- 1) 先列表所有数据库的逻辑文件名、逻辑日志名和数据库名称
-- 2) 根据上面三个名字 拼接成 SQL 还原脚本
-- 3) 参数说明：
--	  @BackupRootDir	备份文件目录
--	  @MoveRootDir		数据库文件目录
--	  @IsDifferential	是否继续还原增量
--	  @IsDiffRestore	是否增量还原
--	  @IsLogRestore		是否日志还原
--	  @IsMirrorRestore	是否镜像还原，镜像还原时，默认继续增量还原 @IsDifferential = 1
--    @DBNamerestore    要还原的单个数据库的数据库名
--    @IsRestoreSingleDB是否还原单个数据库，默认还原所有数据库 @IsRestoreSingleDB = 0
--	  
-- 4) 如果处于正在恢复状态的数据库，可以使用 RESTORE LOG [数据库名] WITH RECOVERY
--	  修改成在线状态
--
-- 5) 当数据库复制新建时，需要重新命名物理文件名；
-- =============================================


-- 环境变量
SET NOCOUNT ON

DECLARE @SQL				NVARCHAR(MAX)
DECLARE @tbDatabaseFields	TABLE ([file_id] INT, [type] INT, [logical_name] SYSNAME, [physical_name] SYSNAME, [backup_name] SYSNAME)
DECLARE @tbDatabases		TABLE ([name] SYSNAME)

DECLARE @BackupRootDir		NVARCHAR(MAX)
DECLARE @MoveRootDir		NVARCHAR(MAX)

DECLARE @FileID				INT
DECLARE @Type				INT
DECLARE @DbName				SYSNAME
DECLARE @LogicalName		SYSNAME
DECLARE @PhycialName		SYSNAME
DECLARE @BackupName			SYSNAME
DECLARE @DbNamePrefix		NVARCHAR(32)
DECLARE @DBNamerestore      NVARCHAR(60)

DECLARE @IsRestoreSingleDB  INT
DECLARE @IsDifferential		BIT
DECLARE @IsDiffRestore		BIT
DECLARE @IsLogRestore		BIT
DECLARE @IsMirrorRestore	BIT

-- 初始变量，需要目录后面带分隔符： \
SET @BackupRootDir			=	N'''C:\DBBackup\'
SET @MoveRootDir			=	N'''C:\DBBackup\'

-- 初始变量
SET @DbNamePrefix			=	''

-- 是否还原单个数据库
SET @IsRestoreSingleDB		=	0

-- 要还原的单个数据库的数据库名
SET @DBNamerestore			=	N'test'

-- 是否继续还原增量: 是 1； 否 0；
SET @IsDifferential			=	0

-- 是否增量还原：是 1； 否 0；
SET @IsDiffRestore			=	0

-- 是否日志还原：是 1； 否 0；
SET @IsLogRestore			=	0

-- 是否镜像还原：是 1； 否 0；
-- 镜像还原时，默认继续增量还原 @IsDifferential = 1
SET @IsMirrorRestore		=	1


------------------------------------------------------------------------------------------------
-- 执行逻辑

-- 镜像还原时，默认继续增量还原，因为镜像数据库必须处于还原
IF @IsMirrorRestore = 1 
BEGIN
	SET @IsDifferential = 1

	PRINT '-- 镜像还原脚本'
END


IF @IsRestoreSingleDB = 1
    BEGIN
		IF NOT EXISTS (   SELECT name  FROM   sys.[databases]  WHERE  name = @DBNamerestore )
			RETURN;
		-- 单个数据库
		INSERT INTO @tbDatabases ( [name] ) SELECT   [name]     FROM     master..sysdatabases
					WHERE    [name] NOT IN ( 'master', 'tempdb', 'model', 'msdb' )
							 AND [name] = @DBNamerestore
					ORDER BY [name];
    END;
ELSE
    BEGIN
        -- 列表所有数据库
        INSERT INTO @tbDatabases ( [name] ) SELECT   [name]   FROM     master..sysdatabases
                    WHERE    [name] NOT IN ( 'master', 'tempdb', 'model', 'msdb' )
                             AND [name] LIKE @DbNamePrefix + '%'
                    ORDER BY [name];
    END;



DECLARE CUR_DbLogical_Names CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
SELECT [name] FROM @tbDatabases ORDER BY [name]

-- 查询数据库逻辑文件名
OPEN CUR_DbLogical_Names
FETCH NEXT FROM CUR_DbLogical_Names INTO @DbName
WHILE @@FETCH_STATUS=0
BEGIN
	 SET @SQL = 'USE '+@DbName+';'			  
			  + 'SELECT [file_id],  [type], [name], [physical_name], '''+@DbName+''' as backup_name '
			  + 'FROM sys.database_files'
	 INSERT @tbDatabaseFields([file_id],  [type], [logical_name], [physical_name], [backup_name])
	 EXEC (@SQL)

	FETCH NEXT FROM CUR_DbLogical_Names INTO @DbName
END
CLOSE CUR_DbLogical_Names
DEALLOCATE CUR_DbLogical_Names

/*
SELECT * FROM @tbDatabaseFields
*/

-- 生成还原脚本
SET @SQL=
	'
	USE [Master]
	GO
	'
		PRINT @SQL
		
		

-- 还原脚本
DECLARE CUR_DbLogical_Names CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
SELECT [name] FROM @tbDatabases ORDER BY [name]

-- 查询数据库逻辑文件名
OPEN CUR_DbLogical_Names
FETCH NEXT FROM CUR_DbLogical_Names INTO @DbName
WHILE @@FETCH_STATUS=0
BEGIN
	
	SET @SQL = N''
	
	IF @IsLogRestore=0
	BEGIN	
        SET @SQL = 	@SQL +'--'+@DbName+char(13)
		SET @SQL = @SQL + REPLACE( REPLACE( 'RESTORE DATABASE {dbname} FROM  DISK = {backupRootDir}{dbname}.bak'' WITH  FILE = 1, ', '{dbname}', @DbName), '{backupRootDir}',  @BackupRootDir)
	END
	
	IF @IsLogRestore=1
	BEGIN
		SET @SQL = @SQL + REPLACE( 'RESTORE LOG {dbname} WITH RECOVERY', N'{dbname}', @DbName)
	END
	
	IF @IsDiffRestore=0 AND @IsLogRestore=0
	BEGIN
	
		
		-- 物理文件名
		DECLARE Cur_Database_Files CURSOR LOCAL FORWARD_ONLY FOR
			SELECT * FROM @tbDatabaseFields WHERE [backup_name]=@DbName ORDER BY [backup_name]		
					

		OPEN Cur_Database_Files
		FETCH NEXT FROM Cur_Database_Files INTO @FileID, @Type, @LogicalName, @PhycialName, @BackupName
		WHILE @@FETCH_STATUS=0
		BEGIN		
		 
			 IF @Type=1
			 BEGIN
			      IF @IsMirrorRestore = 1 
					  BEGIN
		 				  SET @SQL = @SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' + '''' + @PhycialName + ''', '
					  END
				  ELSE
					  BEGIN
						  SET @PhycialName=REVERSE(SUBSTRING(REVERSE(@PhycialName),(CHARINDEX('fdl.',REVERSE(@PhycialName))+4),(CHARINDEX('\',REVERSE(@PhycialName)))-(CHARINDEX('fdl.',REVERSE(@PhycialName))+4)))
		 				  SET @SQL = @SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' + @MoveRootDir + @PhycialName + '.ldf'', '
					  END
			 END
			 
			 IF @Type=0
			 BEGIN
		 		IF RIGHT(@PhycialName, 3)='mdf'
		 		BEGIN
				    IF @IsMirrorRestore = 1 
					  BEGIN
		 			        SET @SQL = @SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' +  ''''  + @PhycialName + ''', '
					  END 
					ELSE
                       BEGIN
					      	SET @PhycialName=REVERSE(SUBSTRING(REVERSE(@PhycialName),(CHARINDEX('fdm.',REVERSE(@PhycialName))+4),(CHARINDEX('\',REVERSE(@PhycialName)))-(CHARINDEX('fdm.',REVERSE(@PhycialName))+4)))
		 			        SET @SQL = @SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' + @MoveRootDir + @PhycialName + '.mdf'', '
					   END
		 		END
			 	
		 		IF RIGHT(@PhycialName, 3)='ndf'
		 		BEGIN
				      IF @IsMirrorRestore = 1 
						  BEGIN
		 						SET @SQL =@SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' +  ''''  + @PhycialName + ''', '
						  END
					  ELSE
						  BEGIN
					   			SET @PhycialName=REVERSE(SUBSTRING(REVERSE(@PhycialName),(CHARINDEX('fdn.',REVERSE(@PhycialName))+4),(CHARINDEX('\',REVERSE(@PhycialName)))-(CHARINDEX('fdn.',REVERSE(@PhycialName))+4)))
		 						SET @SQL =@SQL + CHAR(10) + REPLICATE(' ', 4) + 'MOVE N''' + @LogicalName + ''' TO N' + @MoveRootDir + @PhycialName + '.ndf'', '
                      
						  END
		 		END
			 	
			 END
			
			--PRINT '1' + @LogicalName + ' ' + @PhycialName
			
			FETCH NEXT FROM Cur_Database_Files into @FileID, @Type, @LogicalName, @PhycialName, @BackupName
		END
		CLOSE Cur_Database_Files
		DEALLOCATE Cur_Database_Files
	
	END

	IF @IsLogRestore=0
	BEGIN
		
		-- 继续还原增量备份	
		IF @IsDifferential=1
		BEGIN
			SET @SQL = @SQL + ' NORECOVERY, '
		END
		
			SET @SQL = @SQL + ' NOUNLOAD,  REPLACE,  STATS = 5 '
		
	END
	
	SET @SQL = @SQL + '
go
		'


	IF @IsMirrorRestore = 1
	BEGIN
		SET @SQL = @SQL + CHAR(10)
				 + '


					RESTORE LOG {dbname} FROM  DISK = {backupRootDir}{dbname}.trn'' WITH  FILE = 1,
						NOUNLOAD, NORECOVERY,  REPLACE,  STATS = 5
					
				   '
		SET @SQL = REPLACE( REPLACE(@SQL, N'{dbname}', @DbName), N'{backupRootDir}', @BackupRootDir)
	END

	PRINT @SQL
	PRINT ''


	FETCH NEXT FROM CUR_DbLogical_Names INTO @DbName
END
CLOSE CUR_DbLogical_Names
DEALLOCATE CUR_DbLogical_Names

GO

