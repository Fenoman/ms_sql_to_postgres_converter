IF OBJECT_ID('dbo.spWriteStringToFile') IS NOT NULL
	DROP PROCEDURE dbo.spWriteStringToFile

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- ==========================================================================================================
-- Author:	E-Pavlichenko
-- Create date:	1.07.2018
-- Alter date:	1.07.2018
-- Description:	Запись в файл
-- ==========================================================================================================
CREATE PROCEDURE dbo.spWriteStringToFile
(
	@String		VARCHAR(MAX),
	@Path		VARCHAR(8000),
	@Filename	VARCHAR(8000),
	@B_Encoding	BIT = 1
)
AS
DECLARE
	@objFileSystem		INT,
	@objTextStream		INT,
	@objErrorObject		INT,
	@strErrorMessage	VARCHAR(1000),
	@Command			VARCHAR(1000),
	@hr					INT,
	@fileAndPath		VARCHAR(8000)

SET NOCOUNT ON

SELECT @strErrorMessage = 'opening the File System Object'
EXECUTE @hr = sys.sp_OACreate
	'Scripting.FileSystemObject',
	@objFileSystem OUT

SELECT @fileAndPath = @Path + '\' + @Filename
IF @hr = 0
	SELECT
		@objErrorObject = @objFileSystem,
		@strErrorMessage = 'Creating file "' + @fileAndPath + '"'
IF @hr = 0 AND @B_Encoding = 1
	EXECUTE @hr = sys.sp_OAMethod
		@objFileSystem,
		'CreateTextFile',
		@objTextStream OUT,
		@fileAndPath,
		2,
		True
IF @hr = 0 AND @B_Encoding = 0
	EXECUTE @hr = sys.sp_OAMethod
		@objFileSystem,
		'CreateTextFile',
		@objTextStream OUT,
		@fileAndPath,
		2,
		False

IF @hr = 0
	SELECT
		@objErrorObject = @objTextStream,
		@strErrorMessage = 'writing to the file "' + @fileAndPath + '"'
IF @hr = 0
	EXECUTE @hr = sys.sp_OAMethod @objTextStream, 'Write', NULL, @String

IF @hr = 0
	SELECT
		@objErrorObject = @objTextStream,
		@strErrorMessage = 'closing the file "' + @fileAndPath + '"'
IF @hr = 0
	EXECUTE @hr = sys.sp_OAMethod @objTextStream, 'Close'

IF @hr <> 0
BEGIN
	DECLARE
		@Source			VARCHAR(255),
		@Description	VARCHAR(255),
		@Helpfile		VARCHAR(255),
		@HelpID			INT

	EXECUTE sys.sp_OAGetErrorInfo
		@objErrorObject,
		@Source OUTPUT,
		@Description OUTPUT,
		@Helpfile OUTPUT,
		@HelpID OUTPUT
	SELECT	@strErrorMessage = 'Error whilst ' + COALESCE(@strErrorMessage, 'doing something') + ', ' + COALESCE(@Description, '')
	RAISERROR(@strErrorMessage, 16, 1)
END
EXECUTE sys.sp_OADestroy @objTextStream
EXECUTE sys.sp_OADestroy @objFileSystem
GO

