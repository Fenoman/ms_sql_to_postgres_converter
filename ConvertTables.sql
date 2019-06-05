/*------------------------------------------------------------------------------------
	Декларации
-------------------------------------------------------------------------------------*/
-- Путь к папке на сервере Windows где будут формироваться скрипты по конвертации схемы
DECLARE @Path_to_W VARCHAR(255) = 'D:\Tmp\PG_Convert\'
-- Путь к папке на сервере Windows где будут формироваться CSV файлы с экпортируемыми данными
DECLARE @Path_to_W_CSV VARCHAR(255) = 'D:\Tmp\PG_Convert\CSV\'

-- Путь к папке на сервере Windows где лежит установленная утилика gsqlcmd
DECLARE @Path_to_W_gsqlcmd  VARCHAR(255) = 'C:\Program Files (x86)\Gartle\gsqlcmd\'
DECLARE @gsqlcmd_connection VARCHAR(255) = 'ToPG'
-- Кол-во строчек, которое за раз будет выгружаться в CSV. Таким образом избегаем переполнения памяти.
DECLARE @N_Split			INT = 1000000

-- Путь к папке на сервере Linux куда закинем CSV файлы через samba
DECLARE @Path_to_L_CSV VARCHAR(255) = '/home/adm-root/CSV/'

-- Имя подключения к серверу которое мы создадим в postgres через fds_tdw
DECLARE @MS_SQL_Server_Name VARCHAR(255) = '"server\instance\DataBasename"'


-- Таблица куда пишется результат конвертации
DECLARE @Convert_T TABLE
(
	ID						INT IDENTITY(1, 1),
	object_id				INT,
	sch_name				VARCHAR(255),
	t_name					VARCHAR(255),
	C_Table					VARCHAR(1000),
	C_SQL_Convert			VARCHAR(MAX),	-- основной скрипт создания структуры таблиц (Postgres)
	C_SQL_FDW_Schemas		VARCHAR(MAX),	-- создание схем для FDW и мапинг на схемы MS SQL выбранного сервера (MS SQL)
	C_SQL_Import_FDW		VARCHAR(MAX),	-- Скрипты импорта данных через FDW покдлюченный к MS SQL серверу (Postgres)
	C_SQL_Import_CSV		VARCHAR(MAX),	-- Скрипты импорта данных из CSV файлов (Postgres)
	C_cmd_Export_CSV		VARCHAR(MAX),	-- Скрипты экспорта данных в CSV файлы (MS SQL)
	C_PG_SQL_Check_Count	VARCHAR(MAX),	-- Скрипты проверки кол-во строчек в таблицах между серверами (Postgres)
	C_PG_SQL_SerialCorrection VARCHAR(MAX),	-- Скрипты выправления SERIAL значений после импорта в базу Postgres (Postgres)
	B_XML_Indexes			BIT				-- Признак наличия XML индекса на таблице, их надо обрабатывать полностью отдельно вручную
)

-- Таблица куда пишется результат конвертации внешних ключей (FK), отдельно так как должно запускаться после импортаы
DECLARE @Convert_FK_T TABLE
(
	ID				INT IDENTITY(1, 1),
	C_SQL_Convert	VARCHAR(MAX)
)


/*------------------------------------------------------------------------------------
	Исключаемые таблицы
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_Tables') IS NOT NULL DROP TABLE #Exclude_Tables
CREATE TABLE #Exclude_Tables (name VARCHAR(255))

-- Процедура заполнения
EXEC dbo.PG_ExcludedTables


/*------------------------------------------------------------------------------------
	Исключаемые ext. properties
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#Exclude_ExtProps') IS NOT NULL DROP TABLE #Exclude_ExtProps
CREATE TABLE #Exclude_ExtProps (name VARCHAR(255))

-- создаем табличный тип (для передачи в функции)
IF NOT EXISTS (SELECT 1 FROM sys.table_types AS TT WHERE TT.name = 'Exclude_ExtProps')
	CREATE TYPE Exclude_ExtProps AS TABLE (name VARCHAR(255))

DECLARE @Exclude_ExtProps Exclude_ExtProps

-- Процедура заполнения
EXEC dbo.PG_ExcludedExtProps

-- заполняем табличную переменную для передачи в функции
INSERT @Exclude_ExtProps SELECT * FROM #Exclude_ExtProps


/*------------------------------------------------------------------------------------
	Конвертация
-------------------------------------------------------------------------------------*/
-- !!! Comment this insert to see test tables scripts output !!!
INSERT @Convert_T
(
	object_id,
	sch_name,
	t_name,
	C_Table,
	C_SQL_Convert,
	C_SQL_FDW_Schemas,
	C_SQL_Import_FDW,
	C_SQL_Import_CSV,
	C_cmd_Export_CSV,
	C_PG_SQL_Check_Count,
	C_PG_SQL_SerialCorrection,
	B_XML_Indexes
)

-- !!! Comment this insert to see test tables scripts output !!!
SELECT 
	T.object_id,
	S.name,
	T.name,
	'''' + S.name + '.' + t.name + ''',' AS C_Table,

	/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

	------------------------------------
	-- Скрипт на создание схемы
	------------------------------------
	'CREATE SCHEMA IF NOT EXISTS ' + dbo.PG_SchemeMapping(s.name) + ';' + CHAR(10) +

	------------------------------------
	-- Конвертируем имя таблицы и пишем скобку для создания "тела"
	------------------------------------
	'CREATE '
	-- !!! List for UNLOGGED option !!!
	+ IIF(s.name = 'Tmp', 'UNLOGGED', '')
	-- !!! List for UNLOGGED option !!!
	+ ' TABLE ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + CHAR(10) +
	'(' + CHAR(10) +
	
		------------------------------------
		-- Конвертируем колонки
		------------------------------------
		dbo.PG_SQL_Convert_Columns(T.object_id, T.name, PK_exists.index_id, cc_exists.B_Exists, kc_exists.B_Exists) + CHAR(10) +
	
		------------------------------------
		-- Добавляем PK если есть, PG автоматом создает индекс с ASC сортировкой (DESC невозможно, надо делать отдельный индекс), INCLUDE не делаем
		------------------------------------
		dbo.PG_SQL_Convert_PK(PK_exists.object_id, PK_exists.index_id, PK_exists.name, cc_exists.B_Exists, kc_exists.B_Exists) +
	
		------------------------------------
		-- Ограничения на таблицу
		------------------------------------
		dbo.PG_SQL_Convert_TableConstraints(T.object_id, kc_exists.B_Exists) +
	
		------------------------------------
		-- Ограничения уникальности
		------------------------------------
		dbo.PG_SQL_Convert_UniqueConstraints(T.object_id) +

	------------------------------------
	-- Завершаем создание таблицы скобкой
	------------------------------------
	')' + CHAR(10)
	
	-- Генерируем свойство OIDS
	+ 'WITH (OIDS=' + IIF(PK_exists.index_id IS NOT NULL, 'FALSE', 'TRUE') 

	-- Заполняем FillFactor
	+ ', FILLFACTOR=90' + ')'

	-- Табличное пространство
	+ ' TABLESPACE ' + dbo.PG_TableSpacesMapping(fg.name)
	
	-- Завершаем батч создания таблицы
	+ ';' + CHAR(10) +

	------------------------------------
	-- Индексы
	------------------------------------
	dbo.PG_SQL_Convert_Indexes(T.object_id) +

	------------------------------------
	-- ext. properties to JSON
	------------------------------------
	-- на таблицу
	dbo.PG_SQL_Convert_ExtProps_Table(T.object_id, s.name, T.name, @Exclude_ExtProps) +
	
	-- на колонки
	dbo.PG_SQL_Convert_ExtProps_Columns(T.object_id, s.name, T.name, @Exclude_ExtProps) +

	------------------------------------
	-- вычисляемые поля
	------------------------------------
	dbo.PG_SQL_Convert_CalcColumns(T.object_id, s.name, T.name) +

	CHAR(10) + CHAR(10)
	AS C_SQL_Convert,

	/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
	
	/*------------------------------------------------------------------------------------
		Скрипт создания схем в postgres на которые будут отображаться схемы MS SQL подключенного сервера и БД
	-------------------------------------------------------------------------------------*/
	'CREATE SCHEMA IF NOT EXISTS ' + s.name + '_ms;' + CHAR(10) +
	'IMPORT FOREIGN SCHEMA ' + s.name + CHAR(10) +
	'EXCEPT (mssql_table)' + CHAR(10) +
	'FROM SERVER ' + @MS_SQL_Server_Name + CHAR(10) +
	'INTO ' + s.name + '_ms' + CHAR(10) +
	'OPTIONS (import_default ''false'');' + CHAR(10) + CHAR(10)
	AS C_SQL_FDW_Schemas,

	/*------------------------------------------------------------------------------------
		Скрипт для импорта данных через FDW
	-------------------------------------------------------------------------------------*/
	'SET lc_monetary="C";' + CHAR(10) +
	'INSERT INTO ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + CHAR(10) + 
	'(' + CHAR(10) +
		dbo.PG_SQL_DataImport_Columns(T.object_id, S.name + '.' + T.name, 0) + CHAR(10) +
	')' + CHAR(10) + 
	'SELECT' + CHAR(10) + 
	'' +  dbo.PG_SQL_DataImport_Columns(T.object_id, S.name + '.' + T.name, 1) + CHAR(10) +
	'FROM ' + s.name + '_ms' + '."' + T.name + '";' + CHAR(10) + 
	
	'--SELECT * FROM ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ';' + CHAR(10) + 
	'--SELECT count(*) FROM ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ';' + CHAR(10) + 
	'--SELECT * FROM ' + s.name + '_ms."' + T.name + '";' + CHAR(10) + 
	'--SELECT count(*) FROM ' + s.name + '_ms."' + T.name + '";' + CHAR(10) + 
	CHAR(10) + CHAR(10)
	AS C_SQL_Import_FDW,

	/*------------------------------------------------------------------------------------
		Скрипт для импорта данных через CSV файлы полученные утилитой gsqlcmd
	-------------------------------------------------------------------------------------*/
	'SET lc_monetary="C";' + CHAR(10) +
	'SET DATESTYLE = "US";' + CHAR(10) +
	dbo.PG_SQL_ImpCSV(s.name, t.name, @Path_to_L_CSV, T.object_id, @N_Split, T_Count.Row_Cnt) + 
	'--SELECT * FROM ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ';' + CHAR(10) + 
	'--SELECT count(*) FROM ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ';' + CHAR(10) + 
	CHAR(10) + CHAR(10) + IIF(ISNULL(T_Count.Row_Cnt, 0) = 0, NULL, '')
	AS C_SQL_Import_CSV,

	/*------------------------------------------------------------------------------------
		Скрипт для экспорта данных таблиц в CSV (для пейджинга используется OFFSET FETCH MS SQL 2012+)
	-------------------------------------------------------------------------------------*/
	dbo.PG_SQL_ExpCSV_Bat(s.name, t.name, @Path_to_W_gsqlcmd, @gsqlcmd_connection, @Path_to_W_CSV, T.object_id, PK_exists.index_id, @N_Split, T_Count.Row_Cnt) 
	AS C_cmd_Export_CSV,

	/*------------------------------------------------------------------------------------
		Скрипт для сверки кол-ва строчек в таблицах между базами через tds_fdw
	-------------------------------------------------------------------------------------*/
	'DO' + CHAR(10) +
	'$$' + CHAR(10) +
	'DECLARE C_Table VARCHAR(255);' + CHAR(10) +
	'DECLARE PG_Cnt INT;' + CHAR(10) +
	'DECLARE MS_Cnt INT;' + CHAR(10) +
	'BEGIN' + CHAR(10) +
	CHAR(9) + 'SELECT ''' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ''', PG.cnt, MS.cnt' + CHAR(10) +
	CHAR(9) + CHAR(9) + 'INTO C_Table, PG_Cnt, MS_Cnt' + CHAR(10) +
	CHAR(9) + 'FROM (SELECT count(*) as cnt FROM ' + dbo.PG_SchemeMapping(s.name) + '.' + T.name + ') PG' + CHAR(10) + 
	CHAR(9) + 'CROSS JOIN (SELECT count(*) as cnt FROM ' + s.name + '_ms."' + T.name + '") MS;' + CHAR(10) + CHAR(10) +
	CHAR(9) + 'IF PG_Cnt <> MS_Cnt' + CHAR(10) +
	CHAR(9) + CHAR(9) + 'THEN' + CHAR(10) +
	CHAR(9) + CHAR(9) + CHAR(9) + 'RAISE ''%'', C_Table || '' - Count mismatch!!!'' || '' Postgres Count is '' || PG_Cnt::text || '' - '' || ''MS SQL Count is '' || MS_Cnt::text;' + CHAR(10) +
	CHAR(9) + CHAR(9) + 'ELSE' + CHAR(10) + 
	CHAR(9) + CHAR(9) + CHAR(9) + 'RAISE NOTICE ''%'', C_Table || '' - Count match.'';' + CHAR(10) +
	CHAR(9) +'END IF;' + CHAR(10) +
	'END' + CHAR(10) +
	'$$;' + CHAR(10) + CHAR(10) + CHAR(10) + IIF(dbo.PG_SQL_Excluded_Tables_For_ImpExp(s.name + '.' + t.name) = 0, '', NULL)
	AS C_PG_SQL_Check_Count,

	/*------------------------------------------------------------------------------------
		Исправление SERIAL значений после импорта в базу Postgres
	-------------------------------------------------------------------------------------*/
	(
		SELECT 'SELECT setval(pg_get_serial_sequence(''' 
				+ LOWER(dbo.PG_SchemeMapping(s.name)) + '.' + LOWER(T.name)
				+ ''', ''' + LOWER(Ci.name) + '''), COALESCE((SELECT MAX(' + Ci.name + ') + 1 FROM ' 
				+ dbo.PG_SchemeMapping(s.name) + '.' + T.name 
				+ '), 1), false);' + CHAR(10)
		FROM sys.columns AS Ci
		WHERE Ci.object_id = T.object_id AND Ci.is_identity = 1
		FOR XML PATH('')
	)
	AS C_PG_SQL_SerialCorrection,


	/*------------------------------------------------------------------------------------
		Эта колонца нужна только чтобы знать, что нам таблицее есть XML индекс. 
		Если они нужны нужно каждый случай разбирвать вручную
	-------------------------------------------------------------------------------------*/
	ISNULL(
	(
		SELECT TOP 1 1
		FROM sys.index_columns AS IC
		INNER JOIN sys.columns AS Ci
			ON  Ci.object_id = IC.object_id
			AND Ci.column_id = IC.column_id
		INNER JOIN sys.types AS Ts
			ON  Ts.system_type_id	= Ci.system_type_id
			AND Ts.user_type_id		= Ci.user_type_id
		WHERE	Ts.name			= 'xml'
			AND IC.object_id	= T.object_id
	), 0)
	AS B_XML_Indexes
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
	ON S.schema_id = T.schema_id

-- проверяем существование PK
LEFT JOIN sys.indexes AS PK_exists	
	ON PK_exists.object_id = T.object_id AND PK_exists.is_primary_key = 1

-- проверяем существование проверочных ограничений на таблицу
OUTER APPLY 
( 
	SELECT TOP 1 1 AS B_Exists
	FROM sys.check_constraints AS cc_exists
	WHERE cc_exists.parent_object_id = T.OBJECT_ID AND cc_exists.parent_column_id = 0
) cc_exists

-- проверяем существование ограничений уникальности на таблицу
OUTER APPLY 
( 
	SELECT TOP 1 1 AS B_Exists
	FROM sys.key_constraints AS kc_exists
	WHERE kc_exists.parent_object_id = T.OBJECT_ID AND kc_exists.type = 'UQ'
) kc_exists

-- Получаем файловую группу таблицы
CROSS APPLY 
( 
	SELECT TOP 1 ds.name
	FROM sys.indexes AS i
	INNER JOIN sys.data_spaces AS ds 
		ON ds.data_space_id = i.data_space_id
	WHERE	i.object_id = t.object_id 
		-- Кучи и кластерные индексы
		AND i.type IN (0,1)
	ORDER BY i.type
) fg

-- Получаем кол-во строчек в таблице для разбивки скрипта экспорта CSV на части
OUTER APPLY 
(
	SELECT SUM(row_count) AS Row_Cnt
	FROM sys.dm_db_partition_stats 
	WHERE	object_id=T.object_id 
		AND (index_id=0 or index_id=1)
) T_Count

WHERE	T.is_ms_shipped = 0
	AND S.name + '.' + T.name NOT IN (SELECT name FROM #Exclude_Tables)
	-- Схемы которые переносить не нужно
	AND dbo.PG_SchemeMapping(s.name) <> 'SKIP'
	/*
	-- !!! Test Tables !!!
	AND S.name + '.' + T.name IN 
	( 
		'dbo.SomeTable1',
		'dbo.SomeTable2'
	)
	-- !!! Test Tables !!!
	*/
-- некоторые таблицы надо создавать ПЕРВЫМИ, так как они участвуют в функциях, которые применяются при создании других таблиц (например значения по умолчанию)
-- !!! Tables ORDER BY !!!
ORDER BY 
	/*
	-- Example
	IIF(S.name + '.' + T.name = 'dbo.SomeTable1', 0, 1) ASC,
	IIF(S.name + '.' + T.name = 'dbo.SomeTable2', 0, 1) ASC,
	 */
	S.name + '.' + T.name
-- !!! Tables ORDER BY !!!

-- Тестовый вывод:
-- SELECT * FROM @Convert_T AS CT


/*------------------------------------------------------------------------------------
	Формирование файлов	
-------------------------------------------------------------------------------------*/
DECLARE @i INT = 1,
		@FileName				VARCHAR(1000),
		@FileName_Imp_FDW		VARCHAR(1000),
		@FileName_Imp_CSV		VARCHAR(1000),
		@FileName_Exp_CSV		VARCHAR(1000),
		@FileName_Cnt			VARCHAR(1000),
		@FileName_Serial		VARCHAR(1000),
		@FileContent			VARCHAR(max),
		@FileContent_Imp_FDW	VARCHAR(max),
		@FileContent_Imp_CSV	VARCHAR(max),
		@FileContent_Exp_CSV	VARCHAR(max),
		@FileContent_Cnt		VARCHAR(max),
		@FileContent_Serial		VARCHAR(max),
		@MergedContent			VARCHAR(MAX) = '',
		@MergedContent_Imp_FDW	VARCHAR(MAX) = '',
		@MergedContent_Imp_CSV	VARCHAR(MAX) = '',
		@MergedContent_Exp_CSV	VARCHAR(MAX) = '',
		@MergedContent_Cnt		VARCHAR(MAX) = '',
		@MergedContent_Serial	VARCHAR(MAX) = ''

WHILE (1=1)
BEGIN 
	SELECT 
		@FileName				= CAST(@i AS VARCHAR(10)) + ' - 0struct - ' + sch_name + '.' + t_name + '.sql',
		@FileName_Imp_FDW		= CAST(@i AS VARCHAR(10)) + ' - 2fdw - ' + sch_name + '.' + t_name + '_Imp_FDW.sql',
		@FileName_Imp_CSV		= CAST(@i AS VARCHAR(10)) + ' - 2csv - ' + sch_name + '.' + t_name + '_Imp_CSV.sql',
		@FileName_Exp_CSV		= CAST(@i AS VARCHAR(10)) + ' - 1csv - ' + sch_name + '.' + t_name + '_Exp_CSV.bat',
		@FileName_Cnt			= CAST(@i AS VARCHAR(10)) + ' - 3cnt - ' + sch_name + '.' + t_name + '_COUNT_Check.sql',
		@FileName_Serial		= CAST(@i AS VARCHAR(10)) + ' - 4serial - ' + sch_name + '.' + t_name + '_SERIAL_Correction.sql',
		@FileContent			= C_SQL_Convert,
		@FileContent_Imp_FDW	= C_SQL_Import_FDW,
		@FileContent_Imp_CSV	= C_SQL_Import_CSV,
		@FileContent_Exp_CSV	= C_cmd_Export_CSV,
		@FileContent_Cnt		= C_PG_SQL_Check_Count,
		@FileContent_Serial		= C_PG_SQL_SerialCorrection,
		@MergedContent			= @MergedContent + ISNULL(C_SQL_Convert, ''),
		@MergedContent_Imp_FDW	= @MergedContent_Imp_FDW + ISNULL(C_SQL_Import_FDW, ''),
		@MergedContent_Imp_CSV	= @MergedContent_Imp_CSV + ISNULL(C_SQL_Import_CSV, ''),
		@MergedContent_Exp_CSV	= @MergedContent_Exp_CSV + ISNULL(C_cmd_Export_CSV, ''),
		@MergedContent_Cnt		= @MergedContent_Cnt + ISNULL(C_PG_SQL_Check_Count, ''),
		@MergedContent_Serial	= @MergedContent_Serial + ISNULL(C_PG_SQL_SerialCorrection, '')
	FROM @Convert_T WHERE ID = @i 

	IF @@ROWCOUNT = 0
	BEGIN 
		-- Пишем все скрипты в один файл
		IF NULLIF(@MergedContent, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent,		 @Path_to_W, 'Merged_0_Scheme.sql', 1
		IF NULLIF(@MergedContent_Imp_FDW, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_Imp_FDW, @Path_to_W, 'Merged_2_1_Import_fromFDW.sql', 1
		IF NULLIF(@MergedContent_Imp_CSV, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_Imp_CSV, @Path_to_W, 'Merged_2_Import_fromCSV.sql', 1
		IF NULLIF(@MergedContent_Exp_CSV, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_Exp_CSV, @Path_to_W, 'Merged_1_Export_toCSV.bat', 0
		IF NULLIF(@MergedContent_Cnt, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_Cnt,	 @Path_to_W, 'Merged_3_CheckCount.sql', 1
		IF NULLIF(@MergedContent_Serial, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_Serial,	 @Path_to_W, 'Merged_4_SERIAL_Correction.sql', 1

		DECLARE @Content_FDW_Schemas VARCHAR(max)
		SET @Content_FDW_Schemas = REPLACE(REPLACE((SELECT DISTINCT C_SQL_FDW_Schemas FROM @Convert_T FOR XML PATH('')), '<C_SQL_FDW_Schemas>', ''), '</C_SQL_FDW_Schemas>', '')
		EXEC dbo.spWriteStringToFile @Content_FDW_Schemas,	 @Path_to_W, 'Merged_2_0_Create_FDW_Schemas.sql', 1

		BREAK
	END

	-- записываем в файл
	EXEC dbo.spWriteStringToFile @FileContent,			@Path_to_W, @FileName,			1
	EXEC dbo.spWriteStringToFile @FileContent_Imp_FDW,	@Path_to_W, @FileName_Imp_FDW,	1
	EXEC dbo.spWriteStringToFile @FileContent_Imp_CSV,	@Path_to_W, @FileName_Imp_CSV,	1
	EXEC dbo.spWriteStringToFile @FileContent_Exp_CSV,	@Path_to_W, @FileName_Exp_CSV,	0
	EXEC dbo.spWriteStringToFile @FileContent_Cnt,		@Path_to_W, @FileName_Cnt,		1
	EXEC dbo.spWriteStringToFile @FileContent_Serial,	@Path_to_W, @FileName_Serial,	1

	SET @i = @i + 1
END


/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	На этом шаге необходимо произвести импорт данных (если стоит такая задача)
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


/*------------------------------------------------------------------------------------
	Внешние ключи
-------------------------------------------------------------------------------------*/

-- !!! Comment for test SELECT script !!!
INSERT @Convert_FK_T
(
	C_SQL_Convert
)
SELECT
	'ALTER TABLE '	+ const.parent_obj + ' ADD CONSTRAINT ' + const.const_name + ' FOREIGN KEY (' + const.parent_col_csv + ') REFERENCES ' + const.ref_obj + '('
	+ const.ref_col_csv + ')' + ISNULL(const.delete_action COLLATE Cyrillic_General_CI_AS, '')
	+ ISNULL(' ' + const.update_action COLLATE Cyrillic_General_CI_AS, '') + ';' + CHAR(10)
FROM
	(
		SELECT
			dbo.PG_Remove_Brackets(fk.name, 1) AS const_name,
			fk.is_disabled,
			dbo.PG_SchemeMapping(schParent.name) + '.' + OBJECT_NAME(fkc.parent_object_id) AS parent_obj,
			STUFF
			(
				(
					SELECT	',' + COL_NAME(fcP.parent_object_id, fcP.parent_column_id)
					FROM	sys.foreign_key_columns AS fcP
					WHERE	fcP.constraint_object_id = fk.object_id
					FOR XML PATH('')
				), 1, 1, ''
			) AS parent_col_csv,
			dbo.PG_SchemeMapping(schRef.name) + '.' + OBJECT_NAME(fkc.referenced_object_id) AS ref_obj,
			STUFF
			(
				(
					SELECT	',' + COL_NAME(fcR.referenced_object_id, fcR.referenced_column_id)
					FROM	sys.foreign_key_columns AS fcR
					WHERE	fcR.constraint_object_id = fk.object_id
					FOR XML PATH('')
				), 1, 1, ''
			) AS ref_col_csv,
			CASE
				WHEN fk.delete_referential_action_desc <> 'NO_ACTION'
					THEN ' ON DELETE ' + REPLACE(fk.delete_referential_action_desc, '_', ' ')
				ELSE NULL
			END AS delete_action,
			CASE
				WHEN fk.update_referential_action_desc <> 'NO_ACTION'
					THEN ' ON UPDATE ' + REPLACE(fk.update_referential_action_desc, '_', ' ')
				ELSE NULL
			END AS update_action
		FROM	sys.foreign_key_columns AS fkc
			INNER JOIN sys.foreign_keys AS fk
				ON fk.object_id			= fkc.constraint_object_id
			INNER JOIN sys.objects AS oParent
				ON oParent.object_id	= fkc.parent_object_id
			INNER JOIN sys.schemas AS schParent
				ON schParent.schema_id = oParent.schema_id
			INNER JOIN sys.objects AS oRef
				ON oRef.object_id		= fkc.referenced_object_id
			INNER JOIN sys.schemas AS schRef
				ON schRef.schema_id		= oRef.schema_id
			-- Исключаемые таблицы
		WHERE	schParent.name + '.' + OBJECT_NAME(fkc.parent_object_id) NOT IN (SELECT name FROM #Exclude_Tables)
			AND schRef.name + '.' + OBJECT_NAME(fkc.referenced_object_id) NOT IN (SELECT name FROM #Exclude_Tables)
			-- Схемы которые переносить не нужно
			AND dbo.PG_SchemeMapping(schParent.name) <> 'SKIP'
			AND dbo.PG_SchemeMapping(schRef.name)	 <> 'SKIP'
		GROUP BY
			fkc.parent_object_id,
			fkc.referenced_object_id,
			fk.is_disabled,
			fk.name,
			fk.object_id,
			schParent.name,
			schRef.name,
			fk.delete_referential_action_desc,
			fk.update_referential_action_desc,
			fk.is_not_for_replication
	) AS const
ORDER BY const.const_name


/*------------------------------------------------------------------------------------
	Формирование файлов	
-------------------------------------------------------------------------------------*/
DECLARE @i_FK INT = 1,
		@MergedContent_FK VARCHAR(MAX) = ''

WHILE (1=1)
BEGIN 
	SELECT 
		@MergedContent_FK	= @MergedContent_FK + C_SQL_Convert
	FROM @Convert_FK_T WHERE ID = @i_FK 

	IF @@ROWCOUNT = 0
	BEGIN 
		-- Пишем все скрипты в один файл
		IF NULLIF(@MergedContent, '') IS NOT NULL
			EXEC dbo.spWriteStringToFile @MergedContent_FK, @Path_to_W, 'Merged_5_FK.sql', 1

		BREAK
	END

	SET @i_FK = @i_FK + 1
END
-- !!! Comment for test SELECT script !!!
