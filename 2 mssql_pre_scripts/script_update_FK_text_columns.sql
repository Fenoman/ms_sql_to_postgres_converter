SELECT 
	'ALTER TABLE [' + s.name + '].[' + Tb.name + '] DISABLE TRIGGER ALL;' + CHAR(10) +
	'UPDATE T SET ' + C.name + ' = rtrim(ltrim(T.' +  c.name + ')) FROM [' + s.name + '].[' + Tb.name + '] AS T' + CHAR(10) + 
	'ALTER TABLE [' + s.name + '].[' + Tb.name + '] ENABLE TRIGGER ALL;' + CHAR(10)
FROM sys.columns AS C
INNER JOIN sys.tables AS Tb
	ON Tb.object_id = c.object_id
INNER JOIN sys.schemas AS S
	ON S.schema_id = Tb.schema_id
INNER JOIN sys.types AS T
	ON t.system_type_id = C.system_type_id
WHERE	T.name IN ('text', 'ntext', 'varchar' , 'char', 'nvarchar', 'nchar')
	AND Tb.is_ms_shipped = 0
	AND 
	(
		EXISTS (SELECT 1 FROM sys.foreign_key_columns AS FKC WHERE FKC.parent_object_id = Tb.object_id AND FKC.parent_column_id = C.column_id)
		OR
		EXISTS (SELECT 1 FROM sys.foreign_key_columns AS FKC WHERE FKC.referenced_object_id = Tb.object_id AND FKC.referenced_column_id = C.column_id)
	)