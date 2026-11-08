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
    lag(ten, four, 0.7) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10
ORDER BY
    four,
    ten;

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
    lead(ten * 2, 1, -1.4) OVER (PARTITION BY four ORDER BY ten),
    ten,
    four
FROM
    tenk1
WHERE
    unique2 < 10
ORDER BY
    four,
    ten;

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

-- window functions returning pass-by-ref values from different rows
SELECT
    x,
    lag(x, 1) OVER (ORDER BY x),
    lead(x, 3) OVER (ORDER BY x)
FROM (
    SELECT
        x::numeric AS x
    FROM
        generate_series(1, 10) x);

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

-- test overflow frame specifications
SELECT
    sum(unique1) OVER (ROWS BETWEEN CURRENT ROW AND 9223372036854775807 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ROWS BETWEEN 9223372036854775807 FOLLOWING AND 1 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    last_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 9223372036854775807 FOLLOWING EXCLUDE CURRENT ROW),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

-- These test GROUPS mode with an offset large enough to cause overflow when
-- added to currentgroup.  Although the overflow doesn't produce visibly wrong
-- results (due to the incremental nature of group pointer advancement), we
-- still need to protect against it as signed integer overflow is undefined
-- behavior in C.
SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN CURRENT ROW AND 9223372036854775807 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

SELECT
    sum(unique1) OVER (ORDER BY four GROUPS BETWEEN 9223372036854775807 FOLLOWING AND UNBOUNDED FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

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

-- There is a syntactic ambiguity in the SQL standard.  Since
-- UNBOUNDED is a non-reserved word, it could be the name of a
-- function parameter and be used as an expression.  There is a
-- grammar hack to resolve such cases as the keyword.  The following
-- tests record this behavior.
CREATE FUNCTION unbounded_syntax_test1a (x int)
    RETURNS TABLE (
        a int,
        b int,
        c int)
    LANGUAGE SQL
BEGIN ATOMIC
    SELECT
        sum(unique1) OVER (ROWS BETWEEN x PRECEDING AND x FOLLOWING),
        unique1,
        four
    FROM
        tenk1
    WHERE
        unique1 < 10;
END;
CREATE FUNCTION unbounded_syntax_test1b (x int)
    RETURNS TABLE (
        a int,
        b int,
        c int)
    LANGUAGE SQL
    AS $$
    SELECT
        sum(unique1) OVER (ROWS BETWEEN x PRECEDING AND x FOLLOWING),
        unique1,
        four
    FROM
        tenk1
    WHERE
        unique1 < 10;
$$;
-- These will apply the argument to the window specification inside the function.
SELECT
    *
FROM
    unbounded_syntax_test1a (2);
SELECT
    *
FROM
    unbounded_syntax_test1b (2);
CREATE FUNCTION unbounded_syntax_test2a (UNBOUNDED int)
    RETURNS TABLE (
        a int,
        b int,
        c int)
    LANGUAGE SQL
BEGIN ATOMIC
    SELECT
        sum(unique1) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
        unique1,
        four
    FROM
        tenk1
    WHERE
        unique1 < 10;
END;
CREATE FUNCTION unbounded_syntax_test2b (UNBOUNDED int)
    RETURNS TABLE (
        a int,
        b int,
        c int)
    LANGUAGE SQL
    AS $$
    SELECT
        sum(unique1) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
        unique1,
        four
    FROM
        tenk1
    WHERE
        unique1 < 10;
$$;
-- These will not apply the argument but instead treat UNBOUNDED as a keyword.
SELECT
    *
FROM
    unbounded_syntax_test2a (2);
SELECT
    *
FROM
    unbounded_syntax_test2b (2);
DROP FUNCTION unbounded_syntax_test1a, unbounded_syntax_test1b, unbounded_syntax_test2a, unbounded_syntax_test2b;
-- Other tests with token UNBOUNDED in potentially problematic position
CREATE FUNCTION UNBOUNDED (x int)
    RETURNS int
    LANGUAGE SQL
    IMMUTABLE RETURN x;
SELECT
    sum(unique1) OVER (ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;
SELECT
    sum(unique1) OVER (ROWS BETWEEN UNBOUNDED (1) PRECEDING AND UNBOUNDED (1) FOLLOWING),
unique1,
four
FROM
    tenk1
WHERE
    unique1 < 10;
SELECT
    sum(unique1) OVER (ROWS BETWEEN unbounded.x PRECEDING AND unbounded.x FOLLOWING),
    unique1,
    four
FROM
    tenk1,
    (
        VALUES (1)) AS unbounded (x)
WHERE
    unique1 < 10;
DROP FUNCTION UNBOUNDED;
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
SELECT
    x,
    lead(x, -2147483648) OVER w AS respect_nulls,
    lead(x, -2147483648) ignore nulls OVER w AS ignore_nulls
FROM (
    VALUES (1),
        (2)) AS t (x)
    WINDOW w AS (ORDER BY x);
SELECT
    x,
    lag(x, -2147483648) OVER w AS respect_nulls,
    lag(x, -2147483648) ignore nulls OVER w AS ignore_nulls
FROM (
    VALUES (1),
        (2)) AS t (x)
    WINDOW w AS (ORDER BY x);
-- Test in_range for other numeric datatypes
CREATE temp TABLE numerics (
    id int,
    f_float4 float4,
    f_float8 float8,
    f_numeric numeric
);
INSERT INTO numerics
VALUES
    (0, '-infinity', '-infinity', '-infinity'),
    (1, -3, -3, -3),
    (2, -1, -1, -1),
    (3, 0, 0, 0),
    (4, 1.1, 1.1, 1.1),
    (5, 1.12, 1.12, 1.12),
    (6, 2, 2, 2),
    (7, 100, 100, 100),
    (8, 'infinity', 'infinity', 'infinity'),
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
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 'inf' PRECEDING AND 'inf' PRECEDING);
SELECT
    id,
    f_float4,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float4 RANGE BETWEEN 'inf' FOLLOWING AND 'inf' FOLLOWING);
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
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 'inf' PRECEDING AND 'inf' PRECEDING);
SELECT
    id,
    f_float8,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_float8 RANGE BETWEEN 'inf' FOLLOWING AND 'inf' FOLLOWING);
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
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 'inf' PRECEDING AND 'inf' FOLLOWING);
SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 'inf' PRECEDING AND 'inf' PRECEDING);
SELECT
    id,
    f_numeric,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM numerics
WINDOW w AS (ORDER BY f_numeric RANGE BETWEEN 'inf' FOLLOWING AND 'inf' FOLLOWING);
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
    (0, '10:00', '10:00 BST', '-infinity', '-infinity', '-infinity'),
    (1, '11:00', '11:00 BST', '1 year', '2000-10-19 10:23:54+01', '2000-10-19 10:23:54'),
    (2, '12:00', '12:00 BST', '2 years', '2001-10-19 10:23:54+01', '2001-10-19 10:23:54'),
    (3, '13:00', '13:00 BST', '3 years', '2001-10-19 10:23:54+01', '2001-10-19 10:23:54'),
    (4, '14:00', '14:00 BST', '4 years', '2002-10-19 10:23:54+01', '2002-10-19 10:23:54'),
    (5, '15:00', '15:00 BST', '5 years', '2003-10-19 10:23:54+01', '2003-10-19 10:23:54'),
    (6, '15:00', '15:00 BST', '5 years', '2004-10-19 10:23:54+01', '2004-10-19 10:23:54'),
    (7, '17:00', '17:00 BST', '7 years', '2005-10-19 10:23:54+01', '2005-10-19 10:23:54'),
    (8, '18:00', '18:00 BST', '8 years', '2006-10-19 10:23:54+01', '2006-10-19 10:23:54'),
    (9, '19:00', '19:00 BST', '9 years', '2007-10-19 10:23:54+01', '2007-10-19 10:23:54'),
    (10, '20:00', '20:00 BST', '10 years', '2008-10-19 10:23:54+01', '2008-10-19 10:23:54'),
    (11, '21:00', '21:00 BST', 'infinity', 'infinity', 'infinity');
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
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time DESC RANGE BETWEEN '-70 min' PRECEDING AND '2 hours' FOLLOWING);
-- error, negative offset disallowed
SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval PRECEDING);
SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time RANGE BETWEEN 'infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_time,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_time RANGE BETWEEN '-infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
-- error, negative offset disallowed
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
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz DESC RANGE BETWEEN '70 min' PRECEDING AND '-2 hours' FOLLOWING);
-- error, negative offset disallowed
SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval PRECEDING);
SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz RANGE BETWEEN 'infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timetz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timetz RANGE BETWEEN 'infinity'::interval FOLLOWING AND '-infinity'::interval FOLLOWING);
-- error, negative offset disallowed
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
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval DESC RANGE BETWEEN '-1 year' PRECEDING AND '1 year' FOLLOWING);
-- error, negative offset disallowed
SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval PRECEDING);
SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval RANGE BETWEEN 'infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_interval,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_interval RANGE BETWEEN '-infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
-- error, negative offset disallowed
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
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz DESC RANGE BETWEEN '1 year' PRECEDING AND '-1 year' FOLLOWING);
-- error, negative offset disallowed
SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval PRECEDING);
SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz RANGE BETWEEN 'infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timestamptz,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamptz RANGE BETWEEN '-infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
-- error, negative offset disallowed
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
SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp DESC RANGE BETWEEN '-1 year' PRECEDING AND '1 year' FOLLOWING);
-- error, negative offset disallowed
SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp RANGE BETWEEN 'infinity'::interval PRECEDING AND 'infinity'::interval PRECEDING);
SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp RANGE BETWEEN 'infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
SELECT
    id,
    f_timestamp,
    first_value(id) OVER w,
    last_value(id) OVER w
FROM datetimes
WINDOW w AS (ORDER BY f_timestamp RANGE BETWEEN '-infinity'::interval FOLLOWING AND 'infinity'::interval FOLLOWING);
-- error, negative offset disallowed
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
        generate_series(1, 35, 2)
)
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
        generate_series(1, 35, 2)
)
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
        generate_series(1, 35, 2)
)
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
        generate_series(5, 49, 2)
)
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
        generate_series(5, 49, 2)
)
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
        generate_series(5, 49, 2)
)
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
--
-- Test SupportRequestOptimizeWindowClause's ability to de-duplicate
-- WindowClauses
--
-- Ensure WindowClause frameOptions are changed so that only a single
-- WindowAgg exists in the plan.
EXPLAIN (
    COSTS OFF
)
SELECT
    empno,
    depname,
    row_number() OVER (PARTITION BY depname ORDER BY enroll_date) rn,
    rank() OVER (PARTITION BY depname ORDER BY enroll_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) rnk,
    dense_rank() OVER (PARTITION BY depname ORDER BY enroll_date RANGE BETWEEN CURRENT ROW AND CURRENT ROW) drnk,
    ntile(10) OVER (PARTITION BY depname ORDER BY enroll_date RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) nt,
    percent_rank() OVER (PARTITION BY depname ORDER BY enroll_date ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) pr,
    cume_dist() OVER (PARTITION BY depname ORDER BY enroll_date RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) cd
FROM
    empsalary;
-- Ensure WindowFuncs which cannot support their WindowClause's frameOptions
-- being changed are untouched
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    empno,
    depname,
    row_number() OVER (PARTITION BY depname ORDER BY enroll_date) rn,
    rank() OVER (PARTITION BY depname ORDER BY enroll_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) rnk,
    count(*) OVER (PARTITION BY depname ORDER BY enroll_date RANGE BETWEEN CURRENT ROW AND CURRENT ROW) cnt
FROM
    empsalary;
-- Ensure the above query gives us the expected results
SELECT
    empno,
    depname,
    row_number() OVER (PARTITION BY depname ORDER BY enroll_date) rn,
    rank() OVER (PARTITION BY depname ORDER BY enroll_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) rnk,
    count(*) OVER (PARTITION BY depname ORDER BY enroll_date RANGE BETWEEN CURRENT ROW AND CURRENT ROW) cnt
FROM
    empsalary;
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
-- Test window function run conditions are properly pushed down into the
-- WindowAgg
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        row_number() OVER (ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    rn < 3;
-- The following 3 statements should result the same result.
SELECT
    *
FROM (
    SELECT
        empno,
        row_number() OVER (ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    rn < 3;
SELECT
    *
FROM (
    SELECT
        empno,
        row_number() OVER (ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    3 > rn;
SELECT
    *
FROM (
    SELECT
        empno,
        row_number() OVER (ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    2 >= rn;
-- Ensure r <= 3 is pushed down into the run condition of the window agg
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        rank() OVER (ORDER BY salary DESC) r
    FROM empsalary) emp
WHERE
    r <= 3;
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        rank() OVER (ORDER BY salary DESC) r
    FROM empsalary) emp
WHERE
    r <= 3;
-- Ensure dr = 1 is converted to dr <= 1 to get all rows leading up to dr = 1
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        dense_rank() OVER (ORDER BY salary DESC) dr
    FROM empsalary) emp
WHERE
    dr = 1;
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        dense_rank() OVER (ORDER BY salary DESC) dr
    FROM empsalary) emp
WHERE
    dr = 1;
-- Check COUNT() and COUNT(*)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(empno) OVER (ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(empno) OVER (ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) c
    FROM empsalary) emp
WHERE
    c >= 3;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER () c
    FROM empsalary) emp
WHERE
    11 <= c;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary DESC) c,
        dense_rank() OVER (ORDER BY salary DESC) dr
    FROM empsalary) emp
WHERE
    dr = 1;
-- Ensure we get a run condition when there's a PARTITION BY clause
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        row_number() OVER (PARTITION BY depname ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    rn < 3;
-- and ensure we get the correct results from the above plan
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        row_number() OVER (PARTITION BY depname ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    rn < 3;
-- ensure that "unused" subquery columns are not removed when the column only
-- exists in the run condition
EXPLAIN (
    COSTS OFF
)
SELECT
    empno,
    depname
FROM (
    SELECT
        empno,
        depname,
        row_number() OVER (PARTITION BY depname ORDER BY empno) rn
    FROM empsalary) emp
WHERE
    rn < 3;
-- likewise with count(empno) instead of row_number()
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        salary,
        count(empno) OVER (PARTITION BY depname ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- and again, check the results are what we expect.
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        salary,
        count(empno) OVER (PARTITION BY depname ORDER BY salary DESC) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we get the correct run condition when the window function is both
-- monotonically increasing and decreasing in RANGE mode without an ORDER BY
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        salary,
        count(empno) OVER (RANGE BETWEEN CURRENT ROW AND CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c = 1;
-- As above, but check we detect it's monotonically increasing
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        salary,
        count(empno) OVER (RANGE BETWEEN CURRENT ROW AND CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure that ROWS mode without an ORDER BY doesn't think it's monotonically
-- decreasing, i.e. don't push down the run condition.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        depname,
        salary,
        count(empno) OVER (ROWS BETWEEN CURRENT ROW AND CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c > 1;
-- Try another case with a WindowFunc with a byref return type
SELECT
    *
FROM (
    SELECT
        row_number() OVER (PARTITION BY salary) AS rn,
        lead(depname) OVER (PARTITION BY salary) || ' Department' AS n_dep
    FROM
        empsalary) emp
WHERE
    rn < 1;
-- Some more complex cases with multiple window clauses
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *,
        count(salary) OVER (PARTITION BY depname || '') c1, -- w1
        row_number() OVER (PARTITION BY depname) rn, -- w2
        count(*) OVER (PARTITION BY depname) c2, -- w2
        count(*) OVER (PARTITION BY '' || depname) c3, -- w3
        ntile(2) OVER (PARTITION BY depname) nt -- w2
    FROM empsalary) e
WHERE
    rn <= 1
    AND c1 <= 3
    AND nt < 2;
-- Ensure we correctly filter out all of the run conditions from each window
SELECT
    *
FROM (
    SELECT
        *,
        count(salary) OVER (PARTITION BY depname || '') c1, -- w1
        row_number() OVER (PARTITION BY depname) rn, -- w2
        count(*) OVER (PARTITION BY depname) c2, -- w2
        count(*) OVER (PARTITION BY '' || depname) c3, -- w3
        ntile(2) OVER (PARTITION BY depname) nt -- w2
    FROM empsalary) e
WHERE
    rn <= 1
    AND c1 <= 3
    AND nt < 2;
-- Ensure we remove references to reduced outer joins as nulling rels in run
-- conditions
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        ntile(e2.salary) OVER (PARTITION BY e1.depname) AS c
    FROM
        empsalary e1
        LEFT JOIN empsalary e2 ON TRUE
    WHERE
        e1.empno = e2.empno) s
WHERE
    s.c = 1;
-- Ensure the run condition optimization is used in cases where the WindowFunc
-- has a Var from another query level
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        ntile(s1.x) OVER () AS c
    FROM (
        SELECT
            (
                SELECT
                    1) AS x) AS s1) s
WHERE
    s.c = 1;
-- Tests to ensure we don't push down the run condition when it's not valid to
-- do so.
-- Ensure we don't push down when the frame options show that the window
-- function is not monotonically increasing
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't push down when the window function's monotonic properties
-- don't match that of the clauses.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary) c
    FROM empsalary) emp
WHERE
    3 <= c;
-- Ensure we don't use a run condition when there's a volatile function in the
-- WindowFunc
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(random()) OVER (ORDER BY empno DESC) c
    FROM empsalary) emp
WHERE
    c = 1;
-- Ensure we don't use a run condition when the WindowFunc contains subplans
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count((
            SELECT
                1)) OVER (ORDER BY empno DESC) c
    FROM empsalary) emp
WHERE
    c = 1;
--
-- Ensure we get the correct behavior for run condition pushdown when the
-- frame option has an EXCLUDE clause
--
-- Ensure pushdown occurs for ROWS BETWEEN UNBOUNDED PRECEDING with EXCLUDE
-- CURRENT ROW with COUNT(*)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure pushdown occurs for GROUPS BETWEEN UNBOUNDED PRECEDING with EXCLUDE
-- CURRENT ROW with COUNT(*)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            EXCLUDE CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure pushdown occurs for RANGE BETWEEN UNBOUNDED PRECEDING with EXCLUDE
-- CURRENT ROW with COUNT(*)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            EXCLUDE CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown when a FILTER clause is present
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) FILTER (WHERE salary > 4000) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown with COUNT(ANY)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(salary) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE CURRENT ROW) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown with EXCLUDE GROUP
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE GROUP) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown with EXCLUDE TIES
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE TIES) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown with GROUPS mode and EXCLUDE GROUP
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary GROUPS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE GROUP) c
    FROM empsalary) emp
WHERE
    c <= 3;
-- Ensure we don't get pushdown with GROUPS mode and EXCLUDE TIES
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        empno,
        salary,
        count(*) OVER (ORDER BY salary GROUPS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING
            EXCLUDE TIES) c
    FROM empsalary) emp
WHERE
    c <= 3;
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
-- Ensure that the evaluation order of the WindowAggs results in the WindowAgg
-- with the same sort order that's required by the ORDER BY is evaluated last.
EXPLAIN (
    COSTS OFF
)
SELECT
    empno,
    enroll_date,
    depname,
    sum(salary) OVER (PARTITION BY depname ORDER BY empno) depsalary,
    min(salary) OVER (PARTITION BY depname ORDER BY enroll_date) depminsalary
FROM
    empsalary
ORDER BY
    depname,
    empno;
-- As above, but with an adjusted ORDER BY to ensure the above plan didn't
-- perform only 2 sorts by accident.
EXPLAIN (
    COSTS OFF
)
SELECT
    empno,
    enroll_date,
    depname,
    sum(salary) OVER (PARTITION BY depname ORDER BY empno) depsalary,
    min(salary) OVER (PARTITION BY depname ORDER BY enroll_date) depminsalary
FROM
    empsalary
ORDER BY
    depname,
    enroll_date;
SET enable_hashagg TO OFF;
-- Ensure we don't get a sort for both DISTINCT and ORDER BY.  We expect the
-- sort for the DISTINCT to provide presorted input for the ORDER BY.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    empno,
    enroll_date,
    depname,
    sum(salary) OVER (PARTITION BY depname ORDER BY empno) depsalary,
    min(salary) OVER (PARTITION BY depname ORDER BY enroll_date) depminsalary
FROM
    empsalary
ORDER BY
    depname,
    enroll_date;
-- As above but adjust the ORDER BY clause to help ensure the plan with the
-- minimum amount of sorting wasn't a fluke.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    empno,
    enroll_date,
    depname,
    sum(salary) OVER (PARTITION BY depname ORDER BY empno) depsalary,
    min(salary) OVER (PARTITION BY depname ORDER BY enroll_date) depminsalary
FROM
    empsalary
ORDER BY
    depname,
    empno;
RESET enable_hashagg;
-- Test Sort node reordering
EXPLAIN (
    COSTS OFF
)
SELECT
    lead(1) OVER (PARTITION BY depname ORDER BY salary, enroll_date),
    lag(1) OVER (PARTITION BY depname ORDER BY salary, enroll_date, empno)
FROM
    empsalary;
-- Test incremental sorting
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        depname,
        empno,
        salary,
        enroll_date,
        row_number() OVER (PARTITION BY depname ORDER BY enroll_date) AS first_emp,
        row_number() OVER (PARTITION BY depname ORDER BY enroll_date DESC) AS last_emp
    FROM
        empsalary) emp
WHERE
    first_emp = 1
    OR last_emp = 1;
SELECT
    *
FROM (
    SELECT
        depname,
        empno,
        salary,
        enroll_date,
        row_number() OVER (PARTITION BY depname ORDER BY enroll_date) AS first_emp,
        row_number() OVER (PARTITION BY depname ORDER BY enroll_date DESC) AS last_emp
    FROM
        empsalary) emp
WHERE
    first_emp = 1
    OR last_emp = 1;
CREATE INDEX empsalary_salary_empno_idx ON empsalary (salary, empno);
SET enable_seqscan = 0;
-- Ensure no sorting is done and that the IndexScan maintains all pathkeys
-- useful for the final sort order.
EXPLAIN (
    COSTS OFF
)
SELECT
    salary,
    empno,
    row_number() OVER (ORDER BY salary) rn
FROM
    empsalary
ORDER BY
    salary,
    empno;
RESET enable_seqscan;
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
-- moving aggregates over infinite intervals
SELECT
    x,
    avg(x) OVER (ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS curr_next_avg,
    avg(x) OVER (ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS prev_curr_avg,
    sum(x) OVER (ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS curr_next_sum,
    sum(x) OVER (ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS prev_curr_sum
FROM (
    VALUES (NULL::interval),
        ('infinity'::interval),
        ('-2147483648 days -2147483648 months -9223372036854775807 usecs'), -- extreme interval value
        ('-infinity'::interval),
        ('2147483647 days 2147483647 months 9223372036854775806 usecs'), -- extreme interval value
        ('infinity'::interval),
        ('6 days'::interval),
        ('7 days'::interval),
        (NULL::interval),
        ('-infinity'::interval)) v (x);
--should fail.
SELECT
    x,
    avg(x) OVER (ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING)
FROM (
    VALUES (NULL::interval),
        ('3 days'::interval),
        ('infinity'::timestamptz - now()),
        ('6 days'::interval),
        ('-infinity'::interval)) v (x);
--should fail.
SELECT
    x,
    sum(x) OVER (ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING)
FROM (
    VALUES (NULL::interval),
        ('3 days'::interval),
        ('infinity'::timestamptz - now()),
        ('6 days'::interval),
        ('-infinity'::interval)) v (x);
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
--
-- Test WindowAgg costing takes into account the number of rows that need to
-- be fetched before the first row can be output.
--
-- Ensure we get a cheap start up plan as the WindowAgg can output the first
-- row after reading 1 row from the join.
EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*) OVER (ORDER BY t1.unique1)
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.unique1 = t2.tenthous
LIMIT 1;
-- Ensure we get a cheap total plan.  Lack of ORDER BY in the WindowClause
-- means that all rows must be read from the join, so a cheap startup plan
-- isn't a good choice.
EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*) OVER ()
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.unique1 = t2.tenthous
WHERE
    t2.two = 1
LIMIT 1;
-- Ensure we get a cheap total plan.  This time use UNBOUNDED FOLLOWING, which
-- needs to read all join rows to output the first WindowAgg row.
EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*) OVER (ORDER BY t1.unique1 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.unique1 = t2.tenthous
LIMIT 1;
-- Ensure we get a cheap total plan.  This time use 10000 FOLLOWING so we need
-- to read all join rows.
EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*) OVER (ORDER BY t1.unique1 ROWS BETWEEN UNBOUNDED PRECEDING AND 10000 FOLLOWING)
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.unique1 = t2.tenthous
LIMIT 1;
-- Tests for problems with failure to walk or mutate expressions
-- within window frame clauses.
-- test walker (fails with collation error if expressions are not walked)
SELECT
    array_agg(i) OVER w
FROM generate_series(1, 5) i
WINDOW w AS (ORDER BY i ROWS BETWEEN (('foo' < 'foobar')::integer)
    PRECEDING AND CURRENT ROW);
-- test mutator (fails when inlined if expressions are not mutated)
CREATE FUNCTION pg_temp.f (group_size bigint)
    RETURNS SETOF integer[]
    AS $$
    SELECT
        array_agg(s) OVER w
    FROM generate_series(1, 5) s
WINDOW w AS (ORDER BY s ROWS BETWEEN CURRENT ROW AND GROUP_SIZE FOLLOWING)
$$
LANGUAGE SQL
STABLE;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_temp.f (2);
SELECT
    *
FROM
    pg_temp.f (2);
-- IGNORE NULLS tests
CREATE TEMPORARY TABLE planets (
    name text,
    distance text,
    orbit integer
);
INSERT INTO planets
VALUES
    ('mercury', 'close', 88),
    ('venus', 'close', 224),
    ('earth', 'close', NULL),
    ('mars', 'close', NULL),
    ('jupiter', 'close', 4332),
    ('saturn', 'far', 24491),
    ('uranus', 'far', NULL),
    ('neptune', 'far', 60182),
    ('pluto', 'far', 90560),
    ('xyzzy', 'far', NULL);
-- test ruleutils
CREATE VIEW planets_view AS
SELECT
    name,
    orbit,
    lag(orbit) OVER w AS lag,
    lag(orbit) RESPECT NULLS OVER w AS lag_respect,
lag(orbit) IGNORE NULLS OVER w AS lag_ignore
FROM
    planets
WINDOW w AS (ORDER BY name);
SELECT
    pg_get_viewdef('planets_view');
-- lag
SELECT
    name,
    orbit,
    lag(orbit) OVER w AS lag,
    lag(orbit) RESPECT NULLS OVER w AS lag_respect,
lag(orbit) IGNORE NULLS OVER w AS lag_ignore
FROM
    planets
WINDOW w AS (ORDER BY name);
-- lead
SELECT
    name,
    orbit,
    lead(orbit) OVER w AS lead,
    lead(orbit) RESPECT NULLS OVER w AS lead_respect,
lead(orbit) IGNORE NULLS OVER w AS lead_ignore
FROM
    planets
WINDOW w AS (ORDER BY name);
-- first_value
SELECT
    name,
    orbit,
    first_value(orbit) RESPECT NULLS OVER w1,
first_value(orbit) IGNORE NULLS OVER w1,
first_value(orbit) RESPECT NULLS OVER w2,
first_value(orbit) IGNORE NULLS OVER w2
FROM planets
WINDOW w1 AS (ORDER BY name ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
w2 AS (
ORDER BY
    name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- nth_value
SELECT
    name,
    orbit,
    nth_value(orbit, 2) RESPECT NULLS OVER w1,
nth_value(orbit, 2) IGNORE NULLS OVER w1,
nth_value(orbit, 2) RESPECT NULLS OVER w2,
nth_value(orbit, 2) IGNORE NULLS OVER w2
FROM planets
WINDOW w1 AS (ORDER BY name ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
w2 AS (
ORDER BY
    name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- last_value
SELECT
    name,
    orbit,
    last_value(orbit) RESPECT NULLS OVER w1,
last_value(orbit) IGNORE NULLS OVER w1,
last_value(orbit) RESPECT NULLS OVER w2,
last_value(orbit) IGNORE NULLS OVER w2
FROM planets
WINDOW w1 AS (ORDER BY name ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
w2 AS (
ORDER BY
    name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- exclude current row
SELECT
    name,
    orbit,
    first_value(orbit) IGNORE NULLS OVER w,
last_value(orbit) IGNORE NULLS OVER w,
nth_value(orbit, 2) IGNORE NULLS OVER w,
lead(orbit, 1) IGNORE NULLS OVER w AS lead_ignore,
lag(orbit, 1) IGNORE NULLS OVER w AS lag_ignore
FROM
    planets
WINDOW w AS (ORDER BY name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE CURRENT ROW);
-- valid and invalid functions
SELECT
    abs(1) IGNORE NULLS;
-- fails
SELECT
    no_such_window_func () IGNORE NULLS;
-- fails, but not because of null treatment
SELECT
    sum(orbit) IGNORE NULLS
FROM
    planets;
-- fails
SELECT
    sum(orbit) OVER ()
FROM
    planets;
-- succeeds
SELECT
    sum(orbit) RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    sum(orbit) IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    row_number() OVER ()
FROM
    planets;
-- succeeds
SELECT
    row_number() RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    row_number() IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    rank() OVER ()
FROM
    planets;
-- succeeds
SELECT
    rank() RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    rank() IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    dense_rank() OVER ()
FROM
    planets;
-- succeeds
SELECT
    dense_rank() RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    dense_rank() IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    percent_rank() OVER ()
FROM
    planets;
-- succeeds
SELECT
    percent_rank() RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    percent_rank() IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    cume_dist() OVER ()
FROM
    planets;
-- succeeds
SELECT
    cume_dist() RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    cume_dist() IGNORE NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    ntile(1) OVER ()
FROM
    planets;
-- succeeds
SELECT
    ntile(1) RESPECT NULLS OVER ()
FROM
    planets;
-- fails
SELECT
    ntile(1) IGNORE NULLS OVER ()
FROM
    planets;
-- fails
-- test two consecutive nulls
UPDATE
    planets
SET
    orbit = NULL
WHERE
    name = 'jupiter';
SELECT
    name,
    orbit,
    first_value(orbit) IGNORE NULLS OVER w,
last_value(orbit) IGNORE NULLS OVER w,
nth_value(orbit, 2) IGNORE NULLS OVER w,
lead(orbit, 1) IGNORE NULLS OVER w AS lead_ignore,
lag(orbit, 1) IGNORE NULLS OVER w AS lag_ignore
FROM
    planets
WINDOW w AS (ORDER BY name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- test partitions
SELECT
    name,
    distance,
    orbit,
    first_value(orbit) IGNORE NULLS OVER w,
last_value(orbit) IGNORE NULLS OVER w,
nth_value(orbit, 2) IGNORE NULLS OVER w,
lead(orbit, 1) IGNORE NULLS OVER w AS lead_ignore,
lag(orbit, 1) IGNORE NULLS OVER w AS lag_ignore
FROM
    planets
WINDOW w AS (PARTITION BY distance ORDER BY name ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- nth_value without nulls
SELECT
    x,
    nth_value(x, 2) IGNORE NULLS OVER w
FROM generate_series(1, 5) g (x)
WINDOW w AS (ORDER BY x ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING EXCLUDE CURRENT ROW);
SELECT
    x,
    nth_value(x, 2) IGNORE NULLS OVER w
FROM generate_series(1, 5) g (x)
WINDOW w AS (ORDER BY x ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);
-- EXCLUDE GROUP/TIES without ORDER BY: every row is a peer of the current
-- row, so the IGNORE NULLS scan must stop at the end of the partition
SELECT
    x,
    first_value(x) IGNORE NULLS OVER w,
nth_value(x, 2) IGNORE NULLS OVER w
FROM (
    VALUES (1),
    (NULL),
(3)) v (x)
    WINDOW w AS (
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING EXCLUDE GROUP)
ORDER BY
    x;
SELECT
    x,
    first_value(x) IGNORE NULLS OVER w,
nth_value(x, 2) IGNORE NULLS OVER w
FROM (
    VALUES (1),
    (NULL),
(3)) v (x)
    WINDOW w AS (
RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING EXCLUDE TIES)
ORDER BY
    x;
SELECT
    p,
    x,
    first_value(x) IGNORE NULLS OVER w
FROM (
    VALUES (1, 1),
    (1, NULL),
(2, NULL)) v (p, x)
    WINDOW w AS (PARTITION BY p ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING EXCLUDE TIES)
ORDER BY
    p,
    x;
-- volatile arguments cannot use the IGNORE NULLS nullness cache
CREATE TEMPORARY SEQUENCE null_treatment_seq;
CREATE FUNCTION pg_temp.volatile_null (i int)
    RETURNS int
    LANGUAGE sql
    VOLATILE
    AS $$
    SELECT
        CASE WHEN nextval('null_treatment_seq') % 2 = 0 THEN
            i
        ELSE
            NULL
        END;
$$;
SELECT
    x,
    first_value(pg_temp.volatile_null (x)) IGNORE NULLS OVER (ORDER BY x ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM
    generate_series(1, 5) g (x);
SELECT
    last_value
FROM
    null_treatment_seq;
ALTER SEQUENCE null_treatment_seq
    RESTART WITH 1;
SELECT
    x,
    lead(pg_temp.volatile_null (x), 1) IGNORE NULLS OVER (ORDER BY x)
FROM
    generate_series(1, 5) g (x);
SELECT
    last_value
FROM
    null_treatment_seq;
ALTER SEQUENCE null_treatment_seq
    RESTART WITH 1;
SELECT
    x,
    first_value((
        SELECT
            CASE WHEN nextval('null_treatment_seq') % 2 = 0 THEN
                x
            ELSE
                NULL
            END)) IGNORE NULLS OVER (ORDER BY x ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM
    generate_series(1, 5) g (x);
SELECT
    last_value
FROM
    null_treatment_seq;
--cleanup
DROP TABLE planets CASCADE;
