--
-- UNION (also INTERSECT, EXCEPT)
--
-- Simple UNION constructs
SELECT
    1 AS two
UNION
SELECT
    2
ORDER BY
    1;

SELECT
    1 AS one
UNION
SELECT
    1
ORDER BY
    1;

SELECT
    1 AS two
UNION ALL
SELECT
    2;

SELECT
    1 AS two
UNION ALL
SELECT
    1;

SELECT
    1 AS three
UNION
SELECT
    2
UNION
SELECT
    3
ORDER BY
    1;

SELECT
    1 AS two
UNION
SELECT
    2
UNION
SELECT
    2
ORDER BY
    1;

SELECT
    1 AS three
UNION
SELECT
    2
UNION ALL
SELECT
    2
ORDER BY
    1;

SELECT
    1.1 AS two
UNION
SELECT
    2.2
ORDER BY
    1;

-- Mixed types
SELECT
    1.1 AS two
UNION
SELECT
    2
ORDER BY
    1;

SELECT
    1 AS two
UNION
SELECT
    2.2
ORDER BY
    1;

SELECT
    1 AS one
UNION
SELECT
    1.0::float8
ORDER BY
    1;

SELECT
    1.1 AS two
UNION ALL
SELECT
    2
ORDER BY
    1;

SELECT
    1.0::float8 AS two
UNION ALL
SELECT
    1
ORDER BY
    1;

SELECT
    1.1 AS three
UNION
SELECT
    2
UNION
SELECT
    3
ORDER BY
    1;

SELECT
    1.1::float8 AS two
UNION
SELECT
    2
UNION
SELECT
    2.0::float8
ORDER BY
    1;

SELECT
    1.1 AS three
UNION
SELECT
    2
UNION ALL
SELECT
    2
ORDER BY
    1;

SELECT
    1.1 AS two
UNION (
    SELECT
        2
    UNION ALL
    SELECT
        2)
ORDER BY
    1;

--
-- Try testing from tables...
--
SELECT
    f1 AS five
FROM
    FLOAT8_TBL
UNION
SELECT
    f1
FROM
    FLOAT8_TBL
ORDER BY
    1;

SELECT
    f1 AS ten
FROM
    FLOAT8_TBL
UNION ALL
SELECT
    f1
FROM
    FLOAT8_TBL;

SELECT
    f1 AS nine
FROM
    FLOAT8_TBL
UNION
SELECT
    f1
FROM
    INT4_TBL
ORDER BY
    1;

SELECT
    f1 AS ten
FROM
    FLOAT8_TBL
UNION ALL
SELECT
    f1
FROM
    INT4_TBL;

SELECT
    f1 AS five
FROM
    FLOAT8_TBL
WHERE
    f1 BETWEEN - 1e6 AND 1e6
UNION
SELECT
    f1
FROM
    INT4_TBL
WHERE
    f1 BETWEEN 0 AND 1000000
ORDER BY
    1;

SELECT
    CAST(f1 AS char(4)) AS three
FROM
    VARCHAR_TBL
UNION
SELECT
    f1
FROM
    CHAR_TBL
ORDER BY
    1;

SELECT
    f1 AS three
FROM
    VARCHAR_TBL
UNION
SELECT
    CAST(f1 AS varchar)
FROM
    CHAR_TBL
ORDER BY
    1;

SELECT
    f1 AS eight
FROM
    VARCHAR_TBL
UNION ALL
SELECT
    f1
FROM
    CHAR_TBL;

SELECT
    f1 AS five
FROM
    TEXT_TBL
UNION
SELECT
    f1
FROM
    VARCHAR_TBL
UNION
SELECT
    TRIM(TRAILING FROM f1)
FROM
    CHAR_TBL
ORDER BY
    1;

--
-- INTERSECT and EXCEPT
--
SELECT
    q2
FROM
    int8_tbl
INTERSECT
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q2
FROM
    int8_tbl
INTERSECT ALL
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q2
FROM
    int8_tbl
EXCEPT
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q2
FROM
    int8_tbl
EXCEPT ALL
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q2
FROM
    int8_tbl
EXCEPT ALL SELECT DISTINCT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
EXCEPT
SELECT
    q2
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
EXCEPT ALL
SELECT
    q2
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
EXCEPT ALL SELECT DISTINCT
    q2
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
EXCEPT ALL
SELECT
    q1
FROM
    int8_tbl
FOR NO KEY UPDATE;

-- nested cases
(
    SELECT
        1,
        2,
        3
    UNION
    SELECT
        4,
        5,
        6)
INTERSECT
SELECT
    4,
    5,
    6;

(
    SELECT
        1,
        2,
        3
    UNION
    SELECT
        4,
        5,
        6
    ORDER BY
        1,
        2)
INTERSECT
SELECT
    4,
    5,
    6;

(
    SELECT
        1,
        2,
        3
    UNION
    SELECT
        4,
        5,
        6)
EXCEPT
SELECT
    4,
    5,
    6;

(
    SELECT
        1,
        2,
        3
    UNION
    SELECT
        4,
        5,
        6
    ORDER BY
        1,
        2)
EXCEPT
SELECT
    4,
    5,
    6;

-- exercise both hashed and sorted implementations of INTERSECT/EXCEPT
SET enable_hashagg TO ON;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM (
    SELECT
        unique1
    FROM
        tenk1
    INTERSECT
    SELECT
        fivethous
    FROM
        tenk1) ss;

SELECT
    count(*)
FROM (
    SELECT
        unique1
    FROM
        tenk1
    INTERSECT
    SELECT
        fivethous
    FROM
        tenk1) ss;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1
EXCEPT
SELECT
    unique2
FROM
    tenk1
WHERE
    unique2 != 10;

SELECT
    unique1
FROM
    tenk1
EXCEPT
SELECT
    unique2
FROM
    tenk1
WHERE
    unique2 != 10;

SET enable_hashagg TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM (
    SELECT
        unique1
    FROM
        tenk1
    INTERSECT
    SELECT
        fivethous
    FROM
        tenk1) ss;

SELECT
    count(*)
FROM (
    SELECT
        unique1
    FROM
        tenk1
    INTERSECT
    SELECT
        fivethous
    FROM
        tenk1) ss;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1
EXCEPT
SELECT
    unique2
FROM
    tenk1
WHERE
    unique2 != 10;

SELECT
    unique1
FROM
    tenk1
EXCEPT
SELECT
    unique2
FROM
    tenk1
WHERE
    unique2 != 10;

RESET enable_hashagg;

--
-- Mixed types
--
SELECT
    f1
FROM
    float8_tbl
INTERSECT
SELECT
    f1
FROM
    int4_tbl
ORDER BY
    1;

SELECT
    f1
FROM
    float8_tbl
EXCEPT
SELECT
    f1
FROM
    int4_tbl
ORDER BY
    1;

--
-- Operator precedence and (((((extra))))) parentheses
--
SELECT
    q1
FROM
    int8_tbl
INTERSECT
SELECT
    q2
FROM
    int8_tbl
UNION ALL
SELECT
    q2
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
INTERSECT (
            SELECT
                q2
            FROM
                int8_tbl
            UNION ALL
            SELECT
                q2
            FROM
                int8_tbl)
ORDER BY
    1;

(((
            SELECT
                q1
            FROM
                int8_tbl
            INTERSECT
            SELECT
                q2
            FROM
                int8_tbl
            ORDER BY
                1)))
UNION ALL
SELECT
    q2
FROM
    int8_tbl;

SELECT
    q1
FROM
    int8_tbl
UNION ALL
SELECT
    q2
FROM
    int8_tbl
EXCEPT
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

SELECT
    q1
FROM
    int8_tbl
UNION ALL ((
            SELECT
                q2
            FROM
                int8_tbl
            EXCEPT
            SELECT
                q1
            FROM
                int8_tbl
            ORDER BY
                1));

(((
            SELECT
                q1
            FROM
                int8_tbl
            UNION ALL
            SELECT
                q2
            FROM
                int8_tbl)))
EXCEPT
SELECT
    q1
FROM
    int8_tbl
ORDER BY
    1;

--
-- Subqueries with ORDER BY & LIMIT clauses
--
-- In this syntax, ORDER BY/LIMIT apply to the result of the EXCEPT
SELECT
    q1,
    q2
FROM
    int8_tbl
EXCEPT
SELECT
    q2,
    q1
FROM
    int8_tbl
ORDER BY
    q2,
    q1;

-- This should fail, because q2 isn't a name of an EXCEPT output column
SELECT
    q1
FROM
    int8_tbl
EXCEPT
SELECT
    q2
FROM
    int8_tbl
ORDER BY
    q2
LIMIT 1;

-- But this should work:
SELECT
    q1
FROM
    int8_tbl
EXCEPT (
            SELECT
                q2
            FROM
                int8_tbl
            ORDER BY
                q2
            LIMIT 1)
ORDER BY
    1;

--
-- New syntaxes (7.1) permit new tests
--
(((((
                    SELECT
                        *
                    FROM
                        int8_tbl)))));

--
-- Check behavior with empty select list (allowed since 9.4)
--
SELECT
UNION
SELECT
;

SELECT
INTERSECT
SELECT
;

SELECT
EXCEPT
SELECT
;

-- check hashed implementation
SET enable_hashagg = TRUE;

SET enable_sort = FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
FROM
    generate_series(1, 5)
UNION
SELECT
FROM
    generate_series(1, 3);

EXPLAIN (
    COSTS OFF
)
SELECT
FROM
    generate_series(1, 5)
INTERSECT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
UNION
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
UNION ALL
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
INTERSECT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
INTERSECT ALL
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
EXCEPT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
EXCEPT ALL
SELECT
FROM
    generate_series(1, 3);

-- check sorted implementation
SET enable_hashagg = FALSE;

SET enable_sort = TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
FROM
    generate_series(1, 5)
UNION
SELECT
FROM
    generate_series(1, 3);

EXPLAIN (
    COSTS OFF
)
SELECT
FROM
    generate_series(1, 5)
INTERSECT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
UNION
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
UNION ALL
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
INTERSECT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
INTERSECT ALL
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
EXCEPT
SELECT
FROM
    generate_series(1, 3);

SELECT
FROM
    generate_series(1, 5)
EXCEPT ALL
SELECT
FROM
    generate_series(1, 3);

RESET enable_hashagg;

RESET enable_sort;

--
-- Check handling of a case with unknown constants.  We don't guarantee
-- an undecorated constant will work in all cases, but historically this
-- usage has worked, so test we don't break it.
--
SELECT
    a.f1
FROM (
    SELECT
        'test' AS f1
    FROM
        varchar_tbl) a
UNION
SELECT
    b.f1
FROM (
    SELECT
        f1
    FROM
        varchar_tbl) b
ORDER BY
    1;

-- This should fail, but it should produce an error cursor
SELECT
    '3.4'::numeric
UNION
SELECT
    'foo';

--
-- Test that expression-index constraints can be pushed down through
-- UNION or UNION ALL
--
CREATE TEMP TABLE t1 (
    a text,
    b text
);

CREATE INDEX t1_ab_idx ON t1 ((a || b));

CREATE TEMP TABLE t2 (
    ab text PRIMARY KEY
);

INSERT INTO t1
VALUES
    ('a', 'b'),
    ('x', 'y');

INSERT INTO t2
VALUES
    ('ab'),
    ('xy');

SET enable_seqscan = OFF;

SET enable_indexscan = ON;

SET enable_bitmapscan = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a || b AS ab
    FROM
        t1
    UNION ALL
    SELECT
        *
    FROM
        t2) t
WHERE
    ab = 'ab';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a || b AS ab
    FROM
        t1
    UNION
    SELECT
        *
    FROM
        t2) t
WHERE
    ab = 'ab';

--
-- Test that ORDER BY for UNION ALL can be pushed down to inheritance
-- children.
--
CREATE TEMP TABLE t1c (
    b text,
    a text
);

ALTER TABLE t1c INHERIT t1;

CREATE TEMP TABLE t2c (
    PRIMARY KEY (ab)
)
INHERITS (
    t2
);

INSERT INTO t1c
VALUES
    ('v', 'w'),
    ('c', 'd'),
    ('m', 'n'),
    ('e', 'f');

INSERT INTO t2c
VALUES
    ('vw'),
    ('cd'),
    ('mn'),
    ('ef');

CREATE INDEX t1c_ab_idx ON t1c ((a || b));

SET enable_seqscan = ON;

SET enable_indexonlyscan = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a || b AS ab
    FROM
        t1
    UNION ALL
    SELECT
        ab
    FROM
        t2) t
ORDER BY
    1
LIMIT 8;

SELECT
    *
FROM (
    SELECT
        a || b AS ab
    FROM
        t1
    UNION ALL
    SELECT
        ab
    FROM
        t2) t
ORDER BY
    1
LIMIT 8;

RESET enable_seqscan;

RESET enable_indexscan;

RESET enable_bitmapscan;

-- This simpler variant of the above test has been observed to fail differently
CREATE TABLE events (
    event_id int PRIMARY KEY
);

CREATE TABLE other_events (
    event_id int PRIMARY KEY
);

CREATE TABLE events_child ()
INHERITS (
    events
);

EXPLAIN (
    COSTS OFF
)
SELECT
    event_id
FROM (
    SELECT
        event_id
    FROM
        events
    UNION ALL
    SELECT
        event_id
    FROM
        other_events) ss
ORDER BY
    event_id;

DROP TABLE events_child, events, other_events;

RESET enable_indexonlyscan;

-- Test constraint exclusion of UNION ALL subqueries
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS t,
        *
    FROM
        tenk1 a
    UNION ALL
    SELECT
        2 AS t,
        *
    FROM
        tenk1 b) c
WHERE
    t = 2;

-- Test that we push quals into UNION sub-selects only when it's safe
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS t,
        2 AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x < 4
ORDER BY
    x;

SELECT
    *
FROM (
    SELECT
        1 AS t,
        2 AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x < 4
ORDER BY
    x;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS t,
        generate_series(1, 10) AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x < 4
ORDER BY
    x;

SELECT
    *
FROM (
    SELECT
        1 AS t,
        generate_series(1, 10) AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x < 4
ORDER BY
    x;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS t,
        (random() * 3)::int AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x > 3
ORDER BY
    x;

SELECT
    *
FROM (
    SELECT
        1 AS t,
        (random() * 3)::int AS x
    UNION
    SELECT
        2 AS t,
        4 AS x) ss
WHERE
    x > 3
ORDER BY
    x;

-- Test proper handling of parameterized appendrel paths when the
-- potential join qual is expensive
CREATE FUNCTION expensivefunc (int)
    RETURNS int
    LANGUAGE plpgsql
    IMMUTABLE STRICT
    COST 10000
    AS $$
BEGIN
    RETURN $1;
END
$$;

CREATE temp TABLE t3 AS
SELECT
    generate_series(-1000, 1000) AS x;

CREATE INDEX t3i ON t3 (expensivefunc (x));

ANALYZE t3;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t3 a
    UNION ALL
    SELECT
        *
    FROM
        t3 b) ss
    JOIN int4_tbl ON f1 = expensivefunc (x);

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t3 a
    UNION ALL
    SELECT
        *
    FROM
        t3 b) ss
    JOIN int4_tbl ON f1 = expensivefunc (x);

DROP TABLE t3;

DROP FUNCTION expensivefunc (int);

-- Test handling of appendrel quals that const-simplify into an AND
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *,
        0 AS x
    FROM
        int8_tbl a
    UNION ALL
    SELECT
        *,
        1 AS x
    FROM
        int8_tbl b) ss
WHERE (x = 0)
    OR (q1 >= q2
        AND q1 <= q2);

SELECT
    *
FROM (
    SELECT
        *,
        0 AS x
    FROM
        int8_tbl a
    UNION ALL
    SELECT
        *,
        1 AS x
    FROM
        int8_tbl b) ss
WHERE (x = 0)
    OR (q1 >= q2
        AND q1 <= q2);

