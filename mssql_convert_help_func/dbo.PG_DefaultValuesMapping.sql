IF OBJECT_ID('dbo.PG_DefaultValuesMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_DefaultValuesMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Мапинг значений
-- =============================================
CREATE FUNCTION dbo.PG_DefaultValuesMapping
(
	@type	  VARCHAR(50),
	@value	  VARCHAR(500)	-- значение
)
RETURNS VARCHAR(500) 
AS
BEGIN
	RETURN	
		CASE @type
			WHEN 'bit' 
				THEN CASE @value WHEN '0' THEN 'false' WHEN '1' THEN 'true' ELSE @value END
			ELSE @value
		END
END
GO