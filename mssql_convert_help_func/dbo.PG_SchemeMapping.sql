IF OBJECT_ID('dbo.PG_SchemeMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_SchemeMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Мапинг схем на новые схемы
-- =============================================
CREATE FUNCTION dbo.PG_SchemeMapping
(
	@scheme_or_fullname VARCHAR(500)	-- только схема (например dbo) или полное имя (например dbo.SD_Subscr)
)
RETURNS VARCHAR(500) -- Если передана только схема то возвращаем только схему, если передано полное имя то возвращаем полное имя с новой схемой
AS
BEGIN

	RETURN	CASE
			WHEN @scheme_or_fullname = 'dbo' OR @scheme_or_fullname LIKE 'dbo.%'
				THEN IIF(@scheme_or_fullname = 'dbo', 'dbo', REPLACE( @scheme_or_fullname, 'dbo.', 'dbo.'))
			
			/*
			-- SKIP Example
			WHEN @scheme_or_fullname = 'XXX' OR @scheme_or_fullname LIKE 'XXX.%'
				THEN IIF(@scheme_or_fullname = 'XXX', 'SKIP', REPLACE( @scheme_or_fullname, 'XXX.', 'SKIP.'))
			
			-- Rename Example
			WHEN @scheme_or_fullname = 'YYY' OR @scheme_or_fullname LIKE 'YYY.%'
				THEN IIF(@scheme_or_fullname = 'YYY', 'NewName', REPLACE( @scheme_or_fullname, 'YYY.', 'NewName.'))

			*/
			ELSE @scheme_or_fullname
		END
END
GO