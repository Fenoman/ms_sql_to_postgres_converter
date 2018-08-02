/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
EXEC dbo.PG_ExcludedTables

/*------------------------------------------------------------------------------------
	Значения по умолчанию на колонки
-------------------------------------------------------------------------------------*/
SELECT DISTINCT dc.definition AS Original, dbo.PG_Remove_Brackets(dc.definition, 0) AS target_definition
FROM sys.default_constraints dc
INNER JOIN sys.tables AS T
	ON T.object_id = dc.parent_object_id
INNER JOIN sys.schemas AS S 
	ON S.schema_id = T.schema_id 
WHERE  T.is_ms_shipped = 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'
ORDER BY dc.definition