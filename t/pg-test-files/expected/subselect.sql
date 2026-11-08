--
-- SUBSELECT
--
SELECT
    1 AS one
WHERE
    1 IN (
        SELECT
            1);

SELECT
    1 AS zero
WHERE
    1 NOT IN (
        SELECT
            1);

SELECT
    1 AS zero
WHERE
    1 IN (
        SELECT
            2);

-- Check grammar's handling of extra parens in assorted contexts
SELECT
    *
FROM (
    SELECT
        1 AS x) ss;

SELECT
    *
FROM ((
        SELECT
            1 AS x)) ss;

SELECT
    *
FROM ((
        SELECT
            1 AS x)),
((
    SELECT
        *
    FROM ((
        SELECT
            2 AS y))));

(
    SELECT
        2)
UNION
SELECT
    2;

((
        SELECT
            2))
UNION
SELECT
    2;

SELECT
    ((
            SELECT
                2)
        UNION
        SELECT
            2);

SELECT
    ((
                SELECT
                    2)
        UNION
        SELECT
            2);

SELECT
    (
        SELECT
            ARRAY[1, 2, 3])[1];

SELECT
    ((
            SELECT
                ARRAY[1, 2, 3]))[2];

SELECT
    ((
                SELECT
                    ARRAY[1, 2, 3]))[3];

-- Set up some simple test tables
CREATE TABLE SUBSELECT_TBL (
    f1 integer,
    f2 integer,
    f3 float
);

INSERT INTO SUBSELECT_TBL
    VALUES (1, 2, 3);

INSERT INTO SUBSELECT_TBL
    VALUES (2, 3, 4);

INSERT INTO SUBSELECT_TBL
    VALUES (3, 4, 5);

INSERT INTO SUBSELECT_TBL
    VALUES (1, 1, 1);

INSERT INTO SUBSELECT_TBL
    VALUES (2, 2, 2);

INSERT INTO SUBSELECT_TBL
    VALUES (3, 3, 3);

INSERT INTO SUBSELECT_TBL
    VALUES (6, 7, 8);

INSERT INTO SUBSELECT_TBL
    VALUES (8, 9, NULL);

SELECT
    *
FROM
    SUBSELECT_TBL;

-- Uncorrelated subselects
SELECT
    f1 AS "Constant Select"
FROM
    SUBSELECT_TBL
WHERE
    f1 IN (
        SELECT
            1);

SELECT
    f1 AS "Uncorrelated Field"
FROM
    SUBSELECT_TBL
WHERE
    f1 IN (
        SELECT
            f2
        FROM
            SUBSELECT_TBL);

SELECT
    f1 AS "Uncorrelated Field"
FROM
    SUBSELECT_TBL
WHERE
    f1 IN (
        SELECT
            f2
        FROM
            SUBSELECT_TBL
        WHERE
            f2 IN (
                SELECT
                    f1
                FROM
                    SUBSELECT_TBL));

SELECT
    f1,
    f2
FROM
    SUBSELECT_TBL
WHERE (f1, f2)
NOT IN (
    SELECT
        f2,
        CAST(f3 AS int4)
    FROM
        SUBSELECT_TBL
    WHERE
        f3 IS NOT NULL);

-- Correlated subselects
SELECT
    f1 AS "Correlated Field",
    f2 AS "Second Field"
FROM
    SUBSELECT_TBL upper
WHERE
    f1 IN (
        SELECT
            f2
        FROM
            SUBSELECT_TBL
        WHERE
            f1 = upper.f1);

SELECT
    f1 AS "Correlated Field",
    f3 AS "Second Field"
FROM
    SUBSELECT_TBL upper
WHERE
    f1 IN (
        SELECT
            f2
        FROM
            SUBSELECT_TBL
        WHERE
            CAST(upper.f2 AS float) = f3);

SELECT
    f1 AS "Correlated Field",
    f3 AS "Second Field"
FROM
    SUBSELECT_TBL upper
WHERE
    f3 IN (
        SELECT
            upper.f1 + f2
        FROM
            SUBSELECT_TBL
        WHERE
            f2 = CAST(f3 AS integer));

SELECT
    f1 AS "Correlated Field"
FROM
    SUBSELECT_TBL
WHERE (f1, f2) IN (
    SELECT
        f2,
        CAST(f3 AS int4)
    FROM
        SUBSELECT_TBL
    WHERE
        f3 IS NOT NULL);

-- Check ROWCOMPARE cases, both correlated and not
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ROW (1,
        2) = (
        SELECT
            f1,
            f2) AS eq
FROM
    SUBSELECT_TBL;

SELECT
    ROW (1,
        2) = (
        SELECT
            f1,
            f2) AS eq
FROM
    SUBSELECT_TBL;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ROW (1,
        2) = (
        SELECT
            3,
            4) AS eq
FROM
    SUBSELECT_TBL;

SELECT
    ROW (1,
        2) = (
        SELECT
            3,
            4) AS eq
FROM
    SUBSELECT_TBL;

SELECT
    ROW (1,
        2) = (
        SELECT
            f1,
            f2
        FROM
            SUBSELECT_TBL);

-- error
-- Subselects without aliases
SELECT
    count
FROM (
    SELECT
        COUNT(DISTINCT name)
    FROM
        road);

SELECT
    COUNT(*)
FROM ( SELECT DISTINCT
        name
    FROM
        road);

SELECT
    *
FROM (
    SELECT
        *
    FROM
        int4_tbl),
(
    VALUES (123456))
WHERE
    f1 = column1;

CREATE VIEW view_unnamed_ss AS
SELECT
    *
FROM (
    SELECT
        *
    FROM (
        SELECT
            abs(f1) AS a1
        FROM
            int4_tbl)),
(
    SELECT
        *
    FROM
        int8_tbl)
WHERE
    a1 < 10
    AND q1 > a1
ORDER BY
    q1,
    q2;

SELECT
    *
FROM
    view_unnamed_ss;

\sv view_unnamed_ss
DROP VIEW view_unnamed_ss;

-- Test matching of locking clause to correct alias
CREATE VIEW view_unnamed_ss_locking AS
SELECT
    *
FROM (
    SELECT
        *
    FROM
        int4_tbl),
int8_tbl AS unnamed_subquery
WHERE
    f1 = q1
FOR UPDATE
    OF unnamed_subquery;

\sv view_unnamed_ss_locking
DROP VIEW view_unnamed_ss_locking;

--
-- Use some existing tables in the regression test
--
SELECT
    ss.f1 AS "Correlated Field",
    ss.f3 AS "Second Field"
FROM
    SUBSELECT_TBL ss
WHERE
    f1 NOT IN (
        SELECT
            f1 + 1
        FROM
            INT4_TBL
        WHERE
            f1 != ss.f1
            AND f1 < 2147483647);

SELECT
    q1,
    float8(count(*)) / (
        SELECT
            count(*)
        FROM
            int8_tbl)
FROM
    int8_tbl
GROUP BY
    q1
ORDER BY
    q1;

-- Unspecified-type literals in output columns should resolve as text
SELECT
    *,
    pg_typeof(f1)
FROM (
    SELECT
        'foo' AS f1
    FROM
        generate_series(1, 3)) ss
ORDER BY
    1;

-- ... unless there's context to suggest differently
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    '42'
UNION ALL
SELECT
    '43';

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    '42'
UNION ALL
SELECT
    43;

-- check materialization of an initplan reference (bug #14524)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    1 = ALL (
        SELECT
            (
                SELECT
                    1));

SELECT
    1 = ALL (
        SELECT
            (
                SELECT
                    1));

--
-- Check EXISTS simplification with LIMIT
--
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl o
WHERE
    EXISTS (
        SELECT
            1
        FROM
            int4_tbl i
        WHERE
            i.f1 = o.f1
        LIMIT NULL);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl o
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            int4_tbl i
        WHERE
            i.f1 = o.f1
        LIMIT 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl o
WHERE
    EXISTS (
        SELECT
            1
        FROM
            int4_tbl i
        WHERE
            i.f1 = o.f1
        LIMIT 0);

--
-- Test cases to catch unpleasant interactions between IN-join processing
-- and subquery pullup.
--
SELECT
    count(*)
FROM (
    SELECT
        1
    FROM
        tenk1 a
    WHERE
        unique1 IN (
            SELECT
                hundred
            FROM
                tenk1 b)) ss;

SELECT
    count(DISTINCT ss.ten)
FROM (
    SELECT
        ten
    FROM
        tenk1 a
    WHERE
        unique1 IN (
            SELECT
                hundred
            FROM
                tenk1 b)) ss;

SELECT
    count(*)
FROM (
    SELECT
        1
    FROM
        tenk1 a
    WHERE
        unique1 IN ( SELECT DISTINCT
                hundred
            FROM
                tenk1 b)) ss;

SELECT
    count(DISTINCT ss.ten)
FROM (
    SELECT
        ten
    FROM
        tenk1 a
    WHERE
        unique1 IN ( SELECT DISTINCT
                hundred
            FROM
                tenk1 b)) ss;

--
-- Test cases to check for overenthusiastic optimization of
-- "IN (SELECT DISTINCT ...)" and related cases.  Per example from
-- Luca Pireddu and Michael Fuhr.
--
CREATE TEMP TABLE foo (
    id integer
);

CREATE TEMP TABLE bar (
    id1 integer,
    id2 integer
);

INSERT INTO foo
    VALUES (1);

INSERT INTO bar
    VALUES (1, 1);

INSERT INTO bar
    VALUES (2, 2);

INSERT INTO bar
    VALUES (3, 1);

-- These cases require an extra level of distinct-ing above subquery s
SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM ( SELECT DISTINCT
                id1,
                id2
            FROM
                bar) AS s);

SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM (
            SELECT
                id1,
                id2
            FROM
                bar
            GROUP BY
                id1,
                id2) AS s);

SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM (
            SELECT
                id1,
                id2
            FROM
                bar
            UNION
            SELECT
                id1,
                id2
            FROM
                bar) AS s);

-- These cases do not
SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM ( SELECT DISTINCT ON (id2)
                id1,
                id2
            FROM
                bar) AS s);

SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM (
            SELECT
                id2
            FROM
                bar
            GROUP BY
                id2) AS s);

SELECT
    *
FROM
    foo
WHERE
    id IN (
        SELECT
            id2
        FROM (
            SELECT
                id2
            FROM
                bar
            UNION
            SELECT
                id2
            FROM
                bar) AS s);

--
-- Test case to catch problems with multiply nested sub-SELECTs not getting
-- recalculated properly.  Per bug report from Didier Moens.
--
CREATE TABLE orderstest (
    approver_ref integer,
    po_ref integer,
    ordercanceled boolean
);

INSERT INTO orderstest
    VALUES (1, 1, FALSE);

INSERT INTO orderstest
    VALUES (66, 5, FALSE);

INSERT INTO orderstest
    VALUES (66, 6, FALSE);

INSERT INTO orderstest
    VALUES (66, 7, FALSE);

INSERT INTO orderstest
    VALUES (66, 1, TRUE);

INSERT INTO orderstest
    VALUES (66, 8, FALSE);

INSERT INTO orderstest
    VALUES (66, 1, FALSE);

INSERT INTO orderstest
    VALUES (77, 1, FALSE);

INSERT INTO orderstest
    VALUES (1, 1, FALSE);

INSERT INTO orderstest
    VALUES (66, 1, FALSE);

INSERT INTO orderstest
    VALUES (1, 1, FALSE);

CREATE VIEW orders_view AS
SELECT
    *,
    (
        SELECT
            CASE WHEN ord.approver_ref = 1 THEN
                '---'
            ELSE
                'Approved'
            END) AS "Approved",
    (
        SELECT
            CASE WHEN ord.ordercanceled THEN
                'Canceled'
            ELSE
                (
                    SELECT
                        CASE WHEN ord.po_ref = 1 THEN
                        (
                            SELECT
                                CASE WHEN ord.approver_ref = 1 THEN
                                    '---'
                                ELSE
                                    'Approved'
                                END)
                        ELSE
                            'PO'
                        END)
            END) AS "Status",
    (
        CASE WHEN ord.ordercanceled THEN
            'Canceled'
        ELSE
            (
                CASE WHEN ord.po_ref = 1 THEN
                (
                    CASE WHEN ord.approver_ref = 1 THEN
                        '---'
                    ELSE
                        'Approved'
                    END)
                ELSE
                    'PO'
                END)
        END) AS "Status_OK"
FROM
    orderstest ord;

SELECT
    *
FROM
    orders_view;

DROP TABLE orderstest CASCADE;

--
-- Test cases to catch situations where rule rewriter fails to propagate
-- hasSubLinks flag correctly.  Per example from Kyle Bateman.
--
CREATE temp TABLE parts (
    partnum text,
    cost float8
);

CREATE temp TABLE shipped (
    ttype char(2),
    ordnum int4,
    partnum text,
    value float8
);

CREATE temp VIEW shipped_view AS
SELECT
    *
FROM
    shipped
WHERE
    ttype = 'wt';

CREATE RULE shipped_view_insert AS ON INSERT TO shipped_view
    DO INSTEAD
    INSERT INTO shipped VALUES ('wt', NEW.ordnum, NEW.partnum, NEW.value);

INSERT INTO parts (partnum, cost)
    VALUES (1, 1234.56);

INSERT INTO shipped_view (ordnum, partnum, value)
    VALUES (0, 1, (
            SELECT
                COST
            FROM parts
            WHERE
                partnum = '1'));

SELECT
    *
FROM
    shipped_view;

CREATE RULE shipped_view_update AS ON UPDATE
    TO shipped_view
        DO INSTEAD
        UPDATE
            shipped SET
            partnum = NEW.partnum,
            value = NEW.value WHERE
            ttype = NEW.ttype
            AND ordnum = NEW.ordnum;

UPDATE
    shipped_view
SET
    value = 11
FROM
    int4_tbl a
    JOIN int4_tbl b ON (a.f1 = (
            SELECT
                f1
            FROM
                int4_tbl c
            WHERE
                c.f1 = b.f1))
WHERE
    ordnum = a.f1;

SELECT
    *
FROM
    shipped_view;

SELECT
    f1,
    ss1 AS relabel
FROM (
    SELECT
        *,
        (
            SELECT
                sum(f1)
            FROM
                int4_tbl b
            WHERE
                f1 >= a.f1) AS ss1
        FROM
            int4_tbl a) ss;

--
-- Test cases involving PARAM_EXEC parameters and min/max index optimizations.
-- Per bug report from David Sanchez i Gregori.
--
SELECT
    *
FROM (
    SELECT
        max(unique1)
    FROM
        tenk1 AS a
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                tenk1 AS b
            WHERE
                b.thousand = a.unique2)) ss;

SELECT
    *
FROM (
    SELECT
        min(unique1)
    FROM
        tenk1 AS a
    WHERE
        NOT EXISTS (
            SELECT
                1
            FROM
                tenk1 AS b
            WHERE
                b.unique2 = 10000)) ss;

--
-- Test cases for interactions between PARAM_EXEC, subplans and array
-- subscripts
--
-- check that array subscription doesn't conflict with PARAM_EXEC (see #19370)
SELECT
    (ARRAY[1, 2])[(
        SELECT
            g.i)]
FROM
    generate_series(1, 1) g (i);

SELECT
    (ARRAY[1, 2])[(
        SELECT
            g.i) : (
        SELECT
            g.i + 1)]
FROM
    generate_series(1, 1) g (i);

--
-- Test that an IN implemented using a UniquePath does unique-ification
-- with the right semantics, as per bug #4113.  (Unfortunately we have
-- no simple way to ensure that this test case actually chooses that type
-- of plan, but it does in releases 7.4-8.3.  Note that an ordering difference
-- here might mean that some other plan type is being used, rendering the test
-- pointless.)
--
CREATE temp TABLE numeric_table (
    num_col numeric
);

INSERT INTO numeric_table
VALUES
    (1),
    (1.000000000000000000001),
    (2),
    (3);

CREATE temp TABLE float_table (
    float_col float8
);

INSERT INTO float_table
VALUES
    (1),
    (2),
    (3);

SELECT
    *
FROM
    float_table
WHERE
    float_col IN (
        SELECT
            num_col
        FROM
            numeric_table);

SELECT
    *
FROM
    numeric_table
WHERE
    num_col IN (
        SELECT
            float_col
        FROM
            float_table);

--
-- Test that a semijoin implemented by unique-ifying the RHS can explore
-- different paths of the RHS rel.
--
CREATE TABLE semijoin_unique_tbl (
    a int,
    b int
);

INSERT INTO semijoin_unique_tbl
SELECT
    i % 10,
    i % 10
FROM
    generate_series(1, 1000) i;

CREATE INDEX ON semijoin_unique_tbl (a, b);

ANALYZE semijoin_unique_tbl;

-- Ensure that we get a plan with Unique + IndexScan
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    semijoin_unique_tbl t1,
    semijoin_unique_tbl t2
WHERE (t1.a, t2.a) IN (
    SELECT
        a,
        b
    FROM
        semijoin_unique_tbl t3)
ORDER BY
    t1.a,
    t2.a;

-- Ensure that we can unique-ify expressions more complex than plain Vars
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    semijoin_unique_tbl t1,
    semijoin_unique_tbl t2
WHERE (t1.a, t2.a) IN (
    SELECT
        a + 1,
        b + 1
    FROM
        semijoin_unique_tbl t3)
ORDER BY
    t1.a,
    t2.a;

-- encourage use of parallel plans
SET parallel_setup_cost = 0;

SET parallel_tuple_cost = 0;

SET min_parallel_table_scan_size = 0;

SET max_parallel_workers_per_gather = 4;

SET enable_indexscan TO OFF;

-- Ensure that we get a parallel plan for the unique-ification
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    semijoin_unique_tbl t1,
    semijoin_unique_tbl t2
WHERE (t1.a, t2.a) IN (
    SELECT
        a,
        b
    FROM
        semijoin_unique_tbl t3)
ORDER BY
    t1.a,
    t2.a;

RESET enable_indexscan;

RESET max_parallel_workers_per_gather;

RESET min_parallel_table_scan_size;

RESET parallel_tuple_cost;

RESET parallel_setup_cost;

DROP TABLE semijoin_unique_tbl;

CREATE TABLE unique_tbl_p (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE unique_tbl_p1 PARTITION OF unique_tbl_p
FOR VALUES FROM (0) TO (5);

CREATE TABLE unique_tbl_p2 PARTITION OF unique_tbl_p
FOR VALUES FROM (5) TO (10);

CREATE TABLE unique_tbl_p3 PARTITION OF unique_tbl_p
FOR VALUES FROM (10) TO (20);

INSERT INTO unique_tbl_p
SELECT
    i % 12,
    i
FROM
    generate_series(0, 1000) i;

CREATE INDEX ON unique_tbl_p1 (a);

CREATE INDEX ON unique_tbl_p2 (a);

CREATE INDEX ON unique_tbl_p3 (a);

ANALYZE unique_tbl_p;

SET enable_partitionwise_join TO ON;

-- Ensure that the unique-ification works for partition-wise join
-- (Only one of the two joins will be done partitionwise, but that's good
-- enough for our purposes.)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    unique_tbl_p t1,
    unique_tbl_p t2
WHERE (t1.a, t2.a) IN (
    SELECT
        a,
        a
    FROM
        unique_tbl_p t3)
ORDER BY
    t1.a,
    t2.a;

RESET enable_partitionwise_join;

DROP TABLE unique_tbl_p;

--
-- Test case for bug #4290: bogus calculation of subplan param sets
--
CREATE temp TABLE ta (
    id int PRIMARY KEY,
    val int
);

INSERT INTO ta
    VALUES (1, 1);

INSERT INTO ta
    VALUES (2, 2);

CREATE temp TABLE tb (
    id int PRIMARY KEY,
    aval int
);

INSERT INTO tb
    VALUES (1, 1);

INSERT INTO tb
    VALUES (2, 1);

INSERT INTO tb
    VALUES (3, 2);

INSERT INTO tb
    VALUES (4, 2);

CREATE temp TABLE tc (
    id int PRIMARY KEY,
    aid int
);

INSERT INTO tc
    VALUES (1, 1);

INSERT INTO tc
    VALUES (2, 2);

SELECT
    (
        SELECT
            min(tb.id)
        FROM
            tb
        WHERE
            tb.aval = (
                SELECT
                    ta.val
                FROM
                    ta
                WHERE
                    ta.id = tc.aid)) AS min_tb_id
FROM
    tc;

--
-- Test case for 8.3 "failed to locate grouping columns" bug
--
CREATE temp TABLE t1 (
    f1 numeric(14, 0),
    f2 varchar(30)
);

SELECT
    *
FROM ( SELECT DISTINCT
        f1,
        f2,
        (
            SELECT
                f2
            FROM
                t1 x
            WHERE
                x.f1 = up.f1) AS fs
        FROM
            t1 up) ss
GROUP BY
    f1,
    f2,
    fs;

--
-- Test case for bug #5514 (mishandling of whole-row Vars in subselects)
--
CREATE temp TABLE table_a (
    id integer
);

INSERT INTO table_a
    VALUES (42);

CREATE temp VIEW view_a AS
SELECT
    *
FROM
    table_a;

SELECT
    view_a
FROM
    view_a;

SELECT
    (
        SELECT
            view_a)
FROM
    view_a;

SELECT
    (
        SELECT
            (
                SELECT
                    view_a))
    FROM
        view_a;

SELECT
    (
        SELECT
            (a.*)::text)
FROM
    view_a a;

--
-- Test case for bug #19037: no relation entry for relid N
--
EXPLAIN (
    COSTS OFF
)
SELECT
    (1 = ANY (array_agg(f1))) = ANY (
        SELECT
            FALSE)
FROM
    int4_tbl;

SELECT
    (1 = ANY (array_agg(f1))) = ANY (
        SELECT
            FALSE)
FROM
    int4_tbl;

--
-- Check that whole-row Vars reading the result of a subselect don't include
-- any junk columns therein
--
SELECT
    q
FROM (
    SELECT
        max(f1)
    FROM
        int4_tbl
    GROUP BY
        f1
    ORDER BY
        f1) q;

WITH q AS (
    SELECT
        max(f1)
    FROM
        int4_tbl
    GROUP BY
        f1
    ORDER BY
        f1
)
SELECT
    q
FROM
    q;

--
-- Test case for sublinks pulled up into joinaliasvars lists in an
-- inherited update/delete query
--
BEGIN;
--  this shouldn't delete anything, but be safe
DELETE FROM road
WHERE EXISTS (
        SELECT
            1
        FROM
            int4_tbl
        CROSS JOIN (
            SELECT
                f1,
                ARRAY(
                    SELECT
                        q1
                    FROM int8_tbl) AS arr
            FROM
                text_tbl) ss
        WHERE
            road.name = ss.f1);
ROLLBACK;

--
-- Test case for sublinks pushed down into subselects via join alias expansion
--
SELECT
    (
        SELECT
            sq1) AS qq1
FROM (
    SELECT
        EXISTS (
            SELECT
                1
            FROM
                int4_tbl
            WHERE
                f1 = q2) AS sq1,
        42 AS dummy
    FROM
        int8_tbl) sq0
    JOIN int4_tbl i4 ON dummy = i4.f1;

-- Likewise, but with the sublink inserted into a whole-row reference.
SELECT
    1
FROM ((
        SELECT
            (
                SELECT
                    1) AS x) ss1
        CROSS JOIN int4_tbl i4) j
WHERE (
    SELECT
        1
    WHERE
        j IS NULL) IS NULL;

SELECT
    1
FROM ((
        SELECT
            (
                SELECT
                    1) AS x) ss1
        CROSS JOIN int4_tbl i4) j
WHERE (1, 1) IN (
    SELECT
        (j IS NULL)::int,
        count(*)
    FROM
        int4_tbl);

SELECT
    1
FROM ((
        SELECT
            (
                SELECT
                    1) AS x) ss1
        CROSS JOIN int4_tbl i4) j
WHERE
    EXISTS (
        SELECT
            1
        FROM
            int4_tbl TABLESAMPLE SYSTEM ((j IS NULL)::int * 100));

--
-- Test case for subselect within UPDATE of INSERT...ON CONFLICT DO UPDATE
--
CREATE temp TABLE upsert (
    key int4 PRIMARY KEY,
    val text
);

INSERT INTO upsert
    VALUES (1, 'val')
ON CONFLICT (key)
    DO UPDATE SET
        val = 'not seen';

INSERT INTO upsert
    VALUES (1, 'val')
ON CONFLICT (key)
    DO UPDATE SET
        val = 'seen with subselect ' || (
            SELECT
                f1
            FROM
                int4_tbl
            WHERE
                f1 != 0
            LIMIT 1)::text;

SELECT
    *
FROM
    upsert;

WITH aa AS (
    SELECT
        'int4_tbl' u
    FROM
        int4_tbl
    LIMIT 1
)
INSERT INTO upsert
VALUES
    (1, 'x'),
    (999, 'y')
ON CONFLICT (key)
    DO UPDATE SET
        val = (
            SELECT
                u
            FROM
                aa)
    RETURNING
        *;

--
-- Test case for cross-type partial matching in hashed subplan (bug #7597)
--
CREATE temp TABLE outer_7597 (
    f1 int4,
    f2 int4
);

INSERT INTO outer_7597
    VALUES (0, 0);

INSERT INTO outer_7597
    VALUES (1, 0);

INSERT INTO outer_7597
    VALUES (0, NULL);

INSERT INTO outer_7597
    VALUES (1, NULL);

CREATE temp TABLE inner_7597 (
    c1 int8,
    c2 int8
);

INSERT INTO inner_7597
    VALUES (0, NULL);

SELECT
    *
FROM
    outer_7597
WHERE (f1, f2)
NOT IN (
    SELECT
        *
    FROM
        inner_7597);

--
-- Similar test case using text that verifies that collation
-- information is passed through by execTuplesEqual() in nodeSubplan.c
-- (otherwise it would error in texteq())
--
CREATE temp TABLE outer_text (
    f1 text,
    f2 text
);

INSERT INTO outer_text
    VALUES ('a', 'a');

INSERT INTO outer_text
    VALUES ('b', 'a');

INSERT INTO outer_text
    VALUES ('a', NULL);

INSERT INTO outer_text
    VALUES ('b', NULL);

CREATE temp TABLE inner_text (
    c1 text,
    c2 text
);

INSERT INTO inner_text
    VALUES ('a', NULL);

INSERT INTO inner_text
    VALUES ('123', '456');

SELECT
    *
FROM
    outer_text
WHERE (f1, f2)
NOT IN (
    SELECT
        *
    FROM
        inner_text);

--
-- Another test case for cross-type hashed subplans: comparison of
-- inner-side values must be done with appropriate operator
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    'foo'::text IN (
        SELECT
            'bar'::name
        UNION ALL
        SELECT
            'bar'::name);

SELECT
    'foo'::text IN (
        SELECT
            'bar'::name
        UNION ALL
        SELECT
            'bar'::name);

--
-- Test that we don't try to hash nested records (bug #17363)
-- (Hashing could be supported, but for now we don't)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ROW (ROW (ROW (1))) = ANY (
        SELECT
            ROW (ROW (1)));

SELECT
    ROW (ROW (ROW (1))) = ANY (
        SELECT
            ROW (ROW (1)));

--
-- Test case for premature memory release during hashing of subplan output
--
SELECT
    '1'::text IN (
        SELECT
            '1'::name
        UNION ALL
        SELECT
            '1'::name);

--
-- Test that we don't try to use a hashed subplan if the simplified
-- testexpr isn't of the right shape
--
-- this fails by default, of course
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);

BEGIN;
-- make an operator to allow it to succeed
CREATE FUNCTION bogus_int8_text_eq (int8, text)
    RETURNS boolean
    LANGUAGE sql
    AS '
    SELECT
        $1::text = $2;
';
CREATE OPERATOR = (
    PROCEDURE = bogus_int8_text_eq,
    LEFTARG = int8,
    RIGHTARG = text
);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
-- inlining of this function results in unusual number of hash clauses,
-- which we can still cope with
CREATE OR REPLACE FUNCTION bogus_int8_text_eq (int8, text)
    RETURNS boolean
    LANGUAGE sql
    AS '
    SELECT
        $1::text = $2
        AND $1::text = $2;
';
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
-- inlining of this function causes LHS and RHS to be switched,
-- which we can't cope with, so hashing should be abandoned
CREATE OR REPLACE FUNCTION bogus_int8_text_eq (int8, text)
    RETURNS boolean
    LANGUAGE sql
    AS '
    SELECT
        $2 = $1::text;
';
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
SELECT
    *
FROM
    int8_tbl
WHERE
    q1 IN (
        SELECT
            c1
        FROM
            inner_text);
ROLLBACK;

-- to get rid of the bogus operator
--
-- Test resolution of hashed vs non-hashed implementation of EXISTS subplan
--
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 t
WHERE (EXISTS (
        SELECT
            1
        FROM
            tenk1 k
        WHERE
            k.unique1 = t.unique2)
    OR ten < 0);

SELECT
    count(*)
FROM
    tenk1 t
WHERE (EXISTS (
        SELECT
            1
        FROM
            tenk1 k
        WHERE
            k.unique1 = t.unique2)
    OR ten < 0);

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 t
WHERE (EXISTS (
        SELECT
            1
        FROM
            tenk1 k
        WHERE
            k.unique1 = t.unique2)
    OR ten < 0)
AND thousand = 1;

SELECT
    count(*)
FROM
    tenk1 t
WHERE (EXISTS (
        SELECT
            1
        FROM
            tenk1 k
        WHERE
            k.unique1 = t.unique2)
    OR ten < 0)
AND thousand = 1;

-- It's possible for the same EXISTS to get resolved both ways
CREATE temp TABLE exists_tbl (
    c1 int,
    c2 int,
    c3 int
)
PARTITION BY LIST (c1);

CREATE temp TABLE exists_tbl_null PARTITION OF exists_tbl
FOR VALUES IN (NULL);

CREATE temp TABLE exists_tbl_def PARTITION OF exists_tbl DEFAULT;

INSERT INTO exists_tbl
SELECT
    x,
    x / 2,
    x + 1
FROM
    generate_series(0, 10) x;

ANALYZE exists_tbl;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    exists_tbl t1
WHERE (EXISTS (
        SELECT
            1
        FROM
            exists_tbl t2
        WHERE
            t1.c1 = t2.c2)
    OR c3 < 0);

SELECT
    *
FROM
    exists_tbl t1
WHERE (EXISTS (
        SELECT
            1
        FROM
            exists_tbl t2
        WHERE
            t1.c1 = t2.c2)
    OR c3 < 0);

--
-- Test case for planner bug with nested EXISTS handling
--
SELECT
    a.thousand
FROM
    tenk1 a,
    tenk1 b
WHERE
    a.thousand = b.thousand
    AND EXISTS (
        SELECT
            1
        FROM
            tenk1 c
        WHERE
            b.hundred = c.hundred
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    tenk1 d
                WHERE
                    a.thousand = d.thousand));

--
-- Check that nested sub-selects are not pulled up if they contain volatiles
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    x,
    x
FROM (
    SELECT
        (
            SELECT
                now()) AS x
        FROM (
            VALUES (1),
                (2)) v (y)) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    x,
    x
FROM (
    SELECT
        (
            SELECT
                random()) AS x
        FROM (
            VALUES (1),
                (2)) v (y)) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    x,
    x
FROM (
    SELECT
        (
            SELECT
                now()
            WHERE
                y = y) AS x
        FROM (
            VALUES (1),
                (2)) v (y)) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    x,
    x
FROM (
    SELECT
        (
            SELECT
                random()
            WHERE
                y = y) AS x
        FROM (
            VALUES (1),
                (2)) v (y)) ss;

--
-- Test rescan of a hashed subplan (the use of random() is to prevent the
-- sub-select from being pulled up, which would result in not hashing)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    sum(ss.tst::int)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            i.ten IN (
                SELECT
                    f1
                FROM
                    int4_tbl
                WHERE
                    f1 <= o.hundred) AS tst,
            random() AS r
        FROM
            onek i
        WHERE
            i.unique1 = o.unique1) ss
WHERE
    o.ten = 0;

SELECT
    sum(ss.tst::int)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            i.ten IN (
                SELECT
                    f1
                FROM
                    int4_tbl
                WHERE
                    f1 <= o.hundred) AS tst,
            random() AS r
        FROM
            onek i
        WHERE
            i.unique1 = o.unique1) ss
WHERE
    o.ten = 0;

--
-- Test rescan of a hashed subplan that is referenced more than once (here
-- the equivalence class produces two copies of it in the scan filter)
--
EXPLAIN (
    COSTS OFF
)
SELECT
    i4.f1,
    (
        SELECT
            count(*)
        FROM
            onek
        WHERE
            two = four
            AND two = (0 IN (
                    SELECT
                        i4.f1))::int)
FROM
    int4_tbl i4
ORDER BY
    i4.f1;

SELECT
    i4.f1,
    (
        SELECT
            count(*)
        FROM
            onek
        WHERE
            two = four
            AND two = (0 IN (
                    SELECT
                        i4.f1))::int)
FROM
    int4_tbl i4
ORDER BY
    i4.f1;

--
-- Test rescan of a hashed SetOp node
--
BEGIN;
SET local enable_groupagg = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            *
        FROM
            onek i1
        WHERE
            i1.unique1 = o.unique1
        EXCEPT
        SELECT
            *
        FROM
            onek i2
        WHERE
            i2.unique1 = o.unique2) ss
WHERE
    o.ten = 1;
SELECT
    count(*)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            *
        FROM
            onek i1
        WHERE
            i1.unique1 = o.unique1
        EXCEPT
        SELECT
            *
        FROM
            onek i2
        WHERE
            i2.unique1 = o.unique2) ss
WHERE
    o.ten = 1;
ROLLBACK;

--
-- Test rescan of a sorted SetOp node
--
BEGIN;
SET local enable_hashagg = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            *
        FROM
            onek i1
        WHERE
            i1.unique1 = o.unique1
        EXCEPT
        SELECT
            *
        FROM
            onek i2
        WHERE
            i2.unique1 = o.unique2) ss
WHERE
    o.ten = 1;
SELECT
    count(*)
FROM
    onek o
    CROSS JOIN LATERAL (
        SELECT
            *
        FROM
            onek i1
        WHERE
            i1.unique1 = o.unique1
        EXCEPT
        SELECT
            *
        FROM
            onek i2
        WHERE
            i2.unique1 = o.unique2) ss
WHERE
    o.ten = 1;
ROLLBACK;

--
-- Test rescan of a RecursiveUnion node
--
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(o.four),
    sum(ss.a)
FROM
    onek o
    CROSS JOIN LATERAL ( WITH RECURSIVE x (
            a
        ) AS (
            SELECT
                o.four AS a
        UNION
        SELECT
            a + 1
        FROM
            x
        WHERE
            a < 10
        )
        SELECT
            *
        FROM
            x) ss
WHERE
    o.ten = 1;

SELECT
    sum(o.four),
    sum(ss.a)
FROM
    onek o
    CROSS JOIN LATERAL ( WITH RECURSIVE x (
            a
        ) AS (
            SELECT
                o.four AS a
        UNION
        SELECT
            a + 1
        FROM
            x
        WHERE
            a < 10
        )
        SELECT
            *
        FROM
            x) ss
WHERE
    o.ten = 1;

--
-- Check we don't misoptimize a NOT IN where the subquery returns no rows.
--
CREATE temp TABLE notinouter (
    a int
);

CREATE temp TABLE notininner (
    b int NOT NULL
);

INSERT INTO notinouter
VALUES
    (NULL),
    (1);

SELECT
    *
FROM
    notinouter
WHERE
    a NOT IN (
        SELECT
            b
        FROM
            notininner);

--
-- Check we behave sanely in corner case of empty SELECT list (bug #8648)
--
CREATE temp TABLE nocolumns ();

SELECT
    EXISTS (
        SELECT
            *
        FROM
            nocolumns);

--
-- Check behavior with a SubPlan in VALUES (bug #14924)
--
SELECT
    val.x
FROM
    generate_series(1, 10) AS s (i),
    LATERAL (
        VALUES ((
                    SELECT
                        s.i + 1)),
                (s.i + 101)) AS val (x)
WHERE
    s.i < 10
    AND (
        SELECT
            val.x) < 110;

-- another variant of that (bug #16213)
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    VALUES (3 NOT IN (
                SELECT
                    *
                FROM (
                    VALUES (1), (2)) ss1)),
        (FALSE)) ss;

SELECT
    *
FROM (
    VALUES (3 NOT IN (
                SELECT
                    *
                FROM (
                    VALUES (1), (2)) ss1)),
        (FALSE)) ss;

--
-- Check sane behavior with nested IN SubLinks
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl
WHERE (
    CASE WHEN f1 IN (
        SELECT
            unique1
        FROM
            tenk1 a) THEN
        f1
    ELSE
        NULL
    END) IN (
        SELECT
            ten
        FROM
            tenk1 b);

SELECT
    *
FROM
    int4_tbl
WHERE (
    CASE WHEN f1 IN (
        SELECT
            unique1
        FROM
            tenk1 a) THEN
        f1
    ELSE
        NULL
    END) IN (
        SELECT
            ten
        FROM
            tenk1 b);

--
-- Check for incorrect optimization when IN subquery contains a SRF
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl o
WHERE (f1, f1) IN (
    SELECT
        f1,
        generate_series(1, 50) / 10 g
    FROM
        int4_tbl i
    GROUP BY
        f1);

SELECT
    *
FROM
    int4_tbl o
WHERE (f1, f1) IN (
    SELECT
        f1,
        generate_series(1, 50) / 10 g
    FROM
        int4_tbl i
    GROUP BY
        f1);

--
-- check for over-optimization of whole-row Var referencing an Append plan
--
SELECT
    (
        SELECT
            q
        FROM (
            SELECT
                1,
                2,
                3
            WHERE
                f1 > 0
            UNION ALL
            SELECT
                4,
                5,
                6.0
            WHERE
                f1 <= 0) q)
FROM
    int4_tbl;

--
-- Check for sane handling of a lateral reference in a subquery's quals
-- (most of the complication here is to prevent the test case from being
-- flattened too much)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    int4_tbl i4,
    LATERAL (
        SELECT
            i4.f1 > 1 AS b,
            1 AS id
        FROM (
            SELECT
                random()
            ORDER BY
                1) AS t1
        UNION ALL
        SELECT
            TRUE AS b,
            2 AS id) AS t2
    WHERE
        b
        AND f1 >= 0;

SELECT
    *
FROM
    int4_tbl i4,
    LATERAL (
        SELECT
            i4.f1 > 1 AS b,
            1 AS id
        FROM (
            SELECT
                random()
            ORDER BY
                1) AS t1
        UNION ALL
        SELECT
            TRUE AS b,
            2 AS id) AS t2
    WHERE
        b
        AND f1 >= 0;

--
-- Check that volatile quals aren't pushed down past a DISTINCT:
-- nextval() should not be called more than the nominal number of times
--
CREATE temp SEQUENCE ts1;

SELECT
    *
FROM ( SELECT DISTINCT
        ten
    FROM
        tenk1) ss
WHERE
    ten < 10 + nextval('ts1')
ORDER BY
    1;

SELECT
    nextval('ts1');

--
-- Check that volatile quals aren't pushed down past a set-returning function;
-- while a nonvolatile qual can be, if it doesn't reference the SRF.
--
CREATE FUNCTION tattle (x int, y int)
    RETURNS bool VOLATILE
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'x = %, y = %', x, y;
    RETURN x > y;
END
$$;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, 8);

SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, 8);

-- if we pretend it's stable, we get different results:
ALTER FUNCTION tattle (x int, y int) STABLE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, 8);

SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, 8);

-- although even a stable qual should not be pushed down if it references SRF
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, u);

SELECT
    *
FROM (
    SELECT
        9 AS x,
        unnest(ARRAY[1, 2, 3, 11, 12, 13]) AS u) ss
WHERE
    tattle (x, u);

--
-- check that an upper-level qual is not pushed down if it references a grouped
-- Var whose underlying expression contains SRFs
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        generate_series(1, ten) AS g,
        count(*)
    FROM
        tenk1
    GROUP BY
        1) ss
WHERE
    ss.g = 1;

SELECT
    *
FROM (
    SELECT
        generate_series(1, ten) AS g,
        count(*)
    FROM
        tenk1
    GROUP BY
        1) ss
WHERE
    ss.g = 1;

--
-- check that an upper-level qual is not pushed down if it references a grouped
-- Var whose underlying expression contains volatile functions
--
ALTER FUNCTION tattle (x int, y int) VOLATILE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        tattle (3, ten) AS v,
        count(*)
    FROM
        tenk1
    WHERE
        unique1 < 3
    GROUP BY
        1) ss
WHERE
    ss.v;

SELECT
    *
FROM (
    SELECT
        tattle (3, ten) AS v,
        count(*)
    FROM
        tenk1
    WHERE
        unique1 < 3
    GROUP BY
        1) ss
WHERE
    ss.v;

-- if we pretend it's stable, we get different results:
ALTER FUNCTION tattle (x int, y int) STABLE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        tattle (3, ten) AS v,
        count(*)
    FROM
        tenk1
    WHERE
        unique1 < 3
    GROUP BY
        1) ss
WHERE
    ss.v;

SELECT
    *
FROM (
    SELECT
        tattle (3, ten) AS v,
        count(*)
    FROM
        tenk1
    WHERE
        unique1 < 3
    GROUP BY
        1) ss
WHERE
    ss.v;

DROP FUNCTION tattle (x int, y int);

--
-- check that an upper-level qual is not pushed down if its operator is from a
-- different btree opfamily than the subquery's grouping eqop
--
BEGIN;
CREATE TYPE t_rec AS (
    x numeric
);
CREATE TEMP TABLE pdt (
    id int,
    a t_rec
);
INSERT INTO pdt
VALUES
    (1, ROW (1.00)::t_rec),
    (2, ROW (1.0)::t_rec),
    (3, ROW (2)::t_rec);
-- DISTINCT ON: conflict, qual stays in outer query
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ( SELECT DISTINCT ON (a)
        id,
        a
    FROM
        pdt
    ORDER BY
        a,
        id) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM ( SELECT DISTINCT ON (a)
        id,
        a
    FROM
        pdt
    ORDER BY
        a,
        id) s
WHERE
    a *= ROW (1.0)::t_rec;
-- Window function PARTITION BY: conflict, qual stays outside the WindowAgg
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        id,
        a,
        count(*) OVER (PARTITION BY a) AS cnt
    FROM
        pdt) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM (
    SELECT
        id,
        a,
        count(*) OVER (PARTITION BY a) AS cnt
    FROM
        pdt) s
WHERE
    a *= ROW (1.0)::t_rec;
-- Plain DISTINCT: conflict, qual stays in outer query
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ( SELECT DISTINCT
        a
    FROM
        pdt) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM ( SELECT DISTINCT
        a
    FROM
        pdt) s
WHERE
    a *= ROW (1.0)::t_rec;
-- Positive: compatible opfamily, safe to push past the grouping
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ( SELECT DISTINCT ON (a)
        id,
        a
    FROM
        pdt
    ORDER BY
        a,
        id) s
WHERE
    a = ROW (1.0)::t_rec;
SELECT
    *
FROM ( SELECT DISTINCT ON (a)
        id,
        a
    FROM
        pdt
    ORDER BY
        a,
        id) s
WHERE
    a = ROW (1.0)::t_rec;
-- Simple CASE: the arg is compared by each WHEN, so the same rules apply.
-- The relabeled arg is compared by oid's =, not the grouping eqop.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ( SELECT DISTINCT
        id
    FROM
        pdt) s
WHERE (
    CASE id::oid
    WHEN 1 THEN
        1
    ELSE
        0
    END) = 1;
-- Positive: compatible opfamily, safe to push past the grouping
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ( SELECT DISTINCT
        id
    FROM
        pdt) s
WHERE (
    CASE id
    WHEN 1 THEN
        1
    ELSE
        0
    END) = 1;
-- Set operations: any operation other than UNION ALL groups rows by equality,
-- so the same opfamily-mismatch rules apply.
CREATE TEMP TABLE u1 (
    a t_rec
);
CREATE TEMP TABLE u2 (
    a t_rec
);
INSERT INTO u1
VALUES
    (ROW (1.00)::t_rec),
    (ROW (1.0)::t_rec);
INSERT INTO u2
    VALUES (ROW (1.0)::t_rec);
-- UNION: conflict, qual stays in outer query
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    UNION
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    UNION
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
-- INTERSECT: same
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    INTERSECT
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    INTERSECT
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
-- INTERSECT ALL: still groups
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    INTERSECT ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    INTERSECT ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
-- UNION ALL of (UNION ...): an inner grouping node still exposes the
-- conflict to a qual pushed down through the outer UNION ALL.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM ((
        SELECT
            a
        FROM
            u1
        UNION
        SELECT
            a
        FROM
            u2)
    UNION ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM ((
        SELECT
            a
        FROM
            u1
        UNION
        SELECT
            a
        FROM
            u2)
    UNION ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
-- UNION ALL only: no grouping anywhere, pushdown remains allowed.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    UNION ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
SELECT
    *
FROM (
    SELECT
        a
    FROM
        u1
    UNION ALL
    SELECT
        a
    FROM
        u2) s
WHERE
    a *= ROW (1.0)::t_rec;
ROLLBACK;

--
-- Test that LIMIT can be pushed to SORT through a subquery that just projects
-- columns.  We check for that having happened by looking to see if EXPLAIN
-- ANALYZE shows that a top-N sort was used.  We must suppress or filter away
-- all the non-invariant parts of the EXPLAIN ANALYZE output.
--
CREATE TABLE sq_limit (
    pk int PRIMARY KEY,
    c1 int,
    c2 int
);

INSERT INTO sq_limit
VALUES
    (1, 1, 1),
    (2, 2, 2),
    (3, 3, 3),
    (4, 4, 4),
    (5, 1, 1),
    (6, 2, 2),
    (7, 3, 3),
    (8, 4, 4);

CREATE FUNCTION explain_sq_limit ()
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE
    ln text;
BEGIN
    FOR ln IN EXPLAIN (
        ANALYZE,
        summary OFF,
        timing OFF,
        COSTS OFF,
        buffers OFF
)
    SELECT
        *
    FROM (
        SELECT
            pk,
            c2
        FROM
            sq_limit
        ORDER BY
            c1,
            pk) AS x
LIMIT 3 LOOP
    ln := regexp_replace(ln, 'Memory: \S*', 'Memory: xxx');
    RETURN NEXT ln;
END LOOP;
END;
$$;

SELECT
    *
FROM
    explain_sq_limit ();

SELECT
    *
FROM (
    SELECT
        pk,
        c2
    FROM
        sq_limit
    ORDER BY
        c1,
        pk) AS x
LIMIT 3;

DROP FUNCTION explain_sq_limit ();

DROP TABLE sq_limit;

--
-- Ensure that backward scan direction isn't propagated into
-- expression subqueries (bug #15336)
--
BEGIN;
DECLARE c1 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        generate_series(1, 4) i
WHERE
    i <> ALL (
        VALUES (2),
            (3));
MOVE FORWARD ALL IN c1;
FETCH BACKWARD ALL IN c1;
COMMIT;

--
-- Check that JsonConstructorExpr is treated as non-strict, and thus can be
-- wrapped in a PlaceHolderVar
--
BEGIN;
CREATE temp TABLE json_tab (
    a int
);
INSERT INTO json_tab
    VALUES (1);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    json_tab t1
    LEFT JOIN (
        SELECT
            json_array (1, a)
        FROM
            json_tab t2) s ON FALSE;
SELECT
    *
FROM
    json_tab t1
    LEFT JOIN (
        SELECT
            json_array (1, a)
        FROM
            json_tab t2) s ON FALSE;
ROLLBACK;

--
-- Verify that we correctly flatten cases involving a subquery output
-- expression that doesn't need to be wrapped in a PlaceHolderVar
--
EXPLAIN (
    COSTS OFF
)
SELECT
    tname,
    attname
FROM (
    SELECT
        relname::information_schema.sql_identifier AS tname,
        *
    FROM (
        SELECT
            *
        FROM
            pg_class c) ss1) ss2
    RIGHT JOIN pg_attribute a ON a.attrelid = ss2.oid
WHERE
    tname = 'tenk1'
    AND attnum = 1;

SELECT
    tname,
    attname
FROM (
    SELECT
        relname::information_schema.sql_identifier AS tname,
        *
    FROM (
        SELECT
            *
        FROM
            pg_class c) ss1) ss2
    RIGHT JOIN pg_attribute a ON a.attrelid = ss2.oid
WHERE
    tname = 'tenk1'
    AND attnum = 1;

-- Check behavior when there's a lateral reference in the output expression
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.ten,
    sum(x)
FROM
    tenk1 t1
    LEFT JOIN LATERAL (
        SELECT
            t1.ten + t2.ten AS x,
            t2.fivethous
        FROM
            tenk1 t2) ss ON t1.unique1 = ss.fivethous
GROUP BY
    t1.ten
ORDER BY
    t1.ten;

SELECT
    t1.ten,
    sum(x)
FROM
    tenk1 t1
    LEFT JOIN LATERAL (
        SELECT
            t1.ten + t2.ten AS x,
            t2.fivethous
        FROM
            tenk1 t2) ss ON t1.unique1 = ss.fivethous
GROUP BY
    t1.ten
ORDER BY
    t1.ten;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q1 + t3.q1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q1 + t3.q1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

-- strict expressions containing variables of rels under the same lowest
-- nulling outer join can escape being wrapped
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN LATERAL (
            SELECT
                t2.q1 + 1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN LATERAL (
            SELECT
                t2.q1 + 1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

-- otherwise we need to wrap the strict expressions
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q1 + 1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q1 + 1 AS x,
                *
            FROM
                int8_tbl t3) t3 ON t2.q2 = t3.q2) ON t1.q2 = t2.q2
ORDER BY
    1,
    2;

-- lateral references for simple Vars can escape being wrapped if the
-- referenced rel is under the same lowest nulling outer join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN LATERAL (
            SELECT
                t2.q2 AS x,
                *
            FROM
                int8_tbl t3) ss ON t2.q2 = ss.q1) ON t1.q1 = t2.q1
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        INNER JOIN LATERAL (
            SELECT
                t2.q2 AS x,
                *
            FROM
                int8_tbl t3) ss ON t2.q2 = ss.q1) ON t1.q1 = t2.q1
ORDER BY
    1,
    2;

-- otherwise we need to wrap the Vars
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q2 AS x,
                *
            FROM
                int8_tbl t3) ss ON t2.q2 = ss.q1) ON t1.q1 = t2.q1
ORDER BY
    1,
    2;

SELECT
    t1.q1,
    x
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN LATERAL (
            SELECT
                t2.q2 AS x,
                *
            FROM
                int8_tbl t3) ss ON t2.q2 = ss.q1) ON t1.q1 = t2.q1
ORDER BY
    1,
    2;

-- lateral references for PHVs can also escape being wrapped if the
-- referenced rel is under the same lowest nulling outer join
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss2.*
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN (
            SELECT
                coalesce(q1, q1) AS x,
                *
            FROM
                int8_tbl t3) ss1 ON t2.q1 = ss1.q2
            INNER JOIN LATERAL (
                SELECT
                    ss1.x AS y,
                    *
                FROM
                    int8_tbl t4) ss2 ON t2.q2 = ss2.q1) ON t1.q2 = ss2.q1
ORDER BY
    1,
    2,
    3;

SELECT
    ss2.*
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN (
            SELECT
                coalesce(q1, q1) AS x,
                *
            FROM
                int8_tbl t3) ss1 ON t2.q1 = ss1.q2
            INNER JOIN LATERAL (
                SELECT
                    ss1.x AS y,
                    *
                FROM
                    int8_tbl t4) ss2 ON t2.q2 = ss2.q1) ON t1.q2 = ss2.q1
ORDER BY
    1,
    2,
    3;

-- otherwise we need to wrap the PHVs
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    ss2.*
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN (
            SELECT
                coalesce(q1, q1) AS x,
                *
            FROM
                int8_tbl t3) ss1 ON t2.q1 = ss1.q2
            LEFT JOIN LATERAL (
                SELECT
                    ss1.x AS y,
                    *
                FROM
                    int8_tbl t4) ss2 ON t2.q2 = ss2.q1) ON t1.q2 = ss2.q1
ORDER BY
    1,
    2,
    3;

SELECT
    ss2.*
FROM
    int8_tbl t1
    LEFT JOIN (int8_tbl t2
        LEFT JOIN (
            SELECT
                coalesce(q1, q1) AS x,
                *
            FROM
                int8_tbl t3) ss1 ON t2.q1 = ss1.q2
            LEFT JOIN LATERAL (
                SELECT
                    ss1.x AS y,
                    *
                FROM
                    int8_tbl t4) ss2 ON t2.q2 = ss2.q1) ON t1.q2 = ss2.q1
ORDER BY
    1,
    2,
    3;

--
-- Tests for CTE inlining behavior
--
-- Basic subquery that can be inlined
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM (
        SELECT
            f1
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x
WHERE
    f1 = 1;

-- Explicitly request materialization
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS MATERIALIZED (
    SELECT
        *
    FROM (
        SELECT
            f1
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x
WHERE
    f1 = 1;

-- Stable functions are safe to inline
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM (
        SELECT
            f1,
            now()
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x
WHERE
    f1 = 1;

-- Volatile functions prevent inlining
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM (
        SELECT
            f1,
            random()
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x
WHERE
    f1 = 1;

-- SELECT FOR UPDATE cannot be inlined
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM (
        SELECT
            f1
        FROM
            subselect_tbl
        FOR UPDATE) ss
)
SELECT
    *
FROM
    x
WHERE
    f1 = 1;

-- Multiply-referenced CTEs are inlined only when requested
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM (
        SELECT
            f1,
            now() AS n
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x,
    x x2
WHERE
    x.n = x2.n;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS NOT MATERIALIZED (
    SELECT
        *
    FROM (
        SELECT
            f1,
            now() AS n
        FROM
            subselect_tbl) ss
)
SELECT
    *
FROM
    x,
    x x2
WHERE
    x.n = x2.n;

-- Multiply-referenced CTEs can't be inlined if they contain outer self-refs
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH RECURSIVE x (a)
AS ((
        VALUES ('a'),
            ('b'))
    UNION ALL ( WITH z AS NOT MATERIALIZED (
            SELECT
                *
            FROM
                x
            )
            SELECT
                z.a || z1.a AS a
            FROM
                z
            CROSS JOIN z AS z1
        WHERE
            length(z.a || z1.a) < 5))
SELECT
    *
FROM
    x;

WITH RECURSIVE x (
    a
) AS ((
        VALUES ('a'),
            ('b'))
    UNION ALL ( WITH z AS NOT MATERIALIZED (
            SELECT
                *
            FROM
                x
            )
            SELECT
                z.a || z1.a AS a
            FROM
                z
            CROSS JOIN z AS z1
        WHERE
            length(
                z.a || z1.a
            ) < 5
        ))
SELECT
    *
FROM
    x;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH RECURSIVE x (a)
AS ((
        VALUES ('a'),
            ('b'))
    UNION ALL ( WITH z AS NOT MATERIALIZED (
            SELECT
                *
            FROM
                x
            )
            SELECT
                z.a || z.a AS a
            FROM
                z
            WHERE
                length(z.a || z.a) < 5))
SELECT
    *
FROM
    x;

WITH RECURSIVE x (
    a
) AS ((
        VALUES ('a'),
            ('b'))
    UNION ALL ( WITH z AS NOT MATERIALIZED (
            SELECT
                *
            FROM
                x
            )
            SELECT
                z.a || z.a AS a
            FROM
                z
            WHERE
                length(
                    z.a || z.a
                ) < 5
            ))
SELECT
    *
FROM
    x;

-- Check handling of outer references
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM
        int4_tbl
    )
SELECT
    *
FROM ( WITH y AS (
        SELECT
            *
        FROM
            x
    )
    SELECT
        *
    FROM
        y) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS MATERIALIZED (
    SELECT
        *
    FROM
        int4_tbl
)
SELECT
    *
FROM ( WITH y AS (
        SELECT
            *
        FROM
            x
    )
    SELECT
        *
    FROM
        y) ss;

-- Ensure that we inline the correct CTE when there are
-- multiple CTEs with the same name
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        1 AS y
)
SELECT
    *
FROM ( WITH x AS (
        SELECT
            2 AS y
    )
    SELECT
        *
    FROM
        x) ss;

-- Row marks are not pushed into CTEs
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH x AS (
    SELECT
        *
    FROM
        subselect_tbl
)
SELECT
    *
FROM
    x
FOR UPDATE;

-- Pull up direct-correlated ANY_SUBLINKs
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
WHERE
    hundred IN (
        SELECT
            hundred
        FROM
            tenk2 B
        WHERE
            B.odd = A.odd);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tenk2 B
        WHERE
            A.hundred IN (
                SELECT
                    C.hundred
                FROM
                    tenk2 C
                WHERE
                    c.odd = b.odd));

-- we should only try to pull up the sublink into RHS of a left join
-- but a.hundred is not available.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
    LEFT JOIN tenk2 B ON A.hundred IN (
        SELECT
            c.hundred
        FROM
            tenk2 C
        WHERE
            c.odd = b.odd);

-- we should only try to pull up the sublink into RHS of a left join
-- but a.odd is not available for this.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
    LEFT JOIN tenk2 B ON B.hundred IN (
        SELECT
            c.hundred
        FROM
            tenk2 C
        WHERE
            c.odd = a.odd);

-- should be able to pull up since all the references are available.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
    LEFT JOIN tenk2 B ON B.hundred IN (
        SELECT
            c.hundred
        FROM
            tenk2 C
        WHERE
            c.odd = b.odd);

-- we can pull up the sublink into the inner JoinExpr.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
    INNER JOIN tenk2 B ON A.hundred IN (
        SELECT
            c.hundred
        FROM
            tenk2 C
        WHERE
            c.odd = b.odd)
WHERE
    a.thousand < 750;

-- we can pull up the aggregate sublink into RHS of a left join.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 A
    LEFT JOIN tenk2 B ON B.hundred IN (
        SELECT
            min(c.hundred)
        FROM
            tenk2 C
        WHERE
            c.odd = b.odd);

--
-- Test VALUES to ARRAY (VtA) transformation
--
-- VtA transformation for joined VALUES is not supported
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek,
    (
        VALUES ('RFAAAA'),
            ('VJAAAA')) AS v (i)
WHERE
    onek.stringu1 = v.i;

-- VtA transformation for a composite argument is not supported
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek
WHERE (unique1, ten) IN (
    VALUES (1, 1),
        (20, 0),
        (99, 9),
        (17, 99))
ORDER BY
    unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek
WHERE
    unique1 IN (
        VALUES (10000),
            (2),
            (389),
            (1000),
            (2000),
            (10029))
    ORDER BY
        unique1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek
WHERE
    unique1 IN (
        VALUES (1200),
            (1));

-- Recursive evaluation of constant queries is not yet supported
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek
WHERE
    unique1 IN (
        SELECT
            x * x
        FROM (
            VALUES (1200),
                (1)) AS x (x));

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    stringu1
FROM
    onek
WHERE
    stringu1::name IN (
        VALUES ('RFAAAA'),
            ('VJAAAA'));

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    stringu1
FROM
    onek
WHERE
    stringu1::text IN (
        VALUES ('RFAAAA'),
            ('VJAAAA'));

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek
WHERE
    unique1 IN (
        VALUES (1200::bigint),
            (1));

-- VtA shouldn't depend on the side of the join probing with the VALUES expression.
EXPLAIN (
    COSTS OFF
)
SELECT
    c.unique1,
    c.ten
FROM
    tenk1 c
    JOIN onek a USING (ten)
WHERE
    a.ten IN (
        VALUES (1),
            (2));

EXPLAIN (
    COSTS OFF
)
SELECT
    c.unique1,
    c.ten
FROM
    tenk1 c
    JOIN onek a USING (ten)
WHERE
    c.ten IN (
        VALUES (1),
            (2));

-- Constant expressions are simplified
EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek
WHERE
    sin(two) + four IN (
        VALUES (sin(0.5)),
            (2));

EXPLAIN (
    COSTS OFF
)
-- VtA allows NULLs in the list
SELECT
    ten
FROM
    onek
WHERE
    sin(two) + four IN (
        VALUES (sin(0.5)),
            (NULL),
            (2));

-- VtA is supported for custom plans where params are substituted with
-- constants.  VtA is not supported with generic plans where params prevent
-- us from building a constant array.
PREPARE test (int, numeric, text) AS
SELECT
    ten
FROM
    onek
WHERE
    sin(two) * four / ($3::real) IN (
        VALUES (sin($2)),
            (2),
            ($1));

EXPLAIN (
    COSTS OFF
) EXECUTE test (42, 3.14, '-1.5');

EXPLAIN (
    COSTS OFF
) EXECUTE test (NULL, 3.14, NULL);

EXPLAIN (
    COSTS OFF
) EXECUTE test (NULL, 3.14, '-1.5');

SET plan_cache_mode = 'force_generic_plan';

EXPLAIN (
    COSTS OFF
) EXECUTE test (NULL, 3.14, '-1.5');

RESET plan_cache_mode;

--  VtA doesn't support LIMIT, OFFSET, and ORDER BY clauses
EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek
WHERE
    unique1 IN (
        VALUES (1),
            (2)
            OFFSET 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek
WHERE
    unique1 IN (
        VALUES (1),
            (2)
        ORDER BY
            1);

EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek
WHERE
    unique1 IN (
        VALUES (1),
            (2)
        LIMIT 1);

EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek t
WHERE
    unique1 IN (
        VALUES (0),
            ((2 IN (
                    SELECT
                        unique2
                    FROM onek c
                    WHERE
                        c.unique2 = t.unique1))::integer));

EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek t
WHERE
    unique1 IN (
        VALUES (0),
            ((2 IN (
                    SELECT
                        unique2
                    FROM onek c
                    WHERE
                        c.unique2 IN (
                            VALUES (sin(0.5)), (2))))::integer));

-- VtA is not allowed with subqueries
EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek t
WHERE
    unique1 IN (
        VALUES (0),
            ((2 IN (
                    SELECT
                        (3)))::integer));

-- VtA is not allowed with non-constant expressions
EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek t
WHERE
    unique1 IN (
        VALUES (0),
            (unique2));

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek t1,
    LATERAL (
        SELECT
            *
        FROM
            onek t2
        WHERE
            t2.ten IN (
                VALUES (t1.ten),
                    (1)));

-- VtA causes the whole expression to be evaluated as a constant
EXPLAIN (
    COSTS OFF
)
SELECT
    ten
FROM
    onek t
WHERE
    1.0::integer IN ((
        VALUES (1), (3)));

--
-- Check NOT IN performs an ANTI JOIN when both the outer query's expressions
-- and the sub-select's output columns are provably non-nullable, and the
-- operator itself cannot return NULL for non-null inputs.
--
BEGIN;
CREATE TEMP TABLE not_null_tab (
    id int NOT NULL,
    val int NOT NULL
);
CREATE TEMP TABLE null_tab (
    id int,
    val int
);
-- ANTI JOIN: both sides are defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- No ANTI JOIN: outer side is nullable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- No ANTI JOIN: inner side is nullable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            null_tab);
-- ANTI JOIN: outer side is defined NOT NULL, inner side is forced nonnullable
-- by qual clause
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            null_tab
        WHERE
            id IS NOT NULL);
-- No ANTI JOIN: outer side is nullable (we don't check outer query quals for now)
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    null_tab
WHERE
    id IS NOT NULL
    AND id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- ANTI JOIN: outer side is defined NOT NULL, inner side is defined NOT NULL
-- and is not nulled by outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            t1.id
        FROM
            not_null_tab t1
        LEFT JOIN not_null_tab t2 ON t1.id = t2.id);
-- No ANTI JOIN: inner side is defined NOT NULL but is nulled by outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            t2.id
        FROM
            not_null_tab t1
        LEFT JOIN not_null_tab t2 ON t1.id = t2.id);
-- ANTI JOIN: outer side is defined NOT NULL, inner side is forced nonnullable
-- by qual clause
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            t2.id
        FROM
            not_null_tab t1
        LEFT JOIN not_null_tab t2 ON t1.id = t2.id
    WHERE
        t2.id IS NOT NULL);
-- ANTI JOIN: outer side is defined NOT NULL, inner side is forced nonnullable
-- by qual clause
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            t1.id
        FROM
            null_tab t1
        LEFT JOIN null_tab t2 ON t1.id = t2.id
    WHERE
        t1.id IS NOT NULL);
-- ANTI JOIN: outer side is defined NOT NULL, inner side is forced nonnullable
-- by qual clause
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            t1.id
        FROM
            null_tab t1
            INNER JOIN null_tab t2 ON t1.id = t2.id
            LEFT JOIN null_tab t3 ON TRUE);
-- ANTI JOIN: outer side is defined NOT NULL and is not nulled by outer join,
-- inner side is defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab t1
    LEFT JOIN not_null_tab t2 ON t1.id = t2.id
WHERE
    t1.id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- No ANTI JOIN: outer side is nulled by outer join
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab t1
    LEFT JOIN not_null_tab t2 ON t1.id = t2.id
WHERE
    t2.id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- No ANTI JOIN: sublink is in an outer join's ON qual and references the
-- non-nullable side
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab t1
    LEFT JOIN not_null_tab t2 ON t1.id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- ANTI JOIN: outer side is defined NOT NULL and is not nulled by outer join,
-- inner side is defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab t1
    LEFT JOIN not_null_tab t2 ON t2.id NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
-- ANTI JOIN: both sides are defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE (id, val)
NOT IN (
    SELECT
        id,
        val
    FROM
        not_null_tab);
-- ANTI JOIN: both sides are defined NOT NULL
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    NOT (id, val) > ANY (
        SELECT
            id,
            val
        FROM
            not_null_tab);
-- No ANTI JOIN: one column of the outer side is nullable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab t1,
    null_tab t2
WHERE (t1.id, t2.id)
NOT IN (
    SELECT
        id,
        val
    FROM
        not_null_tab);
-- No ANTI JOIN: one column of the inner side is nullable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE (id, val)
NOT IN (
    SELECT
        t1.id,
        t2.id
    FROM
        not_null_tab t1,
        null_tab t2);
-- ANTI JOIN: COALESCE(nullable, constant) is non-nullable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    null_tab
WHERE
    COALESCE(id, -1)
    NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            COALESCE(id, -1)
        FROM
            null_tab);
-- ANTI JOIN: GROUP BY (without Grouping Sets) preserves the non-nullability of
-- the column
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            not_null_tab
        GROUP BY
            id);
-- No ANTI JOIN: GROUP BY on a nullable column
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            null_tab
        GROUP BY
            id);
-- No ANTI JOIN: Grouping Sets can introduce NULLs
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            not_null_tab
        GROUP BY
            GROUPING SETS ((id),
                (val)));
-- create a custom "unsafe" equality operator
CREATE FUNCTION int4eq_unsafe (int4, int4)
    RETURNS bool
    AS 'int4eq'
    LANGUAGE internal
    IMMUTABLE;
CREATE OPERATOR ?= (
    PROCEDURE = int4eq_unsafe,
    LEFTARG = int4,
    RIGHTARG = int4
);
-- No ANTI JOIN: the operator is not safe
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    NOT id ?= ANY (
        SELECT
            id
        FROM
            not_null_tab);
-- No ANTI JOIN: the inner side has an unvalidated NOT NULL constraint, so
-- the column might contain NULLs.
CREATE TEMP TABLE notnull_notvalid_tab (
    id int
);
INSERT INTO notnull_notvalid_tab
    VALUES (NULL);
ALTER TABLE notnull_notvalid_tab
    ADD CONSTRAINT nn NOT NULL id NOT VALID;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            notnull_notvalid_tab);
-- NOT IN with NULL on inner side should return no rows
SELECT
    *
FROM
    not_null_tab
WHERE
    id NOT IN (
        SELECT
            id
        FROM
            notnull_notvalid_tab);
-- No ANTI JOIN: the sub-select's output is an upper-level Var, so the
-- sub-select's own quals tell us nothing about its nullability
INSERT INTO null_tab
    VALUES (1, NULL);
INSERT INTO not_null_tab
    VALUES (2, 2);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    null_tab t1
WHERE
    COALESCE(t1.id, -1)
    NOT IN (
        SELECT
            t1.val
        FROM
            not_null_tab t2
        WHERE
            t2.val IS NOT NULL);
-- NOT IN with NULL on inner side should return no rows
SELECT
    *
FROM
    null_tab t1
WHERE
    COALESCE(t1.id, -1)
    NOT IN (
        SELECT
            t1.val
        FROM
            not_null_tab t2
        WHERE
            t2.val IS NOT NULL);
-- No ANTI JOIN: the inner operand is coerced by a cast function that can
-- return NULL for a non-null input
CREATE FUNCTION int4_to_text_nullable (int4)
    RETURNS text
    AS '
    SELECT
        CASE WHEN $1 <> 0 THEN
            $1::varchar
        END;
'
LANGUAGE sql
IMMUTABLE STRICT;
CREATE CAST (int4 AS text) WITH FUNCTION int4_to_text_nullable (int4) AS IMPLICIT;
CREATE TEMP TABLE not_null_text_tab (
    t text NOT NULL
);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    not_null_text_tab
WHERE
    t NOT IN (
        SELECT
            id
        FROM
            not_null_tab);
ROLLBACK;

