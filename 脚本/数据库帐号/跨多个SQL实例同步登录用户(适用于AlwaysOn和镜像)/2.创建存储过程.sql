--2.创建存储过程，AlwaysOn集群里的所有节点都要创建这个存储过程





USE [master]
GO
-- =================================================================
-- Author:        <steven>
-- Create date: <2021-12-26>
-- Description:    <Synchronize login users between multiple SQLServer Instances>
-- =================================================================
create  PROCEDURE [dbo].[usp_SyncLoginUserRegularBetweenInstances]
AS
BEGIN

      IF EXISTS(SELECT  1   FROM    sys.dm_hadr_availability_replica_states hars 
              INNER JOIN sys.availability_groups ag ON ag.group_id = hars.group_id
              INNER JOIN sys.availability_replicas ar ON ar.replica_id = hars.replica_id
      WHERE   [hars].[is_local] = 1 AND [hars].[role_desc] = 'PRIMARY'AND [hars].[operational_state_desc] = 'ONLINE'
              AND [hars].[synchronization_health_desc] = 'HEALTHY')
      BEGIN
               ----Check for prerequisite, if not present deploy it.
               IF NOT EXISTS (SELECT  id  FROM  [master].[dbo].[sysobjects] where name='sp_hexadecimal' and xtype='P')  
               BEGIN
                     DECLARE @sp_hexadecimalcreatescript NVARCHAR(3000)
                     --The sp_hexadecimal stored procedure is used to generate the user's password hash value and the user's SID
                     SET @sp_hexadecimalcreatescript =  N'
                  CREATE PROCEDURE [dbo].[sp_hexadecimal]
                      @binvalue VARBINARY(256) ,
                      @hexvalue VARCHAR(514) OUTPUT
                  AS
                      DECLARE @charvalue VARCHAR(514);
                      DECLARE @i INT;
                      DECLARE @length INT;
                      DECLARE @hexstring CHAR(16);
                      SELECT @charvalue = ''0x'';
                      SELECT @i = 1;
                      SELECT @length = DATALENGTH(@binvalue);
                      SELECT @hexstring = ''0123456789ABCDEF'';
                      WHILE ( @i <= @length )
                          BEGIN
                              DECLARE @tempint INT;
                              DECLARE @firstint INT;
                              DECLARE @secondint INT;
                              SELECT @tempint = CONVERT(INT, SUBSTRING(@binvalue, @i, 1));
                              SELECT @firstint = FLOOR(@tempint / 16);
                              SELECT @secondint = @tempint - ( @firstint * 16 );
                              SELECT @charvalue = @charvalue
                                                  + SUBSTRING(@hexstring, @firstint + 1, 1)
                                                  + SUBSTRING(@hexstring, @secondint + 1, 1);
                              SELECT @i = @i + 1;
                          END;
                  
                      SELECT @hexvalue = @charvalue;'
                           
                           EXEC [master].[dbo].sp_executesql @sp_hexadecimalcreatescript
               END
               
                              
               
               --The temporary table below is used to save the generated login user script , user by user, line by line
               DECLARE @TempTable TABLE
               (id INT IDENTITY ,Script NVARCHAR(MAX))
               DECLARE @Login NVARCHAR(MAX)
               DECLARE CURLOGIN CURSOR FOR
               SELECT name 
               FROM sys.server_principals
               WHERE [type] = 'S' AND  [is_disabled] =0   AND  [name] <> 'sa'
               --WHERE CONVERT(VARCHAR(24), create_date, 103) = CONVERT(VARCHAR(24), GETDATE(), 103)
               --    OR CONVERT(VARCHAR(24), modify_date, 103) = CONVERT(VARCHAR(24), GETDATE(), 103)
               
               OPEN CURLOGIN
               FETCH NEXT FROM CURLOGIN INTO @Login
               
               WHILE @@FETCH_STATUS = 0
               BEGIN
                   SET NOCOUNT ON
                   DECLARE @Script NVARCHAR(MAX)
                   DECLARE @LoginName VARCHAR(1500) = @Login
                   DECLARE @LoginSID VARBINARY(400)
                   DECLARE @SID_String VARCHAR(1514)
                   DECLARE @LoginPWD VARBINARY(1256)
                   DECLARE @PWD_String VARCHAR(1514)
                   DECLARE @LoginType CHAR(1)
                   DECLARE @is_disabled BIT
                   DECLARE @default_database_name SYSNAME
                   DECLARE @default_language_name SYSNAME
                   DECLARE @is_policy_checked BIT
                   DECLARE @is_expiration_checked BIT
                   DECLARE @createdDateTime DATETIME
               
                   SELECT @LoginSID = P.[sid]
                       , @LoginType = P.[type]
                       , @is_disabled = P.is_disabled 
                       , @default_database_name = P.default_database_name 
                       , @default_language_name = P.default_language_name 
                       , @createdDateTime = P.create_date 
                   FROM sys.server_principals P
                   WHERE P.name = @LoginName
               
                   SET @Script = ''
               
                   --If the login is a SQL Login, then do a lot of stuff...
                   IF @LoginType = 'S'
                   BEGIN
                       SET @LoginPWD = CAST(LOGINPROPERTY(@LoginName, 'PasswordHash') AS VARBINARY(256))
                       EXEC [master].[dbo].[sp_hexadecimal] @LoginPWD, @PWD_String OUT    
                       EXEC [master].[dbo].[sp_hexadecimal] @LoginSID, @SID_String OUT
                       SELECT @is_policy_checked = S.is_policy_checked
                           , @is_expiration_checked = S.is_expiration_checked
                       FROM sys.sql_logins S  
                       WHERE S.[type] = 'S' AND  S.[is_disabled] =0  
               
                       -- Create  diff Script
                       SET @Script = @Script + CHAR(13) 
                           + CHAR(13) + '''' 
                           + CHAR(13) + 'USE  [master];'  + CHAR(13) 
                           + 'IF EXISTS (SELECT name FROM sys.server_principals WHERE name= ''''' + @LoginName + ''''') ' 
                           + CHAR(13) + 'BEGIN '
                           + CHAR(13) + CHAR(9) + ' DECLARE @CurrentLoginPWD VARBINARY(512)'
                           + CHAR(13) + CHAR(9) + ' DECLARE @CurrentPWD_String VARCHAR(1514)'
                           + CHAR(13) + CHAR(9) + ' DECLARE @CurrentLoginSID VARBINARY(400)'
                           + CHAR(13) + CHAR(9) + ' DECLARE @CurrentSID_String VARCHAR(1514)'
                           + CHAR(13) + CHAR(9) + ' SELECT @CurrentLoginSID = [sid]  FROM sys.server_principals WHERE name = '''''+ @LoginName +''''''
                           + CHAR(13) + CHAR(9) + ' SET  @CurrentLoginPWD =CAST(LOGINPROPERTY(''''' + @LoginName + ''''', ' + '''''PasswordHash''''' +') AS VARBINARY(512))'
                           + CHAR(13) + CHAR(9) + ' EXEC [master].[dbo].[sp_hexadecimal] @CurrentLoginPWD , @CurrentPWD_String OUT    '
                           + CHAR(13) + CHAR(9) + ' EXEC [master].[dbo].[sp_hexadecimal] @CurrentLoginSID, @CurrentSID_String OUT '
                           + CHAR(13) + CHAR(9) + ' --Compare two SID if the same  '
                           + CHAR(13) + CHAR(9) + ' IF  ''''' + @SID_String + ''''' =  @CurrentSID_String      '
                           + CHAR(13) + CHAR(9) + ' BEGIN'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) + ' --Compare two password  if the same '
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) + ' IF  ''''' + @PWD_String + ''''' <>  @CurrentPWD_String      '
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) + ' BEGIN'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  '--Just update login user password'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ' ALTER LOGIN ' + QUOTENAME(@LoginName)
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ' WITH PASSWORD = ' + @PWD_String + ' HASHED'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ', DEFAULT_DATABASE = [' + @default_database_name + ']'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ', DEFAULT_LANGUAGE = [' + @default_language_name + ']'
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ', CHECK_POLICY ' + CASE WHEN @is_policy_checked = 0 THEN '=OFF' ELSE '=ON' END
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) +  CHAR(9) +  ', CHECK_EXPIRATION ' + CASE WHEN @is_expiration_checked = 0 THEN '=OFF' ELSE '=ON' END
                           + CHAR(13) + CHAR(9) +  CHAR(9) +  CHAR(9) + ' END'
                           + CHAR(13) + CHAR(9) + ' END'
                           + CHAR(13) + 'END '
                           + CHAR(13) + 'ELSE'
                           + CHAR(13) + 'BEGIN '
                           + CHAR(13) + CHAR(9) + ' --Create new login user ' 
                           + CHAR(13) + CHAR(9) + ' CREATE LOGIN ' + QUOTENAME(@LoginName)
                           + CHAR(13) + CHAR(9) + ' WITH PASSWORD = ' + @PWD_String + ' HASHED'
                           + CHAR(13) + CHAR(9) + ', SID = ' + @SID_String
                           + CHAR(13) + CHAR(9) + ', DEFAULT_DATABASE = [' + @default_database_name + ']'
                           + CHAR(13) + CHAR(9) + ', DEFAULT_LANGUAGE = [' + @default_language_name + ']'
                           + CHAR(13) + CHAR(9) + ', CHECK_POLICY ' + CASE WHEN @is_policy_checked = 0 THEN '=OFF' ELSE '=ON' END
                           + CHAR(13) + CHAR(9) + ', CHECK_EXPIRATION ' + CASE WHEN @is_expiration_checked = 0 THEN '=OFF' ELSE '=ON' END
                           + CHAR(13) + 'END '
                       
                       --SET @Script = @Script + CHAR(13) + CHAR(13)
                       --    + ' ALTER LOGIN [' + @LoginName + ']'
                       --    + CHAR(13) + CHAR(9) + 'WITH DEFAULT_DATABASE = [' + @default_database_name + ']'
                       --    + CHAR(13) + CHAR(9) + ', DEFAULT_LANGUAGE = [' + @default_language_name + ']'
                   END
                   --ELSE
                   --BEGIN
                   --    --The login is a NT login (or group).
                   --    SET @Script = @Script + CHAR(13) + CHAR(13)
                   --        + 'IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name= ''' + @LoginName + ''') ' 
                   --        + CHAR(13) + ' BEGIN '
                   --        + CHAR(13) + CHAR(9) + ' CREATE LOGIN ' + QUOTENAME(@LoginName) + ' FROM WINDOWS'
                   --        + CHAR(13) + CHAR(9) + 'WITH DEFAULT_DATABASE = [' + @default_database_name + ']'
                   --        + CHAR(13) + ' END '
                   --END
               
               
                   --This section deals with the Server Roles that belong to that login...
                   DECLARE @ServerRoles TABLE
                       (
                       ServerRole SYSNAME
                       , MemberName SYSNAME
                       , MemberSID VARBINARY(185)
                       )
               
                   ----Prevent multiple records from being inserted into the @ServerRoles table
                   IF NOT EXISTS (SELECT 1 FROM @ServerRoles )
                   BEGIN
                       INSERT INTO @ServerRoles EXEC sp_helpsrvrolemember
                   END
                   
               
                   ----Remove all Roles
                   --SET @Script = @Script + CHAR(13)
                   --SET @Script = @Script 
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''sysadmin'''
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''securityadmin'''
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''serveradmin''' 
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''setupadmin''' 
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''processadmin'''
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''diskadmin''' 
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''dbcreator''' 
                   --    + CHAR(13) + 'EXEC sp_dropsrvrolemember ' + QUOTENAME(@LoginName) + ', ''bulkadmin''' 
               
                   /** Output to script... **/
                   --SET @Script = @Script + CHAR(13) + CHAR(13)
               
                        --Test if there are any server roles for this login...
                        IF EXISTS(SELECT 1 FROM @ServerRoles WHERE MemberName = @LoginName)
                        BEGIN
                        
                            SET @Script = @Script + CHAR(13)
                        
                            DECLARE @ServerRole SYSNAME
                            DECLARE curRoles CURSOR LOCAL STATIC FORWARD_ONLY
                        
                            FOR SELECT  ServerRole 
                                FROM @ServerRoles
                                WHERE MemberName = @LoginName
                            
                            OPEN curRoles
                        
                            FETCH NEXT FROM curRoles
                            INTO @ServerRole
                        
                            WHILE @@FETCH_STATUS = 0
                            BEGIN
                                 /** Output to Script **/
                                 SET @Script = @Script 
                                              + CHAR(13) + 'EXEC sp_addsrvrolemember ' + QUOTENAME(@LoginName) + ', ' + '''''' + @ServerRole + ''''''
                                     
                                 FETCH NEXT FROM curRoles
                                 INTO @ServerRole
                            END
                        
                            --Cleanup.
                            CLOSE curRoles
                            DEALLOCATE curRoles
                        END
                        SET @Script = @Script + CHAR(13)  + '''' 
                        INSERT INTO @TempTable
                        VALUES(@Script)
                        
                        FETCH NEXT FROM CURLOGIN INTO @Login
               END
               CLOSE CURLOGIN;
               DEALLOCATE CURLOGIN;
               SELECT id, Script FROM @TempTable ORDER BY id
              
            
               ------------------------------------------------------------------------------------
               --Use  linked servers  to send scripts to remote machines for execution
               --------------------------------------------------------------------------------
               DECLARE @LinkedServerName NVARCHAR(512);
               DECLARE @DynamicSQL NVARCHAR(MAX);
               DECLARE @EXISTSSQL NVARCHAR(2000);
               
               
               DECLARE cursor_linked_servers CURSOR FOR
               SELECT name
               FROM sys.servers
               WHERE is_linked = 1 
               AND [product]='SQL Server' 
               AND [provider]='SQLNCLI' 
               AND [connect_timeout]>0 AND [query_timeout] >0;
               
               
               OPEN cursor_linked_servers;
               FETCH NEXT FROM cursor_linked_servers INTO @LinkedServerName;
               WHILE @@FETCH_STATUS = 0
               BEGIN  
                       --Determine whether the remote machine has the stored procedure call "sp_hexadecimal"
                       --if not have  do not execute the cursor traversal loop
                       CREATE TABLE #EXISTSTB(id BIGINT)
                       SET @EXISTSSQL='SELECT * FROM OPENQUERY('+ QUOTENAME(@LinkedServerName) + ', ''SELECT  id  FROM  [master].[dbo].[sysobjects] WHERE name = ''''sp_hexadecimal'''' AND xtype=''''P'''' '')'
                       INSERT INTO #EXISTSTB EXEC(@EXISTSSQL) 
                       IF EXISTS(SELECT * FROM #EXISTSTB)
                       BEGIN
                               DECLARE @RunSQL NVARCHAR(MAX)
                               DECLARE CURSYNC CURSOR FOR
                               SELECT Script FROM @TempTable ORDER BY id
                               
                               OPEN CURSYNC
                               FETCH NEXT FROM CURSYNC INTO @RunSQL
                               
                               WHILE @@FETCH_STATUS = 0
                               BEGIN 
                                        SET @DynamicSQL = 'EXEC('+ @RunSQL + ') AT ['+ @LinkedServerName +']'
                                        EXEC sp_executesql @DynamicSQL;
                               
                                   FETCH NEXT FROM CURSYNC INTO @RunSQL
                               END;
                               
                               CLOSE CURSYNC
                               DEALLOCATE CURSYNC
                       END
                       DROP TABLE #EXISTSTB
               
                   FETCH NEXT FROM cursor_linked_servers INTO @LinkedServerName;
               END;
               
               -- close cursor
               CLOSE cursor_linked_servers;
               DEALLOCATE cursor_linked_servers;
      
      END
        
END




 