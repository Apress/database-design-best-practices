USE AdventureWorks2017;
SET STATISTICS IO ON;
GO

/*	Segment 6. Working with Database Metadata

	An introduction to the various system tables and views that can be used to report on, search, and understand database objects in SQL Server.
*/

SELECT
	schemas.name AS SchemaName,
	tables.name AS TableName,
	columns.name AS ColumnName,
	*
FROM sys.tables
INNER JOIN sys.columns
ON tables.object_id = columns.object_id
INNER JOIN sys.schemas
ON schemas.schema_id = tables.schema_id
WHERE tables.is_ms_shipped = 0
AND columns.name = 'SalesPersonID';

SELECT
	*
FROM sys.databases;

SELECT
	*
FROM sys.objects
WHERE is_ms_shipped = 0;

SELECT
	*
FROM sys.objects
WHERE is_ms_shipped = 0
AND type_desc = 'FOREIGN_KEY_CONSTRAINT';

SELECT
	*
FROM sys.foreign_keys;
SELECT
	*
FROM sys.foreign_key_columns;

WITH CTE_FOREIGN_KEY_COLUMNS AS (
	SELECT
		parent_schema.name AS parent_schema,
		parent_table.name AS parent_table,
		referenced_schema.name AS referenced_schema,
		referenced_table.name AS referenced_table,
		foreign_keys.name AS foreign_key_name,
		STUFF(( SELECT ', ' + referencing_column.name
				FROM sys.foreign_key_columns
				INNER JOIN sys.objects
				ON objects.object_id = foreign_key_columns.constraint_object_id
				INNER JOIN sys.tables parent_table
				ON foreign_key_columns.parent_object_id = parent_table.object_id
				INNER JOIN sys.schemas parent_schema
				ON parent_schema.schema_id = parent_table.schema_id
				INNER JOIN sys.columns referencing_column
				ON foreign_key_columns.parent_object_id = referencing_column.object_id 
				AND foreign_key_columns.parent_column_id = referencing_column.column_id
				INNER JOIN sys.columns referenced_column
				ON foreign_key_columns.referenced_object_id = referenced_column.object_id
				AND foreign_key_columns.referenced_column_id = referenced_column.column_id
				INNER JOIN sys.tables referenced_table
				ON referenced_table.object_id = foreign_key_columns.referenced_object_id
				INNER JOIN sys.schemas referenced_schema
				ON referenced_schema.schema_id = referenced_table.schema_id
				WHERE objects.object_id = foreign_keys.object_id
				ORDER BY foreign_key_columns.constraint_column_id ASC
			FOR XML PATH('')), 1, 2, '') AS foreign_key_column_list,
		STUFF(( SELECT ', ' + referenced_column.name
				FROM sys.foreign_key_columns
				INNER JOIN sys.objects
				ON objects.object_id = foreign_key_columns.constraint_object_id
				INNER JOIN sys.tables parent_table
				ON foreign_key_columns.parent_object_id = parent_table.object_id
				INNER JOIN sys.schemas parent_schema
				ON parent_schema.schema_id = parent_table.schema_id
				INNER JOIN sys.columns referencing_column
				ON foreign_key_columns.parent_object_id = referencing_column.object_id 
				AND foreign_key_columns.parent_column_id = referencing_column.column_id
				INNER JOIN sys.columns referenced_column
				ON foreign_key_columns.referenced_object_id = referenced_column.object_id
				AND foreign_key_columns.referenced_column_id = referenced_column.column_id
				INNER JOIN sys.tables referenced_table
				ON referenced_table.object_id = foreign_key_columns.referenced_object_id
				INNER JOIN sys.schemas referenced_schema
				ON referenced_schema.schema_id = referenced_table.schema_id
				WHERE objects.object_id = foreign_keys.object_id
				ORDER BY foreign_key_columns.constraint_column_id ASC
			FOR XML PATH('')), 1, 2, '') AS referenced_column_list
	FROM sys.foreign_keys
	INNER JOIN sys.tables parent_table
	ON foreign_keys.parent_object_id = parent_table.object_id
	INNER JOIN sys.schemas parent_schema
	ON parent_schema.schema_id = parent_table.schema_id
	INNER JOIN sys.tables referenced_table
	ON referenced_table.object_id = foreign_keys.referenced_object_id
	INNER JOIN sys.schemas referenced_schema
	ON referenced_schema.schema_id = referenced_table.schema_id)
SELECT
	db_name() AS database_name,
	parent_schema + ' --> ' + referenced_schema AS parent_and_referenced_schema,
	parent_table + ' --> ' + referenced_table AS parent_and_referenced_table,
	foreign_key_name AS objectname,
	foreign_key_column_list + ' --> ' + referenced_column_list AS key_column_list
FROM CTE_FOREIGN_KEY_COLUMNS
WHERE CTE_FOREIGN_KEY_COLUMNS.foreign_key_column_list LIKE '%SalesPersonID%'
OR CTE_FOREIGN_KEY_COLUMNS.referenced_column_list LIKE '%SalesPersonID%';

SELECT
	databases.name AS DatabaseName,
	master_files.name AS DBFileName,
	master_files.physical_name,
	CAST(CAST(master_files.size AS DECIMAL(24,0)) / 128.00 AS DECIMAL(24,2)) AS FileSizeInMB,
	CASE
		WHEN master_files.max_size = -1 THEN -1
		WHEN master_files.max_size = 0 THEN 0
		ELSE CAST(CAST(master_files.max_size AS DECIMAL(24,0)) / 128.00 AS INT) -- 0 = No growth allowed, -1 = No maximum size
	END AS MaxSizeMB
FROM sys.master_files
INNER JOIN sys.databases
ON master_files.database_id = databases.database_id;

SELECT DB_NAME() AS DbName, 
        name AS DBFileName, 
        type_desc AS FileTypeDesc,
        size/128.0 AS CurrentSizeMB,  
        size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
WHERE type IN (0,1);

CREATE TABLE #database_file_results
(DbName SYSNAME NOT NULL,
 DBFileName SYSNAME NOT NULL,
 FileTypeDesc VARCHAR(60) NOT NULL,
 CurrentSizeMB INT NOT NULL,
 FreeSpaceMB INT NOT NULL);
DECLARE @sql_command NVARCHAR(MAX) = '';
SELECT @sql_command = @sql_command + '
USE [' + databases.name + '];
SELECT DB_NAME() AS DbName, 
        name AS DBFileName, 
        type_desc AS FileTypeDesc,
        size/128.0 AS CurrentSizeMB,  
        size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
WHERE type IN (0,1);'
FROM sys.databases;
INSERT INTO #database_file_results
	(DbName, DBFileName, FileTypeDesc, CurrentSizeMB, FreeSpaceMB)
EXEC sp_executesql @sql_command;

SELECT * FROM #database_file_results;
DROP TABLE #database_file_results;

SELECT
	*
FROM sys.sql_modules;

SELECT
	db_name() AS database_name,
	parent_schema.name AS schema_name,
	parent_object.name AS table_name,
	child_object.name AS objectname,
	sql_modules.definition AS object_definition,
	CASE child_object.type 
		WHEN 'P' THEN 'Stored Procedure'
		WHEN 'RF' THEN 'Replication Filter Procedure'
		WHEN 'V' THEN 'View'
		WHEN 'TR' THEN 'DML Trigger'
		WHEN 'FN' THEN 'Scalar Function'
		WHEN 'IF' THEN 'Inline Table Valued Function'
		WHEN 'TF' THEN 'SQL Table Valued Function'
		WHEN 'R' THEN 'Rule'
	END	AS object_type
FROM sys.sql_modules
INNER JOIN sys.objects child_object
ON sql_modules.object_id = child_object.object_id
LEFT JOIN sys.objects parent_object
ON parent_object.object_id = child_object.parent_object_id
LEFT JOIN sys.schemas parent_schema
ON child_object.schema_id = parent_schema.schema_id
WHERE sql_modules.definition LIKE '%SalesOrderHeader%';

SELECT
	db_name() AS database_name,
	parent_schema.name AS schema_name,
	parent_object.name AS table_name,
	child_object.name AS objectname,
	sql_modules.definition AS object_definition,
	CASE child_object.type 
		WHEN 'P' THEN 'Stored Procedure'
		WHEN 'RF' THEN 'Replication Filter Procedure'
		WHEN 'V' THEN 'View'
		WHEN 'TR' THEN 'DML Trigger'
		WHEN 'FN' THEN 'Scalar Function'
		WHEN 'IF' THEN 'Inline Table Valued Function'
		WHEN 'TF' THEN 'SQL Table Valued Function'
		WHEN 'R' THEN 'Rule'
	END	AS object_type
FROM sys.sql_modules
INNER JOIN sys.objects child_object
ON sql_modules.object_id = child_object.object_id
LEFT JOIN sys.objects parent_object
ON parent_object.object_id = child_object.parent_object_id
LEFT JOIN sys.schemas parent_schema
ON child_object.schema_id = parent_schema.schema_id
WHERE parent_object.name = 'PurchaseOrderDetail';


	