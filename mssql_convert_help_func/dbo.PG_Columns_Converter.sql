IF OBJECT_ID('dbo.PG_Columns_Converter') IS NOT NULL
	DROP FUNCTION dbo.PG_Columns_Converter
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Мапинг одних типов колонок на другие + конвертация в типы Postgres
-- =============================================
CREATE FUNCTION dbo.PG_Columns_Converter
(
	@column_name VARCHAR(255),
	@table_name VARCHAR(255),
	@SQL_Type VARCHAR(50),
	@max_length SMALLINT,	-- максимальная размерность типа, актуально для VARCHAR(10) - 10 будет размерность
	@precision	TINYINT,	-- кол-во разрядов всего, акутально для decimal(19,6) - 19 кол-во разрядов
	@scale		TINYINT		-- кол-во рязрядов после запятой, акутально для decimal(19,6) - 6 кол-во разрядов после запятой из 19
)
RETURNS VARCHAR(100)
AS
BEGIN 
	
	RETURN
	CASE 
	/*	-- Examples
		WHEN @column_name IN (	'SomeColumn0' OR @table_name IN ('SomeTable0') AND @column_name = 'Column0'
			THEN 'INT' 
		WHEN @column_name IN (	'SomeColumn1') OR @table_name IN ('SomeTable1') AND @column_name = 'Column1'
			THEN 'SMALLINT' 
		WHEN @table_name IN ('SomeTable2') AND @column_name = 'Column2'
			THEN 'SMALLINT' 
		WHEN @table_name IN ('SomeTable3') AND @column_name = 'Column3'
			THEN 'INT' 
		WHEN @column_name = 'Column4'
			THEN 'INT'
  */
		WHEN 1 = 0 THEN ''
		ELSE dbo.PG_Type_Converter(@SQL_Type, @max_length, @precision, @scale) 
	END

END
GO