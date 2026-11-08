--
-- LIMIT
-- Check the LIMIT/OFFSET feature of SELECT
--
SELECT
    ''::text AS two,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 > 50
ORDER BY
    unique1
LIMIT 2;

SELECT
    ''::text AS five,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 > 60
ORDER BY
    unique1
LIMIT 5;

SELECT
    ''::text AS two,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 > 60
    AND unique1 < 63
ORDER BY
    unique1
LIMIT 5;

SELECT
    ''::text AS three,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 > 100
ORDER BY
    unique1
LIMIT 3 OFFSET 20;

SELECT
    ''::text AS zero,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 < 50
ORDER BY
    unique1 DESC
LIMIT 8 OFFSET 99;

SELECT
    ''::text AS eleven,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 < 50
ORDER BY
    unique1 DESC
LIMIT 20 OFFSET 39;

SELECT
    ''::text AS ten,
    unique1,
    unique2,
    stringu1
FROM
    onek
ORDER BY
    unique1 OFFSET 990;

SELECT
    ''::text AS five,
    unique1,
    unique2,
    stringu1
FROM
    onek
ORDER BY
    unique1 OFFSET 990
LIMIT 5;

SELECT
    ''::text AS five,
    unique1,
    unique2,
    stringu1
FROM
    onek
ORDER BY
    unique1
LIMIT 5 OFFSET 900;

-- Test null limit and offset.  The planner would discard a simple null
-- constant, so to ensure executor is exercised, do this:
SELECT
    *
FROM
    int8_tbl
LIMIT (
    CASE WHEN random() < 0.5 THEN
        NULL::bigint
    END);

SELECT
    *
FROM
    int8_tbl OFFSET (
        CASE WHEN random() < 0.5 THEN
            NULL::bigint
        END);

-- Test assorted cases involving backwards fetch from a LIMIT plan node
BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl
    LIMIT 10;
FETCH ALL IN c1;
FETCH 1 IN c1;
FETCH BACKWARD 1 IN c1;
FETCH BACKWARD ALL IN c1;
FETCH BACKWARD 1 IN c1;
FETCH ALL IN c1;
DECLARE c2 CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl
    LIMIT 3;
FETCH ALL IN c2;
FETCH 1 IN c2;
FETCH BACKWARD 1 IN c2;
FETCH BACKWARD ALL IN c2;
FETCH BACKWARD 1 IN c2;
FETCH ALL IN c2;
DECLARE c3 CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl OFFSET 3;
FETCH ALL IN c3;
FETCH 1 IN c3;
FETCH BACKWARD 1 IN c3;
FETCH BACKWARD ALL IN c3;
FETCH BACKWARD 1 IN c3;
FETCH ALL IN c3;
DECLARE c4 CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl OFFSET 10;
FETCH ALL IN c4;
FETCH 1 IN c4;
FETCH BACKWARD 1 IN c4;
FETCH BACKWARD ALL IN c4;
FETCH BACKWARD 1 IN c4;
FETCH ALL IN c4;
DECLARE c5 CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl
    ORDER BY
        q1 FETCH FIRST 2 ROWS WITH TIES;
FETCH ALL IN c5;
FETCH 1 IN c5;
FETCH BACKWARD 1 IN c5;
FETCH BACKWARD 1 IN c5;
FETCH ALL IN c5;
FETCH BACKWARD ALL IN c5;
FETCH ALL IN c5;
FETCH BACKWARD ALL IN c5;
ROLLBACK;

-- Stress test for variable LIMIT in conjunction with bounded-heap sorting
SELECT
    (
        SELECT
            n
        FROM (
            VALUES (1)) AS x,
            (
                SELECT
                    n
                FROM
                    generate_series(1, 10) AS n
                ORDER BY
                    n
                LIMIT 1 OFFSET s - 1) AS y) AS z
FROM
    generate_series(1, 10) AS s;

--
-- Test behavior of volatile and set-returning functions in conjunction
-- with ORDER BY and LIMIT.
--
CREATE temp SEQUENCE testseq;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unique1,
    unique2,
    nextval('testseq')
FROM
    tenk1
ORDER BY
    unique2
LIMIT 10;

SELECT
    unique1,
    unique2,
    nextval('testseq')
FROM
    tenk1
ORDER BY
    unique2
LIMIT 10;

SELECT
    currval('testseq');

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unique1,
    unique2,
    nextval('testseq')
FROM
    tenk1
ORDER BY
    tenthous
LIMIT 10;

SELECT
    unique1,
    unique2,
    nextval('testseq')
FROM
    tenk1
ORDER BY
    tenthous
LIMIT 10;

SELECT
    currval('testseq');

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unique1,
    unique2,
    generate_series(1, 10)
FROM
    tenk1
ORDER BY
    unique2
LIMIT 7;

SELECT
    unique1,
    unique2,
    generate_series(1, 10)
FROM
    tenk1
ORDER BY
    unique2
LIMIT 7;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unique1,
    unique2,
    generate_series(1, 10)
FROM
    tenk1
ORDER BY
    tenthous
LIMIT 7;

SELECT
    unique1,
    unique2,
    generate_series(1, 10)
FROM
    tenk1
ORDER BY
    tenthous
LIMIT 7;

-- use of random() is to keep planner from folding the expressions together
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    generate_series(0, 2) AS s1,
    generate_series((random() * .1)::int, 2) AS s2;

SELECT
    generate_series(0, 2) AS s1,
    generate_series((random() * .1)::int, 2) AS s2;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    generate_series(0, 2) AS s1,
    generate_series((random() * .1)::int, 2) AS s2
ORDER BY
    s2 DESC;

SELECT
    generate_series(0, 2) AS s1,
    generate_series((random() * .1)::int, 2) AS s2
ORDER BY
    s2 DESC;

-- test for failure to set all aggregates' aggtranstype
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    sum(tenthous) AS s1,
    sum(tenthous) + random() * 0 AS s2
FROM
    tenk1
GROUP BY
    thousand
ORDER BY
    thousand
LIMIT 3;

SELECT
    sum(tenthous) AS s1,
    sum(tenthous) + random() * 0 AS s2
FROM
    tenk1
GROUP BY
    thousand
ORDER BY
    thousand
LIMIT 3;

--
-- FETCH FIRST
-- Check the WITH TIES clause
--
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 5
ORDER BY
    thousand FETCH FIRST 2 ROW WITH TIES;

SELECT
    thousand
FROM
    onek
WHERE
    thousand < 5
ORDER BY
    thousand FETCH FIRST ROWS WITH TIES;

SELECT
    thousand
FROM
    onek
WHERE
    thousand < 5
ORDER BY
    thousand FETCH FIRST 1 ROW WITH TIES;

SELECT
    thousand
FROM
    onek
WHERE
    thousand < 5
ORDER BY
    thousand FETCH FIRST 2 ROW ONLY;

-- SKIP LOCKED and WITH TIES are incompatible
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 5
ORDER BY
    thousand FETCH FIRST 1 ROW WITH TIES
FOR UPDATE
    SKIP LOCKED;

-- should fail
SELECT
    ''::text AS two,
    unique1,
    unique2,
    stringu1
FROM
    onek
WHERE
    unique1 > 50 FETCH FIRST 2 ROW WITH TIES;

-- test ruleutils
CREATE VIEW limit_thousand_v_1 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand FETCH FIRST 5 ROWS WITH TIES OFFSET 10;

\d+ limit_thousand_v_1
CREATE VIEW limit_thousand_v_2 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand OFFSET 10 FETCH FIRST 5 ROWS ONLY;

\d+ limit_thousand_v_2
CREATE VIEW limit_thousand_v_3 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand FETCH FIRST NULL ROWS WITH TIES;

-- fails
CREATE VIEW limit_thousand_v_3 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand FETCH FIRST (NULL +1)
    ROWS WITH TIES;

\d+ limit_thousand_v_3
CREATE VIEW limit_thousand_v_4 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand FETCH FIRST (5::bigint)
    ROWS WITH TIES;

\d+ limit_thousand_v_4
CREATE VIEW limit_thousand_v_5 AS
SELECT
    thousand
FROM
    onek
WHERE
    thousand < 995
ORDER BY
    thousand FETCH FIRST NULL ROWS ONLY;

\d+ limit_thousand_v_5
-- leave these views
