--
-- AGGREGATES
--
-- directory paths are passed to us in environment variables
\getenv abs_srcdir PG_ABS_SRCDIR

-- avoid bit-exact output here because operations may not be bit-exact.
SET extra_float_digits = 0;

-- prepare some test data
CREATE TABLE aggtest (
    a int2,
    b float4
);

\set filename :abs_srcdir '/data/agg.data'
COPY aggtest
FROM
    :'filename';

ANALYZE aggtest;

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

SELECT
    any_value (v)
FROM (
    VALUES (1),
        (2),
        (3)) AS v (v);

SELECT
    any_value (v)
FROM (
    VALUES (NULL)) AS v (v);

SELECT
    any_value (v)
FROM (
    VALUES (NULL),
        (1),
        (2)) AS v (v);

SELECT
    any_value (v)
FROM (
    VALUES (ARRAY['hello', 'world'])) AS v (v);

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
    var_pop(1.0::float8),
    var_samp(2.0::float8);

SELECT
    stddev_pop(3.0::float8),
    stddev_samp(4.0::float8);

SELECT
    var_pop('inf'::float8),
    var_samp('inf'::float8);

SELECT
    stddev_pop('inf'::float8),
    stddev_samp('inf'::float8);

SELECT
    var_pop('nan'::float8),
    var_samp('nan'::float8);

SELECT
    stddev_pop('nan'::float8),
    stddev_samp('nan'::float8);

SELECT
    var_pop(1.0::float4),
    var_samp(2.0::float4);

SELECT
    stddev_pop(3.0::float4),
    stddev_samp(4.0::float4);

SELECT
    var_pop('inf'::float4),
    var_samp('inf'::float4);

SELECT
    stddev_pop('inf'::float4),
    stddev_samp('inf'::float4);

SELECT
    var_pop('nan'::float4),
    var_samp('nan'::float4);

SELECT
    stddev_pop('nan'::float4),
    stddev_samp('nan'::float4);

SELECT
    var_pop(1.0::numeric),
    var_samp(2.0::numeric);

SELECT
    stddev_pop(3.0::numeric),
    stddev_samp(4.0::numeric);

SELECT
    var_pop('inf'::numeric),
    var_samp('inf'::numeric);

SELECT
    stddev_pop('inf'::numeric),
    stddev_samp('inf'::numeric);

SELECT
    var_pop('nan'::numeric),
    var_samp('nan'::numeric);

SELECT
    stddev_pop('nan'::numeric),
    stddev_samp('nan'::numeric);

-- verify correct results for min(record) and max(record) aggregates
SELECT
    max(ROW (a, b))
FROM
    aggtest;

SELECT
    max(ROW (b, a))
FROM
    aggtest;

SELECT
    min(ROW (a, b))
FROM
    aggtest;

SELECT
    min(ROW (b, a))
FROM
    aggtest;

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
    sum(x::float8),
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('1'),
        ('infinity')) v (x);

SELECT
    sum(x::float8),
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('infinity'),
        ('1')) v (x);

SELECT
    sum(x::float8),
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('infinity'),
        ('infinity')) v (x);

SELECT
    sum(x::float8),
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('-infinity'),
        ('infinity')) v (x);

SELECT
    sum(x::float8),
    avg(x::float8),
    var_pop(x::float8)
FROM (
    VALUES ('-infinity'),
        ('-infinity')) v (x);

SELECT
    sum(x::numeric),
    avg(x::numeric),
    var_pop(x::numeric)
FROM (
    VALUES ('1'),
        ('infinity')) v (x);

SELECT
    sum(x::numeric),
    avg(x::numeric),
    var_pop(x::numeric)
FROM (
    VALUES ('infinity'),
        ('1')) v (x);

SELECT
    sum(x::numeric),
    avg(x::numeric),
    var_pop(x::numeric)
FROM (
    VALUES ('infinity'),
        ('infinity')) v (x);

SELECT
    sum(x::numeric),
    avg(x::numeric),
    var_pop(x::numeric)
FROM (
    VALUES ('-infinity'),
        ('infinity')) v (x);

SELECT
    sum(x::numeric),
    avg(x::numeric),
    var_pop(x::numeric)
FROM (
    VALUES ('-infinity'),
        ('-infinity')) v (x);

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

-- check single-tuple behavior
SELECT
    covar_pop(1::float8, 2::float8),
    covar_samp(3::float8, 4::float8);

SELECT
    covar_pop(1::float8, 'inf'::float8),
    covar_samp(3::float8, 'inf'::float8);

SELECT
    covar_pop(1::float8, 'nan'::float8),
    covar_samp(3::float8, 'nan'::float8);

-- check some cases that formerly had poor roundoff-error behavior
-- note: regr_r2() differs from corr() for a horizontal line, per spec
SELECT
    corr(0.09, g),
    regr_r2(0.09, g)
FROM
    generate_series(1, 30) g;

SELECT
    corr(g, 0.09),
    regr_r2(g, 0.09),
    regr_slope(g, 0.09),
    regr_intercept(g, 0.09)
FROM
    generate_series(1, 30) g;

SELECT
    corr(1.3 + g * 1e-16, 1.3 + g * 1e-16)
FROM
    generate_series(1, 3) g;

-- verify that we handle Inf/NaN the same regardless of position
WITH data (
    x
) AS (
    VALUES (1::float8),
        (2::float8),
        (3::float8))
SELECT
    covar_pop(x, 0::float8)
FROM
    data;

WITH data (
    x
) AS (
    VALUES ('Inf'::float8),
        (2::float8),
        (3::float8))
SELECT
    covar_pop(x, 0::float8)
FROM
    data;

WITH data (
    x
) AS (
    VALUES (1::float8),
        ('Inf'::float8),
        (3::float8))
SELECT
    covar_pop(x, 0::float8)
FROM
    data;

WITH data (
    x
) AS (
    VALUES ('NaN'::float8),
        (2::float8),
        (3::float8))
SELECT
    covar_pop(x, 0::float8)
FROM
    data;

WITH data (
    x
) AS (
    VALUES (1::float8),
        ('NaN'::float8),
        (3::float8))
SELECT
    covar_pop(x, 0::float8)
FROM
    data;

-- check some cases that formerly suffered from internal overflow/underflow
SELECT
    corr(1e-100 + g * 1e-105, 1e-100 + g * 1e-105),
    regr_r2(1e-100 + g * 1e-105, 1e-100 + g * 1e-105)
FROM
    generate_series(1, 3) g;

SELECT
    corr(1e-100 + g * 1e-105, 1e-100 + g * 1e-105),
    regr_r2(1e-100 + g * 1e-105, 1e-100 + g * 1e-105)
FROM
    generate_series(1, 30) g;

SELECT
    corr(1e100 + g * 1e95, 1e100 + g * 1e95),
    regr_r2(1e100 + g * 1e95, 1e100 + g * 1e95)
FROM
    generate_series(1, 2) g;

SELECT
    regr_intercept(y, x)
FROM (
    VALUES (- 1e150, 0),
        (2e150, 3e150)) v (x, y);

SELECT
    regr_intercept(y, x)
FROM (
    VALUES (- 1e-131, 0),
        (2e-131, 3e-131)) v (x, y);

-- these examples pose definitional questions for NaN inputs,
-- which we resolve by saying that an all-NaN input column is not all equal
SELECT
    corr(g, 'NaN'),
    regr_r2(g, 'NaN')
FROM
    generate_series(1, 30) g;

SELECT
    corr(0.1, 'NaN'),
    regr_r2(0.1, 'NaN')
FROM
    generate_series(1, 30) g;

SELECT
    corr('NaN', 0.1),
    regr_r2('NaN', 0.1)
FROM
    generate_series(1, 30) g;

SELECT
    corr('NaN', 'NaN'),
    regr_r2('NaN', 'NaN')
FROM
    generate_series(1, 30) g;

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
    float8_regr_accum('{4,140,2900,1290,83075,15050,100,0}'::float8[], 200, 100);

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
    float8_regr_combine('{3,60,200,750,20000,2000,1,NaN}'::float8[], '{0,0,0,0,0,0,0,0}'::float8[]);

SELECT
    float8_regr_combine('{0,0,0,0,0,0,0,0}'::float8[], '{2,180,200,740,57800,-3400,NaN,1}'::float8[]);

SELECT
    float8_regr_combine('{3,60,200,750,20000,2000,7,8}'::float8[], '{2,180,200,740,57800,-3400,7,9}'::float8[]);

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

-- sanity checks
SELECT
    sum(q1 + q2),
    sum(q1) + sum(q2)
FROM
    int8_tbl;

SELECT
    sum(q1 - q2),
    sum(q2 - q1),
    sum(q1) - sum(q2)
FROM
    int8_tbl;

SELECT
    sum(q1 * 2000),
    sum(- q1 * 2000),
    2000 * sum(q1)
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
            max((
                SELECT
                    i.unique2
                FROM tenk1 i
                WHERE
                    i.unique1 = o.unique1)))
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
    ARRAY(
        SELECT
            sum(x + y) s
        FROM generate_series(1, 3) y
        GROUP BY
            y
        ORDER BY
            s)
FROM
    generate_series(1, 3) x;

SELECT
    ARRAY(
        SELECT
            sum(x + y) s
        FROM generate_series(1, 3) y
        GROUP BY
            y
        ORDER BY
            s)
FROM
    generate_series(1, 3) x;

-- Test handling of grouping-expression references within sublinks
SELECT
    two + four AS g,
    (
        SELECT
            f1
        FROM
            int4_tbl
        WHERE
            f1 = (two + four))
FROM
    tenk1 t1
GROUP BY
    two + four
ORDER BY
    1;

SELECT
    q1,
    (
        SELECT
            q1) AS ss -- q1 is actually a COALESCE expression here
FROM
    int8_tbl i81
    FULL OUTER JOIN int8_tbl i82 USING (q1)
GROUP BY
    q1
ORDER BY
    q1;

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
    BIT_OR(i4) AS "?",
    BIT_XOR (i8) AS "?"
FROM
    bitwise_test;

COPY bitwise_test FROM STDIN NULL 'null';
1	1	1	1	1	B0101
3	3	3	null	2	B0100
7	7	7	3	4	B1100
\.
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
    BIT_OR(y) AS "1101",
    BIT_XOR (i2) AS "5",
    BIT_XOR (i4) AS "5",
    BIT_XOR (i8) AS "5",
    BIT_XOR (i) AS "?",
    BIT_XOR (x) AS "7",
    BIT_XOR (y) AS "1101"
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

COPY bool_test FROM STDIN NULL 'null';
TRUE	null	FALSE	null
FALSE	TRUE	null	null
null	TRUE	FALSE	null
\.
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

-- two interesting corner cases: both non-null and null constant gets
-- optimized into a seqscan
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

EXPLAIN (
    COSTS OFF
)
SELECT
    max(NULL)
FROM
    tenk1;

SELECT
    max(NULL)
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

-- DISTINCT can also trigger wrong answers with hash aggregation (bug #18465)
BEGIN;
SET local enable_groupagg = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    ( SELECT DISTINCT
            min(t1.f1)
        FROM
            int4_tbl t1
        WHERE
            t1.f1 = t0.f1)
FROM
    int4_tbl t0;
SELECT
    f1,
    ( SELECT DISTINCT
            min(t1.f1)
        FROM
            int4_tbl t1
        WHERE
            t1.f1 = t0.f1)
FROM
    int4_tbl t0;
ROLLBACK;

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

SELECT
    avg((
        SELECT
            avg(a1.col1 ORDER BY (
                    SELECT
                        avg(a2.col2)
                    FROM tenk1 a3))
        FROM tenk1 a1 (col1)))
FROM
    tenk1 a2 (col2);

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

CREATE temp TABLE t1c ()
INHERITS (
    t1
);

-- Ensure we don't remove any columns when t1 has a child table
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

-- Okay to remove columns if we're only querying the parent.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    ONLY t1
GROUP BY
    a,
    b,
    c,
    d;

CREATE temp TABLE p_t1 (
    a int,
    b int,
    c int,
    d int,
    PRIMARY KEY (a, b)
)
PARTITION BY LIST (a);

CREATE temp TABLE p_t1_1 PARTITION OF p_t1
FOR VALUES IN (1);

CREATE temp TABLE p_t1_2 PARTITION OF p_t1
FOR VALUES IN (2);

-- Ensure we can remove non-PK columns for partitioned tables.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    p_t1
GROUP BY
    a,
    b,
    c,
    d;

CREATE UNIQUE INDEX t2_z_uidx ON t2 (z);

-- Ensure we don't remove any columns from the GROUP BY for a unique
-- index on a NULLable column.
EXPLAIN (
    COSTS OFF
)
SELECT
    y,
    z
FROM
    t2
GROUP BY
    y,
    z;

-- Make the column NOT NULL and ensure we remove the redundant column
ALTER TABLE t2
    ALTER COLUMN z SET NOT NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    y,
    z
FROM
    t2
GROUP BY
    y,
    z;

-- When there are multiple supporting unique indexes and the GROUP BY contains
-- columns to cover all of those, ensure we pick the index with the least
-- number of columns so that we can remove more columns from the GROUP BY.
EXPLAIN (
    COSTS OFF
)
SELECT
    x,
    y,
    z
FROM
    t2
GROUP BY
    x,
    y,
    z;

-- As above but try ordering the columns differently to ensure we get the
-- same result.
EXPLAIN (
    COSTS OFF
)
SELECT
    x,
    y,
    z
FROM
    t2
GROUP BY
    z,
    x,
    y;

-- Ensure we don't use a partial index as proof of functional dependency
DROP INDEX t2_z_uidx;

CREATE INDEX t2_z_uidx ON t2 (z)
WHERE
    z > 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    y,
    z
FROM
    t2
GROUP BY
    y,
    z;

-- A unique index defined as NULLS NOT DISTINCT does not need a supporting NOT
-- NULL constraint on the indexed columns.  Ensure the redundant columns are
-- removed from the GROUP BY for such a table.
DROP INDEX t2_z_uidx;

ALTER TABLE t2
    ALTER COLUMN z DROP NOT NULL;

CREATE UNIQUE INDEX t2_z_uidx ON t2 (z) nulls NOT DISTINCT;

EXPLAIN (
    COSTS OFF
)
SELECT
    y,
    z
FROM
    t2
GROUP BY
    y,
    z;

DROP TABLE t1 CASCADE;

DROP TABLE t2;

DROP TABLE t3;

DROP TABLE p_t1;

-- A composite type used by the tests below to exercise the asymmetry
-- between record_ops (per-field equality, the default) and record_image_ops
-- (bytewise equality): values like row(1.0) and row(1.00) are field-equal
-- but byte-distinct.
CREATE TYPE avg_rec AS (
    x numeric
);

-- A unique index proves uniqueness only under its own opfamily.  When the
-- GROUP BY's eqop comes from a different opfamily with looser equality,
-- rows the index regards as distinct can collapse into one GROUP BY group,
-- so the index is not usable for removing redundant columns.
CREATE temp TABLE t_opf (
    a avg_rec NOT NULL,
    b text
);

CREATE UNIQUE INDEX ON t_opf (a record_image_ops);

-- (1.0) and (1.00) are bytewise distinct but logically equal as records;
-- the index admits both, but GROUP BY a (default record_ops) would merge
-- them, so b must be retained as a grouping key.
INSERT INTO t_opf
VALUES
    (ROW (1.0)::avg_rec, 'X'),
    (ROW (1.00)::avg_rec, 'Y');

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b
FROM
    t_opf
GROUP BY
    a,
    b
ORDER BY
    b;

SELECT
    a,
    b
FROM
    t_opf
GROUP BY
    a,
    b
ORDER BY
    b;

DROP TABLE t_opf;

-- A HAVING clause that uses an equality operator from a different opfamily
-- than the GROUP BY's eqop must NOT be pushed down to WHERE.
CREATE temp TABLE t_having (
    id int,
    a avg_rec
);

INSERT INTO t_having
VALUES
    (1, ROW (1.0)::avg_rec),
    (2, ROW (1.00)::avg_rec),
    (3, ROW (2)::avg_rec);

-- the clause must stay in HAVING
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a *= ROW (1.0)::avg_rec;

SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a *= ROW (1.0)::avg_rec;

-- the clause must stay in HAVING
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a *= ANY (ARRAY[ROW (1.0)::avg_rec]);

SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a *= ANY (ARRAY[ROW (1.0)::avg_rec]);

-- the clause can be pushed down to WHERE
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a = ROW (1.0)::avg_rec;

SELECT
    a,
    count(*)
FROM
    t_having
GROUP BY
    a
HAVING
    a = ROW (1.0)::avg_rec;

DROP TABLE t_having;

DROP TYPE avg_rec;

--
-- Test GROUP BY matching of join columns that are type-coerced due to USING
--
CREATE temp TABLE t1 (
    f1 int,
    f2 int
);

CREATE temp TABLE t2 (
    f1 bigint,
    f2 oid
);

SELECT
    f1
FROM
    t1
    LEFT JOIN t2 USING (f1)
GROUP BY
    f1;

SELECT
    f1
FROM
    t1
    LEFT JOIN t2 USING (f1)
GROUP BY
    t1.f1;

SELECT
    t1.f1
FROM
    t1
    LEFT JOIN t2 USING (f1)
GROUP BY
    t1.f1;

-- only this one should fail:
SELECT
    t1.f1
FROM
    t1
    LEFT JOIN t2 USING (f1)
GROUP BY
    f1;

-- check case where we have to inject nullingrels into coerced join alias
SELECT
    f1,
    count(*)
FROM
    t1 x (x0,
        x1)
    LEFT JOIN (t1
        LEFT JOIN t2 USING (f1)) ON (x0 = 0)
GROUP BY
    f1;

-- same, for a RelabelType coercion
SELECT
    f2,
    count(*)
FROM
    t1 x (x0,
        x1)
    LEFT JOIN (t1
        LEFT JOIN t2 USING (f2)) ON (x0 = 0)
GROUP BY
    f2;

-- check that we preserve join alias in GROUP BY expressions
CREATE temp VIEW v1 AS
SELECT
    f1::int
FROM
    t1
    LEFT JOIN t2 USING (f1)
GROUP BY
    f1;

SELECT
    pg_get_viewdef('v1'::regclass);

DROP VIEW v1;

DROP TABLE t1, t2;

--
-- Test planner's selection of pathkeys for ORDER BY aggregates
--
-- Ensure we order by four.  This suits the most aggregate functions.
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(two ORDER BY two),
    max(four ORDER BY four),
    min(four ORDER BY four)
FROM
    tenk1;

-- Ensure we order by two.  It's a tie between ordering by two and four but
-- we tiebreak on the aggregate's position.
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(two ORDER BY two),
    max(four ORDER BY four),
    min(four ORDER BY four),
    max(two ORDER BY two)
FROM
    tenk1;

-- Similar to above, but tiebreak on ordering by four
EXPLAIN (
    COSTS OFF
)
SELECT
    max(four ORDER BY four),
    sum(two ORDER BY two),
    min(four ORDER BY four),
    max(two ORDER BY two)
FROM
    tenk1;

-- Ensure this one orders by ten since there are 3 aggregates that require ten
-- vs two that suit two and four.
EXPLAIN (
    COSTS OFF
)
SELECT
    max(four ORDER BY four),
    sum(two ORDER BY two),
    min(four ORDER BY four),
    max(two ORDER BY two),
    sum(ten ORDER BY ten),
    min(ten ORDER BY ten),
    max(ten ORDER BY ten)
FROM
    tenk1;

-- Try a case involving a GROUP BY clause where the GROUP BY column is also
-- part of an aggregate's ORDER BY clause.  We want a sort order that works
-- for the GROUP BY along with the first and the last aggregate.
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(unique1 ORDER BY ten, two),
    sum(unique1 ORDER BY four),
    sum(unique1 ORDER BY two, four)
FROM
    tenk1
GROUP BY
    ten;

-- Ensure that we never choose to provide presorted input to an Aggref with
-- a volatile function in the ORDER BY / DISTINCT clause.  We want to ensure
-- these sorts are performed individually rather than at the query level.
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(unique1 ORDER BY two),
    sum(unique1 ORDER BY four),
    sum(unique1 ORDER BY four, two),
    sum(unique1 ORDER BY two, random()),
    sum(unique1 ORDER BY two, random(), random() + 1)
FROM
    tenk1
GROUP BY
    ten;

-- Ensure consecutive NULLs are properly treated as distinct from each other
SELECT
    array_agg(DISTINCT val)
FROM (
    SELECT
        NULL AS val
    FROM
        generate_series(1, 2));

-- Ensure no ordering is requested when enable_presorted_aggregate is off
SET enable_presorted_aggregate TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    sum(two ORDER BY two)
FROM
    tenk1;

RESET enable_presorted_aggregate;

--
-- Test cases with FILTER clause
--
-- Ensure we presort when the aggregate contains plain Vars
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(two ORDER BY two) FILTER (WHERE two > 1)
FROM
    tenk1;

-- Ensure we presort for RelabelType'd Vars
EXPLAIN (
    COSTS OFF
)
SELECT
    string_agg(DISTINCT f1, ',') FILTER (WHERE length(f1) > 1)
FROM
    varchar_tbl;

-- Ensure we don't presort when the aggregate's argument contains an
-- explicit cast.
EXPLAIN (
    COSTS OFF
)
SELECT
    string_agg(DISTINCT f1::varchar(2), ',') FILTER (WHERE length(f1) > 1)
FROM
    varchar_tbl;

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

-- single input sorted on two keys; 0 and -0 differ only for *<
SELECT
    array_agg(DISTINCT r ORDER BY r USING <, r USING *<)
FROM (
    VALUES (ROW (-0.0::float8)),
        (ROW (0.0::float8))) v (r),
    generate_series(1, 2) i;

-- check again for the non-presorted aggregate code
SET enable_presorted_aggregate TO OFF;

SELECT
    array_agg(DISTINCT r ORDER BY r USING <, r USING *<)
FROM (
    VALUES (ROW (-0.0::float8)),
        (ROW (0.0::float8))) v (r),
    generate_series(1, 2) i;

-- likewise, but without DISTINCT; the second sort key must not be ignored
SELECT
    array_agg(r ORDER BY r USING <, r USING *<)
FROM (
    VALUES (ROW (-0.0::float8)),
        (ROW (0.0::float8))) v (r);

RESET enable_presorted_aggregate;

-- test a more complex permutation that has previous caused issues
SELECT
    string_agg(DISTINCT 'a', ','),
    sum((
        SELECT
            sum(1)
        FROM (
            VALUES (1)) b (id)
        WHERE
            a.id = b.id))
FROM
    unnest(ARRAY[1]) a (id);

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
-- string_agg, min, max bytea tests
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

SELECT
    min(v)
FROM
    bytea_test_table;

SELECT
    max(v)
FROM
    bytea_test_table;

INSERT INTO bytea_test_table
    VALUES (decode('ffff', 'hex'));

INSERT INTO bytea_test_table
    VALUES (decode('aaaa', 'hex'));

SELECT
    min(v)
FROM
    bytea_test_table;

SELECT
    max(v)
FROM
    bytea_test_table;

DROP TABLE bytea_test_table;

-- Test parallel string_agg and array_agg
CREATE TABLE pagg_test (
    x int,
    y int
)
WITH (
    autovacuum_enabled = OFF
);

INSERT INTO pagg_test
SELECT
    (
        CASE x % 4
        WHEN 1 THEN
            NULL
        ELSE
            x
        END),
    x % 10
FROM
    generate_series(1, 5000) x;

SET parallel_setup_cost TO 0;

SET parallel_tuple_cost TO 0;

SET parallel_leader_participation TO 0;

SET min_parallel_table_scan_size = 0;

SET bytea_output = 'escape';

SET max_parallel_workers_per_gather = 2;

-- create a view as we otherwise have to repeat this query a few times.
CREATE VIEW v_pagg_test AS
SELECT
    y,
    min(t) AS tmin,
    max(t) AS tmax,
    count(DISTINCT t) AS tndistinct,
    min(b) AS bmin,
    max(b) AS bmax,
    count(DISTINCT b) AS bndistinct,
    min(a) AS amin,
    max(a) AS amax,
    count(DISTINCT a) AS andistinct,
    min(aa) AS aamin,
    max(aa) AS aamax,
    count(DISTINCT aa) AS aandistinct
FROM (
    SELECT
        y,
        unnest(regexp_split_to_array(a1.t, ','))::int AS t,
        unnest(regexp_split_to_array(a1.b::text, ',')) AS b,
        unnest(a1.a) AS a,
        unnest(a1.aa) AS aa
    FROM (
        SELECT
            y,
            string_agg(x::text, ',') AS t,
            string_agg(x::text::bytea, ',') AS b,
            array_agg(x) AS a,
            array_agg(ARRAY[x]) AS aa
        FROM
            pagg_test
        GROUP BY
            y) a1) a2
GROUP BY
    y;

-- Ensure results are correct.
SELECT
    *
FROM
    v_pagg_test
ORDER BY
    y;

-- Ensure parallel aggregation is actually being used.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    v_pagg_test
ORDER BY
    y;

-- Ensure results are the same without parallel aggregation.
SET max_parallel_workers_per_gather = 0;

SELECT
    *
FROM
    v_pagg_test
ORDER BY
    y;

-- Check that we don't fail on anonymous record types.
SET max_parallel_workers_per_gather = 2;

EXPLAIN (
    COSTS OFF
)
SELECT
    array_dims(array_agg(s))
FROM (
    SELECT
        *
    FROM
        pagg_test) s;

SELECT
    array_dims(array_agg(s))
FROM (
    SELECT
        *
    FROM
        pagg_test) s;

-- Clean up
RESET max_parallel_workers_per_gather;

RESET bytea_output;

RESET min_parallel_table_scan_size;

RESET parallel_leader_participation;

RESET parallel_tuple_cost;

RESET parallel_setup_cost;

DROP VIEW v_pagg_test;

DROP TABLE pagg_test;

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

SELECT
    any_value (v) FILTER (WHERE v > 2)
FROM (
    VALUES (1),
        (2),
        (3)) AS v (v);

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
            max((
                SELECT
                    i.unique2
                FROM tenk1 i
                WHERE
                    i.unique1 = o.unique1)) FILTER (WHERE o.unique1 < 10))
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

-- check handling of bare boolean Var in FILTER
SELECT
    max(0) FILTER (WHERE b1)
FROM
    bool_test;

SELECT
    (
        SELECT
            max(0) FILTER (WHERE b1))
FROM
    bool_test;

-- check for correct detection of nested-aggregate errors in FILTER
SELECT
    max(unique1) FILTER (WHERE sum(ten) > 0)
FROM
    tenk1;

SELECT
    (
        SELECT
            max(unique1) FILTER (WHERE sum(ten) > 0)
        FROM
            int8_tbl)
FROM
    tenk1;

SELECT
    max(unique1) FILTER (WHERE bool_or(ten > 0))
FROM
    tenk1;

SELECT
    (
        SELECT
            max(unique1) FILTER (WHERE bool_or(ten > 0))
        FROM
            int8_tbl)
FROM
    tenk1;

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
    ARRAY(
        SELECT
            percentile_disc(a) WITHIN GROUP (ORDER BY x)
        FROM (
            VALUES (0.3), (0.7)) v (a)
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

SELECT
    cleast_agg (q1, q2)
FROM
    int8_tbl;

SELECT
    cleast_agg (4.5, f1)
FROM
    int4_tbl;

SELECT
    cleast_agg (VARIADIC ARRAY[4.5, f1])
FROM
    int4_tbl;

SELECT
    pg_typeof(cleast_agg (VARIADIC ARRAY[4.5, f1]))
FROM
    int4_tbl;

--
-- Test SupportRequestSimplifyAggref code
--
BEGIN;
CREATE TABLE agg_simplify (
    a int,
    not_null_col int NOT NULL,
    nullable_col int
);
-- Ensure count(not_null_col) uses count(*)
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(not_null_col)
FROM
    agg_simplify;
-- Ensure count(<not null const>) uses count(*)
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count('bananas')
FROM
    agg_simplify;
-- Ensure count(null) isn't optimized
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(NULL)
FROM
    agg_simplify;
-- Ensure count(nullable_col) does not use count(*)
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(nullable_col)
FROM
    agg_simplify;
-- Ensure there's no optimization with DISTINCT aggs
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(DISTINCT not_null_col)
FROM
    agg_simplify;
-- Ensure there's no optimization with ORDER BY aggs
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(not_null_col ORDER BY not_null_col)
FROM
    agg_simplify;
-- Ensure we don't optimize to count(*) with agglevelsup > 0
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    a
FROM
    agg_simplify a
GROUP BY
    a
HAVING
    EXISTS (
        SELECT
            1
        FROM
            onek b
        WHERE
            count(a.not_null_col) = b.four);
ROLLBACK;

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

-- GROUP BY optimization by reordering GROUP BY clauses
CREATE TABLE btg AS
SELECT
    i % 10 AS x,
    i % 10 AS y,
    'abc' || i % 10 AS z,
    i AS w
FROM
    generate_series(1, 100) AS i;

CREATE INDEX btg_x_y_idx ON btg (x, y);

ANALYZE btg;

SET enable_hashagg = OFF;

SET enable_seqscan = OFF;

-- Utilize the ordering of index scan to avoid a Sort operation
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btg
GROUP BY
    y,
    x;

-- Engage incremental sort
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btg
GROUP BY
    z,
    y,
    w,
    x;

-- Utilize the ordering of subquery scan to avoid a Sort operation
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM (
    SELECT
        *
    FROM
        btg
    ORDER BY
        x,
        y,
        w,
        z) AS q1
GROUP BY
    w,
    x,
    z,
    y;

-- Utilize the ordering of merge join to avoid a Sort operation
SET enable_hashjoin = OFF;

SET enable_nestloop = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btg t1
    JOIN btg t2 ON t1.w = t2.w
        AND t1.x = t2.x
        AND t1.z = t2.z
GROUP BY
    t1.w,
    t1.z,
    t1.x;

RESET enable_nestloop;

RESET enable_hashjoin;

-- Should work with and without GROUP-BY optimization
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btg
GROUP BY
    w,
    x,
    z,
    y
ORDER BY
    y,
    x,
    z,
    w;

-- Utilize incremental sort to make the ORDER BY rule a bit cheaper
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btg
GROUP BY
    w,
    x,
    y,
    z
ORDER BY
    x * x,
    z;

-- Test the case where the number of incoming subtree path keys is more than
-- the number of grouping keys.
CREATE INDEX btg_y_x_w_idx ON btg (y, x, w);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    y,
    x,
    array_agg(DISTINCT w)
FROM
    btg
WHERE
    y < 0
GROUP BY
    x,
    y;

-- Ensure that we do not select the aggregate pathkeys instead of the grouping
-- pathkeys
CREATE TABLE group_agg_pk AS
SELECT
    i % 10 AS x,
    i % 2 AS y,
    i % 2 AS z,
    2 AS w,
    i % 10 AS f
FROM
    generate_series(1, 100) AS i;

ANALYZE group_agg_pk;

SET enable_nestloop = OFF;

SET enable_hashjoin = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    avg(c1.f ORDER BY c1.x, c1.y)
FROM
    group_agg_pk c1
    JOIN group_agg_pk c2 ON c1.x = c2.x
GROUP BY
    c1.w,
    c1.z;

SELECT
    avg(c1.f ORDER BY c1.x, c1.y)
FROM
    group_agg_pk c1
    JOIN group_agg_pk c2 ON c1.x = c2.x
GROUP BY
    c1.w,
    c1.z;

-- Pathkeys, built in a subtree, can be used to optimize GROUP-BY clause
-- ordering.  Also, here we check that it doesn't depend on the initial clause
-- order in the GROUP-BY list.
EXPLAIN (
    COSTS OFF
)
SELECT
    c1.y,
    c1.x
FROM
    group_agg_pk c1
    JOIN group_agg_pk c2 ON c1.x = c2.x
GROUP BY
    c1.y,
    c1.x,
    c2.x;

EXPLAIN (
    COSTS OFF
)
SELECT
    c1.y,
    c1.x
FROM
    group_agg_pk c1
    JOIN group_agg_pk c2 ON c1.x = c2.x
GROUP BY
    c1.y,
    c2.x,
    c1.x;

RESET enable_nestloop;

RESET enable_hashjoin;

DROP TABLE group_agg_pk;

-- Test the case where the ordering of the scan matches the ordering within the
-- aggregate but cannot be found in the group-by list
CREATE TABLE agg_sort_order (
    c1 int PRIMARY KEY,
    c2 int
);

CREATE UNIQUE INDEX agg_sort_order_c2_idx ON agg_sort_order (c2);

INSERT INTO agg_sort_order
SELECT
    i,
    i
FROM
    generate_series(1, 100) i;

ANALYZE agg_sort_order;

EXPLAIN (
    COSTS OFF
)
SELECT
    array_agg(c1 ORDER BY c2),
    c2
FROM
    agg_sort_order
WHERE
    c2 < 100
GROUP BY
    c1
ORDER BY
    2;

DROP TABLE agg_sort_order CASCADE;

DROP TABLE btg;

RESET enable_hashagg;

RESET enable_seqscan;

-- Secondly test the case of a parallel aggregate combiner function
-- returning NULL. For that use normal transition function, but a
-- combiner function returning NULL.
BEGIN;
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

-- test multiple usage of an aggregate whose finalfn returns a R/W datum
BEGIN;
CREATE FUNCTION rwagg_sfunc (x anyarray, y anyarray)
    RETURNS anyarray
    LANGUAGE plpgsql
    IMMUTABLE
    AS $$
BEGIN
    RETURN array_fill(y[1], ARRAY[4]);
END;
$$;
CREATE FUNCTION rwagg_finalfunc (x anyarray)
    RETURNS anyarray
    LANGUAGE plpgsql
    STRICT IMMUTABLE
    AS $$
DECLARE
    res x%TYPE;
BEGIN
    -- assignment is essential for this test, it expands the array to R/W
    res := array_fill(x[1], ARRAY[4]);
    RETURN res;
END;
$$;
CREATE AGGREGATE rwagg (anyarray) (
    STYPE = anyarray,
    SFUNC = rwagg_sfunc,
    FINALFUNC = rwagg_finalfunc
);
CREATE FUNCTION eatarray (x real[])
    RETURNS real[]
    LANGUAGE plpgsql
    STRICT IMMUTABLE
    AS $$
BEGIN
    x[1] := x[1] + 1;
    RETURN x;
END;
$$;
SELECT
    eatarray (rwagg (ARRAY[1.0::real])),
    eatarray (rwagg (ARRAY[1.0::real]));
ROLLBACK;

-- test coverage for aggregate combine/serial/deserial functions
BEGIN;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
SET parallel_leader_participation = OFF;
SET enable_indexonlyscan = OFF;
-- variance(int4) covers numeric_poly_combine
-- sum(int8) covers int8_avg_combine
-- regr_count(float8, float8) covers int8inc_float8_float8 and aggregates with > 1 arg
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    variance(unique1::int4),
    sum(unique1::int8),
    regr_count(unique1::float8, unique1::float8)
FROM (
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1) u;
SELECT
    variance(unique1::int4),
    sum(unique1::int8),
    regr_count(unique1::float8, unique1::float8)
FROM (
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1) u;
-- variance(int8) covers numeric_combine
-- avg(numeric) covers numeric_avg_combine
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    variance(unique1::int8),
    avg(unique1::numeric)
FROM (
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1) u;
SELECT
    variance(unique1::int8),
    avg(unique1::numeric)
FROM (
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk1) u;
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

--
-- Hash Aggregation Spill tests
--
SET enable_groupagg = FALSE;

SET work_mem = '64kB';

SELECT
    unique1,
    count(*),
    sum(twothousand)
FROM
    tenk1
GROUP BY
    unique1
HAVING
    sum(fivethous) > 4975
ORDER BY
    sum(twothousand);

SET work_mem TO DEFAULT;

SET enable_groupagg TO DEFAULT;

--
-- Compare results between plans using sorting and plans using hash
-- aggregation. Force spilling in both cases by setting work_mem low.
--
SET work_mem = '64kB';

CREATE TABLE agg_data_2k AS
SELECT
    g
FROM
    generate_series(0, 1999) g;

ANALYZE agg_data_2k;

CREATE TABLE agg_data_20k AS
SELECT
    g
FROM
    generate_series(0, 19999) g;

ANALYZE agg_data_20k;

-- Produce results with sorting.
SET enable_hashagg = FALSE;

SET jit_above_cost = 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    g % 10000 AS c1,
    sum(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_20k
GROUP BY
    g % 10000;

CREATE TABLE agg_group_1 AS
SELECT
    g % 10000 AS c1,
    sum(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_20k
GROUP BY
    g % 10000;

CREATE TABLE agg_group_2 AS
SELECT
    *
FROM (
    VALUES (100),
        (300),
        (500)) AS r (a),
    LATERAL (
        SELECT
            (g / 2)::numeric AS c1, array_agg(g::numeric) AS c2,
            count(*) AS c3
        FROM
            agg_data_2k
        WHERE
            g < r.a
        GROUP BY
            g / 2) AS s;

SET jit_above_cost TO DEFAULT;

CREATE TABLE agg_group_3 AS
SELECT
    (g / 2)::numeric AS c1,
    sum(7::int4) AS c2,
    count(*) AS c3
FROM
    agg_data_2k
GROUP BY
    g / 2;

CREATE TABLE agg_group_4 AS
SELECT
    (g / 2)::numeric AS c1,
    array_agg(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_2k
GROUP BY
    g / 2;

-- Produce results with hash aggregation
SET enable_hashagg = TRUE;

SET enable_groupagg = FALSE;

SET jit_above_cost = 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    g % 10000 AS c1,
    sum(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_20k
GROUP BY
    g % 10000;

CREATE TABLE agg_hash_1 AS
SELECT
    g % 10000 AS c1,
    sum(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_20k
GROUP BY
    g % 10000;

CREATE TABLE agg_hash_2 AS
SELECT
    *
FROM (
    VALUES (100),
        (300),
        (500)) AS r (a),
    LATERAL (
        SELECT
            (g / 2)::numeric AS c1, array_agg(g::numeric) AS c2,
            count(*) AS c3
        FROM
            agg_data_2k
        WHERE
            g < r.a
        GROUP BY
            g / 2) AS s;

SET jit_above_cost TO DEFAULT;

CREATE TABLE agg_hash_3 AS
SELECT
    (g / 2)::numeric AS c1,
    sum(7::int4) AS c2,
    count(*) AS c3
FROM
    agg_data_2k
GROUP BY
    g / 2;

CREATE TABLE agg_hash_4 AS
SELECT
    (g / 2)::numeric AS c1,
    array_agg(g::numeric) AS c2,
    count(*) AS c3
FROM
    agg_data_2k
GROUP BY
    g / 2;

SET enable_groupagg = TRUE;

SET work_mem TO DEFAULT;

-- Compare group aggregation results to hash aggregation results
(
    SELECT
        *
    FROM
        agg_hash_1
    EXCEPT
    SELECT
        *
    FROM
        agg_group_1)
UNION ALL (
    SELECT
        *
    FROM
        agg_group_1
    EXCEPT
    SELECT
        *
    FROM
        agg_hash_1);

(
    SELECT
        *
    FROM
        agg_hash_2
    EXCEPT
    SELECT
        *
    FROM
        agg_group_2)
UNION ALL (
    SELECT
        *
    FROM
        agg_group_2
    EXCEPT
    SELECT
        *
    FROM
        agg_hash_2);

(
    SELECT
        *
    FROM
        agg_hash_3
    EXCEPT
    SELECT
        *
    FROM
        agg_group_3)
UNION ALL (
    SELECT
        *
    FROM
        agg_group_3
    EXCEPT
    SELECT
        *
    FROM
        agg_hash_3);

(
    SELECT
        *
    FROM
        agg_hash_4
    EXCEPT
    SELECT
        *
    FROM
        agg_group_4)
UNION ALL (
    SELECT
        *
    FROM
        agg_group_4
    EXCEPT
    SELECT
        *
    FROM
        agg_hash_4);

DROP TABLE agg_group_1;

DROP TABLE agg_group_2;

DROP TABLE agg_group_3;

DROP TABLE agg_group_4;

DROP TABLE agg_hash_1;

DROP TABLE agg_hash_2;

DROP TABLE agg_hash_3;

DROP TABLE agg_hash_4;

