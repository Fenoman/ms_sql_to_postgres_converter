/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
EXEC dbo.PG_ExcludedTables

/*------------------------------------------------------------------------------------
	Все используемые типы
-------------------------------------------------------------------------------------*/
SELECT DISTINCT
	cc.definition
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
	ON S.schema_id = T.schema_id
INNER JOIN sys.computed_columns cc
	ON CC.object_id = T.object_id
WHERE	T.is_ms_shipped = 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'