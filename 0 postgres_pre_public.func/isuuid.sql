CREATE OR REPLACE FUNCTION isuuid(text) RETURNS BOOLEAN AS
$$
-- =============================================
-- Author:  e-pavlichenko
-- Create date: 13.06.2018
-- Alter date:	13.06.2018
-- Description: Является ли строка GUID
-- =============================================
BEGIN
  RETURN $1 ~ '^([0-9a-fA-F]{8}-{1}[0-9a-fA-F]{4}-{1}[0-9a-fA-F]{4}-{1}[0-9a-fA-F]{4}-{1}[0-9a-fA-F]{12})$';
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT;