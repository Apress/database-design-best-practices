USE AdventureWorks2017;
SET STATISTICS IO ON;
/*	Segment 4. Application Needs

	Building database schema to meet the needs of an application.
*/
GO

-- Deleting old data that is no longer needed:
DECLARE @one_month_ago DATE = DATEADD(MONTH, -1, CAST(GETUTCDATE() AS DATE));
DELETE FROM sales.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate < @one_month_ago;

-- Archiving old data that is no longer needed in production, but may be needed for compliance, reporting, or audit purposes:
DELETE FROM sales.SalesOrderHeader
OUTPUT DELETED.CustomerID,
	   DELETED.DueDate,
	   DELETED.ModifiedDate,
	   DELETED.OnlineOrderFlag,
	   DELETED.OrderDate,
	   DELETED.PurchaseOrderNumber,
	   DELETED.SalesOrderID,
	   DELETED.SalesOrderNumber,
	   DELETED.SalesPersonID,
	   DELETED.TaxAmt,
	   DELETED.TerritoryID,
	   DELETED.TotalDue
INTO archive.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate < @one_month_ago;

-- Add an is_archived flag to support keeping data in-place, but being able to filter it from some queries.
ALTER TABLE sales.SalesOrderHeader ADD is_archived BIT NOT NULL CONSTRAINT DF_SalesOrderHeader_is_archived DEFAULT (0);

UPDATE sales.SalesOrderHeader
	SET is_archived = 1
WHERE SalesOrderHeader.OrderDate < @one_month_ago;

CREATE TABLE dbo.employee_demo
(	employee_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_employee_demo PRIMARY KEY CLUSTERED,
	employee_name NVARCHAR(100) NOT NULL, -- NVARCHAR to support multi-byte characters
	internal_status_code VARCHAR(5) NOT NULL, -- Can be VARCHAR as it is internal to the app and not customer-facing.
	tag_details NVARCHAR(100) COLLATE Chinese_PRC_CI_AS NOT NULL 
);
GO

SELECT TOP 1
	SalesOrderID,
	CustomerID,
	Status,
	DueDate
FROM sales.SalesOrderHeader
WHERE Status <> 5
AND CustomerID = 29825;

CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_covering ON sales.SalesOrderHeader (CustomerID, Status) INCLUDE (DueDate, SalesOrderID);
GO

