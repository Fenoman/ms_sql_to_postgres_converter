CREATE OR REPLACE FUNCTION userid()
  RETURNS int
LANGUAGE plpgsql
STABLE
AS $$
-- =============================================
-- Author:  e-pavlichenko
-- Create date: 17.05.2018
-- Alter date:  17.05.2018
-- Description: ID пользователя
-- =============================================
BEGIN
RETURN usesysid::int FROM pg_user WHERE usename = CURRENT_USER;
END
$$;