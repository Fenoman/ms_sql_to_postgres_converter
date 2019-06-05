IF OBJECT_ID('dbo.PG_SQL_ExpCSV_Order_By') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_ExpCSV_Order_By
GO

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	список колонгок для условия ORDER BY для постраничного экспорта в CSV
-- =============================================
CREATE FUNCTION dbo.PG_SQL_ExpCSV_Order_By
(
	@PK_exists_object_id INT,
	@PK_exists_index_id INT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
		CASE 
			WHEN @PK_exists_index_id IS NOT NULL
				THEN 
					STUFF(
							(
								SELECT ', ' + QUOTENAME(COL_NAME(@PK_exists_object_id, ic.column_id))
								FROM sys.index_columns ic
								WHERE	ic.object_id = @PK_exists_object_id
									AND ic.index_id  = @PK_exists_index_id
									------------------------------------
									AND ic.is_included_column = 0
									------------------------------------
								ORDER BY ic.key_ordinal
								FOR XML path('')
							)
							, 1, 2, ''
						) 
			-- Если PK нет, то просто собираем все колонки
			ELSE	STUFF(
							(
								SELECT ', ' + QUOTENAME(c.name)
								FROM sys.columns AS C
								WHERE	c.object_id = @PK_exists_object_id
								ORDER BY c.column_id
								FOR XML path('')
							)
							, 1, 2, ''
						) 
		  END

END