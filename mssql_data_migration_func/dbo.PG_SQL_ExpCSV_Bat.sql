IF OBJECT_ID('dbo.PG_SQL_ExpCSV_Bat') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_ExpCSV_Bat
GO

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	формирование bat для экспорта в CSV
-- =============================================
CREATE FUNCTION dbo.PG_SQL_ExpCSV_Bat
(
	@s_name					VARCHAR(255),
	@t_name					VARCHAR(255),
	@Path_to_W_gsqlcmd		VARCHAR(255),
	@gsqlcmd_connection		VARCHAR(255),
	@Path_to_W_CSV			VARCHAR(255),
	@PK_exists_object_id	INT, 
	@PK_exists_index_id		INT,
	@N_Split				INT,
	@Row_Cnt				INT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	DECLARE @N_Offset INT = 0		-- сколько строчек пропустить
	DECLARE @i INT = 0				-- Счетчик
	DECLARE @Bat VARCHAR(max) = ''	-- сформированная команда экспорта

	WHILE @N_Offset < @Row_Cnt
	BEGIN
		SET @Bat = @Bat +
		'"' + @Path_to_W_gsqlcmd 
			+ 'gsqlcmd.exe" ' + @gsqlcmd_connection 
			+ ' "SELECT * FROM [' + @s_name + '].[' + @t_name + '] ORDER BY ' + dbo.PG_SQL_ExpCSV_Order_By(@PK_exists_object_id, @PK_exists_index_id) 
			+ ' OFFSET ' + CAST(@N_Offset AS VARCHAR(255)) + ' ROWS FETCH NEXT ' + CAST(@N_Split AS VARCHAR(255)) + ' ROWS ONLY" ' 
			+ @Path_to_W_CSV + @s_name + '.' + @t_name 
			+ '_' + CAST(@i AS VARCHAR(255)) + '.csv /asCsv /separator=, /outputcodepage=65001 /commandTimeout=99999 /connectionTimeout=99999'
			+ CHAR(10) + IIF(dbo.PG_SQL_Excluded_Tables_For_ImpExp(@s_name + '.' + @t_name) = 0, '', NULL)

		SET @N_Offset = @N_Offset + @N_Split
		SET @i = @i + 1
	END
	RETURN @Bat
		

END