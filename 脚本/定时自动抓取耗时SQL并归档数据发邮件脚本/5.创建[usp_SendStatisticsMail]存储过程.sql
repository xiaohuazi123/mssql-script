USE [MonitorElapsedHighSQL]
GO

--对统计数据定时发邮件
CREATE  PROCEDURE [dbo].[usp_SendStatisticsMail]
AS
    BEGIN
       
        --定义变量
        DECLARE @SQL NVARCHAR(MAX)
        DECLARE @SQLConcat NVARCHAR(MAX)
        DECLARE @infoConcat NVARCHAR(MAX)
        DECLARE @finalSQL NVARCHAR(MAX)


        DECLARE @DBID NVARCHAR(MAX)
        DECLARE @servername NVARCHAR(200)
        DECLARE @date DATETIME

        DECLARE @sqlversion NVARCHAR(200)
        DECLARE @uptime NVARCHAR(200)


        --1.数据库版本信息
        SELECT  @sqlversion = @@version


        --2.数据库服务器已运行时间信息
        SELECT  @uptime = CONVERT(NVARCHAR(200), DATEDIFF(DAY, sqlserver_start_time, GETDATE()))
        FROM    sys.dm_os_sys_info WITH ( NOLOCK )
        OPTION  ( RECOMPILE )



        --3.查看数据库服务器名
        SELECT  @servername = LTRIM(@@servername)


        SET @date = GETDATE()
        SET @SQL = ' '
        SET @SQLConcat = ' '
        SET @infoConcat = ' '



        IF ( @servername IS NOT NULL AND @servername <> '' )
            BEGIN
                SET @infoConcat = '<h3><font color="#FF0000">主机名：' + @ServerName + '</font></h3></br>'
            END

        IF ( @uptime IS NOT NULL  AND @uptime <> '' )
            BEGIN
                SET @infoConcat = @infoConcat + '<h4>数据库服务器已运行天数：' + @uptime  + '天</h4></br>' 
            END

        IF ( @sqlversion IS NOT NULL AND @sqlversion <> '' )
            BEGIN
                SET @infoConcat = @infoConcat + '<h4>数据库版本信息：' + @sqlversion + '</h4></br>'
            END


      -----------------------------------------------------------


        SET @SQL = N'<H3>[' + @servername + ']_前5条不同的最耗时SQL 表名：[MostElapsedStatisticsByDay] ------   邮件发出时间：' + CONVERT(NVARCHAR(200), @date, 120) + '</H3>'
            + '<table border="1">' + N'<tr>
<th>[id]</th>
<th>[耗时]</th>
<th>[IO读次数]</th>
<th>[IO写次数]</th>
<th>[数据库名称]</th>
<th>[执行计划SQL]</th>
<th>[日期]</th>
</tr>' + CAST(( SELECT TOP 5
                        [id] AS 'td' ,
                        '' ,
                        [ElapsedMS] AS 'td' ,
                        '' ,
                        [IOReads] AS 'td' ,
                        '' ,
                        [IOWrites] AS 'td' ,
                        '' ,
                        [DBName] AS 'td' ,
                        '' ,
                        LEFT([planstmttext], 100) AS 'td' ,
                        '' ,
                        CONVERT(DATE, [gettime]) AS 'td' ,
                        ''
                FROM    [dbo].[MostElapsedStatisticsByDay]
                WHERE   DATEPART(DAY, [gettime]) = DATEPART(DAY, GETDATE()) AND DATEPART(MONTH , [gettime]) = DATEPART(MONTH, GETDATE()) AND DATEPART(YEAR, [gettime]) = DATEPART(YEAR, GETDATE())
                ORDER BY [ElapsedMS] DESC
              FOR
                XML PATH('tr') ,
                    ELEMENTS-- TYPE 
              ) AS NVARCHAR(MAX)) + N'</table>';
        PRINT @SQL

        IF ( @SQL IS NOT NULL
             AND @SQL <> ''
           )
            BEGIN
                SET @SQLConcat = @SQL + @SQLConcat

            END




      --------------------------------------------------------



        SET @SQL = N'<H3>[' + @servername + ']_前5条I/O read最多的SQL 表名：[MostIOReadStatisticsByDay]------   邮件发出时间：' + CONVERT(NVARCHAR(200), @date, 120) + '</H3>'
            + '<table border="1">' + N'<tr>
<th>[id]</th>
<th>[IO读次数]</th>
<th>[数据库名称]</th>
<th>[执行计划SQL]</th>
<th>[日期]</th>
</tr>' + CAST(( SELECT TOP 5
                        [id] AS 'td' ,
                        '' ,
                        [IOReads] AS 'td' ,
                        '' ,
                        [DBName] AS 'td' ,
                        '' ,
                        LEFT([planstmttext], 100) AS 'td' ,
                        '' ,
                        CONVERT(DATE, [gettime]) AS 'td' ,
                        ''
                FROM    [dbo].[MostIOReadStatisticsByDay]
                WHERE   DATEPART(DAY, [gettime]) = DATEPART(DAY, GETDATE()) AND DATEPART(MONTH , [gettime]) = DATEPART(MONTH, GETDATE()) AND DATEPART(YEAR, [gettime]) = DATEPART(YEAR, GETDATE())
                ORDER BY [IOReads] DESC
              FOR
                XML PATH('tr') ,
                    ELEMENTS-- TYPE 
              ) AS NVARCHAR(MAX)) + N'</table>';


     
        IF ( @SQL IS NOT NULL
             AND @SQL <> ''
           )
            BEGIN
                SET @SQLConcat = @SQL + @SQLConcat

            END

--      -----------------------------------------------------



        SET @SQL = N'<H3>[' + @servername + ']_前5条I/O write最多的SQL 表名：[MostIOWriteStatisticsByDay]------   邮件发出时间：'+ CONVERT(NVARCHAR(200), @date, 120) + '</H3>'
            + '<table border="1">' + N'<tr>
<th>[id]</th>
<th>[IO写次数]</th>
<th>[数据库名称]</th>
<th>[执行计划SQL]</th>
<th>[日期]</th>
</tr>' + CAST(( SELECT TOP 5
                        [id] AS 'td' ,
                        '' ,
                        [IOWrites] AS 'td' ,
                        '' ,
                        [DBName] AS 'td' ,
                        '' ,
                        LEFT([planstmttext], 100) AS 'td' ,
                        '' ,
                        CONVERT(DATE, [gettime]) AS 'td' ,
                        ''
                FROM    [dbo].[MostIOWriteStatisticsByDay]
                WHERE   DATEPART(DAY, [gettime]) = DATEPART(DAY, GETDATE()) AND DATEPART(MONTH , [gettime]) = DATEPART(MONTH, GETDATE()) AND DATEPART(YEAR, [gettime]) = DATEPART(YEAR, GETDATE())
                ORDER BY [IOWrites] DESC
              FOR
                XML PATH('tr') ,
                    ELEMENTS-- TYPE 
              ) AS NVARCHAR(MAX)) + N'</table>';


      
        IF ( @SQL IS NOT NULL
             AND @SQL <> ''
           )
            BEGIN
                SET @SQLConcat = @SQL + @SQLConcat

            END

--      -------------------------------------------------------




        SET @SQL = N'<H3>[' + @servername + ']_前5条使用sp_executesql执行的SQL 表名：[sp_executesqlCountStatisticsByDay]------   邮件发出时间：'+ CONVERT(NVARCHAR(200), @date, 120) + '</H3>'
            + '<table border="1">' + N'<tr>
<th>[id]</th>
<th>[sp_executesql调用次数]</th>
<th>[数据库名称]</th>
<th>[执行计划SQL]</th>
<th>[日期]</th>
</tr>' + CAST(( SELECT TOP 5
                        [id] AS 'td' ,
                        '' ,
                        [sp_executesqlCount] AS 'td' ,
                        '' ,
                        [DBName] AS 'td' ,
                        '' ,
                        LEFT([planstmttext], 100) AS 'td' ,
                        '' ,
                        CONVERT(DATE, [gettime]) AS 'td' ,
                        ''
                FROM    [dbo].[sp_executesqlCountStatisticsByDay]
                WHERE   DATEPART(DAY, [gettime]) = DATEPART(DAY, GETDATE()) AND DATEPART(MONTH , [gettime]) = DATEPART(MONTH, GETDATE()) AND DATEPART(YEAR, [gettime]) = DATEPART(YEAR, GETDATE())
                ORDER BY [sp_executesqlCount] DESC
              FOR
                XML PATH('tr') ,
                    ELEMENTS-- TYPE 
              ) AS NVARCHAR(MAX)) + N'</table>';

     
        IF ( @SQL IS NOT NULL
             AND @SQL <> ''
           )
            BEGIN
                SET @SQLConcat = @SQL + @SQLConcat

            END

--      --------------------------------------------------------
        
        SET @SQL = N'<H3>[' + @servername+ ']_SQL语句数量 表名：[SQLCountStatisticsByDay]------   邮件发出时间：' + CONVERT(NVARCHAR(200), @date, 120) + '</H3>'
            + '<table border="1">' + N'<tr>
<th>[id]</th>
<th>[SQL数量]</th>
<th>[日期]</th>
</tr>' + CAST(( SELECT  [id] AS 'td' ,
                        '' ,
                        [SQLCount] AS 'td' ,
                        '' ,
                        CONVERT(DATE, [gettime]) AS 'td' ,
                        ''
                FROM    [dbo].[SQLCountStatisticsByDay]
                WHERE   DATEPART(DAY, [gettime]) = DATEPART(DAY, GETDATE()) AND DATEPART(MONTH , [gettime]) = DATEPART(MONTH, GETDATE()) AND DATEPART(YEAR, [gettime]) = DATEPART(YEAR, GETDATE())
              FOR
                XML PATH('tr') ,
                    ELEMENTS-- TYPE 
              ) AS NVARCHAR(MAX)) + N'</table>';

      
        IF ( @SQL IS NOT NULL
             AND @SQL <> ''
           )
            BEGIN
                SET @SQLConcat = @SQL + @SQLConcat

            END

      -----------------------------------------------

        IF ( @infoConcat IS NOT NULL AND @infoConcat <> '' AND @SQLConcat IS NOT NULL  AND @SQLConcat <> '')
            BEGIN
                SET @finalSQL = @infoConcat + '</br></br>' + @SQLConcat
                EXEC [msdb].[dbo].[sp_send_dbmail] @profile_name = 'SQLServer',
                    @recipients = 'dba@xx.com', -- varchar(max) --收件人
                    @subject = N'SQL Server 实例SQL语句抓取统计信息', -- nvarchar(255) 标题
                    @body_format = 'HTML', -- varchar(20) 正文格式可选值：text html
                    @body = @finalSQL
            END


     


    END