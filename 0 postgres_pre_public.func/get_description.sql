CREATE OR REPLACE FUNCTION get_description
(
  schemaname VARCHAR, tablename VARCHAR, columnname VARCHAR DEFAULT NULL
)
RETURNS TEXT AS
$$
DECLARE pos int;
BEGIN
  SELECT      ordinal_position INTO pos
  FROM        information_schema.columns
  WHERE       table_catalog = current_catalog
          AND table_schema  = lower(schemaname)
          AND table_name    = lower(tablename)
          AND column_name   = lower(columnname);

  RETURN col_description((schemaname || '.' || tablename)::REGCLASS, coalesce(pos, 0));
END
$$
LANGUAGE plpgsql STABLE;
-- select get_description('dbo', 'cs_users', 'link')::json->'Description'

