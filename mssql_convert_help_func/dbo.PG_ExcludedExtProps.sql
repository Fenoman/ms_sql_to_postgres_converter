IF OBJECT_ID('dbo.PG_ExcludedExtProps') IS NOT NULL
	DROP PROCEDURE dbo.PG_ExcludedExtProps
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================r==
-- Author:		e-pavlichenko
-- Alter date:  05.06.2018
-- Description:	Список исключаемых extp.props
-- =============================================
CREATE PROCEDURE dbo.PG_ExcludedExtProps
AS
BEGIN

	INSERT  #Exclude_ExtProps
	(
		name
	)
	SELECT DISTINCT EP.name FROM sys.extended_properties AS EP
	WHERE  EP.name IN
	(
		'[Example]'
	)

END