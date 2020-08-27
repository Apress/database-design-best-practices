USE AdventureWorks2017;
SET STATISTICS IO ON;
GO
/*	Segment 7. Data Integrity and Relational Database Design

	Discuss relational and non-relational data, as well as data integrity, ACID, and the use of contraints/triggers
	to enforce important rules.
*/

CREATE TABLE Sales.SalesOrderHeader(
	SalesOrderID int IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	RevisionNumber tinyint NOT NULL,
	OrderDate datetime NOT NULL,
	DueDate datetime NOT NULL,
	ShipDate datetime NULL,
	Status tinyint NOT NULL,
	OnlineOrderFlag dbo.Flag NOT NULL,
	SalesOrderNumber  AS (isnull(N'SO'+CONVERT(nvarchar(23),SalesOrderID),N'*** ERROR ***')),
	PurchaseOrderNumber dbo.OrderNumber NULL,
	AccountNumber dbo.AccountNumber NULL,
	CustomerID int NOT NULL,
	SalesPersonID int NULL,
	TerritoryID int NULL,
	BillToAddressID int NOT NULL,
	ShipToAddressID int NOT NULL,
	ShipMethodID int NOT NULL,
	CreditCardID int NULL,
	CreditCardApprovalCode varchar(15) NULL,
	CurrencyRateID int NULL,
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	TotalDue  AS (isnull((SubTotal+TaxAmt)+Freight,(0))),
	Comment nvarchar(128) NULL,
	rowguid uniqueidentifier ROWGUIDCOL  NOT NULL,
	ModifiedDate datetime NOT NULL,
 CONSTRAINT PK_SalesOrderHeader_SalesOrderID PRIMARY KEY CLUSTERED 
	(SalesOrderID ASC));

CREATE TABLE Sales.SalesOrderDetail(
	SalesOrderID int NOT NULL CONSTRAINT FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID FOREIGN KEY(SalesOrderID) REFERENCES Sales.SalesOrderHeader (SalesOrderID) ON DELETE CASCADE,
	SalesOrderDetailID int IDENTITY(1,1) NOT NULL,
	CarrierTrackingNumber nvarchar(25) NULL,
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  AS (isnull((UnitPrice*((1.0)-UnitPriceDiscount))*OrderQty,(0.0))),
	rowguid uniqueidentifier ROWGUIDCOL  NOT NULL,
	ModifiedDate datetime NOT NULL,
 CONSTRAINT PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID PRIMARY KEY CLUSTERED 
	(SalesOrderID ASC, SalesOrderDetailID ASC));

INSERT INTO Sales.SalesOrderDetail
	(SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
VALUES (
	-1,
	'C12345',
	1,
	4,
	1,
	17.00,
	0.00,
	NEWID(),
	GETUTCDATE());

ALTER TABLE Sales.SalesOrderDetail ADD CONSTRAINT DF_SalesOrderDetail_UnitPriceDiscount DEFAULT (0.0) FOR UnitPriceDiscount;
GO

ALTER TABLE Sales.SalesOrderDetail WITH CHECK ADD CONSTRAINT CK_SalesOrderDetail_UnitPrice CHECK ([UnitPrice]>=0.00);
GO

ALTER TABLE Production.Product WITH CHECK ADD CONSTRAINT CK_Product_Class CHECK (upper([Class])='H' OR upper([Class])='M' OR upper([Class])='L' OR [Class] IS NULL)
GO

USE AdventureWorksDW2017
GO

CREATE PROCEDURE dbo.validate_call_center_data
	@validation_date DATE
AS
BEGIN
	IF EXISTS (SELECT * FROM dbo.FactCallCenter WHERE [Shift] = 'midnight' AND TotalOperators > 10 AND DateKey = @validation_date)
	BEGIN
		INSERT INTO dbo.Exceptions
			(FactCallCenterID, ExceptionTime, ExceptionEntity, ExceptionMessage)
		SELECT
			FactCallCenter.FactCallCenterID,
			GETUTCDATE() AS ExceptionTime,
			'FactCallCenter' AS ExceptionEntity,
			'Too many operators on call at midnight shift' AS ExceptionMessage
		FROM dbo.FactCallCenter
		WHERE [Shift] = 'midnight'
		AND TotalOperators > 10
		AND DateKey = @validation_date;
	END

	IF (SELECT COUNT(*) FROM dbo.FactCallCenter WHERE DateKey = @validation_date) < 100
	BEGIN
		INSERT INTO dbo.Exceptions
			(FactCallCenterID, ExceptionTime, ExceptionEntity, ExceptionMessage)
		SELECT
			FactCallCenter.FactCallCenterID,
			GETUTCDATE() AS ExceptionTime,
			'FactCallCenter' AS ExceptionEntity,
			'Not enough rows added today.  Please check load process for exceptions.' AS ExceptionMessage
		FROM dbo.FactCallCenter
		WHERE DateKey = @validation_date;
	END
END
GO
