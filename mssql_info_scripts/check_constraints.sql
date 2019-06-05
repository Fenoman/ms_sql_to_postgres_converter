/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
EXEC dbo.PG_ExcludedTables


/*------------------------------------------------------------------------------------
	Проверочные ограничения на таблицу
-------------------------------------------------------------------------------------*/
SELECT DISTINCT cc.definition--, S.name + '.' + T.name
FROM sys.check_constraints cc
INNER JOIN sys.tables AS T
	ON T.object_id = cc.parent_object_id
INNER JOIN sys.schemas AS S 
	ON S.schema_id = T.schema_id
WHERE	T.is_ms_shipped = 0
	-- ограничения на таблицу
	AND CC.parent_column_id = 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'


/*------------------------------------------------------------------------------------
	Проверочные ограничения на колонки
-------------------------------------------------------------------------------------*/
SELECT DISTINCT cc.definition--, S.name + '.' + T.name
FROM sys.check_constraints cc
INNER JOIN sys.tables AS T
	ON T.object_id = cc.parent_object_id
INNER JOIN sys.schemas AS S 
	ON S.schema_id = T.schema_id
WHERE	T.is_ms_shipped = 0
	-- ограничения на таблицу
	AND CC.parent_column_id <> 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'