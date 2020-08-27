USE AdventureWorks2017;
SET STATISTICS IO ON;
GO
/*	Segment 2. OLAP vs. OLTP - Separating Transactional and Analytic Workloads
	Show how OLAP and OLTP data are different and how data structures should be built to accomodate each.
*/
GO

-- Example of a narrow OLTP search query
SELECT
	SalesOrderHeader.OrderDate,
	SalesOrderHeader.DueDate,
	SalesOrderHeader.ShipDate,
	SalesOrderHeader.Status,
	SalesOrderHeader.PurchaseOrderNumber,
	SalesOrderHeader.AccountNumber,
	SalesOrderDetail.OrderQty,
	SalesOrderDetail.UnitPrice
FROM sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
WHERE SalesOrderHeader.SalesOrderNumber = 'SO43659'
ORDER BY SalesOrderDetail.SalesOrderDetailID ASC;

-- Example of a wide OLAP search query
SELECT
	COUNT(*) AS LineItemCount,
	SUM(SalesOrderDetail.UnitPrice) AS TotalUnitPrice
FROM sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
WHERE SalesOrderDetail.UnitPrice > 1000.000
AND SalesOrderHeader.OrderDate >= '1/1/2011'
AND SalesOrderHeader.OrderDate < '1/1/2012';

CREATE TABLE dbo.fact_SalesOrderSummary
(	OrderDate DATE NOT NULL CONSTRAINT PK_fact_SalesOrderSummary PRIMARY KEY CLUSTERED,
	OrderCount INT NOT NULL,
	OrderDetailCount INT NOT NULL,
	LineItemCountGreaterThan1kUnitPrice INT NOT NULL,
	LineItemTotalGreaterThan1kUnitPrice MONEY NOT NULL,
	TotalDue MONEY NOT NULL);

INSERT INTO dbo.fact_SalesOrderSummary
	(OrderDate, OrderCount, OrderDetailCount, LineItemCountGreaterThan1kUnitPrice, LineItemTotalGreaterThan1kUnitPrice,TotalDue)
SELECT
	CAST(SalesOrderHeader.OrderDate AS DATE) AS OrderDate,
	COUNT(DISTINCT SalesOrderHeader.SalesOrderID) AS OrderCount,
	COUNT(DISTINCT SalesOrderDetail.SalesOrderDetailID) AS OrderDetailCount,
	SUM(CASE WHEN SalesOrderDetail.UnitPrice > 1000.000 THEN 1 ELSE 0 END) AS LineItemCountGreaterThan1kUnitPrice,
	SUM(CASE WHEN SalesOrderDetail.UnitPrice > 1000.000 THEN SalesOrderDetail.UnitPrice ELSE 0 END) AS LineItemTotalGreaterThan1kUnitPrice,
	SUM(SalesOrderHeader.TotalDue) AS TotalDue
FROM sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
GROUP BY CAST(SalesOrderHeader.OrderDate AS DATE)
ORDER BY CAST(SalesOrderHeader.OrderDate AS DATE);

SELECT
	SUM(fact_SalesOrderSummary.LineItemCountGreaterThan1kUnitPrice) AS LineItemCount,
	SUM(fact_SalesOrderSummary.LineItemTotalGreaterThan1kUnitPrice) AS TotalUnitPrice
FROM dbo.fact_SalesOrderSummary
WHERE fact_SalesOrderSummary.OrderDate >= '1/1/2011'
AND fact_SalesOrderSummary.OrderDate < '1/1/2012';

CREATE TABLE Sales.SalesOrderHeader_COLUMNSTORE
(	SalesOrderID INT NOT NULL,
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
	SalesOrderDetailID int NOT NULL,
	CarrierTrackingNumber nvarchar(25) NULL,
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  MONEY NOT NULL);

CREATE CLUSTERED INDEX CI_SalesOrderHeader_COLUMNSTORE ON Sales.SalesOrderHeader_COLUMNSTORE (OrderDate);

INSERT INTO Sales.SalesOrderHeader_COLUMNSTORE
	(SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID,
	 BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, SalesOrderDetailID, CarrierTrackingNumber, 
	 OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, LineTotal)
SELECT
	(100000 * Employee.BusinessEntityID) + SalesOrderHeader.SalesOrderID AS SalesOrderID,
	SalesOrderHeader.RevisionNumber,
	SalesOrderHeader.OrderDate,
	SalesOrderHeader.DueDate,
	SalesOrderHeader.ShipDate,
	SalesOrderHeader.Status,
	SalesOrderHeader.OnlineOrderFlag,
	SalesOrderHeader.PurchaseOrderNumber,
	SalesOrderHeader.AccountNumber,
	SalesOrderHeader.CustomerID,
	SalesOrderHeader.SalesPersonID,
	SalesOrderHeader.TerritoryID,
	SalesOrderHeader.BillToAddressID,
	SalesOrderHeader.ShipToAddressID,
	SalesOrderHeader.ShipMethodID,
	SalesOrderHeader.CreditCardID,
	SalesOrderHeader.CreditCardApprovalCode,
	SalesOrderHeader.CurrencyRateID,
	SalesOrderHeader.SubTotal,
	SalesOrderHeader.TaxAmt,
	SalesOrderHeader.Freight,
	(150000 * Employee.BusinessEntityID) + SalesOrderDetail.SalesOrderDetailID AS SalesOrderDetailID,
	SalesOrderDetail.CarrierTrackingNumber, 
	SalesOrderDetail.OrderQty,
	SalesOrderDetail.ProductID,
	SalesOrderDetail.SpecialOfferID,
	SalesOrderDetail.UnitPrice,
	SalesOrderDetail.UnitPriceDiscount,
	SalesOrderDetail.LineTotal
FROM sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
CROSS JOIN HumanResources.Employee
WHERE Employee.BusinessEntityID <= 100;

DROP INDEX CI_SalesOrderHeader_COLUMNSTORE ON Sales.SalesOrderHeader_COLUMNSTORE;
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCI_SalesOrderHeader_COLUMNSTORE ON Sales.SalesOrderHeader_COLUMNSTORE WITH (MAXDOP = 1);

SELECT
	COUNT(*) AS LineItemCount,
	SUM(SalesOrderHeader_COLUMNSTORE.UnitPrice) AS TotalUnitPrice
FROM Sales.SalesOrderHeader_COLUMNSTORE
WHERE SalesOrderHeader_COLUMNSTORE.UnitPrice > 1000.000
AND SalesOrderHeader_COLUMNSTORE.OrderDate >= '1/1/2011'
AND SalesOrderHeader_COLUMNSTORE.OrderDate < '1/1/2012';




















-- Cleanup
DROP TABLE Sales.SalesOrderHeader_COLUMNSTORE;
DROP TABLE dbo.fact_SalesOrderSummary;
