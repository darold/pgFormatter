--
-- Test domains.
--
-- Test Comment / Drop
CREATE DOMAIN domaindroptest int4;

COMMENT ON DOMAIN domaindroptest IS 'About to drop this..';

CREATE DOMAIN dependenttypetest domaindroptest;

-- fail because of dependent type
DROP DOMAIN domaindroptest;

DROP DOMAIN domaindroptest CASCADE;

-- this should fail because already gone
DROP DOMAIN domaindroptest CASCADE;

-- Test domain input.
-- Note: the point of checking both INSERT and COPY FROM is that INSERT
-- exercises CoerceToDomain while COPY exercises domain_in.
CREATE DOMAIN domainvarchar varchar(5);

CREATE DOMAIN domainnumeric numeric(8, 2);

CREATE DOMAIN domainint4 int4;

CREATE DOMAIN domaintext text;

-- Test explicit coercions --- these should succeed (and truncate)
SELECT
    cast('123456' AS domainvarchar);

SELECT
    cast('12345' AS domainvarchar);

-- Test tables using domains
CREATE TABLE basictest (
    testint4 domainint4,
    testtext domaintext,
    testvarchar domainvarchar,
    testnumeric domainnumeric
);

INSERT INTO basictest
    VALUES ('88', 'haha', 'short', '123.12');

-- Good
INSERT INTO basictest
    VALUES ('88', 'haha', 'short text', '123.12');

-- Bad varchar
INSERT INTO basictest
    VALUES ('88', 'haha', 'short', '123.1212');

-- Truncate numeric
SELECT
    *
FROM
    basictest;

-- check that domains inherit operations from base types
SELECT
    testtext || testvarchar AS ||,
    testnumeric + 42 AS sum
FROM
    basictest;

-- check that union/case/coalesce type resolution handles domains properly
SELECT
    coalesce(4::domainint4, 7) IS OF (int4) AS t;

SELECT
    coalesce(4::domainint4, 7) IS OF (domainint4) AS f;

SELECT
    coalesce(4::domainint4, 7::domainint4) IS OF (domainint4) AS t;

DROP TABLE basictest;

DROP DOMAIN domainvarchar RESTRICT;

DROP DOMAIN domainnumeric RESTRICT;

DROP DOMAIN domainint4 RESTRICT;

DROP DOMAIN domaintext;

-- Test domains over array types
CREATE DOMAIN domainint4arr int4[1];

CREATE DOMAIN domainchar4arr varchar(4)[2][3];

CREATE TABLE domarrtest (
    testint4arr domainint4arr,
    testchar4arr domainchar4arr
);

INSERT INTO domarrtest
    VALUES ('{2,2}', '{{"a","b"},{"c","d"}}');

INSERT INTO domarrtest
    VALUES ('{{2,2},{2,2}}', '{{"a","b"}}');

INSERT INTO domarrtest
    VALUES ('{2,2}', '{{"a","b"},{"c","d"},{"e","f"}}');

INSERT INTO domarrtest
    VALUES ('{2,2}', '{{"a"},{"c"}}');

INSERT INTO domarrtest
    VALUES (NULL, '{{"a","b","c"},{"d","e","f"}}');

INSERT INTO domarrtest
    VALUES (NULL, '{{"toolong","b","c"},{"d","e","f"}}');

INSERT INTO domarrtest (testint4arr[1], testint4arr[3])
    VALUES (11, 22);

SELECT
    *
FROM
    domarrtest;

SELECT
    testint4arr[1],
    testchar4arr[2:2]
FROM
    domarrtest;

SELECT
    array_dims(testint4arr),
    array_dims(testchar4arr)
FROM
    domarrtest;

SELECT
    *
FROM
    domarrtest;

UPDATE
    domarrtest
SET
    testint4arr[1] = testint4arr[1] + 1,
    testint4arr[3] = testint4arr[3] - 1
WHERE
    testchar4arr IS NULL;

SELECT
    *
FROM
    domarrtest
WHERE
    testchar4arr IS NULL;

DROP TABLE domarrtest;

DROP DOMAIN domainint4arr RESTRICT;

DROP DOMAIN domainchar4arr RESTRICT;

CREATE DOMAIN dia AS int[];

SELECT
    '{1,2,3}'::dia;

SELECT
    array_dims('{1,2,3}'::dia);

SELECT
    pg_typeof('{1,2,3}'::dia);

SELECT
    pg_typeof('{1,2,3}'::dia || 42);

-- should be int[] not dia
DROP DOMAIN dia;

-- Test domains over composites
CREATE TYPE comptype AS (
    r float8,
    i float8
);

CREATE DOMAIN dcomptype AS comptype;

CREATE TABLE dcomptable (
    d1 dcomptype UNIQUE
);

INSERT INTO dcomptable
    VALUES (ROW (1, 2)::dcomptype);

INSERT INTO dcomptable
    VALUES (ROW (3, 4)::comptype);

INSERT INTO dcomptable
    VALUES (ROW (1, 2)::dcomptype);

-- fail on uniqueness
INSERT INTO dcomptable (d1.r)
    VALUES (11);

SELECT
    *
FROM
    dcomptable;

SELECT
    (d1).r,
    (d1).i,
    (d1).*
FROM
    dcomptable;

UPDATE
    dcomptable
SET
    d1.r = (d1).r + 1
WHERE (d1).i > 0;

SELECT
    *
FROM
    dcomptable;

ALTER DOMAIN dcomptype
    ADD CONSTRAINT c1 CHECK ((value).r <= (value).i);

ALTER DOMAIN dcomptype
    ADD CONSTRAINT c2 CHECK ((value).r > (value).i);

-- fail
SELECT
    ROW (2,
        1)::dcomptype;

-- fail
INSERT INTO dcomptable
    VALUES (ROW (1, 2)::comptype);

INSERT INTO dcomptable
    VALUES (ROW (2, 1)::comptype);

-- fail
INSERT INTO dcomptable (d1.r)
    VALUES (99);

INSERT INTO dcomptable (d1.r, d1.i)
    VALUES (99, 100);

INSERT INTO dcomptable (d1.r, d1.i)
    VALUES (100, 99);

-- fail
UPDATE
    dcomptable
SET
    d1.r = (d1).r + 1
WHERE (d1).i > 0;

-- fail
UPDATE
    dcomptable
SET
    d1.r = (d1).r - 1,
    d1.i = (d1).i + 1
WHERE (d1).i > 0;

SELECT
    *
FROM
    dcomptable;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) UPDATE
    dcomptable
SET
    d1.r = (d1).r - 1,
    d1.i = (d1).i + 1
WHERE (d1).i > 0;

CREATE RULE silly AS ON DELETE TO dcomptable
    DO INSTEAD
    UPDATE
        dcomptable SET
        d1.r = (d1).r - 1,
        d1.i = (d1).i + 1 WHERE (d1).i > 0;

\d+ dcomptable
DROP TABLE dcomptable;

DROP TYPE comptype CASCADE;

-- check altering and dropping columns used by domain constraints
CREATE TYPE comptype AS (
    r float8,
    i float8
);

CREATE DOMAIN dcomptype AS comptype;

ALTER DOMAIN dcomptype
    ADD CONSTRAINT c1 CHECK ((value).r > 0);

COMMENT ON CONSTRAINT c1 ON DOMAIN dcomptype IS 'random commentary';

SELECT
    ROW (0,
        1)::dcomptype;

-- fail
ALTER TYPE comptype
    ALTER attribute r TYPE varchar;

-- fail
ALTER TYPE comptype
    ALTER attribute r TYPE bigint;

ALTER TYPE comptype
    DROP attribute r;

-- fail
ALTER TYPE comptype
    DROP attribute i;

SELECT
    conname,
    obj_description(oid, 'pg_constraint')
FROM
    pg_constraint
WHERE
    contypid = 'dcomptype'::regtype;

-- check comment is still there
DROP TYPE comptype CASCADE;

-- Test domains over arrays of composite
CREATE TYPE comptype AS (
    r float8,
    i float8
);

CREATE DOMAIN dcomptypea AS comptype[];

CREATE TABLE dcomptable (
    d1 dcomptypea UNIQUE
);

INSERT INTO dcomptable
    VALUES (ARRAY[ROW (1, 2)]::dcomptypea);

INSERT INTO dcomptable
    VALUES (ARRAY[ROW (3, 4), ROW (5, 6)]::comptype[]);

INSERT INTO dcomptable
    VALUES (ARRAY[ROW (7, 8)::comptype, ROW (9, 10)::comptype]);

INSERT INTO dcomptable
    VALUES (ARRAY[ROW (1, 2)]::dcomptypea);

-- fail on uniqueness
INSERT INTO dcomptable (d1[1])
    VALUES (ROW (9, 10));

INSERT INTO dcomptable (d1[1].r)
    VALUES (11);

SELECT
    *
FROM
    dcomptable;

SELECT
    d1[2],
    d1[1].r,
    d1[1].i
FROM
    dcomptable;

UPDATE
    dcomptable
SET
    d1[2] = ROW (d1[2].i,
        d1[2].r);

SELECT
    *
FROM
    dcomptable;

UPDATE
    dcomptable
SET
    d1[1].r = d1[1].r + 1
WHERE
    d1[1].i > 0;

SELECT
    *
FROM
    dcomptable;

ALTER DOMAIN dcomptypea
    ADD CONSTRAINT c1 CHECK (value[1].r <= value[1].i);

ALTER DOMAIN dcomptypea
    ADD CONSTRAINT c2 CHECK (value[1].r > value[1].i);

-- fail
SELECT
    ARRAY[ROW (2, 1)]::dcomptypea;

-- fail
INSERT INTO dcomptable
    VALUES (ARRAY[ROW (1, 2)]::comptype[]);

INSERT INTO dcomptable
    VALUES (ARRAY[ROW (2, 1)]::comptype[]);

-- fail
INSERT INTO dcomptable (d1[1].r)
    VALUES (99);

INSERT INTO dcomptable (d1[1].r, d1[1].i)
    VALUES (99, 100);

INSERT INTO dcomptable (d1[1].r, d1[1].i)
    VALUES (100, 99);

-- fail
UPDATE
    dcomptable
SET
    d1[1].r = d1[1].r + 1
WHERE
    d1[1].i > 0;

-- fail
UPDATE
    dcomptable
SET
    d1[1].r = d1[1].r - 1,
    d1[1].i = d1[1].i + 1
WHERE
    d1[1].i > 0;

SELECT
    *
FROM
    dcomptable;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) UPDATE
    dcomptable
SET
    d1[1].r = d1[1].r - 1,
    d1[1].i = d1[1].i + 1
WHERE
    d1[1].i > 0;

CREATE RULE silly AS ON DELETE TO dcomptable
    DO INSTEAD
    UPDATE
        dcomptable SET
        d1[1].r = d1[1].r - 1,
        d1[1].i = d1[1].i + 1 WHERE
        d1[1].i > 0;

\d+ dcomptable
DROP TABLE dcomptable;

DROP TYPE comptype CASCADE;

-- Test arrays over domains
CREATE DOMAIN posint AS int CHECK (value > 0);

CREATE TABLE pitable (
    f1 posint[]
);

INSERT INTO pitable
    VALUES (ARRAY[42]);

INSERT INTO pitable
    VALUES (ARRAY[-1]);

-- fail
INSERT INTO pitable
    VALUES ('{0}');

-- fail
UPDATE
    pitable
SET
    f1[1] = f1[1] + 1;

UPDATE
    pitable
SET
    f1[1] = 0;

-- fail
SELECT
    *
FROM
    pitable;

DROP TABLE pitable;

CREATE DOMAIN vc4 AS varchar(4);

CREATE TABLE vc4table (
    f1 vc4[]
);

INSERT INTO vc4table
    VALUES (ARRAY['too long']);

-- fail
INSERT INTO vc4table
    VALUES (ARRAY['too long']::vc4[]);

-- cast truncates
SELECT
    *
FROM
    vc4table;

DROP TABLE vc4table;

DROP TYPE vc4;

-- You can sort of fake arrays-of-arrays by putting a domain in between
CREATE DOMAIN dposinta AS posint[];

CREATE TABLE dposintatable (
    f1 dposinta[]
);

INSERT INTO dposintatable
    VALUES (ARRAY[ARRAY[42]]);

-- fail
INSERT INTO dposintatable
    VALUES (ARRAY[ARRAY[42]::posint[]]);

-- still fail
INSERT INTO dposintatable
    VALUES (ARRAY[ARRAY[42]::dposinta]);

-- but this works
SELECT
    f1,
    f1[1],
    (f1[1])[1]
FROM
    dposintatable;

SELECT
    pg_typeof(f1)
FROM
    dposintatable;

SELECT
    pg_typeof(f1[1])
FROM
    dposintatable;

SELECT
    pg_typeof(f1[1][1])
FROM
    dposintatable;

SELECT
    pg_typeof((f1[1])[1])
FROM
    dposintatable;

UPDATE
    dposintatable
SET
    f1[2] = ARRAY[99];

SELECT
    f1,
    f1[1],
    (f1[2])[1]
FROM
    dposintatable;

-- it'd be nice if you could do something like this, but for now you can't:
UPDATE
    dposintatable
SET
    f1[2][1] = ARRAY[97];

-- maybe someday we can make this syntax work:
UPDATE
    dposintatable
SET
    (f1[2])[1] = ARRAY[98];

DROP TABLE dposintatable;

DROP DOMAIN posint CASCADE;

-- Test not-null restrictions
CREATE DOMAIN dnotnull varchar(15) NOT NULL;

CREATE DOMAIN dnull varchar(15);

CREATE DOMAIN dcheck varchar(15) NOT NULL CHECK (VALUE = 'a'
    OR VALUE = 'c'
    OR VALUE = 'd');

CREATE TABLE nulltest (
    col1 dnotnull,
    col2 dnotnull NULL, -- NOT NULL in the domain cannot be overridden
    col3 dnull NOT NULL,
    col4 dnull,
    col5 dcheck CHECK (col5 IN ('c', 'd'))
);

INSERT INTO nulltest DEFAULT VALUES; INSERT INTO nulltest
    VALUES ('a', 'b', 'c', 'd', 'c');

-- Good
INSERT INTO nulltest
    VALUES ('a', 'b', 'c', 'd', NULL);

INSERT INTO nulltest
    VALUES ('a', 'b', 'c', 'd', 'a');

INSERT INTO nulltest
    VALUES (NULL, 'b', 'c', 'd', 'd');

INSERT INTO nulltest
    VALUES ('a', NULL, 'c', 'd', 'c');

INSERT INTO nulltest
    VALUES ('a', 'b', NULL, 'd', 'c');

INSERT INTO nulltest
    VALUES ('a', 'b', 'c', NULL, 'd');

-- Good
SELECT
    *
FROM
    nulltest;

-- Test out coerced (casted) constraints
SELECT
    cast('1' AS dnotnull);

SELECT
    cast(NULL AS dnotnull);

-- fail
SELECT
    cast(cast(NULL AS dnull) AS dnotnull);

-- fail
SELECT
    cast(col4 AS dnotnull)
FROM
    nulltest;

-- fail
-- cleanup
DROP TABLE nulltest;

DROP DOMAIN dnotnull RESTRICT;

DROP DOMAIN dnull RESTRICT;

DROP DOMAIN dcheck RESTRICT;

CREATE DOMAIN ddef1 int4 DEFAULT 3;

CREATE DOMAIN ddef2 oid DEFAULT '12';

-- Type mixing, function returns int8
CREATE DOMAIN ddef3 text DEFAULT 5;

CREATE SEQUENCE ddef4_seq;

CREATE DOMAIN ddef4 int4 DEFAULT nextval('ddef4_seq');

CREATE DOMAIN ddef5 numeric(8, 2) NOT NULL DEFAULT '12.12';

CREATE TABLE defaulttest (
    col1 ddef1,
    col2 ddef2,
    col3 ddef3,
    col4 ddef4 PRIMARY KEY,
    col5 ddef1 NOT NULL DEFAULT NULL,
    col6 ddef2 DEFAULT '88',
    col7 ddef4 DEFAULT 8000,
    col8 ddef5
);

INSERT INTO defaulttest (col4)
    VALUES (0);

-- fails, col5 defaults to null
ALTER TABLE defaulttest
    ALTER COLUMN col5 DROP DEFAULT;

INSERT INTO defaulttest DEFAULT VALUES; -- succeeds, inserts domain default
-- We used to treat SET DEFAULT NULL as equivalent to DROP DEFAULT; wrong
ALTER TABLE defaulttest
    ALTER COLUMN col5 SET DEFAULT NULL;

INSERT INTO defaulttest (col4)
    VALUES (0);

-- fails
ALTER TABLE defaulttest
    ALTER COLUMN col5 DROP DEFAULT;

INSERT INTO defaulttest DEFAULT VALUES; INSERT INTO defaulttest DEFAULT VALUES;
SELECT
    *
FROM
    defaulttest;

DROP TABLE defaulttest CASCADE;

-- Test ALTER DOMAIN .. NOT NULL
CREATE DOMAIN dnotnulltest integer;

CREATE TABLE domnotnull (
    col1 dnotnulltest,
    col2 dnotnulltest
);

INSERT INTO domnotnull DEFAULT VALUES; ALTER DOMAIN dnotnulltest SET NOT NULL;

-- fails
UPDATE
    domnotnull
SET
    col1 = 5;

ALTER DOMAIN dnotnulltest SET NOT NULL;

-- fails
UPDATE
    domnotnull
SET
    col2 = 6;

ALTER DOMAIN dnotnulltest SET NOT NULL;

UPDATE
    domnotnull
SET
    col1 = NULL;

-- fails
ALTER DOMAIN dnotnulltest DROP NOT NULL;

UPDATE
    domnotnull
SET
    col1 = NULL;

DROP DOMAIN dnotnulltest CASCADE;

-- Test ALTER DOMAIN .. DEFAULT ..
CREATE TABLE domdeftest (
    col1 ddef1
);

INSERT INTO domdeftest DEFAULT VALUES;
SELECT
    *
FROM
    domdeftest;

ALTER DOMAIN ddef1 SET DEFAULT '42';

INSERT INTO domdeftest DEFAULT VALUES;
SELECT
    *
FROM
    domdeftest;

ALTER DOMAIN ddef1 DROP DEFAULT;

INSERT INTO domdeftest DEFAULT VALUES;
SELECT
    *
FROM
    domdeftest;

DROP TABLE domdeftest;

-- Test ALTER DOMAIN .. CONSTRAINT ..
CREATE DOMAIN con AS integer;

CREATE TABLE domcontest (
    col1 con
);

INSERT INTO domcontest
    VALUES (1);

INSERT INTO domcontest
    VALUES (2);

ALTER DOMAIN con
    ADD CONSTRAINT t CHECK (VALUE < 1);

-- fails
ALTER DOMAIN con
    ADD CONSTRAINT t CHECK (VALUE < 34);

ALTER DOMAIN con
    ADD CHECK (VALUE > 0);

INSERT INTO domcontest
    VALUES (-5);

-- fails
INSERT INTO domcontest
    VALUES (42);

-- fails
INSERT INTO domcontest
    VALUES (5);

ALTER DOMAIN con
    DROP CONSTRAINT t;

INSERT INTO domcontest
    VALUES (-5);

--fails
INSERT INTO domcontest
    VALUES (42);

ALTER DOMAIN con
    DROP CONSTRAINT nonexistent;

ALTER DOMAIN con
    DROP CONSTRAINT IF EXISTS nonexistent;

-- Test ALTER DOMAIN .. CONSTRAINT .. NOT VALID
CREATE DOMAIN things AS INT;

CREATE TABLE thethings (
    stuff things
);

INSERT INTO thethings (stuff)
    VALUES (55);

ALTER DOMAIN things
    ADD CONSTRAINT meow CHECK (VALUE < 11);

ALTER DOMAIN things
    ADD CONSTRAINT meow CHECK (VALUE < 11) NOT VALID;

ALTER DOMAIN things VALIDATE CONSTRAINT meow;

UPDATE
    thethings
SET
    stuff = 10;

ALTER DOMAIN things VALIDATE CONSTRAINT meow;

-- Confirm ALTER DOMAIN with RULES.
CREATE TABLE domtab (
    col1 integer
);

CREATE DOMAIN dom AS integer;

CREATE VIEW domview AS
SELECT
    cast(col1 AS dom)
FROM
    domtab;

INSERT INTO domtab (col1)
    VALUES (NULL);

INSERT INTO domtab (col1)
    VALUES (5);

SELECT
    *
FROM
    domview;

ALTER DOMAIN dom SET NOT NULL;

SELECT
    *
FROM
    domview;

-- fail
ALTER DOMAIN dom DROP NOT NULL;

SELECT
    *
FROM
    domview;

ALTER DOMAIN dom
    ADD CONSTRAINT domchkgt6 CHECK (value > 6);

SELECT
    *
FROM
    domview;

--fail
ALTER DOMAIN dom
    DROP CONSTRAINT domchkgt6 RESTRICT;

SELECT
    *
FROM
    domview;

-- cleanup
DROP DOMAIN ddef1 RESTRICT;

DROP DOMAIN ddef2 RESTRICT;

DROP DOMAIN ddef3 RESTRICT;

DROP DOMAIN ddef4 RESTRICT;

DROP DOMAIN ddef5 RESTRICT;

DROP SEQUENCE ddef4_seq;

-- Test domains over domains
CREATE DOMAIN vchar4 varchar(4);

CREATE DOMAIN dinter vchar4 CHECK (substring(VALUE, 1, 1) = 'x');

CREATE DOMAIN dtop dinter CHECK (substring(VALUE, 2, 1) = '1');

SELECT
    'x123'::dtop;

SELECT
    'x1234'::dtop;

-- explicit coercion should truncate
SELECT
    'y1234'::dtop;

-- fail
SELECT
    'y123'::dtop;

-- fail
SELECT
    'yz23'::dtop;

-- fail
SELECT
    'xz23'::dtop;

-- fail
CREATE temp TABLE dtest (
    f1 dtop
);

INSERT INTO dtest
    VALUES ('x123');

INSERT INTO dtest
    VALUES ('x1234');

-- fail, implicit coercion
INSERT INTO dtest
    VALUES ('y1234');

-- fail, implicit coercion
INSERT INTO dtest
    VALUES ('y123');

-- fail
INSERT INTO dtest
    VALUES ('yz23');

-- fail
INSERT INTO dtest
    VALUES ('xz23');

-- fail
DROP TABLE dtest;

DROP DOMAIN vchar4 CASCADE;

-- Make sure that constraints of newly-added domain columns are
-- enforced correctly, even if there's no default value for the new
-- column. Per bug #1433
CREATE DOMAIN str_domain AS text NOT NULL;

CREATE TABLE domain_test (
    a int,
    b int
);

INSERT INTO domain_test
    VALUES (1, 2);

INSERT INTO domain_test
    VALUES (1, 2);

-- should fail
ALTER TABLE domain_test
    ADD COLUMN c str_domain;

CREATE DOMAIN str_domain2 AS text CHECK (value <> 'foo') DEFAULT 'foo';

-- should fail
ALTER TABLE domain_test
    ADD COLUMN d str_domain2;

-- Check that domain constraints on prepared statement parameters of
-- unknown type are enforced correctly.
CREATE DOMAIN pos_int AS int4 CHECK (value > 0) NOT NULL;

PREPARE s1 AS
SELECT
    $1::pos_int = 10 AS "is_ten";

EXECUTE s1 (10);

EXECUTE s1 (0);

-- should fail
EXECUTE s1 (NULL);

-- should fail
-- Check that domain constraints on plpgsql function parameters, results,
-- and local variables are enforced correctly.
CREATE FUNCTION doubledecrement (p1 pos_int)
    RETURNS pos_int
    AS $$
DECLARE
    v pos_int;
BEGIN
    RETURN p1;
END
$$
LANGUAGE plpgsql;

SELECT
    doubledecrement (3);

-- fail because of implicit null assignment
CREATE OR REPLACE FUNCTION doubledecrement (p1 pos_int)
    RETURNS pos_int
    AS $$
DECLARE
    v pos_int := 0;
BEGIN
    RETURN p1;
END
$$
LANGUAGE plpgsql;

SELECT
    doubledecrement (3);

-- fail at initialization assignment
CREATE OR REPLACE FUNCTION doubledecrement (p1 pos_int)
    RETURNS pos_int
    AS $$
DECLARE
    v pos_int := 1;
BEGIN
    v := p1 - 1;
    RETURN v - 1;
END
$$
LANGUAGE plpgsql;

SELECT
    doubledecrement (NULL);

-- fail before call
SELECT
    doubledecrement (0);

-- fail before call
SELECT
    doubledecrement (1);

-- fail at assignment to v
SELECT
    doubledecrement (2);

-- fail at return
SELECT
    doubledecrement (3);

-- good
-- Check that ALTER DOMAIN tests columns of derived types
CREATE DOMAIN posint AS int4;

-- Currently, this doesn't work for composite types, but verify it complains
CREATE TYPE ddtest1 AS (
    f1 posint
);

CREATE TABLE ddtest2 (
    f1 ddtest1
);

INSERT INTO ddtest2
    VALUES (ROW (-1));

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

DROP TABLE ddtest2;

-- Likewise for domains within arrays of composite
CREATE TABLE ddtest2 (
    f1 ddtest1[]
);

INSERT INTO ddtest2
    VALUES ('{(-1)}');

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

DROP TABLE ddtest2;

-- Likewise for domains within domains over composite
CREATE DOMAIN ddtest1d AS ddtest1;

CREATE TABLE ddtest2 (
    f1 ddtest1d
);

INSERT INTO ddtest2
    VALUES ('(-1)');

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

DROP TABLE ddtest2;

DROP DOMAIN ddtest1d;

-- Likewise for domains within domains over array of composite
CREATE DOMAIN ddtest1d AS ddtest1[];

CREATE TABLE ddtest2 (
    f1 ddtest1d
);

INSERT INTO ddtest2
    VALUES ('{(-1)}');

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

DROP TABLE ddtest2;

DROP DOMAIN ddtest1d;

-- Doesn't work for ranges, either
CREATE TYPE rposint AS RANGE (
    subtype = posint
);

CREATE TABLE ddtest2 (
    f1 rposint
);

INSERT INTO ddtest2
    VALUES ('(-1,3]');

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

DROP TABLE ddtest2;

DROP TYPE rposint;

ALTER DOMAIN posint
    ADD CONSTRAINT c1 CHECK (value >= 0);

CREATE DOMAIN posint2 AS posint CHECK (value % 2 = 0);

CREATE TABLE ddtest2 (
    f1 posint2
);

INSERT INTO ddtest2
    VALUES (11);

-- fail
INSERT INTO ddtest2
    VALUES (-2);

-- fail
INSERT INTO ddtest2
    VALUES (2);

ALTER DOMAIN posint
    ADD CONSTRAINT c2 CHECK (value >= 10);

-- fail
ALTER DOMAIN posint
    ADD CONSTRAINT c2 CHECK (value > 0);

-- OK
DROP TABLE ddtest2;

DROP TYPE ddtest1;

DROP DOMAIN posint CASCADE;

--
-- Check enforcement of domain-related typmod in plpgsql (bug #5717)
--
CREATE OR REPLACE FUNCTION array_elem_check (numeric)
    RETURNS numeric
    AS $$
DECLARE
    x numeric(4, 2)[1];
BEGIN
    x[1] := $1;
    RETURN x[1];
END
$$
LANGUAGE plpgsql;

SELECT
    array_elem_check (121.00);

SELECT
    array_elem_check (1.23456);

CREATE DOMAIN mynums AS numeric(4, 2)[1];

CREATE OR REPLACE FUNCTION array_elem_check (numeric)
    RETURNS numeric
    AS $$
DECLARE
    x mynums;
BEGIN
    x[1] := $1;
    RETURN x[1];
END
$$
LANGUAGE plpgsql;

SELECT
    array_elem_check (121.00);

SELECT
    array_elem_check (1.23456);

CREATE DOMAIN mynums2 AS mynums;

CREATE OR REPLACE FUNCTION array_elem_check (numeric)
    RETURNS numeric
    AS $$
DECLARE
    x mynums2;
BEGIN
    x[1] := $1;
    RETURN x[1];
END
$$
LANGUAGE plpgsql;

SELECT
    array_elem_check (121.00);

SELECT
    array_elem_check (1.23456);

DROP FUNCTION array_elem_check (numeric);

--
-- Check enforcement of array-level domain constraints
--
CREATE DOMAIN orderedpair AS int[2] CHECK (value[1] < value[2]);

SELECT
    ARRAY[1, 2]::orderedpair;

SELECT
    ARRAY[2, 1]::orderedpair;

-- fail
CREATE temp TABLE op (
    f1 orderedpair
);

INSERT INTO op
    VALUES (ARRAY[1, 2]);

INSERT INTO op
    VALUES (ARRAY[2, 1]);

-- fail
UPDATE
    op
SET
    f1[2] = 3;

UPDATE
    op
SET
    f1[2] = 0;

-- fail
SELECT
    *
FROM
    op;

CREATE OR REPLACE FUNCTION array_elem_check (int)
    RETURNS int
    AS $$
DECLARE
    x orderedpair := '{1,2}';
BEGIN
    x[2] := $1;
    RETURN x[2];
END
$$
LANGUAGE plpgsql;

SELECT
    array_elem_check (3);

SELECT
    array_elem_check (-1);

DROP FUNCTION array_elem_check (int);

--
-- Check enforcement of changing constraints in plpgsql
--
CREATE DOMAIN di AS int;

CREATE FUNCTION dom_check (int)
    RETURNS di
    AS $$
DECLARE
    d di;
BEGIN
    d := $1::di;
    RETURN d;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

SELECT
    dom_check (0);

ALTER DOMAIN di
    ADD CONSTRAINT pos CHECK (value > 0);

SELECT
    dom_check (0);

-- fail
ALTER DOMAIN di
    DROP CONSTRAINT pos;

SELECT
    dom_check (0);

-- implicit cast during assignment is a separate code path, test that too
CREATE OR REPLACE FUNCTION dom_check (int)
    RETURNS di
    AS $$
DECLARE
    d di;
BEGIN
    d := $1;
    RETURN d;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

SELECT
    dom_check (0);

ALTER DOMAIN di
    ADD CONSTRAINT pos CHECK (value > 0);

SELECT
    dom_check (0);

-- fail
ALTER DOMAIN di
    DROP CONSTRAINT pos;

SELECT
    dom_check (0);

DROP FUNCTION dom_check (int);

DROP DOMAIN di;

--
-- Check use of a (non-inline-able) SQL function in a domain constraint;
-- this has caused issues in the past
--
CREATE FUNCTION sql_is_distinct_from (anyelement, anyelement)
    RETURNS boolean
    LANGUAGE sql
    AS '
    SELECT
        $1 IS DISTINCT FROM $2
    LIMIT 1;
';

CREATE DOMAIN inotnull int CHECK (sql_is_distinct_from (value, NULL));

SELECT
    1::inotnull;

SELECT
    NULL::inotnull;

CREATE TABLE dom_table (
    x inotnull
);

INSERT INTO dom_table
    VALUES ('1');

INSERT INTO dom_table
    VALUES (1);

INSERT INTO dom_table
    VALUES (NULL);

DROP TABLE dom_table;

DROP DOMAIN inotnull;

DROP FUNCTION sql_is_distinct_from (anyelement, anyelement);

--
-- Renaming
--
CREATE DOMAIN testdomain1 AS int;

ALTER DOMAIN testdomain1 RENAME TO testdomain2;

ALTER TYPE testdomain2 RENAME TO testdomain3;

-- alter type also works
DROP DOMAIN testdomain3;

--
-- Renaming domain constraints
--
CREATE DOMAIN testdomain1 AS int CONSTRAINT unsigned CHECK (value > 0);

ALTER DOMAIN testdomain1 RENAME CONSTRAINT unsigned TO unsigned_foo;

ALTER DOMAIN testdomain1
    DROP CONSTRAINT unsigned_foo;

DROP DOMAIN testdomain1;

