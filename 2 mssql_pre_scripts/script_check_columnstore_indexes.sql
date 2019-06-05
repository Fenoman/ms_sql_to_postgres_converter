/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
IF OBJECT_ID('dbo.PG_ExcludedTables') IS NOT NULL EXEC dbo.PG_ExcludedTables

/*------------------------------------------------------------------------------------
	Список таблиц с колоночными индексами
-------------------------------------------------------------------------------------*/
SELECT S.name + '.' + T.name
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
	ON S.schema_id = T.SCHEMA_ID
INNER JOIN sys.indexes AS I
	ON	I.object_id = T.object_id
	AND I.type_desc LIKE '%COLUMNSTORE%'
WHERE	T.is_ms_shipped = 0
	-- Исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
ORDER BY 1