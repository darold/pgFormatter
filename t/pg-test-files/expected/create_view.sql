--
-- CREATE_VIEW
-- Virtual class definitions
--	(this also tests the query rewrite system)
--
CREATE VIEW street AS
SELECT
    r.name,
    r.thepath,
    c.cname AS cname
FROM
    ONLY road r,
    real_city c
WHERE
    c.outline ## r.thepath;

CREATE VIEW iexit AS
SELECT
    ih.name,
    ih.thepath,
    interpt_pp (ih.thepath, r.thepath) AS exit
FROM
    ihighway ih,
    ramp r
WHERE
    ih.thepath ## r.thepath;

CREATE VIEW toyemp AS
SELECT
    name,
    age,
    location,
    12 * salary AS annualsal
FROM
    emp;

-- Test comments
COMMENT ON VIEW noview IS 'no view';

COMMENT ON VIEW toyemp IS 'is a view';

COMMENT ON VIEW toyemp IS NULL;

-- These views are left around mainly to exercise special cases in pg_dump.
CREATE TABLE view_base_table (
    key int PRIMARY KEY,
    data varchar(20)
);

CREATE VIEW key_dependent_view AS
SELECT
    *
FROM
    view_base_table
GROUP BY
    key;

ALTER TABLE view_base_table
    DROP CONSTRAINT view_base_table_pkey;

-- fails
CREATE VIEW key_dependent_view_no_cols AS
SELECT
FROM
    view_base_table
GROUP BY
    key
HAVING
    length(data) > 0;

--
-- CREATE OR REPLACE VIEW
--
CREATE OR REPLACE VIEW viewtest AS
SELECT
    *
FROM
    viewtest_tbl;

CREATE OR REPLACE VIEW viewtest AS
SELECT
    *
FROM
    viewtest_tbl
WHERE
    a > 10;

SELECT
    *
FROM
    viewtest;

CREATE OR REPLACE VIEW viewtest AS
SELECT
    a,
    b
FROM
    viewtest_tbl
WHERE
    a > 5
ORDER BY
    b DESC;

SELECT
    *
FROM
    viewtest;

-- should fail
CREATE OR REPLACE VIEW viewtest AS
SELECT
    a
FROM
    viewtest_tbl
WHERE
    a <> 20;

-- should fail
CREATE OR REPLACE VIEW viewtest AS
SELECT
    1,
    *
FROM
    viewtest_tbl;

-- should fail
CREATE OR REPLACE VIEW viewtest AS
SELECT
    a,
    b::numeric
FROM
    viewtest_tbl;

-- should work
CREATE OR REPLACE VIEW viewtest AS
SELECT
    a,
    b,
    0 AS c
FROM
    viewtest_tbl;

DROP VIEW viewtest;

DROP TABLE viewtest_tbl;

-- tests for temporary views
CREATE SCHEMA temp_view_test
    CREATE TABLE base_table (
        a int,
        id int)
    CREATE TABLE base_table2 (
        a int,
        id int
);

SET search_path TO temp_view_test, public;

CREATE TEMPORARY TABLE temp_table (
    a int,
    id int
);

-- should be created in temp_view_test schema
CREATE VIEW v1 AS
SELECT
    *
FROM
    base_table;

-- should be created in temp object schema
CREATE VIEW v1_temp AS
SELECT
    *
FROM
    temp_table;

-- should be created in temp object schema
CREATE TEMP VIEW v2_temp AS
SELECT
    *
FROM
    base_table;

-- should be created in temp_views schema
CREATE VIEW temp_view_test.v2 AS
SELECT
    *
FROM
    base_table;

-- should fail
CREATE VIEW temp_view_test.v3_temp AS
SELECT
    *
FROM
    temp_table;

-- should fail
CREATE SCHEMA test_view_schema
    CREATE TEMP VIEW testview AS
    SELECT
        1;

-- joins: if any of the join relations are temporary, the view
-- should also be temporary
-- should be non-temp
CREATE VIEW v3 AS
SELECT
    t1.a AS t1_a,
    t2.a AS t2_a
FROM
    base_table t1,
    base_table2 t2
WHERE
    t1.id = t2.id;

-- should be temp (one join rel is temp)
CREATE VIEW v4_temp AS
SELECT
    t1.a AS t1_a,
    t2.a AS t2_a
FROM
    base_table t1,
    temp_table t2
WHERE
    t1.id = t2.id;

-- should be temp
CREATE VIEW v5_temp AS
SELECT
    t1.a AS t1_a,
    t2.a AS t2_a,
    t3.a AS t3_a
FROM
    base_table t1,
    base_table2 t2,
    temp_table t3
WHERE
    t1.id = t2.id
    AND t2.id = t3.id;

-- subqueries
CREATE VIEW v4 AS
SELECT
    *
FROM
    base_table
WHERE
    id IN (
        SELECT
            id
        FROM
            base_table2);

CREATE VIEW v5 AS
SELECT
    t1.id,
    t2.a
FROM
    base_table t1,
    (
        SELECT
            *
        FROM
            base_table2) t2;

CREATE VIEW v6 AS
SELECT
    *
FROM
    base_table
WHERE
    EXISTS (
        SELECT
            1
        FROM
            base_table2);

CREATE VIEW v7 AS
SELECT
    *
FROM
    base_table
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            base_table2);

CREATE VIEW v8 AS
SELECT
    *
FROM
    base_table
WHERE
    EXISTS (
        SELECT
            1);

CREATE VIEW v6_temp AS
SELECT
    *
FROM
    base_table
WHERE
    id IN (
        SELECT
            id
        FROM
            temp_table);

CREATE VIEW v7_temp AS
SELECT
    t1.id,
    t2.a
FROM
    base_table t1,
    (
        SELECT
            *
        FROM
            temp_table) t2;

CREATE VIEW v8_temp AS
SELECT
    *
FROM
    base_table
WHERE
    EXISTS (
        SELECT
            1
        FROM
            temp_table);

CREATE VIEW v9_temp AS
SELECT
    *
FROM
    base_table
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            temp_table);

-- a view should also be temporary if it references a temporary view
CREATE VIEW v10_temp AS
SELECT
    *
FROM
    v7_temp;

CREATE VIEW v11_temp AS
SELECT
    t1.id,
    t2.a
FROM
    base_table t1,
    v10_temp t2;

CREATE VIEW v12_temp AS
SELECT
    TRUE
FROM
    v11_temp;

-- a view should also be temporary if it references a temporary sequence
CREATE SEQUENCE seq1;

CREATE TEMPORARY SEQUENCE seq1_temp;

CREATE VIEW v9 AS
SELECT
    seq1.is_called
FROM
    seq1;

CREATE VIEW v13_temp AS
SELECT
    seq1_temp.is_called
FROM
    seq1_temp;

SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'v_'
    AND relnamespace = (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname = 'temp_view_test')
ORDER BY
    relname;

SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'v%'
    AND relnamespace IN (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname LIKE 'pg_temp%')
ORDER BY
    relname;

CREATE SCHEMA testviewschm2;

SET search_path TO testviewschm2, public;

CREATE TABLE t1 (
    num int,
    name text
);

CREATE TABLE t2 (
    num2 int,
    value text
);

CREATE TEMP TABLE tt (
    num2 int,
    value text
);

CREATE VIEW nontemp1 AS
SELECT
    *
FROM
    t1
    CROSS JOIN t2;

CREATE VIEW temporal1 AS
SELECT
    *
FROM
    t1
    CROSS JOIN tt;

CREATE VIEW nontemp2 AS
SELECT
    *
FROM
    t1
    INNER JOIN t2 ON t1.num = t2.num2;

CREATE VIEW temporal2 AS
SELECT
    *
FROM
    t1
    INNER JOIN tt ON t1.num = tt.num2;

CREATE VIEW nontemp3 AS
SELECT
    *
FROM
    t1
    LEFT JOIN t2 ON t1.num = t2.num2;

CREATE VIEW temporal3 AS
SELECT
    *
FROM
    t1
    LEFT JOIN tt ON t1.num = tt.num2;

CREATE VIEW nontemp4 AS
SELECT
    *
FROM
    t1
    LEFT JOIN t2 ON t1.num = t2.num2
        AND t2.value = 'xxx';

CREATE VIEW temporal4 AS
SELECT
    *
FROM
    t1
    LEFT JOIN tt ON t1.num = tt.num2
        AND tt.value = 'xxx';

SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'nontemp%'
    AND relnamespace = (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname = 'testviewschm2')
ORDER BY
    relname;

SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'temporal%'
    AND relnamespace IN (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname LIKE 'pg_temp%')
ORDER BY
    relname;

CREATE TABLE tbl1 (
    a int,
    b int
);

CREATE TABLE tbl2 (
    c int,
    d int
);

CREATE TABLE tbl3 (
    e int,
    f int
);

CREATE TABLE tbl4 (
    g int,
    h int
);

CREATE TEMP TABLE tmptbl (
    i int,
    j int
);

--Should be in testviewschm2
CREATE VIEW pubview AS
SELECT
    *
FROM
    tbl1
WHERE
    tbl1.a BETWEEN (
        SELECT
            d
        FROM
            tbl2
        WHERE
            c = 1)
    AND (
        SELECT
            e
        FROM
            tbl3
        WHERE
            f = 2)
    AND EXISTS (
        SELECT
            g
        FROM
            tbl4
        LEFT JOIN tbl3 ON tbl4.h = tbl3.f);

SELECT
    count(*)
FROM
    pg_class
WHERE
    relname = 'pubview'
    AND relnamespace IN (
        SELECT
            OID
        FROM
            pg_namespace
        WHERE
            nspname = 'testviewschm2');

--Should be in temp object schema
CREATE VIEW mytempview AS
SELECT
    *
FROM
    tbl1
WHERE
    tbl1.a BETWEEN (
        SELECT
            d
        FROM
            tbl2
        WHERE
            c = 1)
    AND (
        SELECT
            e
        FROM
            tbl3
        WHERE
            f = 2)
    AND EXISTS (
        SELECT
            g
        FROM
            tbl4
        LEFT JOIN tbl3 ON tbl4.h = tbl3.f)
    AND NOT EXISTS (
        SELECT
            g
        FROM
            tbl4
    LEFT JOIN tmptbl ON tbl4.h = tmptbl.j);

SELECT
    count(*)
FROM
    pg_class
WHERE
    relname LIKE 'mytempview'
    AND relnamespace IN (
        SELECT
            OID
        FROM
            pg_namespace
        WHERE
            nspname LIKE 'pg_temp%');

--
-- CREATE VIEW and WITH(...) clause
--
CREATE VIEW mysecview1 AS
SELECT
    *
FROM
    tbl1
WHERE
    a = 0;

CREATE VIEW mysecview2 WITH ( security_barrier = TRUE
) AS
SELECT
    *
FROM
    tbl1
WHERE
    a > 0;

CREATE VIEW mysecview3 WITH ( security_barrier = FALSE
) AS
SELECT
    *
FROM
    tbl1
WHERE
    a < 0;

CREATE VIEW mysecview4 WITH ( security_barrier
) AS
SELECT
    *
FROM
    tbl1
WHERE
    a <> 0;

CREATE VIEW mysecview5 WITH ( security_barrier = 100) -- Error
AS
SELECT
    *
FROM
    tbl1
WHERE
    a > 100;

CREATE VIEW mysecview6 WITH ( invalid_option) -- Error
AS
SELECT
    *
FROM
    tbl1
WHERE
    a < 100;

SELECT
    relname,
    relkind,
    reloptions
FROM
    pg_class
WHERE
    oid IN ('mysecview1'::regclass, 'mysecview2'::regclass, 'mysecview3'::regclass, 'mysecview4'::regclass)
ORDER BY
    relname;

CREATE OR REPLACE VIEW mysecview1 AS
SELECT
    *
FROM
    tbl1
WHERE
    a = 256;

CREATE OR REPLACE VIEW mysecview2 AS
SELECT
    *
FROM
    tbl1
WHERE
    a > 256;

CREATE OR REPLACE VIEW mysecview3 WITH ( security_barrier = TRUE
) AS
SELECT
    *
FROM
    tbl1
WHERE
    a < 256;

CREATE OR REPLACE VIEW mysecview4 WITH ( security_barrier = FALSE
) AS
SELECT
    *
FROM
    tbl1
WHERE
    a <> 256;

SELECT
    relname,
    relkind,
    reloptions
FROM
    pg_class
WHERE
    oid IN ('mysecview1'::regclass, 'mysecview2'::regclass, 'mysecview3'::regclass, 'mysecview4'::regclass)
ORDER BY
    relname;

-- Check that unknown literals are converted to "text" in CREATE VIEW,
-- so that we don't end up with unknown-type columns.
CREATE VIEW unspecified_types AS
SELECT
    42 AS i,
    42.5 AS num,
    'foo' AS u,
    'foo'::unknown AS u2,
    NULL AS n;

\d+ unspecified_types
SELECT
    *
FROM
    unspecified_types;

-- This test checks that proper typmods are assigned in a multi-row VALUES
CREATE VIEW tt1 AS
SELECT
    *
FROM (
    VALUES ('abc'::varchar(3),
            '0123456789',
            42,
            'abcd'::varchar(4)),
        ('0123456789', 'abc'::varchar(3),
            42.12,
            'abc'::varchar(4))) vv (a, b, c, d);

\d+ tt1
SELECT
    *
FROM
    tt1;

SELECT
    a::varchar(3)
FROM
    tt1;

DROP VIEW tt1;

-- Test view decompilation in the face of relation renaming conflicts
CREATE TABLE tt1 (
    f1 int,
    f2 int,
    f3 text
);

CREATE TABLE tx1 (
    x1 int,
    x2 int,
    x3 text
);

CREATE TABLE temp_view_test.tt1 (
    y1 int,
    f2 int,
    f3 text
);

CREATE VIEW aliased_view_1 AS
SELECT
    *
FROM
    tt1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tx1
        WHERE
            tt1.f1 = tx1.x1);

CREATE VIEW aliased_view_2 AS
SELECT
    *
FROM
    tt1 a1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tx1
        WHERE
            a1.f1 = tx1.x1);

CREATE VIEW aliased_view_3 AS
SELECT
    *
FROM
    tt1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tx1 a2
        WHERE
            tt1.f1 = a2.x1);

CREATE VIEW aliased_view_4 AS
SELECT
    *
FROM
    temp_view_test.tt1
WHERE
    EXISTS (
        SELECT
            1
        FROM
            tt1
        WHERE
            temp_view_test.tt1.y1 = tt1.f1);

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
ALTER TABLE tx1 RENAME TO a1;

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
ALTER TABLE tt1 RENAME TO a2;

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
ALTER TABLE a1 RENAME TO tt1;

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
ALTER TABLE a2 RENAME TO tx1;

ALTER TABLE tx1 SET SCHEMA temp_view_test;

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
ALTER TABLE temp_view_test.tt1 RENAME TO tmp1;

ALTER TABLE temp_view_test.tmp1 SET SCHEMA testviewschm2;

ALTER TABLE tmp1 RENAME TO tx1;

\d+ aliased_view_1
\d+ aliased_view_2
\d+ aliased_view_3
\d+ aliased_view_4
-- Test view decompilation in the face of column addition/deletion/renaming
CREATE TABLE tt2 (
    a int,
    b int,
    c int
);

CREATE TABLE tt3 (
    ax int8,
    b int2,
    c numeric
);

CREATE TABLE tt4 (
    ay int,
    b int,
    q int
);

CREATE VIEW v1 AS
SELECT
    *
FROM
    tt2
    NATURAL JOIN tt3;

CREATE VIEW v1a AS
SELECT
    *
FROM (tt2
    NATURAL JOIN tt3) j;

CREATE VIEW v2 AS
SELECT
    *
FROM
    tt2
    JOIN tt3 USING (b, c)
    JOIN tt4 USING (b);

CREATE VIEW v2a AS
SELECT
    *
FROM (tt2
    JOIN tt3 USING (b, c)
    JOIN tt4 USING (b)) j;

CREATE VIEW v3 AS
SELECT
    *
FROM
    tt2
    JOIN tt3 USING (b, c)
    FULL JOIN tt4 USING (b);

SELECT
    pg_get_viewdef('v1', TRUE);

SELECT
    pg_get_viewdef('v1a', TRUE);

SELECT
    pg_get_viewdef('v2', TRUE);

SELECT
    pg_get_viewdef('v2a', TRUE);

SELECT
    pg_get_viewdef('v3', TRUE);

ALTER TABLE tt2
    ADD COLUMN d int;

ALTER TABLE tt2
    ADD COLUMN e int;

SELECT
    pg_get_viewdef('v1', TRUE);

SELECT
    pg_get_viewdef('v1a', TRUE);

SELECT
    pg_get_viewdef('v2', TRUE);

SELECT
    pg_get_viewdef('v2a', TRUE);

SELECT
    pg_get_viewdef('v3', TRUE);

ALTER TABLE tt3 RENAME c TO d;

SELECT
    pg_get_viewdef('v1', TRUE);

SELECT
    pg_get_viewdef('v1a', TRUE);

SELECT
    pg_get_viewdef('v2', TRUE);

SELECT
    pg_get_viewdef('v2a', TRUE);

SELECT
    pg_get_viewdef('v3', TRUE);

ALTER TABLE tt3
    ADD COLUMN c int;

ALTER TABLE tt3
    ADD COLUMN e int;

SELECT
    pg_get_viewdef('v1', TRUE);

SELECT
    pg_get_viewdef('v1a', TRUE);

SELECT
    pg_get_viewdef('v2', TRUE);

SELECT
    pg_get_viewdef('v2a', TRUE);

SELECT
    pg_get_viewdef('v3', TRUE);

ALTER TABLE tt2
    DROP COLUMN d;

SELECT
    pg_get_viewdef('v1', TRUE);

SELECT
    pg_get_viewdef('v1a', TRUE);

SELECT
    pg_get_viewdef('v2', TRUE);

SELECT
    pg_get_viewdef('v2a', TRUE);

SELECT
    pg_get_viewdef('v3', TRUE);

CREATE TABLE tt5 (
    a int,
    b int
);

CREATE TABLE tt6 (
    c int,
    d int
);

CREATE VIEW vv1 AS
SELECT
    *
FROM (tt5
    CROSS JOIN tt6) j (aa,
        bb,
        cc,
        dd);

SELECT
    pg_get_viewdef('vv1', TRUE);

ALTER TABLE tt5
    ADD COLUMN c int;

SELECT
    pg_get_viewdef('vv1', TRUE);

ALTER TABLE tt5
    ADD COLUMN cc int;

SELECT
    pg_get_viewdef('vv1', TRUE);

ALTER TABLE tt5
    DROP COLUMN c;

SELECT
    pg_get_viewdef('vv1', TRUE);

-- Unnamed FULL JOIN USING is lots of fun too
CREATE TABLE tt7 (
    x int,
    xx int,
    y int
);

ALTER TABLE tt7
    DROP COLUMN xx;

CREATE TABLE tt8 (
    x int,
    z int
);

CREATE VIEW vv2 AS
SELECT
    *
FROM (
    VALUES (1, 2, 3, 4, 5)) v (a, b, c, d, e)
UNION ALL
SELECT
    *
FROM
    tt7
    FULL JOIN tt8 USING (x),
    tt8 tt8x;

SELECT
    pg_get_viewdef('vv2', TRUE);

CREATE VIEW vv3 AS
SELECT
    *
FROM (
    VALUES (1, 2, 3, 4, 5, 6)) v (a, b, c, x, e, f)
UNION ALL
SELECT
    *
FROM
    tt7
    FULL JOIN tt8 USING (x),
    tt7 tt7x
    FULL JOIN tt8 tt8x USING (x);

SELECT
    pg_get_viewdef('vv3', TRUE);

CREATE VIEW vv4 AS
SELECT
    *
FROM (
    VALUES (1, 2, 3, 4, 5, 6, 7)) v (a, b, c, x, e, f, g)
UNION ALL
SELECT
    *
FROM
    tt7
    FULL JOIN tt8 USING (x),
    tt7 tt7x
    FULL JOIN tt8 tt8x USING (x)
    FULL JOIN tt8 tt8y USING (x);

SELECT
    pg_get_viewdef('vv4', TRUE);

ALTER TABLE tt7
    ADD COLUMN zz int;

ALTER TABLE tt7
    ADD COLUMN z int;

ALTER TABLE tt7
    DROP COLUMN zz;

ALTER TABLE tt8
    ADD COLUMN z2 int;

SELECT
    pg_get_viewdef('vv2', TRUE);

SELECT
    pg_get_viewdef('vv3', TRUE);

SELECT
    pg_get_viewdef('vv4', TRUE);

-- Implicit coercions in a JOIN USING create issues similar to FULL JOIN
CREATE TABLE tt7a (
    x date,
    xx int,
    y int
);

ALTER TABLE tt7a
    DROP COLUMN xx;

CREATE TABLE tt8a (
    x timestamptz,
    z int
);

CREATE VIEW vv2a AS
SELECT
    *
FROM (
    VALUES (now(),
            2,
            3,
            now(),
            5)) v (a, b, c, d, e)
UNION ALL
SELECT
    *
FROM
    tt7a
    LEFT JOIN tt8a USING (x),
    tt8a tt8ax;

SELECT
    pg_get_viewdef('vv2a', TRUE);

--
-- Also check dropping a column that existed when the view was made
--
CREATE TABLE tt9 (
    x int,
    xx int,
    y int
);

CREATE TABLE tt10 (
    x int,
    z int
);

CREATE VIEW vv5 AS
SELECT
    x,
    y,
    z
FROM
    tt9
    JOIN tt10 USING (x);

SELECT
    pg_get_viewdef('vv5', TRUE);

ALTER TABLE tt9
    DROP COLUMN xx;

SELECT
    pg_get_viewdef('vv5', TRUE);

--
-- Another corner case is that we might add a column to a table below a
-- JOIN USING, and thereby make the USING column name ambiguous
--
CREATE TABLE tt11 (
    x int,
    y int
);

CREATE TABLE tt12 (
    x int,
    z int
);

CREATE TABLE tt13 (
    z int,
    q int
);

CREATE VIEW vv6 AS
SELECT
    x,
    y,
    z,
    q
FROM (tt11
    JOIN tt12 USING (x))
JOIN tt13 USING (z);

SELECT
    pg_get_viewdef('vv6', TRUE);

ALTER TABLE tt11
    ADD COLUMN z int;

SELECT
    pg_get_viewdef('vv6', TRUE);

--
-- Check cases involving dropped/altered columns in a function's rowtype result
--
CREATE TABLE tt14t (
    f1 text,
    f2 text,
    f3 text,
    f4 text
);

INSERT INTO tt14t
    VALUES ('foo', 'bar', 'baz', '42');

ALTER TABLE tt14t
    DROP COLUMN f2;

CREATE FUNCTION tt14f ()
    RETURNS SETOF tt14t
    AS $$
DECLARE
    rec1 record;
BEGIN
    FOR rec1 IN
    SELECT
        *
    FROM
        tt14t LOOP
            RETURN NEXT rec1;
        END LOOP;
END;
$$
LANGUAGE plpgsql;

CREATE VIEW tt14v AS
SELECT
    t.*
FROM
    tt14f () t;

SELECT
    pg_get_viewdef('tt14v', TRUE);

SELECT
    *
FROM
    tt14v;

BEGIN;
-- this perhaps should be rejected, but it isn't:
ALTER TABLE tt14t
    DROP COLUMN f3;
-- f3 is still in the view ...
SELECT
    pg_get_viewdef('tt14v', TRUE);
-- but will fail at execution
SELECT
    f1,
    f4
FROM
    tt14v;
SELECT
    *
FROM
    tt14v;
ROLLBACK;

BEGIN;
-- this perhaps should be rejected, but it isn't:
ALTER TABLE tt14t
    ALTER COLUMN f4 TYPE integer
    USING f4::integer;
-- f4 is still in the view ...
SELECT
    pg_get_viewdef('tt14v', TRUE);
-- but will fail at execution
SELECT
    f1,
    f3
FROM
    tt14v;
SELECT
    *
FROM
    tt14v;
ROLLBACK;

-- check display of whole-row variables in some corner cases
CREATE TYPE nestedcomposite AS (
    x int8_tbl
);

CREATE VIEW tt15v AS
SELECT
    ROW (i)::nestedcomposite
FROM
    int8_tbl i;

SELECT
    *
FROM
    tt15v;

SELECT
    pg_get_viewdef('tt15v', TRUE);

SELECT
    ROW (i.*::int8_tbl)::nestedcomposite
FROM
    int8_tbl i;

CREATE VIEW tt16v AS
SELECT
    *
FROM
    int8_tbl i,
    LATERAL (
        VALUES (i)) ss;

SELECT
    *
FROM
    tt16v;

SELECT
    pg_get_viewdef('tt16v', TRUE);

SELECT
    *
FROM
    int8_tbl i,
    LATERAL (
        VALUES (i.*::int8_tbl)) ss;

CREATE VIEW tt17v AS
SELECT
    *
FROM
    int8_tbl i
WHERE
    i IN (
        VALUES (i));

SELECT
    *
FROM
    tt17v;

SELECT
    pg_get_viewdef('tt17v', TRUE);

SELECT
    *
FROM
    int8_tbl i
WHERE
    i.* IN (
        VALUES (i.*::int8_tbl));

-- check unique-ification of overlength names
CREATE VIEW tt18v AS
SELECT
    *
FROM
    int8_tbl xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy
UNION ALL
SELECT
    *
FROM
    int8_tbl xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxz;

SELECT
    pg_get_viewdef('tt18v', TRUE);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tt18v;

-- check display of ScalarArrayOp with a sub-select
SELECT
    'foo'::text = ANY (ARRAY['abc', 'def', 'foo']::text[]);

SELECT
    'foo'::text = ANY ((
            SELECT
                ARRAY['abc', 'def', 'foo']::text[]));

-- fail
SELECT
    'foo'::text = ANY ((
            SELECT
                ARRAY['abc', 'def', 'foo']::text[])::text[]);

CREATE VIEW tt19v AS
SELECT
    'foo'::text = ANY (ARRAY['abc', 'def', 'foo']::text[]) c1,
    'foo'::text = ANY ((
            SELECT
                ARRAY['abc', 'def', 'foo']::text[])::text[]) c2;

SELECT
    pg_get_viewdef('tt19v', TRUE);

-- check display of assorted RTE_FUNCTION expressions
CREATE VIEW tt20v AS
SELECT
    *
FROM
    coalesce(1, 2) AS c,
    COLLATION FOR ('x'::text) col,
    CURRENT_DATE AS d,
    localtimestamp(3) AS t,
    cast(1 + 2 AS int4) AS i4,
    cast(1 + 2 AS int8) AS i8;

SELECT
    pg_get_viewdef('tt20v', TRUE);

-- corner cases with empty join conditions
CREATE VIEW tt21v AS
SELECT
    *
FROM
    tt5
    NATURAL INNER JOIN tt6;

SELECT
    pg_get_viewdef('tt21v', TRUE);

CREATE VIEW tt22v AS
SELECT
    *
FROM
    tt5
    NATURAL
    LEFT JOIN tt6;

SELECT
    pg_get_viewdef('tt22v', TRUE);

-- check handling of views with immediately-renamed columns
CREATE VIEW tt23v (col_a, col_b) AS
SELECT
    q1 AS other_name1,
    q2 AS other_name2
FROM
    int8_tbl
UNION
SELECT
    42,
    43;

SELECT
    pg_get_viewdef('tt23v', TRUE);

SELECT
    pg_get_ruledef(oid, TRUE)
FROM
    pg_rewrite
WHERE
    ev_class = 'tt23v'::regclass
    AND ev_type = '1';

-- clean up all the random objects we made above
DROP SCHEMA temp_view_test CASCADE;

DROP SCHEMA testviewschm2 CASCADE;

