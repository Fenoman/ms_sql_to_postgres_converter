IF OBJECT_ID('dbo.PG_SQL_Convert_UniqueConstraints') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_UniqueConstraints
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	Конвертация ограничений уникальности
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_UniqueConstraints
(
	@T_object_id INT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
		ISNULL
		(
			(
				SELECT
				(
					SELECT	CHAR(9) + 'CONSTRAINT ' + kc.name 
							+ ' UNIQUE (' 
								+ 
								STUFF
								(
									(
										SELECT ', ' +  C.name
										FROM sys.indexes AS I
										INNER JOIN sys.index_columns AS IC
											ON  IC.object_id = I.object_id
											AND IC.index_id = I.index_id
											AND IC.is_included_column = 0
										INNER JOIN sys.columns AS C
											ON	C.object_id = IC.object_id
											AND C.column_id = IC.column_id
										WHERE 	I.object_id = kc.parent_object_id
											AND I.index_id = kc.unique_index_id
										ORDER BY IC.key_ordinal
										FOR XML path('')
									)
								, 1, 2, '')
							+ ')' 
							-- !!! Attention
							+ ' USING INDEX TABLESPACE ' + 'ts_indexes'
							-- !!! Attention
							+ IIF(kc_next.B_Exists IS NULL, '', ',')
							+ CHAR(10)
					FROM sys.key_constraints kc
					OUTER APPLY
					( 
						SELECT TOP 1 1 B_Exists
						FROM sys.key_constraints AS kc_next
						WHERE	kc_next.parent_object_id = kc.parent_object_id
							AND kc_next.object_id > kc.object_id
								-- Исключаем PK
							AND kc_next.type = 'UQ'
						ORDER BY kc_next.object_id ASC
					) kc_next
					WHERE	kc.parent_object_id = @T_object_id 
							-- Исключаем PK
							AND kc.type = 'UQ'
					ORDER BY kc.object_id ASC
					FOR XML path(''), TYPE
				).value('./text()[1]','varchar(max)')
			)
	, '')

END
GO