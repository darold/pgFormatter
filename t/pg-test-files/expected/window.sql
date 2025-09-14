--
-- WINDOW FUNCTIONS
--
CREATE TEMPORARY TABLE empsalary (
    depname varchar,
    empno bigint,
    salary int,
    enroll_date date
);

INSERT INTO empsalary
VALUES
    ('develop', 10, 5200, '2007-08-01'),
    ('sales', 1, 5000, '2006-10-01'),
    ('personnel', 5, 3500, '2007-12-10'),
    ('sales', 4, 4800, '2007-08-08'),
    ('personnel', 2, 3900, '2006-12-23'),
    ('develop', 7, 4200, '2008-01-01'),
    ('develop', 9, 4500, '2008-01-01'),
    ('sales', 3, 4800, '2007-08-01'),
    ('develop', 8, 6000, '2006-10-01'),
    ('develop', 11, 5200, '2007-08-15');

SELECT
    depname,
    empno,
    salary,
    sum(salary) OVER (PARTITION BY depname)
FROM
    empsalary
ORDER BY
    depname,
    salary;

SELECT
    depname,
    empno,
    salary,
    rank() OVER (PARTITION BY depname ORDER BY salary)
FROM
    empsalary;

-- with GROUP BY
SELECT
    four,
    ten,
    SUM(SUM(four)) OVER (PARTITION BY four),
    AVG(ten)
FROM
    tenk1
GROUP BY
    four,
    ten
ORDER BY
    four,
    ten;

SELECT
    depname,
    empno,
    salary,
    sum(salary) OVER w
FROM empsalary
WINDOW w AS (PARTITION BY depname);

SELECT
    depname,
    empno,
    salary,
    rank() OVER w
FROM empsalary
WINDOW w AS (PARTITION BY depname ORDER BY salary)
ORDER BY
    rank() OVER w;

-- empty window specification
SELECT
    COUNT(*) OVER ()
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    COUNT(*) OVER w
FROM tenk1
WHERE unique2 < 10
WINDOW w AS ();

-- no window operation
SELECT
    four
FROM
    tenk1
WHERE
    FALSE
WINDOW w AS (PARTITION BY ten);

-- cumulative aggregate
SELECT
    sum(four) OVER (PARTITION BY ten ORDER BY unique2) AS sum_1,
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    row_number() OVER (ORDER BY unique2)
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    rank() OVER (PARTITION BY four ORDER BY ten) AS rank_1,
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    dense_rank() OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    percent_rank() OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    cume_dist() OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    ntile(3) OVER (ORDER BY ten, four),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    ntile(NULL) OVER (ORDER BY ten, four),
    ten,
    four
FROM
    tenk1
LIMIT 2;

SELECT
    lag(ten) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    lag(ten, four) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    lag(ten, four, 0) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    lead(ten) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    lead(ten * 2, 1) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    lead(ten * 2, 1, -1) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    first_value(ten) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

-- last_value returns the last row of the frame, which is CURRENT ROW in ORDER BY window.
SELECT
    last_value(four) OVER (ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    last_value(ten) OVER (PARTITION BY four),
    ten,
    four
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        unique2 < 10
    ORDER BY
        four,
        ten) s
ORDER BY
    four,
    ten;

SELECT
    nth_value(ten, four + 1) OVER (PARTITION BY four),
    ten,
    four
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        unique2 < 10
    ORDER BY
        four,
        ten) s;

SELECT
    ten,
    two,
    sum(hundred) AS gsum,
    sum(sum(hundred)) OVER (PARTITION BY two ORDER BY ten) AS wsum
FROM
    tenk1
GROUP BY
    ten,
    two;

SELECT
    count(*) OVER (PARTITION BY four),
    four
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        two = 1) s
WHERE
    unique2 < 10;

SELECT
    (count(*) OVER (PARTITION BY four ORDER BY ten) + sum(hundred) OVER (PARTITION BY four ORDER BY ten))::varchar AS cntsum
FROM
    tenk1
WHERE
    unique2 < 10;

-- opexpr with different windows evaluation.
SELECT
    *
FROM (
    SELECT
        count(*) OVER (PARTITION BY four ORDER BY ten) + sum(hundred) OVER (PARTITION BY two ORDER BY ten) AS total,
        count(*) OVER (PARTITION BY four ORDER BY ten) AS fourcount,
        sum(hundred) OVER (PARTITION BY two ORDER BY ten) AS twosum
    FROM
        tenk1) sub
WHERE
    total <> fourcount + twosum;

SELECT
    avg(four) OVER (PARTITION BY four ORDER BY thousand / 100)
FROM
    tenk1
WHERE
    unique2 < 10;

SELECT
    ten,
    two,
    sum(hundred) AS gsum,
    sum(sum(hundred)) OVER win AS wsum
FROM
    tenk1
GROUP BY ten,
two
WINDOW win AS (PARTITION BY two ORDER BY ten);

-- more than one window with GROUP BY
SELECT
    sum(salary),
    row_number() OVER (ORDER BY depname),
    sum(sum(salary)) OVER (ORDER BY depname DESC)
FROM
    empsalary
GROUP BY
    depname;

-- identical windows with different names
SELECT
    sum(salary) OVER w1,
    count(*) OVER w2
FROM empsalary
WINDOW w1 AS (ORDER BY salary),
w2 AS (
ORDER BY
    salary);

-- subplan
SELECT
    lead(ten, (
            SELECT
                two
            FROM tenk1
            WHERE
                s.unique2 = unique2)) OVER (PARTITION BY four ORDER BY ten)
FROM
    tenk1 s
WHERE
    unique2 < 10;

-- empty table
SELECT
    count(*) OVER (PARTITION BY four)
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        FALSE) s;

-- mixture of agg/wfunc in the same window
SELECT
    sum(salary) OVER w,
    rank() OVER w
FROM empsalary
WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);

-- strict aggs
SELECT
    empno,
    depname,
    salary,
    bonus,
    depadj,
    MIN(bonus) OVER (ORDER BY empno),
    MAX(depadj) OVER ()
FROM (
    SELECT
        *,
        CASE WHEN enroll_date < '2008-01-01' THEN
            2008 - extract(YEAR FROM enroll_date)
        END * 500 AS bonus,
        CASE WHEN AVG(salary) OVER (PARTITION BY depname) < salary THEN
            200
        END AS depadj
    FROM
        empsalary) s;

-- window function over ungrouped agg over empty row set (bug before 9.1)
SELECT
    SUM(COUNT(f1)) OVER ()
FROM
    int4_tbl
WHERE
    f1 = 42;

-- window function with ORDER BY an expression involving aggregates (9.1 bug)
SELECT
    ten,
    sum(unique1) + sum(unique2) AS res,
    rank() OVER (ORDER BY sum(unique1) + sum(unique2)) AS rank
FROM
    tenk1
GROUP BY
    ten
ORDER BY
    ten;

-- window and aggregate with GROUP BY expression (9.2 bug)
EXPLAIN (
    COSTS OFF
)
SELECT
    first_value(max(x)) OVER (),
    y
FROM (
    SELECT
        unique1 AS x,
        ten + four AS y
    FROM
        tenk1) ss
GROUP BY
    y;

-- test non-default frame specifications
SELECT
    four,
    ten,
    sum(ten) OVER (PARTITION BY four ORDER BY ten),
    last_value(ten) OVER (PARTITION BY four ORDER BY ten)
FROM ( SELECT DISTINCT
        ten,
        four
    FROM
        tenk1) ss;

SELECT
    four,
    ten,
    sum(ten) OVER (PARTITION BY four ORDER BY ten RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    last_value(ten) OVER (PARTITION BY four ORDER BY ten RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM ( SELECT DISTINCT
        ten,
        four
    FROM
        tenk1) ss;

SELECT
    four,
    ten,
    sum(ten) OVER (PARTITION BY four ORDER BY ten RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
    last_value(ten) OVER (PARTITION BY four ORDER BY ten RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
FROM ( SELECT DISTINCT
        ten,
        four
    FROM
        tenk1) ss;

SELECT
    four,
    ten / 4 AS two,
    sum(ten / 4) OVER (PARTITION BY four ORDER BY ten / 4 RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    last_value(ten / 4) OVER (PARTITION BY four ORDER BY ten / 4 RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM ( SELECT DISTINCT
        ten,
        four
    FROM
        tenk1) ss;

SELECT
    four,
    ten / 4 AS two,
    sum(ten / 4) OVER (PARTITION BY four ORDER BY ten / 4 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    last_value(ten / 4) OVER (PARTITION BY four ORDER BY ten / 4 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM ( SELECT DISTINCT
        ten,
        four
    FROM
        tenk1) ss;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE NO OTHERS),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    first_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    first_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    first_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    last_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    last_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    last_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 2 PRECEDING AND 1 PRECEDING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (w RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10
WINDOW w AS (ORDER BY four);

SELECT
    sum(unique1) OVER (w RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10
WINDOW w AS (ORDER BY four);

SELECT
    sum(unique1) OVER (w RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10
WINDOW w AS (ORDER BY four);

SELECT
    sum(unique1) OVER (w RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10
WINDOW w AS (ORDER BY four);

SELECT
    first_value(unique1) OVER w,
    nth_value(unique1, 2) OVER w AS nth_2,
    last_value(unique1) OVER w,
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10
WINDOW w AS (ORDER BY four RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING);

SELECT
    sum(unique1) OVER (ORDER BY unique1 ROWS (
        SELECT
            unique1
        FROM tenk1 ORDER BY unique1
    LIMIT 1) + 1 PRECEDING),
unique1
FROM
    tenk1
WHERE
    unique1 < 10;

CREATE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

CREATE OR REPLACE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

CREATE OR REPLACE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

CREATE OR REPLACE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

CREATE OR REPLACE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING EXCLUDE NO OTHERS) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

CREATE OR REPLACE TEMP VIEW v_window AS
SELECT
    i,
    sum(i) OVER (ORDER BY i GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS sum_rows
FROM
    generate_series(1, 10) i;

SELECT
    *
FROM
    v_window;

SELECT
    pg_get_viewdef('v_window');

DROP VIEW v_window;

CREATE TEMP VIEW v_window AS
SELECT
    i,
    min(i) OVER (ORDER BY i RANGE BETWEEN '1 day' PRECEDING AND '10 days' FOLLOWING) AS min_i
FROM
    generate_series(now(), now() + '100 days'::interval, '1 hour') i;

SELECT
    pg_get_viewdef('v_window');

-- RANGE offset PRECEDING/FOLLOWING tests
SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four DESC RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING
        EXCLUDE NO OTHERS),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING
        EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING
        EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 1::int2 PRECEDING
        EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 6::int2 FOLLOWING EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four RANGE BETWEEN 2::int8 PRECEDING AND 6::int2 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY four ORDER BY unique1 RANGE BETWEEN 5::int8 PRECEDING AND 6::int2 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY four ORDER BY unique1 RANGE BETWEEN 5::int8 PRECEDING AND 6::int2 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(salary) OVER (ORDER BY enroll_date RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY enroll_date DESC RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY enroll_date DESC RANGE BETWEEN '1 year'::interval FOLLOWING AND '1 year'::interval FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY enroll_date RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE CURRENT ROW),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY enroll_date RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE GROUP),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY enroll_date RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING),
    lead(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING),
    nth_value(salary, 1) OVER (ORDER BY salary RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING),
    salary
FROM
    empsalary;

SELECT
    last_value(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING),
    lag(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING),
    salary
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 FOLLOWING AND 3000 FOLLOWING EXCLUDE CURRENT ROW),
    lead(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 FOLLOWING AND 3000 FOLLOWING EXCLUDE TIES),
    nth_value(salary, 1) OVER (ORDER BY salary RANGE BETWEEN 1000 FOLLOWING AND 3000 FOLLOWING EXCLUDE TIES),
    salary
FROM
    empsalary;

SELECT
    last_value(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 FOLLOWING AND 3000 FOLLOWING EXCLUDE GROUP),
    lag(salary) OVER (ORDER BY salary RANGE BETWEEN 1000 FOLLOWING AND 3000 FOLLOWING EXCLUDE GROUP),
    salary
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE TIES),
    last_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE TIES),
    last_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE GROUP),
    last_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE GROUP),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE CURRENT ROW),
    last_value(salary) OVER (ORDER BY enroll_date RANGE BETWEEN UNBOUNDED PRECEDING AND '1 year'::interval FOLLOWING EXCLUDE CURRENT ROW),
    salary,
    enroll_date
FROM
    empsalary;

-- RANGE offset PRECEDING/FOLLOWING with null values
SELECT
    x,
    y,
    first_value(y) OVER w,
    last_value(y) OVER w
FROM (
SELECT
    x, x AS y
FROM
    generate_series(1, 5) AS x
UNION ALL
SELECT
    NULL,
    42
UNION ALL
SELECT
    NULL,
    43) ss
WINDOW w AS (ORDER BY x ASC nulls FIRST RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING);

SELECT
    x,
    y,
    first_value(y) OVER w,
    last_value(y) OVER w
FROM (
SELECT
    x, x AS y
FROM
    generate_series(1, 5) AS x
UNION ALL
SELECT
    NULL,
    42
UNION ALL
SELECT
    NULL,
    43) ss
WINDOW w AS (ORDER BY x ASC nulls LAST RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING);

SELECT
    x,
    y,
    first_value(y) OVER w,
    last_value(y) OVER w
FROM (
SELECT
    x, x AS y
FROM
    generate_series(1, 5) AS x
UNION ALL
SELECT
    NULL,
    42
UNION ALL
SELECT
    NULL,
    43) ss
WINDOW w AS (ORDER BY x DESC nulls FIRST RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING);

SELECT
    x,
    y,
    first_value(y) OVER w,
    last_value(y) OVER w
FROM (
SELECT
    x, x AS y
FROM
    generate_series(1, 5) AS x
UNION ALL
SELECT
    NULL,
    42
UNION ALL
SELECT
    NULL,
    43) ss
WINDOW w AS (ORDER BY x DESC nulls LAST RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING);

-- Check overflow behavior for various integer sizes
SELECT
    x,
    last_value(x) OVER (ORDER BY x::smallint RANGE BETWEEN CURRENT ROW AND 2147450884 FOLLOWING)
FROM
    generate_series(32764, 32766) x;

SELECT
    x,
    last_value(x) OVER (ORDER BY x::smallint DESC RANGE BETWEEN CURRENT ROW AND 2147450885 FOLLOWING)
FROM
    generate_series(-32766, -32764) x;

SELECT
    x,
    last_value(x) OVER (ORDER BY x RANGE BETWEEN CURRENT ROW AND 4 FOLLOWING)
FROM
    generate_series(2147483644, 2147483646) x;

SELECT
    x,
    last_value(x) OVER (ORDER BY x DESC RANGE BETWEEN CURRENT ROW AND 5 FOLLOWING)
FROM
    generate_series(-2147483646, -2147483644) x;

SELECT
    x,
    last_value(x) OVER (ORDER BY x RANGE BETWEEN CURRENT ROW AND 4 FOLLOWING)
FROM
    generate_series(9223372036854775804, 9223372036854775806) x;

SELECT
    x,
    last_value(x) OVER (ORDER BY x DESC RANGE BETWEEN CURRENT ROW AND 5 FOLLOWING)
FROM
    generate_series(-9223372036854775806, -9223372036854775804) x;

-- Test in_range for other numeric datatypes
CREATE temp TABLE numerics (
    id int,
    f_float4 float4,
    f_float8 float8,
    f_numeric numeric
);

INSERT INTO numerics
VALUES
    (0, '-infinity', '-infinity', '-1000'), -- numeric type lacks infinities
    (1, -3, -3, -3),
    (2, -1, -1, -1),
    (3, 0, 0, 0),
    (4, 1.1, 1.1, 1.1),
    (5, 1.12, 1.12, 1.12),
    (6, 2, 2, 2),
    (7, 100, 100, 100),
    (8, 'infinity', 'infinity', '1000'),
    (9, 'NaN', 'NaN', 'NaN');

SELECT
    id,
    f_float4,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING);

SELECT
    id,
    f_float4,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 1 PRECEDING AND 1.1::float4 FOLLOWING);

SELECT
    id,
    f_float4,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 'inf' PRECEDING AND 'inf' FOLLOWING);

SELECT
    id,
    f_float4,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 1.1 PRECEDING AND 'NaN' FOLLOWING);

-- error, NaN disallowed
SELECT
    id,
    f_float8,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING);

SELECT
    id,
    f_float8,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 1 PRECEDING AND 1.1::float8 FOLLOWING);

SELECT
    id,
    f_float8,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 'inf' PRECEDING AND 'inf' FOLLOWING);

SELECT
    id,
    f_float8,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 1.1 PRECEDING AND 'NaN' FOLLOWING);

-- error, NaN disallowed
SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING);

SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 1 PRECEDING AND 1.1::numeric FOLLOWING);

SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 1 PRECEDING AND 1.1::float8 FOLLOWING);

-- currently unsupported
SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 1.1 PRECEDING AND 'NaN' FOLLOWING);

-- error, NaN disallowed
-- Test in_range for other datetime datatypes
CREATE temp TABLE datetimes (
    id int,
    f_time time,
    f_timetz timetz,
    f_interval interval,
    f_timestamptz timestamptz,
    f_timestamp timestamp
);

INSERT INTO datetimes
VALUES
    (1, '11:00', '11:00 BST', '1 year', '2000-10-19 10:23:54+01', '2000-10-19 10:23:54'),
    (2, '12:00', '12:00 BST', '2 years', '2001-10-19 10:23:54+01', '2001-10-19 10:23:54'),
    (3, '13:00', '13:00 BST', '3 years', '2001-10-19 10:23:54+01', '2001-10-19 10:23:54'),
    (4, '14:00', '14:00 BST', '4 years', '2002-10-19 10:23:54+01', '2002-10-19 10:23:54'),
    (5, '15:00', '15:00 BST', '5 years', '2003-10-19 10:23:54+01', '2003-10-19 10:23:54'),
    (6, '15:00', '15:00 BST', '5 years', '2004-10-19 10:23:54+01', '2004-10-19 10:23:54'),
    (7, '17:00', '17:00 BST', '7 years', '2005-10-19 10:23:54+01', '2005-10-19 10:23:54'),
    (8, '18:00', '18:00 BST', '8 years', '2006-10-19 10:23:54+01', '2006-10-19 10:23:54'),
    (9, '19:00', '19:00 BST', '9 years', '2007-10-19 10:23:54+01', '2007-10-19 10:23:54'),
    (10, '20:00', '20:00 BST', '10 years', '2008-10-19 10:23:54+01', '2008-10-19 10:23:54');

SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time RANGE BETWEEN '70 min'::interval PRECEDING AND '2 hours'::interval FOLLOWING);

SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time DESC RANGE BETWEEN '70 min' PRECEDING AND '2 hours' FOLLOWING);

SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz RANGE BETWEEN '70 min'::interval PRECEDING AND '2 hours'::interval FOLLOWING);

SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz DESC RANGE BETWEEN '70 min' PRECEDING AND '2 hours' FOLLOWING);

SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING);

SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval DESC RANGE BETWEEN '1 year' PRECEDING AND '1 year' FOLLOWING);

SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING);

SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz DESC RANGE BETWEEN '1 year' PRECEDING AND '1 year' FOLLOWING);

SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp RANGE BETWEEN '1 year'::interval PRECEDING AND '1 year'::interval FOLLOWING);

SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp DESC RANGE BETWEEN '1 year' PRECEDING AND '1 year' FOLLOWING);

-- RANGE offset PRECEDING/FOLLOWING error cases
SELECT
    sum(salary) OVER (ORDER BY enroll_date, salary RANGE BETWEEN '1 year'::interval PRECEDING AND '2 years'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (RANGE BETWEEN '1 year'::interval PRECEDING AND '2 years'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    sum(salary) OVER (ORDER BY depname RANGE BETWEEN '1 year'::interval PRECEDING AND '2 years'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    max(enroll_date) OVER (ORDER BY enroll_date RANGE BETWEEN 1 PRECEDING AND 2 FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    max(enroll_date) OVER (ORDER BY salary RANGE BETWEEN -1 PRECEDING AND 2 FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    max(enroll_date) OVER (ORDER BY salary RANGE BETWEEN 1 PRECEDING AND -2 FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    max(enroll_date) OVER (ORDER BY salary RANGE BETWEEN '1 year'::interval PRECEDING AND '2 years'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    max(enroll_date) OVER (ORDER BY enroll_date RANGE BETWEEN '1 year'::interval PRECEDING AND '-2 years'::interval FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

-- GROUPS tests
SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 1 PRECEDING AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN UNBOUNDED PRECEDING AND 2 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 2 PRECEDING AND 1 PRECEDING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 2 PRECEDING AND 1 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 0 PRECEDING AND 0 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 2 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 2 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 2 PRECEDING AND 1 FOLLOWING EXCLUDE TIES),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY ten ORDER BY four GROUPS BETWEEN 0 PRECEDING AND 0 FOLLOWING),
    unique1,
    four,
    ten
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY ten ORDER BY four GROUPS BETWEEN 0 PRECEDING AND 0 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four,
    ten
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY ten ORDER BY four GROUPS BETWEEN 0 PRECEDING AND 0 FOLLOWING EXCLUDE GROUP),
    unique1,
    four,
    ten
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (PARTITION BY ten ORDER BY four GROUPS BETWEEN 0 PRECEDING AND 0 FOLLOWING EXCLUDE TIES),
    unique1,
    four,
    ten
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    lead(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    nth_value(salary, 1) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    last_value(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    lag(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    first_value(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 FOLLOWING AND 3 FOLLOWING EXCLUDE CURRENT ROW),
    lead(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 FOLLOWING AND 3 FOLLOWING EXCLUDE TIES),
    nth_value(salary, 1) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 FOLLOWING AND 3 FOLLOWING EXCLUDE TIES),
    salary,
    enroll_date
FROM
    empsalary;

SELECT
    last_value(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 FOLLOWING AND 3 FOLLOWING EXCLUDE GROUP),
    lag(salary) OVER (ORDER BY enroll_date GROUPS BETWEEN 1 FOLLOWING AND 3 FOLLOWING EXCLUDE GROUP),
    salary,
    enroll_date
FROM
    empsalary;

-- Show differences in offset interpretation between ROWS, RANGE, and GROUPS
WITH cte (
    x
) AS (
    SELECT
        *
    FROM
        generate_series(1, 35, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

WITH cte (
    x
) AS (
    SELECT
        *
    FROM
        generate_series(1, 35, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING);

WITH cte (
    x
) AS (
    SELECT
        *
    FROM
        generate_series(1, 35, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

WITH cte (
    x
) AS (
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        *
    FROM
        generate_series(5, 49, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

WITH cte (
    x
) AS (
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        *
    FROM
        generate_series(5, 49, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING);

WITH cte (
    x
) AS (
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        1
    UNION ALL
    SELECT
        *
    FROM
        generate_series(5, 49, 2))
SELECT
    x,
    (sum(x) OVER w)
    FROM
        cte
WINDOW w AS (ORDER BY x GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

-- with UNION
SELECT
    count(*) OVER (PARTITION BY four)
FROM (
    SELECT
        *
    FROM
        tenk1
    UNION ALL
    SELECT
        *
    FROM
        tenk2) s
LIMIT 0;

-- check some degenerate cases
CREATE temp TABLE t1 (
    f1 int,
    f2 int8
);

INSERT INTO t1
VALUES
    (1, 1),
    (1, 2),
    (2, 2);

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

-- error, must have order by
EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 ORDER BY f2 RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 ORDER BY f2 RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1, f1 ORDER BY f2 RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1, f2 ORDER BY f2 RANGE BETWEEN 1 FOLLOWING AND 2 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

-- error, must have order by
EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 ORDER BY f2 GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1 ORDER BY f2 GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1, f1 ORDER BY f2 GROUPS BETWEEN 2 PRECEDING AND 1 PRECEDING)
FROM
    t1
WHERE
    f1 = f2;

SELECT
    f1,
    sum(f1) OVER (PARTITION BY f1, f2 ORDER BY f2 GROUPS BETWEEN 1 FOLLOWING AND 2 FOLLOWING)
FROM
    t1
WHERE
    f1 = f2;

-- ordering by a non-integer constant is allowed
SELECT
    rank() OVER (ORDER BY length('abc'));

-- can't order by another window function
SELECT
    rank() OVER (ORDER BY rank() OVER (ORDER BY random()));

-- some other errors
SELECT
    *
FROM
    empsalary
WHERE
    row_number() OVER (ORDER BY salary) < 10;

SELECT
    *
FROM
    empsalary
    INNER JOIN tenk1 ON row_number() OVER (ORDER BY salary) < 10;

SELECT
    rank() OVER (ORDER BY 1),
    count(*)
FROM
    empsalary
GROUP BY
    1;

SELECT
    *
FROM
    rank() OVER (ORDER BY random());

DELETE FROM empsalary
WHERE (rank() OVER (ORDER BY random())) > 10;

DELETE FROM empsalary
RETURNING
    rank() OVER (ORDER BY random());

SELECT
    count(*) OVER w
FROM tenk1
WINDOW w AS (ORDER BY unique1),
w AS (
ORDER BY
    unique1);

SELECT
    rank() OVER (PARTITION BY four, ORDER BY ten)
FROM
    tenk1;

SELECT
    count() OVER ()
FROM
    tenk1;

SELECT
    generate_series(1, 100) OVER ()
FROM
    empsalary;

SELECT
    ntile(0) OVER (ORDER BY ten),
    ten,
    four
FROM
    tenk1;

SELECT
    nth_value(four, 0) OVER (ORDER BY ten),
    ten,
    four
FROM
    tenk1;

-- filter
SELECT
    sum(salary),
    row_number() OVER (ORDER BY depname),
    sum(sum(salary) FILTER (WHERE enroll_date > '2007-01-01')) FILTER (WHERE depname <> 'sales') OVER (ORDER BY depname DESC) AS "filtered_sum",
    depname
FROM
    empsalary
GROUP BY
    depname;

-- Test pushdown of quals into a subquery containing window functions
-- pushdown is safe because all PARTITION BY clauses include depname:
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        depname,
        sum(salary) OVER (PARTITION BY depname) depsalary,
        min(salary) OVER (PARTITION BY depname || 'A', depname) depminsalary
    FROM empsalary) emp
WHERE
    depname = 'sales';

-- pushdown is unsafe because there's a PARTITION BY clause without depname:
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        depname,
        sum(salary) OVER (PARTITION BY enroll_date) enroll_salary,
        min(salary) OVER (PARTITION BY depname) depminsalary
    FROM empsalary) emp
WHERE
    depname = 'sales';

-- Test Sort node collapsing
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        depname,
        sum(salary) OVER (PARTITION BY depname ORDER BY empno) depsalary,
        min(salary) OVER (PARTITION BY depname, empno ORDER BY enroll_date) depminsalary
    FROM empsalary) emp
WHERE
    depname = 'sales';

-- Test Sort node reordering
EXPLAIN (
    COSTS OFF
)
SELECT
    lead(1) OVER (PARTITION BY depname ORDER BY salary, enroll_date),
    lag(1) OVER (PARTITION BY depname ORDER BY salary, enroll_date, empno)
FROM
    empsalary;

-- cleanup
DROP TABLE empsalary;

-- test user-defined window function with named args and default args
CREATE FUNCTION nth_value_def (val anyelement, n integer = 1)
    RETURNS anyelement
    LANGUAGE internal
WINDOW IMMUTABLE STRICT
AS 'window_nth_value';

SELECT
    nth_value_def (n := 2, val := ten) OVER (PARTITION BY four),
    ten,
    four
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        unique2 < 10
    ORDER BY
        four,
        ten) s;

SELECT
    nth_value_def (ten) OVER (PARTITION BY four),
    ten,
    four
FROM (
    SELECT
        *
    FROM
        tenk1
    WHERE
        unique2 < 10
    ORDER BY
        four,
        ten) s;

--
-- Test the basic moving-aggregate machinery
--
-- create aggregates that record the series of transform calls (these are
-- intentionally not true inverses)
CREATE FUNCTION logging_sfunc_nonstrict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        COALESCE($1, '') || '*' || quote_nullable($2)
$$
LANGUAGE SQL
IMMUTABLE;

CREATE FUNCTION logging_msfunc_nonstrict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        COALESCE($1, '') || '+' || quote_nullable($2)
$$
LANGUAGE SQL
IMMUTABLE;

CREATE FUNCTION logging_minvfunc_nonstrict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        $1 || '-' || quote_nullable($2)
$$
LANGUAGE SQL
IMMUTABLE;

CREATE AGGREGATE logging_agg_nonstrict (anyelement) (
    STYPE = text,
    SFUNC = logging_sfunc_nonstrict,
    MSTYPE = text,
    MSFUNC = logging_msfunc_nonstrict,
    MINVFUNC = logging_minvfunc_nonstrict
);

CREATE AGGREGATE logging_agg_nonstrict_initcond (anyelement) (
    STYPE = text,
    SFUNC = logging_sfunc_nonstrict,
    MSTYPE = text,
    MSFUNC = logging_msfunc_nonstrict,
    MINVFUNC = logging_minvfunc_nonstrict,
    INITCOND = 'I',
    MINITCOND = 'MI'
);

CREATE FUNCTION logging_sfunc_strict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        $1 || '*' || quote_nullable($2)
$$
LANGUAGE SQL
STRICT IMMUTABLE;

CREATE FUNCTION logging_msfunc_strict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        $1 || '+' || quote_nullable($2)
$$
LANGUAGE SQL
STRICT IMMUTABLE;

CREATE FUNCTION logging_minvfunc_strict (text, anyelement)
    RETURNS text
    AS $$
    SELECT
        $1 || '-' || quote_nullable($2)
$$
LANGUAGE SQL
STRICT IMMUTABLE;

CREATE AGGREGATE logging_agg_strict (text) (
    STYPE = text,
    SFUNC = logging_sfunc_strict,
    MSTYPE = text,
    MSFUNC = logging_msfunc_strict,
    MINVFUNC = logging_minvfunc_strict
);

CREATE AGGREGATE logging_agg_strict_initcond (anyelement) (
    STYPE = text,
    SFUNC = logging_sfunc_strict,
    MSTYPE = text,
    MSFUNC = logging_msfunc_strict,
    MINVFUNC = logging_minvfunc_strict,
    INITCOND = 'I',
    MINITCOND = 'MI'
);

-- test strict and non-strict cases
SELECT
    p::text || ',' || i::text || ':' || COALESCE(v::text, 'NULL') AS row,
    logging_agg_nonstrict (v) OVER wnd AS nstrict,
    logging_agg_nonstrict_initcond (v) OVER wnd AS nstrict_init,
    logging_agg_strict (v::text) OVER wnd AS strict,
    logging_agg_strict_initcond (v) OVER wnd AS strict_init
FROM (
    VALUES (1, 1, NULL),
        (1, 2, 'a'),
        (1, 3, 'b'),
        (1, 4, NULL),
        (1, 5, NULL),
        (1, 6, 'c'),
        (2, 1, NULL),
        (2, 2, 'x'),
        (3, 1, 'z')) AS t (p, i, v)
    WINDOW wnd AS (PARTITION BY P ORDER BY i ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
ORDER BY
    p,
    i;

-- and again, but with filter
SELECT
    p::text || ',' || i::text || ':' || CASE WHEN f THEN
        COALESCE(v::text, 'NULL')
    ELSE
        '-'
    END AS row,
    logging_agg_nonstrict (v) FILTER (WHERE f) OVER wnd AS nstrict_filt,
    logging_agg_nonstrict_initcond (v) FILTER (WHERE f) OVER wnd AS nstrict_init_filt,
    logging_agg_strict (v::text) FILTER (WHERE f) OVER wnd AS strict_filt,
    logging_agg_strict_initcond (v) FILTER (WHERE f) OVER wnd AS strict_init_filt
FROM (
    VALUES (1, 1, TRUE, NULL),
        (1, 2, FALSE, 'a'),
        (1, 3, TRUE, 'b'),
        (1, 4, FALSE, NULL),
        (1, 5, FALSE, NULL),
        (1, 6, FALSE, 'c'),
        (2, 1, FALSE, NULL),
        (2, 2, TRUE, 'x'),
        (3, 1, TRUE, 'z')) AS t (p, i, f, v)
    WINDOW wnd AS (PARTITION BY p ORDER BY i ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
ORDER BY
    p,
    i;

-- test that volatile arguments disable moving-aggregate mode
SELECT
    i::text || ':' || COALESCE(v::text, 'NULL') AS row,
    logging_agg_strict (v::text) OVER wnd AS inverse,
    logging_agg_strict (v::text || CASE WHEN random() < 0 THEN
            '?'
        ELSE
            ''
        END) OVER wnd AS noinverse
FROM (
    VALUES (1, 'a'),
        (2, 'b'),
        (3, 'c')) AS t (i, v)
    WINDOW wnd AS (ORDER BY i ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
ORDER BY
    i;

SELECT
    i::text || ':' || COALESCE(v::text, 'NULL') AS row,
    logging_agg_strict (v::text) FILTER (WHERE TRUE) OVER wnd AS inverse,
    logging_agg_strict (v::text) FILTER (WHERE random() >= 0) OVER wnd AS noinverse
FROM (
    VALUES (1, 'a'),
        (2, 'b'),
        (3, 'c')) AS t (i, v)
    WINDOW wnd AS (ORDER BY i ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
ORDER BY
    i;

-- test that non-overlapping windows don't use inverse transitions
SELECT
    logging_agg_strict (v::text) OVER wnd
FROM (
    VALUES (1, 'a'),
    (2, 'b'),
(3, 'c')) AS t (i, v)
    WINDOW wnd AS (ORDER BY i ROWS BETWEEN CURRENT ROW AND CURRENT ROW)
ORDER BY
    i;

-- test that returning NULL from the inverse transition functions
-- restarts the aggregation from scratch. The second aggregate is supposed
-- to test cases where only some aggregates restart, the third one checks
-- that one aggregate restarting doesn't cause others to restart.
CREATE FUNCTION sum_int_randrestart_minvfunc (int4, int4)
    RETURNS int4
    AS $$
    SELECT
        CASE WHEN random() < 0.2 THEN
            NULL
        ELSE
            $1 - $2
        END
$$
LANGUAGE SQL
STRICT;

CREATE AGGREGATE sum_int_randomrestart (int4) (
    STYPE = int4,
    SFUNC = int4pl,
    MSTYPE = int4,
    MSFUNC = int4pl,
    MINVFUNC = sum_int_randrestart_minvfunc
);

WITH vs AS (
    SELECT
        i,
        (random() * 100)::int4 AS v
    FROM
        generate_series(1, 100) AS i
),
sum_following AS (
    SELECT
        i,
        SUM(v) OVER (ORDER BY i DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS s
    FROM
        vs
)
SELECT DISTINCT
    sum_following.s = sum_int_randomrestart (v) OVER fwd AS eq1,
    - sum_following.s = sum_int_randomrestart (- v) OVER fwd AS eq2,
    100 * 3 + (vs.i - 1) * 3 = length(logging_agg_nonstrict (''::text) OVER fwd) AS eq3
FROM
    vs
    JOIN sum_following ON sum_following.i = vs.i
WINDOW fwd AS (ORDER BY vs.i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING);

--
-- Test various built-in aggregates that have moving-aggregate support
--
-- test inverse transition functions handle NULLs properly
SELECT
    i,
    AVG(v::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    AVG(v::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    AVG(v::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    AVG(v::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1.5),
        (2, 2.5),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    AVG(v::interval) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, '1 sec'),
        (2, '2 sec'),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::money) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, '1.10'),
        (2, '2.20'),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::interval) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, '1 sec'),
        (2, '2 sec'),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1.1),
        (2, 2.2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    SUM(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1.01),
        (2, 2),
        (3, 3)) v (i, n);

SELECT
    i,
    COUNT(v) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    COUNT(*) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    VAR_POP(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_POP(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_POP(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_POP(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_SAMP(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_SAMP(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_SAMP(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VAR_SAMP(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VARIANCE(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VARIANCE(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VARIANCE(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    VARIANCE(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    STDDEV_POP(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_POP(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_POP(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_POP(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_SAMP(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_SAMP(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_SAMP(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV_SAMP(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (1, NULL),
        (2, 600),
        (3, 470),
        (4, 170),
        (5, 430),
        (6, 300)) r (i, n);

SELECT
    STDDEV(n::bigint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (0, NULL),
        (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    STDDEV(n::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (0, NULL),
        (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    STDDEV(n::smallint) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (0, NULL),
        (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

SELECT
    STDDEV(n::numeric) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM (
    VALUES (0, NULL),
        (1, 600),
        (2, 470),
        (3, 170),
        (4, 430),
        (5, 300)) r (i, n);

-- test that inverse transition functions work with various frame options
SELECT
    i,
    SUM(v::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND CURRENT ROW)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::int) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, NULL),
        (4, NULL)) t (i, v);

SELECT
    i,
    SUM(v::int) OVER (ORDER BY i ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM (
    VALUES (1, 1),
        (2, 2),
        (3, 3),
        (4, 4)) t (i, v);

-- ensure aggregate over numeric properly recovers from NaN values
SELECT
    a,
    b,
    SUM(b) OVER (ORDER BY A ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
FROM (
    VALUES (1, 1::numeric),
        (2, 2),
        (3, 'NaN'),
        (4, 3),
        (5, 4)) t (a, b);

-- It might be tempting for someone to add an inverse trans function for
-- float and double precision. This should not be done as it can give incorrect
-- results. This test should fail if anyone ever does this without thinking too
-- hard about it.
SELECT
    to_char(SUM(n::float8) OVER (ORDER BY i ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING), '999999999999999999999D9')
FROM (
    VALUES (1, 1e20),
        (2, 1)) n (i, n);

SELECT
    i,
    b,
    bool_and(b) OVER w,
    bool_or(b) OVER w
FROM (
    VALUES (1, TRUE),
    (2, TRUE),
(3, FALSE),
(4, FALSE),
(5, TRUE)) v (i, b)
    WINDOW w AS (ORDER BY i ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING);

