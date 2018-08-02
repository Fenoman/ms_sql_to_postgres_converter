IF OBJECT_ID('dbo.PG_CheckConstraints_Convert') IS NOT NULL
	DROP FUNCTION dbo.PG_CheckConstraints_Convert
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Конвертация выражения в ограничениях
-- =============================================
CREATE FUNCTION dbo.PG_CheckConstraints_Convert
(
	@string VARCHAR(5000)
)
RETURNS VARCHAR(5000)
AS
BEGIN 
	
	SET @string = REPLACE(@string, 'isnull(', 'coalesce(')
	SET @string = REPLACE(@string, 'datepart(year,', 'date_part(''year'',')
	SET @string = REPLACE(@string, 'datepart(month,', 'date_part(''month'',')
	SET @string = REPLACE(@string, 'datepart(day,', 'date_part(''day'',')

	RETURN @string
	
END
GO