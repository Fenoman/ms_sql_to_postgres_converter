IF OBJECT_ID('dbo.PG_SQL_DataImport_Columns') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_DataImport_Columns
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 02.07.2018
-- Alter date:	02.07.2018
-- Description:	Список колонок для запроса импорта данных
-- =============================================
CREATE FUNCTION dbo.PG_SQL_DataImport_Columns
(
	@T_object_id INT,
	@T_name VARCHAR(255),
	@B_Select BIT		-- 1 - список для INSERT, 0 - список для SELECT
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
				CASE 
					-- для полей типа bit конвертируем 0 и 1 в false и true
					WHEN Ts.name = 'bit' AND @B_Select = 1
						THEN 'CASE WHEN ' +  '"' + C.name + '" = 1 THEN true ELSE false END' + ',' + CHAR(10)
				-- !!! Attention
					-- Исключение, колонку SomeColumn в таблице dbo.SomeTable не переносим!
					WHEN @T_name = 'dbo.SomeTable' AND C.name = 'SomeColumn' AND @B_Select = 1
						THEN '666999' -- Значение зашлушка. Следите за типом!
				-- !!! Attention
					ELSE IIF(ISNUMERIC(C.name) = 1, '"' + C.name + '"', IIF(@B_Select = 1, '"' + C.name + '"', C.name)) + ',' + CHAR(10)
				END 
			FROM sys.columns AS C
			INNER JOIN sys.types AS Ts
				ON  Ts.system_type_id = c.system_type_id
				AND Ts.user_type_id = c.user_type_id
			WHERE C.object_id = @T_object_id
				-- Исключаемые таблицы
				AND dbo.PG_SQL_Excluded_Tables_For_ImpExp(@T_name) = 0
			ORDER BY 
					/*------------------------------------------------------------------------------------
						порядок колонок, на самом деле тут совершенно не критично. Но для красоты нужно.
					-------------------------------------------------------------------------------------*/
					/* -- Example
					IIF(C.name = 'ColOne', 1, 0) DESC,
					IIF(C.name = 'ColTwo', 1, 0) DESC,
					IIF(C.name = 'ColThree', 1, 0) DESC,
					IIF(C.name LIKE 'SomeName[_]%' AND C.name <> 'SomeName_999', 1, 0) DESC,
					IIF(C.name LIKE 'F[_]%', 1, 0) DESC,
					IIF(C.name LIKE 'C[_]%', 1, 0) DESC,
					IIF(C.name LIKE 'N[_]%', 1, 0) DESC,
					IIF(C.name LIKE 'B[_]%', 1, 0) DESC, 
					IIF(C.name LIKE 'D[_]%', 1, 0) DESC, 
					IIF(C.name LIKE 'I[_]%', 1, 0) DESC, 
					IIF(C.name LIKE 'int%', 1, 0) DESC,
						TRY_CAST(REPLACE(c.name, 'int', '') AS INT) ASC,
					IIF(C.name LIKE 'money%', 1, 0) DESC,
						TRY_CAST(REPLACE(c.name, 'money', '') AS INT) ASC,
					IIF(C.name LIKE 'bit%', 1, 0) DESC,
						TRY_CAST(REPLACE(c.name, 'bit', '') AS INT) ASC,
					IIF(C.name LIKE 'datetime%', 1, 0) DESC,
						TRY_CAST(REPLACE(c.name, 'datetime', '') AS INT) ASC,
					IIF(C.name LIKE 'string%', 1, 0) DESC,
						TRY_CAST(REPLACE(c.name, 'string', '') AS INT) ASC,
					IIF(C.name NOT LIKE 'S[_]%', 1, 0) DESC,
					*/
					c.name ASC
			FOR XML path(''), TYPE
		).value('./text()[1]','varchar(max)')
	), 1, 2, '' ))

END