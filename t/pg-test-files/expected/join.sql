--
-- JOIN
-- Test JOIN clauses
--
CREATE TABLE J1_TBL (
    i integer,
    j integer,
    t text
);

CREATE TABLE J2_TBL (
    i integer,
    k integer
);

INSERT INTO J1_TBL
    VALUES (1, 4, 'one');

INSERT INTO J1_TBL
    VALUES (2, 3, 'two');

INSERT INTO J1_TBL
    VALUES (3, 2, 'three');

INSERT INTO J1_TBL
    VALUES (4, 1, 'four');

INSERT INTO J1_TBL
    VALUES (5, 0, 'five');

INSERT INTO J1_TBL
    VALUES (6, 6, 'six');

INSERT INTO J1_TBL
    VALUES (7, 7, 'seven');

INSERT INTO J1_TBL
    VALUES (8, 8, 'eight');

INSERT INTO J1_TBL
    VALUES (0, NULL, 'zero');

INSERT INTO J1_TBL
    VALUES (NULL, NULL, 'null');

INSERT INTO J1_TBL
    VALUES (NULL, 0, 'zero');

INSERT INTO J2_TBL
    VALUES (1, -1);

INSERT INTO J2_TBL
    VALUES (2, 2);

INSERT INTO J2_TBL
    VALUES (3, -3);

INSERT INTO J2_TBL
    VALUES (2, 4);

INSERT INTO J2_TBL
    VALUES (5, -5);

INSERT INTO J2_TBL
    VALUES (5, -5);

INSERT INTO J2_TBL
    VALUES (0, NULL);

INSERT INTO J2_TBL
    VALUES (NULL, NULL);

INSERT INTO J2_TBL
    VALUES (NULL, 0);

-- useful in some tests below
CREATE temp TABLE onerow ();

INSERT INTO onerow DEFAULT VALUES; ANALYZE onerow;

--
-- CORRELATION NAMES
-- Make sure that table/column aliases are supported
-- before diving into more complex join syntax.
--
SELECT
    *
FROM
    J1_TBL AS tx;

SELECT
    *
FROM
    J1_TBL tx;

SELECT
    *
FROM
    J1_TBL AS t1 (a,
        b,
        c);

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c);

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c),
    J2_TBL t2 (d,
        e);

SELECT
    t1.a,
    t2.e
FROM
    J1_TBL t1 (a,
        b,
        c),
    J2_TBL t2 (d,
        e)
WHERE
    t1.a = t2.d;

--
-- CROSS JOIN
-- Qualifications are not allowed on cross joins,
-- which degenerate into a standard unqualified inner join.
--
SELECT
    *
FROM
    J1_TBL
    CROSS JOIN J2_TBL;

-- ambiguous column
SELECT
    i,
    k,
    t
FROM
    J1_TBL
    CROSS JOIN J2_TBL;

-- resolve previous ambiguity by specifying the table name
SELECT
    t1.i,
    k,
    t
FROM
    J1_TBL t1
    CROSS JOIN J2_TBL t2;

SELECT
    ii,
    tt,
    kk
FROM (J1_TBL
    CROSS JOIN J2_TBL) AS tx (ii,
        jj,
        tt,
        ii2,
        kk);

SELECT
    tx.ii,
    tx.jj,
    tx.kk
FROM (J1_TBL t1 (a,
        b,
        c)
    CROSS JOIN J2_TBL t2 (d,
        e)) AS tx (ii,
        jj,
        tt,
        ii2,
        kk);

SELECT
    *
FROM
    J1_TBL
    CROSS JOIN J2_TBL a
    CROSS JOIN J2_TBL b;

--
--
-- Inner joins (equi-joins)
--
--
--
-- Inner joins (equi-joins) with USING clause
-- The USING syntax changes the shape of the resulting table
-- by including a column in the USING clause only once in the result.
--
-- Inner equi-join on specified column
SELECT
    *
FROM
    J1_TBL
    INNER JOIN J2_TBL USING (i);

-- Same as above, slightly different syntax
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i);

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c)
    JOIN J2_TBL t2 (a,
        d)
    USING (a)
ORDER BY
    a,
    d;

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c)
    JOIN J2_TBL t2 (a,
        b)
    USING (b)
ORDER BY
    b,
    t1.a;

-- test join using aliases
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i)
WHERE
    J1_TBL.t = 'one';

-- ok
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    J1_TBL.t = 'one';

-- ok
SELECT
    *
FROM (J1_TBL
    JOIN J2_TBL USING (i)) AS x
WHERE
    J1_TBL.t = 'one';

-- error
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    x.i = 1;

-- ok
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    x.t = 'one';

-- error
SELECT
    *
FROM (J1_TBL
    JOIN J2_TBL USING (i) AS x) AS xx
WHERE
    x.i = 1;

-- error (XXX could use better hint)
SELECT
    *
FROM
    J1_TBL a1
    JOIN J2_TBL a2 USING (i) AS a1;

-- error
SELECT
    x.*
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    J1_TBL.t = 'one';

SELECT
    ROW (x.*)
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    J1_TBL.t = 'one';

SELECT
    row_to_json(x.*)
FROM
    J1_TBL
    JOIN J2_TBL USING (i) AS x
WHERE
    J1_TBL.t = 'one';

--
-- NATURAL JOIN
-- Inner equi-join on all columns with the same name
--
SELECT
    *
FROM
    J1_TBL
    NATURAL JOIN J2_TBL;

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c)
    NATURAL JOIN J2_TBL t2 (a,
        d);

SELECT
    *
FROM
    J1_TBL t1 (a,
        b,
        c)
    NATURAL JOIN J2_TBL t2 (d,
        a);

-- mismatch number of columns
-- currently, Postgres will fill in with underlying names
SELECT
    *
FROM
    J1_TBL t1 (a,
        b)
    NATURAL JOIN J2_TBL t2 (a);

--
-- Inner joins (equi-joins)
--
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i = J2_TBL.i);

SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i = J2_TBL.k);

--
-- Non-equi-joins
--
SELECT
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i <= J2_TBL.k);

--
-- Outer joins
-- Note that OUTER is a noise word
--
SELECT
    *
FROM
    J1_TBL
    LEFT OUTER JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    *
FROM
    J1_TBL
    LEFT JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    *
FROM
    J1_TBL
    RIGHT OUTER JOIN J2_TBL USING (i);

SELECT
    *
FROM
    J1_TBL
    RIGHT JOIN J2_TBL USING (i);

SELECT
    *
FROM
    J1_TBL
    FULL OUTER JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    *
FROM
    J1_TBL
    FULL JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    *
FROM
    J1_TBL
    LEFT JOIN J2_TBL USING (i)
WHERE (k = 1);

SELECT
    *
FROM
    J1_TBL
    LEFT JOIN J2_TBL USING (i)
WHERE (i = 1);

--
-- semijoin selectivity for <>
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a,
    tenk1 b
WHERE
    EXISTS (
        SELECT
            *
        FROM
            tenk1 c
        WHERE
            b.twothousand = c.twothousand
            AND b.fivethous <> c.fivethous)
    AND a.tenthous = b.tenthous
    AND a.tenthous < 5000;

--
-- More complicated constructs
--
--
-- Multiway full join
--
CREATE TABLE t1 (
    name text,
    n integer
);

CREATE TABLE t2 (
    name text,
    n integer
);

CREATE TABLE t3 (
    name text,
    n integer
);

INSERT INTO t1
    VALUES ('bb', 11);

INSERT INTO t2
    VALUES ('bb', 12);

INSERT INTO t2
    VALUES ('cc', 22);

INSERT INTO t2
    VALUES ('ee', 42);

INSERT INTO t3
    VALUES ('bb', 13);

INSERT INTO t3
    VALUES ('cc', 23);

INSERT INTO t3
    VALUES ('dd', 33);

SELECT
    *
FROM
    t1
    FULL JOIN t2 USING (name)
    FULL JOIN t3 USING (name);

--
-- Test interactions of join syntax and subqueries
--
-- Basic cases (we expect planner to pull up the subquery here)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t2) AS s2
    INNER JOIN (
        SELECT
            *
        FROM
            t3) s3 USING (name);

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t2) AS s2
    LEFT JOIN (
        SELECT
            *
        FROM
            t3) s3 USING (name);

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t2) AS s2
    FULL JOIN (
        SELECT
            *
        FROM
            t3) s3 USING (name);

-- Cases with non-nullable expressions in subquery results;
-- make sure these go to null as expected
SELECT
    *
FROM (
    SELECT
        name,
        n AS s2_n,
        2 AS s2_2
    FROM
        t2) AS s2
    NATURAL INNER JOIN (
        SELECT
            name,
            n AS s3_n,
            3 AS s3_2
        FROM
            t3) s3;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s2_n,
        2 AS s2_2
    FROM
        t2) AS s2
    NATURAL
    LEFT JOIN (
        SELECT
            name,
            n AS s3_n,
            3 AS s3_2
        FROM
            t3) s3;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s2_n,
        2 AS s2_2
    FROM
        t2) AS s2
    NATURAL
    FULL JOIN (
        SELECT
            name,
            n AS s3_n,
            3 AS s3_2
        FROM
            t3) s3;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s1_n,
        1 AS s1_1
    FROM
        t1) AS s1
    NATURAL INNER JOIN (
        SELECT
            name,
            n AS s2_n,
            2 AS s2_2
        FROM
            t2) AS s2
    NATURAL INNER JOIN (
        SELECT
            name,
            n AS s3_n,
            3 AS s3_2
        FROM
            t3) s3;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s1_n,
        1 AS s1_1
    FROM
        t1) AS s1
    NATURAL
    FULL JOIN (
        SELECT
            name,
            n AS s2_n,
            2 AS s2_2
        FROM
            t2) AS s2
    NATURAL
    FULL JOIN (
        SELECT
            name,
            n AS s3_n,
            3 AS s3_2
        FROM
            t3) s3;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s1_n
    FROM
        t1) AS s1
    NATURAL
    FULL JOIN (
        SELECT
            *
        FROM (
            SELECT
                name,
                n AS s2_n
            FROM
                t2) AS s2
            NATURAL
            FULL JOIN (
                SELECT
                    name,
                    n AS s3_n
                FROM
                    t3) AS s3) ss2;

SELECT
    *
FROM (
    SELECT
        name,
        n AS s1_n
    FROM
        t1) AS s1
    NATURAL
    FULL JOIN (
        SELECT
            *
        FROM (
            SELECT
                name,
                n AS s2_n,
                2 AS s2_2
            FROM
                t2) AS s2
            NATURAL
            FULL JOIN (
                SELECT
                    name,
                    n AS s3_n
                FROM
                    t3) AS s3) ss2;

-- Constants as join keys can also be problematic
SELECT
    *
FROM (
    SELECT
        name,
        n AS s1_n
    FROM
        t1) AS s1
    FULL JOIN (
        SELECT
            name,
            2 AS s2_n
        FROM
            t2) AS s2 ON (s1_n = s2_n);

-- Test for propagation of nullability constraints into sub-joins
CREATE temp TABLE x (
    x1 int,
    x2 int
);

INSERT INTO x
    VALUES (1, 11);

INSERT INTO x
    VALUES (2, 22);

INSERT INTO x
    VALUES (3, NULL);

INSERT INTO x
    VALUES (4, 44);

INSERT INTO x
    VALUES (5, NULL);

CREATE temp TABLE y (
    y1 int,
    y2 int
);

INSERT INTO y
    VALUES (1, 111);

INSERT INTO y
    VALUES (2, 222);

INSERT INTO y
    VALUES (3, 333);

INSERT INTO y
    VALUES (4, NULL);

SELECT
    *
FROM
    x;

SELECT
    *
FROM
    y;

SELECT
    *
FROM
    x
    LEFT JOIN y ON (x1 = y1
            AND x2 IS NOT NULL);

SELECT
    *
FROM
    x
    LEFT JOIN y ON (x1 = y1
            AND y2 IS NOT NULL);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1
            AND x2 IS NOT NULL);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1
            AND y2 IS NOT NULL);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1
            AND xx2 IS NOT NULL);

-- these should NOT give the same answers as above
SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1)
WHERE (x2 IS NOT NULL);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1)
WHERE (y2 IS NOT NULL);

SELECT
    *
FROM (x
    LEFT JOIN y ON (x1 = y1))
    LEFT JOIN x xx (xx1,
        xx2) ON (x1 = xx1)
WHERE (xx2 IS NOT NULL);

--
-- regression test: check for bug with propagation of implied equality
-- to outside an IN
--
SELECT
    count(*)
FROM
    tenk1 a
WHERE
    unique1 IN (
        SELECT
            unique1
        FROM
            tenk1 b
            JOIN tenk1 c USING (unique1)
        WHERE
            b.unique2 = 42);

--
-- regression test: check for failure to generate a plan with multiple
-- degenerate IN clauses
--
SELECT
    count(*)
FROM
    tenk1 x
WHERE
    x.unique1 IN (
        SELECT
            a.f1
        FROM
            int4_tbl a,
            float8_tbl b
        WHERE
            a.f1 = b.f1)
    AND x.unique1 = 0
    AND x.unique1 IN (
        SELECT
            aa.f1
        FROM
            int4_tbl aa,
            float8_tbl bb
        WHERE
            aa.f1 = bb.f1);

-- try that with GEQO too
BEGIN;
SET geqo = ON;
SET geqo_threshold = 2;
SELECT
    count(*)
FROM
    tenk1 x
WHERE
    x.unique1 IN (
        SELECT
            a.f1
        FROM
            int4_tbl a,
            float8_tbl b
        WHERE
            a.f1 = b.f1)
    AND x.unique1 = 0
    AND x.unique1 IN (
        SELECT
            aa.f1
        FROM
            int4_tbl aa,
            float8_tbl bb
        WHERE
            aa.f1 = bb.f1);
ROLLBACK;

--
-- regression test: be sure we cope with proven-dummy append rels
--
EXPLAIN (
    COSTS OFF
)
SELECT
    aa,
    bb,
    unique1,
    unique1
FROM
    tenk1
    RIGHT JOIN b_star ON aa = unique1
WHERE
    bb < bb
    AND bb IS NULL;

SELECT
    aa,
    bb,
    unique1,
    unique1
FROM
    tenk1
    RIGHT JOIN b_star ON aa = unique1
WHERE
    bb < bb
    AND bb IS NULL;

--
-- regression test: check handling of empty-FROM subquery underneath outer join
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i1
    LEFT JOIN (int8_tbl i2
        JOIN (
            SELECT
                123 AS x) ss ON i2.q1 = x) ON i1.q2 = i2.q2
ORDER BY
    1,
    2;

SELECT
    *
FROM
    int8_tbl i1
    LEFT JOIN (int8_tbl i2
        JOIN (
            SELECT
                123 AS x) ss ON i2.q1 = x) ON i1.q2 = i2.q2
ORDER BY
    1,
    2;

--
-- regression test: check a case where join_clause_is_movable_into()
-- used to give an imprecise result, causing an assertion failure
--
SELECT
    count(*)
FROM (
    SELECT
        t3.tenthous AS x1,
        coalesce(t1.stringu1, t2.stringu1) AS x2
    FROM
        tenk1 t1
        LEFT JOIN tenk1 t2 ON t1.unique1 = t2.unique1
        JOIN tenk1 t3 ON t1.unique2 = t3.unique2) ss,
    tenk1 t4,
    tenk1 t5
WHERE
    t4.thousand = t5.unique1
    AND ss.x1 = t4.tenthous
    AND ss.x2 = t5.stringu1;

--
-- regression test: check a case where we formerly missed including an EC
-- enforcement clause because it was expected to be handled at scan level
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.f1,
    b.f1,
    t.thousand,
    t.tenthous
FROM
    tenk1 t,
    (
        SELECT
            sum(f1) + 1 AS f1
        FROM
            int4_tbl i4a) a,
    (
        SELECT
            sum(f1) AS f1
        FROM
            int4_tbl i4b) b
WHERE
    b.f1 = t.thousand
    AND a.f1 = b.f1
    AND (a.f1 + b.f1 + 999) = t.tenthous;

SELECT
    a.f1,
    b.f1,
    t.thousand,
    t.tenthous
FROM
    tenk1 t,
    (
        SELECT
            sum(f1) + 1 AS f1
        FROM
            int4_tbl i4a) a,
    (
        SELECT
            sum(f1) AS f1
        FROM
            int4_tbl i4b) b
WHERE
    b.f1 = t.thousand
    AND a.f1 = b.f1
    AND (a.f1 + b.f1 + 999) = t.tenthous;

--
-- Test hash joins with multiple hash keys and subplans.
--
-- First ensure we get a hash join with multiple hash keys.
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.unique1,
    t2.unique1
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.two = t2.two
        AND t1.unique1 = (
            SELECT
                min(unique1)
            FROM
                tenk1
        WHERE
            t2.unique1 = unique1)
WHERE
    t1.unique1 < 10
    AND t2.unique1 < 10
ORDER BY
    t1.unique1;

-- Ensure we get the expected result
SELECT
    t1.unique1,
    t2.unique1
FROM
    tenk1 t1
    INNER JOIN tenk1 t2 ON t1.two = t2.two
        AND t1.unique1 = (
            SELECT
                min(unique1)
            FROM
                tenk1
        WHERE
            t2.unique1 = unique1)
WHERE
    t1.unique1 < 10
    AND t2.unique1 < 10
ORDER BY
    t1.unique1;

--
-- checks for correct handling of quals in multiway outer joins
--
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.f1
FROM
    int4_tbl t1,
    int4_tbl t2
    LEFT JOIN int4_tbl t3 ON t3.f1 > 0
    LEFT JOIN int4_tbl t4 ON t3.f1 > 1
WHERE
    t4.f1 IS NULL;

SELECT
    t1.f1
FROM
    int4_tbl t1,
    int4_tbl t2
    LEFT JOIN int4_tbl t3 ON t3.f1 > 0
    LEFT JOIN int4_tbl t4 ON t3.f1 > 1
WHERE
    t4.f1 IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE
    LEFT JOIN int4_tbl t3 ON t2.f1 > 0
    LEFT JOIN int4_tbl t4 ON t3.f1 > 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1
    LEFT JOIN onek t2 ON t1.unique1 = t2.unique1
    LEFT JOIN onek t3 ON t2.unique1 != t3.unique1
    LEFT JOIN onek t4 ON t3.unique1 = t4.unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            now()
        FROM
            int4_tbl t2
            LEFT JOIN int4_tbl t3 ON t2.f1 = t3.f1
            LEFT JOIN int4_tbl t4 ON t3.f1 = t4.f1) s ON TRUE
    INNER JOIN int4_tbl t5 ON TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE
    LEFT JOIN int4_tbl t3 ON TRUE
    LEFT JOIN int4_tbl t4 ON t2.f1 = t3.f1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE
    LEFT JOIN int4_tbl t3 ON t2.f1 = t3.f1
    LEFT JOIN int4_tbl t4 ON t3.f1 != t4.f1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN (int4_tbl t2
        LEFT JOIN int4_tbl t3 ON t2.f1 > 0) ON t2.f1 > 1
    LEFT JOIN int4_tbl t4 ON t2.f1 > 2
        AND t3.f1 > 3
WHERE
    t1.f1 = coalesce(t2.f1, 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN ((
            SELECT
                t2.f1
            FROM
                int4_tbl t2
                LEFT JOIN int4_tbl t3 ON t2.f1 > 0
            WHERE
                t3.f1 IS NULL) s
        LEFT JOIN tenk1 t4 ON s.f1 > 1) ON s.f1 = t1.f1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN ((
            SELECT
                t2.f1
            FROM
                int4_tbl t2
                LEFT JOIN int4_tbl t3 ON t2.f1 > 0
            WHERE
                t2.f1 <> coalesce(t3.f1, -1)) s
        LEFT JOIN tenk1 t4 ON s.f1 > 1) ON s.f1 = t1.f1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1
    LEFT JOIN onek t2 ON t1.unique1 = t2.unique1
    LEFT JOIN onek t3 ON t2.unique1 = t3.unique1
    LEFT JOIN onek t4 ON t3.unique1 = t4.unique1
        AND t2.unique2 = t4.unique2;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN int8_tbl t3
        FULL JOIN int8_tbl t4 ON FALSE ON FALSE)
    LEFT JOIN int8_tbl t5 ON t2.q1 = t5.q1 ON t2.q2 = 123;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            int8_tbl t3
        WHERE
            t3.q1 = t2.q1 OFFSET 0) s ON t2.q1 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            generate_series(t2.q1, 100)) s ON t2.q1 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            t2.q1
        FROM
            int8_tbl t3) s ON t2.q1 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1
    LEFT JOIN onek t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            onek t3
        WHERE
            t3.two = t2.two OFFSET 0) s ON t2.unique1 = 1;

--
-- check a case where we formerly got confused by conflicting sort orders
-- in redundant merge join path keys
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    j1_tbl
    FULL JOIN (
        SELECT
            *
        FROM
            j2_tbl
        ORDER BY
            j2_tbl.i DESC,
            j2_tbl.k ASC) j2_tbl ON j1_tbl.i = j2_tbl.i
    AND j1_tbl.i = j2_tbl.k;

SELECT
    *
FROM
    j1_tbl
    FULL JOIN (
        SELECT
            *
        FROM
            j2_tbl
        ORDER BY
            j2_tbl.i DESC,
            j2_tbl.k ASC) j2_tbl ON j1_tbl.i = j2_tbl.i
    AND j1_tbl.i = j2_tbl.k;

--
-- a different check for handling of redundant sort keys in merge joins
--
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM (
    SELECT
        *
    FROM
        tenk1 x
    ORDER BY
        x.thousand,
        x.twothousand,
        x.fivethous) x
    LEFT JOIN (
        SELECT
            *
        FROM
            tenk1 y
        ORDER BY
            y.unique2) y ON x.thousand = y.unique2
    AND x.twothousand = y.hundred
    AND x.fivethous = y.unique2;

SELECT
    count(*)
FROM (
    SELECT
        *
    FROM
        tenk1 x
    ORDER BY
        x.thousand,
        x.twothousand,
        x.fivethous) x
    LEFT JOIN (
        SELECT
            *
        FROM
            tenk1 y
        ORDER BY
            y.unique2) y ON x.thousand = y.unique2
    AND x.twothousand = y.hundred
    AND x.fivethous = y.unique2;

SET enable_hashjoin = 0;

SET enable_nestloop = 0;

SET enable_hashagg = 0;

--
-- Check that we use the pathkeys from a prefix of the group by / order by
-- clause for the join pathkeys when that prefix covers all join quals.  We
-- expect this to lead to an incremental sort for the group by / order by.
--
EXPLAIN (
    COSTS OFF
)
SELECT
    x.thousand,
    x.twothousand,
    count(*)
FROM
    tenk1 x
    INNER JOIN tenk1 y ON x.thousand = y.thousand
GROUP BY
    x.thousand,
    x.twothousand
ORDER BY
    x.thousand DESC,
    x.twothousand;

RESET enable_hashagg;

RESET enable_nestloop;

RESET enable_hashjoin;

--
-- Clean up
--
DROP TABLE t1;

DROP TABLE t2;

DROP TABLE t3;

DROP TABLE J1_TBL;

DROP TABLE J2_TBL;

-- Both DELETE and UPDATE allow the specification of additional tables
-- to "join" against to determine which rows should be modified.
CREATE TEMP TABLE t1 (
    a int,
    b int
);

CREATE TEMP TABLE t2 (
    a int,
    b int
);

CREATE TEMP TABLE t3 (
    x int,
    y int
);

INSERT INTO t1
    VALUES (5, 10);

INSERT INTO t1
    VALUES (15, 20);

INSERT INTO t1
    VALUES (100, 100);

INSERT INTO t1
    VALUES (200, 1000);

INSERT INTO t2
    VALUES (200, 2000);

INSERT INTO t3
    VALUES (5, 20);

INSERT INTO t3
    VALUES (6, 7);

INSERT INTO t3
    VALUES (7, 8);

INSERT INTO t3
    VALUES (500, 100);

DELETE FROM t3 USING t1 table1
WHERE t3.x = table1.a;

SELECT
    *
FROM
    t3;

DELETE FROM t3 USING t1
JOIN t2 USING (a)
WHERE t3.x > t1.a;

SELECT
    *
FROM
    t3;

DELETE FROM t3 USING t3 t3_other
WHERE t3.x = t3_other.x
    AND t3.y = t3_other.y;

SELECT
    *
FROM
    t3;

-- Test join against inheritance tree
CREATE temp TABLE t2a ()
INHERITS (
    t2
);

INSERT INTO t2a
    VALUES (200, 2001);

SELECT
    *
FROM
    t1
    LEFT JOIN t2 ON (t1.a = t2.a);

-- Test matching of column name with wrong alias
SELECT
    t1.x
FROM
    t1
    JOIN t3 ON (t1.a = t3.x);

-- Test matching of locking clause with wrong alias
SELECT
    t1.*,
    t2.*,
    unnamed_join.*
FROM
    t1
    JOIN t2 ON (t1.a = t2.a),
    t3 AS unnamed_join
FOR UPDATE
    OF unnamed_join;

SELECT
    foo.*,
    unnamed_join.*
FROM
    t1
    JOIN t2 USING (a) AS foo,
    t3 AS unnamed_join
FOR UPDATE
    OF unnamed_join;

SELECT
    foo.*,
    unnamed_join.*
FROM
    t1
    JOIN t2 USING (a) AS foo,
    t3 AS unnamed_join
FOR UPDATE
    OF foo;

SELECT
    bar.*,
    unnamed_join.*
FROM (t1
    JOIN t2 USING (a) AS foo) AS bar,
    t3 AS unnamed_join
FOR UPDATE
    OF foo;

SELECT
    bar.*,
    unnamed_join.*
FROM (t1
    JOIN t2 USING (a) AS foo) AS bar,
    t3 AS unnamed_join
FOR UPDATE
    OF bar;

--
-- regression test for 8.1 merge right join bug
--
CREATE TEMP TABLE tt1 (
    tt1_id int4,
    joincol int4
);

INSERT INTO tt1
    VALUES (1, 11);

INSERT INTO tt1
    VALUES (2, NULL);

CREATE TEMP TABLE tt2 (
    tt2_id int4,
    joincol int4
);

INSERT INTO tt2
    VALUES (21, 11);

INSERT INTO tt2
    VALUES (22, 11);

SET enable_hashjoin TO OFF;

SET enable_nestloop TO OFF;

-- these should give the same results
SELECT
    tt1.*,
    tt2.*
FROM
    tt1
    LEFT JOIN tt2 ON tt1.joincol = tt2.joincol;

SELECT
    tt1.*,
    tt2.*
FROM
    tt2
    RIGHT JOIN tt1 ON tt1.joincol = tt2.joincol;

RESET enable_hashjoin;

RESET enable_nestloop;

--
-- regression test for bug #18522 (merge-right-anti-join in inner_unique cases)
--
CREATE temp TABLE tbl_ra (
    a int UNIQUE,
    b int
);

INSERT INTO tbl_ra
SELECT
    i,
    i % 100
FROM
    generate_series(1, 1000) i;

CREATE INDEX ON tbl_ra (b);

ANALYZE tbl_ra;

SET enable_hashjoin TO OFF;

SET enable_nestloop TO OFF;

-- ensure we get a merge right anti join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_ra t1
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tbl_ra t2
        WHERE
            t2.b = t1.a)
    AND t1.b < 2;

-- and check we get the expected results
SELECT
    *
FROM
    tbl_ra t1
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tbl_ra t2
        WHERE
            t2.b = t1.a)
    AND t1.b < 2;

RESET enable_hashjoin;

RESET enable_nestloop;

--
-- regression test for bug with hash-right-semi join
--
CREATE temp TABLE tbl_rs (
    a int,
    b int
);

INSERT INTO tbl_rs
SELECT
    i,
    i
FROM
    generate_series(1, 10) i;

ANALYZE tbl_rs;

-- ensure we get a hash right semi join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_rs t1
    JOIN LATERAL (
        SELECT
            *
        FROM
            tbl_rs t2
        WHERE
            t2.a IN (
                SELECT
                    t1.a + t3.a
                FROM
                    tbl_rs t3)
            AND t2.a < 5) ON TRUE;

-- and check we get the expected results
SELECT
    *
FROM
    tbl_rs t1
    JOIN LATERAL (
        SELECT
            *
        FROM
            tbl_rs t2
        WHERE
            t2.a IN (
                SELECT
                    t1.a + t3.a
                FROM
                    tbl_rs t3)
            AND t2.a < 5) ON TRUE;

--
-- regression test for bug with parallel-hash-right-semi join
--
BEGIN;
-- encourage use of parallel plans
SET local parallel_setup_cost = 0;
SET local parallel_tuple_cost = 0;
SET local min_parallel_table_scan_size = 0;
SET local max_parallel_workers_per_gather = 4;
-- ensure we don't get parallel hash right semi join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tenk1 t2
        WHERE
            fivethous = t1.fivethous)
    AND t1.fivethous < 5;
ROLLBACK;

--
-- Check that for hash right semi and right anti joins we charge cpu_tuple_cost
-- and qual costs on the rows from the inner side, except that a right anti
-- join charges the non-hashed joinquals on the candidate pairs passing the
-- hash clauses.
--
BEGIN;
CREATE temp TABLE hj_small (
    id int PRIMARY KEY
);
CREATE temp TABLE hj_large (
    v int
);
INSERT INTO hj_small
SELECT
    i
FROM
    generate_series(1, 200) i;
INSERT INTO hj_large
SELECT
    (i % 500) + 11
FROM
    generate_series(1, 1000) i;
ANALYZE hj_small,
hj_large;
-- ensure we hash the small side and scan the large one, not the reverse
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    hj_small s
WHERE
    EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id);
-- and check we get the expected results
SELECT
    count(*)
FROM
    hj_small s
WHERE
    EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id);
-- likewise for a right anti join
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    hj_small s
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id);
SELECT
    count(*)
FROM
    hj_small s
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id);
-- also check the case with a non-hashed joinqual
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    hj_small s
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id
            AND r.v > s.id - 1);
SELECT
    count(*)
FROM
    hj_small s
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            hj_large r
        WHERE
            r.v = s.id
            AND r.v > s.id - 1);
ROLLBACK;

--
-- regression test for bug #13908 (hash join with skew tuples & nbatch increase)
--
SET work_mem TO '64kB';

SET enable_mergejoin TO OFF;

SET enable_memoize TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
WHERE
    a.hundred = b.thousand
    AND (b.fivethous % 10) < 10;

SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
WHERE
    a.hundred = b.thousand
    AND (b.fivethous % 10) < 10;

RESET work_mem;

RESET enable_mergejoin;

RESET enable_memoize;

--
-- regression test for 8.2 bug with improper re-ordering of left joins
--
CREATE temp TABLE tt3 (
    f1 int,
    f2 text
);

INSERT INTO tt3
SELECT
    x,
    repeat('xyzzy', 100)
FROM
    generate_series(1, 10000) x;

ANALYZE tt3;

CREATE temp TABLE tt4 (
    f1 int
);

INSERT INTO tt4
VALUES
    (0),
    (1),
    (9999);

ANALYZE tt4;

SET enable_nestloop TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    a.f1
FROM
    tt4 a
    LEFT JOIN (
        SELECT
            b.f1
        FROM
            tt3 b
            LEFT JOIN tt3 c ON (b.f1 = c.f1)
        WHERE
            COALESCE(c.f1, 0) = 0) AS d ON (a.f1 = d.f1)
WHERE
    COALESCE(d.f1, 0) = 0
ORDER BY
    1;

SELECT
    a.f1
FROM
    tt4 a
    LEFT JOIN (
        SELECT
            b.f1
        FROM
            tt3 b
            LEFT JOIN tt3 c ON (b.f1 = c.f1)
        WHERE
            COALESCE(c.f1, 0) = 0) AS d ON (a.f1 = d.f1)
WHERE
    COALESCE(d.f1, 0) = 0
ORDER BY
    1;

RESET enable_nestloop;

--
-- test that estimate_hash_bucket_stats estimates correctly with skewed data
-- (we should choose to hash the filtered table)
--
CREATE temp TABLE skewedtable (
    val int NOT NULL,
    filt int NOT NULL
);

INSERT INTO skewedtable
SELECT
    CASE WHEN g <= 100 THEN
        0
    ELSE
        (g % 100) + 1
    END,
    g % 10
FROM
    generate_series(1, 1000) g;

ANALYZE skewedtable;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    skewedtable t1
    JOIN skewedtable t2 ON t1.val = t2.val
WHERE
    t1.filt = 5;

DROP TABLE skewedtable;

--
-- basic semijoin and antijoin recognition tests
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
WHERE
    unique1 IN (
        SELECT
            unique2
        FROM
            tenk1 b);

-- sadly, this is not an antijoin
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
WHERE
    unique1 NOT IN (
        SELECT
            unique2
        FROM
            tenk1 b);

EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tenk1 b
        WHERE
            a.unique1 = b.unique2);

EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tenk1 b
        WHERE
            a.unique1 = b.unique2);

EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
    LEFT JOIN tenk1 b ON a.unique1 = b.unique2
WHERE
    b.unique2 IS NULL;

-- check that we avoid de-duplicating columns redundantly
SET enable_memoize TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tenk1
WHERE (hundred, thousand) IN (
    SELECT
        twothousand,
        twothousand
    FROM
        onek);

RESET enable_memoize;

--
-- more antijoin recognition tests using various non-null proofs (NOT NULL
-- constraints, strict join clauses within the RHS subtree)
--
BEGIN;
CREATE temp TABLE tbl_anti (
    a int NOT NULL,
    b int,
    c int
);
-- this is an antijoin, as t2.a is non-null for any matching row
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_anti t2 ON t1.unique1 = t2.b
WHERE
    t2.a IS NULL;
-- this is an antijoin, as t2.a is non-null for any matching row
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t2.a IS NULL;
-- this is not an antijoin, as t3.a can be nulled by t2/t3 join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3.a IS NULL;
-- this is an antijoin: the strict join clause t2.c = t3.c guarantees t3.c is
-- non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        INNER JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3.c IS NULL;
-- this is an antijoin: the strict join clause t2.c = t3.c guarantees t2.c is
-- non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        INNER JOIN tbl_anti t3 ON t2.c = t3.c
        LEFT JOIN tbl_anti t4 ON t3.c = t4.c) ON t1.unique1 = t2.b
WHERE
    t2.c IS NULL;
-- this is an antijoin: the strict join clause t2.c = t3.c guarantees t3.c is
-- non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (
        SELECT
            t2.b,
            t3.c
        FROM
            tbl_anti t2,
            tbl_anti t3
        WHERE
            t2.c = t3.c) ss ON t1.unique1 = ss.b
WHERE
    ss.c IS NULL;
-- this is an antijoin: the strict join clause t2.c = t3.c guarantees t2.c is
-- non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (
        SELECT
            t2.c
        FROM
            tbl_anti t2
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    tbl_anti t3
                WHERE
                    t2.c = t3.c)) ss ON TRUE
WHERE
    ss.c IS NULL;
-- this is not an antijoin: the join clause t2.c = t3.c cannot guarantee t3.c
-- is non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3.c IS NULL;
-- likewise with right join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        RIGHT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3.c IS NULL;
-- likewise with full join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        FULL JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3.c IS NULL;
-- this is not an antijoin, even though the inner-join clause in the lateral
-- subquery proves t1.b non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    LEFT JOIN LATERAL (
        SELECT
            t2.b
        FROM
            tbl_anti t2,
            tbl_anti t3
        WHERE
            t2.c = t3.c
            AND t3.b = t1.b) ss ON TRUE
WHERE
    t1.b IS NULL;
-- a full join can also reduce to an antijoin: the forced-null Var is defined
-- not null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t2.a IS NULL;
-- the symmetric case, with the forced-null Var on the left side
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t1.a IS NULL;
-- this is an antijoin: the forced-null Var is proven not null by the strict
-- clause within its subtree
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN (tbl_anti t2
        JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.b = t2.b
WHERE
    t3.c IS NULL;
-- the symmetric case, with the forced-null Var on the left side
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (tbl_anti t1
    JOIN tbl_anti t4 ON t1.c = t4.c)
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t1.c IS NULL;
-- this is not an antijoin: the join clause cannot prove t2.b non-null in the
-- full join's right-only rows
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t2.b IS NULL;
-- the symmetric case: the join clause cannot prove t1.b non-null in the full
-- join's left-only rows
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t1.b IS NULL;
-- this is an antijoin: t2 is not nullable within the full join's right input,
-- so its NOT NULL column still proves it
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.b = t2.b
WHERE
    t2.a IS NULL;
-- this is not an antijoin: t3 can be nulled by the t2/t3 join, so its NOT NULL
-- constraint proves nothing here
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.b = t2.b
WHERE
    t3.a IS NULL;
-- once the full join is reduced to an antijoin, its own quals can be passed
-- down to its inputs, which a full join never allows; here that reduces the
-- t2/t3 join to an inner join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_anti t1
    FULL JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.b = t2.b
        AND t3.c > 0
WHERE
    t2.a IS NULL;
-- A USING join column becomes a merged (COALESCE) output, so reducing the
-- full join also has to fix up its nulling rels.
CREATE temp TABLE ma (
    x int NOT NULL,
    y int
);
CREATE temp TABLE mb (
    x int NOT NULL,
    y int
);
INSERT INTO ma
VALUES
    (1, 10),
    (2, 20);
INSERT INTO mb
VALUES
    (3, 10),
    (4, 40);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    y,
    ma.x AS ax,
    mb.x AS bx
FROM
    ma
    FULL JOIN mb USING (y)
WHERE
    mb.x IS NULL
ORDER BY
    y;
SELECT
    y,
    ma.x AS ax,
    mb.x AS bx
FROM
    ma
    FULL JOIN mb USING (y)
WHERE
    mb.x IS NULL
ORDER BY
    y;
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    y,
    ma.x AS ax,
    mb.x AS bx
FROM
    ma
    FULL JOIN mb USING (y)
WHERE
    ma.x IS NULL
ORDER BY
    y;
SELECT
    y,
    ma.x AS ax,
    mb.x AS bx
FROM
    ma
    FULL JOIN mb USING (y)
WHERE
    ma.x IS NULL
ORDER BY
    y;
-- A whole-row Var IS NULL is true only when every column is NULL, so it
-- works as an antijoin test whenever any column is provably non-null in
-- matching rows.
CREATE temp TABLE tbl_wr (
    b int,
    c int
);
-- this is an antijoin: t2.a is defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_anti t2 ON TRUE
WHERE
    t2 IS NULL;
-- this is an antijoin: the strict join clause proves t2.b non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_wr t2 ON t1.unique1 = t2.b
WHERE
    t2 IS NULL;
-- this is an antijoin: the strict join clause within the RHS subtree proves
-- t2.c non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_wr t2
        JOIN tbl_anti t3 ON t2.c = t3.c) ON TRUE
WHERE
    t2 IS NULL;
-- this is not an antijoin: nothing proves any column of t2 non-null
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_wr t2 ON TRUE
WHERE
    t2 IS NULL;
-- nor is this: the strict record comparison proves only that the whole-row
-- datum is non-null, but record_eq treats NULL fields as equal, so a
-- matching row can still have all columns NULL and pass the row-format test
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_wr t2
        JOIN tbl_wr t3 ON t2 = t3) ON TRUE
WHERE
    t2 IS NULL;
-- nor is this: the join clause is strict only for t2's ctid, which is not
-- part of the row value, so a matching row can still have all columns NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_wr t1
    LEFT JOIN tbl_wr t2 ON t2.ctid = t1.ctid
WHERE
    t2 IS NULL;
-- this is not an antijoin: t3 can be nulled by the lower outer join, so its
-- NOT NULL constraint proves nothing here
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tbl_anti t2
        LEFT JOIN tbl_anti t3 ON t2.c = t3.c) ON t1.unique1 = t2.b
WHERE
    t3 IS NULL;
-- whole-row tests work for full joins too: t2.a's NOT NULL constraint
-- reduces this one ...
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_wr t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t2 IS NULL;
-- ... but nothing proves a column of t1 non-null, since the join clause
-- cannot serve as the proof here
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_wr t1
    FULL JOIN tbl_anti t2 ON t1.b = t2.b
WHERE
    t1 IS NULL;
-- The IS NOT NULL counterpart: a row-format IS NOT NULL test is false both
-- for a null-extended row and when any column is NULL, so it reduces join
-- strength like any strict qual.
-- reduced to an inner join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_wr t2 ON t1.unique1 = t2.b
WHERE
    t2 IS NOT NULL;
-- reduced to a left join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tbl_wr t1
    FULL JOIN tbl_wr t2 ON t1.b = t2.b
WHERE
    t1 IS NOT NULL;
-- composite-type columns: reduced to an inner join
CREATE temp TABLE tbl_comp (
    a int,
    w tbl_wr
);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_comp t2 ON t1.unique1 = t2.a
WHERE
    t2.w IS NOT NULL;
-- composite-type columns: reduced to an antijoin
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN tbl_comp t2 ON t2.w IS NOT NULL
WHERE
    t2 IS NULL;
-- For a zero-field row, IS NULL and IS NOT NULL are both true, so the join
-- clause here proves only that t2's datum is non-null, which must not refute
-- the whole-row IS NULL above: matched rows pass both tests.
CREATE temp TABLE tbl_zero ();
INSERT INTO tbl_zero DEFAULT VALUES;

-- should not be reduced
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x)
    LEFT JOIN tbl_zero t2 ON t2 IS NOT NULL
WHERE
    t2 IS NULL;
-- should return 2 rows
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x)
    LEFT JOIN tbl_zero t2 ON t2 IS NOT NULL
WHERE
    t2 IS NULL;
-- Test that quals made redundant by reducing an outer join to an antijoin are
-- removed from the jointree
-- (fallout from the fix for bug #19560)
CREATE temp TABLE tbl_anti_pk (
    a int PRIMARY KEY,
    b int
);
-- t3.a IS NULL is redundant, and the t2/t3 join can be removed
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tbl_anti_pk t1
    LEFT JOIN (tbl_anti_pk t2
        LEFT JOIN tbl_anti_pk t3 ON t3.a = t2.a) ON t2.a = t1.a
WHERE
    t2.a IS NULL
    AND t3.a IS NULL;
-- the redundant qual can also be a degenerate ON clause of an upper join
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tbl_anti_pk t1
    LEFT JOIN (tbl_anti_pk t2
        LEFT JOIN (tbl_anti_pk t3
            LEFT JOIN tbl_anti_pk t5 ON t5.a = t3.a) ON t3.a = t2.a) ON t3.a IS NULL
        AND t5.a IS NULL;
-- the same happens when the antijoin is reduced from a full join
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tbl_anti_pk t1
    FULL JOIN (tbl_anti_pk t2
        LEFT JOIN tbl_anti_pk t3 ON t3.a = t2.a) ON TRUE
WHERE
    t2.a IS NULL
    AND t3.a IS NULL;
-- but a qual on the surviving side of the reduced full join is not redundant
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tbl_anti_pk t1
    FULL JOIN (tbl_anti_pk t2
        LEFT JOIN tbl_anti_pk t3 ON t3.a = t2.a) ON TRUE
WHERE
    t2.a IS NULL
    AND t1.b IS NULL;
ROLLBACK;

--
-- regression test for bogus RTE_GROUP entries
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    tenk1 a
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tenk1 b
        WHERE
            a.unique1 = b.unique2
        GROUP BY
            b.unique1);

--
-- regression test for proper handling of outer joins within antijoins
--
CREATE temp TABLE tt4x (
    c1 int,
    c2 int,
    c3 int
);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tt4x t1
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tt4x t2
        LEFT JOIN tt4x t3 ON t2.c3 = t3.c1
        LEFT JOIN (
            SELECT
                t5.c1 AS c1
            FROM
                tt4x t4
                LEFT JOIN tt4x t5 ON t4.c2 = t5.c1) a1 ON t3.c2 = a1.c1
        WHERE
            t1.c1 = t2.c2);

--
-- regression test for problems of the sort depicted in bug #3494
--
CREATE temp TABLE tt5 (
    f1 int,
    f2 int
);

CREATE temp TABLE tt6 (
    f1 int,
    f2 int
);

INSERT INTO tt5
    VALUES (1, 10);

INSERT INTO tt5
    VALUES (1, 11);

INSERT INTO tt6
    VALUES (1, 9);

INSERT INTO tt6
    VALUES (1, 2);

INSERT INTO tt6
    VALUES (2, 9);

SELECT
    *
FROM
    tt5,
    tt6
WHERE
    tt5.f1 = tt6.f1
    AND tt5.f1 = tt5.f2 - tt6.f2;

--
-- regression test for problems of the sort depicted in bug #3588
--
CREATE temp TABLE xx (
    pkxx int
);

CREATE temp TABLE yy (
    pkyy int,
    pkxx int
);

INSERT INTO xx
    VALUES (1);

INSERT INTO xx
    VALUES (2);

INSERT INTO xx
    VALUES (3);

INSERT INTO yy
    VALUES (101, 1);

INSERT INTO yy
    VALUES (201, 2);

INSERT INTO yy
    VALUES (301, NULL);

SELECT
    yy.pkyy AS yy_pkyy,
    yy.pkxx AS yy_pkxx,
    yya.pkyy AS yya_pkyy,
    xxa.pkxx AS xxa_pkxx,
    xxb.pkxx AS xxb_pkxx
FROM
    yy
    LEFT JOIN (
        SELECT
            *
        FROM
            yy
        WHERE
            pkyy = 101) AS yya ON yy.pkyy = yya.pkyy
    LEFT JOIN xx xxa ON yya.pkxx = xxa.pkxx
    LEFT JOIN xx xxb ON coalesce(xxa.pkxx, 1) = xxb.pkxx;

--
-- regression test for improper pushing of constants across outer-join clauses
-- (as seen in early 8.2.x releases)
--
CREATE temp TABLE zt1 (
    f1 int PRIMARY KEY
);

CREATE temp TABLE zt2 (
    f2 int PRIMARY KEY
);

CREATE temp TABLE zt3 (
    f3 int PRIMARY KEY
);

INSERT INTO zt1
    VALUES (53);

INSERT INTO zt2
    VALUES (53);

SELECT
    *
FROM
    zt2
    LEFT JOIN zt3 ON (f2 = f3)
    LEFT JOIN zt1 ON (f3 = f1)
WHERE
    f2 = 53;

CREATE temp VIEW zv1 AS
SELECT
    *,
    'dummy'::text AS junk
FROM
    zt1;

SELECT
    *
FROM
    zt2
    LEFT JOIN zt3 ON (f2 = f3)
    LEFT JOIN zv1 ON (f3 = f1)
WHERE
    f2 = 53;

-- the zt3/zt1b join clause must be kept when zt2/zt3 is commuted into zt1/zt2
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    zt1
    LEFT JOIN zt2 ON (zt1.f1 = f2)
    LEFT JOIN zt3 ON (f2 = f3)
    LEFT JOIN zt1 zt1b ON (f3 = zt1b.f1)
WHERE
    zt1.f1 = 53;

SELECT
    *
FROM
    zt1
    LEFT JOIN zt2 ON (zt1.f1 = f2)
    LEFT JOIN zt3 ON (f2 = f3)
    LEFT JOIN zt1 zt1b ON (f3 = zt1b.f1)
WHERE
    zt1.f1 = 53;

-- likewise for the zt3/zt2 join clause when zt1b/zt3 is commuted into zt1/zt1b
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    zt1
    LEFT JOIN zt1 zt1b ON (zt1.f1 = zt1b.f1
            AND zt1b.f1 = 53)
    LEFT JOIN (zt3
        LEFT JOIN zt2 ON (f3 = f2)) ON (zt1b.f1 = f3);

SELECT
    *
FROM
    zt1
    LEFT JOIN zt1 zt1b ON (zt1.f1 = zt1b.f1
            AND zt1b.f1 = 53)
    LEFT JOIN (zt3
        LEFT JOIN zt2 ON (f3 = f2)) ON (zt1b.f1 = f3);

--
-- regression test for improper extraction of OR indexqual conditions
-- (as seen in early 8.3.x releases)
--
SELECT
    a.unique2,
    a.ten,
    b.tenthous,
    b.unique2,
    b.hundred
FROM
    tenk1 a
    LEFT JOIN tenk1 b ON a.unique2 = b.tenthous
WHERE
    a.unique1 = 42
    AND ((b.unique2 IS NULL
            AND a.ten = 2)
        OR b.hundred = 3);

--
-- test proper positioning of one-time quals in EXISTS (8.4devel bug)
--
PREPARE foo (bool) AS
SELECT
    count(*)
FROM
    tenk1 a
    LEFT JOIN tenk1 b ON (a.unique2 = b.unique1
            AND EXISTS (
                SELECT
                    1
                FROM
                    tenk1 c
            WHERE
                c.thousand = b.unique2
                AND $1));

EXECUTE foo (TRUE);

EXECUTE foo (FALSE);

--
-- test for sane behavior with noncanonical merge clauses, per bug #4926
--
BEGIN;
SET enable_mergejoin = 1;
SET enable_hashjoin = 0;
SET enable_nestloop = 0;
CREATE temp TABLE a (
    i integer
);
CREATE temp TABLE b (
    x integer,
    y integer
);
SELECT
    *
FROM
    a
    LEFT JOIN b ON i = x
        AND i = y
        AND x = i;
ROLLBACK;

--
-- test handling of merge clauses using record_ops
--
BEGIN;
CREATE TYPE mycomptype AS (
    id int,
    v bigint
);
CREATE temp TABLE tidv (
    idv mycomptype
);
CREATE INDEX ON tidv (idv);
EXPLAIN (
    COSTS OFF
)
SELECT
    a.idv,
    b.idv
FROM
    tidv a,
    tidv b
WHERE
    a.idv = b.idv;
SET enable_mergejoin = 0;
SET enable_hashjoin = 0;
EXPLAIN (
    COSTS OFF
)
SELECT
    a.idv,
    b.idv
FROM
    tidv a,
    tidv b
WHERE
    a.idv = b.idv;
ROLLBACK;

--
-- test NULL behavior of whole-row Vars, per bug #5025
--
SELECT
    t1.q2,
    count(t2.*)
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON (t1.q2 = t2.q1)
GROUP BY
    t1.q2
ORDER BY
    1;

SELECT
    t1.q2,
    count(t2.*)
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            *
        FROM
            int8_tbl) t2 ON (t1.q2 = t2.q1)
GROUP BY
    t1.q2
ORDER BY
    1;

SELECT
    t1.q2,
    count(t2.*)
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            *
        FROM
            int8_tbl OFFSET 0) t2 ON (t1.q2 = t2.q1)
GROUP BY
    t1.q2
ORDER BY
    1;

SELECT
    t1.q2,
    count(t2.*)
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            q1,
            CASE WHEN q2 = 1 THEN
                1
            ELSE
                q2
            END AS q2
        FROM
            int8_tbl) t2 ON (t1.q2 = t2.q1)
GROUP BY
    t1.q2
ORDER BY
    1;

-- nulled whole-row Var of a join alias in aggregate queries
SELECT
    t1.q2,
    count(t23)
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        JOIN int4_tbl t3 ON t3.f1 = 0) t23 ON (t1.q2 = t23.q1)
GROUP BY
    t1.q2
ORDER BY
    1;

SELECT
    t23,
    count(*)
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        JOIN int4_tbl t3 ON t3.f1 = 0) t23 ON (t1.q2 = t23.q1)
GROUP BY
    t23
ORDER BY
    1;

-- nulled whole-row Var of a zero-column join, referenced from a subquery
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    t1.q2,
    (
        SELECT
            t23::text)
FROM
    int8_tbl t1
    LEFT JOIN ((
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t2
        CROSS JOIN (
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t3) t23 ON (t1.q1 = 123)
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    t1.q2,
    (
        SELECT
            t23::text)
FROM
    int8_tbl t1
    LEFT JOIN ((
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t2
        CROSS JOIN (
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t3) t23 ON (t1.q1 = 123)
ORDER BY
    1,
    2;

-- nulled whole-row Var of a zero-column outer join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    t1.q2,
    f
FROM
    int8_tbl t1
    LEFT JOIN ((
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t2
        LEFT JOIN (
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t3 ON TRUE) t23 ON (t1.q1 = 123),
length(t23::text) f
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    t1.q2,
    f
FROM
    int8_tbl t1
    LEFT JOIN ((
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t2
        LEFT JOIN (
            SELECT
            FROM
                int4_tbl
            WHERE
                f1 = 0) t3 ON TRUE) t23 ON (t1.q1 = 123),
length(t23::text) f
ORDER BY
    1,
    2;

-- nulled whole-row Var of a join with a variable-free merged column
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM (unnest(ARRAY[1, (
            SELECT
                sum(f1)
            FROM int4_tbl)]) AS u (b)
    RIGHT JOIN (
        VALUES (1)) AS v (b)
        USING (b)
        FULL JOIN int8_tbl i8 ON TRUE) AS j,
    length(j::text) f;

SELECT
    1
FROM (unnest(ARRAY[1, (
            SELECT
                sum(f1)
            FROM int4_tbl)]) AS u (b)
    RIGHT JOIN (
        VALUES (1)) AS v (b)
        USING (b)
        FULL JOIN int8_tbl i8 ON TRUE) AS j,
    length(j::text) f;

-- nulled whole-row Var of a join containing a lateral reference
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (j IS NULL)
FROM
    int4_tbl i4
    LEFT JOIN (int8_tbl i8
        JOIN LATERAL (
            SELECT
                i4.f1
            FROM (
                VALUES (3)) v) ss (x) ON TRUE) AS j ON FALSE;

SELECT
    (j IS NULL)
FROM
    int4_tbl i4
    LEFT JOIN (int8_tbl i8
        JOIN LATERAL (
            SELECT
                i4.f1
            FROM (
                VALUES (3)) v) ss (x) ON TRUE) AS j ON FALSE;

-- same, but the PHV must be passed up through another join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    j
FROM
    int4_tbl i4
    LEFT JOIN (LATERAL (
            VALUES (i4.f1)) AS v (a)
            CROSS JOIN int8_tbl i8) AS j ON (j.q1 = 123
                AND j.q2 = 456),
            int4_tbl i4b
    WHERE
        i4.f1 = 0
    ORDER BY
        1;

SELECT
    j
FROM
    int4_tbl i4
    LEFT JOIN (LATERAL (
            VALUES (i4.f1)) AS v (a)
            CROSS JOIN int8_tbl i8) AS j ON (j.q1 = 123
                AND j.q2 = 456),
            int4_tbl i4b
    WHERE
        i4.f1 = 0
    ORDER BY
        1;

-- same, referenced from a subquery, with only lateral references and constants
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    i4.f1,
    (
        SELECT
            j::text)
FROM
    int4_tbl i4
    LEFT JOIN (LATERAL (
            SELECT
                i4.f1) ss (x)
            CROSS JOIN (
                SELECT
                    1) s2 (y)) j ON (i4.f1 = 0)
ORDER BY
    1;

SELECT
    i4.f1,
    (
        SELECT
            j::text)
FROM
    int4_tbl i4
    LEFT JOIN (LATERAL (
            SELECT
                i4.f1) ss (x)
            CROSS JOIN (
                SELECT
                    1) s2 (y)) j ON (i4.f1 = 0)
ORDER BY
    1;

--
-- test incorrect failure to NULL pulled-up subexpressions
--
BEGIN;
CREATE temp TABLE a (
    code char NOT NULL,
    CONSTRAINT a_pk PRIMARY KEY (code)
);
CREATE temp TABLE b (
    a char NOT NULL,
    num integer NOT NULL,
    CONSTRAINT b_pk PRIMARY KEY (a, num)
);
CREATE temp TABLE c (
    name char NOT NULL,
    a char,
    CONSTRAINT c_pk PRIMARY KEY (name)
);
INSERT INTO a (code)
    VALUES ('p');
INSERT INTO a (code)
    VALUES ('q');
INSERT INTO b (a, num)
    VALUES ('p', 1);
INSERT INTO b (a, num)
    VALUES ('p', 2);
INSERT INTO c (name, a)
    VALUES ('A', 'p');
INSERT INTO c (name, a)
    VALUES ('B', 'q');
INSERT INTO c (name, a)
    VALUES ('C', NULL);
SELECT
    c.name,
    ss.code,
    ss.b_cnt,
    ss.const
FROM
    c
    LEFT JOIN (
        SELECT
            a.code,
            coalesce(b_grp.cnt, 0) AS b_cnt,
            -1 AS const
        FROM
            a
            LEFT JOIN (
                SELECT
                    count(1) AS cnt,
                    b.a
                FROM
                    b
                GROUP BY
                    b.a) AS b_grp ON a.code = b_grp.a) AS ss ON (c.a = ss.code)
ORDER BY
    c.name;
ROLLBACK;

--
-- test incorrect handling of placeholders that only appear in targetlists,
-- per bug #6154
--
SELECT
    *
FROM (
    SELECT
        1 AS key1) sub1
    LEFT JOIN (
        SELECT
            sub3.key3,
            sub4.value2,
            COALESCE(sub4.value2, 66) AS value3
        FROM (
            SELECT
                1 AS key3) sub3
            LEFT JOIN (
                SELECT
                    sub5.key5,
                    COALESCE(sub6.value1, 1) AS value2
                FROM (
                    SELECT
                        1 AS key5) sub5
                    LEFT JOIN (
                        SELECT
                            2 AS key6,
                            42 AS value1) sub6 ON sub5.key5 = sub6.key6) sub4 ON sub4.key5 = sub3.key3) sub2 ON sub1.key1 = sub2.key3;

-- test the path using join aliases, too
SELECT
    *
FROM (
    SELECT
        1 AS key1) sub1
    LEFT JOIN (
        SELECT
            sub3.key3,
            value2,
            COALESCE(value2, 66) AS value3
        FROM (
            SELECT
                1 AS key3) sub3
            LEFT JOIN (
                SELECT
                    sub5.key5,
                    COALESCE(sub6.value1, 1) AS value2
                FROM (
                    SELECT
                        1 AS key5) sub5
                    LEFT JOIN (
                        SELECT
                            2 AS key6,
                            42 AS value1) sub6 ON sub5.key5 = sub6.key6) sub4 ON sub4.key5 = sub3.key3) sub2 ON sub1.key1 = sub2.key3;

--
-- test case where a PlaceHolderVar is used as a nestloop parameter
--
EXPLAIN (
    COSTS OFF
)
SELECT
    qq,
    unique1
FROM (
    SELECT
        COALESCE(q1, 0) AS qq
    FROM
        int8_tbl a) AS ss1
    FULL OUTER JOIN (
        SELECT
            COALESCE(q2, -1) AS qq
        FROM
            int8_tbl b) AS ss2 USING (qq)
    INNER JOIN tenk1 c ON qq = unique2;

SELECT
    qq,
    unique1
FROM (
    SELECT
        COALESCE(q1, 0) AS qq
    FROM
        int8_tbl a) AS ss1
    FULL OUTER JOIN (
        SELECT
            COALESCE(q2, -1) AS qq
        FROM
            int8_tbl b) AS ss2 USING (qq)
    INNER JOIN tenk1 c ON qq = unique2;

--
-- nested nestloops can require nested PlaceHolderVars
--
CREATE temp TABLE nt1 (
    id int PRIMARY KEY,
    a1 boolean,
    a2 boolean
);

CREATE temp TABLE nt2 (
    id int PRIMARY KEY,
    nt1_id int,
    b1 boolean,
    b2 boolean,
    FOREIGN KEY (nt1_id) REFERENCES nt1 (id)
);

CREATE temp TABLE nt3 (
    id int PRIMARY KEY,
    nt2_id int,
    c1 boolean,
    FOREIGN KEY (nt2_id) REFERENCES nt2 (id)
);

INSERT INTO nt1
    VALUES (1, TRUE, TRUE);

INSERT INTO nt1
    VALUES (2, TRUE, FALSE);

INSERT INTO nt1
    VALUES (3, FALSE, FALSE);

INSERT INTO nt2
    VALUES (1, 1, TRUE, TRUE);

INSERT INTO nt2
    VALUES (2, 2, TRUE, FALSE);

INSERT INTO nt2
    VALUES (3, 3, FALSE, FALSE);

INSERT INTO nt3
    VALUES (1, 1, TRUE);

INSERT INTO nt3
    VALUES (2, 2, FALSE);

INSERT INTO nt3
    VALUES (3, 3, TRUE);

EXPLAIN (
    COSTS OFF
)
SELECT
    nt3.id
FROM
    nt3 AS nt3
    LEFT JOIN (
        SELECT
            nt2.*,
            (nt2.b1
                    AND ss1.a3) AS b3
            FROM
                nt2 AS nt2
        LEFT JOIN (
            SELECT
                nt1.*,
                (nt1.id IS NOT NULL) AS a3
            FROM
                nt1) AS ss1 ON ss1.id = nt2.nt1_id) AS ss2 ON ss2.id = nt3.nt2_id
WHERE
    nt3.id = 1
    AND ss2.b3;

SELECT
    nt3.id
FROM
    nt3 AS nt3
    LEFT JOIN (
        SELECT
            nt2.*,
            (nt2.b1
                    AND ss1.a3) AS b3
            FROM
                nt2 AS nt2
        LEFT JOIN (
            SELECT
                nt1.*,
                (nt1.id IS NOT NULL) AS a3
            FROM
                nt1) AS ss1 ON ss1.id = nt2.nt1_id) AS ss2 ON ss2.id = nt3.nt2_id
WHERE
    nt3.id = 1
    AND ss2.b3;

--
-- test case where a PlaceHolderVar is propagated into a subquery
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            q1 AS x,
            42 AS y
        FROM
            int8_tbl t2) ss ON t1.q2 = ss.x
WHERE
    1 = (
        SELECT
            1
        FROM int8_tbl t3
        WHERE
            ss.y IS NOT NULL
        LIMIT 1)
ORDER BY
    1,
    2;

SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            q1 AS x,
            42 AS y
        FROM
            int8_tbl t2) ss ON t1.q2 = ss.x
WHERE
    1 = (
        SELECT
            1
        FROM int8_tbl t3
        WHERE
            ss.y IS NOT NULL
        LIMIT 1)
ORDER BY
    1,
    2;

--
-- variant where a PlaceHolderVar is needed at a join, but not above the join
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl AS i41,
    LATERAL (
        SELECT
            1 AS x
        FROM (
            SELECT
                i41.f1 AS lat,
                i42.f1 AS loc
            FROM
                int8_tbl AS i81,
                int4_tbl AS i42) AS ss1
            RIGHT JOIN int4_tbl AS i43 ON (i43.f1 > 1)
        WHERE
            ss1.loc = ss1.lat) AS ss2
WHERE
    i41.f1 > 0;

SELECT
    *
FROM
    int4_tbl AS i41,
    LATERAL (
        SELECT
            1 AS x
        FROM (
            SELECT
                i41.f1 AS lat,
                i42.f1 AS loc
            FROM
                int8_tbl AS i81,
                int4_tbl AS i42) AS ss1
            RIGHT JOIN int4_tbl AS i43 ON (i43.f1 > 1)
        WHERE
            ss1.loc = ss1.lat) AS ss2
WHERE
    i41.f1 > 0;

--
-- test the corner cases FULL JOIN ON TRUE and FULL JOIN ON FALSE
--
SELECT
    *
FROM
    int4_tbl a
    FULL JOIN int4_tbl b ON TRUE;

SELECT
    *
FROM
    int4_tbl a
    FULL JOIN int4_tbl b ON FALSE;

--
-- test for ability to use a cartesian join when necessary
--
CREATE temp TABLE q1 AS
SELECT
    1 AS q1;

CREATE temp TABLE q2 AS
SELECT
    0 AS q2;

ANALYZE q1;

ANALYZE q2;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
    JOIN int4_tbl ON f1 = twothousand,
    q1,
    q2
WHERE
    q1 = thousand
    OR q2 = thousand;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
    JOIN int4_tbl ON f1 = twothousand,
    q1,
    q2
WHERE
    thousand = (q1 + q2);

--
-- test ability to generate a suitable plan for a star-schema query
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1,
    int8_tbl a,
    int8_tbl b
WHERE
    thousand = a.q1
    AND tenthous = b.q1
    AND a.q2 = 1
    AND b.q2 = 2;

--
-- test a corner case in which we shouldn't apply the star-schema optimization
--
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.unique2,
    t1.stringu1,
    t2.unique1,
    t2.stringu2
FROM
    tenk1 t1
    INNER JOIN int4_tbl i1
    LEFT JOIN (
        SELECT
            v1.x2,
            v2.y1,
            11 AS d1
        FROM (
            SELECT
                1,
                0
            FROM
                onerow) v1 (x1,
                x2)
            LEFT JOIN (
                SELECT
                    3,
                    1
                FROM
                    onerow) v2 (y1,
                    y2) ON v1.x1 = v2.y2) subq1 ON (i1.f1 = subq1.x2) ON (t1.unique2 = subq1.d1)
    LEFT JOIN tenk1 t2 ON (subq1.y1 = t2.unique1)
WHERE
    t1.unique2 < 42
    AND t1.stringu1 > t2.stringu2;

SELECT
    t1.unique2,
    t1.stringu1,
    t2.unique1,
    t2.stringu2
FROM
    tenk1 t1
    INNER JOIN int4_tbl i1
    LEFT JOIN (
        SELECT
            v1.x2,
            v2.y1,
            11 AS d1
        FROM (
            SELECT
                1,
                0
            FROM
                onerow) v1 (x1,
                x2)
            LEFT JOIN (
                SELECT
                    3,
                    1
                FROM
                    onerow) v2 (y1,
                    y2) ON v1.x1 = v2.y2) subq1 ON (i1.f1 = subq1.x2) ON (t1.unique2 = subq1.d1)
    LEFT JOIN tenk1 t2 ON (subq1.y1 = t2.unique1)
WHERE
    t1.unique2 < 42
    AND t1.stringu1 > t2.stringu2;

-- variant that isn't quite a star-schema case
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss1.d1
FROM
    tenk1 AS t1
    INNER JOIN tenk1 AS t2 ON t1.tenthous = t2.ten
    INNER JOIN int8_tbl AS i8
    LEFT JOIN int4_tbl AS i4
    INNER JOIN (
        SELECT
            64::information_schema.cardinal_number AS d1
        FROM
            tenk1 t3,
            LATERAL (
                SELECT
                    abs(t3.unique1) + random()) ss0 (x)
            WHERE
                t3.fivethous < 0) AS ss1 ON i4.f1 = ss1.d1 ON i8.q1 = i4.f1 ON t1.tenthous = ss1.d1
WHERE
    t1.unique1 < i4.f1;

SELECT
    ss1.d1
FROM
    tenk1 AS t1
    INNER JOIN tenk1 AS t2 ON t1.tenthous = t2.ten
    INNER JOIN int8_tbl AS i8
    LEFT JOIN int4_tbl AS i4
    INNER JOIN (
        SELECT
            64::information_schema.cardinal_number AS d1
        FROM
            tenk1 t3,
            LATERAL (
                SELECT
                    abs(t3.unique1) + random()) ss0 (x)
            WHERE
                t3.fivethous < 0) AS ss1 ON i4.f1 = ss1.d1 ON i8.q1 = i4.f1 ON t1.tenthous = ss1.d1
WHERE
    t1.unique1 < i4.f1;

-- this variant is foldable by the remove-useless-RESULT-RTEs code
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.unique2,
    t1.stringu1,
    t2.unique1,
    t2.stringu2
FROM
    tenk1 t1
    INNER JOIN int4_tbl i1
    LEFT JOIN (
        SELECT
            v1.x2,
            v2.y1,
            11 AS d1
        FROM (
            VALUES (1, 0)) v1 (x1, x2)
            LEFT JOIN (
                VALUES (3, 1)) v2 (y1, y2) ON v1.x1 = v2.y2) subq1 ON (i1.f1 = subq1.x2) ON (t1.unique2 = subq1.d1)
    LEFT JOIN tenk1 t2 ON (subq1.y1 = t2.unique1)
WHERE
    t1.unique2 < 42
    AND t1.stringu1 > t2.stringu2;

SELECT
    t1.unique2,
    t1.stringu1,
    t2.unique1,
    t2.stringu2
FROM
    tenk1 t1
    INNER JOIN int4_tbl i1
    LEFT JOIN (
        SELECT
            v1.x2,
            v2.y1,
            11 AS d1
        FROM (
            VALUES (1, 0)) v1 (x1, x2)
            LEFT JOIN (
                VALUES (3, 1)) v2 (y1, y2) ON v1.x1 = v2.y2) subq1 ON (i1.f1 = subq1.x2) ON (t1.unique2 = subq1.d1)
    LEFT JOIN tenk1 t2 ON (subq1.y1 = t2.unique1)
WHERE
    t1.unique2 < 42
    AND t1.stringu1 > t2.stringu2;

-- Here's a variant that we can't fold too aggressively, though,
-- or we end up with noplace to evaluate the lateral PHV
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS x) ss1
    LEFT JOIN (
        SELECT
            2 AS y) ss2 ON (TRUE),
    LATERAL (
        SELECT
            ss2.y AS z
        LIMIT 1) ss3;

SELECT
    *
FROM (
    SELECT
        1 AS x) ss1
    LEFT JOIN (
        SELECT
            2 AS y) ss2 ON (TRUE),
    LATERAL (
        SELECT
            ss2.y AS z
        LIMIT 1) ss3;

-- Also, we mustn't remove an RTE_RESULT that is the only baserel where a PHV
-- can be evaluated, even when the PHV's phrels also mention an outer join.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x)
    LEFT JOIN (
        SELECT
            q
        FROM (
            SELECT
                7 AS q
            FROM (
                SELECT
                WHERE
                    FALSE) ss1) ss2
        LEFT JOIN (
            SELECT
                8 AS z) ss3 ON TRUE) ss4 ON TRUE;

SELECT
    *
FROM (
    VALUES (1),
        (2)) v (x)
    LEFT JOIN (
        SELECT
            q
        FROM (
            SELECT
                7 AS q
            FROM (
                SELECT
                WHERE
                    FALSE) ss1) ss2
        LEFT JOIN (
            SELECT
                8 AS z) ss3 ON TRUE) ss4 ON TRUE;

-- Nor an RTE_RESULT whose PHV is nested in a PHV evaluated at some but not
-- all of the sibling rels
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.z
FROM (
    SELECT
        1) s1
    LEFT JOIN ((
            SELECT
                1) s2
            LEFT JOIN (
                SELECT
                    1 AS x) v ON TRUE
                CROSS JOIN (LATERAL (
                        SELECT
                            coalesce(v.x, 0) AS z,
                            f1
                        FROM
                            int4_tbl) ss
                        CROSS JOIN LATERAL (
                            SELECT
                                ss.f1 OFFSET 0) g)) ON TRUE;

SELECT
    ss.z
FROM (
    SELECT
        1) s1
    LEFT JOIN ((
            SELECT
                1) s2
            LEFT JOIN (
                SELECT
                    1 AS x) v ON TRUE
                CROSS JOIN (LATERAL (
                        SELECT
                            coalesce(v.x, 0) AS z,
                            f1
                        FROM
                            int4_tbl) ss
                        CROSS JOIN LATERAL (
                            SELECT
                                ss.f1 OFFSET 0) g)) ON TRUE;

-- Same, with the PHVs coming from grouping sets
EXPLAIN (
    COSTS OFF
)
SELECT
    s1.x
FROM (
    VALUES (1)) AS v (x),
    LATERAL (
        SELECT
            v.x + 1, 2) AS s1 (x, y)
    CROSS JOIN generate_series(s1.y, s1.y) AS g
GROUP BY
    GROUPING SETS (1,
        1);

SELECT
    s1.x
FROM (
    VALUES (1)) AS v (x),
    LATERAL (
        SELECT
            v.x + 1, 2) AS s1 (x, y)
    CROSS JOIN generate_series(s1.y, s1.y) AS g
GROUP BY
    GROUPING SETS (1,
        1);

-- But we can remove it if the outer PHV covers all of the sibling rels
EXPLAIN (
    COSTS OFF
)
SELECT
    s.y
FROM (
    VALUES (1)) v (x),
    LATERAL (
        SELECT
            v.x + f1 AS y
        FROM
            int4_tbl) s
GROUP BY
    GROUPING SETS (1, ());

-- This example demonstrates the folly of our old "have_dangerous_phv" logic
BEGIN;
SET local from_collapse_limit TO 2;
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (
        SELECT
            coalesce(t2.q1 + x, 0)
        FROM
            int8_tbl t2,
            LATERAL (
                SELECT
                    t3.q1 AS x
                FROM
                    int8_tbl t3,
                    LATERAL (
                        SELECT
                            t2.q1,
                            t3.q1 OFFSET 0) s)) ON TRUE;
ROLLBACK;

-- ... not that the initial replacement didn't have some bugs too
BEGIN;
CREATE temp TABLE t (
    i int PRIMARY KEY
);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    t t1
    LEFT JOIN (
        SELECT
            1 AS x,
            *
        FROM
            t t2 (i2)) t2ss ON t1.i = t2ss.i2
    LEFT JOIN t t3 (i3) ON FALSE
    LEFT JOIN t t4 (i4) ON t4.i4 > t2ss.x;
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        k
    FROM (
        SELECT
            i,
            coalesce(i, j) AS k
        FROM (
            SELECT
                i
            FROM
                t
            UNION ALL
            SELECT
                0)
            JOIN (
                SELECT
                    1 AS j
                LIMIT 1) ON i = j)
        RIGHT JOIN (
            SELECT
                2 AS x) ON TRUE
            JOIN (
                SELECT
                    3 AS y) ON i IS NOT NULL),
LATERAL (
    SELECT
        k AS kl
    LIMIT 1);
ROLLBACK;

-- nestloop parameter PHV whose ph_eval_at mentions an outer join that is
-- computed in the rels supplying the parameters
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    v.k
FROM (
    SELECT
        1) d
    LEFT JOIN (
        SELECT
            t1.f1,
            1
        FROM
            int4_tbl t1,
            onerow t2
            LEFT JOIN onerow t3 ON TRUE) s (x,
        y) ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            s.y
        FROM
            onerow t4) v (k) ON TRUE
WHERE
    v.k > s.x;

-- likewise, where an upper nestloop could wrongly claim the parameter
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    v.k,
    g
FROM (
    SELECT
        1) d
    LEFT JOIN (
        SELECT
            t1.f1,
            1
        FROM
            int4_tbl t1,
            onerow t2
            LEFT JOIN onerow t3 ON TRUE) s (x,
        y) ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            s.y
        FROM
            onerow t4) v (k) ON TRUE,
    LATERAL generate_series(v.k, 1) g
WHERE
    v.k > s.x;

-- PHVs containing SubLinks are quite tricky to get right
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i8
    INNER JOIN (
        SELECT
            (
                SELECT
                    TRUE) AS x
            FROM
                int4_tbl i4,
                LATERAL (
                    SELECT
                        i4.f1 AS y
                    LIMIT 1) ss1
            WHERE
                i4.f1 = 0) ss2 ON TRUE
    RIGHT JOIN (
        SELECT
            FALSE AS z) ss3 ON TRUE,
    LATERAL (
        SELECT
            i8.q2 AS q2l
        WHERE
            x
        LIMIT 1) ss4
WHERE
    i8.q2 = 123;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i8
    INNER JOIN (
        SELECT
            (
                SELECT
                    TRUE) AS x
            FROM
                int4_tbl i4,
                LATERAL (
                    SELECT
                        1 AS y
                    LIMIT 1) ss1
            WHERE
                i4.f1 = 0) ss2 ON TRUE
    RIGHT JOIN (
        SELECT
            FALSE AS z) ss3 ON TRUE,
    LATERAL (
        SELECT
            i8.q2 AS q2l
        WHERE
            x
        LIMIT 1) ss4
WHERE
    i8.q2 = 123;

-- Test proper handling of appendrel PHVs during useless-RTE removal
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        0 AS z) AS t1
    LEFT JOIN (
        SELECT
            TRUE AS a) AS t2 ON TRUE,
    LATERAL (
        SELECT
            TRUE AS b
    UNION ALL
    SELECT
        a AS b) AS t3
WHERE
    b;

SELECT
    *
FROM (
    SELECT
        0 AS z) AS t1
    LEFT JOIN (
        SELECT
            TRUE AS a) AS t2 ON TRUE,
    LATERAL (
        SELECT
            TRUE AS b
    UNION ALL
    SELECT
        a AS b) AS t3
WHERE
    b;

-- Test PHV in a semijoin qual, which confused useless-RTE removal (bug #17700)
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH ctetable AS NOT MATERIALIZED (
    SELECT
        1 AS f1
)
SELECT
    *
FROM
    ctetable c1
WHERE
    f1 IN (
        SELECT
            c3.f1
        FROM
            ctetable c2
        FULL JOIN ctetable c3 ON TRUE);

WITH ctetable AS NOT MATERIALIZED (
    SELECT
        1 AS f1
)
SELECT
    *
FROM
    ctetable c1
WHERE
    f1 IN (
        SELECT
            c3.f1
        FROM
            ctetable c2
        FULL JOIN ctetable c3 ON TRUE);

-- Test PHV that winds up in a Result node, despite having nonempty nullingrels
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    table_catalog,
    table_name
FROM
    int4_tbl t1
    INNER JOIN (int8_tbl t2
        LEFT JOIN information_schema.column_udt_usage ON NULL) ON NULL;

-- Test handling of qual pushdown to appendrel members with non-Var outputs
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl
    LEFT JOIN (
        SELECT
            text 'foo'
    UNION ALL
    SELECT
        text 'bar') ss (x) ON TRUE
WHERE
    ss.x IS NULL;

-- Test a join qual referencing a nulled appendrel output only within a PHV
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            1 AS x
    UNION ALL
    SELECT
        2) s ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            s.x AS y
        FROM
            int4_tbl t2) ss ON TRUE
    LEFT JOIN int4_tbl t3 ON ss.y IS NULL;

-- Same, but the join qual's required_relids don't include the nulling OJ
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM ((int4_tbl t1
    LEFT JOIN (
        SELECT
            1 AS x
    UNION ALL
    SELECT
        2) s ON t1.f1 < s.x)
JOIN LATERAL (
    SELECT
        coalesce(s.x, t2.f1) AS y
    FROM
        int4_tbl t2) ss ON TRUE)
    FULL JOIN int4_tbl t3 ON t3.f1 = t1.f1
        AND ss.y = t3.f1
    RIGHT JOIN int4_tbl t4 ON t3.f1 = t4.f1;

-- Test computation of varnullingrels when translating appendrel Var
BEGIN;
CREATE temp TABLE t_append (
    a int NOT NULL,
    b int
);
INSERT INTO t_append
    VALUES (1, 1);
INSERT INTO t_append
    VALUES (2, 3);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.a,
    s.a
FROM
    t_append t1
    LEFT JOIN t_append t2 ON t1.a = t2.b
    JOIN LATERAL (
        SELECT
            t1.a AS a
    UNION ALL
    SELECT
        t2.a AS a) s ON TRUE
WHERE
    s.a IS NOT NULL;
SELECT
    t1.a,
    s.a
FROM
    t_append t1
    LEFT JOIN t_append t2 ON t1.a = t2.b
    JOIN LATERAL (
        SELECT
            t1.a AS a
    UNION ALL
    SELECT
        t2.a AS a) s ON TRUE
WHERE
    s.a IS NOT NULL;
ROLLBACK;

--
-- test inlining of immutable functions
--
CREATE FUNCTION f_immutable_int4 (i integer)
    RETURNS integer
    AS $$
BEGIN
    RETURN i;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

-- check optimization of function scan with join
EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1,
    (
        SELECT
            *
        FROM
            f_immutable_int4 (1) x) x
WHERE
    x = unique1;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unique1,
    x.*
FROM
    tenk1,
    (
        SELECT
            *,
            random()
        FROM
            f_immutable_int4 (1) x) x
WHERE
    x = unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1,
    f_immutable_int4 (1) x
WHERE
    x = unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1,
    LATERAL f_immutable_int4 (1) x
WHERE
    x = unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1,
    LATERAL f_immutable_int4 (1) x
WHERE
    x IN (
        SELECT
            17);

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    x
FROM
    tenk1
    JOIN f_immutable_int4 (1) x ON unique1 = x;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    x
FROM
    tenk1
    LEFT JOIN f_immutable_int4 (1) x ON unique1 = x;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    x
FROM
    tenk1
    RIGHT JOIN f_immutable_int4 (1) x ON unique1 = x;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    x
FROM
    tenk1
    FULL JOIN f_immutable_int4 (1) x ON unique1 = x;

-- check that pullup of a const function allows further const-folding
EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1,
    f_immutable_int4 (1) x
WHERE
    x = 42;

-- test inlining of immutable functions with PlaceHolderVars
EXPLAIN (
    COSTS OFF
)
SELECT
    nt3.id
FROM
    nt3 AS nt3
    LEFT JOIN (
        SELECT
            nt2.*,
            (nt2.b1
                    OR i4 = 42) AS b3
            FROM
                nt2 AS nt2
        LEFT JOIN f_immutable_int4 (0) i4 ON i4 = nt2.nt1_id) AS ss2 ON ss2.id = nt3.nt2_id
WHERE
    nt3.id = 1
    AND ss2.b3;

DROP FUNCTION f_immutable_int4 (int);

-- test inlining when function returns composite
CREATE FUNCTION mki8 (bigint, bigint)
    RETURNS int8_tbl
    AS $$
    SELECT
        ROW ($1,
            $2)::int8_tbl
$$
LANGUAGE sql;

CREATE FUNCTION mki4 (int)
    RETURNS int4_tbl
    AS $$
    SELECT
        ROW ($1)::int4_tbl
$$
LANGUAGE sql;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    mki8 (1, 2);

SELECT
    *
FROM
    mki8 (1, 2);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    mki4 (42);

SELECT
    *
FROM
    mki4 (42);

DROP FUNCTION mki8 (bigint, bigint);

DROP FUNCTION mki4 (int);

-- test const-folding of a whole-row Var into a per-field Var
-- (need to inline a function to reach this case, else parser does it)
CREATE FUNCTION f_field_select (t onek)
    RETURNS int4
    AS $$
    SELECT
        t.unique2;
$$
LANGUAGE sql
IMMUTABLE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (t2.*).unique1,
    f_field_select (t2)
FROM
    tenk1 t1
    LEFT JOIN onek t2 ON t1.unique1 = t2.unique1
    LEFT JOIN int8_tbl t3 ON TRUE;

DROP FUNCTION f_field_select (t onek);

--
-- test extraction of restriction OR clauses from join OR clause
-- (we used to only do this for indexable clauses)
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    JOIN tenk1 b ON (a.unique1 = 1
            AND b.unique1 = 2)
        OR (a.unique2 = 3
            AND b.hundred = 4);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    JOIN tenk1 b ON (a.unique1 = 1
            AND b.unique1 = 2)
        OR (a.unique2 = 3
            AND b.ten = 4);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    JOIN tenk1 b ON (a.unique1 = 1
            AND b.unique1 = 2)
        OR ((a.unique2 = 3
                OR a.unique2 = 7)
            AND b.hundred = 4);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    JOIN tenk1 b ON (a.unique1 = 1
            AND b.unique1 = 2)
        OR ((a.unique2 = 3
                OR a.unique2 = 7)
            AND b.hundred = 4);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    JOIN tenk1 b ON (a.unique1 < 20
            OR a.unique1 = 3
            OR a.unique1 = 1
            AND b.unique1 = 2)
        OR ((a.unique2 = 3
                OR a.unique2 = 7)
            AND b.hundred = 4);

--
-- test placement of movable quals in a parameterized join tree
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tenk1 t2
        JOIN tenk1 t3 ON t2.thousand = t3.unique2) ON t1.hundred = t2.hundred
        AND t1.ten = t3.ten
WHERE
    t1.unique1 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN (tenk1 t2
        JOIN tenk1 t3 ON t2.thousand = t3.unique2) ON t1.hundred = t2.hundred
        AND t1.ten + t2.ten = t3.ten
WHERE
    t1.unique1 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a
    JOIN tenk1 b ON a.unique1 = b.unique2
    LEFT JOIN tenk1 c ON a.unique2 = b.unique1
        AND c.thousand = a.thousand
    JOIN int4_tbl ON b.thousand = f1;

SELECT
    count(*)
FROM
    tenk1 a
    JOIN tenk1 b ON a.unique1 = b.unique2
    LEFT JOIN tenk1 c ON a.unique2 = b.unique1
        AND c.thousand = a.thousand
    JOIN int4_tbl ON b.thousand = f1;

EXPLAIN (
    COSTS OFF
)
SELECT
    b.unique1
FROM
    tenk1 a
    JOIN tenk1 b ON a.unique1 = b.unique2
    LEFT JOIN tenk1 c ON b.unique1 = 42
        AND c.thousand = a.thousand
    JOIN int4_tbl i1 ON b.thousand = f1
    RIGHT JOIN int4_tbl i2 ON i2.f1 = b.tenthous
ORDER BY
    1;

SELECT
    b.unique1
FROM
    tenk1 a
    JOIN tenk1 b ON a.unique1 = b.unique2
    LEFT JOIN tenk1 c ON b.unique1 = 42
        AND c.thousand = a.thousand
    JOIN int4_tbl i1 ON b.thousand = f1
    RIGHT JOIN int4_tbl i2 ON i2.f1 = b.tenthous
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        unique1,
        q1,
        coalesce(unique1, -1) + q1 AS fault
    FROM
        int8_tbl
        LEFT JOIN tenk1 ON (q2 = unique2)) ss
WHERE
    fault = 122
ORDER BY
    fault;

SELECT
    *
FROM (
    SELECT
        unique1,
        q1,
        coalesce(unique1, -1) + q1 AS fault
    FROM
        int8_tbl
        LEFT JOIN tenk1 ON (q2 = unique2)) ss
WHERE
    fault = 122
ORDER BY
    fault;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (1, ARRAY[10, 20]),
        (2, ARRAY[20, 30])) AS v1 (v1x, v1ys)
    LEFT JOIN (
        VALUES (1, 10), (2, 20), (2, NULL)) AS v2 (v2x, v2y) ON v2x = v1x
    LEFT JOIN unnest(v1ys) AS u1 (u1y) ON u1y = v2y;

SELECT
    *
FROM (
    VALUES (1, ARRAY[10, 20]),
        (2, ARRAY[20, 30])) AS v1 (v1x, v1ys)
    LEFT JOIN (
        VALUES (1, 10), (2, 20), (2, NULL)) AS v2 (v2x, v2y) ON v2x = v1x
    LEFT JOIN unnest(v1ys) AS u1 (u1y) ON u1y = v2y;

--
-- test handling of potential equivalence clauses above outer joins
--
EXPLAIN (
    COSTS OFF
)
SELECT
    q1,
    unique2,
    thousand,
    hundred
FROM
    int8_tbl a
    LEFT JOIN tenk1 b ON q1 = unique2
WHERE
    coalesce(thousand, 123) = q1
    AND q1 = coalesce(hundred, 123);

SELECT
    q1,
    unique2,
    thousand,
    hundred
FROM
    int8_tbl a
    LEFT JOIN tenk1 b ON q1 = unique2
WHERE
    coalesce(thousand, 123) = q1
    AND q1 = coalesce(hundred, 123);

EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    unique2,
    CASE WHEN unique2 IS NULL THEN
        f1
    ELSE
        0
    END
FROM
    int4_tbl a
    LEFT JOIN tenk1 b ON f1 = unique2
WHERE (
    CASE WHEN unique2 IS NULL THEN
        f1
    ELSE
        0
    END) = 0;

SELECT
    f1,
    unique2,
    CASE WHEN unique2 IS NULL THEN
        f1
    ELSE
        0
    END
FROM
    int4_tbl a
    LEFT JOIN tenk1 b ON f1 = unique2
WHERE (
    CASE WHEN unique2 IS NULL THEN
        f1
    ELSE
        0
    END) = 0;

--
-- another case with equivalence clauses above outer joins (bug #8591)
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.unique1,
    b.unique1,
    c.unique1,
    coalesce(b.twothousand, a.twothousand)
FROM
    tenk1 a
    LEFT JOIN tenk1 b ON b.thousand = a.unique1
    LEFT JOIN tenk1 c ON c.unique2 = coalesce(b.twothousand, a.twothousand)
WHERE
    a.unique2 < 10
    AND coalesce(b.twothousand, a.twothousand) = 44;

SELECT
    a.unique1,
    b.unique1,
    c.unique1,
    coalesce(b.twothousand, a.twothousand)
FROM
    tenk1 a
    LEFT JOIN tenk1 b ON b.thousand = a.unique1
    LEFT JOIN tenk1 c ON c.unique2 = coalesce(b.twothousand, a.twothousand)
WHERE
    a.unique2 < 10
    AND coalesce(b.twothousand, a.twothousand) = 44;

-- related case
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON t1.q2 = t2.q1,
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl t3
        WHERE
            t2.q1 = t2.q2) ss;

SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN int8_tbl t2 ON t1.q2 = t2.q1,
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl t3
        WHERE
            t2.q1 = t2.q2) ss;

--
-- check handling of join aliases when flattening multiple levels of subquery
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    foo1.join_key AS foo1_id,
    foo3.join_key AS foo3_id,
    bug_field
FROM (
    VALUES (0),
        (1)) foo1 (join_key)
    LEFT JOIN (
        SELECT
            join_key, bug_field
        FROM (
            SELECT
                ss1.join_key, ss1.bug_field
            FROM (
                SELECT
                    f1 AS join_key, 666 AS bug_field
                FROM
                    int4_tbl i1) ss1) foo2
            LEFT JOIN (
                SELECT
                    unique2 AS join_key
                FROM
                    tenk1 i2) ss2 USING (join_key)) foo3 USING (join_key);

SELECT
    foo1.join_key AS foo1_id,
    foo3.join_key AS foo3_id,
    bug_field
FROM (
    VALUES (0),
        (1)) foo1 (join_key)
    LEFT JOIN (
        SELECT
            join_key, bug_field
        FROM (
            SELECT
                ss1.join_key, ss1.bug_field
            FROM (
                SELECT
                    f1 AS join_key, 666 AS bug_field
                FROM
                    int4_tbl i1) ss1) foo2
            LEFT JOIN (
                SELECT
                    unique2 AS join_key
                FROM
                    tenk1 i2) ss2 USING (join_key)) foo3 USING (join_key);

--
-- check handling of a variable-free join alias
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl i0
    LEFT JOIN ((
            SELECT
                *,
                123 AS x
            FROM
                int4_tbl i1) ss1
            LEFT JOIN (
                SELECT
                    *,
                    q2 AS x
                FROM
                    int8_tbl i2) ss2 USING (x)) ss0 ON (i0.f1 = ss0.f1)
ORDER BY
    i0.f1,
    x;

SELECT
    *
FROM
    int4_tbl i0
    LEFT JOIN ((
            SELECT
                *,
                123 AS x
            FROM
                int4_tbl i1) ss1
            LEFT JOIN (
                SELECT
                    *,
                    q2 AS x
                FROM
                    int8_tbl i2) ss2 USING (x)) ss0 ON (i0.f1 = ss0.f1)
ORDER BY
    i0.f1,
    x;

--
-- test successful handling of nested outer joins with degenerate join quals
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2,
            int4_tbl i4b2) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2,
            int4_tbl i4b2) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2,
            int4_tbl i4b2
        WHERE
            q1 = f1) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

SELECT
    t1.*
FROM
    text_tbl t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            int8_tbl i8b1) b1
    LEFT JOIN int8_tbl i8
    LEFT JOIN (
        SELECT
            *,
            NULL::int AS d2
        FROM
            int8_tbl i8b2,
            int4_tbl i4b2
        WHERE
            q1 = f1) b2 ON (i8.q1 = b2.q1) ON (b2.d2 = b1.q2) ON (t1.f1 = b1.d1)
    LEFT JOIN int4_tbl i4 ON (i8.q2 = i4.f1);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    text_tbl t1
    INNER JOIN int8_tbl i8 ON i8.q2 = 456
    RIGHT JOIN text_tbl t2 ON t1.f1 = 'doh!'
    LEFT JOIN int4_tbl i4 ON i8.q1 = i4.f1;

SELECT
    *
FROM
    text_tbl t1
    INNER JOIN int8_tbl i8 ON i8.q2 = 456
    RIGHT JOIN text_tbl t2 ON t1.f1 = 'doh!'
    LEFT JOIN int4_tbl i4 ON i8.q1 = i4.f1;

-- check handling of a variable-free qual for a non-commutable outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    nspname
FROM (
    SELECT
        1 AS x) ss1
    LEFT JOIN (
        SELECT
            n.nspname,
            c.relname
        FROM
            pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE
            c.relkind = 'r') ss2 ON FALSE;

-- check handling of apparently-commutable outer joins with non-commutable
-- joins between them
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    int4_tbl i4
    LEFT JOIN int8_tbl i8 ON i4.f1 IS NOT NULL
    LEFT JOIN (
        SELECT
            1 AS a) ss1 ON NULL
    JOIN int4_tbl i42 ON ss1.a IS NULL
        OR i8.q1 <> i8.q2
    RIGHT JOIN (
        SELECT
            2 AS b) ss2 ON ss2.b < i4.f1;

--
-- test for appropriate join order in the presence of lateral references
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    text_tbl t1
    LEFT JOIN int8_tbl i8 ON i8.q2 = 123,
    LATERAL (
        SELECT
            i8.q1,
            t2.f1
        FROM
            text_tbl t2
        LIMIT 1) AS ss
WHERE
    t1.f1 = ss.f1;

SELECT
    *
FROM
    text_tbl t1
    LEFT JOIN int8_tbl i8 ON i8.q2 = 123,
    LATERAL (
        SELECT
            i8.q1,
            t2.f1
        FROM
            text_tbl t2
        LIMIT 1) AS ss
WHERE
    t1.f1 = ss.f1;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    text_tbl t1
    LEFT JOIN int8_tbl i8 ON i8.q2 = 123,
    LATERAL (
        SELECT
            i8.q1,
            t2.f1
        FROM
            text_tbl t2
        LIMIT 1) AS ss1,
    LATERAL (
        SELECT
            ss1.*
        FROM
            text_tbl t3
        LIMIT 1) AS ss2
WHERE
    t1.f1 = ss2.f1;

SELECT
    *
FROM
    text_tbl t1
    LEFT JOIN int8_tbl i8 ON i8.q2 = 123,
    LATERAL (
        SELECT
            i8.q1,
            t2.f1
        FROM
            text_tbl t2
        LIMIT 1) AS ss1,
    LATERAL (
        SELECT
            ss1.*
        FROM
            text_tbl t3
        LIMIT 1) AS ss2
WHERE
    t1.f1 = ss2.f1;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM
    text_tbl AS tt1
    INNER JOIN text_tbl AS tt2 ON (tt1.f1 = 'foo')
    LEFT JOIN text_tbl AS tt3 ON (tt3.f1 = 'foo')
    LEFT JOIN text_tbl AS tt4 ON (tt3.f1 = tt4.f1),
    LATERAL (
        SELECT
            tt4.f1 AS c0
        FROM
            text_tbl AS tt5
        LIMIT 1) AS ss1
WHERE
    tt1.f1 = ss1.c0;

SELECT
    1
FROM
    text_tbl AS tt1
    INNER JOIN text_tbl AS tt2 ON (tt1.f1 = 'foo')
    LEFT JOIN text_tbl AS tt3 ON (tt3.f1 = 'foo')
    LEFT JOIN text_tbl AS tt4 ON (tt3.f1 = tt4.f1),
    LATERAL (
        SELECT
            tt4.f1 AS c0
        FROM
            text_tbl AS tt5
        LIMIT 1) AS ss1
WHERE
    tt1.f1 = ss1.c0;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM
    int4_tbl AS i4
    INNER JOIN ((
            SELECT
                42 AS n
            FROM
                int4_tbl x1
                LEFT JOIN int8_tbl x2 ON f1 = q1) AS ss1
            RIGHT JOIN (
                SELECT
                    1 AS z) AS ss2 ON TRUE) ON FALSE,
    LATERAL (
        SELECT
            i4.f1,
            ss1.n
        FROM
            int8_tbl AS i8
        LIMIT 1) AS ss3;

SELECT
    1
FROM
    int4_tbl AS i4
    INNER JOIN ((
            SELECT
                42 AS n
            FROM
                int4_tbl x1
                LEFT JOIN int8_tbl x2 ON f1 = q1) AS ss1
            RIGHT JOIN (
                SELECT
                    1 AS z) AS ss2 ON TRUE) ON FALSE,
    LATERAL (
        SELECT
            i4.f1,
            ss1.n
        FROM
            int8_tbl AS i8
        LIMIT 1) AS ss3;

--
-- check a case where we formerly generated invalid parameterized paths
--
BEGIN;
CREATE temp TABLE t (
    a int UNIQUE
);
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    t t1
    JOIN LATERAL (
        SELECT
            t1.a
        FROM (
            SELECT
                1) foo OFFSET 0) AS s1 ON TRUE
    JOIN (
        SELECT
            1
        FROM
            t t2
            INNER JOIN (t t3
                LEFT JOIN (t t4
                    LEFT JOIN t t5 ON t4.a = 1) ON t3.a = t4.a) ON FALSE
        WHERE
            t3.a = coalesce(t5.a, 1)) AS s2 ON TRUE;
ROLLBACK;

--
-- check a case in which a PlaceHolderVar forces join order
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss2.*
FROM
    int4_tbl i41
    LEFT JOIN int8_tbl i8
    JOIN (
        SELECT
            i42.f1 AS c1,
            i43.f1 AS c2,
            42 AS c3
        FROM
            int4_tbl i42,
            int4_tbl i43) ss1 ON i8.q1 = ss1.c2 ON i41.f1 = ss1.c1,
    LATERAL (
        SELECT
            i41.*,
            i8.*,
            ss1.*
        FROM
            text_tbl
        LIMIT 1) ss2
WHERE
    ss1.c2 = 0;

SELECT
    ss2.*
FROM
    int4_tbl i41
    LEFT JOIN int8_tbl i8
    JOIN (
        SELECT
            i42.f1 AS c1,
            i43.f1 AS c2,
            42 AS c3
        FROM
            int4_tbl i42,
            int4_tbl i43) ss1 ON i8.q1 = ss1.c2 ON i41.f1 = ss1.c1,
    LATERAL (
        SELECT
            i41.*,
            i8.*,
            ss1.*
        FROM
            text_tbl
        LIMIT 1) ss2
WHERE
    ss1.c2 = 0;

--
-- check that a join is disallowed when a lateral reference to an outer-join
-- output would have to be passed down into that outer join's own input
--
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            b.q1 AS bx,
            1 AS one
        FROM
            int4_tbl a
            LEFT JOIN int8_tbl b ON a.f1 = b.q2) t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            c.f1 AS cnt
        FROM
            int4_tbl c
        WHERE
            c.f1 = t2.one OFFSET 0) t3 ON t2.bx = t3.cnt;

SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            b.q1 AS bx,
            1 AS one
        FROM
            int4_tbl a
            LEFT JOIN int8_tbl b ON a.f1 = b.q2) t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            c.f1 AS cnt
        FROM
            int4_tbl c
        WHERE
            c.f1 = t2.one OFFSET 0) t3 ON t2.bx = t3.cnt;

-- but a function scan can compute the PHV's expression itself, so the join
-- is allowed
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*),
    sum(f)
FROM
    int8_tbl d
    LEFT JOIN (
        SELECT
            coalesce(t2.q1, 0) AS x,
            t2.q1 AS q
        FROM
            int8_tbl t1
            LEFT JOIN int8_tbl t2 ON TRUE) ss ON TRUE
    LEFT JOIN LATERAL generate_series(ss.x, 124) f ON ss.q = 123;

SELECT
    count(*),
    sum(f)
FROM
    int8_tbl d
    LEFT JOIN (
        SELECT
            coalesce(t2.q1, 0) AS x,
            t2.q1 AS q
        FROM
            int8_tbl t1
            LEFT JOIN int8_tbl t2 ON TRUE) ss ON TRUE
    LEFT JOIN LATERAL generate_series(ss.x, 124) f ON ss.q = 123;

--
-- check that a join is disallowed when its lateral reference can only be
-- satisfied by way of a rel that laterally references the join itself
--
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    LEFT JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

SELECT
    1
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    LEFT JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

-- likewise when the outer join above the lateral referencer is a full join
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    FULL JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    FULL JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

-- likewise when the lateral referencer is part of a sub-joinlist
SET from_collapse_limit TO 4;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE,
    LATERAL (
        SELECT
            t2.f1 OFFSET 0) s1
    JOIN int8_tbl t3 ON s1.f1 = t3.q1,
    LATERAL (
        SELECT
            t3.q2 OFFSET 0) s2
WHERE
    s2.q2 > t1.f1;

RESET from_collapse_limit;

--
-- check that an outer join is not taken to commute with a lower outer join
-- when its clause references the lower join's RHS only laterally within a
-- PlaceHolderVar
--
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    int4_tbl t1
    LEFT JOIN int4_tbl t2 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            t2.f1,
            1
        FROM
            int4_tbl t3) s (x,
        y) ON TRUE
    LEFT JOIN int4_tbl t4 ON t4.f1 = s.x
    JOIN int4_tbl t5 ON TRUE
WHERE
    s.y IS NOT NULL;

--
-- check that a cloned outer-join qual is not enforced multiple times when
-- it is moved into a parameterized join
--
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            b.q1 AS bx,
            1 AS one
        FROM
            int4_tbl a
            LEFT JOIN int8_tbl b ON a.f1 = b.q2) t2 ON TRUE
    LEFT JOIN (LATERAL (
            SELECT
                c.f1 AS cnt
            FROM
                int4_tbl c
            WHERE
                c.f1 = t2.one OFFSET 0) t3
            JOIN int4_tbl t4 ON t3.cnt = t4.f1) ON t2.bx = t3.cnt + t4.f1;

SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN (
        SELECT
            b.q1 AS bx,
            1 AS one
        FROM
            int4_tbl a
            LEFT JOIN int8_tbl b ON a.f1 = b.q2) t2 ON TRUE
    LEFT JOIN (LATERAL (
            SELECT
                c.f1 AS cnt
            FROM
                int4_tbl c
            WHERE
                c.f1 = t2.one OFFSET 0) t3
            JOIN int4_tbl t4 ON t3.cnt = t4.f1) ON t2.bx = t3.cnt + t4.f1;

--
-- check that identical clone variants of an outer-join qual are not
-- enforced multiple times in a parameterized path
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1
    LEFT JOIN onek t2 ON t1.unique1 = t2.unique1
    LEFT JOIN onek t3 ON t2.unique1 = t3.unique1
    LEFT JOIN onek t4 ON t3.unique1 = t4.unique1
        AND t3.ten = t4.ten + 0
        AND t2.unique2 = t4.unique2 + 0
WHERE
    t1.unique1 < 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1
    LEFT JOIN onek t2 ON t1.unique1 = t2.unique1
    LEFT JOIN onek t3 ON t2.unique1 = t3.unique1
    LEFT JOIN (onek t4
        JOIN onek t5 ON t4.ten = t5.ten) ON t3.unique1 = t5.unique1
        AND t3.hundred = t4.unique1 + t5.two
        AND t2.unique2 = t4.unique2
WHERE
    t1.unique1 < 1;

--
-- check that an EC-derived condition is not enforced twice, both within a
-- parameterized path and at the join above it
--
BEGIN;
SET local from_collapse_limit TO 1;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1,
    LATERAL (
        SELECT
            *
        FROM
            tenk1 t2,
            LATERAL (
                SELECT
                    t2.ten AS x OFFSET 0) s0
                JOIN tenk1 t3 ON t3.unique2 = t1.f1
            WHERE
                t3.unique1 = t2.hundred + s0.x) ss1;
SELECT
    count(*)
FROM
    int4_tbl t1,
    LATERAL (
        SELECT
            *
        FROM
            tenk1 t2,
            LATERAL (
                SELECT
                    t2.ten AS x OFFSET 0) s0
                JOIN tenk1 t3 ON t3.unique2 = t1.f1
            WHERE
                t3.unique1 = t2.hundred + s0.x) ss1;
ROLLBACK;

--
-- test successful handling of full join underneath left join (bug #14105)
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS id) AS xx
    LEFT JOIN (tenk1 AS a1
        FULL JOIN (
            SELECT
                1 AS id) AS yy ON (a1.unique1 = yy.id)) ON (xx.id = coalesce(yy.id, yy.id));

SELECT
    *
FROM (
    SELECT
        1 AS id) AS xx
    LEFT JOIN (tenk1 AS a1
        FULL JOIN (
            SELECT
                1 AS id) AS yy ON (a1.unique1 = yy.id)) ON (xx.id = coalesce(yy.id, yy.id));

--
-- test ability to push constants through outer join clauses
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl a
    LEFT JOIN tenk1 b ON f1 = unique2
WHERE
    f1 = 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
    FULL JOIN tenk1 b USING (unique2)
WHERE
    unique2 = 42;

--
-- test that quals attached to an outer join have correct semantics,
-- specifically that they don't re-use expressions computed below the join;
-- we force a mergejoin so that coalesce(b.q1, 1) appears as a join input
--
SET enable_hashjoin TO OFF;

SET enable_nestloop TO OFF;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    a.q2,
    b.q1
FROM
    int8_tbl a
    LEFT JOIN int8_tbl b ON a.q2 = coalesce(b.q1, 1)
WHERE
    coalesce(b.q1, 1) > 0;

SELECT
    a.q2,
    b.q1
FROM
    int8_tbl a
    LEFT JOIN int8_tbl b ON a.q2 = coalesce(b.q1, 1)
WHERE
    coalesce(b.q1, 1) > 0;

RESET enable_hashjoin;

RESET enable_nestloop;

--
-- test join strength reduction with a SubPlan providing the proof
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    LEFT JOIN onek b ON a.unique1 = b.unique2
WHERE (b.unique2, random() > 0) = ANY (
    SELECT
        q1,
        random() > 0
    FROM
        int8_tbl c
    WHERE
        c.q1 < b.unique1);

SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    LEFT JOIN onek b ON a.unique1 = b.unique2
WHERE (b.unique2, random() > 0) = ANY (
    SELECT
        q1,
        random() > 0
    FROM
        int8_tbl c
    WHERE
        c.q1 < b.unique1);

--
-- test full-join strength reduction
--
EXPLAIN (
    COSTS OFF
)
SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    a.unique1 = 42;

SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    a.unique1 = 42;

EXPLAIN (
    COSTS OFF
)
SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    b.unique2 = 43;

SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    b.unique2 = 43;

EXPLAIN (
    COSTS OFF
)
SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    a.unique1 = 42
    AND b.unique2 = 42;

SELECT
    a.unique1,
    b.unique2
FROM
    onek a
    FULL JOIN onek b ON a.unique1 = b.unique2
WHERE
    a.unique1 = 42
    AND b.unique2 = 42;

--
-- test result-RTE removal underneath a full join
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        int8_tbl i81
        JOIN (
            VALUES (123, 2)) v (v1, v2) ON q2 = v1) ss1
    FULL JOIN (
        SELECT
            *
        FROM (
            VALUES (456, 2)) w (v1, v2)
            JOIN int8_tbl i82 ON q2 = v1) ss2 ON TRUE;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        int8_tbl i81
        JOIN (
            VALUES (123, 2)) v (v1, v2) ON q2 = v1) ss1
    FULL JOIN (
        SELECT
            *
        FROM (
            VALUES (456, 2)) w (v1, v2)
            JOIN int8_tbl i82 ON q2 = v1) ss2 ON TRUE;

--
-- test join removal
--
BEGIN;
CREATE TEMP TABLE a (
    id int PRIMARY KEY,
    b_id int
);
CREATE TEMP TABLE b (
    id int PRIMARY KEY,
    c_id int
);
CREATE TEMP TABLE c (
    id int PRIMARY KEY
);
CREATE TEMP TABLE d (
    a int,
    b int
);
CREATE TEMP TABLE e (
    id1 int,
    id2 int,
    PRIMARY KEY (id1, id2)
);
INSERT INTO a
VALUES
    (0, 0),
    (1, NULL);
INSERT INTO b
VALUES
    (0, 0),
    (1, NULL);
INSERT INTO c
VALUES
    (0),
    (1);
INSERT INTO d
VALUES
    (1, 3),
    (2, 2),
    (3, 1);
INSERT INTO e
VALUES
    (0, 0),
    (2, 2),
    (3, 1);
-- all these cases should be optimizable into a simple seqscan
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    a
    LEFT JOIN b ON a.b_id = b.id;
EXPLAIN (
    COSTS OFF
)
SELECT
    b.*
FROM
    b
    LEFT JOIN c ON b.c_id = c.id;
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    a
    LEFT JOIN (b
        LEFT JOIN c ON b.c_id = c.id) ON (a.b_id = b.id);
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    a
    LEFT JOIN b ON a.id = b.id
    LEFT JOIN e ON e.id1 = a.b_id
        AND b.c_id = e.id2;
-- check optimization of outer join within another special join
EXPLAIN (
    COSTS OFF
)
SELECT
    id
FROM
    a
WHERE
    id IN (
        SELECT
            b.id
        FROM
            b
        LEFT JOIN c ON b.id = c.id);
-- check optimization with oddly-nested outer joins
EXPLAIN (
    COSTS OFF
)
SELECT
    a1.id
FROM (a a1
    LEFT JOIN a a2 ON TRUE)
    LEFT JOIN (a a3
        LEFT JOIN a a4 ON a3.id = a4.id) ON a2.id = a3.id;
EXPLAIN (
    COSTS OFF
)
SELECT
    a1.id
FROM (a a1
    LEFT JOIN a a2 ON a1.id = a2.id)
    LEFT JOIN (a a3
        LEFT JOIN a a4 ON a3.id = a4.id) ON a2.id = a3.id;
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    a t1
    LEFT JOIN a t2 ON TRUE
    INNER JOIN a t3 ON TRUE
    LEFT JOIN a t4 ON t2.id = t4.id
        AND t2.id = t3.id;
-- another example (bug #17781)
EXPLAIN (
    COSTS OFF
)
SELECT
    ss1.f1
FROM
    int4_tbl AS t1
    LEFT JOIN (int4_tbl AS t2
        RIGHT JOIN int4_tbl AS t3 ON NULL
        LEFT JOIN (int4_tbl AS t4
            RIGHT JOIN int8_tbl AS t5 ON NULL) ON t2.f1 = t4.f1
        LEFT JOIN ((
                SELECT
                    NULL AS f1
                FROM
                    int4_tbl AS t6) AS ss1
                INNER JOIN int8_tbl AS t7 ON NULL) ON t5.q1 = t7.q2) ON FALSE;
-- variant with Var rather than PHV coming from t6
EXPLAIN (
    COSTS OFF
)
SELECT
    ss1.f1
FROM
    int4_tbl AS t1
    LEFT JOIN (int4_tbl AS t2
        RIGHT JOIN int4_tbl AS t3 ON NULL
        LEFT JOIN (int4_tbl AS t4
            RIGHT JOIN int8_tbl AS t5 ON NULL) ON t2.f1 = t4.f1
        LEFT JOIN ((
                SELECT
                    f1
                FROM
                    int4_tbl AS t6) AS ss1
                INNER JOIN int8_tbl AS t7 ON NULL) ON t5.q1 = t7.q2) ON FALSE;
-- per further discussion of bug #17781
EXPLAIN (
    COSTS OFF
)
SELECT
    ss1.x
FROM (
    SELECT
        f1 / 2 AS x
    FROM
        int4_tbl i4
        LEFT JOIN a ON a.id = i4.f1) ss1
    RIGHT JOIN int8_tbl i8 ON TRUE
WHERE
    CURRENT_USER IS NOT NULL;
-- this is to add a Result node
-- and further discussion of bug #17781
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN onek t3 ON t2.q1 > t3.unique1) ON t1.q2 = t2.q2
    LEFT JOIN onek t4 ON t2.q2 < t3.unique2;
-- bug #19460: we need to clean up RestrictInfos more than we had been doing
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1::int AS id) AS lhs
    FULL JOIN (
        SELECT
            dummy_source.id
        FROM (
            SELECT
                NULL::int AS id) AS dummy_source
            LEFT JOIN (
                SELECT
                    a.id
                FROM
                    a
                WHERE
                    a.id = 42) AS sub ON sub.id = dummy_source.id) AS rhs ON lhs.id = rhs.id;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1::int AS id) AS lhs
    FULL JOIN (
        SELECT
            dummy_source.id
        FROM (
            SELECT
                2::int AS id) AS dummy_source
            LEFT JOIN (
                SELECT
                    a.id
                FROM
                    a) AS sub ON sub.id = dummy_source.id) AS rhs ON lhs.id = rhs.id;
-- check handling of a removed Var that's pushed down into a subquery
-- (fallout from the fix for bug #19560)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    c1,
    c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        END AS c1
    FROM
        int4_tbl i41
        LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON FALSE,
    LATERAL (
        SELECT
            ss1.c1 AS c2
        FROM
            int4_tbl i43 OFFSET 0) ss2;
-- likewise, where the subquery is a UNION ALL whose arms are appendrel
-- children that are not simple enough to be pulled up
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    c1,
    c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        END AS c1
    FROM
        int4_tbl i41
        LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON FALSE,
    LATERAL ((
            SELECT
                ss1.c1 AS c2
            FROM
                int4_tbl i43 OFFSET 0)
    UNION ALL (
        SELECT
            ss1.c1
        FROM
            int4_tbl i44 OFFSET 0)) ss2;
-- likewise, where the PHV contains a SubPlan and the subquery has a join, so
-- that its planner runs flatten_join_alias_vars over the outer-level PHV
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    c1,
    c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        ELSE
            (
                SELECT
                    i41.f1)
        END AS c1
    FROM
        int4_tbl i41
        LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON FALSE,
    LATERAL (
        SELECT
            ss1.c1 AS c2
        FROM
            int4_tbl i43
            JOIN int4_tbl i44 ON TRUE OFFSET 0) ss2;
-- likewise, where the PHV copy is pushed into a SubLink's subselect rather
-- than a LATERAL subquery
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (
        SELECT
            ss1.c1
        FROM
            int4_tbl i43 OFFSET 0) AS c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        END AS c1
    FROM
        int4_tbl i41
    LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON TRUE;
-- likewise, where the pushed-down PHV's expression itself contains a SubLink,
-- so it must be preprocessed once at the outer level rather than again while
-- building the SubPlan that references it
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (
        SELECT
            ss1.c1
        FROM
            int4_tbl i43 OFFSET 0) AS c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        ELSE
            (
                SELECT
                    i41.f1)
        END AS c1
    FROM
        int4_tbl i41
    LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON TRUE;
-- likewise, where the pushed-down PHV sits within an outer-level aggregate
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (
        SELECT
            sum(ss1.c1)
        FROM
            int4_tbl i43) AS c2
FROM (
    SELECT
        (
            SELECT
                i41.f1) AS c1
        FROM
            int4_tbl i41) ss1
    RIGHT JOIN int4_tbl i42 ON TRUE;
-- likewise, where the pushed-down PHV's expression contains another PHV of
-- the same level, which must not be preprocessed separately from its parent
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss3.c2
FROM
    int4_tbl i41
    LEFT JOIN (
        SELECT
            coalesce(ss1.c1, 0) AS c1
        FROM
            int4_tbl i42
            LEFT JOIN (
                SELECT
                    (
                        SELECT
                            i43.f1) AS c1
                    FROM
                        int4_tbl i43) ss1 ON TRUE) ss2 ON TRUE,
    LATERAL (
        SELECT
            ss2.c1 AS c2
        FROM
            int4_tbl i44 OFFSET 0) ss3;
-- likewise, where the PHV copy is only inserted into the LATERAL subquery by
-- expanding a join alias Var of the outer level
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss2.c2
FROM ((
        SELECT
            (
                SELECT
                    i41.f1) AS c1
            FROM
                int4_tbl i41) ss1
        FULL JOIN int4_tbl i42 (c1)
        USING (c1)) j,
    LATERAL (
        SELECT
            j.c1 AS c2
        FROM
            int4_tbl i43 OFFSET 0) ss2;
-- likewise, where the join alias is expanded within a SubLink's subselect
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (
        SELECT
            j.c1
        FROM
            int4_tbl i43 OFFSET 0) AS c2
FROM ((
        SELECT
            (
                SELECT
                    i41.f1) AS c1
            FROM
                int4_tbl i41) ss1
            FULL JOIN int4_tbl i42 (c1)
            USING (c1)) j;
-- likewise, where the SubLink holding the copy ends up in the translated
-- Vars of an appendrel child pulled up from a LATERAL UNION ALL subquery
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss2.c2
FROM (
    SELECT
        CASE WHEN FALSE THEN
            remov.id
        END AS c1
    FROM
        int4_tbl i41
        LEFT JOIN a remov ON i41.f1 = remov.id) ss1
    RIGHT JOIN int4_tbl i42 ON TRUE,
    LATERAL ((
            SELECT
                (
                    SELECT
                        ss1.c1) AS c2)
        UNION ALL (
            SELECT
                (
                    SELECT
                        ss1.c1))) ss2;
-- More tests of correct placement of pseudoconstant quals
-- simple constant-false condition
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN int8_tbl t3 ON FALSE
        LEFT JOIN int8_tbl t4 ON t2.q2 = t4.q2) ON t1.q1 = t2.q1;
-- deduce constant-false from an EquivalenceClass
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN int8_tbl t3 ON (t2.q1 - t3.q2) = 0
            AND (t2.q1 - t3.q2) = 1
    LEFT JOIN int8_tbl t4 ON t2.q2 = t4.q2) ON t1.q1 = t2.q1;
-- pseudoconstant based on an outer-level Param
EXPLAIN (
    COSTS OFF
)
SELECT
    EXISTS (
        SELECT
            *
        FROM
            int8_tbl t1
        LEFT JOIN (int8_tbl t2
            INNER JOIN int8_tbl t3 ON x0.f1 = 1
            LEFT JOIN int8_tbl t4 ON t2.q2 = t4.q2) ON t1.q1 = t2.q1)
FROM
    int4_tbl x0;
-- check that join removal works for a left join when joining a subquery
-- that is guaranteed to be unique by its GROUP BY clause
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            *
        FROM
            b
        GROUP BY
            b.id,
            b.c_id) s ON d.a = s.id
    AND d.b = s.c_id;
-- check that join removal works for a left join when joining a subquery
-- that is guaranteed to be unique by GROUPING SETS
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            ()) s ON d.a = s.x;
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            GROUPING SETS (())) s ON d.a = s.x;
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            GROUPING SETS (()),
        GROUPING SETS (())) s ON d.a = s.x;
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            DISTINCT GROUPING SETS ((),
            ())) s ON d.a = s.x;
-- similarly, but keying off a DISTINCT clause
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN ( SELECT DISTINCT
            *
        FROM
            b) s ON d.a = s.id
        AND d.b = s.c_id;
-- join removal is not possible when the GROUP BY contains a column that is
-- not in the join condition.  (Note: as of 9.6, we notice that b.id is a
-- primary key and so drop b.c_id from the GROUP BY of the resulting plan;
-- but this happens too late for join removal in the outer plan level.)
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            *
        FROM
            b
        GROUP BY
            b.id,
            b.c_id) s ON d.a = s.id;
-- join removal is not possible when the GROUP BY contains non-empty grouping
-- sets or multiple empty grouping sets
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            ROLLUP (x)) s ON d.a = s.x;
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            GROUPING SETS ((),
            ())) s ON d.a = s.x;
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            1 AS x
        FROM
            b
        GROUP BY
            GROUPING SETS ((),
            GROUPING SETS (()))) s ON d.a = s.x;
-- similarly, but keying off a DISTINCT clause
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN ( SELECT DISTINCT
            *
        FROM
            b) s ON d.a = s.id;
-- join removal is not possible when the subquery has DISTINCT ON and a
-- set-returning function that is not a DISTINCT ON column
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN ( SELECT DISTINCT ON (id)
            id,
            generate_series(1, 2) AS g
        FROM
            b
        ORDER BY
            id) s ON d.a = s.id
ORDER BY
    1,
    2;
SELECT
    d.*
FROM
    d
    LEFT JOIN ( SELECT DISTINCT ON (id)
            id,
            generate_series(1, 2) AS g
        FROM
            b
        ORDER BY
            id) s ON d.a = s.id
ORDER BY
    1,
    2;
-- join removal is not possible here
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    a t1
    LEFT JOIN (a t2
        LEFT JOIN a t3 ON t2.id = 1) ON t2.id = 1;
-- check join removal works when uniqueness of the join condition is enforced
-- by a UNION
EXPLAIN (
    COSTS OFF
)
SELECT
    d.*
FROM
    d
    LEFT JOIN (
        SELECT
            id
        FROM
            a
    UNION
    SELECT
        id
    FROM
        b) s ON d.a = s.id;
-- check join removal with a cross-type comparison operator
EXPLAIN (
    COSTS OFF
)
SELECT
    i8.*
FROM
    int8_tbl i8
    LEFT JOIN (
        SELECT
            f1
        FROM
            int4_tbl
        GROUP BY
            f1) i4 ON i8.q1 = i4.f1;
-- check join removal with lateral references
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        a.id
    FROM
        a
        LEFT JOIN b ON a.b_id = b.id) q,
    LATERAL generate_series(1, q.id) gs (i)
WHERE
    q.id = gs.i;
-- check join removal within RHS of an outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    c.id,
    ss.a
FROM
    c
    LEFT JOIN (
        SELECT
            d.a
        FROM
            onerow,
            d
            LEFT JOIN b ON d.a = b.id) ss ON c.id = ss.a;
-- check join removal when Vars reference the removed join via its alias
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    j.b_id,
    (
        SELECT
            j.b_id)
FROM (a
    LEFT JOIN b ON a.b_id = b.id) j;
-- check the case when the placeholder relates to an outer join and its
-- inner in the press field but actually uses only the outer side of the join
EXPLAIN (
    COSTS OFF
)
SELECT
    q.val
FROM
    b
    LEFT JOIN (
        SELECT
            (q1.z IS NOT NULL) AS val
        FROM
            b
            LEFT JOIN (
                SELECT
                    (t1.b_id IS NOT NULL) AS z
                FROM
                    a t1
                    LEFT JOIN a t2 USING (id)) AS q1 ON TRUE) AS q ON TRUE;
CREATE TEMP TABLE parted_b (
    id int PRIMARY KEY
)
PARTITION BY RANGE (id);
CREATE TEMP TABLE parted_b1 PARTITION OF parted_b
FOR VALUES FROM (0) TO (10);
-- test join removals on a partitioned table
EXPLAIN (
    COSTS OFF
)
SELECT
    a.*
FROM
    a
    LEFT JOIN parted_b pb ON a.b_id = pb.id;
-- test that clauses that still embed PHVs are not referencing the removed
-- relation when rebuilt for a partition of the kept relation
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        t1.id
    FROM
        parted_b t1
        LEFT JOIN parted_b t2 ON t1.id = t2.id) s
WHERE
    s.id = 1
GROUP BY
    ();
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    parted_b t1
    JOIN (
        SELECT
            t2.id
        FROM
            parted_b t2
            LEFT JOIN parted_b t3 ON t2.id = t3.id) s ON t1.id = s.id
GROUP BY
    ();
-- likewise for a PHV embedded in an OR join clause
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    parted_b t1
    JOIN (
        SELECT
            t2.id
        FROM
            parted_b t2
            LEFT JOIN parted_b t3 ON t2.id = t3.id) s ON (t1.id = 1
            AND s.id = 2)
        OR (t1.id = 3
            AND s.id = 4)
GROUP BY
    ();
ROLLBACK;

CREATE temp TABLE parent (
    k int PRIMARY KEY,
    pd int
);

CREATE temp TABLE child (
    k int UNIQUE,
    cd int
);

INSERT INTO parent
VALUES
    (1, 10),
    (2, 20),
    (3, 30);

INSERT INTO child
VALUES
    (1, 100),
    (4, 400);

-- this case is optimizable
SELECT
    p.*
FROM
    parent p
    LEFT JOIN child c ON (p.k = c.k);

EXPLAIN (
    COSTS OFF
)
SELECT
    p.*
FROM
    parent p
    LEFT JOIN child c ON (p.k = c.k);

-- this case is not
SELECT
    p.*,
    linked
FROM
    parent p
    LEFT JOIN (
        SELECT
            c.*,
            TRUE AS linked
        FROM
            child c) AS ss ON (p.k = ss.k);

EXPLAIN (
    COSTS OFF
)
SELECT
    p.*,
    linked
FROM
    parent p
    LEFT JOIN (
        SELECT
            c.*,
            TRUE AS linked
        FROM
            child c) AS ss ON (p.k = ss.k);

-- check for a 9.0rc1 bug: join removal breaks pseudoconstant qual handling
SELECT
    p.*
FROM
    parent p
    LEFT JOIN child c ON (p.k = c.k)
WHERE
    p.k = 1
    AND p.k = 2;

EXPLAIN (
    COSTS OFF
)
SELECT
    p.*
FROM
    parent p
    LEFT JOIN child c ON (p.k = c.k)
WHERE
    p.k = 1
    AND p.k = 2;

SELECT
    p.*
FROM (parent p
    LEFT JOIN child c ON (p.k = c.k))
JOIN parent x ON p.k = x.k
WHERE
    p.k = 1
    AND p.k = 2;

EXPLAIN (
    COSTS OFF
)
SELECT
    p.*
FROM (parent p
    LEFT JOIN child c ON (p.k = c.k))
JOIN parent x ON p.k = x.k
WHERE
    p.k = 1
    AND p.k = 2;

-- Ensure multiple gating quals are evaluated correctly
SELECT
    *
FROM (
    SELECT
        c0
    FROM (
        SELECT
            NULL::int AS c0
        FROM ((
                SELECT
                    1)
            UNION ALL (
                SELECT
                    2))) t1
    FULL JOIN (
        SELECT
            1) t2 ON TRUE
    WHERE
        c0 IS NOT NULL) t3
WHERE
    now() IS NOT NULL;

-- bug 5255: this is not optimizable by join removal
BEGIN;
CREATE TEMP TABLE a (
    id int PRIMARY KEY
);
CREATE TEMP TABLE b (
    id int PRIMARY KEY,
    a_id int
);
INSERT INTO a
VALUES
    (0),
    (1);
INSERT INTO b
VALUES
    (0, 0),
    (1, NULL);
SELECT
    *
FROM
    b
    LEFT JOIN a ON (b.a_id = a.id)
WHERE (a.id IS NULL
    OR a.id > 0);
SELECT
    b.*
FROM
    b
    LEFT JOIN a ON (b.a_id = a.id)
WHERE (a.id IS NULL
    OR a.id > 0);
ROLLBACK;

-- another join removal bug: this is not optimizable, either
BEGIN;
CREATE temp TABLE innertab (
    id int8 PRIMARY KEY,
    dat1 int8
);
INSERT INTO innertab
    VALUES (123, 42);
SELECT
    *
FROM (
    SELECT
        1 AS x) ss1
    LEFT JOIN (
        SELECT
            q1,
            q2,
            COALESCE(dat1, q1) AS y
        FROM
            int8_tbl
            LEFT JOIN innertab ON q2 = id) ss2 ON TRUE;
-- join removal bug #17769: can't remove if there's a pushed-down reference
EXPLAIN (
    COSTS OFF
)
SELECT
    q2
FROM (
    SELECT
        *
    FROM
        int8_tbl
        LEFT JOIN innertab ON q2 = id) ss
WHERE
    COALESCE(dat1, 0) = q1;
-- join removal bug #17773: otherwise-removable PHV appears in a qual condition
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    q2
FROM (
    SELECT
        q2,
        'constant'::text AS x
    FROM
        int8_tbl
        LEFT JOIN innertab ON q2 = id) ss
    RIGHT JOIN int4_tbl ON NULL
WHERE
    x >= x;
-- join removal bug #17786: check that OR conditions are cleaned up
EXPLAIN (
    COSTS OFF
)
SELECT
    f1,
    x
FROM
    int4_tbl
    JOIN ((
            SELECT
                42 AS x
            FROM
                int8_tbl
                LEFT JOIN innertab ON q1 = id) AS ss1
            RIGHT JOIN tenk1 ON NULL) ON tenk1.unique1 = ss1.x
        OR tenk1.unique2 = ss1.x;
ROLLBACK;

-- another join removal bug: we must clean up correctly when removing a PHV
BEGIN;
CREATE temp TABLE uniquetbl (
    f1 text UNIQUE
);
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.*
FROM
    uniquetbl AS t1
    LEFT JOIN (
        SELECT
            *,
            '***'::text AS d1
        FROM
            uniquetbl) t2 ON t1.f1 = t2.f1
    LEFT JOIN uniquetbl t3 ON t2.d1 = t3.f1;
EXPLAIN (
    COSTS OFF
)
SELECT
    t0.*
FROM
    text_tbl t0
    LEFT JOIN (
        SELECT
            CASE t1.ten
            WHEN 0 THEN
                'doh!'::text
            ELSE
                NULL::text
            END AS case1,
            t1.stringu2
        FROM
            tenk1 t1
            JOIN int4_tbl i4 ON i4.f1 = t1.unique2
            LEFT JOIN uniquetbl u1 ON u1.f1 = t1.string4) ss ON t0.f1 = ss.case1
WHERE
    ss.stringu2 !~* ss.case1;
SELECT
    t0.*
FROM
    text_tbl t0
    LEFT JOIN (
        SELECT
            CASE t1.ten
            WHEN 0 THEN
                'doh!'::text
            ELSE
                NULL::text
            END AS case1,
            t1.stringu2
        FROM
            tenk1 t1
            JOIN int4_tbl i4 ON i4.f1 = t1.unique2
            LEFT JOIN uniquetbl u1 ON u1.f1 = t1.string4) ss ON t0.f1 = ss.case1
WHERE
    ss.stringu2 !~* ss.case1;
ROLLBACK;

-- another join removal bug: we must clean up EquivalenceClasses too
BEGIN;
CREATE temp TABLE t (
    a int UNIQUE
);
INSERT INTO t
    VALUES (1);
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    t t1
    LEFT JOIN (
        SELECT
            2 AS c
        FROM
            t t2
            LEFT JOIN t t3 ON t2.a = t3.a) s ON TRUE
WHERE
    t1.a = s.c;
SELECT
    1
FROM
    t t1
    LEFT JOIN (
        SELECT
            2 AS c
        FROM
            t t2
            LEFT JOIN t t3 ON t2.a = t3.a) s ON TRUE
WHERE
    t1.a = s.c;
ROLLBACK;

-- join removal bug #19560: removing a join can leave an EquivalenceClass that
-- now yields a base restriction clause, so we must redo equivalence
-- processing from scratch
BEGIN;
CREATE temp TABLE items (
    id text,
    owner text
);
CREATE temp TABLE follows (
    item_id text,
    user_id text,
    UNIQUE (user_id, item_id)
);
INSERT INTO items
    VALUES ('item1', 'alice');
EXPLAIN (
    COSTS OFF
) WITH viewer AS (
    SELECT
        'bob' AS id
)
SELECT
    count(*)
FROM
    items
    LEFT JOIN follows ON follows.item_id = items.id
        AND follows.user_id = 'bob'
    LEFT JOIN viewer ON TRUE
WHERE
    items.owner = viewer.id;
WITH viewer AS (
    SELECT
        'bob' AS id
)
SELECT
    count(*)
FROM
    items
    LEFT JOIN follows ON follows.item_id = items.id
        AND follows.user_id = 'bob'
    LEFT JOIN viewer ON TRUE
WHERE
    items.owner = viewer.id;
ROLLBACK;

-- check handling of semijoins after join removal: we must suppress
-- unique-ification of known-constant values
BEGIN;
CREATE temp TABLE t (
    a int UNIQUE,
    b int
);
INSERT INTO t
    VALUES (1, 2);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.a
FROM
    t t1
    LEFT JOIN t t2 ON t1.a = t2.a
    JOIN t t3 ON TRUE
WHERE
    EXISTS (
        SELECT
            1
        FROM
            t t4
            JOIN t t5 ON t4.b = t5.b
            JOIN t t6 ON t5.b = t6.b
        WHERE
            t1.a = t4.a
            AND t3.a = t5.a
            AND t4.a = 1);
SELECT
    t1.a
FROM
    t t1
    LEFT JOIN t t2 ON t1.a = t2.a
    JOIN t t3 ON TRUE
WHERE
    EXISTS (
        SELECT
            1
        FROM
            t t4
            JOIN t t5 ON t4.b = t5.b
            JOIN t t6 ON t5.b = t6.b
        WHERE
            t1.a = t4.a
            AND t3.a = t5.a
            AND t4.a = 1);
ROLLBACK;

-- check handling of semijoins if all RHS columns are equated to constants: we
-- should suppress unique-ification in this case.
BEGIN;
CREATE temp TABLE t (
    a int,
    b int
);
INSERT INTO t
    VALUES (1, 2);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t t1,
    t t2
WHERE
    EXISTS (
        SELECT
            1
        FROM
            t t3
        WHERE
            t1.a = t3.a
            AND t2.b = t3.b
            AND t3.a = 1
            AND t3.b = 2);
SELECT
    *
FROM
    t t1,
    t t2
WHERE
    EXISTS (
        SELECT
            1
        FROM
            t t3
        WHERE
            t1.a = t3.a
            AND t2.b = t3.b
            AND t3.a = 1
            AND t3.b = 2);
ROLLBACK;

-- check handling of semijoin unique-ification for child relations if all RHS
-- columns are equated to constants.
BEGIN;
CREATE temp TABLE p (
    a int,
    b int
)
PARTITION BY RANGE (a);
CREATE temp TABLE p1 PARTITION OF p
FOR VALUES FROM (0) TO (10);
CREATE temp TABLE p2 PARTITION OF p
FOR VALUES FROM (10) TO (20);
INSERT INTO p
    VALUES (1, 2);
INSERT INTO p
    VALUES (10, 20);
SET enable_partitionwise_join TO ON;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    p t1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            p t2
        WHERE
            t1.a = t2.a
            AND t1.a = 1);
SELECT
    *
FROM
    p t1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            p t2
        WHERE
            t1.a = t2.a
            AND t1.a = 1);
ROLLBACK;

-- test cases where we can remove a join, but not a PHV computed at it
BEGIN;
CREATE temp TABLE t (
    a int UNIQUE,
    b int
);
INSERT INTO t
VALUES
    (1, 1),
    (2, 2);
EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    t t1
    LEFT JOIN (
        SELECT
            t2.a,
            1 AS c
        FROM
            t t2
            LEFT JOIN t t3 ON t2.a = t3.a) s ON TRUE
    LEFT JOIN t t4 ON TRUE
WHERE
    s.a < s.c;
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.a,
    s.*
FROM
    t t1
    LEFT JOIN LATERAL (
        SELECT
            t2.a,
            coalesce(t1.a, 1) AS c
        FROM
            t t2
            LEFT JOIN t t3 ON t2.a = t3.a) s ON TRUE
    LEFT JOIN t t4 ON TRUE
WHERE
    s.a < s.c;
SELECT
    t1.a,
    s.*
FROM
    t t1
    LEFT JOIN LATERAL (
        SELECT
            t2.a,
            coalesce(t1.a, 1) AS c
        FROM
            t t2
            LEFT JOIN t t3 ON t2.a = t3.a) s ON TRUE
    LEFT JOIN t t4 ON TRUE
WHERE
    s.a < s.c;
ROLLBACK;

-- test case to expose miscomputation of required relid set for a PHV
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    i8.*,
    ss.v,
    t.unique2
FROM
    int8_tbl i8
    LEFT JOIN int4_tbl i4 ON i4.f1 = 1
    LEFT JOIN LATERAL (
        SELECT
            i4.f1 + 1 AS v) AS ss ON TRUE
    LEFT JOIN tenk1 t ON t.unique2 = ss.v
WHERE
    q2 = 456;

SELECT
    i8.*,
    ss.v,
    t.unique2
FROM
    int8_tbl i8
    LEFT JOIN int4_tbl i4 ON i4.f1 = 1
    LEFT JOIN LATERAL (
        SELECT
            i4.f1 + 1 AS v) AS ss ON TRUE
    LEFT JOIN tenk1 t ON t.unique2 = ss.v
WHERE
    q2 = 456;

-- and check a related issue where we miscompute required relids for
-- a PHV that's been translated to a child rel
CREATE temp TABLE parttbl (
    a integer PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE temp TABLE parttbl1 PARTITION OF parttbl
FOR VALUES FROM (1) TO (100);

INSERT INTO parttbl
VALUES
    (11),
    (12);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *,
        12 AS phv
    FROM
        parttbl) AS ss
    RIGHT JOIN int4_tbl ON TRUE
WHERE
    ss.a = ss.phv
    AND f1 = 0;

SELECT
    *
FROM (
    SELECT
        *,
        12 AS phv
    FROM
        parttbl) AS ss
    RIGHT JOIN int4_tbl ON TRUE
WHERE
    ss.a = ss.phv
    AND f1 = 0;

-- bug #8444: we've historically allowed duplicate aliases within aliased JOINs
SELECT
    *
FROM
    int8_tbl x
    JOIN (int4_tbl x
        CROSS JOIN int4_tbl y) j ON q1 = f1;

-- error
SELECT
    *
FROM
    int8_tbl x
    JOIN (int4_tbl x
        CROSS JOIN int4_tbl y) j ON q1 = y.f1;

-- error
SELECT
    *
FROM
    int8_tbl x
    JOIN (int4_tbl x
        CROSS JOIN int4_tbl y (ff)) j ON q1 = f1;

-- ok
--
-- test that semi- or inner self-joins on a unique column are removed
--
-- enable only nestloop to get more predictable plans
SET enable_hashjoin TO OFF;

SET enable_mergejoin TO OFF;

CREATE TABLE sj (
    a int UNIQUE,
    b int,
    c int UNIQUE
);

INSERT INTO sj
VALUES
    (1, NULL, 2),
    (NULL, 2, NULL),
    (2, 1, 1);

ANALYZE sj;

-- Trivial self-join case.
EXPLAIN (
    COSTS OFF
)
SELECT
    p.*
FROM
    sj p,
    sj q
WHERE
    q.a = p.a
    AND q.b = q.a - 1;

SELECT
    p.*
FROM
    sj p,
    sj q
WHERE
    q.a = p.a
    AND q.b = q.a - 1;

-- Self-join removal performs after a subquery pull-up process and could remove
-- such kind of self-join too. Check this option.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj p
WHERE
    EXISTS (
        SELECT
            *
        FROM
            sj q
        WHERE
            q.a = p.a
            AND q.b < 10);

SELECT
    *
FROM
    sj p
WHERE
    EXISTS (
        SELECT
            *
        FROM
            sj q
        WHERE
            q.a = p.a
            AND q.b < 10);

-- Don't remove self-join for the case of equality of two different unique columns.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1,
    sj t2
WHERE
    t1.a = t2.c
    AND t1.b IS NOT NULL;

-- Ensure that relations with TABLESAMPLE clauses are not considered as
-- candidates to be removed
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1
    JOIN LATERAL (
        SELECT
            *
        FROM
            sj TABLESAMPLE SYSTEM (t1.b)) s ON t1.a = s.a;

-- Ensure that SJE does not form a self-referential lateral dependency
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1
    LEFT JOIN LATERAL (
        SELECT
            t1.a AS t1a,
            *
        FROM
            sj t2) s ON TRUE
WHERE
    t1.a = s.a;

-- Degenerated case.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a AS x
    FROM
        sj
    WHERE
        FALSE) AS q1,
    (
        SELECT
            a AS y
        FROM
            sj
        WHERE
            FALSE) AS q2
WHERE
    q1.x = q2.y;

-- We can't use a cross-EC generated self join qual because of current logic of
-- the generate_join_implied_equalities routine.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1,
    sj t2
WHERE
    t1.a = t1.b
    AND t1.b = t2.b
    AND t2.b = t2.a;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1,
    sj t2,
    sj t3
WHERE
    t1.a = t1.b
    AND t1.b = t2.b
    AND t2.b = t2.a
    AND t1.b = t3.b
    AND t3.b = t3.a;

-- Double self-join removal.
-- Use a condition on "b + 1", not on "b", for the second join, so that
-- the equivalence class is different from the first one, and we can
-- test the non-ec code path.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj t1
    JOIN sj t2 ON t1.a = t2.a
        AND t1.b = t2.b
    JOIN sj t3 ON t2.a = t3.a
        AND t2.b + 1 = t3.b + 1;

-- subselect that references the removed relation
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.a,
    (
        SELECT
            a
        FROM
            sj
        WHERE
            a = t2.a
            AND a = t1.a)
FROM
    sj t1,
    sj t2
WHERE
    t1.a = t2.a;

-- self-join under outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj x
    JOIN sj y ON x.a = y.a
    LEFT JOIN int8_tbl z ON x.a = z.q1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj x
    JOIN sj y ON x.a = y.a
    LEFT JOIN int8_tbl z ON y.a = z.q1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        t1.*,
        t2.a AS ax
    FROM
        sj t1
        JOIN sj t2 ON (t1.a = t2.a
                AND t1.c * t1.c = t2.c + 2
                AND t2.b IS NULL)) AS q1
    LEFT JOIN (
        SELECT
            t3.*
        FROM
            sj t3,
            sj t4
        WHERE
            t3.c = t4.c) AS q2 ON q1.ax = q2.a;

-- Test that placeholders are updated correctly after join removal
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (1)) x
    LEFT JOIN (
        SELECT
            coalesce(y.q1, 1)
        FROM
            int8_tbl y
            RIGHT JOIN sj j1
            INNER JOIN sj j2 ON j1.a = j2.a ON TRUE) z ON TRUE;

-- Test that references to the removed rel in lateral subqueries are replaced
-- correctly after join removal
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t3.a
FROM
    sj t1
    JOIN sj t2 ON t1.a = t2.a
    JOIN LATERAL (
        SELECT
            t1.a OFFSET 0) t3 ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t3.a
FROM
    sj t1
    JOIN sj t2 ON t1.a = t2.a
    JOIN LATERAL (
        SELECT
            *
        FROM (
            SELECT
                t1.a OFFSET 0)
            OFFSET 0) t3 ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t4.a
FROM
    sj t1
    JOIN sj t2 ON t1.a = t2.a
    JOIN LATERAL (
        SELECT
            t3.a
        FROM
            sj t3,
            (
                SELECT
                    t1.a)
                OFFSET 0) t4 ON TRUE;

-- Check updating of semi_rhs_exprs links from upper-level semi join to
-- the removing relation
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.a
FROM
    sj t1
WHERE
    t1.b IN (
        SELECT
            t2.b
        FROM
            sj t2
            JOIN sj t3 ON t2.c = t3.c);

-- Check that quals get hoisted to the appropriate join level after SJE removal
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    a2.a
FROM
    sj b1
    JOIN sj a1 ON b1.b = a1.a
    JOIN sj a2 ON a2.a = a1.a
        AND a2.b = a1.b;

-- Same, when a semijoin removal happens first
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    a1.a
FROM
    sj b1
    JOIN sj a1 ON a1.a = b1.b
WHERE
    EXISTS (
        SELECT
            1
        FROM
            sj s
        WHERE
            s.a = a1.a);

-- A different case, where modified qual is on a lower join level
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    a2.a
FROM ((sj b1
        JOIN sj a1 ON TRUE)
    JOIN sj c1 ON c1.b = a1.a)
JOIN sj a2 ON a2.a = a1.a
    AND a2.b = a1.b;

--
-- SJE corner case: uniqueness of an inner is [partially] derived from
-- baserestrictinfo clauses.
-- XXX: We really should allow SJE for these corner cases?
--
INSERT INTO sj
    VALUES (3, 1, 3);

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2
    AND j2.a = 3;

-- Return one row
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2
    AND j2.a = 3;

-- Remove SJ, define uniqueness by a constant
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2
    AND j2.a = 2;

-- Return one row
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2
    AND j2.a = 2;

-- Remove SJ, define uniqueness by a constant expression
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int
    AND (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int = j2.a;

-- Return one row
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int
    AND (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int = j2.a;

-- Remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 1
    AND j2.a = 1;

-- Return no rows
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 1
    AND j2.a = 1;

-- Shuffle a clause. Remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND 1 = j1.a
    AND j2.a = 1;

-- Return no rows
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND 1 = j1.a
    AND j2.a = 1;

-- SJE Corner case: a 'a.x=a.x' clause, have replaced with 'a.x IS NOT NULL'
-- after SJ elimination it shouldn't be a mergejoinable clause.
EXPLAIN (
    COSTS OFF
)
SELECT
    t4.*
FROM (
    SELECT
        t1.*,
        t2.a AS a1
    FROM
        sj t1,
        sj t2
    WHERE
        t1.b = t2.b) AS t3
    JOIN sj t4 ON (t4.a = t3.a)
WHERE
    t3.a1 = 42;

SELECT
    t4.*
FROM (
    SELECT
        t1.*,
        t2.a AS a1
    FROM
        sj t1,
        sj t2
    WHERE
        t1.b = t2.b) AS t3
    JOIN sj t4 ON (t4.a = t3.a)
WHERE
    t3.a1 = 42;

-- Functional index
CREATE UNIQUE INDEX sj_fn_idx ON sj ((a * a));

-- Remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a * j1.a = 1
    AND j2.a * j2.a = 1;

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a * j1.a = 1
    AND j2.a * j2.a = 2;

-- Restriction contains expressions in both sides, Remove SJ.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND (j1.a * j1.a) = (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int
    AND (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int = (j2.a * j2.a);

-- Empty set of rows should be returned
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND (j1.a * j1.a) = (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int
    AND (EXTRACT(DOW FROM current_timestamp(0)) / 15 + 3)::int = (j2.a * j2.a);

-- Restriction contains volatile function - disable SJE feature.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND (j1.a * j1.c / 3) = (random() / 3 + 3)::int
    AND (random() / 3 + 3)::int = (j2.a * j2.c / 3);

-- Return one row
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND (j1.a * j1.c / 3) = (random() / 3 + 3)::int
    AND (random() / 3 + 3)::int = (j2.a * j2.c / 3);

-- Multiple filters
CREATE UNIQUE INDEX sj_temp_idx1 ON sj (a, b, c);

-- Remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2
    AND j1.c = 3
    AND j2.a = 2
    AND 3 = j2.c;

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND 2 = j1.a
    AND j1.c = 3
    AND j2.a = 1
    AND 3 = j2.c;

CREATE UNIQUE INDEX sj_temp_idx ON sj (a, b);

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND j1.a = 2;

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND 2 = j2.a;

-- Don't remove SJ
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj j1,
    sj j2
WHERE
    j1.b = j2.b
    AND (j1.a = 1
        OR j2.a = 1);

DROP INDEX sj_fn_idx, sj_temp_idx1, sj_temp_idx;

-- Test that OR predicated are updated correctly after join removal
CREATE TABLE tab_with_flag (
    id int PRIMARY KEY,
    is_flag smallint
);

CREATE INDEX idx_test_is_flag ON tab_with_flag (is_flag);

EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*)
FROM
    tab_with_flag
WHERE (is_flag IS NULL
    OR is_flag = 0)
AND id IN (
    SELECT
        id
    FROM
        tab_with_flag
    WHERE
        id IN (2, 3));

DROP TABLE tab_with_flag;

-- HAVING clause
EXPLAIN (
    COSTS OFF
)
SELECT
    p.b
FROM
    sj p
    JOIN sj q ON p.a = q.a
GROUP BY
    p.b
HAVING
    sum(p.a) = 1;

-- update lateral references and range table entry reference
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        x.*
    FROM
        sj x,
        sj y
    WHERE
        x.a = y.a) q,
    LATERAL generate_series(1, q.a) gs (i);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        y.*
    FROM
        sj x,
        sj y
    WHERE
        x.a = y.a) q,
    LATERAL generate_series(1, q.a) gs (i);

-- Test that a non-EC-derived join clause is processed correctly. Use an
-- outer join so that we can't form an EC.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj p
    JOIN sj q ON p.a = q.a
    LEFT JOIN sj r ON p.a + q.a = r.a;

-- Check that we detect constant-false condition after merging ECs.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj p,
    sj q
WHERE
    p.a = q.a
    AND p.b = 1
    AND q.b = 2;

-- Check that attr_needed is updated correctly after self-join removal. In this
-- test, the join of j1 with j2 is removed. k1.b is required at either j1 or j2.
-- If this info is lost, join targetlist for (k1, k2) will not contain k1.b.
-- Use index scan for k1 so that we don't get 'b' from physical tlist used for
-- seqscan. Also disable reordering of joins because this test depends on a
-- particular join tree.
CREATE TABLE sk (
    a int,
    b int
);

CREATE INDEX ON sk (a);

SET join_collapse_limit TO 1;

SET enable_seqscan TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (sk k1
    JOIN sk k2 ON k1.a = k2.a)
JOIN (sj j1
    JOIN sj j2 ON j1.a = j2.a) ON j1.b = k1.b;

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM (sk k1
    JOIN sk k2 ON k1.a = k2.a)
JOIN (sj j1
    JOIN sj j2 ON j1.a = j2.a) ON j2.b = k1.b;

RESET join_collapse_limit;

RESET enable_seqscan;

-- Check that clauses from the join filter list is not lost on the self-join removal
CREATE TABLE emp1 (
    id serial PRIMARY KEY NOT NULL,
    code int
);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    emp1 e1,
    emp1 e2
WHERE
    e1.id = e2.id
    AND e2.code <> e1.code;

-- Shuffle self-joined relations. Only in the case of iterative deletion
-- attempts explains of these queries will be identical.
CREATE UNIQUE INDEX ON emp1 ((id * id));

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    emp1 c1,
    emp1 c2,
    emp1 c3
WHERE
    c1.id = c2.id
    AND c1.id * c2.id = c3.id * c3.id;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    emp1 c1,
    emp1 c2,
    emp1 c3
WHERE
    c1.id = c3.id
    AND c1.id * c3.id = c2.id * c2.id;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    emp1 c1,
    emp1 c2,
    emp1 c3
WHERE
    c3.id = c2.id
    AND c3.id * c2.id = c1.id * c1.id;

-- Check the usage of a parse tree by the set operations (bug #18170)
EXPLAIN (
    COSTS OFF
)
SELECT
    c1.code
FROM
    emp1 c1
    LEFT JOIN emp1 c2 ON c1.id = c2.id
WHERE
    c2.id IS NOT NULL
EXCEPT ALL
SELECT
    c3.code
FROM
    emp1 c3;

-- Check that SJE removes references from PHVs correctly
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    emp1 t1
    LEFT JOIN (
        SELECT
            coalesce(t3.code, 1)
        FROM
            emp1 t2
            LEFT JOIN (emp1 t3
                JOIN emp1 t4 ON t3.id = t4.id) ON TRUE) ON TRUE;

-- Try PHV, which could potentially be removed completely by SJE, but that's
-- not implemented yet.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM
    emp1 t1
    LEFT JOIN ((
            SELECT
                1 AS x,
                *
            FROM
                emp1 t2) s1
            INNER JOIN (
                SELECT
                    *
                FROM
                    emp1 t3) s2 ON s1.id = s2.id) ON TRUE
WHERE
    s1.x = 1;

-- Check that PHVs do not impose any constraints on removing self joins
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    emp1 t1
    JOIN emp1 t2 ON t1.id = t2.id
    LEFT JOIN LATERAL (
        SELECT
            t1.id AS t1id,
            *
        FROM
            generate_series(1, 1) t3) s ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    generate_series(1, 10) t1 (id)
    LEFT JOIN LATERAL (
        SELECT
            t1.id AS t1id,
            t2.id
        FROM
            emp1 t2
            JOIN emp1 t3 ON t2.id = t3.id) ON TRUE;

-- This is a degenerate case of PHV usage: it is evaluated and needed inside
-- a baserel scan operation that the SJE removes.  The PHV in this test should
-- be in the filter of parameterized Index Scan: the replace_nestloop_params()
-- code will detect if the placeholder list doesn't have a reference to this
-- parameter.
--
-- NOTE:  enable_hashjoin and enable_mergejoin must be disabled.
CREATE TABLE tbl_phv (
    x int,
    y int PRIMARY KEY
);

CREATE INDEX tbl_phv_idx ON tbl_phv (x);

INSERT INTO tbl_phv (x, y)
SELECT
    gs,
    gs
FROM
    generate_series(1, 100) AS gs;

VACUUM ANALYZE tbl_phv;

EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    1
FROM
    tbl_phv t1
    LEFT JOIN (
        SELECT
            1 extra,
            x,
            y
        FROM
            tbl_phv tl) t3
    JOIN (
        SELECT
            y
        FROM
            tbl_phv tr) t4 ON t4.y = t3.y ON TRUE
WHERE
    t3.extra IS NOT NULL
    AND t3.x = t1.x % 2;

DROP TABLE IF EXISTS tbl_phv;

-- Check that SJE replaces join clauses involving the removed rel correctly
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    emp1 t1
    INNER JOIN emp1 t2 ON t1.id = t2.id
    LEFT JOIN emp1 t3 ON t1.id > 1
        AND t1.id < 2;

-- Check that SJE doesn't replace the target relation
EXPLAIN (
    COSTS OFF
) WITH t1 AS (
    SELECT
        *
    FROM
        emp1)
UPDATE
    emp1
SET
    code = t1.code + 1
FROM
    t1
WHERE
    t1.id = emp1.id
RETURNING
    emp1.id,
    emp1.code,
    t1.code;

-- Check that SJE correctly replaces relations in OR-clauses
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    emp1 t1
    INNER JOIN emp1 t2 ON t1.id = t2.id
    LEFT JOIN emp1 t3 ON t1.code = 1
        AND (t2.code = t3.code
            OR t2.code = 1);

INSERT INTO emp1
VALUES
    (1, 1),
    (2, 1);

WITH t1 AS (
    SELECT
        *
    FROM
        emp1
)
UPDATE
    emp1
SET
    code = t1.code + 1
FROM
    t1
WHERE
    t1.id = emp1.id
RETURNING
    emp1.id,
    emp1.code,
    t1.code;

TRUNCATE emp1;

EXPLAIN (
    COSTS OFF
) UPDATE
    sj sq
SET
    b = 1
FROM
    sj AS sz
WHERE
    sq.a = sz.a;

CREATE RULE sj_del_rule AS ON DELETE TO sj
    DO INSTEAD
    UPDATE
        sj SET
        a = 1 WHERE
        a = OLD.a;

EXPLAIN (
    COSTS OFF
) DELETE FROM sj;

DROP RULE sj_del_rule ON sj CASCADE;

-- Check that SJE does not mistakenly omit qual clauses (bug #18187)
INSERT INTO emp1
    VALUES (1, 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    emp1
    FULL JOIN (
        SELECT
            *
        FROM
            emp1 t1
            JOIN emp1 t2
            JOIN emp1 t3 ON t2.id = t3.id ON TRUE
        WHERE
            FALSE) s ON TRUE
WHERE
    FALSE;

SELECT
    1
FROM
    emp1
    FULL JOIN (
        SELECT
            *
        FROM
            emp1 t1
            JOIN emp1 t2
            JOIN emp1 t3 ON t2.id = t3.id ON TRUE
        WHERE
            FALSE) s ON TRUE
WHERE
    FALSE;

-- Check that SJE does not mistakenly re-use knowledge of relation uniqueness
-- made with different set of quals
INSERT INTO emp1
    VALUES (2, 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    emp1 t1
WHERE
    EXISTS (
        SELECT
            *
        FROM
            emp1 t2
        WHERE
            t2.id = t1.code
            AND t2.code > 0);

SELECT
    *
FROM
    emp1 t1
WHERE
    EXISTS (
        SELECT
            *
        FROM
            emp1 t2
        WHERE
            t2.id = t1.code
            AND t2.code > 0);

-- We can remove the join even if we find the join can't duplicate rows and
-- the base quals of each side are different.  In the following case we end up
-- moving quals over to s1 to make it so it can't match any rows.
CREATE TABLE sl (
    a int,
    b int,
    c int
);

CREATE UNIQUE INDEX ON sl (a, b);

VACUUM ANALYZE sl;

-- Both sides are unique, but base quals are different
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sl t1,
    sl t2
WHERE
    t1.a = t2.a
    AND t1.b = 1
    AND t2.b = 2;

-- Check NullTest in baserestrictinfo list
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sl t1,
    sl t2
WHERE
    t1.a = t2.a
    AND t1.b = 1
    AND t2.b = 2
    AND t1.c IS NOT NULL
    AND t2.c IS NOT NULL
    AND t2.b IS NOT NULL
    AND t1.b IS NOT NULL
    AND t1.a IS NOT NULL
    AND t2.a IS NOT NULL;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    sl t1,
    sl t2
WHERE
    t1.b = t2.b
    AND t2.a = 3
    AND t1.a = 3
    AND t1.c IS NOT NULL
    AND t2.c IS NOT NULL
    AND t2.b IS NOT NULL
    AND t1.b IS NOT NULL
    AND t1.a IS NOT NULL
    AND t2.a IS NOT NULL;

-- Join qual isn't mergejoinable, but inner is unique.
EXPLAIN (
    COSTS OFF
)
SELECT
    n2.a
FROM
    sj n1,
    sj n2
WHERE
    n1.a <> n2.a
    AND n2.a = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        n2.a
    FROM
        sj n1,
        sj n2
    WHERE
        n1.a <> n2.a) q0,
    sl
WHERE
    q0.a = 1;

-- Do not forget to replace relid in bare Var join clause (bug #19435)
ALTER TABLE sl
    ADD COLUMN bool_col boolean;

EXPLAIN (
    COSTS OFF
)
SELECT
    1 AS c1
FROM
    sl sl1
    LEFT JOIN (sl AS sl2
        NATURAL JOIN sl AS sl3) ON sl2.bool_col
    LEFT JOIN sl AS sl4 ON sl2.bool_col;

-- Check that quals of a jointree node that becomes empty when the self-join
-- is removed are not lost, and that they don't migrate above an outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    s.a
FROM (
    SELECT
        *
    FROM
        sl
    WHERE
        c IS NOT NULL) s,
    sl t
WHERE
    t.a = s.a
    AND t.b = s.b;

EXPLAIN (
    COSTS OFF
)
SELECT
    t1.a,
    ss.a
FROM
    sl t1
    LEFT JOIN (
        SELECT
            s.a
        FROM (
            SELECT
                *
            FROM
                sl
            WHERE
                c IS NOT NULL) s
            JOIN sl t ON t.a = s.a
                AND t.b = s.b) ss ON ss.a = t1.a;

-- Check optimization disabling if it will violate special join conditions.
-- Two identical joined relations satisfies self join removal conditions but
-- stay in different special join infos.
CREATE TABLE sj_t1 (
    id serial,
    a int
);

CREATE TABLE sj_t2 (
    id serial,
    a int
);

CREATE TABLE sj_t3 (
    id serial,
    a int
);

CREATE TABLE sj_t4 (
    id serial,
    a int
);

CREATE UNIQUE INDEX ON sj_t3 USING btree (a, id);

CREATE UNIQUE INDEX ON sj_t2 USING btree (id);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    sj_t1
    JOIN (
        SELECT
            sj_t2.id AS id
        FROM
            sj_t2
        WHERE
            EXISTS (
                SELECT
                    TRUE
                FROM
                    sj_t3,
                    sj_t4
                WHERE
                    sj_t3.a = 1
                    AND sj_t3.id = sj_t2.id)) t2t3t4 ON sj_t1.id = t2t3t4.id
    JOIN (
        SELECT
            sj_t2.id AS id
        FROM
            sj_t2
        WHERE
            EXISTS (
                SELECT
                    TRUE
                FROM
                    sj_t3,
                    sj_t4
                WHERE
                    sj_t3.a = 1
                    AND sj_t3.id = sj_t2.id)) _t2t3t4 ON sj_t1.id = _t2t3t4.id;

-- Check SJE interaction with aggpresorted optimization.
CREATE TEMP TABLE sje_agg (
    id int PRIMARY KEY,
    p int,
    q int
);

INSERT INTO sje_agg
SELECT
    i,
    i % 3, (i * 7) % 10
FROM
    generate_series(1, 30) i;

ANALYZE sje_agg;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(DISTINCT a.p) AS dp,
    count(DISTINCT a.q) AS dq,
    sum(DISTINCT a2.q) AS sq
FROM
    sje_agg a
    JOIN sje_agg a2 ON a.id = a2.id;

SELECT
    count(DISTINCT a.p) AS dp,
    count(DISTINCT a.q) AS dq,
    sum(DISTINCT a2.q) AS sq
FROM
    sje_agg a
    JOIN sje_agg a2 ON a.id = a2.id;

--
-- Test RowMarks-related code
--
-- Both sides have explicit LockRows marks
EXPLAIN (
    COSTS OFF
)
SELECT
    a1.a
FROM
    sj a1,
    sj a2
WHERE (a1.a = a2.a)
FOR UPDATE;

RESET enable_hashjoin;

RESET enable_mergejoin;

--
-- Test hints given on incorrect column references are useful
--
SELECT
    t1.uunique1
FROM
    tenk1 t1
    JOIN tenk2 t2 ON t1.two = t2.two;

-- error, prefer "t1" suggestion
SELECT
    t2.uunique1
FROM
    tenk1 t1
    JOIN tenk2 t2 ON t1.two = t2.two;

-- error, prefer "t2" suggestion
SELECT
    uunique1
FROM
    tenk1 t1
    JOIN tenk2 t2 ON t1.two = t2.two;

-- error, suggest both at once
SELECT
    ctid
FROM
    tenk1 t1
    JOIN tenk2 t2 ON t1.two = t2.two;

-- error, need qualification
--
-- Take care to reference the correct RTE
--
SELECT
    atts.relid::regclass,
    s.*
FROM
    pg_stats s
    JOIN pg_attribute a ON s.attname = a.attname
        AND s.tablename = a.attrelid::regclass::text
    JOIN (
        SELECT
            unnest(indkey) attnum,
            indexrelid
        FROM
            pg_index i) atts ON atts.attnum = a.attnum
WHERE
    schemaname != 'pg_catalog';

-- Test bug in rangetable flattening
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1
FROM (
    SELECT
        *
    FROM
        int8_tbl
    WHERE
        q1 <> (
            SELECT
                42)
        OFFSET 0) ss
WHERE
    FALSE;

--
-- Test LATERAL
--
SELECT
    unique2,
    x.*
FROM
    tenk1 a,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl b
        WHERE
            f1 = a.unique1) x;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2,
    x.*
FROM
    tenk1 a,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl b
        WHERE
            f1 = a.unique1) x;

SELECT
    unique2,
    x.*
FROM
    int4_tbl x,
    LATERAL (
        SELECT
            unique2
        FROM
            tenk1
        WHERE
            f1 = unique1) ss;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2,
    x.*
FROM
    int4_tbl x,
    LATERAL (
        SELECT
            unique2
        FROM
            tenk1
        WHERE
            f1 = unique1) ss;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2,
    x.*
FROM
    int4_tbl x
    CROSS JOIN LATERAL (
        SELECT
            unique2
        FROM
            tenk1
        WHERE
            f1 = unique1) ss;

SELECT
    unique2,
    x.*
FROM
    int4_tbl x
    LEFT JOIN LATERAL (
        SELECT
            unique1,
            unique2
        FROM
            tenk1
        WHERE
            f1 = unique1) ss ON TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2,
    x.*
FROM
    int4_tbl x
    LEFT JOIN LATERAL (
        SELECT
            unique1,
            unique2
        FROM
            tenk1
        WHERE
            f1 = unique1) ss ON TRUE;

-- check scoping of lateral versus parent references
-- the first of these should return int8_tbl.q2, the second int8_tbl.q1
SELECT
    *,
    (
        SELECT
            r
        FROM (
            SELECT
                q1 AS q2) x,
            (
                SELECT
                    q2 AS r) y)
    FROM
        int8_tbl;

SELECT
    *,
    (
        SELECT
            r
        FROM (
            SELECT
                q1 AS q2) x,
            LATERAL (
                SELECT
                    q2 AS r) y)
    FROM
        int8_tbl;

-- lateral with function in FROM
SELECT
    count(*)
FROM
    tenk1 a,
    LATERAL generate_series(1, two) g;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a,
    LATERAL generate_series(1, two) g;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a
    CROSS JOIN LATERAL generate_series(1, two) g;

-- don't need the explicit LATERAL keyword for functions
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a,
    generate_series(1, two) g;

-- lateral with UNION ALL subselect
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    generate_series(100, 200) g,
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl a
        WHERE
            g = q1
        UNION ALL
        SELECT
            *
        FROM
            int8_tbl b
        WHERE
            g = q2) ss;

SELECT
    *
FROM
    generate_series(100, 200) g,
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl a
        WHERE
            g = q1
        UNION ALL
        SELECT
            *
        FROM
            int8_tbl b
        WHERE
            g = q2) ss;

-- lateral with UNION ALL subselect, where a member is a subquery whose
-- output contains a lateral reference
EXPLAIN (
    COSTS OFF
)
SELECT
    ss.v
FROM
    int8_tbl x,
    LATERAL (
        SELECT
            x.q1
        FROM ( SELECT DISTINCT
                q2
            FROM
                int8_tbl) s
        UNION ALL
        SELECT
            q2
        FROM
            int8_tbl) ss (v);

-- lateral UNION ALL referencing a join alias Var that needs a PHV; the
-- appendrel parent and children must share the PHV
-- Here the Var is a whole-row reference to a nullable join.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.j
FROM
    int4_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN int4_tbl c) j ON TRUE,
    LATERAL ((
            SELECT
                j OFFSET 0)
    UNION ALL
    SELECT
        NULL) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.j
FROM
    int4_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN int4_tbl c) j ON TRUE,
    LATERAL (
        SELECT
            j
    UNION ALL
    SELECT
        NULL) ss;

-- Here the Var is a merged column of a full join with a non-Var input
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.c
FROM
    int4_tbl a
    LEFT JOIN ((
            SELECT
                f1 + 0 AS c
            FROM
                int4_tbl) s
            FULL JOIN int4_tbl b (c)
            USING (c)) j ON TRUE,
    LATERAL ((
            SELECT
                j.c OFFSET 0)
    UNION ALL
    SELECT
        1) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.c
FROM
    int4_tbl a
    LEFT JOIN ((
            SELECT
                f1 + 0 AS c
            FROM
                int4_tbl) s
            FULL JOIN int4_tbl b (c)
            USING (c)) j ON TRUE,
    LATERAL (
        SELECT
            j.c
    UNION ALL
    SELECT
        1) ss;

-- Here the UNION ALL is nested in a pulled-up lateral subquery
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.j
FROM
    int4_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN int4_tbl c) j ON TRUE,
    LATERAL (
        SELECT
            *
        FROM ((
                SELECT
                    j OFFSET 0)
        UNION ALL
        SELECT
            NULL) s) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.j
FROM
    int4_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN int4_tbl c) j ON TRUE,
    LATERAL (
        SELECT
            *
        FROM (
            SELECT
                j
        UNION ALL
        SELECT
            NULL) s) ss;

-- join alias Var needing a PHV, referenced in both the tlist and the quals of
-- a pulled-up subquery; both references must share the PHV
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        v.k
    FROM
        int4_tbl a
        LEFT JOIN (int4_tbl b
            CROSS JOIN int4_tbl c) j ON TRUE
        LEFT JOIN LATERAL (
            SELECT
                j AS k
            FROM
                int4_tbl d) v ON TRUE
        WHERE
            v.k::text IS NOT NULL) ss;

-- join alias Var needing a PHV, inside the PHV that grouping sets put around
-- a pulled-up subquery's output; the qual must not compute ROW(NULL, 1)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss.x,
    count(*)
FROM
    int8_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN (
            SELECT
                1 AS c) s) j ON a.q1 = j.f1
    CROSS JOIN LATERAL (
        SELECT
            j AS x) ss
WHERE
    ss.x::text IS NOT NULL
GROUP BY
    ROLLUP (ss.x);

SELECT
    ss.x,
    count(*)
FROM
    int8_tbl a
    LEFT JOIN (int4_tbl b
        CROSS JOIN (
            SELECT
                1 AS c) s) j ON a.q1 = j.f1
    CROSS JOIN LATERAL (
        SELECT
            j AS x) ss
WHERE
    ss.x::text IS NOT NULL
GROUP BY
    ROLLUP (ss.x);

-- lateral with VALUES
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
    JOIN LATERAL (
        VALUES (a.unique1)) ss (x) ON b.unique2 = ss.x;

SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
    JOIN LATERAL (
        VALUES (a.unique1)) ss (x) ON b.unique2 = ss.x;

-- lateral with VALUES, no flattening possible
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
    JOIN LATERAL (
        VALUES (a.unique1),
            (-1)) ss (x) ON b.unique2 = ss.x;

SELECT
    count(*)
FROM
    tenk1 a,
    tenk1 b
    JOIN LATERAL (
        VALUES (a.unique1),
            (-1)) ss (x) ON b.unique2 = ss.x;

-- lateral injecting a strange outer join condition
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl a,
    int8_tbl x
    LEFT JOIN LATERAL (
        SELECT
            a.q1
        FROM
            int4_tbl y) ss (z) ON x.q2 = ss.z
ORDER BY
    a.q1,
    a.q2,
    x.q1,
    x.q2,
    ss.z;

SELECT
    *
FROM
    int8_tbl a,
    int8_tbl x
    LEFT JOIN LATERAL (
        SELECT
            a.q1
        FROM
            int4_tbl y) ss (z) ON x.q2 = ss.z
ORDER BY
    a.q1,
    a.q2,
    x.q1,
    x.q2,
    ss.z;

-- lateral reference to a join alias variable
SELECT
    *
FROM (
    SELECT
        f1 / 2 AS x
    FROM
        int4_tbl) ss1
    JOIN int4_tbl i4 ON x = f1,
    LATERAL (
        SELECT
            x) ss2 (y);

SELECT
    *
FROM (
    SELECT
        f1 AS x
    FROM
        int4_tbl) ss1
    JOIN int4_tbl i4 ON x = f1,
    LATERAL (
        VALUES (x)) ss2 (y);

SELECT
    *
FROM ((
        SELECT
            f1 / 2 AS x
        FROM
            int4_tbl) ss1
        JOIN int4_tbl i4 ON x = f1) j,
    LATERAL (
        SELECT
            x) ss2 (y);

-- lateral references requiring pullup
SELECT
    *
FROM (
    VALUES (1)) x (lb),
    LATERAL generate_series(lb, 4) x4;

SELECT
    *
FROM (
    SELECT
        f1 / 1000000000
    FROM
        int4_tbl) x (lb),
    LATERAL generate_series(lb, 4) x4;

SELECT
    *
FROM (
    VALUES (1)) x (lb),
    LATERAL (
        VALUES (lb)) y (lbcopy);

SELECT
    *
FROM (
    VALUES (1)) x (lb),
    LATERAL (
        SELECT
            lb
        FROM
            int4_tbl) y (lbcopy);

SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            coalesce(q2, 0) q2
        FROM
            int8_tbl) y ON x.q2 = y.q1,
    LATERAL (
        VALUES (x.q1, y.q1, y.q2)) v (xq1, yq1, yq2);

SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            coalesce(q2, 0) q2
        FROM
            int8_tbl) y ON x.q2 = y.q1,
    LATERAL (
        SELECT
            x.q1,
            y.q1,
            y.q2) v (xq1,
        yq1,
        yq2);

SELECT
    x.*
FROM
    int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            coalesce(q2, 0) q2
        FROM
            int8_tbl) y ON x.q2 = y.q1,
    LATERAL (
        SELECT
            x.q1,
            y.q1,
            y.q2) v (xq1,
        yq1,
        yq2);

SELECT
    v.*
FROM (int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            coalesce(q2, 0) q2
        FROM
            int8_tbl) y ON x.q2 = y.q1)
    LEFT JOIN int4_tbl z ON z.f1 = x.q2,
    LATERAL (
        SELECT
            x.q1,
            y.q1
    UNION ALL
    SELECT
        x.q2,
        y.q2) v (vx,
    vy);

SELECT
    v.*
FROM (int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            (
                SELECT
                    coalesce(q2, 0)) q2
            FROM
                int8_tbl) y ON x.q2 = y.q1)
    LEFT JOIN int4_tbl z ON z.f1 = x.q2,
    LATERAL (
        SELECT
            x.q1,
            y.q1
    UNION ALL
    SELECT
        x.q2,
        y.q2) v (vx,
    vy);

SELECT
    v.*
FROM (int8_tbl x
    LEFT JOIN (
        SELECT
            q1,
            (
                SELECT
                    coalesce(q2, 0)) q2
            FROM
                int8_tbl) y ON x.q2 = y.q1)
    LEFT JOIN int4_tbl z ON z.f1 = x.q2,
    LATERAL (
        SELECT
            x.q1,
            y.q1
        FROM
            onerow
    UNION ALL
    SELECT
        x.q2,
        y.q2
    FROM
        onerow) v (vx,
        vy);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            *,
            a.q2 AS x
        FROM
            int8_tbl b) ss ON a.q2 = ss.q1;

SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            *,
            a.q2 AS x
        FROM
            int8_tbl b) ss ON a.q2 = ss.q1;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            *,
            coalesce(a.q2, 42) AS x
        FROM
            int8_tbl b) ss ON a.q2 = ss.q1;

SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            *,
            coalesce(a.q2, 42) AS x
        FROM
            int8_tbl b) ss ON a.q2 = ss.q1;

-- check EC-derived clauses for a UNION ALL member with nullable lateral refs
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN int8_tbl y ON x.q2 = y.q1,
    LATERAL (
        SELECT
            x.q1 AS v
    UNION ALL
    SELECT
        x.q1 + y.q2) ss
WHERE
    x.q2 = ss.v;

SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN int8_tbl y ON x.q2 = y.q1,
    LATERAL (
        SELECT
            x.q1 AS v
    UNION ALL
    SELECT
        x.q1 + y.q2) ss
WHERE
    x.q2 = ss.v;

-- likewise when the member is scanned below the outer join nulling those refs
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN int8_tbl y ON TRUE
    LEFT JOIN (int8_tbl z
        JOIN LATERAL (
            SELECT
                z.q1 AS v
        UNION ALL
        SELECT
            y.q1 + z.q1) ss ON z.q2 = ss.v) ON y.q1 = 1;

SELECT
    *
FROM
    int8_tbl x
    LEFT JOIN int8_tbl y ON TRUE
    LEFT JOIN (int8_tbl z
        JOIN LATERAL (
            SELECT
                z.q1 AS v
        UNION ALL
        SELECT
            y.q1 + z.q1) ss ON z.q2 = ss.v) ON y.q1 = 1;

-- check that a clause the UNION ALL members cannot enforce is not dropped
-- from the join above as already enforced, even through a Materialize
BEGIN;
SET local join_collapse_limit TO 1;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    JOIN (int4_tbl t2
        CROSS JOIN LATERAL (
            SELECT
                q1
            FROM
                int8_tbl
            WHERE
                q2 < t1.f1
            UNION ALL
            SELECT
                q1
            FROM
                int8_tbl
            WHERE
                q2 < t1.f1) s) ON t1.f1 = s.q1 + t1.f1;
SELECT
    *
FROM
    int4_tbl t1
    JOIN (int4_tbl t2
        CROSS JOIN LATERAL (
            SELECT
                q1
            FROM
                int8_tbl
            WHERE
                q2 < t1.f1
            UNION ALL
            SELECT
                q1
            FROM
                int8_tbl
            WHERE
                q2 < t1.f1) s) ON t1.f1 = s.q1 + t1.f1;
ROLLBACK;

-- lateral can result in join conditions appearing below their
-- real semantic level
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl i
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            int2_tbl j
        WHERE
            i.f1 = j.f1) k ON TRUE;

SELECT
    *
FROM
    int4_tbl i
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM
            int2_tbl j
        WHERE
            i.f1 = j.f1) k ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl i
    LEFT JOIN LATERAL (
        SELECT
            coalesce(i, i)
        FROM
            int2_tbl j
        WHERE
            i.f1 = j.f1) k ON TRUE;

SELECT
    *
FROM
    int4_tbl i
    LEFT JOIN LATERAL (
        SELECT
            coalesce(i, i)
        FROM
            int2_tbl j
        WHERE
            i.f1 = j.f1) k ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl a,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl b
        LEFT JOIN int8_tbl c ON (b.f1 = q1
                AND a.f1 = q2)) ss;

SELECT
    *
FROM
    int4_tbl a,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl b
        LEFT JOIN int8_tbl c ON (b.f1 = q1
                AND a.f1 = q2)) ss;

-- lateral reference in a PlaceHolderVar evaluated at join level
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            b.q1 AS bq1,
            c.q1 AS cq1,
            least (a.q1, b.q1, c.q1)
        FROM
            int8_tbl b
            CROSS JOIN int8_tbl c) ss ON a.q2 = ss.bq1;

SELECT
    *
FROM
    int8_tbl a
    LEFT JOIN LATERAL (
        SELECT
            b.q1 AS bq1,
            c.q1 AS cq1,
            least (a.q1, b.q1, c.q1)
        FROM
            int8_tbl b
            CROSS JOIN int8_tbl c) ss ON a.q2 = ss.bq1;

-- case requiring nested PlaceHolderVars
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl c
    LEFT JOIN (int8_tbl a
        LEFT JOIN (
            SELECT
                q1,
                coalesce(q2, 42) AS x
            FROM
                int8_tbl b) ss1 ON a.q2 = ss1.q1
            CROSS JOIN LATERAL (
                SELECT
                    q1,
                    coalesce(ss1.x, q2) AS y
                FROM
                    int8_tbl d) ss2) ON c.q2 = ss2.q1,
    LATERAL (
        SELECT
            ss2.y OFFSET 0) ss3;

-- another case requiring nested PlaceHolderVars
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        0 AS val0) AS ss0
    LEFT JOIN (
        SELECT
            1 AS val) AS ss1 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            ss1.val AS val_filtered
        WHERE
            FALSE) AS ss2 ON TRUE;

SELECT
    *
FROM (
    SELECT
        0 AS val0) AS ss0
    LEFT JOIN (
        SELECT
            1 AS val) AS ss1 ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            ss1.val AS val_filtered
        WHERE
            FALSE) AS ss2 ON TRUE;

-- case that breaks the old ph_may_need optimization
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    c.*,
    a.*,
    ss1.q1,
    ss2.q1,
    ss3.*
FROM
    int8_tbl c
    LEFT JOIN (int8_tbl a
        LEFT JOIN (
            SELECT
                q1,
                coalesce(q2, f1) AS x
            FROM
                int8_tbl b,
                int4_tbl b2
            WHERE
                q1 < f1) ss1 ON a.q2 = ss1.q1
        CROSS JOIN LATERAL (
            SELECT
                q1,
                coalesce(ss1.x, q2) AS y
            FROM
                int8_tbl d) ss2) ON c.q2 = ss2.q1,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl i
        WHERE
            ss2.y > f1) ss3;

-- check processing of postponed quals (bug #9041)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        1 AS x OFFSET 0) x
    CROSS JOIN (
        SELECT
            2 AS y OFFSET 0) y
    LEFT JOIN LATERAL (
        SELECT
            *
        FROM (
            SELECT
                3 AS z OFFSET 0) z
        WHERE
            z.z = x.x) zz ON zz.z = y.y;

-- a new postponed-quals issue (bug #17768)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl t2
            INNER JOIN int4_tbl t3 ON t1.f1 = 1
            INNER JOIN (int4_tbl t4
                LEFT JOIN int4_tbl t5 ON TRUE) ON TRUE) ss;

-- check dummy rels with lateral references (bug #15694)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i8
    LEFT JOIN LATERAL (
        SELECT
            *,
            i8.q2
        FROM
            int4_tbl
        WHERE
            FALSE) ss ON TRUE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i8
    LEFT JOIN LATERAL (
        SELECT
            *,
            i8.q2
        FROM
            int4_tbl i1,
            int4_tbl i2
        WHERE
            FALSE) ss ON TRUE;

-- check handling of nested appendrels inside LATERAL
SELECT
    *
FROM ((
        SELECT
            2 AS v)
    UNION ALL (
        SELECT
            3 AS v)) AS q1
    CROSS JOIN LATERAL ((
            SELECT
                *
            FROM ((
                    SELECT
                        4 AS v)
            UNION ALL (
                SELECT
                    5 AS v)) AS q3)
    UNION ALL (
        SELECT
            q1.v)) AS q2;

-- check the number of columns specified
SELECT
    *
FROM (int8_tbl i
    CROSS JOIN int4_tbl j) ss (a,
        b,
        c,
        d);

-- check we don't try to do a unique-ified semijoin with LATERAL
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (0, 9998),
        (1, 1000)) v (id, x),
    LATERAL (
        SELECT
            f1
        FROM
            int4_tbl
        WHERE
            f1 = ANY (
                SELECT
                    unique1
                FROM
                    tenk1
                WHERE
                    unique2 = v.x OFFSET 0)) ss;

SELECT
    *
FROM (
    VALUES (0, 9998),
        (1, 1000)) v (id, x),
    LATERAL (
        SELECT
            f1
        FROM
            int4_tbl
        WHERE
            f1 = ANY (
                SELECT
                    unique1
                FROM
                    tenk1
                WHERE
                    unique2 = v.x OFFSET 0)) ss;

-- check proper extParam/allParam handling (this isn't exactly a LATERAL issue,
-- but we can make the test case much more compact with LATERAL)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (0),
        (1)) v (id),
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl t1, LATERAL (
                SELECT
                    *
                FROM (
                    SELECT
                        *
                    FROM
                        int8_tbl t2
                    WHERE (q1, random() > 0) = ANY (
                        SELECT
                            q2,
                            random() > 0
                        FROM
                            int8_tbl t3
                        WHERE
                            q2 = (
                                SELECT
                                    greatest (t1.q1, t2.q2))
                            AND (
                                SELECT
                                    v.id = 0))
                            OFFSET 0) ss2) ss
                WHERE
                    t1.q1 = ss.q2) ss0;

SELECT
    *
FROM (
    VALUES (0),
        (1)) v (id),
    LATERAL (
        SELECT
            *
        FROM
            int8_tbl t1, LATERAL (
                SELECT
                    *
                FROM (
                    SELECT
                        *
                    FROM
                        int8_tbl t2
                    WHERE (q1, random() > 0) = ANY (
                        SELECT
                            q2,
                            random() > 0
                        FROM
                            int8_tbl t3
                        WHERE
                            q2 = (
                                SELECT
                                    greatest (t1.q1, t2.q2))
                            AND (
                                SELECT
                                    v.id = 0))
                            OFFSET 0) ss2) ss
                WHERE
                    t1.q1 = ss.q2) ss0;

-- check that lateral references hidden in a whole-row join alias Var
-- prevent pullup of a LATERAL subquery
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    i4.f1,
    ss.x,
    i8.q1
FROM
    int4_tbl i4,
    LATERAL (
        SELECT
            (j IS NULL)::int
        FROM ((
                SELECT
                    i4.f1) s
            LEFT JOIN (
                SELECT
                    1) v ON FALSE) j) ss (x)
    LEFT JOIN int8_tbl i8 ON ss.x = i8.q1
ORDER BY
    1;

SELECT
    i4.f1,
    ss.x,
    i8.q1
FROM
    int4_tbl i4,
    LATERAL (
        SELECT
            (j IS NULL)::int
        FROM ((
                SELECT
                    i4.f1) s
            LEFT JOIN (
                SELECT
                    1) v ON FALSE) j) ss (x)
    LEFT JOIN int8_tbl i8 ON ss.x = i8.q1
ORDER BY
    1;

-- same, with the lateral reference hidden in the subquery's quals
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    i4.f1,
    i8.q1,
    ss.y
FROM
    int4_tbl i4,
    int8_tbl i8
    LEFT JOIN LATERAL (
        SELECT
            1
        FROM ((
                SELECT
                    i4.f1) s
                LEFT JOIN (
                    SELECT
                        1) v ON FALSE) j
            WHERE
                length(j::text) > 3) ss (y) ON TRUE
WHERE
    i4.f1 = 0
ORDER BY
    1,
    2;

SELECT
    i4.f1,
    i8.q1,
    ss.y
FROM
    int4_tbl i4,
    int8_tbl i8
    LEFT JOIN LATERAL (
        SELECT
            1
        FROM ((
                SELECT
                    i4.f1) s
                LEFT JOIN (
                    SELECT
                        1) v ON FALSE) j
            WHERE
                length(j::text) > 3) ss (y) ON TRUE
WHERE
    i4.f1 = 0
ORDER BY
    1,
    2;

-- check that lateral references in a sort key added below a mergejoin are
-- replaced with nestloop params
SET enable_hashjoin TO OFF;

SET enable_nestloop TO OFF;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN LATERAL (
        SELECT
            t1.f1
        FROM
            int4_tbl t3
        WHERE
            t3.f1 = 0) s (x) ON TRUE
    JOIN int4_tbl t2 ON - s.x = t2.f1
WHERE
    t1.f1 = 123456;

SELECT
    *
FROM
    int4_tbl t1
    LEFT JOIN LATERAL (
        SELECT
            t1.f1
        FROM
            int4_tbl t3
        WHERE
            t3.f1 = 0) s (x) ON TRUE
    JOIN int4_tbl t2 ON - s.x = t2.f1
WHERE
    t1.f1 = 123456;

RESET enable_nestloop;

-- same, with the sort key computed atop a join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN LATERAL (
        SELECT
            t1.f1,
            t3.g
        FROM
            generate_series(1, 1000) t3 (g),
            int4_tbl t4) s (x,
        y) ON TRUE
    JOIN tenk1 t2 ON s.x + s.y = t2.unique1
WHERE
    t1.f1 = 0;

SELECT
    count(*)
FROM
    int4_tbl t1
    LEFT JOIN LATERAL (
        SELECT
            t1.f1,
            t3.g
        FROM
            generate_series(1, 1000) t3 (g),
            int4_tbl t4) s (x,
        y) ON TRUE
    JOIN tenk1 t2 ON s.x + s.y = t2.unique1
WHERE
    t1.f1 = 0;

RESET enable_hashjoin;

-- test some error cases where LATERAL should have been used but wasn't
SELECT
    f1,
    g
FROM
    int4_tbl a,
    (
        SELECT
            f1 AS g) ss;

SELECT
    f1,
    g
FROM
    int4_tbl a,
    (
        SELECT
            a.f1 AS g) ss;

SELECT
    f1,
    g
FROM
    int4_tbl a
    CROSS JOIN (
        SELECT
            f1 AS g) ss;

SELECT
    f1,
    g
FROM
    int4_tbl a
    CROSS JOIN (
        SELECT
            a.f1 AS g) ss;

-- SQL:2008 says the left table is in scope but illegal to access here
SELECT
    f1,
    g
FROM
    int4_tbl a
    RIGHT JOIN LATERAL generate_series(0, a.f1) g ON TRUE;

SELECT
    f1,
    g
FROM
    int4_tbl a
    FULL JOIN LATERAL generate_series(0, a.f1) g ON TRUE;

-- check we complain about ambiguous table references
SELECT
    *
FROM
    int8_tbl x
    CROSS JOIN (int4_tbl x
        CROSS JOIN LATERAL (
            SELECT
                x.f1) ss);

-- LATERAL can be used to put an aggregate into the FROM clause of its query
SELECT
    1
FROM
    tenk1 a,
    LATERAL (
        SELECT
            max(a.unique1)
        FROM
            int4_tbl b) ss;

-- check behavior of LATERAL in UPDATE/DELETE
CREATE temp TABLE xx1 AS
SELECT
    f1 AS x1,
    - f1 AS x2
FROM
    int4_tbl;

-- error, can't do this:
UPDATE
    xx1
SET
    x2 = f1
FROM (
    SELECT
        *
    FROM
        int4_tbl
    WHERE
        f1 = x1) ss;

UPDATE
    xx1
SET
    x2 = f1
FROM (
    SELECT
        *
    FROM
        int4_tbl
    WHERE
        f1 = xx1.x1) ss;

-- can't do it even with LATERAL:
UPDATE
    xx1
SET
    x2 = f1
FROM
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl
        WHERE
            f1 = x1) ss;

-- we might in future allow something like this, but for now it's an error:
UPDATE
    xx1
SET
    x2 = f1
FROM
    xx1,
    LATERAL (
        SELECT
            *
        FROM
            int4_tbl
        WHERE
            f1 = x1) ss;

-- also errors:
DELETE FROM xx1 USING (
    SELECT
        *
    FROM
        int4_tbl
    WHERE
        f1 = x1) ss;

DELETE FROM xx1 USING (
    SELECT
        *
    FROM
        int4_tbl
    WHERE
        f1 = xx1.x1) ss;

DELETE FROM xx1 USING LATERAL (
    SELECT
        *
    FROM
        int4_tbl
    WHERE
        f1 = x1) ss;

--
-- test LATERAL reference propagation down a multi-level inheritance hierarchy
-- produced for a multi-level partitioned table hierarchy.
--
CREATE TABLE join_pt1 (
    a int,
    b int,
    c varchar
)
PARTITION BY RANGE (a);

CREATE TABLE join_pt1p1 PARTITION OF join_pt1
FOR VALUES FROM (0) TO (100)
PARTITION BY RANGE (b);

CREATE TABLE join_pt1p2 PARTITION OF join_pt1
FOR VALUES FROM (100) TO (200);

CREATE TABLE join_pt1p1p1 PARTITION OF join_pt1p1
FOR VALUES FROM (0) TO (100);

INSERT INTO join_pt1
VALUES
    (1, 1, 'x'),
    (101, 101, 'y');

CREATE TABLE join_ut1 (
    a int,
    b int,
    c varchar
);

INSERT INTO join_ut1
VALUES
    (101, 101, 'y'),
    (2, 2, 'z');

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.b,
    ss.phv
FROM
    join_ut1 t1
    LEFT JOIN LATERAL (
        SELECT
            t2.a AS t2a,
            t3.a t3a,
            least (t1.a, t2.a, t3.a) phv
        FROM
            join_pt1 t2
            JOIN join_ut1 t3 ON t2.a = t3.b) ss ON t1.a = ss.t2a
ORDER BY
    t1.a;

SELECT
    t1.b,
    ss.phv
FROM
    join_ut1 t1
    LEFT JOIN LATERAL (
        SELECT
            t2.a AS t2a,
            t3.a t3a,
            least (t1.a, t2.a, t3.a) phv
        FROM
            join_pt1 t2
            JOIN join_ut1 t3 ON t2.a = t3.b) ss ON t1.a = ss.t2a
ORDER BY
    t1.a;

DROP TABLE join_pt1;

DROP TABLE join_ut1;

--
-- test estimation behavior with multi-column foreign key and constant qual
--
BEGIN;
CREATE TABLE fkest (
    x integer,
    x10 integer,
    x10b integer,
    x100 integer
);
INSERT INTO fkest
SELECT
    x,
    x / 10,
    x / 10,
    x / 100
FROM
    generate_series(1, 1000) x;
CREATE UNIQUE INDEX ON fkest (x, x10, x100);
ANALYZE fkest;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    fkest f1
    JOIN fkest f2 ON (f1.x = f2.x
            AND f1.x10 = f2.x10b
            AND f1.x100 = f2.x100)
    JOIN fkest f3 ON f1.x = f3.x
WHERE
    f1.x100 = 2;
ALTER TABLE fkest
    ADD CONSTRAINT fk FOREIGN KEY (x, x10b, x100) REFERENCES fkest (x, x10, x100);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    fkest f1
    JOIN fkest f2 ON (f1.x = f2.x
            AND f1.x10 = f2.x10b
            AND f1.x100 = f2.x100)
    JOIN fkest f3 ON f1.x = f3.x
WHERE
    f1.x100 = 2;
ROLLBACK;

--
-- test that foreign key join estimation performs sanely for outer joins
--
BEGIN;
CREATE TABLE fkest (
    a int,
    b int,
    c int UNIQUE,
    PRIMARY KEY (a, b)
);
CREATE TABLE fkest1 (
    a int,
    b int,
    PRIMARY KEY (a, b)
);
INSERT INTO fkest
SELECT
    x / 10,
    x % 10,
    x
FROM
    generate_series(1, 1000) x;
INSERT INTO fkest1
SELECT
    x / 10,
    x % 10
FROM
    generate_series(1, 1000) x;
ALTER TABLE fkest1
    ADD CONSTRAINT fkest1_a_b_fkey FOREIGN KEY (a, b) REFERENCES fkest;
ANALYZE fkest;
ANALYZE fkest1;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    fkest f
    LEFT JOIN fkest1 f1 ON f.a = f1.a
        AND f.b = f1.b
    LEFT JOIN fkest1 f2 ON f.a = f2.a
        AND f.b = f2.b
    LEFT JOIN fkest1 f3 ON f.a = f3.a
        AND f.b = f3.b
WHERE
    f.c = 1;
ROLLBACK;

--
-- test planner's ability to mark joins as unique
--
CREATE TABLE j1 (
    id int PRIMARY KEY
);

CREATE TABLE j2 (
    id int PRIMARY KEY
);

CREATE TABLE j3 (
    id int
);

INSERT INTO j1
VALUES
    (1),
    (2),
    (3);

INSERT INTO j2
VALUES
    (1),
    (2),
    (3);

INSERT INTO j3
VALUES
    (1),
    (1);

ANALYZE j1;

ANALYZE j2;

ANALYZE j3;

-- ensure join is properly marked as unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id = j2.id;

-- ensure join is not unique when not an equi-join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id > j2.id;

-- ensure non-unique rel is not chosen as inner
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j3 ON j1.id = j3.id;

-- ensure left join is marked as unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    LEFT JOIN j2 ON j1.id = j2.id;

-- ensure right join is marked as unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    RIGHT JOIN j2 ON j1.id = j2.id;

-- ensure full join is marked as unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    FULL JOIN j2 ON j1.id = j2.id;

-- a clauseless (cross) join can't be unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    CROSS JOIN j2;

-- ensure a natural join is marked as unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    NATURAL JOIN j2;

-- ensure a distinct clause allows the inner to become unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN ( SELECT DISTINCT
            id
        FROM
            j3) j3 ON j1.id = j3.id;

-- ensure group by clause allows the inner to become unique
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN (
        SELECT
            id
        FROM
            j3
        GROUP BY
            id) j3 ON j1.id = j3.id;

DROP TABLE j1;

DROP TABLE j2;

DROP TABLE j3;

-- test more complex permutations of unique joins
CREATE TABLE j1 (
    id1 int,
    id2 int,
    PRIMARY KEY (id1, id2)
);

CREATE TABLE j2 (
    id1 int,
    id2 int,
    PRIMARY KEY (id1, id2)
);

CREATE TABLE j3 (
    id1 int,
    id2 int,
    PRIMARY KEY (id1, id2)
);

INSERT INTO j1
VALUES
    (1, 1),
    (1, 2);

INSERT INTO j2
    VALUES (1, 1);

INSERT INTO j3
    VALUES (1, 1);

ANALYZE j1;

ANALYZE j2;

ANALYZE j3;

-- ensure there's no unique join when not all columns which are part of the
-- unique index are seen in the join clause
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1;

-- ensure proper unique detection with multiple join quals
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2;

-- ensure we don't detect the join to be unique when quals are not part of the
-- join condition
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
WHERE
    j1.id2 = 1;

-- as above, but for left joins.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    LEFT JOIN j2 ON j1.id1 = j2.id1
WHERE
    j1.id2 = 1;

CREATE UNIQUE INDEX j1_id2_idx ON j1 (id2)
WHERE
    id2 > 0;

-- ensure we don't use a partial unique index as unique proofs
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id2 = j2.id2;

DROP INDEX j1_id2_idx;

-- validate logic in merge joins which skips mark and restore.
-- it should only do this if all quals which were used to detect the unique
-- are present as join quals, and not plain quals.
SET enable_nestloop TO 0;

SET enable_hashjoin TO 0;

SET enable_sort TO 0;

-- we need additional data to get the partial indexes to be preferred
INSERT INTO j1
SELECT
    2,
    i
FROM
    generate_series(1, 100) i;

INSERT INTO j2
SELECT
    1,
    i
FROM
    generate_series(2, 100) i;

ANALYZE j1;

ANALYZE j2;

-- create indexes that will be preferred over the PKs to perform the join
CREATE INDEX j1_id1_idx ON j1 (id1)
WHERE
    id1 % 1000 = 1;

CREATE INDEX j2_id1_idx ON j2 (id1)
WHERE
    id1 % 1000 = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1;

SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1;

-- Exercise array keys mark/restore B-Tree code
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1
    AND j2.id1 = ANY (ARRAY[1]);

SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1
    AND j2.id1 = ANY (ARRAY[1]);

-- Exercise array keys "find extreme element" B-Tree code
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1
    AND j2.id1 >= ANY (ARRAY[1, 5]);

SELECT
    *
FROM
    j1
    INNER JOIN j2 ON j1.id1 = j2.id1
        AND j1.id2 = j2.id2
WHERE
    j1.id1 % 1000 = 1
    AND j2.id1 % 1000 = 1
    AND j2.id1 >= ANY (ARRAY[1, 5]);

RESET enable_nestloop;

RESET enable_hashjoin;

RESET enable_sort;

DROP TABLE j1;

DROP TABLE j2;

DROP TABLE j3;

-- check that semijoin inner is not seen as unique for a portion of the outerrel
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.unique1,
    t2.hundred
FROM
    onek t1,
    tenk1 t2
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tenk1 t3
        WHERE
            t3.thousand = t1.unique1
            AND t3.tenthous = t2.hundred)
    AND t1.unique1 < 1;

-- ... unless it actually is unique
CREATE TABLE j3 AS
SELECT
    unique1,
    tenthous
FROM
    onek;

VACUUM ANALYZE j3;

CREATE UNIQUE INDEX ON j3 (unique1, tenthous);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.unique1,
    t2.hundred
FROM
    onek t1,
    tenk1 t2
WHERE
    EXISTS (
        SELECT
            1
        FROM
            j3
        WHERE
            j3.unique1 = t1.unique1
            AND j3.tenthous = t2.hundred)
    AND t1.unique1 < 1;

DROP TABLE j3;

-- Exercise the "skip fetch" Bitmap Heap Scan optimization when candidate
-- tuples are discarded. This may occur when:
--   1. A join doesn't require all inner tuples to be scanned for each outer
--      tuple, and
--   2. The inner side is scanned using a bitmap heap scan, and
--   3. The bitmap heap scan is eligible for the "skip fetch" optimization.
--      This optimization is usable when no data from the underlying table is
--      needed. Use a temp table so it is only visible to this backend and
--      vacuum may reliably mark all blocks in the table all visible in the
--      visibility map.
CREATE TEMP TABLE skip_fetch (
    a int,
    b int
)
WITH (
    fillfactor = 10
);

INSERT INTO skip_fetch
SELECT
    i % 3,
    i
FROM
    generate_series(0, 30) i;

CREATE INDEX ON skip_fetch (a);

VACUUM (ANALYZE) skip_fetch;

SET enable_indexonlyscan = OFF;

SET enable_seqscan = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    t1.a
FROM
    skip_fetch t1
    LEFT JOIN skip_fetch t2 ON t2.a = 1
WHERE
    t2.a IS NULL;

SELECT
    t1.a
FROM
    skip_fetch t1
    LEFT JOIN skip_fetch t2 ON t2.a = 1
WHERE
    t2.a IS NULL;

RESET enable_indexonlyscan;

RESET enable_seqscan;

-- Test BitmapHeapScan with a rescan releases resources correctly
SET enable_seqscan = OFF;

SET enable_indexscan = OFF;

CREATE TEMP TABLE rescan_bhs (
    a int
);

INSERT INTO rescan_bhs
VALUES
    (1),
    (2);

CREATE INDEX ON rescan_bhs (a);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rescan_bhs t1
    LEFT JOIN rescan_bhs t2 ON t1.a IN (
        SELECT
            a
        FROM
            rescan_bhs t3
        WHERE
            t2.a > 1);

SELECT
    *
FROM
    rescan_bhs t1
    LEFT JOIN rescan_bhs t2 ON t1.a IN (
        SELECT
            a
        FROM
            rescan_bhs t3
        WHERE
            t2.a > 1);

RESET enable_seqscan;

RESET enable_indexscan;

-- Test that we do not account for nullingrels when looking up statistics
CREATE TABLE group_tbl (
    a int,
    b int
);

INSERT INTO group_tbl
SELECT
    1,
    1;

CREATE STATISTICS group_tbl_stat (ndistinct) ON a, b FROM group_tbl;

ANALYZE group_tbl;

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    group_tbl t1
    LEFT JOIN (
        SELECT
            a c1,
            COALESCE(a, a) c2
        FROM
            group_tbl t2) s ON TRUE
GROUP BY
    s.c1,
    s.c2;

DROP TABLE group_tbl;

-- Test that we ignore PlaceHolderVars when looking up statistics
EXPLAIN (
    COSTS OFF
)
SELECT
    t1.unique1
FROM
    tenk1 t1
    LEFT JOIN (
        SELECT
            *,
            42 AS phv
        FROM
            tenk1 t2) ss ON t1.unique2 = ss.unique2
WHERE
    ss.unique1 = ss.phv
    AND t1.unique1 < 100;

SELECT
    t1.unique1
FROM
    tenk1 t1
    LEFT JOIN (
        SELECT
            *,
            42 AS phv
        FROM
            tenk1 t2) ss ON t1.unique2 = ss.unique2
WHERE
    ss.unique1 = ss.phv
    AND t1.unique1 < 100;

--
-- Test for a nested loop join involving index scan, transforming OR-clauses
-- to SAOP.
--
EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*)
FROM
    tenk1 t1,
    tenk1 t2
WHERE
    t2.thousand = t1.tenthous
    OR t2.thousand = t1.unique1
    OR t2.thousand = t1.unique2;

SELECT
    COUNT(*)
FROM
    tenk1 t1,
    tenk1 t2
WHERE
    t2.thousand = t1.tenthous
    OR t2.thousand = t1.unique1
    OR t2.thousand = t1.unique2;

EXPLAIN (
    COSTS OFF
)
SELECT
    COUNT(*)
FROM
    onek t1
    LEFT JOIN tenk1 t2 ON (t2.thousand = t1.tenthous
            OR t2.thousand = t1.thousand);

SELECT
    COUNT(*)
FROM
    onek t1
    LEFT JOIN tenk1 t2 ON (t2.thousand = t1.tenthous
            OR t2.thousand = t1.thousand);

--
-- Test that a qual from above an antijoin made from a sublink is not pushed
-- down into the antijoin's RHS.
--
EXPLAIN (
    COSTS OFF
)
SELECT
    s.*
FROM (
    VALUES (1)) AS v (z)
    LEFT JOIN (
        SELECT
            123456 AS c, t1.f1 AS x
        FROM
            int4_tbl t1
        WHERE
            NOT EXISTS (
                SELECT
                    1
                FROM
                    tenk1 t2
                WHERE
                    t2.unique1 = t1.f1)) s ON TRUE
WHERE
    s.x = s.c;

SELECT
    s.*
FROM (
    VALUES (1)) AS v (z)
    LEFT JOIN (
        SELECT
            123456 AS c, t1.f1 AS x
        FROM
            int4_tbl t1
        WHERE
            NOT EXISTS (
                SELECT
                    1
                FROM
                    tenk1 t2
                WHERE
                    t2.unique1 = t1.f1)) s ON TRUE
WHERE
    s.x = s.c;

-- Test the same for NOT IN, which needs non-nullable inputs to become an
-- antijoin
BEGIN;
CREATE TEMP TABLE not_null_tab (
    f1 int4 NOT NULL
);
INSERT INTO not_null_tab
VALUES
    (0),
    (123456),
    (-123456);
ANALYZE not_null_tab;
EXPLAIN (
    COSTS OFF
)
SELECT
    s.*
FROM (
    VALUES (1)) AS v (z)
    LEFT JOIN (
        SELECT
            123456 AS c, t1.f1 AS x
        FROM
            not_null_tab t1
        WHERE
            t1.f1 NOT IN (
                SELECT
                    t2.unique1
                FROM
                    tenk1 t2
                WHERE
                    t2.unique1 IS NOT NULL)) s ON TRUE
WHERE
    s.x = s.c;
SELECT
    s.*
FROM (
    VALUES (1)) AS v (z)
    LEFT JOIN (
        SELECT
            123456 AS c, t1.f1 AS x
        FROM
            not_null_tab t1
        WHERE
            t1.f1 NOT IN (
                SELECT
                    t2.unique1
                FROM
                    tenk1 t2
                WHERE
                    t2.unique1 IS NOT NULL)) s ON TRUE
WHERE
    s.x = s.c;
ROLLBACK;

