IF OBJECT_ID('dbo.PG_SQL_Convert_Indexes') IS NOT NULL
	DROP FUNCTION dbo.PG_SQL_Convert_Indexes
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 26.05.2018
-- Alter date:	26.05.2018
-- Description:	Конвертация индексов
-- =============================================
CREATE FUNCTION dbo.PG_SQL_Convert_Indexes
(
	@T_object_id INT
)
RETURNS VARCHAR(max)
AS
BEGIN 
	
	RETURN
	ISNULL
	(
		CHAR(10) +
		(
			SELECT
				 'CREATE ' 
				+ CASE WHEN INDEXPROPERTY(i.[object_id], i.name, 'IsUnique') = 1 THEN 'UNIQUE ' ELSE '' END 
				+ 'INDEX ' + i.name + ' ON ' + s.name + '.' + o.name 
				+ ' (' + STUFF(
									(
										SELECT ', ' + COL_NAME(o.[object_id], ic.column_id) + ' ' + CASE WHEN ic.is_descending_key = 0 THEN 'ASC' ELSE 'DESC' END
										FROM sys.index_columns ic
										WHERE	ic.object_id = o.[object_id]
											AND ic.index_id  = i.index_id
											------------------------------------
											AND ic.is_included_column = 0
											AND (ic.partition_ordinal = 0 OR ic.key_ordinal <> 0)
											------------------------------------
										ORDER BY ic.key_ordinal
										FOR XML path('')
									)
									, 1, 2, ''
								) 
					+ ')' 
				+ ISNULL(' INCLUDE (' + 
							NULLIF(
									STUFF(
											(
												SELECT ', ' + COL_NAME(o.[object_id], ic.column_id)
												FROM sys.index_columns ic
												WHERE	ic.object_id = o.[object_id]
													AND ic.index_id  = i.index_id
													------------------------------------
													AND ic.is_included_column = 1
													AND ic.partition_ordinal = 0
													------------------------------------
												ORDER BY ic.key_ordinal
												FOR XML path('')
											)
											, 1, 2, ''
										)
								, '')
						+ ')', '')
									-- !!! Attention
				+ ' TABLESPACE ' + 'ts_indexes'
									-- !!! Attention
				+   CASE WHEN i.has_filter = 1 THEN ' WHERE (' + dbo.PG_Remove_Brackets(dbo.PG_FilteredIndexMapping(i.filter_definition), 0) + ')' ELSE '' END 
				+ ';' + CHAR(10)
			FROM sys.indexes AS i
			INNER JOIN sys.objects AS o
				ON o.[object_id] = i.[object_id]
			INNER JOIN sys.schemas AS s
				ON s.[schema_id] = o.[schema_id]
			WHERE	i.type_desc		<> 'CLUSTERED COLUMNSTORE' 
				AND i.type_desc		<> 'HEAP'
				AND i.is_primary_key = 0
				AND i.is_unique_constraint = 0
				AND i.object_id = @T_object_id
				-- Индекс по XML колонкам создавать надо вручную
				AND NOT EXISTS
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
						AND IC.object_id	= i.object_id
						AND IC.index_id		= i.index_id
				)
			ORDER BY i.name
			FOR XML path('')
		)
	, ''
	)

END
GO