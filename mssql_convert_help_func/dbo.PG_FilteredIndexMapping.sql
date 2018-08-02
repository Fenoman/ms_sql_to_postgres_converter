IF OBJECT_ID('dbo.PG_FilteredIndexMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_FilteredIndexMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 06.06.2018
-- Alter date:	06.06.2018
-- Description:	Мапинг фильтров в фильтрованных индексах
-- =============================================
CREATE FUNCTION dbo.PG_FilteredIndexMapping
(
	@filter_definition VARCHAR(500)	-- name из sys.extended_properties
)
RETURNS VARCHAR(500) 
AS
BEGIN
	RETURN @filter_definition
		/* -- Example
		CASE @filter_definition
			WHEN '([Bit_Col]=(0))' 
				THEN '([Bit_Col]=(false))'
			ELSE @filter_definition
		END
		*/
END
GO