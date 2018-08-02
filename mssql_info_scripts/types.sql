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
	Ts.name--, c.max_length, c.precision, c.scale, ts.max_length, ts.precision, ts.scale, count(*) as Cnt
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
	ON S.schema_id = T.schema_id
INNER JOIN sys.columns AS C
	ON C.object_id = T.object_id
INNER JOIN sys.types AS Ts
	ON  Ts.system_type_id = c.system_type_id
	AND Ts.user_type_id = c.user_type_id
WHERE	T.is_ms_shipped = 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'