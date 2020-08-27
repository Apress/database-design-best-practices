USE AdventureWorks2017;
SET STATISTICS IO ON;
GO
/*	Segment 3. Choosing the Correct Data Type

	Considerations into how to choose the best data type when building new database schema.
*/

CREATE TABLE dbo.account
(	account_id INT,
	name NVARCHAR(MAX),
	address_1 VARCHAR(50),
	address_2 VARCHAR(50),
	city VARCHAR(25),
	state_or_region VARCHAR(20),
	postal_code VARCHAR(25),
	create_date DATETIME,
	last_modified_date DATE,
	last_modified_by VARCHAR(50)
);
/*	NVARCHAR = 2 byte unicode characters
	VARCHAR = 1 byte non-unicode characters	*/

DECLARE @date DATE = GETUTCDATE();
SELECT @date;

DECLARE @time TIME = GETUTCDATE();
SELECT @time;

DECLARE @datetime2_0 DATETIME2(0) = GETUTCDATE();
SELECT @datetime2_0;
DECLARE @datetime2_3 DATETIME2(3) = GETUTCDATE();
SELECT @datetime2_3;
DECLARE @datetime2_6 DATETIME2(6) = GETUTCDATE();
SELECT @datetime2_6;

DECLARE @datetimeoffset0 DATETIMEOFFSET(0) = SYSDATETIME();
SELECT @datetimeoffset0;
DECLARE @datetimeoffset3 DATETIMEOFFSET(3) = SYSUTCDATETIME();
SELECT @datetimeoffset3;
DECLARE @datetimeoffset DATETIMEOFFSET = SYSDATETIMEOFFSET();
SELECT @datetimeoffset;

DECLARE @datetimeoffsetstickbuilt DATETIMEOFFSET = TODATETIMEOFFSET(SYSDATETIME(), '-04:00');
SELECT @datetimeoffsetstickbuilt;

DECLARE @decimal10_2 DECIMAL(10,2) = 123.4567890;
SELECT @decimal10_2;

DECLARE @decimal10_2_2 DECIMAL(10,2) = 123456789.4567890;
SELECT @decimal10_2_2;

DECLARE @decimal5_2 DECIMAL(5,2) = 17.25;
DECLARE @decimal7_4 DECIMAL(7,4) = 2.6667;
SELECT @decimal5_2 + @decimal7_4;
SELECT @decimal5_2 - @decimal7_4;
SELECT @decimal5_2 * @decimal7_4;
SELECT @decimal5_2 / @decimal7_4;

DECLARE @money1 DECIMAL(20,2) = 99.99;
DECLARE @money2 DECIMAL(20,2) = 15.00;
DECLARE @tax DECIMAL(6,4) = 1.08;
SELECT result = (@money1 + @money2) * @tax;

DECLARE @money3 MONEY = 99.99;
DECLARE @money4 MONEY = 123456789.0123456789;
SELECT @money3, @money4;

DECLARE @money5 SMALLMONEY = 99.99;
DECLARE @money6 SMALLMONEY = 123456.0123456789;
SELECT @money5, @money6;
GO

CREATE TABLE dbo.account_detail
(	account_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY CLUSTERED,
	account_name NVARCHAR(MAX),
	address_1 VARCHAR(100),
	address_2 VARCHAR(100),
	city VARCHAR(50),
	state_or_region VARCHAR(50),
	postal_code VARCHAR(50),
	create_date DATETIME2(3),
	last_modified_date DATETIME2(3),
	is_active BIT NOT NULL,
	active BIT,
	is_not_disabled BIT NOT NULL);

DECLARE @status_bitmap INT = 73; -- = 0001001001
GO

CREATE TABLE dbo.order_detail
(	order_detail_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_order_detail PRIMARY KEY CLUSTERED,
	account_id INT NOT NULL CONSTRAINT FK_order_detail FOREIGN KEY REFERENCES dbo.account_detail (account_id),
	order_time DATETIME2(3) NOT NULL,
	order_amount DECIMAL(10,2) NOT NULL,
	quantity INT NOT NULL,
	tax_percentage DECIMAL(4,4) NOT NULL,
	order_total AS (order_amount * quantity) * (1 + tax_percentage));
	
-- Create a test account
INSERT INTO dbo.account_detail
	(account_name, address_1, address_2, city, state_or_region, postal_code, create_date, last_modified_date, is_active, active, is_not_disabled)
VALUES (
	'Compuglobalhypermeganet',
	'1 Wall Street',
	'Suite #1',
	'New York',
	'NY',
	'10005',
	GETUTCDATE(),
	GETUTCDATE(),
	1,
	1,
	1);

-- Create a test order
INSERT INTO dbo.order_detail
	(account_id, order_time, order_amount, quantity, tax_percentage)
VALUES (
	1,
	GETUTCDATE(),
	'47.39',
	3,
	0.05);

SELECT
	*
FROM dbo.order_detail;












/*
drop table account_detail
drop table order_detail
*/