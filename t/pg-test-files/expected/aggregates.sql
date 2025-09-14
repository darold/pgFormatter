--
-- AGGREGATES
--
-- avoid bit-exact output here because operations may not be bit-exact.
SET extra_float_digits = 0;

SELECT
    avg(four) AS avg_1
FROM
    onek;

SELECT
    avg(a) AS avg_32
FROM
    aggtest
WHERE
    a < 100;

-- In 7.1, avg(float4) is computed using float8 arithmetic.
-- Round the result to 3 digits to avoid platform-specific results.
SELECT
    avg(b)::numeric(10, 3) AS avg_107_943
FROM
    aggtest;

SELECT
    avg(gpa) AS avg_3_4
FROM
    ONLY student;

SELECT
    sum(four) AS sum_1500
FROM
    onek;

SELECT
    sum(a) AS sum_198
FROM
    aggtest;

SELECT
    sum(b) AS avg_431_773
FROM
    aggtest;

SELECT
    sum(gpa) AS avg_6_8
FROM
    ONLY student;

SELECT
    max(four) AS max_3
FROM
    onek;

SELECT
    max(a) AS max_100
FROM
    aggtest;

SELECT
    max(aggtest.b) AS max_324_78
FROM
    aggtest;

SELECT
    max(student.gpa) AS max_3_7
FROM
    student;

SELECT
    stddev_pop(b)
FROM
    aggtest;

SELECT
    stddev_samp(b)
FROM
    aggtest;

SELECT
    var_pop(b)
FROM
    aggtest;

SELECT
    var_samp(b)
FROM
    aggtest;

SELECT
    stddev_pop(b::numeric)
FROM
    aggtest;

SELECT
    stddev_samp(b::numeric)
FROM
    aggtest;

SELECT
    var_pop(b::numeric)
FROM
    aggtest;

SELECT
    var_samp(b::numeric)
FROM
    aggtest;

-- population variance is defined for a single tuple, sample variance
-- is not
SELECT
    var_pop(1.0),
    var_samp(2.0);

SELECT
    stddev_pop(3.0::numeric),
    stddev_samp(4.0::numeric);

-- verify correct results for null and NaN inputs
SELECT
    sum(NULL::int4)
FROM
    generate_series(1, 3);

SELECT
    sum(NULL::int8)
FROM
    generate_series(1, 3);

SELECT
    sum(NULL::numeric)
FROM
    generate_series(1, 3);

SELECT
    sum(NULL::float8)
FROM
    generate_series(1, 3);

SELECT
    avg(NULL::int4)
FROM
    generate_series(1, 3);

SELECT
    avg(NULL::int8)
FROM
    generate_series(1, 3);

SELECT
    avg(NULL::numeric)
FROM
    generate_series(1, 3);

SELECT
    avg(NULL::float8)
FROM
    generate_series(1, 3);

SELECT
    sum('NaN'::numeric)
FROM
    generate_series(1, 3);

SELECT
    avg('NaN'::numeric)
FROM
    generate_series(1, 3);

-- verify correct results for infinite inputs
SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('1'),
        ('infinity')) v (x);

SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('infinity'),
        ('1')) v (x);

SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('infinity'),
        ('infinity')) v (x);

SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('-infinity'),
        ('infinity')) v (x);

-- test accuracy with a large input offset
SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES (100000003),
        (100000004),
        (100000006),
        (100000007)) v (x);

SELECT
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES (7000000000005),
        (7000000000007)) v (x);

-- SQL2003 binary aggregates
SELECT
    regr_count(b, a)
FROM
    aggtest;

SELECT
    regr_sxx(b, a)
FROM
    aggtest;

SELECT
    regr_syy(b, a)
FROM
    aggtest;

SELECT
    regr_sxy(b, a)
FROM
    aggtest;

SELECT
    regr_avgx(b, a),
    regr_avgy(b, a)
FROM
    aggtest;

SELECT
    regr_r2(b, a)
FROM
    aggtest;

SELECT
    regr_slope(b, a),
    regr_intercept(b, a)
FROM
    aggtest;

SELECT
    covar_pop(b, a),
    covar_samp(b, a)
FROM
    aggtest;

SELECT
    corr(b, a)
FROM
    aggtest;

-- test accum and combine functions directly
CREATE TABLE regr_test (
    x float8,
    y float8
);

INSERT INTO regr_test
VALUES
    (10, 150),
    (20, 250),
    (30, 350),
    (80, 540),
    (100, 200);

SELECT
    count(*),
    sum(x),
    regr_sxx(y, x),
    sum(y),
    regr_syy(y, x),
    regr_sxy(y, x)
FROM
    regr_test
WHERE
    x IN (10, 20, 30, 80);

SELECT
    count(*),
    sum(x),
    regr_sxx(y, x),
    sum(y),
    regr_syy(y, x),
    regr_sxy(y, x)
FROM
    regr_test;

SELECT
    float8_accum('{4,140,2900}'::float8[], 100);

SELECT
    float8_regr_accum('{4,140,2900,1290,83075,15050}'::float8[], 200, 100);

SELECT
    count(*),
    sum(x),
    regr_sxx(y, x),
    sum(y),
    regr_syy(y, x),
    regr_sxy(y, x)
FROM
    regr_test
WHERE
    x IN (10, 20, 30);

SELECT
    count(*),
    sum(x),
    regr_sxx(y, x),
    sum(y),
    regr_syy(y, x),
    regr_sxy(y, x)
FROM
    regr_test
WHERE
    x IN (80, 100);

SELECT
    float8_combine('{3,60,200}'::float8[], '{0,0,0}'::float8[]);

SELECT
    float8_combine('{0,0,0}'::float8[], '{2,180,200}'::float8[]);

SELECT
    float8_combine('{3,60,200}'::float8[], '{2,180,200}'::float8[]);

SELECT
    float8_regr_combine('{3,60,200,750,20000,2000}'::float8[], '{0,0,0,0,0,0}'::float8[]);

SELECT
    float8_regr_combine('{0,0,0,0,0,0}'::float8[], '{2,180,200,740,57800,-3400}'::float8[]);

SELECT
    float8_regr_combine('{3,60,200,750,20000,2000}'::float8[], '{2,180,200,740,57800,-3400}'::float8[]);

DROP TABLE regr_test;

-- test count, distinct
SELECT
    count(four) AS cnt_1000
FROM
    onek;

SELECT
    count(DISTINCT four) AS cnt_4
FROM
    onek;

SELECT
    ten,
    count(*),
    sum(four)
FROM
    onek
GROUP BY
    ten
ORDER BY
    ten;

SELECT
    ten,
    count(four),
    sum(DISTINCT four)
FROM
    onek
GROUP BY
    ten
ORDER BY
    ten;

-- user-defined aggregates
SELECT
    newavg (four) AS avg_1
FROM
    onek;

SELECT
    newsum (four) AS sum_1500
FROM
    onek;

SELECT
    newcnt (four) AS cnt_1000
FROM
    onek;

SELECT
    newcnt (*) AS cnt_1000
FROM
    onek;

SELECT
    oldcnt (*) AS cnt_1000
FROM
    onek;

SELECT
    sum2 (q1, q2)
FROM
    int8_tbl;

-- test for outer-level aggregates
-- this should work
SELECT
    ten,
    sum(DISTINCT four)
FROM
    onek a
GROUP BY
    ten
HAVING
    EXISTS (
        SELECT
            1
        FROM
            onek b
        WHERE
            sum(DISTINCT a.four) = b.four);

-- this should fail because subquery has an agg of its own in WHERE
SELECT
    ten,
    sum(DISTINCT four)
FROM
    onek a
GROUP BY
    ten
HAVING
    EXISTS (
        SELECT
            1
        FROM
            onek b
        WHERE
            sum(DISTINCT a.four + b.four) = b.four);

-- Test handling of sublinks within outer-level aggregates.
-- Per bug report from Daniel Grace.
SELECT
    (
        SELECT
            max(
                SELECT
                    i.unique2
                FROM tenk1 i
                WHERE
                    i.unique1 = o.unique1))
FROM
    tenk1 o;

-- Test handling of Params within aggregate arguments in hashed aggregation.
-- Per bug report from Jeevan Chalke.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    s1,
    s2,
    sm
FROM
    generate_series(1, 3) s1,
    LATERAL (
        SELECT
            s2,
            sum(s1 + s2) sm
        FROM
            generate_series(1, 3) s2
        GROUP BY
            s2) ss
ORDER BY
    1,
    2;

SELECT
    s1,
    s2,
    sm
FROM
    generate_series(1, 3) s1,
    LATERAL (
        SELECT
            s2,
            sum(s1 + s2) sm
        FROM
            generate_series(1, 3) s2
        GROUP BY
            s2) ss
ORDER BY
    1,
    2;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ARRAY (
        SELECT
            sum(x + y) s
        FROM
            generate_series(1, 3) y
        GROUP BY
            y
        ORDER BY
            s)
FROM
    generate_series(1, 3) x;

SELECT
    ARRAY (
        SELECT
            sum(x + y) s
        FROM
            generate_series(1, 3) y
        GROUP BY
            y
        ORDER BY
            s)
FROM
    generate_series(1, 3) x;

--
-- test for bitwise integer aggregates
--
CREATE TEMPORARY TABLE bitwise_test (
    i2 int2,
    i4 int4,
    i8 int8,
    i integer,
    x int2,
    y bit(4)
);

-- empty case
SELECT
    BIT_AND(i2) AS "?",
    BIT_OR(i4) AS "?"
FROM
    bitwise_test;

SELECT
    BIT_AND(i2) AS "1",
    BIT_AND(i4) AS "1",
    BIT_AND(i8) AS "1",
    BIT_AND(i) AS "?",
    BIT_AND(x) AS "0",
    BIT_AND(y) AS "0100",
    BIT_OR(i2) AS "7",
    BIT_OR(i4) AS "7",
    BIT_OR(i8) AS "7",
    BIT_OR(i) AS "?",
    BIT_OR(x) AS "7",
    BIT_OR(y) AS "1101"
FROM
    bitwise_test;

--
-- test boolean aggregates
--
-- first test all possible transition and final states
SELECT
    -- boolean and transitions
    -- null because strict
    booland_statefunc(NULL, NULL) IS NULL AS "t",
    booland_statefunc(TRUE, NULL) IS NULL AS "t",
    booland_statefunc(FALSE, NULL) IS NULL AS "t",
    booland_statefunc(NULL, TRUE) IS NULL AS "t",
    booland_statefunc(NULL, FALSE) IS NULL AS "t",
    -- and actual computations
    booland_statefunc(TRUE, TRUE) AS "t",
    NOT booland_statefunc(TRUE, FALSE) AS "t",
    NOT booland_statefunc(FALSE, TRUE) AS "t",
    NOT booland_statefunc(FALSE, FALSE) AS "t";

SELECT
    -- boolean or transitions
    -- null because strict
    boolor_statefunc(NULL, NULL) IS NULL AS "t",
    boolor_statefunc(TRUE, NULL) IS NULL AS "t",
    boolor_statefunc(FALSE, NULL) IS NULL AS "t",
    boolor_statefunc(NULL, TRUE) IS NULL AS "t",
    boolor_statefunc(NULL, FALSE) IS NULL AS "t",
    -- actual computations
    boolor_statefunc(TRUE, TRUE) AS "t",
    boolor_statefunc(TRUE, FALSE) AS "t",
    boolor_statefunc(FALSE, TRUE) AS "t",
    NOT boolor_statefunc(FALSE, FALSE) AS "t";

CREATE TEMPORARY TABLE bool_test (
    b1 bool,
    b2 bool,
    b3 bool,
    b4 bool
);

-- empty case
SELECT
    BOOL_AND(b1) AS "n",
    BOOL_OR(b3) AS "n"
FROM
    bool_test;

SELECT
    BOOL_AND(b1) AS "f",
    BOOL_AND(b2) AS "t",
    BOOL_AND(b3) AS "f",
    BOOL_AND(b4) AS "n",
    BOOL_AND(NOT b2) AS "f",
    BOOL_AND(NOT b3) AS "t"
FROM
    bool_test;

SELECT
    EVERY(b1) AS "f",
    EVERY(b2) AS "t",
    EVERY(b3) AS "f",
    EVERY(b4) AS "n",
    EVERY(NOT b2) AS "f",
    EVERY(NOT b3) AS "t"
FROM
    bool_test;

SELECT
    BOOL_OR(b1) AS "t",
    BOOL_OR(b2) AS "t",
    BOOL_OR(b3) AS "f",
    BOOL_OR(b4) AS "n",
    BOOL_OR(NOT b2) AS "f",
    BOOL_OR(NOT b3) AS "t"
FROM
    bool_test;

--
-- Test cases that should be optimized into indexscans instead of
-- the generic aggregate implementation.
--
-- Basic cases
EXPLAIN (
    COSTS OFF
)
SELECT
    min(unique1)
FROM
    tenk1;

SELECT
    min(unique1)
FROM
    tenk1;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique1)
FROM
    tenk1;

SELECT
    max(unique1)
FROM
    tenk1;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 < 42;

SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 < 42;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 > 42;

SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 > 42;

-- the planner may choose a generic aggregate here if parallel query is
-- enabled, since that plan will be parallel safe and the "optimized"
-- plan, which has almost identical cost, will not be.  we want to test
-- the optimized plan, so temporarily disable parallel query.
BEGIN;
SET local max_parallel_workers_per_gather = 0;
EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 > 42000;
SELECT
    max(unique1)
FROM
    tenk1
WHERE
    unique1 > 42000;
ROLLBACK;

-- multi-column index (uses tenk1_thous_tenthous)
EXPLAIN (
    COSTS OFF
)
SELECT
    max(tenthous)
FROM
    tenk1
WHERE
    thousand = 33;

SELECT
    max(tenthous)
FROM
    tenk1
WHERE
    thousand = 33;

EXPLAIN (
    COSTS OFF
)
SELECT
    min(tenthous)
FROM
    tenk1
WHERE
    thousand = 33;

SELECT
    min(tenthous)
FROM
    tenk1
WHERE
    thousand = 33;

-- check parameter propagation into an indexscan subquery
EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    (
        SELECT
            min(unique1)
        FROM
            tenk1
        WHERE
            unique1 > f1) AS gt
FROM
    int4_tbl;

SELECT
    f1,
    (
        SELECT
            min(unique1)
        FROM
            tenk1
        WHERE
            unique1 > f1) AS gt
FROM
    int4_tbl;

-- check some cases that were handled incorrectly in 8.3.0
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    max(unique2)
FROM
    tenk1;

SELECT DISTINCT
    max(unique2)
FROM
    tenk1;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    1;

SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    max(unique2);

SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    max(unique2);

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    max(unique2) + 1;

SELECT
    max(unique2)
FROM
    tenk1
ORDER BY
    max(unique2) + 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    max(unique2),
    generate_series(1, 3) AS g
FROM
    tenk1
ORDER BY
    g DESC;

SELECT
    max(unique2),
    generate_series(1, 3) AS g
FROM
    tenk1
ORDER BY
    g DESC;

-- interesting corner case: constant gets optimized into a seqscan
EXPLAIN (
    COSTS OFF
)
SELECT
    max(100)
FROM
    tenk1;

SELECT
    max(100)
FROM
    tenk1;

-- try it on an inheritance tree
CREATE TABLE minmaxtest (
    f1 int
);

CREATE TABLE minmaxtest1 ()
INHERITS (
    minmaxtest
);

CREATE TABLE minmaxtest2 ()
INHERITS (
    minmaxtest
);

CREATE TABLE minmaxtest3 ()
INHERITS (
    minmaxtest
);

CREATE INDEX minmaxtesti ON minmaxtest (f1);

CREATE INDEX minmaxtest1i ON minmaxtest1 (f1);

CREATE INDEX minmaxtest2i ON minmaxtest2 (f1 DESC);

CREATE INDEX minmaxtest3i ON minmaxtest3 (f1)
WHERE
    f1 IS NOT NULL;

INSERT INTO minmaxtest
VALUES
    (11),
    (12);

INSERT INTO minmaxtest1
VALUES
    (13),
    (14);

INSERT INTO minmaxtest2
VALUES
    (15),
    (16);

INSERT INTO minmaxtest3
VALUES
    (17),
    (18);

EXPLAIN (
    COSTS OFF
)
SELECT
    min(f1),
    max(f1)
FROM
    minmaxtest;

SELECT
    min(f1),
    max(f1)
FROM
    minmaxtest;

-- DISTINCT doesn't do anything useful here, but it shouldn't fail
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    min(f1),
    max(f1)
FROM
    minmaxtest;

SELECT DISTINCT
    min(f1),
    max(f1)
FROM
    minmaxtest;

DROP TABLE minmaxtest CASCADE;

-- check for correct detection of nested-aggregate errors
SELECT
    max(min(unique1))
FROM
    tenk1;

SELECT
    (
        SELECT
            max(min(unique1))
        FROM
            int8_tbl)
FROM
    tenk1;

--
-- Test removal of redundant GROUP BY columns
--
CREATE temp TABLE t1 (
    a int,
    b int,
    c int,
    d int,
    PRIMARY KEY (a, b)
);

CREATE temp TABLE t2 (
    x int,
    y int,
    z int,
    PRIMARY KEY (x, y)
);

CREATE temp TABLE t3 (
    a int,
    b int,
    c int,
    PRIMARY KEY (a, b) DEFERRABLE
);

-- Non-primary-key columns can be removed from GROUP BY
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t1
GROUP BY
    a,
    b,
    c,
    d;

-- No removal can happen if the complete PK is not present in GROUP BY
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    c
FROM
    t1
GROUP BY
    a,
    c,
    d;

-- Test removal across multiple relations
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t1
    INNER JOIN t2 ON t1.a = t2.x
        AND t1.b = t2.y
GROUP BY
    t1.a,
    t1.b,
    t1.c,
    t1.d,
    t2.x,
    t2.y,
    t2.z;

-- Test case where t1 can be optimized but not t2
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.*,
    t2.x,
    t2.z
FROM
    t1
    INNER JOIN t2 ON t1.a = t2.x
        AND t1.b = t2.y
GROUP BY
    t1.a,
    t1.b,
    t1.c,
    t1.d,
    t2.x,
    t2.z;

-- Cannot optimize when PK is deferrable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t3
GROUP BY
    a,
    b,
    c;

DROP TABLE t1;

DROP TABLE t2;

DROP TABLE t3;

--
-- Test combinations of DISTINCT and/or ORDER BY
--
SELECT
    array_agg(a ORDER BY b)
FROM (
    VALUES (1, 4),
        (2, 3),
        (3, 1),
        (4, 2)) v (a, b);

SELECT
    array_agg(a ORDER BY a)
FROM (
    VALUES (1, 4),
        (2, 3),
        (3, 1),
        (4, 2)) v (a, b);

SELECT
    array_agg(a ORDER BY a DESC)
FROM (
    VALUES (1, 4),
        (2, 3),
        (3, 1),
        (4, 2)) v (a, b);

SELECT
    array_agg(b ORDER BY a DESC)
FROM (
    VALUES (1, 4),
        (2, 3),
        (3, 1),
        (4, 2)) v (a, b);

SELECT
    array_agg(DISTINCT a)
FROM (
    VALUES (1),
        (2),
        (1),
        (3),
        (NULL),
        (2)) v (a);

SELECT
    array_agg(DISTINCT a ORDER BY a)
FROM (
    VALUES (1),
        (2),
        (1),
        (3),
        (NULL),
        (2)) v (a);

SELECT
    array_agg(DISTINCT a ORDER BY a DESC)
FROM (
    VALUES (1),
        (2),
        (1),
        (3),
        (NULL),
        (2)) v (a);

SELECT
    array_agg(DISTINCT a ORDER BY a DESC nulls LAST)
FROM (
    VALUES (1),
        (2),
        (1),
        (3),
        (NULL),
        (2)) v (a);

-- multi-arg aggs, strict/nonstrict, distinct/order by
SELECT
    aggfstr (a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    aggfns (a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    aggfstr (DISTINCT a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

SELECT
    aggfns (DISTINCT a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

SELECT
    aggfstr (DISTINCT a, b, c ORDER BY b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

SELECT
    aggfns (DISTINCT a, b, c ORDER BY b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

-- test specific code paths
SELECT
    aggfns (DISTINCT a, a, c ORDER BY c USING ~<~, a)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, a, c ORDER BY c USING ~<~)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, a, c ORDER BY a)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, b, c ORDER BY a, c USING ~<~, b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

-- check node I/O via view creation and usage, also deparsing logic
CREATE VIEW agg_view1 AS
SELECT
    aggfns (a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (DISTINCT a, b, c)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (DISTINCT a, b, c ORDER BY b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 3) i;

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (a, b, c ORDER BY b + 1)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (a, a, c ORDER BY b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (a, b, c ORDER BY c USING ~<~)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c);

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

CREATE OR REPLACE VIEW agg_view1 AS
SELECT
    aggfns (DISTINCT a, b, c ORDER BY a, c USING ~<~, b)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    *
FROM
    agg_view1;

SELECT
    pg_get_viewdef('agg_view1'::regclass);

DROP VIEW agg_view1;

-- incorrect DISTINCT usage errors
SELECT
    aggfns (DISTINCT a, b, c ORDER BY i)
FROM (
    VALUES (1, 1, 'foo')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, b, c ORDER BY a, b + 1)
FROM (
    VALUES (1, 1, 'foo')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, b, c ORDER BY a, b, i, c)
FROM (
    VALUES (1, 1, 'foo')) v (a, b, c),
    generate_series(1, 2) i;

SELECT
    aggfns (DISTINCT a, a, c ORDER BY a, b)
FROM (
    VALUES (1, 1, 'foo')) v (a, b, c),
    generate_series(1, 2) i;

-- string_agg tests
SELECT
    string_agg(a, ',')
FROM (
    VALUES ('aaaa'),
        ('bbbb'),
        ('cccc')) g (a);

SELECT
    string_agg(a, ',')
FROM (
    VALUES ('aaaa'),
        (NULL),
        ('bbbb'),
        ('cccc')) g (a);

SELECT
    string_agg(a, 'AB')
FROM (
    VALUES (NULL),
        (NULL),
        ('bbbb'),
        ('cccc')) g (a);

SELECT
    string_agg(a, ',')
FROM (
    VALUES (NULL),
        (NULL)) g (a);

-- check some implicit casting cases, as per bug #5564
SELECT
    string_agg(DISTINCT f1, ',' ORDER BY f1)
FROM
    varchar_tbl;

-- ok
SELECT
    string_agg(DISTINCT f1::text, ',' ORDER BY f1)
FROM
    varchar_tbl;

-- not ok
SELECT
    string_agg(DISTINCT f1, ',' ORDER BY f1::text)
FROM
    varchar_tbl;

-- not ok
SELECT
    string_agg(DISTINCT f1::text, ',' ORDER BY f1::text)
FROM
    varchar_tbl;

-- ok
-- string_agg bytea tests
CREATE TABLE bytea_test_table (
    v bytea
);

SELECT
    string_agg(v, '')
FROM
    bytea_test_table;

INSERT INTO bytea_test_table
    VALUES (decode('ff', 'hex'));

SELECT
    string_agg(v, '')
FROM
    bytea_test_table;

INSERT INTO bytea_test_table
    VALUES (decode('aa', 'hex'));

SELECT
    string_agg(v, '')
FROM
    bytea_test_table;

SELECT
    string_agg(v, NULL)
FROM
    bytea_test_table;

SELECT
    string_agg(v, decode('ee', 'hex'))
FROM
    bytea_test_table;

DROP TABLE bytea_test_table;

-- FILTER tests
SELECT
    min(unique1) FILTER (WHERE unique1 > 100)
FROM
    tenk1;

SELECT
    sum(1 / ten) FILTER (WHERE ten > 0)
FROM
    tenk1;

SELECT
    ten,
    sum(DISTINCT four) FILTER (WHERE four::text ~ '123')
FROM
    onek a
GROUP BY
    ten;

SELECT
    ten,
    sum(DISTINCT four) FILTER (WHERE four > 10)
FROM
    onek a
GROUP BY
    ten
HAVING
    EXISTS (
        SELECT
            1
        FROM
            onek b
        WHERE
            sum(DISTINCT a.four) = b.four);

SELECT
    max(foo COLLATE "C") FILTER (WHERE (bar COLLATE "POSIX") > '0')
FROM (
    VALUES ('a', 'b')) AS v (foo, bar);

-- outer reference in FILTER (PostgreSQL extension)
SELECT
    (
        SELECT
            count(*)
        FROM (
            VALUES (1)) t0 (inner_c))
FROM (
    VALUES (2), (3)) t1 (outer_c);

-- inner query is aggregation query
SELECT
    (
        SELECT
            count(*) FILTER (WHERE outer_c <> 0)
        FROM (
            VALUES (1)) t0 (inner_c))
FROM (
    VALUES (2), (3)) t1 (outer_c);

-- outer query is aggregation query
SELECT
    (
        SELECT
            count(inner_c) FILTER (WHERE outer_c <> 0)
        FROM (
            VALUES (1)) t0 (inner_c))
FROM (
    VALUES (2), (3)) t1 (outer_c);

-- inner query is aggregation query
SELECT
    (
        SELECT
            max(
                SELECT
                    i.unique2
                FROM tenk1 i
                WHERE
                    i.unique1 = o.unique1) FILTER (WHERE o.unique1 < 10))
FROM
    tenk1 o;

-- outer query is aggregation query
-- subquery in FILTER clause (PostgreSQL extension)
SELECT
    sum(unique1) FILTER (WHERE unique1 IN (
        SELECT
            unique1 FROM onek WHERE unique1 < 100))
FROM
    tenk1;

-- exercise lots of aggregate parts with FILTER
SELECT
    aggfns (DISTINCT a, b, c ORDER BY a, c USING ~<~, b) FILTER (WHERE a > 1)
FROM (
    VALUES (1, 3, 'foo'),
        (0, NULL, NULL),
        (2, 2, 'bar'),
        (3, 1, 'baz')) v (a, b, c),
    generate_series(1, 2) i;

-- ordered-set aggregates
SELECT
    p,
    percentile_cont(p) WITHIN GROUP (ORDER BY x::float8)
FROM
    generate_series(1, 5) x,
    (
        VALUES (0::float8),
            (0.1),
            (0.25),
            (0.4),
            (0.5),
            (0.6),
            (0.75),
            (0.9),
            (1)) v (p)
GROUP BY
    p
ORDER BY
    p;

SELECT
    p,
    percentile_cont(p ORDER BY p) WITHIN GROUP (ORDER BY x) -- error
FROM
    generate_series(1, 5) x,
    (
        VALUES (0::float8),
            (0.1),
            (0.25),
            (0.4),
            (0.5),
            (0.6),
            (0.75),
            (0.9),
            (1)) v (p)
GROUP BY
    p
ORDER BY
    p;

SELECT
    p,
    sum() WITHIN GROUP (ORDER BY x::float8) -- error
FROM
    generate_series(1, 5) x,
    (
        VALUES (0::float8),
            (0.1),
            (0.25),
            (0.4),
            (0.5),
            (0.6),
            (0.75),
            (0.9),
            (1)) v (p)
GROUP BY
    p
ORDER BY
    p;

SELECT
    p,
    percentile_cont(p, p) -- error
FROM
    generate_series(1, 5) x,
    (
        VALUES (0::float8),
            (0.1),
            (0.25),
            (0.4),
            (0.5),
            (0.6),
            (0.75),
            (0.9),
            (1)) v (p)
GROUP BY
    p
ORDER BY
    p;

SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY b)
FROM
    aggtest;

SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY b),
    sum(b)
FROM
    aggtest;

SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

SELECT
    percentile_disc(0.5) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

SELECT
    rank(3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3),
        (4)) v (x);

SELECT
    cume_dist(3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3),
        (4)) v (x);

SELECT
    percent_rank(3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3),
        (4),
        (5)) v (x);

SELECT
    dense_rank(3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3),
        (4)) v (x);

SELECT
    percentile_disc(ARRAY[0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

SELECT
    percentile_cont(ARRAY[0, 0.25, 0.5, 0.75, 1]) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

SELECT
    percentile_disc(ARRAY[[NULL, 1, 0.5],[0.75, 0.25, NULL]]) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

SELECT
    percentile_cont(ARRAY[0, 1, 0.25, 0.75, 0.5, 1, 0.3, 0.32, 0.35, 0.38, 0.4]) WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 6) x;

SELECT
    ten,
    mode() WITHIN GROUP (ORDER BY string4)
FROM
    tenk1
GROUP BY
    ten;

SELECT
    percentile_disc(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY x)
FROM
    unnest('{fred,jim,fred,jack,jill,fred,jill,jim,jim,sheila,jim,sheila}'::text[]) u (x);

-- check collation propagates up in suitable cases:
SELECT
    pg_collation_for(percentile_disc(1) WITHIN GROUP (ORDER BY x COLLATE "POSIX"))
FROM (
    VALUES ('fred'),
        ('jim')) v (x);

-- ordered-set aggs created with CREATE AGGREGATE
SELECT
    test_rank (3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3),
        (4)) v (x);

SELECT
    test_percentile_disc (0.5) WITHIN GROUP (ORDER BY thousand)
FROM
    tenk1;

-- ordered-set aggs can't use ungrouped vars in direct args:
SELECT
    rank(x) WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 5) x;

-- outer-level agg can't use a grouped arg of a lower level, either:
SELECT
    ARRAY (
        SELECT
            percentile_disc(a) WITHIN GROUP (ORDER BY x)
        FROM (
            VALUES (0.3),
                (0.7)) v (a)
            GROUP BY
                a)
    FROM
        generate_series(1, 5) g (x);

-- agg in the direct args is a grouping violation, too:
SELECT
    rank(sum(x)) WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 5) x;

-- hypothetical-set type unification and argument-count failures:
SELECT
    rank(3) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES ('fred'),
        ('jim')) v (x);

SELECT
    rank(3) WITHIN GROUP (ORDER BY stringu1, stringu2)
FROM
    tenk1;

SELECT
    rank('fred') WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 5) x;

SELECT
    rank('adam'::text COLLATE "C") WITHIN GROUP (ORDER BY x COLLATE "POSIX")
FROM (
    VALUES ('fred'),
        ('jim')) v (x);

-- hypothetical-set type unification successes:
SELECT
    rank('adam'::varchar) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES ('fred'),
        ('jim')) v (x);

SELECT
    rank('3') WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 5) x;

-- divide by zero check
SELECT
    percent_rank(0) WITHIN GROUP (ORDER BY x)
FROM
    generate_series(1, 0) x;

-- deparse and multiple features:
CREATE VIEW aggordview1 AS
SELECT
    ten,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY thousand) AS p50,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY thousand) FILTER (WHERE hundred = 1) AS px,
    rank(5, 'AZZZZ', 50) WITHIN GROUP (ORDER BY hundred, string4 DESC, hundred)
FROM
    tenk1
GROUP BY
    ten
ORDER BY
    ten;

SELECT
    pg_get_viewdef('aggordview1');

SELECT
    *
FROM
    aggordview1
ORDER BY
    ten;

DROP VIEW aggordview1;

-- variadic aggregates
SELECT
    least_agg (q1, q2)
FROM
    int8_tbl;

SELECT
    least_agg (VARIADIC ARRAY[q1, q2])
FROM
    int8_tbl;

-- test aggregates with common transition functions share the same states
BEGIN WORK;
CREATE TYPE avg_state AS (
    total bigint,
    count bigint
);
CREATE OR REPLACE FUNCTION avg_transfn (state avg_state, n int)
    RETURNS avg_state
    AS $$
DECLARE
    new_state avg_state;
BEGIN
    RAISE NOTICE 'avg_transfn called with %', n;
    IF state IS NULL THEN
        IF n IS NOT NULL THEN
            new_state.total := n;
            new_state.count := 1;
            RETURN new_state;
        END IF;
        RETURN NULL;
    ELSIF n IS NOT NULL THEN
        state.total := state.total + n;
        state.count := state.count + 1;
        RETURN state;
    END IF;
    RETURN NULL;
END
$$
LANGUAGE plpgsql;
CREATE FUNCTION avg_finalfn (state avg_state)
    RETURNS int4
    AS $$
BEGIN
    IF state IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN state.total / state.count;
    END IF;
END
$$
LANGUAGE plpgsql;
CREATE FUNCTION sum_finalfn (state avg_state)
    RETURNS int4
    AS $$
BEGIN
    IF state IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN state.total;
    END IF;
END
$$
LANGUAGE plpgsql;
CREATE AGGREGATE my_avg (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = avg_finalfn
);
CREATE AGGREGATE my_sum (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = sum_finalfn
);
-- aggregate state should be shared as aggs are the same.
SELECT
    my_avg (one),
    my_avg (one)
FROM (
    VALUES (1),
        (3)) t (one);
-- aggregate state should be shared as transfn is the same for both aggs.
SELECT
    my_avg (one),
    my_sum (one)
FROM (
    VALUES (1),
        (3)) t (one);
-- same as previous one, but with DISTINCT, which requires sorting the input.
SELECT
    my_avg (DISTINCT one),
    my_sum (DISTINCT one)
FROM (
    VALUES (1),
        (3),
        (1)) t (one);
-- shouldn't share states due to the distinctness not matching.
SELECT
    my_avg (DISTINCT one),
    my_sum (one)
FROM (
    VALUES (1),
        (3)) t (one);
-- shouldn't share states due to the filter clause not matching.
SELECT
    my_avg (one) FILTER (WHERE one > 1),
    my_sum (one)
FROM (
    VALUES (1),
        (3)) t (one);
-- this should not share the state due to different input columns.
SELECT
    my_avg (one),
    my_sum (two)
FROM (
    VALUES (1, 2),
        (3, 4)) t (one, two);
-- exercise cases where OSAs share state
SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY a),
    percentile_disc(0.5) WITHIN GROUP (ORDER BY a)
FROM (
    VALUES (1::float8),
        (3),
        (5),
        (7)) t (a);
SELECT
    percentile_cont(0.25) WITHIN GROUP (ORDER BY a),
    percentile_disc(0.5) WITHIN GROUP (ORDER BY a)
FROM (
    VALUES (1::float8),
        (3),
        (5),
        (7)) t (a);
-- these can't share state currently
SELECT
    rank(4) WITHIN GROUP (ORDER BY a),
    dense_rank(4) WITHIN GROUP (ORDER BY a)
FROM (
    VALUES (1),
        (3),
        (5),
        (7)) t (a);
-- test that aggs with the same sfunc and initcond share the same agg state
CREATE AGGREGATE my_sum_init (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = sum_finalfn,
    INITCOND = '(10,0)'
);
CREATE AGGREGATE my_avg_init (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = avg_finalfn,
    INITCOND = '(10,0)'
);
CREATE AGGREGATE my_avg_init2 (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = avg_finalfn,
    INITCOND = '(4,0)'
);
-- state should be shared if INITCONDs are matching
SELECT
    my_sum_init (one),
    my_avg_init (one)
FROM (
    VALUES (1),
        (3)) t (one);
-- Varying INITCONDs should cause the states not to be shared.
SELECT
    my_sum_init (one),
    my_avg_init2 (one)
FROM (
    VALUES (1),
        (3)) t (one);
ROLLBACK;

-- test aggregate state sharing to ensure it works if one aggregate has a
-- finalfn and the other one has none.
BEGIN WORK;
CREATE OR REPLACE FUNCTION sum_transfn (state int4, n int4)
    RETURNS int4
    AS $$
DECLARE
    new_state int4;
BEGIN
    RAISE NOTICE 'sum_transfn called with %', n;
    IF state IS NULL THEN
        IF n IS NOT NULL THEN
            new_state := n;
            RETURN new_state;
        END IF;
        RETURN NULL;
    ELSIF n IS NOT NULL THEN
        state := state + n;
        RETURN state;
    END IF;
    RETURN NULL;
END
$$
LANGUAGE plpgsql;
CREATE FUNCTION halfsum_finalfn (state int4)
    RETURNS int4
    AS $$
BEGIN
    IF state IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN state / 2;
    END IF;
END
$$
LANGUAGE plpgsql;
CREATE AGGREGATE my_sum (int4) (
    STYPE = int4,
    SFUNC = sum_transfn
);
CREATE AGGREGATE my_half_sum (int4) (
    STYPE = int4,
    SFUNC = sum_transfn,
    FINALFUNC = halfsum_finalfn
);
-- Agg state should be shared even though my_sum has no finalfn
SELECT
    my_sum (one),
    my_half_sum (one)
FROM (
    VALUES (1),
        (2),
        (3),
        (4)) t (one);
ROLLBACK;

-- test that the aggregate transition logic correctly handles
-- transition / combine functions returning NULL
-- First test the case of a normal transition function returning NULL
BEGIN;
CREATE FUNCTION balkifnull (int8, int4)
    RETURNS int8 STRICT
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF $1 IS NULL THEN
        RAISE 'erroneously called with NULL argument';
    END IF;
    RETURN NULL;
END
$$;
CREATE AGGREGATE balk (int4) (
    SFUNC = balkifnull (int8, int4),
    STYPE = int8,
    PARALLEL = SAFE,
    INITCOND = '0'
);
SELECT
    balk (hundred)
FROM
    tenk1;
ROLLBACK;

-- Secondly test the case of a parallel aggregate combiner function
-- returning NULL. For that use normal transition function, but a
-- combiner function returning NULL.
BEGIN ISOLATION LEVEL REPEATABLE READ;
CREATE FUNCTION balkifnull (int8, int8)
    RETURNS int8 PARALLEL SAFE STRICT
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF $1 IS NULL THEN
        RAISE 'erroneously called with NULL argument';
    END IF;
    RETURN NULL;
END
$$;
CREATE AGGREGATE balk (int4) (
    SFUNC = int4_sum(int8, int4),
    STYPE = int8,
    COMBINEFUNC = balkifnull (int8, int8),
    PARALLEL = SAFE,
    INITCOND = '0'
);
-- force use of parallelism
ALTER TABLE tenk1 SET (parallel_workers = 4);
SET LOCAL parallel_setup_cost = 0;
SET LOCAL max_parallel_workers_per_gather = 4;
EXPLAIN (
    COSTS OFF
)
SELECT
    balk (hundred)
FROM
    tenk1;
SELECT
    balk (hundred)
FROM
    tenk1;
ROLLBACK;

-- test coverage for aggregate combine/serial/deserial functions
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
SET enable_indexonlyscan = OFF;
-- variance(int4) covers numeric_poly_combine
-- sum(int8) covers int8_avg_combine
EXPLAIN (
    COSTS OFF
)
SELECT
    variance(unique1::int4),
    sum(unique1::int8)
FROM
    tenk1;
SELECT
    variance(unique1::int4),
    sum(unique1::int8)
FROM
    tenk1;
ROLLBACK;

-- test coverage for dense_rank
SELECT
    dense_rank(x) WITHIN GROUP (ORDER BY x)
FROM (
    VALUES (1),
        (1),
        (2),
        (2),
        (3),
        (3)) v (x)
GROUP BY
    (x)
ORDER BY
    1;

-- Ensure that the STRICT checks for aggregates does not take NULLness
-- of ORDER BY columns into account. See bug report around
-- 2a505161-2727-2473-7c46-591ed108ac52@email.cz
SELECT
    min(x ORDER BY y)
FROM (
    VALUES (1, NULL)) AS d (x, y);

SELECT
    min(x ORDER BY y)
FROM (
    VALUES (1, 2)) AS d (x, y);

-- check collation-sensitive matching between grouping expressions
SELECT
    v || 'a',
    CASE v || 'a'
    WHEN 'aa' THEN
        1
    ELSE
        0
    END,
    count(*)
FROM
    unnest(ARRAY['a', 'b']) u (v)
GROUP BY
    v || 'a'
ORDER BY
    1;

SELECT
    v || 'a',
    CASE WHEN v || 'a' = 'aa' THEN
        1
    ELSE
        0
    END,
    count(*)
FROM
    unnest(ARRAY['a', 'b']) u (v)
GROUP BY
    v || 'a'
ORDER BY
    1;

