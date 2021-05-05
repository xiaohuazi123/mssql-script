

-- =============================================
-- Create date: <2014/4/18>
-- Description: 非域环境镜像自动生成模板
--环境：非域环境
-- =============================================





DECLARE @DBName NVARCHAR(255)
DECLARE @masterip NVARCHAR(255)
DECLARE @mirrorip NVARCHAR(255)
DECLARE @witness NVARCHAR(255)
DECLARE @masteriptail NVARCHAR(255)
DECLARE @mirroriptail NVARCHAR(255)
DECLARE @witnesstail NVARCHAR(255)
DECLARE @certpath NVARCHAR(MAX)
DECLARE @Restorepath NVARCHAR(MAX)
DECLARE @Restorepath1 NVARCHAR(MAX)
DECLARE @Restorepath2 NVARCHAR(MAX)
DECLARE @MKPASSWORD NVARCHAR(500)
DECLARE @LOGINPWD NVARCHAR(500)
DECLARE @SQL NVARCHAR(MAX)


if OBJECT_ID ('tempdb..#temp')is not null 
BEGIN 
 DROP TABLE #BackupFileList
END

CREATE TABLE #BackupFileList 
    (
      LogicalName NVARCHAR(100) ,
      PhysicalName NVARCHAR(100) ,
      BackupType CHAR(1) ,
      FileGroupName NVARCHAR(50) ,
      SIZE BIGINT ,
      MaxSize BIGINT ,
      FileID BIGINT ,
      CreateLSN BIGINT ,
      DropLSN BIGINT NULL ,
      UniqueID UNIQUEIDENTIFIER ,
      ReadOnlyLSN BIGINT NULL ,
      ReadWriteLSN BIGINT NULL ,
      BackupSizeInBytes BIGINT ,
      SourceBlockSize INT ,
      FileGroupID INT ,
      LogGroupGUID UNIQUEIDENTIFIER NULL ,
      DifferentialBaseLSN BIGINT NULL ,
      DifferentialBaseGUID UNIQUEIDENTIFIER ,
      IsReadOnly BIT ,
      IsPresent BIT ,
      TDEThumbprint NVARCHAR(100)
    )


SET NOCOUNT ON

SET @masterip='172.31.21.10'  --★Do 主库ip
SET @mirrorip='172.31.38.85'   --★Do 从库ip
SET @witness='172.31.33.6'   --★Do  见证ip
SET @certpath='D:\DBBackup\'   --★Do  证书存放路径
SET @Restorepath='D:\DBBackup\'   --★Do 备份还原路径
SET @DBName='testmirror'               --★Do 要做镜像的数据库名
SET @MKPASSWORD='master@2015key123' --★Do  证书密码
SET @LOGINPWD='User_Pass@2015key123'  --★Do  镜像登录用户密码




select @masteriptail= PARSENAME(@masterip,2)+'_'+PARSENAME(@masterip,1) 
select @mirroriptail= PARSENAME(@mirrorip,2)+'_'+PARSENAME(@mirrorip,1) 
select @witnesstail= PARSENAME(@witness,2)+'_'+PARSENAME(@witness,1) 


--------------------------------------------------------------------------------
DECLARE @stat NVARCHAR(MAX)

SET  @stat='--自动生成镜像脚本V1 By huazai'
PRINT @stat
PRINT CHAR(13)+CHAR(13)




SET  @stat='--0、首先确定要做镜像的库的恢复模式为完整，用以下sql语句来查看'+CHAR(13)
+'SELECT [name], [recovery_model_desc] FROM sys.[databases]'+CHAR(13)+CHAR(13)+CHAR(13)

PRINT '--主：'+@masterip
PRINT '--备：'+@mirrorip
PRINT '--见证：'+@witness
PRINT CHAR(13)+CHAR(13)
PRINT @stat

--------------------------------------------------------------------
PRINT '-- ============================================='

SET  @stat='--1、 在主服务器和镜像服务器上和见证服务器上创建Master Key 、创建证书 '+CHAR(13)
+'--主机'+CHAR(13)
+'USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@MKPASSWORD+''';'
+'CREATE CERTIFICATE HOST_'
+@masteriptail
+'_cert  WITH SUBJECT = ''HOST_'
+@masteriptail
+'_certificate'','+CHAR(13)
+'START_DATE = ''09/20/2010'',EXPIRY_DATE = ''01/01/2099'';'+CHAR(13)

PRINT @stat


SET  @stat='--备机'+CHAR(13)
+'USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@MKPASSWORD+''';'
+'CREATE CERTIFICATE HOST_'
+@mirroriptail
+'_cert  WITH SUBJECT = ''HOST_'
+@mirroriptail
+'_certificate'','+CHAR(13)
+'START_DATE = ''09/20/2010'',EXPIRY_DATE = ''01/01/2099'';'+CHAR(13)

PRINT @stat


SET  @stat='--见证'+CHAR(13)
+'USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@MKPASSWORD+''';'
+'CREATE CERTIFICATE HOST_'
+@witnesstail
+'_cert  WITH SUBJECT = ''HOST_'
+@witnesstail
+'_certificate'','+CHAR(13)
+'START_DATE = ''09/20/2010'',EXPIRY_DATE = ''01/01/2099'';'+CHAR(13)+CHAR(13)+CHAR(13)+CHAR(13)

PRINT @stat

-----------------------------------------------------------

PRINT '-- ============================================='


SET  @stat='--2、创建镜像端点，同一个实例上只能存在一个镜像端点  '+CHAR(13)
+'--主机'+CHAR(13)
+'CREATE ENDPOINT Endpoint_Mirroring 
STATE = STARTED 
AS 
TCP ( LISTENER_PORT=5022 , LISTENER_IP = ALL ) 
FOR 
DATABASE_MIRRORING 
( AUTHENTICATION = CERTIFICATE HOST_'
+@masteriptail
+'_cert  , ENCRYPTION = REQUIRED ALGORITHM AES , ROLE = ALL );'+CHAR(13)

PRINT @stat

SET  @stat='--备机'+CHAR(13)
+'CREATE ENDPOINT Endpoint_Mirroring 
STATE = STARTED 
AS 
TCP ( LISTENER_PORT=5022 , LISTENER_IP = ALL ) 
FOR 
DATABASE_MIRRORING 
( AUTHENTICATION = CERTIFICATE HOST_'
+@mirroriptail
+'_cert  , ENCRYPTION = REQUIRED ALGORITHM AES , ROLE = ALL );'+CHAR(13)

PRINT @stat


SET  @stat='--见证'+CHAR(13)
+'CREATE ENDPOINT Endpoint_Mirroring
STATE = STARTED
AS
TCP ( LISTENER_PORT=5022 , LISTENER_IP = ALL )
FOR
DATABASE_MIRRORING
( AUTHENTICATION = CERTIFICATE HOST_'
+@witnesstail
+'_cert  , ENCRYPTION = REQUIRED ALGORITHM AES , ROLE = ALL );'+CHAR(13)+CHAR(13)+CHAR(13)

PRINT @stat

----------------------------------------------------------------------------------------

PRINT '-- ============================================='


SET  @stat='--3、备份证书，然后互换  '+CHAR(13)
+'--主机'+CHAR(13)
+'BACKUP CERTIFICATE HOST_'
+@masteriptail
+'_cert TO FILE = '+''''+@certpath+'\HOST_'+@masteriptail+'_cert.cer'';'+CHAR(13)

PRINT @stat

SET  @stat='--备机'+CHAR(13)
+'BACKUP CERTIFICATE HOST_'
+@mirroriptail
+'_cert TO FILE = '+''''+@certpath+'\HOST_'+@mirroriptail+'_cert.cer'';'+CHAR(13)

PRINT @stat


SET  @stat='--见证'+CHAR(13)
+'BACKUP CERTIFICATE HOST_'
+@witnesstail
+'_cert TO FILE = '+''''+@certpath+'\HOST_'+@witnesstail+'_cert.cer'';'+CHAR(13)+CHAR(13)+CHAR(13)

PRINT @stat


----------------------------------------------------------------------------------

PRINT '-- ============================================='


SET  @stat='--4、新增主备登陆用户  '+CHAR(13)
+'--主机'+CHAR(13)
+'CREATE LOGIN DB_02_Mirror WITH PASSWORD = '''+@LOGINPWD+'''; 
CREATE USER DB_02_Mirror FOR LOGIN DB_02_Mirror; 
CREATE CERTIFICATE HOST_'
+@mirroriptail
+'_cert AUTHORIZATION DB_02_Mirror FROM FILE ='''+@certpath+'HOST_'+@mirroriptail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_02_Mirror];'+CHAR(13)

PRINT @stat

SET  @stat='CREATE LOGIN DB_03_Mirror WITH PASSWORD = '''+@LOGINPWD+''';
CREATE USER DB_03_Mirror FOR LOGIN DB_03_Mirror;
CREATE CERTIFICATE HOST_'
+@witnesstail
+'_cert AUTHORIZATION DB_03_Mirror FROM FILE ='''+@certpath+'HOST_'+@witnesstail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_03_Mirror];'+CHAR(13)

PRINT @stat


SET  @stat='--备机'+CHAR(13)
+'CREATE LOGIN DB_01_Mirror WITH PASSWORD = '''+@LOGINPWD+'''; 
CREATE USER DB_01_Mirror FOR LOGIN DB_01_Mirror; 
CREATE CERTIFICATE HOST_'
+@masteriptail
+'_cert AUTHORIZATION DB_01_Mirror FROM FILE ='''+@certpath+'HOST_'+@masteriptail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_01_Mirror];'+CHAR(13)

PRINT @stat

SET  @stat='CREATE LOGIN DB_03_Mirror WITH PASSWORD = '''+@LOGINPWD+''';
CREATE USER DB_03_Mirror FOR LOGIN DB_03_Mirror;
CREATE CERTIFICATE HOST_'
+@witnesstail
+'_cert AUTHORIZATION DB_03_Mirror FROM FILE ='''+@certpath+'HOST_'+@witnesstail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_03_Mirror];'+CHAR(13)

PRINT @stat


SET  @stat='--见证'+CHAR(13)
+'CREATE LOGIN DB_01_Mirror WITH PASSWORD = '''+@LOGINPWD+'''; 
CREATE USER DB_01_Mirror FOR LOGIN DB_01_Mirror; 
CREATE CERTIFICATE HOST_'
+@masteriptail
+'_cert AUTHORIZATION DB_01_Mirror FROM FILE ='''+@certpath+'HOST_'+@masteriptail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_01_Mirror];'+CHAR(13)

PRINT @stat

SET  @stat='CREATE LOGIN DB_02_Mirror WITH PASSWORD = '''+@LOGINPWD+''';
CREATE USER DB_02_Mirror FOR LOGIN DB_02_Mirror;
CREATE CERTIFICATE HOST_'
+@mirroriptail
+'_cert AUTHORIZATION DB_02_Mirror FROM FILE ='''+@certpath+'HOST_'+@mirroriptail+'_cert.cer'';'
+'GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [DB_02_Mirror];'+CHAR(13)+CHAR(13)+CHAR(13)+CHAR(13)

PRINT @stat

------------------------------------------------------------------------------

PRINT '-- ============================================='



SET  @stat='--5、各个机器都开放5022端口，并且用telnet测试5022端口是否开通 将下面三个脚本各自粘贴到bat文件里'+CHAR(13)
PRINT @stat

SET  @stat='echo 主库'+CHAR(13)
+'telnet '+@mirrorip+' 5022'+CHAR(13)
+'telnet '+@witness+' 5022'+CHAR(13)
+'pause'

PRINT @stat+CHAR(13)+CHAR(13)

SET  @stat='echo 镜像库'+CHAR(13)
+'telnet '+@masterip+' 5022'+CHAR(13)
+'telnet '+@witness+' 5022'+CHAR(13)
+'pause'

PRINT @stat+CHAR(13)+CHAR(13)

SET  @stat='echo 见证'+CHAR(13)
+'telnet '+@masterip+' 5022'+CHAR(13)
+'telnet '+@mirrorip+' 5022'+CHAR(13)
+'pause'

PRINT @stat+CHAR(13)+CHAR(13)+CHAR(13)


--------------------------------------------------------------

PRINT '-- ============================================='



SET  @stat='--6、备份数据库(完整备份+事务日志备份)'+CHAR(13)
PRINT @stat

SET  @stat='DECLARE @FileName NVARCHAR(MAX)'+CHAR(13)+CHAR(13)

PRINT @stat


SET  @stat='--('+@DBName+'数据库完整备份)'+CHAR(13)
+'SET @FileName = ''D:\DBBackup\'+@DBName+'_FullBackup_1.bak''
BACKUP DATABASE ['+@DBName+']
TO DISK=@FileName WITH FORMAT ,COMPRESSION'+CHAR(13)+CHAR(13)

PRINT @stat


SET  @stat='--('+@DBName+'数据库日志备份)'+CHAR(13)
+'SET @FileName = ''D:\DBBackup\'+@DBName+'_logBackup_2.bak''
BACKUP DATABASE ['+@DBName+']
TO DISK=@FileName WITH FORMAT ,COMPRESSION'

PRINT @stat+CHAR(13)+CHAR(13)+CHAR(13)

------------------------------------------------------------------------------

PRINT '-- ============================================='


SET  @stat='--7、还原数据库(指定norecovery方式还原)'+CHAR(13)
PRINT @stat

SET  @Restorepath1=''

SET @Restorepath2=@Restorepath+@DBName+'_FullBackup_1.bak'
SET @SQL = 'RESTORE FILELISTONLY  FROM DISK = '''+@Restorepath2+''''  

INSERT INTO #BackupFileList EXEC (@SQL);

 DECLARE @LNAME NVARCHAR(2000)
  DECLARE @PNAME NVARCHAR(2000)


        DECLARE CurTBName CURSOR
        FOR
            SELECT LogicalName,PhysicalName
            FROM    #BackupFileList  

        OPEN CurTBName
        FETCH NEXT FROM CurTBName INTO @LNAME,@PNAME

        WHILE @@FETCH_STATUS = 0
            BEGIN  
             SET  @Restorepath1=' MOVE N'''+@LNAME+''' TO N'''+@PNAME+''', '+CHAR(13)+@Restorepath1


                FETCH NEXT FROM CurTBName INTO  @LNAME,@PNAME
            END
        CLOSE CurTBName
        DEALLOCATE CurTBName




SET  @stat='USE [master]
RESTORE DATABASE '+@DBName+' FROM  DISK = N'''+@Restorepath+@DBName+'_FullBackup_1.bak'' WITH  FILE = 1,'+CHAR(13)
+@Restorepath1
+'NOUNLOAD,NORECOVERY,  REPLACE,  STATS = 5
GO'

SET  @stat='USE [master]
RESTORE LOG '+@DBName+' FROM  DISK = N'''+@Restorepath+@DBName+'_logBackup_2.bak'' WITH  FILE = 1,'+CHAR(13)
+'NOUNLOAD,NORECOVERY,  REPLACE,  STATS = 5
GO'



PRINT @stat+CHAR(13)+CHAR(13)

DROP TABLE #BackupFileList

--------------------------------------------------------------------------------

PRINT '-- ============================================='



SET  @stat='--8、增加镜像伙伴，需要先在备机上执行，再执行主机，镜像弄好之后，默认为事务安全等级为FULL'+CHAR(13)
PRINT @stat




SET  @stat='--备机上执行'+CHAR(13)
+'USE [master]
GO

ALTER DATABASE ['+@DBName+'] SET PARTNER = '''+'TCP://'+@masterip+':5022'';  --主机服务器的ip'+CHAR(13)+CHAR(13)

PRINT @stat


SET  @stat='--主机上执行'+CHAR(13)
+'USE [master]
GO

ALTER DATABASE ['+@DBName+'] SET PARTNER = '''+'TCP://'+@mirrorip+':5022'';  --镜像服务器的ip'+CHAR(13)+CHAR(13)

PRINT @stat

SET  @stat='ALTER DATABASE ['+@DBName+'] SET PARTNER = '''+'TCP://'+@witness+':5022'';  --见证服务器的ip'+CHAR(13)+CHAR(13)

PRINT @stat