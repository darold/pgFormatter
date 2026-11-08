SELECT
    regexp_split_to_table($re$the quick$re$, $re$\s+$re$) AS foo,
    $$a  b$$;

CREATE FUNCTION f ()
    RETURNS int
    AS $body$
    SELECT
        1
$body$
LANGUAGE sql;

DO $x$
BEGIN
    PERFORM
        1;
END
$x$;

