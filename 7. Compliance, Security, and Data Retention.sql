USE AdventureWorks2017;
SET STATISTICS IO ON;
GO

/*	Segment 8. Compliance, Security, and Data Retention

	Discuss how data retention and security can impact data and how we store and maintain it.
*/

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
	last_modified_by_username VARCHAR(25) NULL
);