IF OBJECT_ID('dbo.PG_Type_Converter') IS NOT NULL
	DROP FUNCTION dbo.PG_Type_Converter
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 14.05.2018
-- Alter date:	14.05.2018
-- Description:	конвертация типов MS SQL в Postgres
-- =============================================
CREATE FUNCTION dbo.PG_Type_Converter
(
	@SQL_Type VARCHAR(50),
	@max_length SMALLINT,	-- максимальная размерность типа, актуально для VARCHAR(10) - 10 будет размерность
	@precision	TINYINT,	-- кол-во разрядов всего, акутально для decimal(19,6) - 19 кол-во разрядов
	@scale		TINYINT		-- кол-во рязрядов после запятой, акутально для decimal(19,6) - 6 кол-во разрядов после запятой из 19
)
RETURNS VARCHAR(100)
AS
BEGIN 
	
	/*
	Excluded types:
		geography
		geometry
		hierarchyid
		sql_variant
		sysname
	*/

	RETURN
	CASE @SQL_Type
		WHEN 'bigint'			THEN 'BIGINT'
		WHEN 'binary'			THEN 'BYTEA'
		WHEN 'bit'				THEN 'BOOLEAN'
		WHEN 'char'				THEN 'CHAR(' + CAST(@max_length AS VARCHAR(5)) + ')'
		WHEN 'date'				THEN 'DATE'
		WHEN 'datetime'			THEN 'TIMESTAMP(3)'
		WHEN 'datetime2'		THEN 'TIMESTAMP(' + CAST(@precision AS VARCHAR(5)) + ')'
		WHEN 'datetimeoffset'	THEN 'TIMESTAMP(' + CAST(@precision AS VARCHAR(5)) + ') WITH TIME ZONE'
		WHEN 'decimal'			THEN 'DECIMAL(' + CAST(@precision AS VARCHAR(5)) + ',' + CAST(@scale AS VARCHAR(5)) + ')'
		WHEN 'float'			THEN 'DOUBLE PRECISION'
		WHEN 'image'			THEN 'BYTEA'
		WHEN 'int'				THEN 'INT'
		WHEN 'money'			THEN 'MONEY'
		WHEN 'nchar'			THEN 'CHAR(' + CAST(@max_length AS VARCHAR(5)) + ')'
		WHEN 'ntext'			THEN 'TEXT'
		WHEN 'numeric'			THEN 'NUMERIC(' + CAST(@precision AS VARCHAR(5)) + ',' + CAST(@scale AS VARCHAR(5)) + ')'
		WHEN 'nvarchar'			THEN  CASE WHEN @max_length = 8000 OR @max_length = -1 THEN 'TEXT' ELSE 'VARCHAR(' + CAST(@max_length AS VARCHAR(5)) + ')' END
		WHEN 'real'				THEN 'REAL'
		WHEN 'smalldatetime'	THEN 'TIMESTAMP(0)'
		WHEN 'smallint'			THEN 'SMALLINT'
		WHEN 'smallmoney'		THEN 'MONEY'
		WHEN 'text'				THEN 'TEXT'
		WHEN 'time'				THEN 'TIME(' + CAST(@precision AS VARCHAR(5)) + ')'
		WHEN 'timestamp'		THEN 'BYTEA'
		WHEN 'tinyint'			THEN 'SMALLINT'
		WHEN 'uniqueidentifier' THEN 'UUID'
		WHEN 'varbinary'		THEN 'BYTEA'
		WHEN 'varchar'			THEN CASE WHEN @max_length = 8000 OR @max_length = -1 THEN 'TEXT' ELSE 'VARCHAR(' + CAST(@max_length AS VARCHAR(5)) + ')' END
		-- This is User Type
		WHEN 'XDecimal'			THEN 'DECIMAL(19,6)'
		WHEN 'xml'				THEN 'XML'
		ELSE 'No_Type_Conversion'
	END
 
END
GO