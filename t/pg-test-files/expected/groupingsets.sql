--
-- grouping sets
--
-- test data sources
CREATE temp VIEW gstest1 (a, b, v) AS
VALUES (1,
    1,
    10),
(1,
    1,
    11),
(1,
    2,
    12),
(1,
    2,
    13),
(1,
    3,
    14),
(2,
    3,
    15),
(3,
    3,
    16),
(3,
    4,
    17),
(4,
    1,
    18),
(4,
    1,
    19);

CREATE temp TABLE gstest2 (
    a integer,
    b integer,
    c integer,
    d integer,
    e integer,
    f integer,
    g integer,
    h integer
);

copy gstest2 from stdin;
1	1	1	1	1	1	1	1
1	1	1	1	1	1	1	2
1	1	1	1	1	1	2	2
1	1	1	1	1	2	2	2
1	1	1	1	2	2	2	2
1	1	1	2	2	2	2	2
1	1	2	2	2	2	2	2
1	2	2	2	2	2	2	2
2	2	2	2	2	2	2	2
\.
CREATE temp TABLE gstest3 (
    a integer,
    b integer,
    c integer,
    d integer
);

copy gstest3 from stdin;
1	1	1	1
2	2	2	2
\.
ALTER TABLE gstest3
    ADD PRIMARY KEY (a);

CREATE temp TABLE gstest4 (
    id integer,
    v integer,
    unhashable_col bit(4),
    unsortable_col xid
);

INSERT INTO gstest4
VALUES
    (1, 1, b'0000', '1'),
    (2, 2, b'0001', '1'),
    (3, 4, b'0010', '2'),
    (4, 8, b'0011', '2'),
    (5, 16, b'0000', '2'),
    (6, 32, b'0001', '2'),
    (7, 64, b'0010', '1'),
    (8, 128, b'0011', '1');

CREATE temp TABLE gstest_empty (
    a integer,
    b integer,
    v integer
);

CREATE FUNCTION gstest_data (v integer, out a integer, out b integer)
    RETURNS SETOF record
    AS $f$
BEGIN
    RETURN QUERY
    SELECT
        v,
        i
    FROM
        generate_series(1, 3) i;
END;
$f$
LANGUAGE plpgsql;

-- basic functionality
SET enable_hashagg = FALSE;

-- test hashing explicitly later
-- simple rollup with multiple plain aggregates, with and without ordering
-- (and with ordering differing from grouping)
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    ROLLUP (a, b);

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    ROLLUP (a, b)
ORDER BY
    a,
    b;

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    ROLLUP (a, b)
ORDER BY
    b DESC,
    a;

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    ROLLUP (a, b)
ORDER BY
    coalesce(a, 0) + coalesce(b, 0);

-- various types of ordered aggs
SELECT
    a,
    b,
    GROUPING (a, b),
    array_agg(v ORDER BY v),
    string_agg(v::text, ':' ORDER BY v DESC),
    percentile_disc(0.5) WITHIN GROUP (ORDER BY v),
    rank(1, 2, 12) WITHIN GROUP (ORDER BY a, b, v)
FROM
    gstest1
GROUP BY
    ROLLUP (a, b)
ORDER BY
    a,
    b;

-- test usage of grouped columns in direct args of aggs
SELECT
    GROUPING (a),
    a,
    array_agg(b),
    rank(a) WITHIN GROUP (ORDER BY b nulls FIRST),
    rank(a) WITHIN GROUP (ORDER BY b nulls LAST)
FROM (
    VALUES (1, 1),
        (1, 4),
        (1, 5),
        (3, 1),
        (3, 2)) v (a, b)
GROUP BY
    ROLLUP (a)
ORDER BY
    a;

-- nesting with window functions
SELECT
    a,
    b,
    sum(c),
    sum(sum(c)) OVER (ORDER BY a, b) AS rsum
FROM
    gstest2
GROUP BY
    ROLLUP (a, b)
ORDER BY
    rsum,
    a,
    b;

-- nesting with grouping sets
SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((),
    GROUPING SETS ((),
    GROUPING SETS (())))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((),
    GROUPING SETS ((),
    GROUPING SETS (((a,
                b)))))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (GROUPING SETS (ROLLUP (c), GROUPING SETS (CUBE (c))))
        ORDER BY
            1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (a,
        GROUPING SETS (a,
            CUBE (b)))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (GROUPING SETS ((a,
                (b))))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (GROUPING SETS ((a,
                b)))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (GROUPING SETS (a,
            GROUPING SETS (a),
            a))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS (GROUPING SETS (a,
            GROUPING SETS (a,
                GROUPING SETS (a),
                ((a)),
                a,
                GROUPING SETS (a),
                (a)),
            a))
ORDER BY
    1 DESC;

SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a,
            (a,
                b)),
        GROUPING SETS ((a,
                (a,
                    b)),
            a))
ORDER BY
    1 DESC;

-- empty input: first is 0 rows, second 1, third 3 etc.
SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        a);

SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        ());

SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        (),
    (),
());

SELECT
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((),
    (),
());

-- empty input with joins tests some important code paths
SELECT
    t1.a,
    t2.b,
    sum(t1.v),
    count(*)
FROM
    gstest_empty t1,
    gstest_empty t2
GROUP BY
    GROUPING SETS ((t1.a,
            t2.b),
        ());

-- simple joins, var resolution, GROUPING on join vars
SELECT
    t1.a,
    t2.b,
    GROUPING (t1.a, t2.b),
    sum(t1.v),
    max(t2.a)
FROM
    gstest1 t1,
    gstest2 t2
GROUP BY
    GROUPING SETS ((t1.a,
            t2.b),
        ());

SELECT
    t1.a,
    t2.b,
    GROUPING (t1.a, t2.b),
    sum(t1.v),
    max(t2.a)
FROM
    gstest1 t1
    JOIN gstest2 t2 ON (t1.a = t2.a)
GROUP BY
    GROUPING SETS ((t1.a,
            t2.b),
        ());

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(t1.v),
    max(t2.c)
FROM
    gstest1 t1
    JOIN gstest2 t2 USING (a, b)
GROUP BY
    GROUPING SETS ((a,
            b),
        ());

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(t1.v),
    max(t2.c)
FROM
    gstest1 t1
    FULL JOIN gstest2 t2 USING (a, b)
GROUP BY
    GROUPING SETS ((a,
            b),
        ());

-- references in subqueries should work too
SELECT
    (
        SELECT
            a),
    (
        SELECT
            b),
    (
        SELECT
            GROUPING (a, b)),
    (
        SELECT
            sum(t1.v)),
    (
        SELECT
            max(t2.c))
FROM
    gstest1 t1
    FULL JOIN gstest2 t2 USING (a, b)
GROUP BY
    GROUPING SETS ((a,
            b),
        ());

-- check that functionally dependent cols are not nulled
SELECT
    a,
    d,
    GROUPING (a, b, c)
FROM
    gstest3
GROUP BY
    GROUPING SETS ((a,
            b),
        (a,
            c));

-- check that distinct grouping columns are kept separate
-- even if they are equal()
EXPLAIN (
    COSTS OFF
)
SELECT
    g AS alias1,
    g AS alias2
FROM
    generate_series(1, 3) g
GROUP BY
    alias1,
    ROLLUP (alias2);

SELECT
    g AS alias1,
    g AS alias2
FROM
    generate_series(1, 3) g
GROUP BY
    alias1,
    ROLLUP (alias2);

-- check that pulled-up subquery outputs still go to null when appropriate
SELECT
    four,
    x
FROM (
    SELECT
        four,
        ten,
        'foo'::text AS x
    FROM
        tenk1) AS t
GROUP BY
    GROUPING SETS (four,
        x)
HAVING
    x = 'foo';

SELECT
    four,
    x || 'x'
FROM (
    SELECT
        four,
        ten,
        'foo'::text AS x
    FROM
        tenk1) AS t
GROUP BY
    GROUPING SETS (four,
        x)
ORDER BY
    four;

SELECT
    (x + y) * 1,
    sum(z)
FROM (
    SELECT
        1 AS x,
        2 AS y,
        3 AS z) s
GROUP BY
    GROUPING SETS (x + y,
        x);

SELECT
    x,
    NOT x AS not_x,
    q2
FROM (
    SELECT
        *,
        q1 = 1 AS x
    FROM
        int8_tbl i1) AS t
GROUP BY
    GROUPING SETS (x,
        q2)
ORDER BY
    x,
    q2;

SELECT
    x,
    y
FROM (
    SELECT
        four AS x,
        four AS y
    FROM
        tenk1) AS t
GROUP BY
    GROUPING SETS (x,
        y)
HAVING
    y IS NULL
ORDER BY
    1,
    2;

SELECT
    x,
    y || 'y'
FROM (
    SELECT
        four AS x,
        four AS y
    FROM
        tenk1) AS t
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;

-- check that operands wrapped in PlaceHolderVars are capable of index matching
BEGIN;
SET local enable_bitmapscan = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    x,
    y
FROM (
    SELECT
        unique1 AS x,
        unique2 AS y
    FROM
        tenk1) AS t
WHERE
    x = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
SELECT
    x,
    y
FROM (
    SELECT
        unique1 AS x,
        unique2 AS y
    FROM
        tenk1) AS t
WHERE
    x = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
EXPLAIN (
    COSTS OFF
)
SELECT
    x,
    y
FROM (
    SELECT
        unique1::oid AS x,
        unique2 AS y
    FROM
        tenk1) AS t
WHERE
    x::integer = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
SELECT
    x,
    y
FROM (
    SELECT
        unique1::oid AS x,
        unique2 AS y
    FROM
        tenk1) AS t
WHERE
    x::integer = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
EXPLAIN (
    COSTS OFF
)
SELECT
    x,
    y
FROM (
    SELECT
        t1.unique1 AS x,
        t1.unique2 AS y
    FROM
        tenk1 t1,
        tenk1 t2) AS t
WHERE
    x = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
SELECT
    x,
    y
FROM (
    SELECT
        t1.unique1 AS x,
        t1.unique2 AS y
    FROM
        tenk1 t1,
        tenk1 t2) AS t
WHERE
    x = 1
GROUP BY
    GROUPING SETS (x,
        y)
ORDER BY
    1,
    2;
ROLLBACK;

-- check qual push-down rules for a subquery with grouping sets
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS x,
        q1,
        sum(q2)
    FROM
        int8_tbl i1
    GROUP BY
        GROUPING SETS (1,
            2)) ss
WHERE
    x = 1
    AND q1 = 123;

SELECT
    *
FROM (
    SELECT
        1 AS x,
        q1,
        sum(q2)
    FROM
        int8_tbl i1
    GROUP BY
        GROUPING SETS (1,
            2)) ss
WHERE
    x = 1
    AND q1 = 123;

-- check handling of pulled-up SubPlan in GROUPING() argument (bug #17479)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    GROUPING (ss.x)
FROM
    int8_tbl i1
    CROSS JOIN LATERAL (
        SELECT
            (
                SELECT
                    i1.q1) AS x) ss
GROUP BY
    ss.x;

SELECT
    GROUPING (ss.x)
FROM
    int8_tbl i1
    CROSS JOIN LATERAL (
        SELECT
            (
                SELECT
                    i1.q1) AS x) ss
GROUP BY
    ss.x;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (
        SELECT
            GROUPING (ss.x))
    FROM
        int8_tbl i1
    CROSS JOIN LATERAL (
        SELECT
            (
                SELECT
                    i1.q1) AS x) ss
GROUP BY
    ss.x;

SELECT
    (
        SELECT
            GROUPING (ss.x))
    FROM
        int8_tbl i1
    CROSS JOIN LATERAL (
        SELECT
            (
                SELECT
                    i1.q1) AS x) ss
GROUP BY
    ss.x;

-- simple rescan tests
SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    ROLLUP (a, b);

SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x),
    LATERAL (
        SELECT
            a, b, sum(v.x)
        FROM
            gstest_data (v.x)
        GROUP BY
            ROLLUP (a, b)) s;

-- min max optimization should still work with GROUP BY ()
EXPLAIN (
    COSTS OFF
)
SELECT
    min(unique1)
FROM
    tenk1
GROUP BY
    ();

-- Views with GROUPING SET queries
CREATE VIEW gstest_view AS
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(c),
    count(*),
    max(c)
FROM
    gstest2
GROUP BY
    ROLLUP ((a, b, c), (c, d));

SELECT
    pg_get_viewdef('gstest_view'::regclass, TRUE);

-- Nested queries with 3 or more levels of nesting
SELECT
    (
        SELECT
            (
                SELECT
                    GROUPING (a, b)
                FROM (
                VALUES (1)) v2 (c))
                FROM (
                VALUES (1, 2)) v1 (a, b)
                GROUP BY
                    (a, b))
            FROM (
                VALUES (6, 7)) v3 (e, f)
        GROUP BY
            ROLLUP (e, f);

SELECT
    (
        SELECT
            (
                SELECT
                    GROUPING (e, f)
                FROM (
                VALUES (1)) v2 (c))
                FROM (
                VALUES (1, 2)) v1 (a, b)
                GROUP BY
                    (a, b))
            FROM (
                VALUES (6, 7)) v3 (e, f)
        GROUP BY
            ROLLUP (e, f);

SELECT
    (
        SELECT
            (
                SELECT
                    GROUPING (c)
                FROM (
                VALUES (1)) v2 (c)
                GROUP BY
                    c)
                FROM (
                VALUES (1, 2)) v1 (a, b)
                GROUP BY
                    (a, b))
            FROM (
                VALUES (6, 7)) v3 (e, f)
        GROUP BY
            ROLLUP (e, f);

-- Combinations of operations
SELECT
    a,
    b,
    c,
    d
FROM
    gstest2
GROUP BY
    ROLLUP (a, b),
    GROUPING SETS (c,
        d);

SELECT
    a,
    b
FROM (
    VALUES (1, 2),
        (2, 3)) v (a, b)
GROUP BY
    a,
    b,
    GROUPING SETS (a);

-- Tests for chained aggregates
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a,
            b),
        (a + 1,
            b + 1),
        (a + 2,
            b + 2))
ORDER BY
    3,
    6;

SELECT
    (
        SELECT
            (
                SELECT
                    GROUPING (a, b)
                FROM (
                VALUES (1)) v2 (c))
                FROM (
                VALUES (1, 2)) v1 (a, b)
                GROUP BY
                    (a, b))
            FROM (
                VALUES (6, 7)) v3 (e, f)
        GROUP BY
            ROLLUP ((e + 1), (f + 1));

SELECT
    (
        SELECT
            (
                SELECT
                    GROUPING (a, b)
                FROM (
                VALUES (1)) v2 (c))
                FROM (
                VALUES (1, 2)) v1 (a, b)
                GROUP BY
                    (a, b))
            FROM (
                VALUES (6, 7)) v3 (e, f)
        GROUP BY
            CUBE ((e + 1),
                (f + 1))
        ORDER BY
            (e + 1),
            (f + 1);

SELECT
    a,
    b,
    sum(c),
    sum(sum(c)) OVER (ORDER BY a, b) AS rsum
FROM
    gstest2
GROUP BY
    CUBE (a,
        b)
ORDER BY
    rsum,
    a,
    b;

SELECT
    a,
    b,
    sum(c)
FROM (
    VALUES (1, 1, 10),
        (1, 1, 11),
        (1, 2, 12),
        (1, 2, 13),
        (1, 3, 14),
        (2, 3, 15),
        (3, 3, 16),
        (3, 4, 17),
        (4, 1, 18),
        (4, 1, 19)) v (a, b, c)
GROUP BY
    ROLLUP (a, b);

SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    CUBE (a,
        b)
ORDER BY
    a,
    b;

-- Test reordering of grouping sets
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a,
            b,
            v),
        (v))
ORDER BY
    v,
    b,
    a;

-- Agg level check. This query should error out.
SELECT
    (
        SELECT
            GROUPING (a, b)
        FROM
            gstest2)
    FROM
        gstest2
    GROUP BY
        a,
        b;

--Nested queries
SELECT
    a,
    b,
    sum(c),
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS (ROLLUP (a, b), a);

-- HAVING queries
SELECT
    ten,
    sum(DISTINCT four)
FROM
    onek a
GROUP BY
    GROUPING SETS ((ten,
            four),
        (ten))
HAVING
    EXISTS (
        SELECT
            1
        FROM
            onek b
        WHERE
            sum(DISTINCT a.four) = b.four);

-- Tests around pushdown of HAVING clauses, partially testing against previous bugs
SELECT
    a,
    count(*)
FROM
    gstest2
GROUP BY
    ROLLUP (a)
ORDER BY
    a;

SELECT
    a,
    count(*)
FROM
    gstest2
GROUP BY
    ROLLUP (a)
HAVING
    a IS DISTINCT FROM 1
ORDER BY
    a;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    count(*)
FROM
    gstest2
GROUP BY
    ROLLUP (a)
HAVING
    a IS DISTINCT FROM 1
ORDER BY
    a;

SELECT
    v.c,
    (
        SELECT
            count(*)
        FROM
            gstest2
        GROUP BY
            ()
    HAVING
        v.c)
FROM (
    VALUES (FALSE),
        (TRUE)) v (c)
ORDER BY
    v.c;

EXPLAIN (
    COSTS OFF
)
SELECT
    v.c,
    (
        SELECT
            count(*)
        FROM
            gstest2
        GROUP BY
            ()
    HAVING
        v.c)
FROM (
    VALUES (FALSE),
        (TRUE)) v (c)
ORDER BY
    v.c;

-- test pushdown of non-degenerate HAVING clause that does not reference any
-- columns that are nullable by grouping sets
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
HAVING
    a > 1
    AND b > 1;

SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
HAVING
    a > 1
    AND b > 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    ROLLUP (a),
    b
HAVING
    b > 1;

SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    ROLLUP (a),
    b
HAVING
    b > 1;

-- test pushdown of degenerate HAVING clause
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS (())
HAVING
    FALSE;

SELECT
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS (())
HAVING
    FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a),
        ())
HAVING
    FALSE;

SELECT
    a,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a),
        ())
HAVING
    FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a),
        (b))
HAVING
    FALSE;

SELECT
    a,
    b,
    count(*)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((a),
        (b))
HAVING
    FALSE;

-- HAVING with GROUPING queries
SELECT
    ten,
    GROUPING (ten)
FROM
    onek
GROUP BY
    GROUPING SETS (ten)
HAVING
    GROUPING (ten) >= 0
ORDER BY
    2,
    1;

SELECT
    ten,
    GROUPING (ten)
FROM
    onek
GROUP BY
    GROUPING SETS (ten,
        four)
HAVING
    GROUPING (ten) > 0
ORDER BY
    2,
    1;

SELECT
    ten,
    GROUPING (ten)
FROM
    onek
GROUP BY
    ROLLUP (ten)
HAVING
    GROUPING (ten) > 0
ORDER BY
    2,
    1;

SELECT
    ten,
    GROUPING (ten)
FROM
    onek
GROUP BY
    CUBE (ten)
HAVING
    GROUPING (ten) > 0
ORDER BY
    2,
    1;

SELECT
    ten,
    GROUPING (ten)
FROM
    onek
GROUP BY
    (ten)
HAVING
    GROUPING (ten) >= 0
ORDER BY
    2,
    1;

-- FILTER queries
SELECT
    ten,
    sum(DISTINCT four) FILTER (WHERE four::text ~ '123')
FROM
    onek a
GROUP BY
    ROLLUP (ten);

-- More rescan tests
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (a)
    LEFT JOIN LATERAL (
        SELECT
            v.a, four, ten, count(*)
        FROM
            onek
        GROUP BY
            CUBE (four,
                ten)) s ON TRUE
ORDER BY
    v.a,
    four,
    ten;

SELECT
    ARRAY(
        SELECT
            ROW (v.a, s1.*)
        FROM (
            SELECT
                two, four, count(*)
            FROM onek
            GROUP BY
                CUBE (two, four)
            ORDER BY
                two, four) s1)
FROM (
    VALUES (1),
        (2)) v (a);

-- Grouping on text columns
SELECT
    sum(ten)
FROM
    onek
GROUP BY
    two,
    ROLLUP (four::text)
ORDER BY
    1;

SELECT
    sum(ten)
FROM
    onek
GROUP BY
    ROLLUP (four::text),
    two
ORDER BY
    1;

-- hashing support
SET enable_hashagg = TRUE;

-- failure cases
SELECT
    count(*)
FROM
    gstest4
GROUP BY
    ROLLUP (unhashable_col, unsortable_col);

SELECT
    array_agg(v ORDER BY v)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((id,
            unsortable_col),
        (id));

-- simple cases
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a),
        (b))
ORDER BY
    3,
    1,
    2;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a),
        (b))
ORDER BY
    3,
    1,
    2;

SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    CUBE (a,
        b)
ORDER BY
    3,
    1,
    2;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    CUBE (a,
        b)
ORDER BY
    3,
    1,
    2;

-- shouldn't try and hash
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    GROUPING (a, b),
    array_agg(v ORDER BY v)
FROM
    gstest1
GROUP BY
    CUBE (a,
        b);

-- unsortable cases
SELECT
    unsortable_col,
    count(*)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((unsortable_col),
        (unsortable_col))
ORDER BY
    unsortable_col::text;

-- mixed hashable/sortable cases
SELECT
    unhashable_col,
    unsortable_col,
    GROUPING (unhashable_col, unsortable_col),
    count(*),
    sum(v)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((unhashable_col),
        (unsortable_col))
ORDER BY
    3,
    5;

EXPLAIN (
    COSTS OFF
)
SELECT
    unhashable_col,
    unsortable_col,
    GROUPING (unhashable_col, unsortable_col),
    count(*),
    sum(v)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((unhashable_col),
        (unsortable_col))
ORDER BY
    3,
    5;

SELECT
    unhashable_col,
    unsortable_col,
    GROUPING (unhashable_col, unsortable_col),
    count(*),
    sum(v)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((v,
            unhashable_col),
        (v,
            unsortable_col))
ORDER BY
    3,
    5;

EXPLAIN (
    COSTS OFF
)
SELECT
    unhashable_col,
    unsortable_col,
    GROUPING (unhashable_col, unsortable_col),
    count(*),
    sum(v)
FROM
    gstest4
GROUP BY
    GROUPING SETS ((v,
            unhashable_col),
        (v,
            unsortable_col))
ORDER BY
    3,
    5;

-- empty input: first is 0 rows, second 1, third 3 etc.
SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        a);

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        a);

SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        ());

SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        (),
    (),
());

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((a,
            b),
        (),
    (),
());

SELECT
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((),
    (),
());

EXPLAIN (
    COSTS OFF
)
SELECT
    sum(v),
    count(*)
FROM
    gstest_empty
GROUP BY
    GROUPING SETS ((),
    (),
());

-- check that functionally dependent cols are not nulled
SELECT
    a,
    d,
    GROUPING (a, b, c)
FROM
    gstest3
GROUP BY
    GROUPING SETS ((a,
            b),
        (a,
            c));

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    d,
    GROUPING (a, b, c)
FROM
    gstest3
GROUP BY
    GROUPING SETS ((a,
            b),
        (a,
            c));

-- simple rescan tests
SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    GROUPING SETS (a,
        b)
ORDER BY
    1,
    2,
    3;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    GROUPING SETS (a,
        b)
ORDER BY
    3,
    1,
    2;

SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x),
    LATERAL (
        SELECT
            a, b, sum(v.x)
        FROM
            gstest_data (v.x)
        GROUP BY
            GROUPING SETS (a,
                b)) s;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x),
    LATERAL (
        SELECT
            a, b, sum(v.x)
        FROM
            gstest_data (v.x)
        GROUP BY
            GROUPING SETS (a,
                b)) s;

-- Tests for chained aggregates
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a,
            b),
        (a + 1,
            b + 1),
        (a + 2,
            b + 2))
ORDER BY
    3,
    6;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    GROUPING (a, b),
    sum(v),
    count(*),
    max(v)
FROM
    gstest1
GROUP BY
    GROUPING SETS ((a,
            b),
        (a + 1,
            b + 1),
        (a + 2,
            b + 2))
ORDER BY
    3,
    6;

SELECT
    a,
    b,
    sum(c),
    sum(sum(c)) OVER (ORDER BY a, b) AS rsum
FROM
    gstest2
GROUP BY
    CUBE (a,
        b)
ORDER BY
    rsum,
    a,
    b;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(c),
    sum(sum(c)) OVER (ORDER BY a, b) AS rsum
FROM
    gstest2
GROUP BY
    CUBE (a,
        b)
ORDER BY
    rsum,
    a,
    b;

SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    CUBE (a,
        b)
ORDER BY
    a,
    b;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(v.x)
FROM (
    VALUES (1),
        (2)) v (x),
    gstest_data (v.x)
GROUP BY
    CUBE (a,
        b)
ORDER BY
    a,
    b;

-- Verify that we correctly handle the child node returning a
-- non-minimal slot, which happens if the input is pre-sorted,
-- e.g. due to an index scan.
BEGIN;
SET LOCAL enable_hashagg = FALSE;
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    count(*),
    max(a),
    max(b)
FROM
    gstest3
GROUP BY
    GROUPING SETS (a,
        b,
        ())
ORDER BY
    a,
    b;
SELECT
    a,
    b,
    count(*),
    max(a),
    max(b)
FROM
    gstest3
GROUP BY
    GROUPING SETS (a,
        b,
        ())
ORDER BY
    a,
    b;
SET LOCAL enable_seqscan = FALSE;
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    count(*),
    max(a),
    max(b)
FROM
    gstest3
GROUP BY
    GROUPING SETS (a,
        b,
        ())
ORDER BY
    a,
    b;
SELECT
    a,
    b,
    count(*),
    max(a),
    max(b)
FROM
    gstest3
GROUP BY
    GROUPING SETS (a,
        b,
        ())
ORDER BY
    a,
    b;
COMMIT;

-- Verify handling of injecting NULL values for the rollup row works correctly
-- when additional columns need to be deformed from the tuple after the NULL
-- is added.
BEGIN;
INSERT INTO gstest3
    VALUES (3, 4, NULL, 5);
SET enable_hashagg = FALSE;
SELECT
    b,
    c,
    d,
    GROUPING (b, c) AS g
FROM
    gstest3
WHERE
    a = 3
GROUP BY
    GROUPING SETS ((a,
            b),
        (a,
            c));
ROLLBACK;

-- More rescan tests
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (a)
    LEFT JOIN LATERAL (
        SELECT
            v.a, four, ten, count(*)
        FROM
            onek
        GROUP BY
            CUBE (four,
                ten)) s ON TRUE
ORDER BY
    v.a,
    four,
    ten;

SELECT
    ARRAY(
        SELECT
            ROW (v.a, s1.*)
        FROM (
            SELECT
                two, four, count(*)
            FROM onek
            GROUP BY
                CUBE (two, four)
            ORDER BY
                two, four) s1)
FROM (
    VALUES (1),
        (2)) v (a);

-- Rescan logic changes when there are no empty grouping sets, so test
-- that too:
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (a)
    LEFT JOIN LATERAL (
        SELECT
            v.a, four, ten, count(*)
        FROM
            onek
        GROUP BY
            GROUPING SETS (four,
                ten)) s ON TRUE
ORDER BY
    v.a,
    four,
    ten;

SELECT
    ARRAY(
        SELECT
            ROW (v.a, s1.*)
        FROM (
            SELECT
                two, four, count(*)
            FROM onek
            GROUP BY
                GROUPING SETS (two, four)
            ORDER BY
                two, four) s1)
FROM (
    VALUES (1),
        (2)) v (a);

-- test the knapsack
SET enable_indexscan = FALSE;

SET hash_mem_multiplier = 1.0;

SET work_mem = '64kB';

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    count(two),
    count(four),
    count(ten),
    count(hundred),
    count(thousand),
    count(twothousand),
    count(*)
FROM
    tenk1
GROUP BY
    GROUPING SETS (unique1,
        twothousand,
        thousand,
        hundred,
        ten,
        four,
        two);

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    count(two),
    count(four),
    count(ten),
    count(hundred),
    count(thousand),
    count(twothousand),
    count(*)
FROM
    tenk1
GROUP BY
    GROUPING SETS (unique1,
        hundred,
        ten,
        four,
        two);

SET work_mem = '384kB';

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    count(two),
    count(four),
    count(ten),
    count(hundred),
    count(thousand),
    count(twothousand),
    count(*)
FROM
    tenk1
GROUP BY
    GROUPING SETS (unique1,
        twothousand,
        thousand,
        hundred,
        ten,
        four,
        two);

-- check collation-sensitive matching between grouping expressions
-- (similar to a check for aggregates, but there are additional code
-- paths for GROUPING, so check again here)
SELECT
    v || 'a',
    CASE GROUPING (v || 'a')
    WHEN 1 THEN
        1
    ELSE
        0
    END,
    count(*)
FROM
    unnest(ARRAY[1, 1], ARRAY['a', 'b']) u (i,
        v)
GROUP BY
    ROLLUP (i, v || 'a')
ORDER BY
    1,
    3;

SELECT
    v || 'a',
    CASE WHEN GROUPING (v || 'a') = 1 THEN
        1
    ELSE
        0
    END,
    count(*)
FROM
    unnest(ARRAY[1, 1], ARRAY['a', 'b']) u (i,
        v)
GROUP BY
    ROLLUP (i, v || 'a')
ORDER BY
    1,
    3;

-- Bug #16784
CREATE TABLE bug_16784 (
    i int,
    j int
);

ANALYZE bug_16784;

ALTER TABLE bug_16784 SET (autovacuum_enabled = 'false');

UPDATE
    pg_class
SET
    reltuples = 10
WHERE
    relname = 'bug_16784';

INSERT INTO bug_16784
SELECT
    g / 10,
    g
FROM
    generate_series(1, 40) g;

SET work_mem = '64kB';

SET enable_groupagg = FALSE;

SELECT
    *
FROM (
    VALUES (1),
        (2)) v (a),
    LATERAL (
        SELECT
            a, i, j, count(*)
        FROM
            bug_16784
        GROUP BY
            CUBE (i,
                j)) s
ORDER BY
    v.a,
    i,
    j;

--
-- Compare results between plans using sorting and plans using hash
-- aggregation. Force spilling in both cases by setting work_mem low
-- and altering the statistics.
--
CREATE TABLE gs_data_1 AS
SELECT
    g % 1000 AS g1000,
    g % 100 AS g100,
    g % 10 AS g10,
    g
FROM
    generate_series(0, 1999) g;

ANALYZE gs_data_1;

ALTER TABLE gs_data_1 SET (autovacuum_enabled = 'false');

UPDATE
    pg_class
SET
    reltuples = 10
WHERE
    relname = 'gs_data_1';

SET work_mem = '64kB';

-- Produce results with sorting.
SET enable_groupagg = TRUE;

SET enable_hashagg = FALSE;

SET jit_above_cost = 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    g100,
    g10,
    sum(g::numeric),
    count(*),
    max(g::text)
FROM
    gs_data_1
GROUP BY
    CUBE (g1000,
        g100,
        g10);

CREATE TABLE gs_group_1 AS
SELECT
    g100,
    g10,
    sum(g::numeric),
    count(*),
    max(g::text)
FROM
    gs_data_1
GROUP BY
    CUBE (g1000,
        g100,
        g10);

-- Produce results with hash aggregation.
SET enable_hashagg = TRUE;

SET enable_groupagg = FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    g100,
    g10,
    sum(g::numeric),
    count(*),
    max(g::text)
FROM
    gs_data_1
GROUP BY
    CUBE (g1000,
        g100,
        g10);

CREATE TABLE gs_hash_1 AS
SELECT
    g100,
    g10,
    sum(g::numeric),
    count(*),
    max(g::text)
FROM
    gs_data_1
GROUP BY
    CUBE (g1000,
        g100,
        g10);

SET enable_groupagg = TRUE;

SET work_mem TO DEFAULT;

SET hash_mem_multiplier TO DEFAULT;

-- Compare results
(
    SELECT
        *
    FROM
        gs_hash_1
    EXCEPT
    SELECT
        *
    FROM
        gs_group_1)
UNION ALL (
    SELECT
        *
    FROM
        gs_group_1
    EXCEPT
    SELECT
        *
    FROM
        gs_hash_1);

DROP TABLE gs_group_1;

DROP TABLE gs_hash_1;

-- GROUP BY DISTINCT
-- "normal" behavior...
SELECT
    a,
    b,
    c
FROM (
    VALUES (1, 2, 3),
        (4, NULL, 6),
        (7, 8, 9)) AS t (a, b, c)
GROUP BY
    ALL ROLLUP (a, b),
    ROLLUP (a, c)
ORDER BY
    a,
    b,
    c;

-- ...which is also the default
SELECT
    a,
    b,
    c
FROM (
    VALUES (1, 2, 3),
        (4, NULL, 6),
        (7, 8, 9)) AS t (a, b, c)
GROUP BY
    ROLLUP (a, b),
    ROLLUP (a, c)
ORDER BY
    a,
    b,
    c;

-- "group by distinct" behavior...
SELECT
    a,
    b,
    c
FROM (
    VALUES (1, 2, 3),
        (4, NULL, 6),
        (7, 8, 9)) AS t (a, b, c)
GROUP BY
    DISTINCT ROLLUP (a, b),
    ROLLUP (a, c)
ORDER BY
    a,
    b,
    c;

-- ...which is not the same as "select distinct"
SELECT DISTINCT
    a,
    b,
    c
FROM (
    VALUES (1, 2, 3),
        (4, NULL, 6),
        (7, 8, 9)) AS t (a, b, c)
GROUP BY
    ROLLUP (a, b),
    ROLLUP (a, c)
ORDER BY
    a,
    b,
    c;

-- test handling of outer GroupingFunc within subqueries
EXPLAIN (
    COSTS OFF
)
SELECT
    (
        SELECT
            GROUPING (v1))
    FROM (
        VALUES ((
                    SELECT
                        1))) v (v1)
GROUP BY
    CUBE (v1);

SELECT
    (
        SELECT
            GROUPING (v1))
    FROM (
        VALUES ((
                    SELECT
                        1))) v (v1)
GROUP BY
    CUBE (v1);

EXPLAIN (
    COSTS OFF
)
SELECT
    (
        SELECT
            GROUPING (v1))
    FROM (
        VALUES ((
                    SELECT
                        1))) v (v1)
GROUP BY
    v1;

SELECT
    (
        SELECT
            GROUPING (v1))
    FROM (
        VALUES ((
                    SELECT
                        1))) v (v1)
GROUP BY
    v1;

-- test handling of subqueries in grouping sets
CREATE temp TABLE gstest5 (
    id integer PRIMARY KEY,
    v integer
);

INSERT INTO gstest5
SELECT
    i,
    i
FROM
    generate_series(1, 5) i;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)),
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id) AS s
FROM
    gstest5 t1
GROUP BY
    GROUPING SETS (v,
        s)
ORDER BY
    CASE WHEN GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)) = 0 THEN
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)
    ELSE
        NULL
    END nulls FIRST;

SELECT
    GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)),
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id) AS s
FROM
    gstest5 t1
GROUP BY
    GROUPING SETS (v,
        s)
ORDER BY
    CASE WHEN GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)) = 0 THEN
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)
    ELSE
        NULL
    END nulls FIRST;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)),
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id) AS s,
    CASE WHEN GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)) = 0 THEN
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)
    ELSE
        NULL
    END AS o
FROM
    gstest5 t1
GROUP BY
    GROUPING SETS (v,
        s)
ORDER BY
    o nulls FIRST;

SELECT
    GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)),
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id) AS s,
    CASE WHEN GROUPING ((
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)) = 0 THEN
    (
        SELECT
            t1.v
        FROM
            gstest5 t2
        WHERE
            id = t1.id)
    ELSE
        NULL
    END AS o
FROM
    gstest5 t1
GROUP BY
    GROUPING SETS (v,
        s)
ORDER BY
    o nulls FIRST;

-- test handling of expressions that should match lower target items
EXPLAIN (
    COSTS OFF
)
SELECT
    a < b
    AND b < 3
FROM (
    VALUES (1, 2)) t (a, b)
GROUP BY
    ROLLUP (a < b
        AND b < 3)
    HAVING
        a < b
        AND b < 3;

SELECT
    a < b
    AND b < 3
FROM (
    VALUES (1, 2)) t (a, b)
GROUP BY
    ROLLUP (a < b
        AND b < 3)
    HAVING
        a < b
        AND b < 3;

EXPLAIN (
    COSTS OFF
)
SELECT
    NOT a
FROM (
    VALUES (TRUE)) t (a)
GROUP BY
    ROLLUP (NOT a)
HAVING
    NOT NOT a;

SELECT
    NOT a
FROM (
    VALUES (TRUE)) t (a)
GROUP BY
    ROLLUP (NOT a)
HAVING
    NOT NOT a;

-- test handling of expressions nullable by grouping sets
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT ON (a, b)
    a,
    b
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
ORDER BY
    a,
    b;

SELECT DISTINCT ON (a, b)
    a,
    b
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
ORDER BY
    a,
    b;

EXPLAIN (
    COSTS OFF
) SELECT DISTINCT ON (a, b + 1)
    a,
    b + 1
FROM (
    VALUES (1, 0),
        (2, 1)) AS t (a, b)
WHERE
    a = b + 1
GROUP BY
    GROUPING SETS ((a,
            b + 1),
        (a))
ORDER BY
    a,
    b + 1;

SELECT DISTINCT ON (a, b + 1)
    a,
    b + 1
FROM (
    VALUES (1, 0),
        (2, 1)) AS t (a, b)
WHERE
    a = b + 1
GROUP BY
    GROUPING SETS ((a,
            b + 1),
        (a))
ORDER BY
    a,
    b + 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
ORDER BY
    a,
    b nulls FIRST;

SELECT
    a,
    b
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a))
ORDER BY
    a,
    b nulls FIRST;

EXPLAIN (
    COSTS OFF
)
SELECT
    1 AS one
GROUP BY
    ROLLUP (one)
ORDER BY
    one nulls FIRST;

SELECT
    1 AS one
GROUP BY
    ROLLUP (one)
ORDER BY
    one nulls FIRST;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    row_number() OVER (ORDER BY a, b nulls FIRST)
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a));

SELECT
    a,
    b,
    row_number() OVER (ORDER BY a, b nulls FIRST)
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
WHERE
    a = b
GROUP BY
    GROUPING SETS ((a,
            b),
        (a));

-- test handling of SRFs with grouping sets
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    generate_series(1, a) AS g
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
GROUP BY
    ROLLUP (g)
ORDER BY
    1;

SELECT
    generate_series(1, a) AS g
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
GROUP BY
    ROLLUP (g)
ORDER BY
    1;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    generate_series(1, a) AS g,
    a + b AS ab
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
GROUP BY
    ROLLUP (a, ab)
ORDER BY
    1,
    2;

SELECT
    generate_series(1, a) AS g,
    a + b AS ab
FROM (
    VALUES (1, 1),
        (2, 2)) AS t (a, b)
GROUP BY
    ROLLUP (a, ab)
ORDER BY
    1,
    2;

-- end
