IF OBJECT_ID('dbo.PG_SQL_DataImport_Columns_CSV') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_DataImport_Columns_CSV
GO

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 02.07.2018
-- Alter date:	02.07.2018
-- Description:	Список колонок для запроса импорта данных через CSV
-- =============================================
CREATE FUNCTION dbo.PG_SQL_DataImport_Columns_CSV
(
	@T_object_id INT,
	@T_name VARCHAR(255)
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
	REVERSE(STUFF(REVERSE
	(
		(
			SELECT 
				-- табулятор для красоты
				CHAR(9) + 
				-- колонки
				IIF(ISNUMERIC(C.name) = 1, '"' + C.name + '"', C.name) + ',' + CHAR(10)
			FROM sys.columns AS C
			INNER JOIN sys.types AS Ts
				ON  Ts.system_type_id = c.system_type_id
				AND Ts.user_type_id = c.user_type_id
			WHERE C.object_id = @T_object_id
				-- Исключаемые таблицы
				AND dbo.PG_SQL_Excluded_Tables_For_ImpExp(@T_name) = 0
			ORDER BY 
					-- порядок колонок строгий, именно в такой порядоке формируются CSV файлы
					c.column_id ASC
			FOR XML path(''), TYPE
		).value('./text()[1]','varchar(max)')
	), 1, 2, '' ))

END
GO

