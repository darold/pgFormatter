CREATE FUNCTION fn_opf12 (INT4, INT2)
    RETURNS BIGINT
    AS '
    SELECT
        NULL::BIGINT;
'
LANGUAGE SQL;

SELECT
    1::NUMERIC,
    cast(2 AS VARCHAR(10));

SELECT
    1::NUMERIC,
    '1.2'::FLOAT8,
    (12)::FLOAT4,
    cast(2 AS VARCHAR(10));

INSERT INTO (
    field_one,
    field_two,
    field_three)
VALUES (
    1,
    2,
    3);

INSERT INTO (
    field_one,
    field_two,
    field_3)
VALUES
    (
        1,
        2,
        3),
    (
        4,
        5,
        6),
    (
        7,
        8,
        9);

CREATE CAST (INT8 AS int8alias1) WITHOUT FUNCTION;

CREATE TABLE test11a AS (
    SELECT
        1::PRIV_TESTDOMAIN1 AS a
);

SELECT
    f1,
    f1::INTERVAL DAY TO MINUTE AS "minutes",
    (f1 + INTERVAL '1 month')::INTERVAL MONTH::INTERVAL YEAR AS "years"
FROM
    interval_tbl;

CREATE FUNCTION foo (bar1 IN TEXT, bar2 IN DATE)
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

SELECT
    format($$ A %I B %s C %L %% D $$, 'pg_user', 22, NULL);

CREATE ROLE admin WITH connection LIMIT 3;

