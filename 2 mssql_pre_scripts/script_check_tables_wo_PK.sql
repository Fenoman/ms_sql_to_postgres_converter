/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
IF OBJECT_ID('dbo.PG_ExcludedTables') IS NOT NULL EXEC dbo.PG_ExcludedTables

/*------------------------------------------------------------------------------------
	Список таблиц без PK
-------------------------------------------------------------------------------------*/
SELECT S.name + '.' + T.name
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
	ON S.schema_id = T.SCHEMA_ID
LEFT JOIN sys.indexes AS I
	ON	I.object_id = T.object_id
	AND I.is_primary_key = 1
WHERE	T.is_ms_shipped = 0 AND I.index_id IS NULL
	-- Исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
ORDER BY 1