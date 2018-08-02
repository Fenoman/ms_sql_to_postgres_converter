IF OBJECT_ID('dbo.PG_ExtPropsMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_ExtPropsMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 06.06.2018
-- Alter date:	06.06.2018
-- Description:	Мапинг ext. props
-- =============================================
CREATE FUNCTION dbo.PG_ExtPropsMapping
(
	@ext_prop VARCHAR(500)	-- name из sys.extended_properties
)
RETURNS VARCHAR(500) 
AS
BEGIN
	RETURN	
		CASE @ext_prop
			WHEN 'MS_Description' 
				THEN 'Description'
			ELSE @ext_prop
		END
END
GO