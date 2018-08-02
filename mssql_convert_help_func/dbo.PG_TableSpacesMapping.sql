IF OBJECT_ID('dbo.PG_TableSpacesMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_TableSpacesMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 02.06.2018
-- Alter date:	02.06.2018
-- Description:	Мапинг схем MS SQL на табличные пространства созданной базы в Postgres
-- =============================================
CREATE FUNCTION dbo.PG_TableSpacesMapping
(
	@ts VARCHAR(500)	-- MS SQL dataspace
)
RETURNS VARCHAR(500)
AS
BEGIN

	RETURN	
		CASE
			WHEN @ts = 'PRIMARY'
				THEN 'ts_data'
			/*
			-- Examples
			WHEN @ts = 'Attachments'
				THEN 'ts_attachments'
			WHEN @ts = 'Data'
				THEN 'ts_data'
			WHEN @ts = 'Indexes'
				THEN 'ts_indexes'
			WHEN @ts = 'PARTITION_SCHEME'
				THEN 'ts_data'
			*/
			ELSE 'ts_data'
		END
END
GO