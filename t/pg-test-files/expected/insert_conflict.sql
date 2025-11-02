--
-- insert...on conflict do unique index inference
--
CREATE TABLE insertconflicttest (
    key int4,
    fruit text
);

--
-- Test unique index inference with operator class specifications and
-- named collations
--
CREATE UNIQUE INDEX op_index_key ON insertconflicttest (key, fruit text_pattern_ops);

CREATE UNIQUE INDEX collation_index_key ON insertconflicttest (key, fruit COLLATE "C");

CREATE UNIQUE INDEX both_index_key ON insertconflicttest (key, fruit COLLATE "C" text_pattern_ops);

CREATE UNIQUE INDEX both_index_expr_key ON insertconflicttest (key, lower(fruit) COLLATE "C" text_pattern_ops);

-- fails
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (fruit)
    DO NOTHING;

-- succeeds
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key, fruit)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (fruit, key, fruit, key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit), key, lower(fruit), key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                insertconflicttest ii
            WHERE
                ii.key = excluded.key);

-- Neither collation nor operator class specifications are required --
-- supplying them merely *limits* matches to indexes with matching opclasses
-- used for relevant indexes
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key, fruit text_pattern_ops)
    DO NOTHING;

-- Okay, arbitrates using both index where text_pattern_ops opclass does and
-- does not appear.
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key, fruit COLLATE "C")
    DO NOTHING;

-- Okay, but only accepts the single index where both opclass and collation are
-- specified
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (fruit COLLATE "C" text_pattern_ops, key)
    DO NOTHING;

-- Okay, but only accepts the single index where both opclass and collation are
-- specified (plus expression variant)
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit)
    COLLATE "C", key, key)
    DO NOTHING;

-- Attribute appears twice, while not all attributes/expressions on attributes
-- appearing within index definition match in terms of both opclass and
-- collation.
--
-- Works because every attribute in inference specification needs to be
-- satisfied once or more by cataloged index attribute, and as always when an
-- attribute in the cataloged definition has a non-default opclass/collation,
-- it still satisfied some inference attribute lacking any particular
-- opclass/collation specification.
--
-- The implementation is liberal in accepting inference specifications on the
-- assumption that multiple inferred unique indexes will prevent problematic
-- cases.  It rolls with unique indexes where attributes redundantly appear
-- multiple times, too (which is not tested here).
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (fruit, key, fruit text_pattern_ops, key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit)
    COLLATE "C" text_pattern_ops, key, key)
    DO NOTHING;

DROP INDEX op_index_key;

DROP INDEX collation_index_key;

DROP INDEX both_index_key;

DROP INDEX both_index_expr_key;

--
-- Make sure that cross matching of attribute opclass/collation does not occur
--
CREATE UNIQUE INDEX cross_match ON insertconflicttest (lower(fruit) COLLATE "C", upper(fruit) text_pattern_ops);

-- fails:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit) text_pattern_ops, upper(fruit)
    COLLATE "C")
    DO NOTHING;

-- works:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit)
    COLLATE "C", upper(fruit) text_pattern_ops)
    DO NOTHING;

DROP INDEX cross_match;

--
-- Single key tests
--
CREATE UNIQUE INDEX key_index ON insertconflicttest (key);

--
-- Explain tests
--
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Bilberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- Should display qual actually attributable to internal sequential scan:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Bilberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        insertconflicttest.fruit != 'Cawesh';

-- With EXCLUDED.* expression in scan node:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        excluded.fruit != 'Elderberry';

-- Does the same, but JSON format shows "Conflict Arbiter Index" as JSON array:
EXPLAIN (
    COSTS OFF,
    format json
) INSERT INTO insertconflicttest
    VALUES (0, 'Bilberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        insertconflicttest.fruit != 'Lime'
    RETURNING
        *;

-- Fails (no unique index inference specification, required for do update variant):
INSERT INTO insertconflicttest
    VALUES (1, 'Apple')
ON CONFLICT
    DO UPDATE SET
        fruit = excluded.fruit;

-- inference succeeds:
INSERT INTO insertconflicttest
    VALUES (1, 'Apple')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (2, 'Orange')
ON CONFLICT (key, key, key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- Succeed, since multi-assignment does not involve subquery:
INSERT INTO insertconflicttest
VALUES
    (1, 'Apple'),
    (2, 'Orange')
ON CONFLICT (key)
    DO UPDATE SET
        (fruit, key) = (excluded.fruit, excluded.key);

-- Give good diagnostic message when EXCLUDED.* spuriously referenced from
-- RETURNING:
INSERT INTO insertconflicttest
    VALUES (1, 'Apple')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    RETURNING
        excluded.fruit;

-- Only suggest <table>.* column when inference element misspelled:
INSERT INTO insertconflicttest
    VALUES (1, 'Apple')
ON CONFLICT (keyy)
    DO UPDATE SET
        fruit = excluded.fruit;

-- Have useful HINT for EXCLUDED.* RTE within UPDATE:
INSERT INTO insertconflicttest
    VALUES (1, 'Apple')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruitt;

-- inference fails:
INSERT INTO insertconflicttest
    VALUES (3, 'Kiwi')
ON CONFLICT (key, fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (4, 'Mango')
ON CONFLICT (fruit, key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (5, 'Lemon')
ON CONFLICT (fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (6, 'Passionfruit')
ON CONFLICT (lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

-- Check the target relation can be aliased
INSERT INTO insertconflicttest AS ict
    VALUES (6, 'Passionfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- ok, no reference to target table
INSERT INTO insertconflicttest AS ict
    VALUES (6, 'Passionfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = ict.fruit;

-- ok, alias
INSERT INTO insertconflicttest AS ict
    VALUES (6, 'Passionfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = insertconflicttest.fruit;

-- error, references aliased away name
DROP INDEX key_index;

--
-- Composite key tests
--
CREATE UNIQUE INDEX comp_key_index ON insertconflicttest (key, fruit);

-- inference succeeds:
INSERT INTO insertconflicttest
    VALUES (7, 'Raspberry')
ON CONFLICT (key, fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (8, 'Lime')
ON CONFLICT (fruit, key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- inference fails:
INSERT INTO insertconflicttest
    VALUES (9, 'Banana')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (10, 'Blueberry')
ON CONFLICT (key, key, key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (11, 'Cherry')
ON CONFLICT (key, lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (12, 'Date')
ON CONFLICT (lower(fruit), key)
    DO UPDATE SET
        fruit = excluded.fruit;

DROP INDEX comp_key_index;

--
-- Partial index tests, no inference predicate specified
--
CREATE UNIQUE INDEX part_comp_key_index ON insertconflicttest (key, fruit)
WHERE
    key < 5;

CREATE UNIQUE INDEX expr_part_comp_key_index ON insertconflicttest (key, lower(fruit))
WHERE
    key < 5;

-- inference fails:
INSERT INTO insertconflicttest
    VALUES (13, 'Grape')
ON CONFLICT (key, fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (14, 'Raisin')
ON CONFLICT (fruit, key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (15, 'Cranberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (16, 'Melon')
ON CONFLICT (key, key, key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (17, 'Mulberry')
ON CONFLICT (key, lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (18, 'Pineapple')
ON CONFLICT (lower(fruit), key)
    DO UPDATE SET
        fruit = excluded.fruit;

DROP INDEX part_comp_key_index;

DROP INDEX expr_part_comp_key_index;

--
-- Expression index tests
--
CREATE UNIQUE INDEX expr_key_index ON insertconflicttest (lower(fruit));

-- inference succeeds:
INSERT INTO insertconflicttest
    VALUES (20, 'Quince')
ON CONFLICT (lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (21, 'Pomegranate')
ON CONFLICT (lower(fruit), lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

-- inference fails:
INSERT INTO insertconflicttest
    VALUES (22, 'Apricot')
ON CONFLICT (upper(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

DROP INDEX expr_key_index;

--
-- Expression index tests (with regular column)
--
CREATE UNIQUE INDEX expr_comp_key_index ON insertconflicttest (key, lower(fruit));

CREATE UNIQUE INDEX tricky_expr_comp_key_index ON insertconflicttest (key, lower(fruit), upper(fruit));

-- inference succeeds:
INSERT INTO insertconflicttest
    VALUES (24, 'Plum')
ON CONFLICT (key, lower(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (25, 'Peach')
ON CONFLICT (lower(fruit), key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- Should not infer "tricky_expr_comp_key_index" index:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (26, 'Fig')
ON CONFLICT (lower(fruit), key, lower(fruit), key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- inference fails:
INSERT INTO insertconflicttest
    VALUES (27, 'Prune')
ON CONFLICT (key, upper(fruit))
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (28, 'Redcurrant')
ON CONFLICT (fruit, key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (29, 'Nectarine')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

DROP INDEX expr_comp_key_index;

DROP INDEX tricky_expr_comp_key_index;

--
-- Non-spurious duplicate violation tests
--
CREATE UNIQUE INDEX key_index ON insertconflicttest (key);

CREATE UNIQUE INDEX fruit_index ON insertconflicttest (fruit);

-- succeeds, since UPDATE happens to update "fruit" to existing value:
INSERT INTO insertconflicttest
    VALUES (26, 'Fig')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- fails, since UPDATE is to row with key value 26, and we're updating "fruit"
-- to a value that happens to exist in another row ('peach'):
INSERT INTO insertconflicttest
    VALUES (26, 'Peach')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

-- succeeds, since "key" isn't repeated/referenced in UPDATE, and "fruit"
-- arbitrates that statement updates existing "Fig" row:
INSERT INTO insertconflicttest
    VALUES (25, 'Fig')
ON CONFLICT (fruit)
    DO UPDATE SET
        fruit = excluded.fruit;

DROP INDEX key_index;

DROP INDEX fruit_index;

--
-- Test partial unique index inference
--
CREATE UNIQUE INDEX partial_key_index ON insertconflicttest (key)
WHERE
    fruit LIKE '%berry';

-- Succeeds
INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (key)
WHERE
    fruit LIKE '%berry'
        DO UPDATE SET
            fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (key)
WHERE
    fruit LIKE '%berry'
        AND fruit = 'inconsequential'
            DO NOTHING;

-- fails
INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit;

INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (key)
WHERE
    fruit LIKE '%berry'
        OR fruit = 'consequential'
            DO NOTHING;

INSERT INTO insertconflicttest
    VALUES (23, 'Blackberry')
ON CONFLICT (fruit)
WHERE
    fruit LIKE '%berry'
        DO UPDATE SET
            fruit = excluded.fruit;

DROP INDEX partial_key_index;

--
-- Test that wholerow references to ON CONFLICT's EXCLUDED work
--
CREATE UNIQUE INDEX plain ON insertconflicttest (key);

-- Succeeds, updates existing row:
INSERT INTO insertconflicttest AS i
    VALUES (23, 'Jackfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        i.* != excluded.*
    RETURNING
        *;

-- No update this time, though:
INSERT INTO insertconflicttest AS i
    VALUES (23, 'Jackfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        i.* != excluded.*
    RETURNING
        *;

-- Predicate changed to require match rather than non-match, so updates once more:
INSERT INTO insertconflicttest AS i
    VALUES (23, 'Jackfruit')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        i.* = excluded.*
    RETURNING
        *;

-- Assign:
INSERT INTO insertconflicttest AS i
    VALUES (23, 'Avocado')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.*::text
    RETURNING
        *;

-- deparse whole row var in WHERE and SET clauses:
EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest AS i
    VALUES (23, 'Avocado')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        excluded.* IS NULL;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest AS i
    VALUES (23, 'Avocado')
ON CONFLICT (key)
    DO UPDATE SET
        fruit = excluded.*::text;

DROP INDEX plain;

-- Cleanup
DROP TABLE insertconflicttest;

--
-- Verify that EXCLUDED does not allow system column references. These
-- do not make sense because EXCLUDED isn't an already stored tuple
-- (and thus doesn't have a ctid etc).
--
CREATE TABLE syscolconflicttest (
    key int4,
    data text
);

INSERT INTO syscolconflicttest
    VALUES (1);

INSERT INTO syscolconflicttest
    VALUES (1)
ON CONFLICT (key)
    DO UPDATE SET
        data = excluded.ctid::text;

DROP TABLE syscolconflicttest;

--
-- Previous tests all managed to not test any expressions requiring
-- planner preprocessing ...
--
CREATE TABLE insertconflict (
    a bigint,
    b bigint
);

CREATE UNIQUE INDEX insertconflicti1 ON insertconflict (coalesce(a, 0));

CREATE UNIQUE INDEX insertconflicti2 ON insertconflict (b)
WHERE
    coalesce(a, 1) > 0;

INSERT INTO insertconflict
    VALUES (1, 2)
ON CONFLICT (coalesce(a, 0))
    DO NOTHING;

INSERT INTO insertconflict
    VALUES (1, 2)
ON CONFLICT (b)
WHERE
    coalesce(a, 1) > 0
        DO NOTHING;

INSERT INTO insertconflict
    VALUES (1, 2)
ON CONFLICT (b)
WHERE
    coalesce(a, 1) > 1
        DO NOTHING;

DROP TABLE insertconflict;

--
-- test insertion through view
--
CREATE TABLE insertconflict (
    f1 int PRIMARY KEY,
    f2 text
);

CREATE VIEW insertconflictv AS
SELECT
    *
FROM
    insertconflict WITH cascaded CHECK option;

INSERT INTO insertconflictv
    VALUES (1, 'foo')
ON CONFLICT (f1)
    DO UPDATE SET
        f2 = excluded.f2;

SELECT
    *
FROM
    insertconflict;

INSERT INTO insertconflictv
    VALUES (1, 'bar')
ON CONFLICT (f1)
    DO UPDATE SET
        f2 = excluded.f2;

SELECT
    *
FROM
    insertconflict;

DROP VIEW insertconflictv;

DROP TABLE insertconflict;

-- ******************************************************************
-- *                                                                *
-- * Test inheritance (example taken from tutorial)                 *
-- *                                                                *
-- ******************************************************************
CREATE TABLE cities (
    name text,
    population float8,
    altitude int -- (in ft)
);

CREATE TABLE capitals (
    state char(2)
)
INHERITS (
    cities
);

-- Create unique indexes.  Due to a general limitation of inheritance,
-- uniqueness is only enforced per-relation.  Unique index inference
-- specification will do the right thing, though.
CREATE UNIQUE INDEX cities_names_unique ON cities (name);

CREATE UNIQUE INDEX capitals_names_unique ON capitals (name);

-- prepopulate the tables.
INSERT INTO cities
    VALUES ('San Francisco', 7.24E+5, 63);

INSERT INTO cities
    VALUES ('Las Vegas', 2.583E+5, 2174);

INSERT INTO cities
    VALUES ('Mariposa', 1200, 1953);

INSERT INTO capitals
    VALUES ('Sacramento', 3.694E+5, 30, 'CA');

INSERT INTO capitals
    VALUES ('Madison', 1.913E+5, 845, 'WI');

-- Tests proper for inheritance:
SELECT
    *
FROM
    capitals;

-- Succeeds:
INSERT INTO cities
    VALUES ('Las Vegas', 2.583E+5, 2174)
ON CONFLICT
    DO NOTHING;

INSERT INTO capitals
    VALUES ('Sacramento', 4664.E + 5, 30, 'CA')
ON CONFLICT (name)
    DO UPDATE SET
        population = excluded.population;

-- Wrong "Sacramento", so do nothing:
INSERT INTO capitals
    VALUES ('Sacramento', 50, 2267, 'NE')
ON CONFLICT (name)
    DO NOTHING;

SELECT
    *
FROM
    capitals;

INSERT INTO cities
    VALUES ('Las Vegas', 5.83E+5, 2001)
ON CONFLICT (name)
    DO UPDATE SET
        population = excluded.population,
        altitude = excluded.altitude;

SELECT
    tableoid::regclass,
    *
FROM
    cities;

INSERT INTO capitals
    VALUES ('Las Vegas', 5.83E+5, 2222, 'NV')
ON CONFLICT (name)
    DO UPDATE SET
        population = excluded.population;

-- Capitals will contain new capital, Las Vegas:
SELECT
    *
FROM
    capitals;

-- Cities contains two instances of "Las Vegas", since unique constraints don't
-- work across inheritance:
SELECT
    tableoid::regclass,
    *
FROM
    cities;

-- This only affects "cities" version of "Las Vegas":
INSERT INTO cities
    VALUES ('Las Vegas', 5.86E+5, 2223)
ON CONFLICT (name)
    DO UPDATE SET
        population = excluded.population,
        altitude = excluded.altitude;

SELECT
    tableoid::regclass,
    *
FROM
    cities;

-- clean up
DROP TABLE capitals;

DROP TABLE cities;

-- Make sure a table named excluded is handled properly
CREATE TABLE excluded (
    key int PRIMARY KEY,
    data text
);

INSERT INTO excluded
    VALUES (1, '1');

-- error, ambiguous
INSERT INTO excluded
    VALUES (1, '2')
ON CONFLICT (key)
    DO UPDATE SET
        data = excluded.data
    RETURNING
        *;

-- ok, aliased
INSERT INTO excluded AS target
    VALUES (1, '2')
ON CONFLICT (key)
    DO UPDATE SET
        data = excluded.data
    RETURNING
        *;

-- ok, aliased
INSERT INTO excluded AS target
    VALUES (1, '2')
ON CONFLICT (key)
    DO UPDATE SET
        data = target.data
    RETURNING
        *;

-- make sure excluded isn't a problem in returning clause
INSERT INTO excluded
    VALUES (1, '2')
ON CONFLICT (key)
    DO UPDATE SET
        data = 3
    RETURNING
        excluded.*;

-- clean up
DROP TABLE excluded;

-- check that references to columns after dropped columns are handled correctly
CREATE TABLE dropcol (
    key int PRIMARY KEY,
    drop1 int,
    keep1 text,
    drop2 numeric,
    keep2 float
);

INSERT INTO dropcol (key, drop1, keep1, drop2, keep2)
    VALUES (1, 1, '1', '1', 1);

-- set using excluded
INSERT INTO dropcol (key, drop1, keep1, drop2, keep2)
    VALUES (1, 2, '2', '2', 2)
ON CONFLICT (key)
    DO UPDATE SET
        drop1 = excluded.drop1,
        keep1 = excluded.keep1,
        drop2 = excluded.drop2,
        keep2 = excluded.keep2
    WHERE
        excluded.drop1 IS NOT NULL
        AND excluded.keep1 IS NOT NULL
        AND excluded.drop2 IS NOT NULL
        AND excluded.keep2 IS NOT NULL
        AND dropcol.drop1 IS NOT NULL
        AND dropcol.keep1 IS NOT NULL
        AND dropcol.drop2 IS NOT NULL
        AND dropcol.keep2 IS NOT NULL
    RETURNING
        *;

;

-- set using existing table
INSERT INTO dropcol (key, drop1, keep1, drop2, keep2)
    VALUES (1, 3, '3', '3', 3)
ON CONFLICT (key)
    DO UPDATE SET
        drop1 = dropcol.drop1,
        keep1 = dropcol.keep1,
        drop2 = dropcol.drop2,
        keep2 = dropcol.keep2
    RETURNING
        *;

;

ALTER TABLE dropcol
    DROP COLUMN drop1,
    DROP COLUMN drop2;

-- set using excluded
INSERT INTO dropcol (key, keep1, keep2)
    VALUES (1, '4', 4)
ON CONFLICT (key)
    DO UPDATE SET
        keep1 = excluded.keep1,
        keep2 = excluded.keep2
    WHERE
        excluded.keep1 IS NOT NULL
        AND excluded.keep2 IS NOT NULL
        AND dropcol.keep1 IS NOT NULL
        AND dropcol.keep2 IS NOT NULL
    RETURNING
        *;

;

-- set using existing table
INSERT INTO dropcol (key, keep1, keep2)
    VALUES (1, '5', 5)
ON CONFLICT (key)
    DO UPDATE SET
        keep1 = dropcol.keep1,
        keep2 = dropcol.keep2
    RETURNING
        *;

;

DROP TABLE dropcol;

-- check handling of regular btree constraint along with gist constraint
CREATE TABLE twoconstraints (
    f1 int UNIQUE,
    f2 box,
    EXCLUDE USING gist (f2 WITH &&)
);

INSERT INTO twoconstraints
    VALUES (1, '((0,0),(1,1))');

INSERT INTO twoconstraints
    VALUES (1, '((2,2),(3,3))');

-- fail on f1
INSERT INTO twoconstraints
    VALUES (2, '((0,0),(1,2))');

-- fail on f2
INSERT INTO twoconstraints
    VALUES (2, '((0,0),(1,2))')
ON CONFLICT ON CONSTRAINT twoconstraints_f1_key
    DO NOTHING;

-- fail on f2
INSERT INTO twoconstraints
    VALUES (2, '((0,0),(1,2))')
ON CONFLICT ON CONSTRAINT twoconstraints_f2_excl
    DO NOTHING;

-- do nothing
SELECT
    *
FROM
    twoconstraints;

DROP TABLE twoconstraints;

-- check handling of self-conflicts at various isolation levels
CREATE TABLE selfconflict (
    f1 int PRIMARY KEY,
    f2 int
);

BEGIN TRANSACTION ISOLATION level read COMMITTED;
INSERT INTO selfconflict
VALUES
    (1, 1),
    (1, 2)
ON CONFLICT
    DO NOTHING;
COMMIT;

BEGIN TRANSACTION ISOLATION level REPEATABLE read;
INSERT INTO selfconflict
VALUES
    (2, 1),
    (2, 2)
ON CONFLICT
    DO NOTHING;
COMMIT;

BEGIN TRANSACTION ISOLATION level SERIALIZABLE;
INSERT INTO selfconflict
VALUES
    (3, 1),
    (3, 2)
ON CONFLICT
    DO NOTHING;
COMMIT;

BEGIN TRANSACTION ISOLATION level read COMMITTED;
INSERT INTO selfconflict
VALUES
    (4, 1),
    (4, 2)
ON CONFLICT (f1)
    DO UPDATE SET
        f2 = 0;
COMMIT;

BEGIN TRANSACTION ISOLATION level REPEATABLE read;
INSERT INTO selfconflict
VALUES
    (5, 1),
    (5, 2)
ON CONFLICT (f1)
    DO UPDATE SET
        f2 = 0;
COMMIT;

BEGIN TRANSACTION ISOLATION level SERIALIZABLE;
INSERT INTO selfconflict
VALUES
    (6, 1),
    (6, 2)
ON CONFLICT (f1)
    DO UPDATE SET
        f2 = 0;
COMMIT;

SELECT
    *
FROM
    selfconflict;

DROP TABLE selfconflict;

-- check ON CONFLICT handling with partitioned tables
CREATE TABLE parted_conflict_test (
    a int UNIQUE,
    b char
)
PARTITION BY LIST (a);

CREATE TABLE parted_conflict_test_1 PARTITION OF parted_conflict_test (b UNIQUE)
FOR VALUES IN (1, 2);

-- no indexes required here
INSERT INTO parted_conflict_test
    VALUES (1, 'a')
ON CONFLICT
    DO NOTHING;

-- index on a required, which does exist in parent
INSERT INTO parted_conflict_test
    VALUES (1, 'a')
ON CONFLICT (a)
    DO NOTHING;

INSERT INTO parted_conflict_test
    VALUES (1, 'a')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

-- targeting partition directly will work
INSERT INTO parted_conflict_test_1
    VALUES (1, 'a')
ON CONFLICT (a)
    DO NOTHING;

INSERT INTO parted_conflict_test_1
    VALUES (1, 'b')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

-- index on b required, which doesn't exist in parent
INSERT INTO parted_conflict_test
    VALUES (2, 'b')
ON CONFLICT (b)
    DO UPDATE SET
        a = excluded.a;

-- targeting partition directly will work
INSERT INTO parted_conflict_test_1
    VALUES (2, 'b')
ON CONFLICT (b)
    DO UPDATE SET
        a = excluded.a;

-- should see (2, 'b')
SELECT
    *
FROM
    parted_conflict_test
ORDER BY
    a;

-- now check that DO UPDATE works correctly for target partition with
-- different attribute numbers
CREATE TABLE parted_conflict_test_2 (
    b char,
    a int UNIQUE
);

ALTER TABLE parted_conflict_test ATTACH PARTITION parted_conflict_test_2
FOR VALUES IN (3);

TRUNCATE parted_conflict_test;

INSERT INTO parted_conflict_test
    VALUES (3, 'a')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

INSERT INTO parted_conflict_test
    VALUES (3, 'b')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

-- should see (3, 'b')
SELECT
    *
FROM
    parted_conflict_test
ORDER BY
    a;

-- case where parent will have a dropped column, but the partition won't
ALTER TABLE parted_conflict_test
    DROP b,
    ADD b char;

CREATE TABLE parted_conflict_test_3 PARTITION OF parted_conflict_test
FOR VALUES IN (4);

TRUNCATE parted_conflict_test;

INSERT INTO parted_conflict_test (a, b)
    VALUES (4, 'a')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

INSERT INTO parted_conflict_test (a, b)
    VALUES (4, 'b')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b
    WHERE
        parted_conflict_test.b = 'a';

-- should see (4, 'b')
SELECT
    *
FROM
    parted_conflict_test
ORDER BY
    a;

-- case with multi-level partitioning
CREATE TABLE parted_conflict_test_4 PARTITION OF parted_conflict_test
FOR VALUES IN (5)
PARTITION BY LIST (a);

CREATE TABLE parted_conflict_test_4_1 PARTITION OF parted_conflict_test_4
FOR VALUES IN (5);

TRUNCATE parted_conflict_test;

INSERT INTO parted_conflict_test (a, b)
    VALUES (5, 'a')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

INSERT INTO parted_conflict_test (a, b)
    VALUES (5, 'b')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b
    WHERE
        parted_conflict_test.b = 'a';

-- should see (5, 'b')
SELECT
    *
FROM
    parted_conflict_test
ORDER BY
    a;

-- test with multiple rows
TRUNCATE parted_conflict_test;

INSERT INTO parted_conflict_test (a, b)
VALUES
    (1, 'a'),
    (2, 'a'),
    (4, 'a')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b
    WHERE
        excluded.b = 'b';

INSERT INTO parted_conflict_test (a, b)
VALUES
    (1, 'b'),
    (2, 'c'),
    (4, 'b')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b
    WHERE
        excluded.b = 'b';

-- should see (1, 'b'), (2, 'a'), (4, 'b')
SELECT
    *
FROM
    parted_conflict_test
ORDER BY
    a;

DROP TABLE parted_conflict_test;

-- test behavior of inserting a conflicting tuple into an intermediate
-- partitioning level
CREATE TABLE parted_conflict (
    a int PRIMARY KEY,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE parted_conflict_1 PARTITION OF parted_conflict
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE parted_conflict_1_1 PARTITION OF parted_conflict_1
FOR VALUES FROM (0) TO (500);

INSERT INTO parted_conflict
    VALUES (40, 'forty');

INSERT INTO parted_conflict_1
    VALUES (40, 'cuarenta')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

DROP TABLE parted_conflict;

-- same thing, but this time try to use an index that's created not in the
-- partition
CREATE TABLE parted_conflict (
    a int,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE parted_conflict_1 PARTITION OF parted_conflict
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE parted_conflict_1_1 PARTITION OF parted_conflict_1
FOR VALUES FROM (0) TO (500);

CREATE UNIQUE INDEX ON ONLY parted_conflict_1 (a);

CREATE UNIQUE INDEX ON ONLY parted_conflict (a);

ALTER INDEX parted_conflict_a_idx ATTACH PARTITION parted_conflict_1_a_idx;

INSERT INTO parted_conflict
    VALUES (40, 'forty');

INSERT INTO parted_conflict_1
    VALUES (40, 'cuarenta')
ON CONFLICT (a)
    DO UPDATE SET
        b = excluded.b;

DROP TABLE parted_conflict;

-- test whole-row Vars in ON CONFLICT expressions
CREATE TABLE parted_conflict (
    a int,
    b text,
    c int
)
PARTITION BY RANGE (a);

CREATE TABLE parted_conflict_1 (
    drp text,
    c int,
    a int,
    b text
);

ALTER TABLE parted_conflict_1
    DROP COLUMN drp;

CREATE UNIQUE INDEX ON parted_conflict (a, b);

ALTER TABLE parted_conflict ATTACH PARTITION parted_conflict_1
FOR VALUES FROM (0) TO (1000);

TRUNCATE parted_conflict;

INSERT INTO parted_conflict
    VALUES (50, 'cincuenta', 1);

INSERT INTO parted_conflict
    VALUES (50, 'cincuenta', 2)
ON CONFLICT (a, b)
    DO UPDATE SET
        (a, b, c) = ROW (excluded.*)
    WHERE
        parted_conflict = (50, text 'cincuenta', 1)
        AND excluded = (50, text 'cincuenta', 2);

-- should see (50, 'cincuenta', 2)
SELECT
    *
FROM
    parted_conflict
ORDER BY
    a;

-- test with statement level triggers
CREATE OR REPLACE FUNCTION parted_conflict_update_func ()
    RETURNS TRIGGER
    AS $$
DECLARE
    r record;
BEGIN
    FOR r IN
    SELECT
        *
    FROM
        inserted LOOP
            RAISE NOTICE 'a = %, b = %, c = %', r.a, r.b, r.c;
        END LOOP;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER parted_conflict_update
    AFTER UPDATE ON parted_conflict referencing new TABLE AS inserted FOR EACH statement
    EXECUTE PROCEDURE parted_conflict_update_func ();

TRUNCATE parted_conflict;

INSERT INTO parted_conflict
    VALUES (0, 'cero', 1);

INSERT INTO parted_conflict
    VALUES (0, 'cero', 1)
ON CONFLICT (a, b)
    DO UPDATE SET
        c = parted_conflict.c + 1;

DROP TABLE parted_conflict;

DROP FUNCTION parted_conflict_update_func ();

