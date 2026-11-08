--
-- expression evaluation tests that don't fit into a more specific file
--
--
-- Tests for SQLValueFunction
--
-- current_date  (always matches because of transactional behaviour)
SELECT
    date(now())::text = CURRENT_DATE::text;

-- current_time / localtime
SELECT
    now()::timetz::text = CURRENT_TIME::text;

SELECT
    now()::timetz(4)::text = current_time(4)::text;

SELECT
    now()::time::text = LOCALTIME::text;

SELECT
    now()::time(3)::text = localtime(3)::text;

-- current_time[stamp]/ localtime[stamp] (always matches because of transactional behaviour)
SELECT
    CURRENT_TIMESTAMP = NOW();

-- precision
SELECT
    length(CURRENT_TIMESTAMP::text) >= length(current_timestamp(0)::text);

-- localtimestamp
SELECT
    now()::timestamp::text = LOCALTIMESTAMP::text;

-- precision overflow
SELECT
    CURRENT_TIME = current_time(7);

SELECT
    CURRENT_TIMESTAMP = current_timestamp(7);

SELECT
    LOCALTIME = localtime(7);

SELECT
    LOCALTIMESTAMP = localtimestamp(7);

-- current_role/user/user is tested in rolenames.sql
-- current database / catalog
SELECT
    current_catalog = current_database();

-- current_schema
SELECT
    current_schema;

SET search_path = 'notme';

SELECT
    current_schema;

SET search_path = 'pg_catalog';

SELECT
    current_schema;

RESET search_path;

--
-- Test parsing of a no-op cast to a type with unspecified typmod
--
BEGIN;
CREATE TABLE numeric_tbl (
    f1 numeric(18, 3),
    f2 numeric
);
CREATE VIEW numeric_view AS
SELECT
    f1,
    f1::numeric(16, 4) AS f1164,
    f1::numeric AS f1n,
    f2,
    f2::numeric(16, 4) AS f2164,
    f2::numeric AS f2n
FROM
    numeric_tbl;
\d+ numeric_view
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    numeric_view;
-- bpchar, lacking planner support for its length coercion function,
-- could behave differently
CREATE TABLE bpchar_tbl (
    f1 character(16) UNIQUE,
    f2 bpchar
);
CREATE VIEW bpchar_view AS
SELECT
    f1,
    f1::character (14) AS f114,
    f1::bpchar AS f1n,
    f2,
    f2::character (14) AS f214,
    f2::bpchar AS f2n
FROM
    bpchar_tbl;
\d+ bpchar_view
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    bpchar_view
WHERE
    f1::bpchar = 'foo';
ROLLBACK;

--
-- Ordinarily, IN/NOT IN can be converted to a ScalarArrayOpExpr
-- with a suitably-chosen array type.
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    random() IN (1, 4, 8.0);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    random()::int IN (1, 4, 8.0);

-- However, if there's not a common supertype for the IN elements,
-- we should instead try to produce "x = v1 OR x = v2 OR ...".
-- In most cases that'll fail for lack of all the requisite = operators,
-- but it can succeed sometimes.  So this should complain about lack of
-- an = operator, not about cast failure.
SELECT
    '(0,0)'::point IN ('(0,0,0,0)'::box, point(0, 0));

--
-- Tests for ScalarArrayOpExpr with a hashfn
--
-- create a stable function so that the tests below are not
-- evaluated using the planner's constant folding.
BEGIN;
CREATE FUNCTION return_int_input (int)
    RETURNS int
    AS $$
BEGIN
    RETURN $1;
END;
$$
LANGUAGE plpgsql
STABLE;
CREATE FUNCTION return_text_input (text)
    RETURNS text
    AS $$
BEGIN
    RETURN $1;
END;
$$
LANGUAGE plpgsql
STABLE;
SELECT
    return_int_input (1) IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1);
SELECT
    return_int_input (1) IN (10, 9, 2, 8, 3, 7, 4, 6, 5, NULL);
SELECT
    return_int_input (1) IN (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT
    return_int_input (1) IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1, NULL);
SELECT
    return_int_input (NULL::int) IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1);
SELECT
    return_int_input (NULL::int) IN (10, 9, 2, 8, 3, 7, 4, 6, 5, NULL);
SELECT
    return_text_input ('a') IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');
-- NOT IN
SELECT
    return_int_input (1)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1);
SELECT
    return_int_input (1)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 0);
SELECT
    return_int_input (1)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 2, NULL);
SELECT
    return_int_input (1)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1, NULL);
SELECT
    return_int_input (1)
    NOT IN (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT
    return_int_input (NULL::int)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, 1);
SELECT
    return_int_input (NULL::int)
    NOT IN (10, 9, 2, 8, 3, 7, 4, 6, 5, NULL);
SELECT
    return_text_input ('a')
    NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');
ROLLBACK;

-- Test with non-strict equality function.
-- We need to create our own type for this.
BEGIN;
CREATE TYPE myint;
CREATE FUNCTION myintin (cstring)
    RETURNS myint STRICT IMMUTABLE
    LANGUAGE internal
    AS 'int4in';
CREATE FUNCTION myintout (myint)
    RETURNS cstring STRICT IMMUTABLE
    LANGUAGE internal
    AS 'int4out';
CREATE FUNCTION myinthash (myint)
    RETURNS integer STRICT IMMUTABLE
    LANGUAGE internal
    AS 'hashint4';
CREATE TYPE myint (
    input = myintin,
    output = myintout,
    LIKE = int4
);
CREATE CAST (int4 AS myint) WITHOUT FUNCTION;
CREATE CAST (myint AS int4) WITHOUT FUNCTION;
CREATE FUNCTION myinteq (myint, myint)
    RETURNS bool
    AS $$
BEGIN
    IF $1 IS NULL AND $2 IS NULL THEN
        RETURN TRUE;
    ELSE
        RETURN $1::int = $2::int;
    END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;
CREATE FUNCTION myintne (myint, myint)
    RETURNS bool
    AS $$
BEGIN
    RETURN NOT myinteq ($1, $2);
END;
$$
LANGUAGE plpgsql
IMMUTABLE;
CREATE OPERATOR = (
    LEFTARG = myint,
    RIGHTARG = myint,
    commutator = =,
    negator = <>,
    PROCEDURE = myinteq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);
CREATE OPERATOR <> (
    LEFTARG = myint,
    RIGHTARG = myint,
    commutator = <>,
    negator = =,
    PROCEDURE = myintne,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);
CREATE OPERATOR class myint_ops DEFAULT FOR TYPE myint
    USING HASH AS
    OPERATOR 1 = ( myint, myint),
    FUNCTION 1 myinthash ( myint
);
CREATE TABLE inttest (
    a myint
);
INSERT INTO inttest
VALUES
    (NULL),
    (0::myint),
    (1::myint);
-- Test EEOP_HASHED_SCALARARRAYOP against EEOP_SCALARARRAYOP.  Ensure the
-- result of non-hashed vs hashed is the same.
SELECT
    a,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
-- Now make the equal function return false when given two NULLs
CREATE OR REPLACE FUNCTION myinteq (myint, myint)
    RETURNS bool
    AS $$
BEGIN
    IF $1 IS NULL AND $2 IS NULL THEN
        RETURN FALSE;
    ELSE
        RETURN $1::int = $2::int;
    END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;
-- And try the same again to ensure EEOP_HASHED_SCALARARRAYOP does the same
-- thing as EEOP_SCALARARRAYOP.
SELECT
    a,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
-- Try again with an equality function that treats NULLs as equal to 0.
CREATE OR REPLACE FUNCTION myinteq (myint, myint)
    RETURNS bool
    AS $$
BEGIN
    IF $1 IS NULL AND $2 IS NULL THEN
        RETURN FALSE;
    ELSE
        RETURN coalesce($1::int, 0) = coalesce($2::int, 0);
    END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;
SELECT
    a,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed,
    a IN (0::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed_zero,
    a IN (0::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed_zero
FROM
    inttest;
SELECT
    a,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
SELECT
    a,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS not_hashed,
    a NOT IN (1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint, 9::myint) AS hashed,
    a NOT IN (0::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed_zero,
    a NOT IN (0::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed_zero
FROM
    inttest;
SELECT
    a,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint) AS not_hashed,
    a NOT IN (NULL::myint, 1::myint, 2::myint, 3::myint, 4::myint, 5::myint, 6::myint, 7::myint, 8::myint) AS hashed
FROM
    inttest;
ROLLBACK;

