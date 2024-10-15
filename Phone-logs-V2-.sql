/*
    ActivityReportData Stored Procedure
    -----------------------------------
    This stored procedure retrieves data about activities and generates Phone logs report for the specified owner and user.
    
    Usage: 
    - Filters activities within the last 13 months.
    - Filters by user assignment and personal tasks.



    Parameters:
    - @ownerid: The owner of the data.
    - @userid: The user for filtering tasks.
    - @startindex: The starting index for pagination.
    - @endindex: The ending index for pagination.
    - @filter: Any additional filtering criteria.
*/

CREATE OR ALTER PROCEDURE [dbo].[ActivityReportData]
    @ownerid INT,
    @userid INT, 
    @startindex INT, 
    @endindex INT,
    @filter NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @pagesize VARCHAR(max);
    DECLARE @sql NVARCHAR(max);

    -- Handle default filter
    IF (@filter IS NULL OR LEN(TRIM(@filter)) = 0)
        SET @filter = '1=1';
    ELSE
        SET @filter = REPLACE(@filter, 'Createdon', 'OrderedResults.Createdon');

    -- Handle pagination
    IF (@startindex = 0 AND @endindex = 0)
    BEGIN
        SET @pagesize = '100 percent';
    END
    ELSE
    BEGIN
        SET @pagesize = CAST(@endindex - @startindex + 1 AS VARCHAR(20));
    END

    -- Dynamic SQL to fetch activity data
    SET @sql = N'
    WITH OrderedResults AS (
        SELECT 
            acc.Code AS MemberAccountNumber, 
            a.RelatedToName AS MemberName,
            a.RelatedToTypeName AS Module,
            (SELECT Name FROM LookUpMaster WHERE LookupMaster.OwnerId = 918 AND LookupMaster.LookupID = a.ActivityTypeID AND GroupKey = 21) AS TaskType,
            a.Subject,
            ae.Act_ex1_35 AS SubjectDescription,
            ae.Act_ex1_37 AS Results,
            ae.Act_ex1_36 AS ResultsDescription,
            CASE 
                WHEN a.StatusID = 1 THEN ''Not Started'' 
                WHEN a.StatusID = 2 THEN ''In Progress'' 
                WHEN a.StatusID = 3 THEN ''On Hold''
                WHEN a.StatusID = 5 THEN ''Closed''  
            END AS Status,
            a.CreatedByName AS UserName,
            r.Name AS FinancialCenter,
            a.CreatedOn,
            a.Details,
            ROW_NUMBER() OVER (ORDER BY a.CreatedOn DESC) AS ROWNUMBER
        FROM ActivityBaseView a
        INNER JOIN act_ex1 ae ON a.OwnerId = ae.OwnerId AND a.ActivityID = ae.act_ex1_Id
        LEFT JOIN Accounts acc ON a.RelatedToAccountID = acc.AccountID
        LEFT JOIN LookUpMaster l ON l.LookUpId = a.ActivityTypeID AND l.OwnerId = 918 AND l.GroupKey = 21
        LEFT OUTER JOIN Regions r ON r.OwnerId = 918 AND a.BranchID = r.RegionID
        WHERE ' + @filter + '
            AND a.OwnerId = @ownerid
            AND (a.IsPersonal <> 1 OR a.AssignedTO = @userid)
            AND a.ItemTypeID = 1
            AND a.CreatedOn >= DATEADD(month, -13, GETDATE())
            AND a.layoutid NOT IN (207129, 207122, 207134)
            AND l.Name IN (''Phone Call'',''Email'',''Fax'',''General'',''Sales Call'',''Scan Documents'',''Text Message'',''TO Do'',''Video Connect'')
    )
    SELECT * FROM OrderedResults WHERE ROWNUMBER BETWEEN @startindex AND @endindex;
    ';

    -- Execute dynamic SQL
    EXEC sp_executesql @sql, N'@ownerid INT, @userid INT, @startindex INT, @endindex INT, @filter NVARCHAR(MAX)', 
                        @ownerid, @userid, @startindex, @endindex, @filter;

END;
GO

--exec ActivityReportData 918,'',1,10000000,'1=1'