

-- =============================================
-- Create date: <2020/7/18>
-- Description: 批量还原指定目录下的所有备份文件
-- =============================================



USE [master];
GO
DECLARE @BackupDir NVARCHAR(500) = N'S:\MSSQL\Backup';  --★Do  指定需要还原数据库的目录
DECLARE @FileName NVARCHAR(500);
DECLARE @Sql NVARCHAR(MAX);
DECLARE @BaseDir NVARCHAR(500) = CASE WHEN RIGHT(@BackupDir, 1) = '\' THEN @BackupDir ELSE @BackupDir + '\' END;


-- 1. 创建临时表存储文件列表
CREATE TABLE #FileList (FileName NVARCHAR(500), depth INT, [file] INT);
INSERT INTO #FileList EXEC master.sys.xp_dirtree @BackupDir, 1, 1;

-- 2. 使用游标遍历后缀为 .bak 的文件
DECLARE file_cur CURSOR FOR  SELECT FileName FROM #FileList WHERE FileName LIKE '%.bak' or FileName LIKE '%.BAK';
OPEN file_cur;
FETCH NEXT FROM file_cur INTO @FileName;

WHILE @@FETCH_STATUS = 0
BEGIN
	    --还原单个数据库
        DECLARE @BackupFilePath NVARCHAR(1000) = @BaseDir + @FileName;

		DECLARE @Header TABLE (
			BackupName NVARCHAR(128),
			BackupDescription NVARCHAR(255),
			BackupType SMALLINT,
			ExpirationDate DATETIME,
			Compressed BIT,
			Position SMALLINT,
			DeviceType TINYINT,
			UserName NVARCHAR(128),
			ServerName NVARCHAR(128),
			DatabaseName NVARCHAR(128),
			DatabaseVersion INT,
			DatabaseCreationDate DATETIME,
			BackupSize BIGINT,
			FirstLSN    numeric(25,0),          
			LastLSN     numeric(25,0),          
			CheckpointLSN   numeric(25,0),      
			DatabaseBackupLSN   numeric(25,0),  
			BackupStartDate DATETIME,
			BackupFinishDate DATETIME,
			SortOrder SMALLINT,
			CodePage SMALLINT,
			UnicodeLocaleId INT,
			UnicodeComparisonStyle INT,
			CompatibilityLevel TINYINT,
			SoftwareVendorId INT,
			SoftwareVersionMajor INT,
			SoftwareMinorVersion INT,
			SoftwareVersionBuild int,
			MachineName nvarchar(128),
			Flags int,
			BindingID   uniqueidentifier,       
			RecoveryForkID  uniqueidentifier,   
			Collation   nvarchar(128),          
			FamilyGUID  uniqueidentifier,       
			HasBulkLoggedData   bit,            
			IsSnapshot  bit,                
			IsReadOnly  bit,                
			IsSingleUser    bit,            
			HasBackupChecksums  bit,        
			IsDamaged   bit,                
			BeginsLogChain  bit,            
			HasIncompleteMetaData   bit,    
			IsForceOffline  bit,            
			IsCopyOnly  bit,                
			FirstRecoveryForkID     uniqueidentifier,   
			ForkPointLSN    numeric(25,0),              
			RecoveryModel   nvarchar(60),               
			DifferentialBaseLSN     numeric(25,0),  
			DifferentialBaseGUID    uniqueidentifier,   
			BackupTypeDescription   nvarchar(60),       
			BackupSetGUID   uniqueidentifier,       
			CompressedBackupSize    bigint,         
			Containment             tinyint,
			KeyAlgorithm            nvarchar(32),               
			EncryptorThumbprint     varbinary(20),      
			EncryptorType           nvarchar(32),               
			LastValidRestoreTime    datetime NULL,          
			TimeZone                nvarchar(32) NULL,       
			CompressionAlgorithm    nvarchar(32) NULL        
		);

		INSERT INTO @Header
		EXEC('RESTORE HEADERONLY FROM DISK = ''' + @BackupFilePath + '''');
        --获取数据库名
		DECLARE @TargetDbName SYSNAME;
		SELECT TOP 1 @TargetDbName = DatabaseName FROM @Header;

		DECLARE @FinalSQL NVARCHAR(MAX);
		
        --拼接还原语句
		SET @FinalSQL = 'USE [master];' + CHAR(13) ;
		SET @FinalSQL = @FinalSQL + 'RESTORE DATABASE [' + @TargetDbName + ']' + CHAR(32);
		SET @FinalSQL = @FinalSQL + 'FROM DISK = N''' + @BackupFilePath + '''' + CHAR(32);
		SET @FinalSQL = @FinalSQL + 'WITH FILE = 1,' + CHAR(32);
		SET @FinalSQL = @FinalSQL + ' REPLACE, STATS = 5, NOUNLOAD' + CHAR(10);

		-- 输出
		print(@FinalSQL)
		
		---- 执行
		--exec(@FinalSQL)

    FETCH NEXT FROM file_cur INTO @FileName;
END

CLOSE file_cur;
DEALLOCATE file_cur;
DROP TABLE #FileList;






