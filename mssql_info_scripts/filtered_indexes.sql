/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
EXEC dbo.PG_ExcludedTables


/*------------------------------------------------------------------------------------
	Filtered indexes
-------------------------------------------------------------------------------------*/
SELECT DISTINCT i.filter_definition
FROM sys.indexes AS i
INNER JOIN sys.tables AS T
	ON T.[object_id] = i.[object_id]
INNER JOIN sys.schemas AS s
	ON s.[schema_id] = T.[schema_id]
WHERE	i.type_desc		<> 'CLUSTERED COLUMNSTORE' 
	AND i.type_desc		<> 'HEAP'
	AND T.is_ms_shipped = 0
	-- исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'