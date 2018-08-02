IF NOT EXISTS (SELECT 1 FROM sys.table_types AS TT WHERE TT.name = 'Exclude_ExtProps')
	CREATE TYPE Exclude_ExtProps AS TABLE (name VARCHAR(255))
GO

IF OBJECT_ID('dbo.PG_SQL_Convert_ExtProps_Columns') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_ExtProps_Columns
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 26.05.2018
-- Alter date:	26.05.2018
-- Description:	Конвертация ext.props на уровне колонок
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_ExtProps_Columns
(
	@T_object_id INT,
	@s_name VARCHAR(255),
	@T_name VARCHAR(255),
	@Exclude_ExtProps Exclude_ExtProps READONLY
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
	ISNULL
	(
		CHAR(10) +
		(
			SELECT
			(
				SELECT
					'COMMENT ON COLUMN ' + dbo.PG_SchemeMapping(@s_name) + '.' + @T_name + '.' + c_ext.name + ' IS ' + ''''
					+ '{ ' +
					STUFF
					(
						(
							SELECT ',' + CHAR(10) + '"' + REPLACE(dbo.PG_ExtPropsMapping(CAST(EP.name AS VARCHAR(max))),'''','''''') + '" : "' 
								+ REPLACE(CAST(EP.value AS VARCHAR(max)),'''','''''') + '"'
							FROM sys.extended_properties AS EP
							WHERE	EP.major_id = c_ext.object_id
								-- исключаемые ext.props
								AND EP.name NOT IN (SELECT name FROM @Exclude_ExtProps)
								-- на уровне колонок
								AND EP.minor_id = c_ext.column_id
							ORDER BY EP.name
							FOR XML path(''), TYPE
						).value('./text()[1]','varchar(max)')
					, 1, 2, '')
					+ '}' + '''' + ';' + CHAR(10)
				FROM sys.columns AS c_ext
				WHERE c_ext.object_id = @T_object_id
				ORDER BY c_ext.column_id
				FOR XML path(''), TYPE
			).value('./text()[1]','varchar(max)')
		)
	, '')

END
GO