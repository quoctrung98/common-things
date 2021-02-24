--Drop database
--https://stackoverflow.com/questions/7469130/cannot-drop-database-because-it-is-currently-in-use
DECLARE @DatabaseName nvarchar(50)
SET @DatabaseName = N'YOUR_DABASE_NAME'

DECLARE @SQL varchar(max)

SELECT @SQL = COALESCE(@SQL,'') + 'Kill ' + Convert(varchar, SPId) + ';'
FROM MASTER..SysProcesses
WHERE DBId = DB_ID(@DatabaseName) AND SPId <> @@SPId

--SELECT @SQL 
EXEC(@SQL)



--Update statistics
--https://social.msdn.microsoft.com/Forums/sqlserver/en-US/f0692fe1-f2e1-4cb9-9fdb-0cf27077bc39/update-stats-with-full-scan-on-database?forum=transactsql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DECLARE @sql nvarchar(MAX);
SELECT @sql = (SELECT 'UPDATE STATISTICS ' +
                      quotename(s.name) + '.' + quotename(o.name) +
                      ' WITH FULLSCAN; ' AS [text()]
               FROM   sys.objects o
               JOIN   sys.schemas s ON o.schema_id = s.schema_id
               WHERE  o.type = 'U'
               FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @sql
EXEC (@sql)


--Show statistics last updated
SELECT DISTINCT
OBJECT_NAME(s.[object_id]) AS TableName,
c.name AS ColumnName,
s.name AS StatName,
s.auto_created,
s.user_created,
s.no_recompute,
s.[object_id],
s.stats_id,
sc.stats_column_id,
sc.column_id,
STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated
FROM sys.stats s JOIN sys.stats_columns sc 
              ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id
JOIN sys.columns c ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id
JOIN sys.partitions par ON par.[object_id] = s.[object_id]
JOIN sys.objects obj ON par.[object_id] = obj.[object_id]
WHERE OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1
AND (s.auto_created = 1 OR s.user_created = 1);



USE [OMS_THUOCSY_20200511]
GO
/****** Object:  StoredProcedure [dbo].[ThongKeTheoDTVByDate]    Script Date: 11/25/2020 10:39:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
--	Name				Date			Description
--	trungdq			25/11/2020		  Thống kê theo điện thoại viên
--  ThongKeNangSuatTheoDTV '395DE479-4E2F-44F2-BC2D-822B1D582EE5' ,1, 3038,null,null,20,1
-- =============================================
ALTER PROCEDURE [dbo].[ThongKeNangSuatTheoDTV]
    @UserId UNIQUEIDENTIFIER ,
    @AppId INT ,
	@ProjectID INT,
	@DateFrom DATETIME = NULL ,
    @DateEnd DATETIME = NULL ,
    @PageSize INT = NULL ,
    @Page INT = NULL
AS
BEGIN
	SELECT CONCAT(u.FirstName, u.LastName) as HoTen, 
	SUM(case when pu.CallBy = u.Id then 1 else 0 end) as DaNhan,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 then 1 else 0 end) as DaXuLy,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 0 then 1 else 0 end) as ChuaGoi,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 and sttc.StatusID = 1 then 1 else 0 end) as ThanhCong,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 and sttc.StatusID = 2 then 1 else 0 end) as TuChoi,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 and sttc.StatusID = 3 then 1 else 0 end) as SaiSo,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 and sttc.StatusID = 4 and sttc.StatusCallID = 1051 then 1 else 0 end) as KhongLienLacDuoc,
	SUM(case when pu.CallBy = u.Id and pu.IsCall = 1 and sttc.StatusID = 5 then 1 else 0 end) as TiemNang
	FROM telesales_Users u
	JOIN telesales_ProjectCustomer pu on u.Id = pu.CallBy 
	JOIN telesales_Call cl on cl.CustomerId = pu.CustomerID
	JOIN telesales_StatusCall sttc on sttc.StatusCallID = cl.StatusCallID
	WHERE (ISNULL(@ProjectID, '') = '' OR cl.ProjectID = @ProjectID)
	AND (ISNULL(@DateFrom, '') = '' OR cl.UpdateDate >= @DateFrom)
	AND (ISNULL(@DateEnd, '') = '' OR cl.UpdateDate <= @DateEnd)
	GROUP BY u.FirstName, u.LastName, u.Id
	ORDER BY u.FirstName DESC OFFSET @PageSize * (@Page - 1) ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
    
--- SQL Excution ORDER
FROM - Including JOINs
WHERE
GROUP BY
HAVING
SELECT
ORDER BY



------pivot



DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX),
	@customerid as  NVARCHAR(MAX)

select @cols = STUFF((SELECT ',' + QUOTENAME(fieldname) 
                    from telesales_customerfield cf
					join telesales_customerfieldvalue cfv on cfv.customerfieldid = cf.customerfieldid
					join telesales_customer cus on cus.customerid = cfv.customerid
                    group by fieldname
					order by fieldname
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @customerid = '''86099E48-C773-4FE9-95B4-002241E5EC50'''

set @query = N'SELECT ' + @cols + N' from 
             (
                select cf.fieldname, cfv.fieldvalue 
                from telesales_customerfieldvalue cfv
				JOIN telesales_customer cus on cus.customerid = cfv.customerid and cus.customerid='+ @customerid +'
				JOIN telesales_customerfield cf on cf.customerfieldid = cfv.customerfieldid
			) x
            pivot 
            (
                max(fieldvalue)
                for fieldname in (' + @cols + N')
            ) p'

exec sp_executesql @query;




CREATE PROCEDURE GetCustomers
@PageSize INT,
@PageIndex INT
AS
BEGIN
	SELECT * FROM Customers
	ORDER BY Customers.FullName DESC OFFSET @PageSize * (@PageIndex - 1) ROWS FETCH NEXT @PageSize ROWS ONLY;
END

