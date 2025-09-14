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
FROM (
        SELECT
            1 AS x) ss;

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
    (
            SELECT
                ARRAY[1, 2, 3])[2];

SELECT
    (
                SELECT
                    ARRAY[1, 2, 3])[3];

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
    '' AS eight,
    *
FROM
    SUBSELECT_TBL;

-- Uncorrelated subselects
SELECT
    '' AS two,
    f1 AS "Constant Select"
FROM
    SUBSELECT_TBL
WHERE
    f1 IN (
        SELECT
            1);

SELECT
    '' AS six,
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
    '' AS six,
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
    '' AS three,
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
    '' AS six,
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
    '' AS six,
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
    '' AS six,
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
    '' AS five,
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

--
-- Use some existing tables in the regression test
--
SELECT
    '' AS eight,
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
                ARRAY (
                    SELECT
                        q1
                    FROM
                        int8_tbl) AS arr
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
    LIMIT 1)
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
        VALUES (
                    SELECT
                        s.i + 1),
                (s.i + 101)) AS val (x)
WHERE
    s.i < 10
    AND (
        SELECT
            val.x) < 110;

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

DROP FUNCTION tattle (x int, y int);

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
        COSTS OFF
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
    -- this case might occur if force_parallel_mode is on:
    ln := regexp_replace(ln, 'Worker 0:  Sort Method', 'Sort Method');
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

-- Ensure that we inline the currect CTE when there are
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

