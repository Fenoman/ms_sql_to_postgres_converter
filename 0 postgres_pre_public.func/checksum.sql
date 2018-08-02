CREATE OR REPLACE FUNCTION checksum(string VARCHAR(4000))
  RETURNS int
AS
$$
-- =============================================
-- Author:  e-pavlichenko
-- Create date: 20.05.2018
-- Alter date:  20.05.2018
-- Description: Вычисление контрольной суммы аналолично как мы делали в MS SQL
-- =============================================
BEGIN
RETURN ('x'||substr(md5(string),1,8))::bit(32)::int;
END
$$LANGUAGE plpgsql;
