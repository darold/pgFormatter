--
-- ERRORS
--
-- bad in postquel, but ok in PostgreSQL
SELECT
    1;

--
-- UNSUPPORTED STUFF
-- doesn't work
-- notify pg_class
--
--
-- SELECT
-- this used to be a syntax error, but now we allow an empty target list
SELECT
;

-- no such relation
SELECT
    *
FROM
    nonesuch;

-- bad name in target list
SELECT
    nonesuch
FROM
    pg_database;

-- empty distinct list isn't OK
SELECT DISTINCT
    FROM pg_database;

-- bad attribute name on lhs of operator
SELECT
    *
FROM
    pg_database
WHERE
    nonesuch = pg_database.datname;

-- bad attribute name on rhs of operator
SELECT
    *
FROM
    pg_database
WHERE
    pg_database.datname = nonesuch;

-- bad attribute name in select distinct on
SELECT DISTINCT ON (foobar)
    *
FROM
    pg_database;

--
-- DELETE
-- missing relation name (this had better not wildcard!)
DELETE FROM;

-- no such relation
DELETE FROM nonesuch;

--
-- DROP
-- missing relation name (this had better not wildcard!)
DROP TABLE;

-- no such relation
DROP TABLE nonesuch;

--
-- ALTER TABLE
-- relation renaming
-- missing relation name
ALTER TABLE RENAME;

-- no such relation
ALTER TABLE nonesuch RENAME TO newnonesuch;

-- no such relation
ALTER TABLE nonesuch RENAME TO stud_emp;

-- conflict
ALTER TABLE stud_emp RENAME TO aggtest;

-- self-conflict
ALTER TABLE stud_emp RENAME TO stud_emp;

-- attribute renaming
-- no such relation
ALTER TABLE nonesuchrel RENAME COLUMN nonesuchatt TO newnonesuchatt;

-- no such attribute
ALTER TABLE emp RENAME COLUMN nonesuchatt TO newnonesuchatt;

-- conflict
ALTER TABLE emp RENAME COLUMN salary TO manager;

-- conflict
ALTER TABLE emp RENAME COLUMN salary TO ctid;

--
-- TRANSACTION STUFF
-- not in a xact
abort;

-- not in a xact
END;

--
-- CREATE AGGREGATE
-- sfunc/finalfunc type disagreement
CREATE AGGREGATE newavg2 (
    SFUNC = int4pl,
    BASETYPE = int4,
    STYPE = int4,
    FINALFUNC = int2um,
    INITCOND = '0'
);

-- left out basetype
CREATE AGGREGATE newcnt1 (
    SFUNC = int4inc,
    STYPE = int4,
    INITCOND = '0'
);

--
-- DROP INDEX
-- missing index name
DROP INDEX;

-- bad index name
DROP INDEX 314159;

-- no such index
DROP INDEX nonesuch;

--
-- DROP AGGREGATE
-- missing aggregate name
DROP AGGREGATE;

-- missing aggregate type
DROP AGGREGATE newcnt1;

-- bad aggregate name
DROP AGGREGATE 314159 (int);

-- bad aggregate type
DROP AGGREGATE newcnt (nonesuch);

-- no such aggregate
DROP AGGREGATE nonesuch (int4);

-- no such aggregate for type
DROP AGGREGATE newcnt (float4);

--
-- DROP FUNCTION
-- missing function name
DROP FUNCTION ();

-- bad function name
DROP FUNCTION 314159 ();

-- no such function
DROP FUNCTION nonesuch ();

--
-- DROP TYPE
-- missing type name
DROP TYPE;

-- bad type name
DROP TYPE 314159;

-- no such type
DROP TYPE nonesuch;

--
-- DROP OPERATOR
-- missing everything
DROP OPERATOR;

-- bad operator name
DROP OPERATOR equals;

-- missing type list
DROP OPERATOR ===;

-- missing parentheses
DROP OPERATOR int4, int4;

-- missing operator name
DROP OPERATOR (int4, int4);

-- missing type list contents
DROP OPERATOR === ();

-- no such operator
DROP OPERATOR === (int4);

-- no such operator by that name
DROP OPERATOR === (int4, int4);

-- no such type1
DROP OPERATOR = (
    nonesuch);

-- no such type1
DROP OPERATOR = (
, int4);

-- no such type1
DROP OPERATOR = (
    nonesuch, int4);

-- no such type2
DROP OPERATOR = (int4, nonesuch);

-- no such type2
DROP OPERATOR = (int4,);

--
-- DROP RULE
-- missing rule name
DROP RULE;

-- bad rule name
DROP RULE 314159;

-- no such rule
DROP RULE nonesuch ON noplace;

-- these postquel variants are no longer supported
DROP tuple RULE nonesuch;

DROP instance RULE nonesuch ON noplace;

DROP rewrite RULE nonesuch;

--
-- Check that division-by-zero is properly caught.
--
SELECT
    1 / 0;

SELECT
    1::int8 / 0;

SELECT
    1 / 0::int8;

SELECT
    1::int2 / 0;

SELECT
    1 / 0::int2;

SELECT
    1::numeric / 0;

SELECT
    1 / 0::numeric;

SELECT
    1::float8 / 0;

SELECT
    1 / 0::float8;

SELECT
    1::float4 / 0;

SELECT
    1 / 0::float4;

--
-- Test psql's reporting of syntax error location
--
xxx;

CREATE foo;

CREATE TABLE;

CREATE TABLE \g

INSERT INTO foo
    VALUES (123) foo;

INSERT INTO 123
    VALUES (123);

INSERT INTO foo
    VALUES (123) 123;

-- with a tab
CREATE TABLE foo (
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL
);

-- long line to be truncated on the left
CREATE TABLE foo (
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL
);

-- long line to be truncated on the right
CREATE TABLE foo (
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL,
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY
);

-- long line to be truncated both ways
CREATE TABLE foo (
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL
);

-- long line to be truncated on the left, many lines
CREATE TEMPORARY TABLE foo (
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL
);

-- long line to be truncated on the right, many lines
CREATE TEMPORARY TABLE foo (
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL,
    id int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY
);

-- long line to be truncated both ways, many lines
CREATE TEMPORARY TABLE foo (
    id int4 UNIQUE NOT NULL,
    idx int4 UNIQUE NOT NULL,
    idy int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL,
    idz int4 UNIQUE NOT NULL,
    idv int4 UNIQUE NOT NULL
);

-- more than 10 lines...
CREATE TEMPORARY TABLE foo (
    id int4 UNIQUE NOT NULL,
    idm int4 UNIQUE NOT NULL,
    idx int4 UNIQUE NOT NULL,
    idy int4 UNIQUE NOT NULL,
    id2 text NOT NULL PRIMARY KEY,
    id3 integer NOT NUL,
    id4 int4 UNIQUE NOT NULL,
    id5 text UNIQUE NOT NULL,
    idz int4 UNIQUE NOT NULL,
    idv int4 UNIQUE NOT NULL
);

-- Check that stack depth detection mechanism works and
-- max_stack_depth is not set too high
CREATE FUNCTION infinite_recurse ()
    RETURNS int
    AS '
    SELECT
        infinite_recurse ();
'
LANGUAGE sql;

\set VERBOSITY terse
SELECT
    infinite_recurse ();

