IF OBJECT_ID('dbo.PG_ExcludedTables') IS NOT NULL 
	DROP PROCEDURE dbo.PG_ExcludedTables
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================r==
-- Author:		e-pavlichenko
-- Alter date:  05.06.2018
-- Description:	List of excluded tables
-- =============================================
CREATE PROCEDURE dbo.PG_ExcludedTables
AS
BEGIN

	INSERT  #Exclude_Tables
	(
		name
	)
	SELECT s.name + '.' + t.name 
	FROM sys.tables t 
	INNER JOIN sys.schemas AS s 
		ON s.schema_id = t.schema_id
	WHERE  s.name + '.' + t.name IN
	(
		-- Here you can put the tables into a list separated by a comma
		'dbo.SampeTable',
		'dbo.SampeTable2'	
	)

END