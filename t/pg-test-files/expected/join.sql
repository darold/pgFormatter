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
    '' AS "xxx",
    *
FROM
    J1_TBL AS tx;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL tx;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL AS t1 (a,
        b,
        c);

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL t1 (a,
        b,
        c);

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL t1 (a,
        b,
        c),
    J2_TBL t2 (d,
        e);

SELECT
    '' AS "xxx",
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
    '' AS "xxx",
    *
FROM
    J1_TBL
    CROSS JOIN J2_TBL;

-- ambiguous column
SELECT
    '' AS "xxx",
    i,
    k,
    t
FROM
    J1_TBL
    CROSS JOIN J2_TBL;

-- resolve previous ambiguity by specifying the table name
SELECT
    '' AS "xxx",
    t1.i,
    k,
    t
FROM
    J1_TBL t1
    CROSS JOIN J2_TBL t2;

SELECT
    '' AS "xxx",
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
    '' AS "xxx",
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
    '' AS "xxx",
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
    '' AS "xxx",
    *
FROM
    J1_TBL
    INNER JOIN J2_TBL USING (i);

-- Same as above, slightly different syntax
SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    JOIN J2_TBL USING (i);

SELECT
    '' AS "xxx",
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
    '' AS "xxx",
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

--
-- NATURAL JOIN
-- Inner equi-join on all columns with the same name
--
SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    NATURAL JOIN J2_TBL;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL t1 (a,
        b,
        c)
    NATURAL JOIN J2_TBL t2 (a,
        d);

SELECT
    '' AS "xxx",
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
    '' AS "xxx",
    *
FROM
    J1_TBL t1 (a,
        b)
    NATURAL JOIN J2_TBL t2 (a);

--
-- Inner joins (equi-joins)
--
SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i = J2_TBL.i);

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i = J2_TBL.k);

--
-- Non-equi-joins
--
SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    JOIN J2_TBL ON (J1_TBL.i <= J2_TBL.k);

--
-- Outer joins
-- Note that OUTER is a noise word
--
SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    LEFT OUTER JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    LEFT JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    RIGHT OUTER JOIN J2_TBL USING (i);

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    RIGHT JOIN J2_TBL USING (i);

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    FULL OUTER JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    FULL JOIN J2_TBL USING (i)
ORDER BY
    i,
    k,
    t;

SELECT
    '' AS "xxx",
    *
FROM
    J1_TBL
    LEFT JOIN J2_TBL USING (i)
WHERE (k = 1);

SELECT
    '' AS "xxx",
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
    int4_tbl i4,
    tenk1 a
WHERE
    EXISTS (
        SELECT
            *
        FROM
            tenk1 b
        WHERE
            a.twothousand = b.twothousand
            AND a.fivethous <> b.fivethous)
    AND i4.f1 = a.tenthous;

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
    RIGHT JOIN b ON aa = unique1
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
    RIGHT JOIN b ON aa = unique1
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
-- regression test: check a case where join_clause_is_movable_into() gives
-- an imprecise result, causing an assertion failure
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
-- regression test for bug #13908 (hash join with skew tuples & nbatch increase)
--
SET work_mem TO '64kB';

SET enable_mergejoin TO OFF;

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

CREATE INDEX tt3i ON tt3 (f1);

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
            c.f1 IS NULL) AS d ON (a.f1 = d.f1)
WHERE
    d.f1 IS NULL;

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
            ss.y IS NOT NULL LIMIT 1)
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
            ss.y IS NOT NULL LIMIT 1)
ORDER BY
    1,
    2;

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
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
    JOIN int4_tbl ON f1 = twothousand,
    int4(sin(1)) q1,
    int4(sin(0)) q2
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
    int4(sin(1)) q1,
    int4(sin(0)) q2
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
        VALUES (1, 10), (2, 20)) AS v2 (v2x, v2y) ON v2x = v1x
    LEFT JOIN unnest(v1ys) AS u1 (u1y) ON u1y = v2y;

SELECT
    *
FROM (
    VALUES (1, ARRAY[10, 20]),
        (2, ARRAY[20, 30])) AS v1 (v1x, v1ys)
    LEFT JOIN (
        VALUES (1, 10), (2, 20)) AS v2 (v2x, v2y) ON v2x = v1x
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
                1 AS id) AS yy ON (a1.unique1 = yy.id)) ON (xx.id = coalesce(yy.id));

SELECT
    *
FROM (
    SELECT
        1 AS id) AS xx
    LEFT JOIN (tenk1 AS a1
        FULL JOIN (
            SELECT
                1 AS id) AS yy ON (a1.unique1 = yy.id)) ON (xx.id = coalesce(yy.id));

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
-- all three cases should be optimizable into a simple seqscan
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
            coalesce(i)
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
            coalesce(i)
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
                    WHERE
                        q1 = ANY (
                            SELECT
                                q2
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
                    WHERE
                        q1 = ANY (
                            SELECT
                                q2
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

-- validate logic in merge joins which skips mark and restore.
-- it should only do this if all quals which were used to detect the unique
-- are present as join quals, and not plain quals.
SET enable_nestloop TO 0;

SET enable_hashjoin TO 0;

SET enable_sort TO 0;

-- create indexes that will be preferred over the PKs to perform the join
CREATE INDEX j1_id1_idx ON j1 (id1)
WHERE
    id1 % 1000 = 1;

CREATE INDEX j2_id1_idx ON j2 (id1)
WHERE
    id1 % 1000 = 1;

-- need an additional row in j2, if we want j2_id1_idx to be preferred
INSERT INTO j2
    VALUES (1, 2);

ANALYZE j2;

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

