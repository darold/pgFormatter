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

CREATE temp TABLE gstest3 (
    a integer,
    b integer,
    c integer,
    d integer
);

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
    RETURN query
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
    GROUPING SETS (a,
                b)))
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
    GROUPING SETS (GROUPING SETS (a,
                b))
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
                (a),
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
    ARRAY (
        SELECT
            ROW (v.a,
                s1.*)
        FROM (
            SELECT
                two,
                four,
                count(*)
            FROM
                onek
            GROUP BY
                CUBE (two,
                    four)
            ORDER BY
                two,
                four) s1)
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
    ARRAY (
        SELECT
            ROW (v.a,
                s1.*)
        FROM (
            SELECT
                two,
                four,
                count(*)
            FROM
                onek
            GROUP BY
                CUBE (two,
                    four)
            ORDER BY
                two,
                four) s1)
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
    ARRAY (
        SELECT
            ROW (v.a,
                s1.*)
        FROM (
            SELECT
                two,
                four,
                count(*)
            FROM
                onek
            GROUP BY
                GROUPING SETS (two,
                    four)
            ORDER BY
                two,
                four) s1)
FROM (
    VALUES (1),
        (2)) v (a);

-- test the knapsack
SET enable_indexscan = FALSE;

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

-- end
