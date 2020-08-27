USE AdventureWorks2017;
SET STATISTICS IO ON;
GO

/*	Segment 9. NULL and NOT NULL - Which to Use and When

	Discuss what NULL means and how to best use it to avoid confusion, bad data, or other app issues.
*/

CREATE TABLE dbo.account_all_null
(	account_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_account PRIMARY KEY CLUSTERED,
	account_name VARCHAR(50),
	address_1 VARCHAR(100),
	address_2 VARCHAR(100),
	city VARCHAR(50),
	state_or_region VARCHAR(50),
	postal_code VARCHAR(25),
	create_time DATETIME2(3),
	created_by_username VARCHAR(25),
	last_modified_time DATETIME2(3),
	last_modified_by_username VARCHAR(25)
);
GO

CREATE TABLE dbo.account
(	account_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_account PRIMARY KEY CLUSTERED,
	account_name VARCHAR(50) NOT NULL,
	address_1 VARCHAR(100) NOT NULL,
	address_2 VARCHAR(100) NULL,
	city VARCHAR(50) NOT NULL,
	state_or_region VARCHAR(50) NOT NULL,
	postal_code VARCHAR(25) NOT NULL,
	create_time DATETIME2(3) NOT NULL,
	created_by_username VARCHAR(25) NOT NULL,
	last_modified_time DATETIME2(3) NULL,
	last_modified_by_username VARCHAR(25) NULL);

SELECT
	*
FROM HumanResources.Employee
WHERE OrganizationNode = NULL;

SELECT
	*
FROM HumanResources.Employee
WHERE OrganizationNode IS NULL;

DECLARE @test_string VARCHAR(100) = 'The test numbers are: ';
DECLARE @number1 INT = 1, @number2 INT = 2, @number3 INT = NULL;
SELECT @test_string = CAST(@number1 AS VARCHAR(100)) + CAST(@number2 AS VARCHAR(100)) + CAST(@number3 AS VARCHAR(100));
SELECT @test_string;

SELECT
	COUNT(OrganizationLevel) AS OrganizationLevel_count,
	COUNT(*) AS Organization_rowcount,
	SUM(OrganizationLevel) AS OrganizationLevel_sum,
	MIN(OrganizationLevel) AS OrganizationLevel_min,
	MAX(OrganizationLevel) AS OrganizationLevel_max
FROM HumanResources.Employee;

SELECT
	COUNT(OrganizationLevel) AS OrganizationLevel_count,
	COUNT(*) AS Organization_rowcount,
	SUM(OrganizationLevel) AS OrganizationLevel_sum,
	MIN(OrganizationLevel) AS OrganizationLevel_min,
	MAX(OrganizationLevel) AS OrganizationLevel_max
FROM HumanResources.Employee
WHERE OrganizationLevel IS NOT NULL;

CREATE TABLE dbo.account
(	account_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_account PRIMARY KEY CLUSTERED,
	account_name VARCHAR(50) NOT NULL,
	address_1 VARCHAR(100) NOT NULL,
	address_2 VARCHAR(100) NULL,
	city VARCHAR(50) NOT NULL,
	state_or_region VARCHAR(50) NOT NULL,
	postal_code VARCHAR(25) NOT NULL,
	create_time DATETIME2(3) NOT NULL,
	created_by_username VARCHAR(25) NOT NULL,
	last_modified_time DATETIME2(3) NULL,
	last_modified_by_username VARCHAR(25) NULL);

CREATE TABLE dbo.account
(	account_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_account PRIMARY KEY CLUSTERED,
	account_name VARCHAR(50) NOT NULL,
	address_1 VARCHAR(100) NOT NULL,
	address_2 VARCHAR(100) NULL,
	city VARCHAR(50) NOT NULL,
	state_or_region VARCHAR(50) NOT NULL,
	postal_code VARCHAR(25) NOT NULL,
	create_time DATETIME2(3) NOT NULL,
	created_by_username VARCHAR(25) NOT NULL);

CREATE TABLE dbo.account_log
(	account_log_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_account_log PRIMARY KEY CLUSTERED,
	account_id INT NOT NULL CONSTRAINT FK_account_log_account FOREIGN KEY REFERENCES dbo.account (account_id),
	last_modified_time DATETIME2(3) NULL,
	last_modified_by_username VARCHAR(25) NULL);

