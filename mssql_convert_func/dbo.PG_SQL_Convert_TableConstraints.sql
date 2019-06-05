IF OBJECT_ID('dbo.PG_SQL_Convert_TableConstraints') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_TableConstraints
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 25.05.2018
-- Alter date:	25.05.2018
-- Description:	Конвертация ограничений на таблицу
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_TableConstraints
(
	@T_object_id INT,
	@kc_exists_B_Exists BIT
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
					SELECT	CHAR(9) + 'CONSTRAINT ' + cc.name 
							+ ' CHECK (' 
								+	dbo.PG_Add_Brackets(
										dbo.PG_Replace_Pattern(
											dbo.PG_Remove_Brackets(
												dbo.PG_CheckConstraints_Convert(cc.definition), 0
											)
										) 
									)
							+ ')' 
							+ IIF(cc_next.B_Exists IS NULL AND @kc_exists_B_Exists IS NULL, '', ',')
							+ CHAR(10)
					FROM sys.check_constraints cc
					OUTER APPLY
					( 
						SELECT TOP 1 1 B_Exists
						FROM sys.check_constraints AS cc_next
						WHERE	cc_next.parent_object_id = cc.parent_object_id
							AND cc_next.object_id > cc.object_id
							-- ограничения на таблицу
							AND cc_next.parent_column_id = 0
						ORDER BY cc_next.object_id ASC
					) cc_next
					WHERE	CC.parent_object_id = @T_object_id 
						-- ограничения на таблицу
						AND CC.parent_column_id = 0
					ORDER BY cc.object_id ASC
					FOR XML path(''), TYPE
				).value('./text()[1]','varchar(max)')
			)
		, '')

END
GO