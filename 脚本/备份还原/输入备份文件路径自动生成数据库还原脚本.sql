





-- =============================================
-- Create date: <2019/7/18>
-- Description: 仅输入备份文件全路径，自动生成数据库还原脚本
-- 1. 仅需修改@BackupFilePath为实际备份文件路径
-- 2. 从RESTORE HEADERONLY获取数据库名，从FILELISTONLY获取文件映射
-- 3. 生成的脚本保留原物理路径，如需修改路径可调整PhysicalName拼接逻辑
-- =============================================


USE [master]
GO


-- =============================================
-- 1. 仅需输入备份文件全路径
-- =============================================
DECLARE @BackupFilePath NVARCHAR(1000) = N'D:\360Downloads\testdefault_full.bak';



-- =============================================
-- 2. 定义表变量 (只适用于SQL2022)
-- =============================================
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

DECLARE @FileList TABLE (
    LogicalName nvarchar(128),                    
    PhysicalName nvarchar(260),                   
    Type char(1),                                 
    FileGroupName nvarchar(128) NULL,             
    Size numeric(20,0),                           
    MaxSize numeric(20,0),                        
    FileID bigint,                                
    CreateLSN numeric(25,0),                      
    DropLSN numeric(25,0) NULL,                   
    UniqueID uniqueidentifier,                    
    ReadOnlyLSN numeric(25,0) NULL,               
    ReadWriteLSN numeric(25,0) NULL,              
    BackupSizeInBytes bigint,                     
    SourceBlockSize int,                          
    FileGroupID int,                              
    LogGroupGUID uniqueidentifier NULL,           
    DifferentialBaseLSN numeric(25,0) NULL,       
    DifferentialBaseGUID uniqueidentifier NULL,   
    IsReadOnly bit,                               
    IsPresent bit,                                
    TDEThumbprint varbinary(32) NULL,             
    SnapshotURL nvarchar(360) NULL                
);


-- =============================================
-- 3. 执行读取并存入表变量
-- =============================================
INSERT INTO @Header
EXEC('RESTORE HEADERONLY FROM DISK = ''' + @BackupFilePath + '''');

INSERT INTO @FileList
EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFilePath + '''');



----=============================================
-- 4. 提取目标数据库名称
----=============================================
DECLARE @TargetDbName SYSNAME;
SELECT TOP 1 @TargetDbName = DatabaseName FROM @Header;

----=============================================
-- 5. 拼接生成 SQL 还原脚本
----=============================================
DECLARE @FinalSQL NVARCHAR(MAX);

SET @FinalSQL = 'USE [master];' + CHAR(13) ;
SET @FinalSQL = @FinalSQL + 'RESTORE DATABASE [' + @TargetDbName + ']' + CHAR(32);
SET @FinalSQL = @FinalSQL + 'FROM DISK = N''' + @BackupFilePath + '''' + CHAR(32);
SET @FinalSQL = @FinalSQL + 'WITH FILE = 1,' + CHAR(13);

-- 直接使用从 @FileList 读出的 LogicalName 和 PhysicalName 拼装 MOVE 语句
SELECT @FinalSQL = @FinalSQL + 
    '    MOVE N''' + LogicalName + ''' TO N''' + PhysicalName + ''',' + CHAR(13)
FROM @FileList;

-- 去除最后一个逗号并闭合脚本
SET @FinalSQL = @FinalSQL + '    REPLACE, STATS = 5, NOUNLOAD;';

-- 输出
print(@FinalSQL)


--执行
--EXEC(@FinalSQL)







