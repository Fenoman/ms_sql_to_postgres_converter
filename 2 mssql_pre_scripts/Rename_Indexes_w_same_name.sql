/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
IF OBJECT_ID('dbo.PG_ExcludedTables') IS NOT NULL EXEC dbo.PG_ExcludedTables


/*------------------------------------------------------------------------------------
	Декларации
-------------------------------------------------------------------------------------*/
DECLARE @i	INT = 1,			-- Счетчик который будет прибавляться в конец имени индекса
		@id INT = 1,			-- Ид-р в таблице #SQL
		@id2 INT = 1,			-- Ид-р в таблице #SQL2
		@C_SQL nvarchar(max)	-- Скрипт для запуска

-- Таблицы сформированных запросов
IF OBJECT_ID('tempdb..#SQL') IS NOT NULL DROP TABLE #SQL
CREATE TABLE #SQL -- для тех где добавляем схемы в конец имени
(
	id INT IDENTITY(1,1),
	C_SQL NVARCHAR(MAX)
)
IF OBJECT_ID('tempdb..#SQL2') IS NOT NULL DROP TABLE #SQL2
CREATE TABLE #SQL2 -- для тех где добавляем номер в конец имени
(
	id INT IDENTITY(1,1),
	C_SQL NVARCHAR(MAX)
)


/*------------------------------------------------------------------------------------
	Сначала пробуем прибавить в конец имени индекса название схемы...
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Idx') IS NOT NULL DROP TABLE #Idx

SELECT I.name, MAX(i.object_id) AS obj, COUNT(*) AS N
INTO #Idx
FROM sys.indexes AS I
INNER JOIN sys.tables AS T
	ON t.object_id = i.object_id
INNER JOIN sys.schemas AS S
	ON s.schema_id = t.schema_id
WHERE	T.is_ms_shipped = 0 
	AND I.index_id <> 0
	-- Исключаемые таблицы
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'
GROUP BY I.name
HAVING COUNT(*) > 1


INSERT #SQL
(
	C_SQL
)
SELECT 
	'EXEC sp_rename N''' + s.name + '.' + t.name+ '.' + i.name + ''', N''' + i.name + '_' + s.name + ''', N''INDEX'';  ' AS C_SQL
FROM #Idx AS I
INNER JOIN sys.tables AS T
	ON t.object_id = i.obj
INNER JOIN sys.schemas AS S
	ON s.schema_id = t.schema_id
-- если на конце индекса уже прибавлена схемы - пропускаем
WHERE SUBSTRING(REVERSE(i.name), 1, LEN('_' + s.name)) <> REVERSE('_' + s.name)

--SELECT * FROM #SQL AS S

WHILE (1=1)
BEGIN
	SELECT @C_SQL = C_SQL FROM #SQL WHERE id = @id
	
	IF @@ROWCOUNT = 0
		BREAK

	EXEC sys.sp_executesql @C_SQL

	SET @id = @id + 1
END


/*------------------------------------------------------------------------------------
	...и если все равно остались индексы с одинаковыми именами прибавляем в конец имени счетчик
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Idx2') IS NOT NULL DROP TABLE #Idx2

CREATE TABLE #Idx2
(
	name NVARCHAR(255),
	obj INT,
	N INT
)

WHILE (1=1)
BEGIN
	INSERT #Idx2
	SELECT I.name, MAX(i.object_id) AS obj, COUNT(*) AS N
	FROM sys.indexes AS I
	INNER JOIN sys.tables AS T
		ON t.object_id = i.object_id
	INNER JOIN sys.schemas AS S
		ON s.schema_id = t.schema_id
	WHERE	T.is_ms_shipped = 0 
		AND I.index_id <> 0
		-- Исключаемые таблицы
		AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
		-- Схемы которые переносить не нужно
		AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'
	GROUP BY I.name
	HAVING COUNT(*) > 1

	IF @@ROWCOUNT = 0
		BREAK

	INSERT #SQL2
	(
		C_SQL
	)
	SELECT 
		'EXEC sp_rename N''' + s.name + '.' + t.name+ '.' + i.name + ''', N''' + i.name + '_' + CAST(@i AS VARCHAR(255)) + ''', N''INDEX'';  ' AS C_SQL
	FROM #Idx2 AS I
	INNER JOIN sys.tables AS T
		ON t.object_id = i.obj
	INNER JOIN sys.schemas AS S
		ON s.schema_id = t.schema_id

	--SELECT * FROM #SQL2 AS S

	WHILE (1=1)
	BEGIN
		SELECT @C_SQL = C_SQL FROM #SQL2 WHERE id = @id2
	
		IF @@ROWCOUNT = 0
			BREAK

		EXEC sys.sp_executesql @C_SQL
		--SELECT @C_SQL

		SET @id2 = @id2 + 1
	END

	-- счетчик индексов
	SET @i = @i + 1
END