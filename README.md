# Phone-Logs-All-V2
This repository contains the SQL script to generate the **Phone Logs - All V2** report under the `Activity Report` category. This report is designed to provide detailed insights into phone logs created within the last 13 months, targeting specific task objects and excluding prospect, partner, or sponsorship tasks.

## Key Features of the Report

- **Target Object**: Tasks (Phone Logs)
- **Fields Included**:
  - Member Account Number
  - Member Name
  - Task Type
  - Subject
  - Subject Description
  - Results
  - Results Description
  - Status
  - Created By
  - Financial Center
  - Created On
- **Date Filter**: The report includes logs created within the last 13 months, starting from the current day as the reference date.
  - For example, if the report is run on **April 16, 2024**, the data will show logs created since **March 16, 2023**.
- **Sorting**: Logs are sorted in descending order by creation date to prioritize the most recent logs.
- **Access Control**: No restrictions on who can view this report.
- **SQL Queries**: The SQL queries are optimized to efficiently filter, sort, and present the required data.

## SQL Script

The SQL script used for generating the report is available in the `SQL/phone_logs_all_v2.sql` file. Here's a brief overview of the query logic:

1. **Selecting Required Fields**:
    - `Member Account Number`, `Member Name`, `Task Type`, and others are selected from the relevant tables (`Accounts`, `ActivityBaseView`, etc.).
2. **Filtering Data**:
    - The report filters tasks that have been created in the last 13 months based on the current date.
3. **Sorting**:
    - Data is sorted by the `CreatedOn` field in descending order.
4. **Excluding Unwanted Tasks**:
    - Tasks related to prospects, partners, and sponsorship are excluded.

## Example Usage

To generate this report, run the following SQL script:

```sql
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
            WHEN a.StatusID = 1 THEN 'Not Started' 
            WHEN a.StatusID = 2 THEN 'In Progress' 
            WHEN a.StatusID = 3 THEN 'On Hold'
            WHEN a.StatusID = 5 THEN 'Closed'  
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
    WHERE a.OwnerId = 918 
        AND (a.IsPersonal <> 1 OR a.AssignedTO = 4254) 
        AND a.ItemTypeID = 1
        AND a.CreatedOn >= DATEADD(month, -13, GETDATE()) 
        AND a.layoutid NOT IN (207129, 207122, 207134) 
        AND l.Name IN ('Phone Call', 'Email', 'Fax', 'General', 'Sales Call', 'Scan Documents', 'Text Message', 'TO Do', 'Video Connect')
)
SELECT * 
FROM OrderedResults 
WHERE ROWNUMBER >= 1 
ORDER BY CreatedOn DESC;
