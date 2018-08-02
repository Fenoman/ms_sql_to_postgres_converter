CREATE OR REPLACE FUNCTION DateDiff(units VARCHAR(30), start_t TIMESTAMP, end_t TIMESTAMP)
  RETURNS INT AS $$
DECLARE
  diff_interval INTERVAL;
  diff          INT = 0;
  years_diff    INT = 0;
  trunc_units   VARCHAR(10);
BEGIN
  trunc_units = CASE units
                WHEN 'sec'
                  THEN 'second'
                WHEN 'mi'
                  THEN 'minute'
                WHEN 'hh'
                  THEN 'hour'
                WHEN 'dd'
                  THEN 'day'
                WHEN 'wk'
                  THEN 'week'
                WHEN 'mm'
                  THEN 'month'
                WHEN 'yy'
                  THEN 'year'
                ELSE units
                END;

  start_t = date_trunc(trunc_units, start_t);
  end_t = date_trunc(trunc_units, end_t);

  IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month')
  THEN
    years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);

    IF units IN ('yy', 'yyyy', 'year')
    THEN
      -- SQL Server does not count full years passed (only difference between year parts)
      RETURN years_diff;
    ELSE
      -- If end month is less than start month it will subtracted
      RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t));
    END IF;
  END IF;

  -- Minus operator returns interval 'DDD days HH:MI:SS'
  diff_interval = end_t - start_t;

  diff = diff + DATE_PART('day', diff_interval);

  IF units IN ('wk', 'ww', 'week')
  THEN
    diff = diff / 7;
    RETURN diff;
  END IF;

  IF units IN ('dd', 'd', 'day')
  THEN
    RETURN diff;
  END IF;

  diff = diff * 24 + DATE_PART('hour', diff_interval);

  IF units IN ('hh', 'hour')
  THEN
    RETURN diff;
  END IF;

  diff = diff * 60 + DATE_PART('minute', diff_interval);

  IF units IN ('mi', 'n', 'minute')
  THEN
    RETURN diff;
  END IF;

  diff = diff * 60 + DATE_PART('second', diff_interval);

  RETURN diff;
END;
$$
LANGUAGE plpgsql;