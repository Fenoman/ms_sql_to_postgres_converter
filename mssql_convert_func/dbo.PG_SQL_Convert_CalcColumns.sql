IF OBJECT_ID('dbo.PG_SQL_Convert_CalcColumns') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_CalcColumns
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 26.05.2018
-- Alter date:	26.05.2018
-- Description:	Конвертация вычисляемых полей
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_CalcColumns
(
	@T_object_id INT,
	@s_name VARCHAR(255),
	@T_name VARCHAR(255)
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
'CREATE OR REPLACE FUNCTION ' + dbo.PG_SchemeMapping(@s_name) + '.Computed_' + @T_name + '()
	RETURNS trigger AS
$$
BEGIN
'
	+
	(
		SELECT 
		(
			SELECT CHAR(9) + 'NEW.' + CC.name + ' = ' + dbo.PG_ComputedColumns_Convert(CC.definition, 0) + ';' + CHAR(10) 
			FROM sys.computed_columns AS CC
			WHERE CC.object_id = @T_object_id
			ORDER BY CC.column_id ASC
			FOR XML path(''), TYPE
		).value('./text()[1]','varchar(max)')
	)
	+
	'
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TU_0_Computed_' + @T_name + '
BEFORE UPDATE
ON ' + dbo.PG_SchemeMapping(@s_name) + '.' + @T_name + '
FOR EACH ROW
WHEN (' 
+
STUFF
(
	(
		-- возможны дубли полей (когда оно используются разными вычисляемыми полями), но это не страшно.
		SELECT DISTINCT ' OR ' + dbo.PG_ComputedColumns_Convert(CC.definition, 1)
		FROM sys.computed_columns AS CC
		WHERE CC.object_id = @T_object_id
		FOR XML path('')
	)
, 1, 4, ''
) 
+
(
	-- сами вычисляемые поля, если они будут обновляться сами по себе - то принудительно их пересчитываем
	SELECT DISTINCT ' OR ' + 'OLD.' + cc.name + ' IS DISTINCT FROM NEW.' + cc.name
	FROM sys.computed_columns AS CC
	WHERE CC.object_id = @T_object_id
	FOR XML path('')
)
+
')
EXECUTE PROCEDURE ' + dbo.PG_SchemeMapping(@s_name) + '.Computed_' + @T_name + '();

CREATE TRIGGER TI_0_Computed_' + @T_name + '
BEFORE INSERT
ON ' + dbo.PG_SchemeMapping(@s_name) + '.' + @T_name + '
FOR EACH ROW
EXECUTE PROCEDURE ' + dbo.PG_SchemeMapping(@s_name) + '.Computed_' + @T_name + '();'
		)
	, '')	

END
GO