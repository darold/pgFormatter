CREATE FUNCTION fn_opf12 (int4, int2)
    RETURNS bigint
    AS 'SELECT NULL::bigint;'
    LANGUAGE SQL;

SELECT
    1::numeric,
    CAST(2 AS varchar(10));

SELECT
    1::numeric,
    '1.2'::float8,
    (12)::float4,
    CAST(2 AS varchar(10));

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
VALUES (
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

CREATE CAST( int8 AS int8alias1) WITHOUT FUNCTION;

CREATE TABLE test11a AS (
    SELECT
        1::PRIV_TESTDOMAIN1 AS a
);

SELECT
    f1,
    f1::interval DAY TO MINUTE AS "minutes",
    (f1 + interval '1 month')::interval MONTH::interval YEAR AS "years"
FROM
    interval_tbl;

