IF OBJECT_ID('dbo.PG_SQL_ImpCSV') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_ImpCSV
GO

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	Формирование скрипта для импорта из CSV с разбивкой
-- =============================================
CREATE FUNCTION dbo.PG_SQL_ImpCSV
(
	@s_name					VARCHAR(255),
	@t_name					VARCHAR(255),
	@Path_to_L_CSV			VARCHAR(255),
	@t_object_id			INT,
	@N_Split				INT,
	@Row_Cnt				INT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	DECLARE @N_Offset INT = 0		-- сколько строчек пропустить
	DECLARE @i INT = 0				-- Счетчик
	DECLARE @SQL VARCHAR(max) = ''	-- сформированная команда импорта

	WHILE @N_Offset < @Row_Cnt
	BEGIN
		SET @SQL = @SQL +
		'copy ' + dbo.PG_SchemeMapping(@s_name) + '.' + @t_name + CHAR(10) + 
		'(' + CHAR(10) +
			dbo.PG_SQL_DataImport_Columns_CSV(@t_object_id, @s_name + '.' + @t_name) + CHAR(10) +
		')' + CHAR(10) + 
		'FROM ''' + @Path_to_L_CSV + ''+ @s_name +'.' + @t_name + '_' + CAST(@i AS VARCHAR(255)) + '.csv'' DELIMITER AS '','' CSV HEADER;' + CHAR(10) + CHAR(10)
		
		SET @N_Offset = @N_Offset + @N_Split
		SET @i = @i + 1
	END
	RETURN @SQL
		

END