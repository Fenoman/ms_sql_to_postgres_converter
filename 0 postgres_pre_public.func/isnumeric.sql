CREATE OR REPLACE FUNCTION isnumeric(text) RETURNS BOOLEAN AS
$$
-- =============================================
-- Author:  e-pavlichenko
-- Create date: 13.06.2018
-- Alter date:	13.06.2018
-- Description: Является ли строка числом
-- =============================================
BEGIN
  RETURN $1 ~ '^([-]?[0-9]+[.]?[0-9]*(e[-+]\d+)?|[.][0-9]+(e[-+]\d+)?)$';
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT;