--
-- ARRAYS
--
CREATE TABLE arrtest (
    a int2[],
    b int4[][][],
    c name[],
    d text[][],
    e float8[],
    f char(5)[],
    g varchar(5)[]
);

--
-- only the 'e' array is 0-based, the others are 1-based.
--
INSERT INTO arrtest (a[1:5], b[1:1][1:2][1:2], c, d, f, g)
    VALUES ('{1,2,3,4,5}', '{{{0,0},{1,2}}}', '{}', '{}', '{}', '{}');

UPDATE
    arrtest
SET
    e[0] = '1.1';

UPDATE
    arrtest
SET
    e[1] = '2.2';

INSERT INTO arrtest (f)
    VALUES ('{"too long"}');

INSERT INTO arrtest (a, b[1:2][1:2], c, d, e, f, g)
    VALUES ('{11,12,23}', '{{3,4},{4,5}}', '{"foobar"}', '{{"elt1", "elt2"}}', '{"3.4", "6.7"}', '{"abc","abcde"}', '{"abc","abcde"}');

INSERT INTO arrtest (a, b[1:2], c, d[1:2])
    VALUES ('{}', '{3,4}', '{foo,bar}', '{bar,foo}');

SELECT
    *
FROM
    arrtest;

SELECT
    arrtest.a[1],
    arrtest.b[1][1][1],
    arrtest.c[1],
    arrtest.d[1][1],
    arrtest.e[0]
FROM
    arrtest;

SELECT
    a[1],
    b[1][1][1],
    c[1],
    d[1][1],
    e[0]
FROM
    arrtest;

SELECT
    a[1:3],
    b[1:1][1:2][1:2],
    c[1:2],
    d[1:1][1:2]
FROM
    arrtest;

SELECT
    array_ndims(a) AS a,
    array_ndims(b) AS b,
    array_ndims(c) AS c
FROM
    arrtest;

SELECT
    array_dims(a) AS a,
    array_dims(b) AS b,
    array_dims(c) AS c
FROM
    arrtest;

-- returns nothing
SELECT
    *
FROM
    arrtest
WHERE
    a[1] < 5
    AND c = '{"foobar"}'::_name;

UPDATE
    arrtest
SET
    a[1:2] = '{16,25}'
WHERE
    NOT a = '{}'::_int2;

UPDATE
    arrtest
SET
    b[1:1][1:1][1:2] = '{113, 117}',
    b[1:1][1:2][2:2] = '{142, 147}'
WHERE
    array_dims(b) = '[1:1][1:2][1:2]';

UPDATE
    arrtest
SET
    c[2:2] = '{"new_word"}'
WHERE
    array_dims(c) IS NOT NULL;

SELECT
    a,
    b,
    c
FROM
    arrtest;

SELECT
    a[1:3],
    b[1:1][1:2][1:2],
    c[1:2],
    d[1:1][2:2]
FROM
    arrtest;

SELECT
    b[1:1][2][2],
    d[1:1][2]
FROM
    arrtest;

INSERT INTO arrtest (a)
    VALUES ('{1,null,3}');

SELECT
    a
FROM
    arrtest;

UPDATE
    arrtest
SET
    a[4] = NULL
WHERE
    a[2] IS NULL;

SELECT
    a
FROM
    arrtest
WHERE
    a[2] IS NULL;

DELETE FROM arrtest
WHERE a[2] IS NULL
    AND b IS NULL;

SELECT
    a,
    b,
    c
FROM
    arrtest;

-- test mixed slice/scalar subscripting
SELECT
    '{{1,2,3},{4,5,6},{7,8,9}}'::int[];

SELECT
    ('{{1,2,3},{4,5,6},{7,8,9}}'::int[])[1:2][2];

SELECT
    '[0:2][0:2]={{1,2,3},{4,5,6},{7,8,9}}'::int[];

SELECT
    ('[0:2][0:2]={{1,2,3},{4,5,6},{7,8,9}}'::int[])[1:2][2];

--
-- check subscription corner cases
--
-- More subscripts than MAXDIMS(6)
SELECT
    ('{}'::int[])[1][2][3][4][5][6][7];

-- NULL index yields NULL when selecting
SELECT
    ('{{{1},{2},{3}},{{4},{5},{6}}}'::int[])[1][NULL][1];

SELECT
    ('{{{1},{2},{3}},{{4},{5},{6}}}'::int[])[1][NULL:1][1];

SELECT
    ('{{{1},{2},{3}},{{4},{5},{6}}}'::int[])[1][1:NULL][1];

-- NULL index in assignment is an error
UPDATE
    arrtest
SET
    c[NULL] = '{"can''t assign"}'
WHERE
    array_dims(c) IS NOT NULL;

UPDATE
    arrtest
SET
    c[NULL:1] = '{"can''t assign"}'
WHERE
    array_dims(c) IS NOT NULL;

UPDATE
    arrtest
SET
    c[1:NULL] = '{"can''t assign"}'
WHERE
    array_dims(c) IS NOT NULL;

-- test slices with empty lower and/or upper index
CREATE TEMP TABLE arrtest_s (
    a int2[],
    b int2[][]
);

INSERT INTO arrtest_s
    VALUES ('{1,2,3,4,5}', '{{1,2,3}, {4,5,6}, {7,8,9}}');

INSERT INTO arrtest_s
    VALUES ('[0:4]={1,2,3,4,5}', '[0:2][0:2]={{1,2,3}, {4,5,6}, {7,8,9}}');

SELECT
    *
FROM
    arrtest_s;

SELECT
    a[:3],
    b[:2][:2]
FROM
    arrtest_s;

SELECT
    a[2:],
    b[2:][2:]
FROM
    arrtest_s;

SELECT
    a[:],
    b[:]
FROM
    arrtest_s;

-- updates
UPDATE
    arrtest_s
SET
    a[:3] = '{11, 12, 13}',
    b[:2][:2] = '{{11,12}, {14,15}}'
WHERE
    array_lower(a, 1) = 1;

SELECT
    *
FROM
    arrtest_s;

UPDATE
    arrtest_s
SET
    a[3:] = '{23, 24, 25}',
    b[2:][2:] = '{{25,26}, {28,29}}';

SELECT
    *
FROM
    arrtest_s;

UPDATE
    arrtest_s
SET
    a[:] = '{11, 12, 13, 14, 15}';

SELECT
    *
FROM
    arrtest_s;

UPDATE
    arrtest_s
SET
    a[:] = '{23, 24, 25}';

-- fail, too small
INSERT INTO arrtest_s
    VALUES (NULL, NULL);

UPDATE
    arrtest_s
SET
    a[:] = '{11, 12, 13, 14, 15}';

-- fail, no good with null
-- check with fixed-length-array type, such as point
SELECT
    f1[0:1]
FROM
    POINT_TBL;

SELECT
    f1[0:]
FROM
    POINT_TBL;

SELECT
    f1[:1]
FROM
    POINT_TBL;

SELECT
    f1[:]
FROM
    POINT_TBL;

-- subscript assignments to fixed-width result in NULL if previous value is NULL
UPDATE
    point_tbl
SET
    f1[0] = 10
WHERE
    f1 IS NULL
RETURNING
    *;

INSERT INTO point_tbl (f1[0])
    VALUES (0)
RETURNING
    *;

-- NULL assignments get ignored
UPDATE
    point_tbl
SET
    f1[0] = NULL
WHERE
    f1::text = '(10,10)'::point::text
RETURNING
    *;

-- but non-NULL subscript assignments work
UPDATE
    point_tbl
SET
    f1[0] = -10,
    f1[1] = -10
WHERE
    f1::text = '(10,10)'::point::text
RETURNING
    *;

-- but not to expand the range
UPDATE
    point_tbl
SET
    f1[3] = 10
WHERE
    f1::text = '(-10,-10)'::point::text
RETURNING
    *;

--
-- test array extension
--
CREATE TEMP TABLE arrtest1 (
    i int[],
    t text[]
);

INSERT INTO arrtest1
    VALUES (ARRAY[1, 2, NULL, 4], ARRAY['one', 'two', NULL, 'four']);

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[2] = 22,
    t[2] = 'twenty-two';

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[5] = 5,
    t[5] = 'five';

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[8] = 8,
    t[8] = 'eight';

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[0] = 0,
    t[0] = 'zero';

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[-3] = -3,
    t[-3] = 'minus-three';

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[0:2] = ARRAY[10, 11, 12],
    t[0:2] = ARRAY['ten', 'eleven', 'twelve'];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[8:10] = ARRAY[18, NULL, 20],
    t[8:10] = ARRAY['p18', NULL, 'p20'];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[11:12] = ARRAY[NULL, 22],
    t[11:12] = ARRAY[NULL, 'p22'];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[15:16] = ARRAY[NULL, 26],
    t[15:16] = ARRAY[NULL, 'p26'];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[- 5: - 3] = ARRAY[-15, -14, -13],
    t[- 5: - 3] = ARRAY['m15', 'm14', 'm13'];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[- 7: - 6] = ARRAY[-17, NULL],
    t[- 7: - 6] = ARRAY['m17', NULL];

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[- 12: - 10] = ARRAY[-22, NULL, -20],
    t[- 12: - 10] = ARRAY['m22', NULL, 'm20'];

SELECT
    *
FROM
    arrtest1;

DELETE FROM arrtest1;

INSERT INTO arrtest1
    VALUES (ARRAY[1, 2, NULL, 4], ARRAY['one', 'two', NULL, 'four']);

SELECT
    *
FROM
    arrtest1;

UPDATE
    arrtest1
SET
    i[0:5] = ARRAY[0, 1, 2, NULL, 4, 5],
    t[0:5] = ARRAY['z', 'p1', 'p2', NULL, 'p4', 'p5'];

SELECT
    *
FROM
    arrtest1;

--
-- array expressions and operators
--
-- table creation and INSERTs
CREATE TEMP TABLE arrtest2 (
    i integer ARRAY[4],
    f float8[],
    n numeric[],
    t text[],
    d timestamp[]
);

INSERT INTO arrtest2
    VALUES (ARRAY[[[113, 142],[1, 147]]], ARRAY[1.1, 1.2, 1.3]::float8[], ARRAY[1.1, 1.2, 1.3], ARRAY[[['aaa', 'aab'],['aba', 'abb'],['aca', 'acb']],[['baa', 'bab'],['bba', 'bbb'],['bca', 'bcb']]], ARRAY['19620326', '19931223', '19970117']::timestamp[]);

-- some more test data
CREATE TEMP TABLE arrtest_f (
    f0 int,
    f1 text,
    f2 float8
);

INSERT INTO arrtest_f
    VALUES (1, 'cat1', 1.21);

INSERT INTO arrtest_f
    VALUES (2, 'cat1', 1.24);

INSERT INTO arrtest_f
    VALUES (3, 'cat1', 1.18);

INSERT INTO arrtest_f
    VALUES (4, 'cat1', 1.26);

INSERT INTO arrtest_f
    VALUES (5, 'cat1', 1.15);

INSERT INTO arrtest_f
    VALUES (6, 'cat2', 1.15);

INSERT INTO arrtest_f
    VALUES (7, 'cat2', 1.26);

INSERT INTO arrtest_f
    VALUES (8, 'cat2', 1.32);

INSERT INTO arrtest_f
    VALUES (9, 'cat2', 1.30);

CREATE TEMP TABLE arrtest_i (
    f0 int,
    f1 text,
    f2 int
);

INSERT INTO arrtest_i
    VALUES (1, 'cat1', 21);

INSERT INTO arrtest_i
    VALUES (2, 'cat1', 24);

INSERT INTO arrtest_i
    VALUES (3, 'cat1', 18);

INSERT INTO arrtest_i
    VALUES (4, 'cat1', 26);

INSERT INTO arrtest_i
    VALUES (5, 'cat1', 15);

INSERT INTO arrtest_i
    VALUES (6, 'cat2', 15);

INSERT INTO arrtest_i
    VALUES (7, 'cat2', 26);

INSERT INTO arrtest_i
    VALUES (8, 'cat2', 32);

INSERT INTO arrtest_i
    VALUES (9, 'cat2', 30);

-- expressions
SELECT
    t.f[1][3][1] AS "131",
    t.f[2][2][1] AS "221"
FROM (
    SELECT
        ARRAY[[[111, 112],[121, 122],[131, 132]],[[211, 212],[221, 122],[231, 232]]] AS f) AS t;

SELECT
    ARRAY[[[[[['hello'],['world']]]]]];

SELECT
    ARRAY[ARRAY['hello'], ARRAY['world']];

SELECT
    ARRAY (
        SELECT
            f2
        FROM
            arrtest_f
        ORDER BY
            f2) AS "ARRAY";

-- with nulls
SELECT
    '{1,null,3}'::int[];

SELECT
    ARRAY[1, NULL, 3];

-- functions
SELECT
    array_append(ARRAY[42], 6) AS "{42,6}";

SELECT
    array_prepend(6, ARRAY[42]) AS "{6,42}";

SELECT
    array_cat(ARRAY[1, 2], ARRAY[3, 4]) AS "{1,2,3,4}";

SELECT
    array_cat(ARRAY[1, 2], ARRAY[[3, 4],[5, 6]]) AS "{{1,2},{3,4},{5,6}}";

SELECT
    array_cat(ARRAY[[3, 4],[5, 6]], ARRAY[1, 2]) AS "{{3,4},{5,6},{1,2}}";

SELECT
    array_position(ARRAY[1, 2, 3, 4, 5], 4);

SELECT
    array_position(ARRAY[5, 3, 4, 2, 1], 4);

SELECT
    array_position(ARRAY[[1, 2],[3, 4]], 3);

SELECT
    array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'], 'mon');

SELECT
    array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'], 'sat');

SELECT
    array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'], NULL);

SELECT
    array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', NULL, 'fri', 'sat'], NULL);

SELECT
    array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', NULL, 'fri', 'sat'], 'sat');

SELECT
    array_positions(NULL, 10);

SELECT
    array_positions(NULL, NULL::int);

SELECT
    array_positions(ARRAY[1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6], 4);

SELECT
    array_positions(ARRAY[[1, 2],[3, 4]], 4);

SELECT
    array_positions(ARRAY[1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6], NULL);

SELECT
    array_positions(ARRAY[1, 2, 3, NULL, 5, 6, 1, 2, 3, NULL, 5, 6], NULL);

SELECT
    array_length(array_positions(ARRAY (
                SELECT
                    'AAAAAAAAAAAAAAAAAAAAAAAAA'::text || i % 10
                FROM generate_series(1, 100) g (i)), 'AAAAAAAAAAAAAAAAAAAAAAAAA5'), 1);

DO $$
DECLARE
    o int;
    a int[] := ARRAY[1, 2, 3, 2, 3, 1, 2];
BEGIN
    o := array_position(a, 2);
    WHILE o IS NOT NULL LOOP
        RAISE NOTICE '%', o;
        o := array_position(a, 2, o + 1);
    END LOOP;
END
$$
LANGUAGE plpgsql;

SELECT
    array_position('[2:4]={1,2,3}'::int[], 1);

SELECT
    array_positions('[2:4]={1,2,3}'::int[], 1);

SELECT
    array_position(ids, (1, 1)),
    array_positions(ids, (1, 1))
FROM (
    VALUES (ARRAY[(0, 0), (1, 1)]),
        (ARRAY[(1, 1)])) AS f (ids);

-- operators
SELECT
    a
FROM
    arrtest
WHERE
    b = ARRAY[[[113, 142],[1, 147]]];

SELECT
    NOT ARRAY[1.1, 1.2, 1.3] = ARRAY[1.1, 1.2, 1.3] AS "FALSE";

SELECT
    ARRAY[1, 2] || 3 AS "{1,2,3}";

SELECT
    0 || ARRAY[1, 2] AS "{0,1,2}";

SELECT
    ARRAY[1, 2] || ARRAY[3, 4] AS "{1,2,3,4}";

SELECT
    ARRAY[[['hello', 'world']]] || ARRAY[[['happy', 'birthday']]] AS "ARRAY";

SELECT
    ARRAY[[1, 2],[3, 4]] || ARRAY[5, 6] AS "{{1,2},{3,4},{5,6}}";

SELECT
    ARRAY[0, 0] || ARRAY[1, 1] || ARRAY[2, 2] AS "{0,0,1,1,2,2}";

SELECT
    0 || ARRAY[1, 2] || 3 AS "{0,1,2,3}";

SELECT
    *
FROM
    array_op_test
WHERE
    i @> '{32}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i && '{32}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i @> '{17}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i && '{17}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i @> '{32,17}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i && '{32,17}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i <@ '{38,34,32,89}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i = '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i @> '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i && '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i <@ '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i = '{NULL}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i @> '{NULL}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i && '{NULL}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    i <@ '{NULL}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t @> '{AAAAAAAA72908}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t && '{AAAAAAAA72908}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t @> '{AAAAAAAAAA646}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t && '{AAAAAAAAAA646}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t @> '{AAAAAAAA72908,AAAAAAAAAA646}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t && '{AAAAAAAA72908,AAAAAAAAAA646}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t <@ '{AAAAAAAA72908,AAAAAAAAAAAAAAAAAAA17075,AA88409,AAAAAAAAAAAAAAAAAA36842,AAAAAAA48038,AAAAAAAAAAAAAA10611}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t = '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t @> '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t && '{}'
ORDER BY
    seqno;

SELECT
    *
FROM
    array_op_test
WHERE
    t <@ '{}'
ORDER BY
    seqno;

-- array casts
SELECT
    ARRAY[1, 2, 3]::text[]::int[]::float8[] AS "{1,2,3}";

SELECT
    ARRAY[1, 2, 3]::text[]::int[]::float8[] IS OF (float8[]) AS "TRUE";

SELECT
    ARRAY[['a', 'bc'],['def', 'hijk']]::text[]::varchar[] AS "{{a,bc},{def,hijk}}";

SELECT
    ARRAY[['a', 'bc'],['def', 'hijk']]::text[]::varchar[] IS OF (varchar[]) AS "TRUE";

SELECT
    CAST(ARRAY[[[[[['a', 'bb', 'ccc']]]]]] AS text[]) AS "{{{{{{a,bb,ccc}}}}}}";

SELECT
    NULL::text[]::int[] AS "NULL";

-- scalar op any/all (array)
SELECT
    33 = ANY ('{1,2,3}');

SELECT
    33 = ANY ('{1,2,33}');

SELECT
    33 = ALL ('{1,2,33}');

SELECT
    33 >= ALL ('{1,2,33}');

-- boundary cases
SELECT
    NULL::int >= ALL ('{1,2,33}');

SELECT
    NULL::int >= ALL ('{}');

SELECT
    NULL::int >= ANY ('{}');

-- cross-datatype
SELECT
    33.4 = ANY (ARRAY[1, 2, 3]);

SELECT
    33.4 > ALL (ARRAY[1, 2, 3]);

-- errors
SELECT
    33 * ANY ('{1,2,3}');

SELECT
    33 * ANY (44);

-- nulls
SELECT
    33 = ANY (NULL::int[]);

SELECT
    NULL::int = ANY ('{1,2,3}');

SELECT
    33 = ANY ('{1,null,3}');

SELECT
    33 = ANY ('{1,null,33}');

SELECT
    33 = ALL (NULL::int[]);

SELECT
    NULL::int = ALL ('{1,2,3}');

SELECT
    33 = ALL ('{1,null,3}');

SELECT
    33 = ALL ('{33,null,33}');

-- nulls later in the bitmap
SELECT
    -1 != ALL (ARRAY (
            SELECT
                NULLIF (g.i, 900)
            FROM
                generate_series(1, 1000) g (i)));

-- test indexes on arrays
CREATE temp TABLE arr_tbl (
    f1 int[] UNIQUE
);

INSERT INTO arr_tbl
    VALUES ('{1,2,3}');

INSERT INTO arr_tbl
    VALUES ('{1,2}');

-- failure expected:
INSERT INTO arr_tbl
    VALUES ('{1,2,3}');

INSERT INTO arr_tbl
    VALUES ('{2,3,4}');

INSERT INTO arr_tbl
    VALUES ('{1,5,3}');

INSERT INTO arr_tbl
    VALUES ('{1,2,10}');

SET enable_seqscan TO OFF;

SET enable_bitmapscan TO OFF;

SELECT
    *
FROM
    arr_tbl
WHERE
    f1 > '{1,2,3}'
    AND f1 <= '{1,5,3}';

SELECT
    *
FROM
    arr_tbl
WHERE
    f1 >= '{1,2,3}'
    AND f1 < '{1,5,3}';

-- test ON CONFLICT DO UPDATE with arrays
CREATE temp TABLE arr_pk_tbl (
    pk int4 PRIMARY KEY,
    f1 int[]
);

INSERT INTO arr_pk_tbl
    VALUES (1, '{1,2,3}');

INSERT INTO arr_pk_tbl
    VALUES (1, '{3,4,5}')
ON CONFLICT (pk)
    DO UPDATE SET
        f1[1] = excluded.f1[1],
        f1[3] = excluded.f1[3]
    RETURNING
        pk,
        f1;

INSERT INTO arr_pk_tbl (pk, f1[1:2])
    VALUES (1, '{6,7,8}')
ON CONFLICT (pk)
    DO UPDATE SET
        f1[1] = excluded.f1[1],
        f1[2] = excluded.f1[2],
        f1[3] = excluded.f1[3]
    RETURNING
        pk,
        f1;

-- note: if above selects don't produce the expected tuple order,
-- then you didn't get an indexscan plan, and something is busted.
RESET enable_seqscan;

RESET enable_bitmapscan;

-- test [not] (like|ilike) (any|all) (...)
SELECT
    'foo' LIKE ANY (ARRAY['%a', '%o']);

-- t
SELECT
    'foo' LIKE ANY (ARRAY['%a', '%b']);

-- f
SELECT
    'foo' LIKE ALL (ARRAY['f%', '%o']);

-- t
SELECT
    'foo' LIKE ALL (ARRAY['f%', '%b']);

-- f
SELECT
    'foo' NOT LIKE ANY (ARRAY['%a', '%b']);

-- t
SELECT
    'foo' NOT LIKE ALL (ARRAY['%a', '%o']);

-- f
SELECT
    'foo' ILIKE ANY (ARRAY['%A', '%O']);

-- t
SELECT
    'foo' ILIKE ALL (ARRAY['F%', '%O']);

-- t
--
-- General array parser tests
--
-- none of the following should be accepted
SELECT
    '{{1,{2}},{2,3}}'::text[];

SELECT
    '{{},{}}'::text[];

SELECT
    E'{{1,2},\\{2,3}}'::text[];

SELECT
    '{{"1 2" x},{3}}'::text[];

SELECT
    '{}}'::text[];

SELECT
    '{ }}'::text[];

SELECT
    ARRAY[];

-- none of the above should be accepted
-- all of the following should be accepted
SELECT
    '{}'::text[];

SELECT
    '{{{1,2,3,4},{2,3,4,5}},{{3,4,5,6},{4,5,6,7}}}'::text[];

SELECT
    '{0 second  ,0 second}'::interval[];

SELECT
    '{ { "," } , { 3 } }'::text[];

SELECT
    '  {   {  "  0 second  "   ,  0 second  }   }'::text[];

SELECT
    '{
           0 second,
           @ 1 hour @ 42 minutes @ 20 seconds
         }'::interval[];

SELECT
    ARRAY[]::text[];

SELECT
    '[0:1]={1.1,2.2}'::float8[];

-- all of the above should be accepted
-- tests for array aggregates
CREATE TEMP TABLE arraggtest (
    f1 int[],
    f2 text[][],
    f3 float[]
);

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{1,2,3,4}', '{{grey,red},{blue,blue}}', '{1.6, 0.0}');

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{1,2,3}', '{{grey,red},{grey,blue}}', '{1.6}');

SELECT
    max(f1),
    min(f1),
    max(f2),
    min(f2),
    max(f3),
    min(f3)
FROM
    arraggtest;

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{3,3,2,4,5,6}', '{{white,yellow},{pink,orange}}', '{2.1,3.3,1.8,1.7,1.6}');

SELECT
    max(f1),
    min(f1),
    max(f2),
    min(f2),
    max(f3),
    min(f3)
FROM
    arraggtest;

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{2}', '{{black,red},{green,orange}}', '{1.6,2.2,2.6,0.4}');

SELECT
    max(f1),
    min(f1),
    max(f2),
    min(f2),
    max(f3),
    min(f3)
FROM
    arraggtest;

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{4,2,6,7,8,1}', '{{red},{black},{purple},{blue},{blue}}', NULL);

SELECT
    max(f1),
    min(f1),
    max(f2),
    min(f2),
    max(f3),
    min(f3)
FROM
    arraggtest;

INSERT INTO arraggtest (f1, f2, f3)
    VALUES ('{}', '{{pink,white,blue,red,grey,orange}}', '{2.1,1.87,1.4,2.2}');

SELECT
    max(f1),
    min(f1),
    max(f2),
    min(f2),
    max(f3),
    min(f3)
FROM
    arraggtest;

-- A few simple tests for arrays of composite types
CREATE TYPE comptype AS (
    f1 int,
    f2 text
);

CREATE TABLE comptable (
    c1 comptype,
    c2 comptype[]
);

-- XXX would like to not have to specify row() construct types here ...
INSERT INTO comptable
    VALUES (ROW (1, 'foo'), ARRAY[ROW (2, 'bar')::comptype, ROW (3, 'baz')::comptype]);

-- check that implicitly named array type _comptype isn't a problem
CREATE TYPE _comptype AS enum (
    'fooey'
);

SELECT
    *
FROM
    comptable;

SELECT
    c2[2].f2
FROM
    comptable;

DROP TYPE _comptype;

DROP TABLE comptable;

DROP TYPE comptype;

CREATE OR REPLACE FUNCTION unnest1 (anyarray)
    RETURNS SETOF anyelement
    AS $$
    SELECT
        $1[s]
    FROM
        generate_subscripts($1, 1) g (s);
$$
LANGUAGE sql
IMMUTABLE;

CREATE OR REPLACE FUNCTION unnest2 (anyarray)
    RETURNS SETOF anyelement
    AS $$
    SELECT
        $1[s1][s2]
    FROM
        generate_subscripts($1, 1) g1 (s1),
    generate_subscripts($1, 2) g2 (s2);
$$
LANGUAGE sql
IMMUTABLE;

SELECT
    *
FROM
    unnest1 (ARRAY[1, 2, 3]);

SELECT
    *
FROM
    unnest2 (ARRAY[[1, 2, 3],[4, 5, 6]]);

DROP FUNCTION unnest1 (anyarray);

DROP FUNCTION unnest2 (anyarray);

SELECT
    array_fill(NULL::integer, ARRAY[3, 3], ARRAY[2, 2]);

SELECT
    array_fill(NULL::integer, ARRAY[3, 3]);

SELECT
    array_fill(NULL::text, ARRAY[3, 3], ARRAY[2, 2]);

SELECT
    array_fill(NULL::text, ARRAY[3, 3]);

SELECT
    array_fill(7, ARRAY[3, 3], ARRAY[2, 2]);

SELECT
    array_fill(7, ARRAY[3, 3]);

SELECT
    array_fill('juhu'::text, ARRAY[3, 3], ARRAY[2, 2]);

SELECT
    array_fill('juhu'::text, ARRAY[3, 3]);

SELECT
    a,
    a = '{}' AS is_eq,
    array_dims(a)
FROM (
    SELECT
        array_fill(42, ARRAY[0]) AS a) ss;

SELECT
    a,
    a = '{}' AS is_eq,
    array_dims(a)
FROM (
    SELECT
        array_fill(42, '{}') AS a) ss;

SELECT
    a,
    a = '{}' AS is_eq,
    array_dims(a)
FROM (
    SELECT
        array_fill(42, '{}', '{}') AS a) ss;

-- raise exception
SELECT
    array_fill(1, NULL, ARRAY[2, 2]);

SELECT
    array_fill(1, ARRAY[2, 2], NULL);

SELECT
    array_fill(1, ARRAY[2, 2], '{}');

SELECT
    array_fill(1, ARRAY[3, 3], ARRAY[1, 1, 1]);

SELECT
    array_fill(1, ARRAY[1, 2, NULL]);

SELECT
    array_fill(1, ARRAY[[1, 2],[3, 4]]);

SELECT
    string_to_array('1|2|3', '|');

SELECT
    string_to_array('1|2|3|', '|');

SELECT
    string_to_array('1||2|3||', '||');

SELECT
    string_to_array('1|2|3', '');

SELECT
    string_to_array('', '|');

SELECT
    string_to_array('1|2|3', NULL);

SELECT
    string_to_array(NULL, '|') IS NULL;

SELECT
    string_to_array('abc', '');

SELECT
    string_to_array('abc', '', 'abc');

SELECT
    string_to_array('abc', ',');

SELECT
    string_to_array('abc', ',', 'abc');

SELECT
    string_to_array('1,2,3,4,,6', ',');

SELECT
    string_to_array('1,2,3,4,,6', ',', '');

SELECT
    string_to_array('1,2,3,4,*,6', ',', '*');

SELECT
    array_to_string(NULL::int4[], ',') IS NULL;

SELECT
    array_to_string('{}'::int4[], ',');

SELECT
    array_to_string(ARRAY[1, 2, 3, 4, NULL, 6], ',');

SELECT
    array_to_string(ARRAY[1, 2, 3, 4, NULL, 6], ',', '*');

SELECT
    array_to_string(ARRAY[1, 2, 3, 4, NULL, 6], NULL);

SELECT
    array_to_string(ARRAY[1, 2, 3, 4, NULL, 6], ',', NULL);

SELECT
    array_to_string(string_to_array('1|2|3', '|'), '|');

SELECT
    array_length(ARRAY[1, 2, 3], 1);

SELECT
    array_length(ARRAY[[1, 2, 3],[4, 5, 6]], 0);

SELECT
    array_length(ARRAY[[1, 2, 3],[4, 5, 6]], 1);

SELECT
    array_length(ARRAY[[1, 2, 3],[4, 5, 6]], 2);

SELECT
    array_length(ARRAY[[1, 2, 3],[4, 5, 6]], 3);

SELECT
    cardinality(NULL::int[]);

SELECT
    cardinality('{}'::int[]);

SELECT
    cardinality(ARRAY[1, 2, 3]);

SELECT
    cardinality('[2:4]={5,6,7}'::int[]);

SELECT
    cardinality('{{1,2}}'::int[]);

SELECT
    cardinality('{{1,2},{3,4},{5,6}}'::int[]);

SELECT
    cardinality('{{{1,9},{5,6}},{{2,3},{3,4}}}'::int[]);

-- array_agg(anynonarray)
SELECT
    array_agg(unique1)
FROM (
    SELECT
        unique1
    FROM
        tenk1
    WHERE
        unique1 < 15
    ORDER BY
        unique1) ss;

SELECT
    array_agg(ten)
FROM (
    SELECT
        ten
    FROM
        tenk1
    WHERE
        unique1 < 15
    ORDER BY
        unique1) ss;

SELECT
    array_agg(nullif (ten, 4))
FROM (
    SELECT
        ten
    FROM
        tenk1
    WHERE
        unique1 < 15
    ORDER BY
        unique1) ss;

SELECT
    array_agg(unique1)
FROM
    tenk1
WHERE
    unique1 < - 15;

-- array_agg(anyarray)
SELECT
    array_agg(ar)
FROM (
    VALUES ('{1,2}'::int[]),
        ('{3,4}'::int[])) v (ar);

SELECT
    array_agg(DISTINCT ar ORDER BY ar DESC)
FROM (
    SELECT
        ARRAY[i / 2]
    FROM
        generate_series(1, 10) a (i)) b (ar);

SELECT
    array_agg(ar)
FROM (
    SELECT
        array_agg(ARRAY[i, i + 1, i - 1])
    FROM
        generate_series(1, 2) a (i)) b (ar);

SELECT
    array_agg(ARRAY[i + 1.2, i + 1.3, i + 1.4])
FROM
    generate_series(1, 3) g (i);

SELECT
    array_agg(ARRAY['Hello', i::text])
FROM
    generate_series(9, 11) g (i);

SELECT
    array_agg(ARRAY[i, nullif (i, 3), i + 1])
FROM
    generate_series(1, 4) g (i);

-- errors
SELECT
    array_agg('{}'::int[])
FROM
    generate_series(1, 2);

SELECT
    array_agg(NULL::int[])
FROM
    generate_series(1, 2);

SELECT
    array_agg(ar)
FROM (
    VALUES ('{1,2}'::int[]),
        ('{3}'::int[])) v (ar);

SELECT
    unnest(ARRAY[1, 2, 3]);

SELECT
    *
FROM
    unnest(ARRAY[1, 2, 3]);

SELECT
    unnest(ARRAY[1, 2, 3, 4.5]::float8[]);

SELECT
    unnest(ARRAY[1, 2, 3, 4.5]::numeric[]);

SELECT
    unnest(ARRAY[1, 2, 3, NULL, 4, NULL, NULL, 5, 6]);

SELECT
    unnest(ARRAY[1, 2, 3, NULL, 4, NULL, NULL, 5, 6]::text[]);

SELECT
    abs(unnest(ARRAY[1, 2, NULL, -3]));

SELECT
    array_remove(ARRAY[1, 2, 2, 3], 2);

SELECT
    array_remove(ARRAY[1, 2, 2, 3], 5);

SELECT
    array_remove(ARRAY[1, NULL, NULL, 3], NULL);

SELECT
    array_remove(ARRAY['A', 'CC', 'D', 'C', 'RR'], 'RR');

SELECT
    array_remove('{{1,2,2},{1,4,3}}', 2);

-- not allowed
SELECT
    array_remove(ARRAY['X', 'X', 'X'], 'X') = '{}';

SELECT
    array_replace(ARRAY[1, 2, 5, 4], 5, 3);

SELECT
    array_replace(ARRAY[1, 2, 5, 4], 5, NULL);

SELECT
    array_replace(ARRAY[1, 2, NULL, 4, NULL], NULL, 5);

SELECT
    array_replace(ARRAY['A', 'B', 'DD', 'B'], 'B', 'CC');

SELECT
    array_replace(ARRAY[1, NULL, 3], NULL, NULL);

SELECT
    array_replace(ARRAY['AB', NULL, 'CDE'], NULL, '12');

-- array(select array-value ...)
SELECT
    ARRAY (
        SELECT
            ARRAY[i, i / 2]
        FROM
            generate_series(1, 5) i);

SELECT
    ARRAY (
        SELECT
            ARRAY['Hello', i::text]
        FROM
            generate_series(9, 11) i);

-- Insert/update on a column that is array of composite
CREATE temp TABLE t1 (
    f1 int8_tbl[]
);

INSERT INTO t1 (f1[5].q1)
    VALUES (42);

SELECT
    *
FROM
    t1;

UPDATE
    t1
SET
    f1[5].q2 = 43;

SELECT
    *
FROM
    t1;

-- Check that arrays of composites are safely detoasted when needed
CREATE temp TABLE src (
    f1 text
);

INSERT INTO src
SELECT
    string_agg(random()::text, '')
FROM
    generate_series(1, 10000);

CREATE TYPE textandtext AS (
    c1 text,
    c2 text
);

CREATE temp TABLE dest (
    f1 textandtext[]
);

INSERT INTO dest
SELECT
    ARRAY[ROW (f1, f1)::textandtext]
FROM
    src;

SELECT
    length(md5((f1[1]).c2))
FROM
    dest;

DELETE FROM src;

SELECT
    length(md5((f1[1]).c2))
FROM
    dest;

TRUNCATE TABLE src;

DROP TABLE src;

SELECT
    length(md5((f1[1]).c2))
FROM
    dest;

DROP TABLE dest;

DROP TYPE textandtext;

-- Tests for polymorphic-array form of width_bucket()
-- this exercises the varwidth and float8 code paths
SELECT
    op,
    width_bucket(op::numeric, ARRAY[1, 3, 5, 10.0]::numeric[]) AS wb_n1,
    width_bucket(op::numeric, ARRAY[0, 5.5, 9.99]::numeric[]) AS wb_n2,
    width_bucket(op::numeric, ARRAY[-6, -5, 2.0]::numeric[]) AS wb_n3,
    width_bucket(op::float8, ARRAY[1, 3, 5, 10.0]::float8[]) AS wb_f1,
    width_bucket(op::float8, ARRAY[0, 5.5, 9.99]::float8[]) AS wb_f2,
    width_bucket(op::float8, ARRAY[-6, -5, 2.0]::float8[]) AS wb_f3
FROM (
    VALUES (-5.2),
        (-0.0000000001),
        (0.000000000001),
        (1),
        (1.99999999999999),
        (2),
        (2.00000000000001),
        (3),
        (4),
        (4.5),
        (5),
        (5.5),
        (6),
        (7),
        (8),
        (9),
        (9.99999999999999),
        (10),
        (10.0000000000001)) v (op);

-- ensure float8 path handles NaN properly
SELECT
    op,
    width_bucket(op, ARRAY[1, 3, 9, 'NaN', 'NaN']::float8[]) AS wb
FROM (
    VALUES (-5.2::float8),
        (4::float8),
        (77::float8),
        ('NaN'::float8)) v (op);

-- these exercise the generic fixed-width code path
SELECT
    op,
    width_bucket(op, ARRAY[1, 3, 5, 10]) AS wb_1
FROM
    generate_series(0, 11) AS op;

SELECT
    width_bucket(now(), ARRAY['yesterday', 'today', 'tomorrow']::timestamptz[]);

-- corner cases
SELECT
    width_bucket(5, ARRAY[3]);

SELECT
    width_bucket(5, '{}');

-- error cases
SELECT
    width_bucket('5'::text, ARRAY[3, 4]::integer[]);

SELECT
    width_bucket(5, ARRAY[3, 4, NULL]);

SELECT
    width_bucket(5, ARRAY[ARRAY[1, 2], ARRAY[3, 4]]);

