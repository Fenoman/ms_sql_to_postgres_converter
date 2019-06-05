IF OBJECT_ID('dbo.PG_SQL_Excluded_Tables_For_ImpExp') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Excluded_Tables_For_ImpExp
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	Исключенные таблицы для импорта и экспорта данных
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Excluded_Tables_For_ImpExp
(
	@t_name	VARCHAR(255) -- имя таблицы со схемой
)
RETURNS bit
AS
BEGIN 
	RETURN	CASE 
				WHEN @t_name 
					NOT IN ('dbo.Example_Table_0',
							'dbo.Example_Table_1')
					AND @t_name NOT LIKE 'dbo.Example[_]%'
				THEN 0 -- Не исключена
				ELSE 1 -- Исключена
			END
END