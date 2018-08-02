IF NOT EXISTS (SELECT 1 FROM sys.table_types AS TT WHERE TT.name = 'Exclude_ExtProps')
	CREATE TYPE Exclude_ExtProps AS TABLE (name VARCHAR(255))
GO

IF OBJECT_ID('dbo.PG_SQL_Convert_ExtProps_Table') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_ExtProps_Table
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 26.05.2018
-- Alter date:	26.05.2018
-- Description:	Конвертация ext.props на уровне таблицы
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_ExtProps_Table
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
		'COMMENT ON TABLE ' + dbo.PG_SchemeMapping(@s_name) + '.' + @T_name +  ' IS ' + ''''
		+
		(
			SELECT
			'{ ' +
			STUFF
			(
				(
					SELECT ',' + CHAR(10) + '"' + REPLACE(REPLACE(dbo.PG_ExtPropsMapping(CAST(EP.name AS VARCHAR(max))),'''',''''''), char(0x0002), '') + '" : "' 
						+ REPLACE(REPLACE(CAST(EP.value AS VARCHAR(max)),'''',''''''), char(0x0002), '') + '"'
					FROM sys.extended_properties AS EP
					WHERE	EP.major_id = @T_object_id
						-- исключаемые ext.props
						AND EP.name NOT IN (SELECT name FROM @Exclude_ExtProps)
						-- На уровне таблицы
						AND EP.minor_id = 0
					ORDER BY EP.name
					FOR XML path(''), TYPE
				).value('./text()[1]','varchar(max)')
			, 1, 2, '')
			+ '}'
		) + '''' + ';' + CHAR(10)
	, '')

END
GO