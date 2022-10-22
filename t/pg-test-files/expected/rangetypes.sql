-- Tests for range data types.
CREATE TYPE textrange AS RANGE (
    subtype = text,
    COLLATION = "C"
);

--
-- test input parser
--
-- negative tests; should fail
SELECT
    ''::textrange;

SELECT
    '-[a,z)'::textrange;

SELECT
    '[a,z) - '::textrange;

SELECT
    '(",a)'::textrange;

SELECT
    '(,,a)'::textrange;

SELECT
    '(),a)'::textrange;

SELECT
    '(a,))'::textrange;

SELECT
    '(],a)'::textrange;

SELECT
    '(a,])'::textrange;

SELECT
    '[z,a]'::textrange;

-- should succeed
SELECT
    '  empty  '::textrange;

SELECT
    ' ( empty, empty )  '::textrange;

SELECT
    ' ( " a " " a ", " z " " z " )  '::textrange;

SELECT
    '(,z)'::textrange;

SELECT
    '(a,)'::textrange;

SELECT
    '[,z]'::textrange;

SELECT
    '[a,]'::textrange;

SELECT
    '(,)'::textrange;

SELECT
    '[ , ]'::textrange;

SELECT
    '["",""]'::textrange;

SELECT
    '[",",","]'::textrange;

SELECT
    '["\\","\\"]'::textrange;

SELECT
    '(\\,a)'::textrange;

SELECT
    '((,z)'::textrange;

SELECT
    '([,z)'::textrange;

SELECT
    '(!,()'::textrange;

SELECT
    '(!,[)'::textrange;

SELECT
    '[a,a]'::textrange;

-- these are allowed but normalize to empty:
SELECT
    '[a,a)'::textrange;

SELECT
    '(a,a]'::textrange;

SELECT
    '(a,a)'::textrange;

--
-- create some test data and test the operators
--
CREATE TABLE numrange_test (
    nr numrange
);

CREATE INDEX numrange_test_btree ON numrange_test (nr);

INSERT INTO numrange_test
    VALUES ('[,)');

INSERT INTO numrange_test
    VALUES ('[3,]');

INSERT INTO numrange_test
    VALUES ('[, 5)');

INSERT INTO numrange_test
    VALUES (numrange(1.1, 2.2));

INSERT INTO numrange_test
    VALUES ('empty');

INSERT INTO numrange_test
    VALUES (numrange(1.7, 1.7, '[]'));

SELECT
    nr,
    isempty(nr),
    lower(nr),
    upper(nr)
FROM
    numrange_test;

SELECT
    nr,
    lower_inc(nr),
    lower_inf(nr),
    upper_inc(nr),
    upper_inf(nr)
FROM
    numrange_test;

SELECT
    *
FROM
    numrange_test
WHERE
    range_contains(nr, numrange(1.9, 1.91));

SELECT
    *
FROM
    numrange_test
WHERE
    nr @> numrange(1.0, 10000.1);

SELECT
    *
FROM
    numrange_test
WHERE
    range_contained_by(numrange(- 1e7, -10000.1), nr);

SELECT
    *
FROM
    numrange_test
WHERE
    1.9 <@ nr;

SELECT
    *
FROM
    numrange_test
WHERE
    nr = 'empty';

SELECT
    *
FROM
    numrange_test
WHERE
    nr = '(1.1, 2.2)';

SELECT
    *
FROM
    numrange_test
WHERE
    nr = '[1.1, 2.2)';

SELECT
    *
FROM
    numrange_test
WHERE
    nr < 'empty';

SELECT
    *
FROM
    numrange_test
WHERE
    nr < numrange(-1000.0, -1000.0, '[]');

SELECT
    *
FROM
    numrange_test
WHERE
    nr < numrange(0.0, 1.0, '[]');

SELECT
    *
FROM
    numrange_test
WHERE
    nr < numrange(1000.0, 1001.0, '[]');

SELECT
    *
FROM
    numrange_test
WHERE
    nr <= 'empty';

SELECT
    *
FROM
    numrange_test
WHERE
    nr >= 'empty';

SELECT
    *
FROM
    numrange_test
WHERE
    nr > 'empty';

SELECT
    *
FROM
    numrange_test
WHERE
    nr > numrange(-1001.0, -1000.0, '[]');

SELECT
    *
FROM
    numrange_test
WHERE
    nr > numrange(0.0, 1.0, '[]');

SELECT
    *
FROM
    numrange_test
WHERE
    nr > numrange(1000.0, 1000.0, '[]');

SELECT
    numrange(2.0, 1.0);

SELECT
    numrange(2.0, 3.0) -|- numrange(3.0, 4.0);

SELECT
    range_adjacent(numrange(2.0, 3.0), numrange(3.1, 4.0));

SELECT
    range_adjacent(numrange(2.0, 3.0), numrange(3.1, NULL));

SELECT
    numrange(2.0, 3.0, '[]') -|- numrange(3.0, 4.0, '()');

SELECT
    numrange(1.0, 2.0) -|- numrange(2.0, 3.0, '[]');

SELECT
    range_adjacent(numrange(2.0, 3.0, '(]'), numrange(1.0, 2.0, '(]'));

SELECT
    numrange(1.1, 3.3) <@ numrange(0.1, 10.1);

SELECT
    numrange(0.1, 10.1) <@ numrange(1.1, 3.3);

SELECT
    numrange(1.1, 2.2) - numrange(2.0, 3.0);

SELECT
    numrange(1.1, 2.2) - numrange(2.2, 3.0);

SELECT
    numrange(1.1, 2.2, '[]') - numrange(2.0, 3.0);

SELECT
    range_minus(numrange(10.1, 12.2, '[]'), numrange(110.0, 120.2, '(]'));

SELECT
    range_minus(numrange(10.1, 12.2, '[]'), numrange(0.0, 120.2, '(]'));

SELECT
    numrange(4.5, 5.5, '[]') && numrange(5.5, 6.5);

SELECT
    numrange(1.0, 2.0) << numrange(3.0, 4.0);

SELECT
    numrange(1.0, 3.0, '[]') << numrange(3.0, 4.0, '[]');

SELECT
    numrange(1.0, 3.0, '()') << numrange(3.0, 4.0, '()');

SELECT
    numrange(1.0, 2.0) >> numrange(3.0, 4.0);

SELECT
    numrange(3.0, 70.0) &< numrange(6.6, 100.0);

SELECT
    numrange(1.1, 2.2) < numrange(1.0, 200.2);

SELECT
    numrange(1.1, 2.2) < numrange(1.1, 1.2);

SELECT
    numrange(1.0, 2.0) + numrange(2.0, 3.0);

SELECT
    numrange(1.0, 2.0) + numrange(1.5, 3.0);

SELECT
    numrange(1.0, 2.0) + numrange(2.5, 3.0);

-- should fail
SELECT
    range_merge(numrange(1.0, 2.0), numrange(2.0, 3.0));

SELECT
    range_merge(numrange(1.0, 2.0), numrange(1.5, 3.0));

SELECT
    range_merge(numrange(1.0, 2.0), numrange(2.5, 3.0));

-- shouldn't fail
SELECT
    numrange(1.0, 2.0) * numrange(2.0, 3.0);

SELECT
    numrange(1.0, 2.0) * numrange(1.5, 3.0);

SELECT
    numrange(1.0, 2.0) * numrange(2.5, 3.0);

CREATE TABLE numrange_test2 (
    nr numrange
);

CREATE INDEX numrange_test2_hash_idx ON numrange_test2 (nr);

INSERT INTO numrange_test2
    VALUES ('[, 5)');

INSERT INTO numrange_test2
    VALUES (numrange(1.1, 2.2));

INSERT INTO numrange_test2
    VALUES (numrange(1.1, 2.2));

INSERT INTO numrange_test2
    VALUES (numrange(1.1, 2.2, '()'));

INSERT INTO numrange_test2
    VALUES ('empty');

SELECT
    *
FROM
    numrange_test2
WHERE
    nr = 'empty'::numrange;

SELECT
    *
FROM
    numrange_test2
WHERE
    nr = numrange(1.1, 2.2);

SELECT
    *
FROM
    numrange_test2
WHERE
    nr = numrange(1.1, 2.3);

SET enable_nestloop = t;

SET enable_hashjoin = f;

SET enable_mergejoin = f;

SELECT
    *
FROM
    numrange_test
    NATURAL JOIN numrange_test2
ORDER BY
    nr;

SET enable_nestloop = f;

SET enable_hashjoin = t;

SET enable_mergejoin = f;

SELECT
    *
FROM
    numrange_test
    NATURAL JOIN numrange_test2
ORDER BY
    nr;

SET enable_nestloop = f;

SET enable_hashjoin = f;

SET enable_mergejoin = t;

SELECT
    *
FROM
    numrange_test
    NATURAL JOIN numrange_test2
ORDER BY
    nr;

SET enable_nestloop TO DEFAULT;

SET enable_hashjoin TO DEFAULT;

SET enable_mergejoin TO DEFAULT;

DROP TABLE numrange_test;

DROP TABLE numrange_test2;

-- test canonical form for int4range
SELECT
    int4range(1, 10, '[]');

SELECT
    int4range(1, 10, '[)');

SELECT
    int4range(1, 10, '(]');

SELECT
    int4range(1, 10, '()');

SELECT
    int4range(1, 2, '()');

-- test canonical form for daterange
SELECT
    daterange('2000-01-10'::date, '2000-01-20'::date, '[]');

SELECT
    daterange('2000-01-10'::date, '2000-01-20'::date, '[)');

SELECT
    daterange('2000-01-10'::date, '2000-01-20'::date, '(]');

SELECT
    daterange('2000-01-10'::date, '2000-01-20'::date, '()');

SELECT
    daterange('2000-01-10'::date, '2000-01-11'::date, '()');

SELECT
    daterange('2000-01-10'::date, '2000-01-11'::date, '(]');

-- test GiST index that's been built incrementally
CREATE TABLE test_range_gist (
    ir int4range
);

CREATE INDEX test_range_gist_idx ON test_range_gist USING gist (ir);

INSERT INTO test_range_gist
SELECT
    int4range(g, g + 10)
FROM
    generate_series(1, 2000) g;

INSERT INTO test_range_gist
SELECT
    'empty'::int4range
FROM
    generate_series(1, 500) g;

INSERT INTO test_range_gist
SELECT
    int4range(g, g + 10000)
FROM
    generate_series(1, 1000) g;

INSERT INTO test_range_gist
SELECT
    'empty'::int4range
FROM
    generate_series(1, 500) g;

INSERT INTO test_range_gist
SELECT
    int4range(NULL, g * 10, '(]')
FROM
    generate_series(1, 100) g;

INSERT INTO test_range_gist
SELECT
    int4range(g * 10, NULL, '(]')
FROM
    generate_series(1, 100) g;

INSERT INTO test_range_gist
SELECT
    int4range(g, g + 10)
FROM
    generate_series(1, 2000) g;

-- first, verify non-indexed results
SET enable_seqscan = t;

SET enable_indexscan = f;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4range(100, 500);

-- now check same queries using index
SET enable_seqscan = f;

SET enable_indexscan = t;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4range(100, 500);

-- now check same queries using a bulk-loaded index
DROP INDEX test_range_gist_idx;

CREATE INDEX test_range_gist_idx ON test_range_gist USING gist (ir);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4range(100, 500);

-- test SP-GiST index that's been built incrementally
CREATE TABLE test_range_spgist (
    ir int4range
);

CREATE INDEX test_range_spgist_idx ON test_range_spgist USING spgist (ir);

INSERT INTO test_range_spgist
SELECT
    int4range(g, g + 10)
FROM
    generate_series(1, 2000) g;

INSERT INTO test_range_spgist
SELECT
    'empty'::int4range
FROM
    generate_series(1, 500) g;

INSERT INTO test_range_spgist
SELECT
    int4range(g, g + 10000)
FROM
    generate_series(1, 1000) g;

INSERT INTO test_range_spgist
SELECT
    'empty'::int4range
FROM
    generate_series(1, 500) g;

INSERT INTO test_range_spgist
SELECT
    int4range(NULL, g * 10, '(]')
FROM
    generate_series(1, 100) g;

INSERT INTO test_range_spgist
SELECT
    int4range(g * 10, NULL, '(]')
FROM
    generate_series(1, 100) g;

INSERT INTO test_range_spgist
SELECT
    int4range(g, g + 10)
FROM
    generate_series(1, 2000) g;

-- first, verify non-indexed results
SET enable_seqscan = t;

SET enable_indexscan = f;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir -|- int4range(100, 500);

-- now check same queries using index
SET enable_seqscan = f;

SET enable_indexscan = t;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir -|- int4range(100, 500);

-- now check same queries using a bulk-loaded index
DROP INDEX test_range_spgist_idx;

CREATE INDEX test_range_spgist_idx ON test_range_spgist USING spgist (ir);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir = int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> 10;

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir && int4range(10, 20);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir << int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_range_spgist
WHERE
    ir -|- int4range(100, 500);

-- test index-only scans
EXPLAIN (
    COSTS OFF
)
SELECT
    ir
FROM
    test_range_spgist
WHERE
    ir -|- int4range(10, 20)
ORDER BY
    ir;

SELECT
    ir
FROM
    test_range_spgist
WHERE
    ir -|- int4range(10, 20)
ORDER BY
    ir;

RESET enable_seqscan;

RESET enable_indexscan;

RESET enable_bitmapscan;

-- test elem <@ range operator
CREATE TABLE test_range_elem (
    i int4
);

CREATE INDEX test_range_elem_idx ON test_range_elem (i);

INSERT INTO test_range_elem
SELECT
    i
FROM
    generate_series(1, 100) i;

SELECT
    count(*)
FROM
    test_range_elem
WHERE
    i <@ int4range(10, 50);

DROP TABLE test_range_elem;

--
-- Btree_gist is not included by default, so to test exclusion
-- constraints with range types, use singleton int ranges for the "="
-- portion of the constraint.
--
CREATE TABLE test_range_excl (
    room int4range,
    speaker int4range,
    during tsrange,
    EXCLUDE USING gist (room WITH =, during WITH &&),
    EXCLUDE USING gist (speaker WITH =, during WITH &&)
);

INSERT INTO test_range_excl
    VALUES (int4range(123, 123, '[]'), int4range(1, 1, '[]'), '[2010-01-02 10:00, 2010-01-02 11:00)');

INSERT INTO test_range_excl
    VALUES (int4range(123, 123, '[]'), int4range(2, 2, '[]'), '[2010-01-02 11:00, 2010-01-02 12:00)');

INSERT INTO test_range_excl
    VALUES (int4range(123, 123, '[]'), int4range(3, 3, '[]'), '[2010-01-02 10:10, 2010-01-02 11:00)');

INSERT INTO test_range_excl
    VALUES (int4range(124, 124, '[]'), int4range(3, 3, '[]'), '[2010-01-02 10:10, 2010-01-02 11:10)');

INSERT INTO test_range_excl
    VALUES (int4range(125, 125, '[]'), int4range(1, 1, '[]'), '[2010-01-02 10:10, 2010-01-02 11:00)');

-- test bigint ranges
SELECT
    int8range(10000000000::int8, 20000000000::int8, '(]');

-- test tstz ranges
SET timezone TO '-08';

SELECT
    '[2010-01-01 01:00:00 -05, 2010-01-01 02:00:00 -08)'::tstzrange;

-- should fail
SELECT
    '[2010-01-01 01:00:00 -08, 2010-01-01 02:00:00 -05)'::tstzrange;

SET timezone TO DEFAULT;

--
-- Test user-defined range of floats
--
--should fail
CREATE TYPE float8range AS RANGE (
    subtype = float8,
    subtype_diff = float4mi
);

--should succeed
CREATE TYPE float8range AS RANGE (
    subtype = float8,
    subtype_diff = float8mi
);

SELECT
    '[123.001, 5.e9)'::float8range @> 888.882::float8;

CREATE TABLE float8range_test (
    f8r float8range,
    i int
);

INSERT INTO float8range_test
    VALUES (float8range (-100.00007, '1.111113e9'), 42);

SELECT
    *
FROM
    float8range_test;

DROP TABLE float8range_test;

--
-- Test range types over domains
--
CREATE DOMAIN mydomain AS int4;

CREATE TYPE mydomainrange AS RANGE (
    subtype = mydomain
);

SELECT
    '[4,50)'::mydomainrange @> 7::mydomain;

DROP DOMAIN mydomain;

-- fail
DROP DOMAIN mydomain CASCADE;

--
-- Test domains over range types
--
CREATE DOMAIN restrictedrange AS int4range CHECK (upper(value) < 10);

SELECT
    '[4,5)'::restrictedrange @> 7;

SELECT
    '[4,50)'::restrictedrange @> 7;

-- should fail
DROP DOMAIN restrictedrange;

--
-- Test multiple range types over the same subtype
--
CREATE TYPE textrange1 AS RANGE (
    subtype = text,
    COLLATION = "C"
);

CREATE TYPE textrange2 AS RANGE (
    subtype = text,
    COLLATION = "C"
);

SELECT
    textrange1 ('a', 'Z') @> 'b'::text;

SELECT
    textrange2 ('a', 'z') @> 'b'::text;

DROP TYPE textrange1;

DROP TYPE textrange2;

--
-- Test polymorphic type system
--
CREATE FUNCTION anyarray_anyrange_func (a anyarray, r anyrange)
    RETURNS anyelement
    AS '
    SELECT
        $1[1] + lower($2);
'
LANGUAGE sql;

SELECT
    anyarray_anyrange_func (ARRAY[1, 2], int4range(10, 20));

-- should fail
SELECT
    anyarray_anyrange_func (ARRAY[1, 2], numrange(10, 20));

DROP FUNCTION anyarray_anyrange_func (anyarray, anyrange);

-- should fail
CREATE FUNCTION bogus_func (anyelement)
    RETURNS anyrange
    AS '
    SELECT
        int4range(1, 10);
'
LANGUAGE sql;

-- should fail
CREATE FUNCTION bogus_func (int)
    RETURNS anyrange
    AS '
    SELECT
        int4range(1, 10);
'
LANGUAGE sql;

CREATE FUNCTION range_add_bounds (anyrange)
    RETURNS anyelement
    AS '
    SELECT
        lower($1) + upper($1);
'
LANGUAGE sql;

SELECT
    range_add_bounds (int4range(1, 17));

SELECT
    range_add_bounds (numrange(1.0001, 123.123));

CREATE FUNCTION rangetypes_sql (q anyrange, b anyarray, out c anyelement)
AS $$
    SELECT
        upper($1) + $2[1]
$$
LANGUAGE sql;

SELECT
    rangetypes_sql (int4range(1, 10), ARRAY[2, 20]);

SELECT
    rangetypes_sql (numrange(1, 10), ARRAY[2, 20]);

-- match failure
--
-- Arrays of ranges
--
SELECT
    ARRAY[numrange(1.1, 1.2), numrange(12.3, 155.5)];

CREATE TABLE i8r_array (
    f1 int,
    f2 int8range[]
);

INSERT INTO i8r_array
    VALUES (42, ARRAY[int8range(1, 10), int8range(2, 20)]);

SELECT
    *
FROM
    i8r_array;

DROP TABLE i8r_array;

--
-- Ranges of arrays
--
CREATE TYPE arrayrange AS RANGE (
    subtype = int4[]
);

SELECT
    arrayrange (ARRAY[1, 2], ARRAY[2, 1]);

SELECT
    arrayrange (ARRAY[2, 1], ARRAY[1, 2]);

-- fail
SELECT
    ARRAY[1, 1] <@ arrayrange (ARRAY[1, 2], ARRAY[2, 1]);

SELECT
    ARRAY[1, 3] <@ arrayrange (ARRAY[1, 2], ARRAY[2, 1]);

--
-- Ranges of composites
--
CREATE TYPE two_ints AS (
    a int,
    b int
);

CREATE TYPE two_ints_range AS RANGE (
    subtype = two_ints
);

-- with force_parallel_mode on, this exercises tqueue.c's range remapping
SELECT
    *,
    row_to_json(upper(t)) AS u
FROM (
    VALUES (two_ints_range (ROW (1, 2), ROW (3, 4))),
        (two_ints_range (ROW (5, 6), ROW (7, 8)))) v (t);

DROP TYPE two_ints CASCADE;

--
-- Check behavior when subtype lacks a hash function
--
CREATE TYPE cashrange AS RANGE (
    subtype = money
);

SET enable_sort = OFF;

-- try to make it pick a hash setop implementation
SELECT
    '(2,5)'::cashrange
EXCEPT
SELECT
    '(5,6)'::cashrange;

RESET enable_sort;

--
-- OUT/INOUT/TABLE functions
--
CREATE FUNCTION outparam_succeed (i anyrange, out r anyrange, out t text)
AS $$
    SELECT
        $1,
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    outparam_succeed (int4range(1, 2));

CREATE FUNCTION inoutparam_succeed (out i anyelement, INOUT r anyrange)
AS $$
    SELECT
        upper($1),
        $1
$$
LANGUAGE sql;

SELECT
    *
FROM
    inoutparam_succeed (int4range(1, 2));

CREATE FUNCTION table_succeed (i anyelement, r anyrange)
    RETURNS TABLE (
        i anyelement,
        r anyrange
    )
    AS $$
    SELECT
        $1,
        $2
$$
LANGUAGE sql;

SELECT
    *
FROM
    table_succeed (123, int4range(1, 11));

-- should fail
CREATE FUNCTION outparam_fail (i anyelement, out r anyrange, out t text)
AS $$
    SELECT
        '[1,10]',
        'foo'
$$
LANGUAGE sql;

--should fail
CREATE FUNCTION inoutparam_fail (INOUT i anyelement, out r anyrange)
AS $$
    SELECT
        $1,
        '[1,10]'
$$
LANGUAGE sql;

--should fail
CREATE FUNCTION table_fail (i anyelement)
    RETURNS TABLE (
        i anyelement,
        r anyrange
    )
    AS $$
    SELECT
        $1,
        '[1,10]'
$$
LANGUAGE sql;

