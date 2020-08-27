USE AdventureWorks2017;
SET STATISTICS IO ON;
GO

/*	Segment 5. Naming Conventions

	Consistent and clearly defined naming of database objects allows for easier and more accurate development!
*/

-- Precise and descriptive object names are best!
CREATE PROCEDURE dbo.process_data
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT TOP 1
		SalesOrderHeader.SalesOrderID
	FROM Sales.SalesOrderHeader
	WHERE SalesOrderHeader.Status <> 5;
END
GO

ALTER TABLE Sales.SalesOrderHeader ADD name VARCHAR(50) NULL;
GO

CREATE DATABASE Account_Metrics_SQL_Server_v2017;
GO

ALTER TABLE HumanResources.Employee ADD active BIT NOT NULL;
ALTER TABLE HumanResources.Employee ADD is_active BIT NOT NULL;
ALTER TABLE HumanResources.Employee ADD is_not_active BIT NOT NULL;
ALTER TABLE HumanResources.Employee ADD is_inactive BIT NOT NULL;
ALTER TABLE HumanResources.Employee ADD is_disabled BIT NOT NULL;
ALTER TABLE HumanResources.Employee ADD is_not_disabled BIT NOT NULL;

CREATE TABLE dbo.SRC_ACCT_DET
	(id INT NOT NULL CONSTRAINT PK_SRC_ACCT_DET PRIMARY KEY CLUSTERED,
	 PRT_ACCT_id INT NULL,
	 CNT_id INT NULL,
	 Addr1 VARCHAR(50) NOT NULL,
	 Addr2 VARCHAR(50) NULL,
	 city VARCHAR(25) NOT NULL,
	 reg VARCHAR(25) NOT NULL,
	 zip VARCHAR(25) NOT NULL,
	 lst_mod_by VARCHAR(50) NOT NULL,
	 crt_dt DATE);

CREATE TABLE dbo.common_reserved_words
(	object_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_reserved_words PRIMARY KEY CLUSTERED,
	state BIT NOT NULL,
	server VARCHAR(100) NOT NULL,
	type TINYINT NOT NULL,
	address VARCHAR(100) NOT NULL
);

SELECT
	tables.name AS columnname,
	columns.name AS tablename,
	*
FROM sys.tables
INNER JOIN sys.columns
ON tables.object_id = columns.object_id
WHERE columns.name LIKE '%account_id%'