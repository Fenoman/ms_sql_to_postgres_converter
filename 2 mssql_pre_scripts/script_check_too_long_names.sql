/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
IF OBJECT_ID('dbo.PG_ExcludedTables') IS NOT NULL EXEC dbo.PG_ExcludedTables

-- Ограничение на допустимое количество символов
DECLARE @charsLimit TINYINT = 63

/*******************************************
 * Слишком длинные наименования таблиц
 *******************************************/
SELECT	s.name			AS [Schema],
		t.name			AS [Table],
		LEN(t.name)		AS [Length]
FROM sys.tables AS t
	INNER JOIN sys.schemas AS s
		ON s.[schema_id] = t.[schema_id]
WHERE t.is_ms_shipped = 0
	AND LEN(t.name) > @charsLimit
	AND s.name + '.' + t.name NOT IN (SELECT name FROM #Exclude_Tables)
	
/*******************************************
 * Слишком длинные наименование колонок
 *******************************************/
SELECT	s.name			AS [Schema],
		t.name			AS [Table],
		c.name			AS [Column],
		LEN(c.name)		AS [Length]
FROM sys.tables AS t
	INNER JOIN sys.schemas AS s
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.[columns] AS c
		ON c.[object_id] = t.[object_id]
WHERE t.is_ms_shipped = 0
	AND LEN(c.name) > @charsLimit
	AND s.name + '.' + t.name NOT IN (SELECT name FROM #Exclude_Tables)
	
/*******************************************
 * Слишком длинные наименования индексов
 *******************************************/
SELECT	s.name			AS [Schema],
		t.name			AS [Table],
		i.name			AS [Index],
		LEN(i.name)		AS [Length]
FROM sys.tables AS t
	INNER JOIN sys.schemas AS s
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.indexes AS i
		ON i.[object_id] = t.[object_id]
WHERE t.is_ms_shipped = 0
	AND LEN(i.name) > @charsLimit
	AND s.name + '.' + t.name NOT IN (SELECT name FROM #Exclude_Tables)
	
/*******************************************
 * Слишком длинные наименования констрейнтов
 *******************************************/
SELECT	s.name			AS [Schema],
		t.name			AS [Table],
		o.type_desc		AS [Type],
		o.name			AS [Contraint],
		LEN(o.name)		AS [Length]
FROM sys.tables AS t
	INNER JOIN sys.schemas AS s
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.objects AS o
		ON o.parent_object_id = t.[object_id]
WHERE t.is_ms_shipped = 0
	AND o.type_desc LIKE '%constraint%'
	AND LEN(o.name) > @charsLimit
	AND s.name + '.' + t.name NOT IN (SELECT name FROM #Exclude_Tables)
ORDER BY s.name + '.' + t.name

/*******************************************
 * Слишком длинные наименования триггеров
 *******************************************/
SELECT	s.name			AS [Schema],
		t.name			AS [Table],
		trg.name		AS [Trigger],
		LEN(trg.name)	AS [Length]
FROM sys.tables AS t
	INNER JOIN sys.schemas AS s
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.triggers AS trg
		ON trg.parent_id = t.[object_id]
WHERE t.is_ms_shipped = 0
	AND LEN(trg.name) > @charsLimit
	AND s.name + '.' + t.name NOT IN (SELECT name FROM #Exclude_Tables)