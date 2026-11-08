--
-- ROWTYPES
--
-- Make both a standalone composite type and a table rowtype
CREATE TYPE complex AS (
    r float8,
    i float8
);

CREATE temp TABLE fullname (
    first text,
    last text
);

-- Nested composite
CREATE TYPE quad AS (
    c1 complex,
    c2 complex
);

-- Some simple tests of I/O conversions and row construction
SELECT
    (1.1,
        2.2)::complex,
    ROW ((3.3,
            4.4),
        (5.5,
            NULL))::quad;

SELECT
    ROW ('Joe',
        'Blow')::fullname,
    '(Joe,Blow)'::fullname;

SELECT
    '(Joe,von Blow)'::fullname,
    '(Joe,d''Blow)'::fullname;

SELECT
    '(Joe,"von""Blow")'::fullname,
    E'(Joe,d\\\\Blow)'::fullname;

SELECT
    '(Joe,"Blow,Jr")'::fullname;

SELECT
    '(Joe,)'::fullname;

-- ok, null 2nd column
SELECT
    '(Joe)'::fullname;

-- bad
SELECT
    '(Joe,,)'::fullname;

-- bad
SELECT
    '[]'::fullname;

-- bad
SELECT
    ' (Joe,Blow)  '::fullname;

-- ok, extra whitespace
SELECT
    '(Joe,Blow) /'::fullname;

-- bad
-- test non-error-throwing API
SELECT
    pg_input_is_valid ('(1,2)', 'complex');

SELECT
    pg_input_is_valid ('(1,2', 'complex');

SELECT
    pg_input_is_valid ('(1,zed)', 'complex');

SELECT
    *
FROM
    pg_input_error_info ('(1,zed)', 'complex');

SELECT
    *
FROM
    pg_input_error_info ('(1,1e400)', 'complex');

CREATE temp TABLE quadtable (
    f1 int,
    q quad
);

INSERT INTO quadtable
VALUES
    (1, ((3.3, 4.4),
        (5.5, 6.6)));

INSERT INTO quadtable
VALUES
    (2, ((NULL, 4.4),
        (5.5, 6.6)));

SELECT
    *
FROM
    quadtable;

SELECT
    f1,
    q.c1
FROM
    quadtable;

-- fails, q is a table reference
SELECT
    f1,
    (q).c1,
    (qq.q).c1.i
FROM
    quadtable qq;

CREATE temp TABLE people (
    fn fullname,
    bd date
);

INSERT INTO people
    VALUES ('(Joe,Blow)', '1984-01-10');

SELECT
    *
FROM
    people;

-- at the moment this will not work due to ALTER TABLE inadequacy:
ALTER TABLE fullname
    ADD COLUMN suffix text DEFAULT '';

-- but this should work:
ALTER TABLE fullname
    ADD COLUMN suffix text DEFAULT NULL;

SELECT
    *
FROM
    people;

-- test insertion/updating of subfields
UPDATE
    people
SET
    fn.suffix = 'Jr';

SELECT
    *
FROM
    people;

INSERT INTO quadtable (f1, q.c1.r, q.c2.i)
    VALUES (44, 55, 66);

UPDATE
    quadtable
SET
    q.c1.r = 12
WHERE
    f1 = 2;

UPDATE
    quadtable
SET
    q.c1 = 12;

-- error, type mismatch
SELECT
    *
FROM
    quadtable;

-- The object here is to ensure that toasted references inside
-- composite values don't cause problems.  The large f1 value will
-- be toasted inside pp, it must still work after being copied to people.
CREATE temp TABLE pp (
    f1 text
);

INSERT INTO pp
    VALUES (repeat('abcdefghijkl', 100000));

INSERT INTO people
SELECT
    ('Jim',
        f1,
        NULL)::fullname,
    CURRENT_DATE
FROM
    pp;

SELECT
    (fn).FIRST,
    substr((fn).LAST, 1, 20),
    length((fn).LAST)
FROM
    people;

-- try an update on a toasted composite value, too
UPDATE
    people
SET
    fn.first = 'Jack';

SELECT
    (fn).FIRST,
    substr((fn).LAST, 1, 20),
    length((fn).LAST)
FROM
    people;

-- Test row comparison semantics.  Prior to PG 8.2 we did this in a totally
-- non-spec-compliant way.
SELECT
    ROW (1,
        2) < ROW (1,
        3) AS true;

SELECT
    ROW (1,
        2) < ROW (1,
        1) AS false;

SELECT
    ROW (1,
        2) < ROW (1,
        NULL) AS null;

SELECT
    ROW (1,
        2,
        3) < ROW (1,
        3,
        NULL) AS true;

-- the NULL is not examined
SELECT
    ROW (11,
        'ABC') < ROW (11,
        'DEF') AS true;

SELECT
    ROW (11,
        'ABC') > ROW (11,
        'DEF') AS false;

SELECT
    ROW (12,
        'ABC') > ROW (11,
        'DEF') AS true;

-- = and <> have different NULL-behavior than < etc
SELECT
    ROW (1,
        2,
        3) < ROW (1,
        NULL,
        4) AS null;

SELECT
    ROW (1,
        2,
        3) = ROW (1,
        NULL,
        4) AS false;

SELECT
    ROW (1,
        2,
        3) <> ROW (1,
        NULL,
        4) AS true;

-- We allow operators beyond the six standard ones, if they have btree
-- operator classes.
SELECT
    ROW ('ABC',
        'DEF') ~<=~ ROW ('DEF',
        'ABC') AS true;

SELECT
    ROW ('ABC',
        'DEF') ~>=~ ROW ('DEF',
        'ABC') AS false;

SELECT
    ROW ('ABC',
        'DEF') ~~ ROW ('DEF',
        'ABC') AS fail;

-- Comparisons of ROW() expressions can cope with some type mismatches
SELECT
    ROW (1,
        2) = ROW (1,
        2::int8);

SELECT
    ROW (1,
        2) IN (ROW (3, 4), ROW (1, 2));

SELECT
    ROW (1,
        2) IN (ROW (3, 4), ROW (1, 2::int8));

-- Check row comparison with a subselect
SELECT
    unique1,
    unique2
FROM
    tenk1
WHERE (unique1, unique2) < ANY (
    SELECT
        ten,
        ten
    FROM
        tenk1
    WHERE
        hundred < 3)
    AND unique1 <= 20
ORDER BY
    1;

-- Also check row comparison with an indexable condition
EXPLAIN (
    COSTS OFF
)
SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE (thousand, tenthous) >= (997, 5000)
ORDER BY
    thousand,
    tenthous;

SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE (thousand, tenthous) >= (997, 5000)
ORDER BY
    thousand,
    tenthous;

EXPLAIN (
    COSTS OFF
)
SELECT
    thousand,
    tenthous,
    four
FROM
    tenk1
WHERE (thousand, tenthous, four) > (998, 5000, 3)
ORDER BY
    thousand,
    tenthous;

SELECT
    thousand,
    tenthous,
    four
FROM
    tenk1
WHERE (thousand, tenthous, four) > (998, 5000, 3)
ORDER BY
    thousand,
    tenthous;

EXPLAIN (
    COSTS OFF
)
SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE (998, 5000) < (thousand, tenthous)
ORDER BY
    thousand,
    tenthous;

SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE (998, 5000) < (thousand, tenthous)
ORDER BY
    thousand,
    tenthous;

EXPLAIN (
    COSTS OFF
)
SELECT
    thousand,
    hundred
FROM
    tenk1
WHERE (998, 5000) < (thousand, hundred)
ORDER BY
    thousand,
    hundred;

SELECT
    thousand,
    hundred
FROM
    tenk1
WHERE (998, 5000) < (thousand, hundred)
ORDER BY
    thousand,
    hundred;

-- Test case for bug #14010: indexed row comparisons fail with nulls
CREATE temp TABLE test_table (
    a text,
    b text
);

INSERT INTO test_table
    VALUES ('a', 'b');

INSERT INTO test_table
SELECT
    'a',
    NULL
FROM
    generate_series(1, 1000);

INSERT INTO test_table
    VALUES ('b', 'a');

CREATE INDEX ON test_table (a, b);

SET enable_sort = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b
FROM
    test_table
WHERE (a, b) > ('a', 'a')
ORDER BY
    a,
    b;

SELECT
    a,
    b
FROM
    test_table
WHERE (a, b) > ('a', 'a')
ORDER BY
    a,
    b;

RESET enable_sort;

-- Check row comparisons with IN
SELECT
    *
FROM
    int8_tbl i8
WHERE
    i8 IN (ROW (123, 456));

-- fail, type mismatch
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    int8_tbl i8
WHERE
    i8 IN (ROW (123, 456)::int8_tbl, '(4567890123456789,123)');

SELECT
    *
FROM
    int8_tbl i8
WHERE
    i8 IN (ROW (123, 456)::int8_tbl, '(4567890123456789,123)');

-- Check ability to select columns from an anonymous rowtype
SELECT
    (ROW (1,
            2.0)).f1;

SELECT
    (ROW (1,
            2.0)).f2;

SELECT
    (ROW (1,
            2.0)).nosuch;

-- fail
SELECT
    (ROW (1,
            2.0)).*;

SELECT
    (r).f1
FROM (
    SELECT
        ROW (1,
            2.0) AS r) ss;

SELECT
    (r).f3
FROM (
    SELECT
        ROW (1,
            2.0) AS r) ss;

-- fail
SELECT
    (r).*
FROM (
    SELECT
        ROW (1,
            2.0) AS r) ss;

-- Check some corner cases involving empty rowtypes
SELECT
    ROW ();

SELECT
    ROW () IS NULL;

SELECT
    ROW () = ROW ();

-- Check ability to create arrays of anonymous rowtypes
SELECT
    ARRAY[ROW (1, 2), ROW (3, 4), ROW (5, 6)];

-- Check ability to compare an anonymous row to elements of an array
SELECT
    ROW (1,
        1.1) = ANY (ARRAY[ROW (7, 7.7), ROW (1, 1.1), ROW (0, 0.0)]);

SELECT
    ROW (1,
        1.1) = ANY (ARRAY[ROW (7, 7.7), ROW (1, 1.0), ROW (0, 0.0)]);

-- Check behavior with a non-comparable rowtype
CREATE TYPE cantcompare AS (
    p point,
    r float8
);

CREATE temp TABLE cc (
    f1 cantcompare
);

INSERT INTO cc
    VALUES ('("(1,2)",3)');

INSERT INTO cc
    VALUES ('("(4,5)",6)');

SELECT
    *
FROM
    cc
ORDER BY
    f1;

-- fail, but should complain about cantcompare
--
-- Tests for record_{eq,cmp}
--
CREATE TYPE testtype1 AS (
    a int,
    b int
);

-- all true
SELECT
    ROW (1,
        2)::testtype1 < ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 <= ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 = ROW (1,
        2)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 <> ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        3)::testtype1 >= ROW (1,
        2)::testtype1;

SELECT
    ROW (1,
        3)::testtype1 > ROW (1,
        2)::testtype1;

-- all false
SELECT
    ROW (1,
        -2)::testtype1 < ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 <= ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 = ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 <> ROW (1,
        -2)::testtype1;

SELECT
    ROW (1,
        -3)::testtype1 >= ROW (1,
        -2)::testtype1;

SELECT
    ROW (1,
        -3)::testtype1 > ROW (1,
        -2)::testtype1;

-- true, but see *< below
SELECT
    ROW (1,
        -2)::testtype1 < ROW (1,
        3)::testtype1;

-- mismatches
CREATE TYPE testtype3 AS (
    a int,
    b text
);

SELECT
    ROW (1,
        2)::testtype1 < ROW (1,
        'abc')::testtype3;

SELECT
    ROW (1,
        2)::testtype1 <> ROW (1,
        'abc')::testtype3;

CREATE TYPE testtype5 AS (
    a int
);

SELECT
    ROW (1,
        2)::testtype1 < ROW (1)::testtype5;

SELECT
    ROW (1,
        2)::testtype1 <> ROW (1)::testtype5;

-- non-comparable types
CREATE TYPE testtype6 AS (
    a int,
    b point
);

SELECT
    ROW (1,
        '(1,2)')::testtype6 < ROW (1,
        '(1,3)')::testtype6;

SELECT
    ROW (1,
        '(1,2)')::testtype6 <> ROW (1,
        '(1,3)')::testtype6;

DROP TYPE testtype1, testtype3, testtype5, testtype6;

--
-- Tests for record_image_{eq,cmp}
--
CREATE TYPE testtype1 AS (
    a int,
    b int
);

-- all true
SELECT
    ROW (1,
        2)::testtype1 *< ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 *<= ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 *= ROW (1,
        2)::testtype1;

SELECT
    ROW (1,
        2)::testtype1 *<> ROW (1,
        3)::testtype1;

SELECT
    ROW (1,
        3)::testtype1 *>= ROW (1,
        2)::testtype1;

SELECT
    ROW (1,
        3)::testtype1 *> ROW (1,
        2)::testtype1;

-- all false
SELECT
    ROW (1,
        -2)::testtype1 *< ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 *<= ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 *= ROW (1,
        -3)::testtype1;

SELECT
    ROW (1,
        -2)::testtype1 *<> ROW (1,
        -2)::testtype1;

SELECT
    ROW (1,
        -3)::testtype1 *>= ROW (1,
        -2)::testtype1;

SELECT
    ROW (1,
        -3)::testtype1 *> ROW (1,
        -2)::testtype1;

-- This returns the "wrong" order because record_image_cmp works on
-- unsigned datums without knowing about the actual data type.
SELECT
    ROW (1,
        -2)::testtype1 *< ROW (1,
        3)::testtype1;

-- other types
CREATE TYPE testtype2 AS (
    a smallint,
    b bool
);

-- byval different sizes
SELECT
    ROW (1,
        TRUE)::testtype2 *< ROW (2,
        TRUE)::testtype2;

SELECT
    ROW (-2,
        TRUE)::testtype2 *< ROW (-1,
        TRUE)::testtype2;

SELECT
    ROW (0,
        FALSE)::testtype2 *< ROW (0,
        TRUE)::testtype2;

SELECT
    ROW (0,
        FALSE)::testtype2 *<> ROW (0,
        TRUE)::testtype2;

CREATE TYPE testtype3 AS (
    a int,
    b text
);

-- variable length
SELECT
    ROW (1,
        'abc')::testtype3 *< ROW (1,
        'abd')::testtype3;

SELECT
    ROW (1,
        'abc')::testtype3 *< ROW (1,
        'abcd')::testtype3;

SELECT
    ROW (1,
        'abc')::testtype3 *> ROW (1,
        'abd')::testtype3;

SELECT
    ROW (1,
        'abc')::testtype3 *<> ROW (1,
        'abd')::testtype3;

CREATE TYPE testtype4 AS (
    a int,
    b point
);

-- by ref, fixed length
SELECT
    ROW (1,
        '(1,2)')::testtype4 *< ROW (1,
        '(1,3)')::testtype4;

SELECT
    ROW (1,
        '(1,2)')::testtype4 *<> ROW (1,
        '(1,3)')::testtype4;

-- mismatches
SELECT
    ROW (1,
        2)::testtype1 *< ROW (1,
        'abc')::testtype3;

SELECT
    ROW (1,
        2)::testtype1 *<> ROW (1,
        'abc')::testtype3;

CREATE TYPE testtype5 AS (
    a int
);

SELECT
    ROW (1,
        2)::testtype1 *< ROW (1)::testtype5;

SELECT
    ROW (1,
        2)::testtype1 *<> ROW (1)::testtype5;

-- non-comparable types
CREATE TYPE testtype6 AS (
    a int,
    b point
);

SELECT
    ROW (1,
        '(1,2)')::testtype6 *< ROW (1,
        '(1,3)')::testtype6;

SELECT
    ROW (1,
        '(1,2)')::testtype6 *>= ROW (1,
        '(1,3)')::testtype6;

SELECT
    ROW (1,
        '(1,2)')::testtype6 *<> ROW (1,
        '(1,3)')::testtype6;

-- anonymous rowtypes in coldeflists
SELECT
    q.a,
    q.b = ROW (2),
    q.c = ARRAY[ROW (3)],
    q.d = ROW (ROW (4))
FROM
    unnest(ARRAY[ROW (1, ROW (2), ARRAY[ROW (3)], ROW (ROW (4))), ROW (2, ROW (3), ARRAY[ROW (4)], ROW (ROW (5)))]) AS q (a int,
        b record,
        c record[],
        d record);

DROP TYPE testtype1, testtype2, testtype3, testtype4, testtype5, testtype6;

--
-- Test case derived from bug #5716: check multiple uses of a rowtype result
--
BEGIN;
CREATE TABLE price (
    id serial PRIMARY KEY,
    active boolean NOT NULL,
    price numeric
);
CREATE TYPE price_input AS (
    id integer,
    price numeric
);
CREATE TYPE price_key AS (
    id integer
);
CREATE FUNCTION price_key_from_table (price)
    RETURNS price_key
    AS $$
    SELECT
        $1.id
$$
LANGUAGE SQL;
CREATE FUNCTION price_key_from_input (price_input)
    RETURNS price_key
    AS $$
    SELECT
        $1.id
$$
LANGUAGE SQL;
INSERT INTO price
VALUES
    (1, FALSE, 42),
    (10, FALSE, 100),
    (11, TRUE, 17.99);
UPDATE
    price
SET
    active = TRUE,
    price = input_prices.price
FROM
    unnest(ARRAY[(10, 123.00), (11, 99.99)]::price_input[]) input_prices
WHERE
    price_key_from_table (price.*) = price_key_from_input (input_prices.*);
SELECT
    *
FROM
    price;
ROLLBACK;

--
-- Test case derived from bug #9085: check * qualification of composite
-- parameters for SQL functions
--
CREATE temp TABLE compos (
    f1 int,
    f2 text
);

CREATE FUNCTION fcompos1 (v compos)
    RETURNS void
    AS $$
    INSERT INTO compos
        VALUES (v);
        -- fail
$$
LANGUAGE sql;

CREATE FUNCTION fcompos1 (v compos)
    RETURNS void
    AS $$
    INSERT INTO compos
        VALUES (v.*);
$$
LANGUAGE sql;

CREATE FUNCTION fcompos2 (v compos)
    RETURNS void
    AS $$
    SELECT
        fcompos1 (v);
$$
LANGUAGE sql;

CREATE FUNCTION fcompos3 (v compos)
    RETURNS void
    AS $$
    SELECT
        fcompos1 (fcompos3.v.*);
$$
LANGUAGE sql;

SELECT
    fcompos1 (ROW (1, 'one'));

SELECT
    fcompos2 (ROW (2, 'two'));

SELECT
    fcompos3 (ROW (3, 'three'));

SELECT
    *
FROM
    compos;

--
-- We allow I/O conversion casts from composite types to strings to be
-- invoked via cast syntax, but not functional syntax.  This is because
-- the latter is too prone to be invoked unintentionally.
--
SELECT
    cast(fullname AS text)
FROM
    fullname;

SELECT
    fullname::text
FROM
    fullname;

SELECT
    text(fullname)
FROM
    fullname;

-- error
SELECT
    fullname.text
FROM
    fullname;

-- error
-- same, but RECORD instead of named composite type:
SELECT
    cast(ROW ('Jim', 'Beam') AS text);

SELECT
    (ROW ('Jim',
            'Beam'))::text;

SELECT
    text(ROW ('Jim', 'Beam'));

-- error
SELECT
    (ROW ('Jim',
            'Beam')).text;

-- error
--
-- Check the equivalence of functional and column notation
--
INSERT INTO fullname
    VALUES ('Joe', 'Blow');

SELECT
    f.last
FROM
    fullname f;

SELECT
    LAST (f)
FROM
    fullname f;

CREATE FUNCTION longname (fullname)
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        $1.FIRST || ' ' || $1.LAST
$$;

SELECT
    f.longname
FROM
    fullname f;

SELECT
    longname (f)
FROM
    fullname f;

-- Starting in v11, the notational form does matter if there's ambiguity
ALTER TABLE fullname
    ADD COLUMN longname text;

SELECT
    f.longname
FROM
    fullname f;

SELECT
    longname (f)
FROM
    fullname f;

--
-- Test that composite values are seen to have the correct column names
-- (bug #11210 and other reports)
--
SELECT
    row_to_json(i)
FROM
    int8_tbl i;

-- since "i" is of type "int8_tbl", attaching aliases doesn't change anything:
SELECT
    row_to_json(i)
FROM
    int8_tbl i (x,
        y);

-- in these examples, we'll report the exposed column names of the subselect:
SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1,
        q2
    FROM
        int8_tbl) AS ss;

SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1,
        q2
    FROM
        int8_tbl OFFSET 0) AS ss;

SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1 AS a,
        q2 AS b
    FROM
        int8_tbl) AS ss;

SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1 AS a,
        q2 AS b
    FROM
        int8_tbl OFFSET 0) AS ss;

SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1 AS a,
        q2 AS b
    FROM
        int8_tbl) AS ss (x,
        y);

SELECT
    row_to_json(ss)
FROM (
    SELECT
        q1 AS a,
        q2 AS b
    FROM
        int8_tbl OFFSET 0) AS ss (x,
        y);

EXPLAIN (
    COSTS OFF
)
SELECT
    row_to_json(q)
FROM (
    SELECT
        thousand,
        tenthous
    FROM
        tenk1
    WHERE
        thousand = 42
        AND tenthous < 2000 OFFSET 0) q;

SELECT
    row_to_json(q)
FROM (
    SELECT
        thousand,
        tenthous
    FROM
        tenk1
    WHERE
        thousand = 42
        AND tenthous < 2000 OFFSET 0) q;

SELECT
    row_to_json(q)
FROM (
    SELECT
        thousand AS x,
        tenthous AS y
    FROM
        tenk1
    WHERE
        thousand = 42
        AND tenthous < 2000 OFFSET 0) q;

SELECT
    row_to_json(q)
FROM (
    SELECT
        thousand AS x,
        tenthous AS y
    FROM
        tenk1
    WHERE
        thousand = 42
        AND tenthous < 2000 OFFSET 0) q (a,
        b);

CREATE temp TABLE tt1 AS
SELECT
    *
FROM
    int8_tbl
LIMIT 2;

CREATE temp TABLE tt2 ()
INHERITS (
    tt1
);

INSERT INTO tt2
    VALUES (0, 0);

SELECT
    row_to_json(r)
FROM (
    SELECT
        q2,
        q1
    FROM
        tt1 OFFSET 0) r;

-- check no-op rowtype conversions
CREATE temp TABLE tt3 ()
INHERITS (
    tt2
);

INSERT INTO tt3
    VALUES (33, 44);

SELECT
    row_to_json(tt3::tt2::tt1)
FROM
    tt3;

--
-- IS [NOT] NULL should not recurse into nested composites (bug #14235)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    r,
    r IS NULL AS isnull,
    r IS NOT NULL AS isnotnull
FROM (
    VALUES (1, ROW (1, 2)),
        (1, ROW (NULL, NULL)),
        (1, NULL),
        (NULL, ROW (1, 2)),
        (NULL, ROW (NULL, NULL)),
        (NULL, NULL)) r (a, b);

SELECT
    r,
    r IS NULL AS isnull,
    r IS NOT NULL AS isnotnull
FROM (
    VALUES (1, ROW (1, 2)),
        (1, ROW (NULL, NULL)),
        (1, NULL),
        (NULL, ROW (1, 2)),
        (NULL, ROW (NULL, NULL)),
        (NULL, NULL)) r (a, b);

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH r (a,
    b) AS MATERIALIZED (
    VALUES (1, ROW (1, 2)),
        (1, ROW (NULL, NULL)),
        (1, NULL),
        (NULL, ROW (1, 2)),
        (NULL, ROW (NULL, NULL)),
        (NULL, NULL))
SELECT
    r,
    r IS NULL AS isnull,
    r IS NOT NULL AS isnotnull
FROM
    r;

WITH r (
    a,
    b
) AS MATERIALIZED (
    VALUES (
            1, ROW (
                1, 2
)
),
        (
            1, ROW (
                NULL, NULL
)
),
        (
            1, NULL
),
        (
            NULL, ROW (
                1, 2
)
),
        (
            NULL, ROW (
                NULL, NULL
)
),
        (
            NULL, NULL
))
SELECT
    r,
    r IS NULL AS isnull,
    r IS NOT NULL AS isnotnull
FROM
    r;

--
-- Check parsing of indirect references to composite values (bug #18077)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH cte (c) AS MATERIALIZED (
    SELECT
        ROW (1,
            2)),
cte2 (c)
AS (
    SELECT
        *
    FROM
        cte
)
SELECT
    *
FROM
    cte2 AS t
WHERE (
    SELECT
        *
    FROM (
        SELECT
            c AS c1) s
    WHERE (
        SELECT
            (c1).f1 > 0)) IS NOT NULL;

WITH cte (
    c
) AS MATERIALIZED (
    SELECT
        ROW (
            1,
            2
)
),
cte2 (
    c
) AS (
    SELECT
        *
    FROM
        cte
)
SELECT
    *
FROM
    cte2 AS t
WHERE (
    SELECT
        *
    FROM (
        SELECT
            c AS c1) s
    WHERE (
        SELECT
            (c1).f1 > 0)) IS NOT NULL;

-- Also check deparsing of such cases
CREATE VIEW composite_v AS
WITH cte (
    c
) AS MATERIALIZED (
    SELECT
        ROW (
            1,
            2
)
),
cte2 (
    c
) AS (
    SELECT
        *
    FROM
        cte
)
SELECT
    1 AS one
FROM
    cte2 AS t
WHERE (
    SELECT
        *
    FROM (
        SELECT
            c AS c1) s
    WHERE (
        SELECT
            (c1).f1 > 0)) IS NOT NULL;

SELECT
    pg_get_viewdef('composite_v', TRUE);

DROP VIEW composite_v;

--
-- Check cases where the composite comes from a proven-dummy rel (bug #18576)
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (ss.a).x,
    (ss.a).n
FROM (
    SELECT
        information_schema._pg_expandarray (ARRAY[1, 2]) AS a) ss;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    (ss.a).x,
    (ss.a).n
FROM (
    SELECT
        information_schema._pg_expandarray (ARRAY[1, 2]) AS a) ss
WHERE
    FALSE;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH cte (c) AS MATERIALIZED (
    SELECT
        ROW (1,
            2)),
cte2 (c)
AS (
    SELECT
        *
    FROM
        cte
)
SELECT
    (c).f1
FROM
    cte2 AS t;

EXPLAIN (
    VERBOSE,
    COSTS OFF
) WITH cte (c) AS MATERIALIZED (
    SELECT
        ROW (1,
            2)),
cte2 (c)
AS (
    SELECT
        *
    FROM
        cte
)
SELECT
    (c).f1
FROM
    cte2 AS t
WHERE
    FALSE;

--
-- Tests for component access / FieldSelect
--
CREATE TABLE compositetable (
    a text,
    b text
);

INSERT INTO compositetable (a, b)
    VALUES ('fa', 'fb');

-- composite type columns can't directly be accessed (error)
SELECT
    d.a
FROM (
    SELECT
        compositetable AS d
    FROM
        compositetable) s;

-- but can be accessed with proper parens
SELECT
    (d).a,
    (d).b
FROM (
    SELECT
        compositetable AS d
    FROM
        compositetable) s;

-- system columns can't be accessed in composite types (error)
SELECT
    (d).ctid
FROM (
    SELECT
        compositetable AS d
    FROM
        compositetable) s;

-- accessing non-existing column in NULL datum errors out
SELECT
    (NULL::compositetable).nonexistent;

-- existing column in a NULL composite yield NULL
SELECT
    (NULL::compositetable).a;

-- oids can't be accessed in composite types (error)
SELECT
    (NULL::compositetable).oid;

DROP TABLE compositetable;

