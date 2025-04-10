-- =============================================
-- Create date: <2014/4/18>
-- Description: 禁用所有Login登录用户，防止有新增的数据写入数据库
-- =============================================



DECLARE @loginName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE login_cursor CURSOR FOR
SELECT name
FROM sys.server_principals
WHERE type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
  AND is_disabled = 0
  AND name NOT IN ('sa');

OPEN login_cursor;
FETCH NEXT FROM login_cursor INTO @loginName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER LOGIN [' + @loginName + '] DISABLE;';
    PRINT @sql
    --EXEC sp_executesql @sql;

    FETCH NEXT FROM login_cursor INTO @loginName;
END

CLOSE login_cursor;
DEALLOCATE login_cursor;
