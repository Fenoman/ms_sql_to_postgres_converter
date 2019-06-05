IF OBJECT_ID('dbo.PG_Add_Brackets') IS NOT NULL
	DROP FUNCTION dbo.PG_Add_Brackets
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Добавляем необходимую ( или ) скобку
-- =============================================
CREATE FUNCTION dbo.PG_Add_Brackets
(
	@string VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN 
	DECLARE @len INT,
			@pos INT = 1,
			@b_found BIT = 0,
			@N_Open INT = 0,
			@N_Close INT = 0
	SET @len = LEN(@string)

	WHILE (@pos <= @len)
	BEGIN 
		IF (SUBSTRING(@string, @pos, 1) = '(')
			SET @N_Open = @N_Open + 1
		IF (SUBSTRING(@string, @pos, 1) = ')')
			SET @N_Close = @N_Close + 1

		SET @pos = @pos + 1
	END

	IF (@N_Open = @N_Close)
		RETURN @string


	SET @pos = 1
	WHILE (@pos <= @len)
	BEGIN 
		IF (SUBSTRING(@string, @pos, 1) = '(')
			SET @b_found = 1

		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 1) = '>')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 1, ')>')
		END
		
		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 1) = '<')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 1, ')<')
		END
		
		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 1) = '=')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 1, ')=')
		END
		
		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 1) = '!')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 1, ')!')
		END

		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 4) = ' AND')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 4, ') AND')
		END

		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 3) = ' OR')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 3, ') OR')
		END

		IF (@b_found = 1 AND SUBSTRING(@string, @pos, 3) = ' IS')
		BEGIN 
			SET @b_found = 0
			SET @string = STUFF(@string, @pos, 3, ') IS')
		END
		
		IF (@b_found = 1 AND @pos = @len)
		BEGIN 
			SET @b_found = 0
			SET @string = @string + ')'
		END

		SET @pos = @pos + 1
	END


	RETURN @string
	
END
GO