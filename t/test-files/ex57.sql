CREATE FUNCTION fn_opf12 (int4, int2)
    RETURNS BIGINT
    AS 'SELECT NULL::BIGINT;'
    LANGUAGE SQL;

SELECT
    1::numeriC,
    cast(2 aS vArchar(10));

SELECT
    1::numeric,
    '1.2'::floAt8,
    (12)::floAt4,
    cast(2 as varChar(10));

INSERT INTO ( field_one, field_two, field_three) VALUES ( 1, 2, 3);

INSERT INTO (field_one, field_two, field_3) VALUES (1,2,3), (4,5,6), (7,8,9);

CREATE cast( int8 AS int8alias1) WITHOUT FUNCTION;

CREATE TABLE test11a AS (SELECT 1::PRIV_TESTDOMAIN1 AS a);
SELECT f1, f1::INTERVAL DAY TO MINUTE AS "minutes",
  (f1 + INTERVAL '1 month')::INTERVAL MONTH::INTERVAL YEAR AS "years"
  FROM interval_tbl;

CREATE FUNCTION foo (
    bar1 IN text,
    bar2 IN date
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    foobar1 BIGINT;
    foobar2 DATE;
    foobar3 TEXT;
    foobar4 INT;
BEGIN
    NULL;
END
$procedure$;

SELECT format($$ A %I B %s C %L %% D $$, 'pg_user', 22, NULL);

create role admin with connection limit 3;
