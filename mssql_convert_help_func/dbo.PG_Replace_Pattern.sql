IF OBJECT_ID('dbo.PG_Replace_Pattern') IS NOT NULL
	DROP FUNCTION dbo.PG_Replace_Pattern
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 31.05.2018
-- Alter date:	31.05.2018
-- Description:	Замена выражений LIKE на атомы регулярных выражений
-- =============================================
CREATE FUNCTION dbo.PG_Replace_Pattern
(
	@string VARCHAR(500)
)
RETURNS VARCHAR(500)
AS
BEGIN 
	
	SET @string = REPLACE(@string, '[_]', '\_')
	RETURN @string
	
END
GO