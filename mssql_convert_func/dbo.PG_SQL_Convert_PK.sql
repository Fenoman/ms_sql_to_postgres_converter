IF OBJECT_ID('dbo.PG_SQL_Convert_PK') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_PK
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	Конвертация PK
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_PK
(
	@PK_exists_object_id INT,
	@PK_exists_index_id INT,
	@PK_exists_name VARCHAR(255),
	@cc_exists_B_Exists BIT,
	@kc_exists_B_Exists BIT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
		CASE 
			WHEN @PK_exists_index_id IS NOT NULL
				THEN CHAR(9) + 'CONSTRAINT ' + @PK_exists_name + ' PRIMARY KEY' 
					+ ' (' 
					+ STUFF(
								(
									SELECT ', ' + COL_NAME(@PK_exists_object_id, ic.column_id)
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
					+ ')'  
					-- !!! Attention
					+ ' USING INDEX TABLESPACE ' + 'ts_indexes'
					-- !!! Attention
					-- Ставим в конце запятую или нет
					+ IIF(@cc_exists_B_Exists IS NULL AND @kc_exists_B_Exists IS NULL, '', ',')
					+ CHAR(10)
			ELSE ''
		  END

END
GO