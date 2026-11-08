-- Tests for range data types.
--
-- test input parser
-- (type textrange was already made in test_setup.sql)
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

-- Also try it with non-error-throwing API
SELECT
    pg_input_is_valid ('(1,4)', 'int4range');

SELECT
    pg_input_is_valid ('(1,4', 'int4range');

SELECT
    *
FROM
    pg_input_error_info ('(1,4', 'int4range');

SELECT
    pg_input_is_valid ('(4,1)', 'int4range');

SELECT
    *
FROM
    pg_input_error_info ('(4,1)', 'int4range');

SELECT
    pg_input_is_valid ('(4,zed)', 'int4range');

SELECT
    *
FROM
    pg_input_error_info ('(4,zed)', 'int4range');

SELECT
    pg_input_is_valid ('[1,2147483647]', 'int4range');

SELECT
    *
FROM
    pg_input_error_info ('[1,2147483647]', 'int4range');

SELECT
    pg_input_is_valid ('[2000-01-01,5874897-12-31]', 'daterange');

SELECT
    *
FROM
    pg_input_error_info ('[2000-01-01,5874897-12-31]', 'daterange');

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
    range_minus_multi ('empty'::numrange, numrange(2.0, 3.0));

SELECT
    range_minus_multi (numrange(1.1, 2.2), 'empty'::numrange);

SELECT
    range_minus_multi (numrange(1.1, 2.2), numrange(2.0, 3.0));

SELECT
    range_minus_multi (numrange(1.1, 2.2), numrange(2.2, 3.0));

SELECT
    range_minus_multi (numrange(1.1, 2.2, '[]'), numrange(2.0, 3.0));

SELECT
    range_minus_multi (numrange(1.0, 3.0), numrange(1.5, 2.0));

SELECT
    range_minus_multi (numrange(10.1, 12.2, '[]'), numrange(110.0, 120.2, '(]'));

SELECT
    range_minus_multi (numrange(10.1, 12.2, '[]'), numrange(0.0, 120.2, '(]'));

SELECT
    range_minus_multi (numrange(1.0, 3.0, '[]'), numrange(1.5, 2.0, '(]'));

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

SELECT
    range_intersect_agg (nr)
FROM
    numrange_test;

SELECT
    range_intersect_agg (nr)
FROM
    numrange_test
WHERE
    FALSE;

SELECT
    range_intersect_agg (nr)
FROM
    numrange_test
WHERE
    nr @> 4.0;

ANALYZE numrange_test;

CREATE TABLE numrange_test2 (
    nr numrange
);

CREATE INDEX numrange_test2_hash_idx ON numrange_test2 USING HASH (nr);

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

-- keep numrange_test around to help exercise dump/reload
DROP TABLE numrange_test2;

--
-- Apply a subset of the above tests on a collatable type, too
--
CREATE TABLE textrange_test (
    tr textrange
);

CREATE INDEX textrange_test_btree ON textrange_test (tr);

INSERT INTO textrange_test
    VALUES ('[,)');

INSERT INTO textrange_test
    VALUES ('["a",]');

INSERT INTO textrange_test
    VALUES ('[,"q")');

INSERT INTO textrange_test
    VALUES (textrange ('b', 'g'));

INSERT INTO textrange_test
    VALUES ('empty');

INSERT INTO textrange_test
    VALUES (textrange ('d', 'd', '[]'));

SELECT
    tr,
    isempty(tr),
    lower(tr),
    upper(tr)
FROM
    textrange_test;

SELECT
    tr,
    lower_inc(tr),
    lower_inf(tr),
    upper_inc(tr),
    upper_inf(tr)
FROM
    textrange_test;

SELECT
    *
FROM
    textrange_test
WHERE
    range_contains(tr, textrange ('f', 'fx'));

SELECT
    *
FROM
    textrange_test
WHERE
    tr @> textrange ('a', 'z');

SELECT
    *
FROM
    textrange_test
WHERE
    range_contained_by(textrange ('0', '9'), tr);

SELECT
    *
FROM
    textrange_test
WHERE
    'e'::text <@ tr;

SELECT
    *
FROM
    textrange_test
WHERE
    tr = 'empty';

SELECT
    *
FROM
    textrange_test
WHERE
    tr = '("b","g")';

SELECT
    *
FROM
    textrange_test
WHERE
    tr = '["b","g")';

SELECT
    *
FROM
    textrange_test
WHERE
    tr < 'empty';

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

SELECT
    daterange('-infinity'::date, '2000-01-01'::date, '()');

SELECT
    daterange('-infinity'::date, '2000-01-01'::date, '[)');

SELECT
    daterange('2000-01-01'::date, 'infinity'::date, '[)');

SELECT
    daterange('2000-01-01'::date, 'infinity'::date, '[]');

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

-- test statistics and selectivity estimation as well
--
-- We don't check the accuracy of selectivity estimation, but at least check
-- it doesn't fall.
ANALYZE test_range_gist;

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

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4multirange (int4range(10, 20), int4range(30, 40));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && '{(10,20),(30,40),(50,60)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ '{(10,30),(40,60),(70,90)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4multirange (int4range(100, 200), int4range(400, 500));

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

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4multirange (int4range(10, 20), int4range(30, 40));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && '{(10,20),(30,40),(50,60)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ '{(10,30),(40,60),(70,90)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4multirange (int4range(100, 200), int4range(400, 500));

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

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir @> int4multirange (int4range(10, 20), int4range(30, 40));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir && '{(10,20),(30,40),(50,60)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir <@ '{(10,30),(40,60),(70,90)}'::int4multirange;

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir << int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir >> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &< int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir &> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_range_gist
WHERE
    ir -|- int4multirange (int4range(100, 200), int4range(400, 500));

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

SET enable_seqscan = f;

SELECT
    count(*)
FROM
    test_range_elem
WHERE
    i <@ int4range(10, 50);

-- also test spgist index on anyrange expression
CREATE INDEX ON test_range_elem USING spgist (int4range(i, i + 10));

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    test_range_elem
WHERE
    int4range(i, i + 10) <@ int4range(10, 30);

SELECT
    count(*)
FROM
    test_range_elem
WHERE
    int4range(i, i + 10) <@ int4range(10, 30);

RESET enable_seqscan;

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

-- CREATE TYPE AS RANGE checks for USAGE on subtype
CREATE ROLE regress_subtype;

CREATE TYPE mytype AS (
    a int,
    b int
);

REVOKE USAGE ON TYPE mytype FROM PUBLIC;

SET ROLE regress_subtype;

CREATE TYPE myrange AS RANGE (
    subtype = mytype
);

RESET ROLE;

GRANT USAGE ON TYPE mytype TO regress_subtype;

SET ROLE regress_subtype;

CREATE TYPE myrange AS RANGE (
    subtype = mytype
);

RESET ROLE;

DROP TYPE mytype CASCADE;

DROP ROLE regress_subtype;

--
-- Test user-defined range of floats
-- (type float8range was already made in test_setup.sql)
--
--should fail
CREATE TYPE bogus_float8range AS RANGE (
    subtype = float8,
    subtype_diff = float4mi
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
CREATE FUNCTION anycompatiblearray_anycompatiblerange_func (a anycompatiblearray, r anycompatiblerange)
    RETURNS anycompatible
    AS '
    SELECT
        $1[1] + lower($2);
'
LANGUAGE sql;

SELECT
    anycompatiblearray_anycompatiblerange_func (ARRAY[1, 2], int4range(10, 20));

SELECT
    anycompatiblearray_anycompatiblerange_func (ARRAY[1, 2], numrange(10, 20));

-- should fail
SELECT
    anycompatiblearray_anycompatiblerange_func (ARRAY[1.1, 2], int4range(10, 20));

DROP FUNCTION anycompatiblearray_anycompatiblerange_func (anycompatiblearray, anycompatiblerange);

-- should fail
CREATE FUNCTION bogus_func (anycompatible)
    RETURNS anycompatiblerange
    AS '
    SELECT
        int4range(1, 10);
'
LANGUAGE sql;

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

-- with debug_parallel_query on, this exercises tqueue.c's range remapping
SELECT
    *,
    row_to_json(upper(t)) AS u
FROM (
    VALUES (two_ints_range (ROW (1, 2), ROW (3, 4))),
        (two_ints_range (ROW (5, 6), ROW (7, 8)))) v (t);

-- this must be rejected to avoid self-inclusion issues:
ALTER TYPE two_ints
    ADD attribute c two_ints_range;

DROP TYPE two_ints CASCADE;

--
-- Check behavior when subtype lacks a hash function
--
CREATE TYPE varbitrange AS RANGE (
    subtype = varbit
);

SET enable_groupagg = OFF;

-- try to make it pick a hash setop implementation
SELECT
    '(01,10)'::varbitrange
EXCEPT
SELECT
    '(10,11)'::varbitrange;

RESET enable_groupagg;

--
-- OUT/INOUT/TABLE functions
--
-- infer anyrange from anyrange
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

CREATE FUNCTION outparam2_succeed (r anyrange, out lu anyarray, out ul anyarray)
AS $$
    SELECT
        ARRAY[lower($1), upper($1)],
        ARRAY[upper($1), lower($1)]
$$
LANGUAGE sql;

SELECT
    *
FROM
    outparam2_succeed (int4range(1, 11));

-- infer anyarray from anyrange
CREATE FUNCTION outparam_succeed2 (i anyrange, out r anyarray, out t text)
AS $$
    SELECT
        ARRAY[upper($1)],
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    outparam_succeed2 (int4range(int4range(1, 2)));

-- infer anyelement from anyrange
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

CREATE FUNCTION table_succeed (r anyrange)
    RETURNS TABLE (
        l anyelement,
        u anyelement
    )
    AS $$
    SELECT
        lower($1),
        upper($1)
$$
LANGUAGE sql;

SELECT
    *
FROM
    table_succeed (int4range(1, 11));

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

--
-- Test support functions
--
-- empty range
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange 'empty';

-- unbounded range
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange(NULL, NULL);

-- only lower bound present
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange('2000-01-01', NULL, '[)');

-- only upper bound present
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange(NULL, '2000-01-01', '(]');

-- lower range "-Infinity" excluded
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange('-Infinity', '1997-04-10'::date, '()');

-- lower range "-Infinity" included
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange('-Infinity', '1997-04-10'::date, '[)');

-- upper range "Infinity" excluded
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange('2002-09-25'::date, 'Infinity', '[)');

-- upper range "Infinity" included
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    CURRENT_DATE <@ daterange('2002-09-25'::date, 'Infinity', '[]');

-- should also work if we use "@>"
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    daterange('-Infinity', '1997-04-10'::date, '()') @> CURRENT_DATE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    daterange('2002-09-25'::date, 'Infinity', '[]') @> CURRENT_DATE;

-- Check that volatile cases are not optimized
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    now() <@ tstzrange('2024-01-20 00:00', '2024-01-21 00:00');

EXPLAIN (
    VERBOSE,
    COSTS OFF
) -- unsafe!
SELECT
    clock_timestamp() <@ tstzrange('2024-01-20 00:00', '2024-01-21 00:00');

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    clock_timestamp() <@ tstzrange('2024-01-20 00:00', NULL);

-- test a custom range type with a non-default operator class
CREATE TYPE textrange_supp AS RANGE (
    subtype = text,
    subtype_opclass = text_pattern_ops
);

CREATE temp TABLE text_support_test (
    t text COLLATE "C"
);

INSERT INTO text_support_test
VALUES
    ('a'),
    ('c'),
    ('d'),
    ('ch');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    text_support_test
WHERE
    t <@ textrange_supp ('a', 'd');

SELECT
    *
FROM
    text_support_test
WHERE
    t <@ textrange_supp ('a', 'd');

DROP TABLE text_support_test;

DROP TYPE textrange_supp;

