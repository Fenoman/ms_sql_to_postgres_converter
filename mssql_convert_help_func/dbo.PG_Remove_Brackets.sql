IF OBJECT_ID('dbo.PG_Remove_Brackets') IS NOT NULL
	DROP FUNCTION dbo.PG_Remove_Brackets
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Удаляем не нужные скобки и квадратные скобки
-- =============================================
CREATE FUNCTION dbo.PG_Remove_Brackets
(
	@string VARCHAR(500),
	@Only_Square BIT = 0
)
RETURNS VARCHAR(500)
AS
BEGIN 
	-- Сохраняем чтобы вернуть как было
	SET @string = REPLACE(@string, '[_]', '{_}')
	SET @string = REPLACE(@string, '()', '{}')
	SET @string = REPLACE(@string, 'coalesce(', '{coalesce}')
	SET @string = REPLACE(@string, 'date_part(', '{date_part}')

	-- То, что надо убрать
	SET @string = REPLACE(@string, '[', '')
	SET @string = REPLACE(@string, ']', '')
	IF @Only_Square = 0 SET @string = REPLACE(@string, '(', '')
	IF @Only_Square = 0 SET @string = REPLACE(@string, ')', '')

	-- Возвращаем как было
	SET @string = REPLACE(@string, '{}', '()')
	SET @string = REPLACE(@string, '{_}', '[_]')
	SET @string = REPLACE(@string, '{coalesce}', 'coalesce(')
	SET @string = REPLACE(@string, '{date_part}', 'date_part(')

	RETURN @string
	
END
GO