IF OBJECT_ID('dbo.PG_FunctionsMapping') IS NOT NULL
	DROP FUNCTION dbo.PG_FunctionsMapping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 15.05.2018
-- Alter date:	15.05.2018
-- Description:	Мапинг функций на функции PG
-- =============================================
CREATE FUNCTION dbo.PG_FunctionsMapping
(
	@function VARCHAR(500)	-- назваине функции с убранными квадратными скобками, лишними обычными скобками и замапленной схемой
)
RETURNS VARCHAR(500) 
AS
BEGIN
	RETURN
		CASE @function
			WHEN 'newsequentialid()' 
				THEN 'uuid_generate_v1()'
			WHEN 'newid()'
				THEN 'uuid_generate_v4()'
			WHEN 'getdate()'
				THEN 'now()'
			WHEN 'suser_sname()'
				THEN 'user'
			WHEN 'host_name()'
				THEN 'coalesce(gethostbyaddr(inet_client_addr()::inet), inet_client_addr()::VARCHAR(50))'
			ELSE @function
		END
		/*
			-- Examples
			WHEN '''19000101'''
				THEN '''19000101''::TIMESTAMP(0)'
			WHEN '''19010101'''
				THEN '''19010101''::TIMESTAMP(0)'
			WHEN '''20790606'''
				THEN '''20790606''::TIMESTAMP(0)'
			WHEN 'CONVERTsmalldatetime,''19000101'',0'
				THEN '''19000101''::TIMESTAMP(0)'
			WHEN 'CONVERTsmalldatetime,''19450609'',0'
				THEN '''19450609''::TIMESTAMP(0)'
			WHEN 'CONVERTsmalldatetime,''20790606'''
				THEN '''20790606''::TIMESTAMP(0)'
			WHEN 'CONVERTsmalldatetime,''20790606'',0'
				THEN '''20790606''::TIMESTAMP(0)'
			WHEN 'CONVERTvarchar8,getdate(),112'
				THEN 'now()'
			WHEN 'N''Text'''
				THEN '''Text'''
			WHEN 'lefthost_name(),50'
				THEN 'coalesce(gethostbyaddr(inet_client_addr()::inet), inet_client_addr()::VARCHAR(50))'
		*/
END
GO