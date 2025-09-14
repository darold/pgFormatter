--
-- ALTER_TABLE
--
-- Clean up in case a prior regression run failed
SET client_min_messages TO 'warning';

DROP ROLE IF EXISTS regress_alter_table_user1;

RESET client_min_messages;

CREATE USER regress_alter_table_user1;

--
-- add attribute
--
CREATE TABLE attmp (
    initial int4
);

COMMENT ON TABLE attmp_wrong IS 'table comment';

COMMENT ON TABLE attmp IS 'table comment';

COMMENT ON TABLE attmp IS NULL;

ALTER TABLE attmp
    ADD COLUMN xmin integer;

-- fails
ALTER TABLE attmp
    ADD COLUMN a int4 DEFAULT 3;

ALTER TABLE attmp
    ADD COLUMN b name;

ALTER TABLE attmp
    ADD COLUMN c text;

ALTER TABLE attmp
    ADD COLUMN d float8;

ALTER TABLE attmp
    ADD COLUMN e float4;

ALTER TABLE attmp
    ADD COLUMN f int2;

ALTER TABLE attmp
    ADD COLUMN g polygon;

ALTER TABLE attmp
    ADD COLUMN i char;

ALTER TABLE attmp
    ADD COLUMN k int4;

ALTER TABLE attmp
    ADD COLUMN l tid;

ALTER TABLE attmp
    ADD COLUMN m xid;

ALTER TABLE attmp
    ADD COLUMN n oidvector;

--ALTER TABLE attmp ADD COLUMN o lock;
ALTER TABLE attmp
    ADD COLUMN p boolean;

ALTER TABLE attmp
    ADD COLUMN q point;

ALTER TABLE attmp
    ADD COLUMN r lseg;

ALTER TABLE attmp
    ADD COLUMN s path;

ALTER TABLE attmp
    ADD COLUMN t box;

ALTER TABLE attmp
    ADD COLUMN v timestamp;

ALTER TABLE attmp
    ADD COLUMN w interval;

ALTER TABLE attmp
    ADD COLUMN x float8[];

ALTER TABLE attmp
    ADD COLUMN y float4[];

ALTER TABLE attmp
    ADD COLUMN z int2[];

INSERT INTO attmp (a, b, c, d, e, f, g, i, k, l, m, n, p, q, r, s, t, v, w, x, y, z)
    VALUES (4, 'name', 'text', 4.1, 4.1, 2, '(4.1,4.1,3.1,3.1)', 'c', 314159, '(1,1)', '512', '1 2 3 4 5 6 7 8', TRUE, '(1.1,1.1)', '(4.1,4.1,3.1,3.1)', '(0,2,4.1,4.1,3.1,3.1)', '(4.1,4.1,3.1,3.1)', 'epoch', '01:00:10', '{1.0,2.0,3.0,4.0}', '{1.0,2.0,3.0,4.0}', '{1,2,3,4}');

SELECT
    *
FROM
    attmp;

DROP TABLE attmp;

-- the wolf bug - schema mods caused inconsistent row descriptors
CREATE TABLE attmp (
    initial int4
);

ALTER TABLE attmp
    ADD COLUMN a int4;

ALTER TABLE attmp
    ADD COLUMN b name;

ALTER TABLE attmp
    ADD COLUMN c text;

ALTER TABLE attmp
    ADD COLUMN d float8;

ALTER TABLE attmp
    ADD COLUMN e float4;

ALTER TABLE attmp
    ADD COLUMN f int2;

ALTER TABLE attmp
    ADD COLUMN g polygon;

ALTER TABLE attmp
    ADD COLUMN i char;

ALTER TABLE attmp
    ADD COLUMN k int4;

ALTER TABLE attmp
    ADD COLUMN l tid;

ALTER TABLE attmp
    ADD COLUMN m xid;

ALTER TABLE attmp
    ADD COLUMN n oidvector;

--ALTER TABLE attmp ADD COLUMN o lock;
ALTER TABLE attmp
    ADD COLUMN p boolean;

ALTER TABLE attmp
    ADD COLUMN q point;

ALTER TABLE attmp
    ADD COLUMN r lseg;

ALTER TABLE attmp
    ADD COLUMN s path;

ALTER TABLE attmp
    ADD COLUMN t box;

ALTER TABLE attmp
    ADD COLUMN v timestamp;

ALTER TABLE attmp
    ADD COLUMN w interval;

ALTER TABLE attmp
    ADD COLUMN x float8[];

ALTER TABLE attmp
    ADD COLUMN y float4[];

ALTER TABLE attmp
    ADD COLUMN z int2[];

INSERT INTO attmp (a, b, c, d, e, f, g, i, k, l, m, n, p, q, r, s, t, v, w, x, y, z)
    VALUES (4, 'name', 'text', 4.1, 4.1, 2, '(4.1,4.1,3.1,3.1)', 'c', 314159, '(1,1)', '512', '1 2 3 4 5 6 7 8', TRUE, '(1.1,1.1)', '(4.1,4.1,3.1,3.1)', '(0,2,4.1,4.1,3.1,3.1)', '(4.1,4.1,3.1,3.1)', 'epoch', '01:00:10', '{1.0,2.0,3.0,4.0}', '{1.0,2.0,3.0,4.0}', '{1,2,3,4}');

SELECT
    *
FROM
    attmp;

CREATE INDEX attmp_idx ON attmp (a, (d + e), b);

ALTER INDEX attmp_idx
    ALTER COLUMN 0 SET STATISTICS 1000;

ALTER INDEX attmp_idx
    ALTER COLUMN 1 SET STATISTICS 1000;

ALTER INDEX attmp_idx
    ALTER COLUMN 2 SET STATISTICS 1000;

\d+ attmp_idx
ALTER INDEX attmp_idx
    ALTER COLUMN 3 SET STATISTICS 1000;

ALTER INDEX attmp_idx
    ALTER COLUMN 4 SET STATISTICS 1000;

ALTER INDEX attmp_idx
    ALTER COLUMN 2 SET STATISTICS - 1;

DROP TABLE attmp;

--
-- rename - check on both non-temp and temp tables
--
CREATE TABLE attmp (
    regtable int
);

CREATE TEMP TABLE attmp (
    attmptable int
);

ALTER TABLE attmp RENAME TO attmp_new;

SELECT
    *
FROM
    attmp;

SELECT
    *
FROM
    attmp_new;

ALTER TABLE attmp RENAME TO attmp_new2;

SELECT
    *
FROM
    attmp;

-- should fail
SELECT
    *
FROM
    attmp_new;

SELECT
    *
FROM
    attmp_new2;

DROP TABLE attmp_new;

DROP TABLE attmp_new2;

-- check rename of partitioned tables and indexes also
CREATE TABLE part_attmp (
    a int PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE part_attmp1 PARTITION OF part_attmp
FOR VALUES FROM (0) TO (100);

ALTER INDEX part_attmp_pkey RENAME TO part_attmp_index;

ALTER INDEX part_attmp1_pkey RENAME TO part_attmp1_index;

ALTER TABLE part_attmp RENAME TO part_at2tmp;

ALTER TABLE part_attmp1 RENAME TO part_at2tmp1;

SET ROLE regress_alter_table_user1;

ALTER INDEX part_attmp_index RENAME TO fail;

ALTER INDEX part_attmp1_index RENAME TO fail;

ALTER TABLE part_at2tmp RENAME TO fail;

ALTER TABLE part_at2tmp1 RENAME TO fail;

RESET ROLE;

DROP TABLE part_at2tmp;

--
-- check renaming to a table's array type's autogenerated name
-- (the array type's name should get out of the way)
--
CREATE TABLE attmp_array (
    id int
);

CREATE TABLE attmp_array2 (
    id int
);

SELECT
    typname
FROM
    pg_type
WHERE
    oid = 'attmp_array[]'::regtype;

SELECT
    typname
FROM
    pg_type
WHERE
    oid = 'attmp_array2[]'::regtype;

ALTER TABLE attmp_array2 RENAME TO _attmp_array;

SELECT
    typname
FROM
    pg_type
WHERE
    oid = 'attmp_array[]'::regtype;

SELECT
    typname
FROM
    pg_type
WHERE
    oid = '_attmp_array[]'::regtype;

DROP TABLE _attmp_array;

DROP TABLE attmp_array;

-- renaming to table's own array type's name is an interesting corner case
CREATE TABLE attmp_array (
    id int
);

SELECT
    typname
FROM
    pg_type
WHERE
    oid = 'attmp_array[]'::regtype;

ALTER TABLE attmp_array RENAME TO _attmp_array;

SELECT
    typname
FROM
    pg_type
WHERE
    oid = '_attmp_array[]'::regtype;

DROP TABLE _attmp_array;

-- ALTER TABLE ... RENAME on non-table relations
-- renaming indexes (FIXME: this should probably test the index's functionality)
ALTER INDEX IF EXISTS __onek_unique1 RENAME TO attmp_onek_unique1;

ALTER INDEX IF EXISTS __attmp_onek_unique1 RENAME TO onek_unique1;

ALTER INDEX onek_unique1 RENAME TO attmp_onek_unique1;

ALTER INDEX attmp_onek_unique1 RENAME TO onek_unique1;

SET ROLE regress_alter_table_user1;

ALTER INDEX onek_unique1 RENAME TO fail;

-- permission denied
RESET ROLE;

-- renaming views
CREATE VIEW attmp_view (unique1) AS
SELECT
    unique1
FROM
    tenk1;

ALTER TABLE attmp_view RENAME TO attmp_view_new;

SET ROLE regress_alter_table_user1;

ALTER VIEW attmp_view_new RENAME TO fail;

-- permission denied
RESET ROLE;

-- hack to ensure we get an indexscan here
SET enable_seqscan TO OFF;

SET enable_bitmapscan TO OFF;

-- 5 values, sorted
SELECT
    unique1
FROM
    tenk1
WHERE
    unique1 < 5;

RESET enable_seqscan;

RESET enable_bitmapscan;

DROP VIEW attmp_view_new;

-- toast-like relation name
ALTER TABLE stud_emp RENAME TO pg_toast_stud_emp;

ALTER TABLE pg_toast_stud_emp RENAME TO stud_emp;

-- renaming index should rename constraint as well
ALTER TABLE onek
    ADD CONSTRAINT onek_unique1_constraint UNIQUE (unique1);

ALTER INDEX onek_unique1_constraint RENAME TO onek_unique1_constraint_foo;

ALTER TABLE onek
    DROP CONSTRAINT onek_unique1_constraint_foo;

-- renaming constraint
ALTER TABLE onek
    ADD CONSTRAINT onek_check_constraint CHECK (unique1 >= 0);

ALTER TABLE onek RENAME CONSTRAINT onek_check_constraint TO onek_check_constraint_foo;

ALTER TABLE onek
    DROP CONSTRAINT onek_check_constraint_foo;

-- renaming constraint should rename index as well
ALTER TABLE onek
    ADD CONSTRAINT onek_unique1_constraint UNIQUE (unique1);

DROP INDEX onek_unique1_constraint;

-- to see whether it's there
ALTER TABLE onek RENAME CONSTRAINT onek_unique1_constraint TO onek_unique1_constraint_foo;

DROP INDEX onek_unique1_constraint_foo;

-- to see whether it's there
ALTER TABLE onek
    DROP CONSTRAINT onek_unique1_constraint_foo;

-- renaming constraints vs. inheritance
CREATE TABLE constraint_rename_test (
    a int CONSTRAINT con1 CHECK (a > 0),
    b int,
    c int
);

\d constraint_rename_test
CREATE TABLE constraint_rename_test2 (
    a int CONSTRAINT con1 CHECK (a > 0),
    d int
)
INHERITS (
    constraint_rename_test
);

\d constraint_rename_test2
ALTER TABLE constraint_rename_test2 RENAME CONSTRAINT con1 TO con1foo;

-- fail
ALTER TABLE ONLY constraint_rename_test RENAME CONSTRAINT con1 TO con1foo;

-- fail
ALTER TABLE constraint_rename_test RENAME CONSTRAINT con1 TO con1foo;

-- ok
\d constraint_rename_test
\d constraint_rename_test2
ALTER TABLE constraint_rename_test
    ADD CONSTRAINT con2 CHECK (b > 0) NO INHERIT;

ALTER TABLE ONLY constraint_rename_test RENAME CONSTRAINT con2 TO con2foo;

-- ok
ALTER TABLE constraint_rename_test RENAME CONSTRAINT con2foo TO con2bar;

-- ok
\d constraint_rename_test
\d constraint_rename_test2
ALTER TABLE constraint_rename_test
    ADD CONSTRAINT con3 PRIMARY KEY (a);

ALTER TABLE constraint_rename_test RENAME CONSTRAINT con3 TO con3foo;

-- ok
\d constraint_rename_test
\d constraint_rename_test2
DROP TABLE constraint_rename_test2;

DROP TABLE constraint_rename_test;

ALTER TABLE IF EXISTS constraint_not_exist RENAME CONSTRAINT con3 TO con3foo;

-- ok
ALTER TABLE IF EXISTS constraint_rename_test
    ADD CONSTRAINT con4 UNIQUE (a);

-- renaming constraints with cache reset of target relation
CREATE TABLE constraint_rename_cache (
    a int,
    CONSTRAINT chk_a CHECK (a > 0),
    PRIMARY KEY (a)
);

ALTER TABLE constraint_rename_cache RENAME CONSTRAINT chk_a TO chk_a_new;

ALTER TABLE constraint_rename_cache RENAME CONSTRAINT constraint_rename_cache_pkey TO constraint_rename_pkey_new;

CREATE TABLE like_constraint_rename_cache (
    LIKE constraint_rename_cache INCLUDING ALL
);

\d like_constraint_rename_cache
DROP TABLE constraint_rename_cache;

DROP TABLE like_constraint_rename_cache;

-- FOREIGN KEY CONSTRAINT adding TEST
CREATE TABLE attmp2 (
    a int PRIMARY KEY
);

CREATE TABLE attmp3 (
    a int,
    b int
);

CREATE TABLE attmp4 (
    a int,
    b int,
    UNIQUE (a, b)
);

CREATE TABLE attmp5 (
    a int,
    b int
);

-- Insert rows into attmp2 (pktable)
INSERT INTO attmp2
    VALUES (1);

INSERT INTO attmp2
    VALUES (2);

INSERT INTO attmp2
    VALUES (3);

INSERT INTO attmp2
    VALUES (4);

-- Insert rows into attmp3
INSERT INTO attmp3
    VALUES (1, 10);

INSERT INTO attmp3
    VALUES (1, 20);

INSERT INTO attmp3
    VALUES (5, 50);

-- Try (and fail) to add constraint due to invalid source columns
ALTER TABLE attmp3
    ADD CONSTRAINT attmpconstr FOREIGN KEY (c) REFERENCES attmp2 MATCH FULL;

-- Try (and fail) to add constraint due to invalid destination columns explicitly given
ALTER TABLE attmp3
    ADD CONSTRAINT attmpconstr FOREIGN KEY (a) REFERENCES attmp2 (b) MATCH FULL;

-- Try (and fail) to add constraint due to invalid data
ALTER TABLE attmp3
    ADD CONSTRAINT attmpconstr FOREIGN KEY (a) REFERENCES attmp2 MATCH FULL;

-- Delete failing row
DELETE FROM attmp3
WHERE a = 5;

-- Try (and succeed)
ALTER TABLE attmp3
    ADD CONSTRAINT attmpconstr FOREIGN KEY (a) REFERENCES attmp2 MATCH FULL;

ALTER TABLE attmp3
    DROP CONSTRAINT attmpconstr;

INSERT INTO attmp3
    VALUES (5, 50);

-- Try NOT VALID and then VALIDATE CONSTRAINT, but fails. Delete failure then re-validate
ALTER TABLE attmp3
    ADD CONSTRAINT attmpconstr FOREIGN KEY (a) REFERENCES attmp2 MATCH FULL NOT VALID;

ALTER TABLE attmp3 validate CONSTRAINT attmpconstr;

-- Delete failing row
DELETE FROM attmp3
WHERE a = 5;

-- Try (and succeed) and repeat to show it works on already valid constraint
ALTER TABLE attmp3 validate CONSTRAINT attmpconstr;

ALTER TABLE attmp3 validate CONSTRAINT attmpconstr;

-- Try a non-verified CHECK constraint
ALTER TABLE attmp3
    ADD CONSTRAINT b_greater_than_ten CHECK (b > 10);

-- fail
ALTER TABLE attmp3
    ADD CONSTRAINT b_greater_than_ten CHECK (b > 10) NOT VALID;

-- succeeds
ALTER TABLE attmp3 VALIDATE CONSTRAINT b_greater_than_ten;

-- fails
DELETE FROM attmp3
WHERE NOT b > 10;

ALTER TABLE attmp3 VALIDATE CONSTRAINT b_greater_than_ten;

-- succeeds
ALTER TABLE attmp3 VALIDATE CONSTRAINT b_greater_than_ten;

-- succeeds
-- Test inherited NOT VALID CHECK constraints
SELECT
    *
FROM
    attmp3;

CREATE TABLE attmp6 ()
INHERITS (
    attmp3
);

CREATE TABLE attmp7 ()
INHERITS (
    attmp3
);

INSERT INTO attmp6
VALUES
    (6, 30),
    (7, 16);

ALTER TABLE attmp3
    ADD CONSTRAINT b_le_20 CHECK (b <= 20) NOT VALID;

ALTER TABLE attmp3 VALIDATE CONSTRAINT b_le_20;

-- fails
DELETE FROM attmp6
WHERE b > 20;

ALTER TABLE attmp3 VALIDATE CONSTRAINT b_le_20;

-- succeeds
-- An already validated constraint must not be revalidated
CREATE FUNCTION boo (int)
    RETURNS int IMMUTABLE STRICT
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'boo: %', $1;
    RETURN $1;
END;
$$;

INSERT INTO attmp7
    VALUES (8, 18);

ALTER TABLE attmp7
    ADD CONSTRAINT IDENTITY CHECK (b = boo (b));

ALTER TABLE attmp3
    ADD CONSTRAINT IDENTITY CHECK (b = boo (b)) NOT VALID;

ALTER TABLE attmp3 VALIDATE CONSTRAINT IDENTITY;

-- A NO INHERIT constraint should not be looked for in children during VALIDATE CONSTRAINT
CREATE TABLE parent_noinh_convalid (
    a int
);

CREATE TABLE child_noinh_convalid ()
INHERITS (
    parent_noinh_convalid
);

INSERT INTO parent_noinh_convalid
    VALUES (1);

INSERT INTO child_noinh_convalid
    VALUES (1);

ALTER TABLE parent_noinh_convalid
    ADD CONSTRAINT check_a_is_2 CHECK (a = 2) NO inherit NOT valid;

-- fail, because of the row in parent
ALTER TABLE parent_noinh_convalid validate CONSTRAINT check_a_is_2;

DELETE FROM ONLY parent_noinh_convalid;

-- ok (parent itself contains no violating rows)
ALTER TABLE parent_noinh_convalid validate CONSTRAINT check_a_is_2;

SELECT
    convalidated
FROM
    pg_constraint
WHERE
    conrelid = 'parent_noinh_convalid'::regclass
    AND conname = 'check_a_is_2';

-- cleanup
DROP TABLE parent_noinh_convalid, child_noinh_convalid;

-- Try (and fail) to create constraint from attmp5(a) to attmp4(a) - unique constraint on
-- attmp4 is a,b
ALTER TABLE attmp5
    ADD CONSTRAINT attmpconstr FOREIGN KEY (a) REFERENCES attmp4 (a) MATCH FULL;

DROP TABLE attmp7;

DROP TABLE attmp6;

DROP TABLE attmp5;

DROP TABLE attmp4;

DROP TABLE attmp3;

DROP TABLE attmp2;

-- NOT VALID with plan invalidation -- ensure we don't use a constraint for
-- exclusion until validated
SET constraint_exclusion TO 'partition';

CREATE TABLE nv_parent (
    d date,
    CHECK (FALSE) NO inherit NOT valid
);

-- not valid constraint added at creation time should automatically become valid
\d nv_parent
CREATE TABLE nv_child_2010 ()
INHERITS (
    nv_parent
);

CREATE TABLE nv_child_2011 ()
INHERITS (
    nv_parent
);

ALTER TABLE nv_child_2010
    ADD CHECK (d BETWEEN '2010-01-01'::date AND '2010-12-31'::date) NOT valid;

ALTER TABLE nv_child_2011
    ADD CHECK (d BETWEEN '2011-01-01'::date AND '2011-12-31'::date) NOT valid;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    nv_parent
WHERE
    d BETWEEN '2011-08-01' AND '2011-08-31';

CREATE TABLE nv_child_2009 (
    CHECK (d BETWEEN '2009-01-01'::date AND '2009-12-31'::date)
)
INHERITS (
    nv_parent
);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    nv_parent
WHERE
    d BETWEEN '2011-08-01'::date AND '2011-08-31'::date;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    nv_parent
WHERE
    d BETWEEN '2009-08-01'::date AND '2009-08-31'::date;

-- after validation, the constraint should be used
ALTER TABLE nv_child_2011 VALIDATE CONSTRAINT nv_child_2011_d_check;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    nv_parent
WHERE
    d BETWEEN '2009-08-01'::date AND '2009-08-31'::date;

-- add an inherited NOT VALID constraint
ALTER TABLE nv_parent
    ADD CHECK (d BETWEEN '2001-01-01'::date AND '2099-12-31'::date) NOT valid;

\d nv_child_2009
-- we leave nv_parent and children around to help test pg_dump logic
-- Foreign key adding test with mixed types
-- Note: these tables are TEMP to avoid name conflicts when this test
-- is run in parallel with foreign_key.sql.
CREATE TEMP TABLE PKTABLE (
    ptest1 int PRIMARY KEY
);

INSERT INTO PKTABLE
    VALUES (42);

CREATE TEMP TABLE FKTABLE (
    ftest1 inet
);

-- This next should fail, because int=inet does not exist
ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1) REFERENCES pktable;

-- This should also fail for the same reason, but here we
-- give the column name
ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1) REFERENCES pktable (ptest1);

DROP TABLE FKTABLE;

-- This should succeed, even though they are different types,
-- because int=int8 exists and is a member of the integer opfamily
CREATE TEMP TABLE FKTABLE (
    ftest1 int8
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1) REFERENCES pktable;

-- Check it actually works
INSERT INTO FKTABLE
    VALUES (42);

-- should succeed
INSERT INTO FKTABLE
    VALUES (43);

-- should fail
DROP TABLE FKTABLE;

-- This should fail, because we'd have to cast numeric to int which is
-- not an implicit coercion (or use numeric=numeric, but that's not part
-- of the integer opfamily)
CREATE TEMP TABLE FKTABLE (
    ftest1 numeric
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1) REFERENCES pktable;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- On the other hand, this should work because int implicitly promotes to
-- numeric, and we allow promotion on the FK side
CREATE TEMP TABLE PKTABLE (
    ptest1 numeric PRIMARY KEY
);

INSERT INTO PKTABLE
    VALUES (42);

CREATE TEMP TABLE FKTABLE (
    ftest1 int
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1) REFERENCES pktable;

-- Check it actually works
INSERT INTO FKTABLE
    VALUES (42);

-- should succeed
INSERT INTO FKTABLE
    VALUES (43);

-- should fail
DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

CREATE TEMP TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    PRIMARY KEY (ptest1, ptest2)
);

-- This should fail, because we just chose really odd types
CREATE TEMP TABLE FKTABLE (
    ftest1 cidr,
    ftest2 timestamp
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1, ftest2) REFERENCES pktable;

DROP TABLE FKTABLE;

-- Again, so should this...
CREATE TEMP TABLE FKTABLE (
    ftest1 cidr,
    ftest2 timestamp
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest1, ptest2);

DROP TABLE FKTABLE;

-- This fails because we mixed up the column ordering
CREATE TEMP TABLE FKTABLE (
    ftest1 int,
    ftest2 inet
);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest2, ptest1);

-- As does this...
ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest2, ftest1) REFERENCES pktable (ptest1, ptest2);

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- Test that ALTER CONSTRAINT updates trigger deferrability properly
CREATE TEMP TABLE PKTABLE (
    ptest1 int PRIMARY KEY
);

CREATE TEMP TABLE FKTABLE (
    ftest1 int
);

ALTER TABLE FKTABLE
    ADD CONSTRAINT fknd FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION NOT DEFERRABLE;

ALTER TABLE FKTABLE
    ADD CONSTRAINT fkdd FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE FKTABLE
    ADD CONSTRAINT fkdi FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE FKTABLE
    ADD CONSTRAINT fknd2 FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE FKTABLE
    ALTER CONSTRAINT fknd2 NOT DEFERRABLE;

ALTER TABLE FKTABLE
    ADD CONSTRAINT fkdd2 FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION NOT DEFERRABLE;

ALTER TABLE FKTABLE
    ALTER CONSTRAINT fkdd2 DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE FKTABLE
    ADD CONSTRAINT fkdi2 FOREIGN KEY (ftest1) REFERENCES pktable ON DELETE CASCADE ON UPDATE NO ACTION NOT DEFERRABLE;

ALTER TABLE FKTABLE
    ALTER CONSTRAINT fkdi2 DEFERRABLE INITIALLY IMMEDIATE;

SELECT
    conname,
    tgfoid::regproc,
    tgtype,
    tgdeferrable,
    tginitdeferred
FROM
    pg_trigger
    JOIN pg_constraint con ON con.oid = tgconstraint
WHERE
    tgrelid = 'pktable'::regclass
ORDER BY
    1,
    2,
    3;

SELECT
    conname,
    tgfoid::regproc,
    tgtype,
    tgdeferrable,
    tginitdeferred
FROM
    pg_trigger
    JOIN pg_constraint con ON con.oid = tgconstraint
WHERE
    tgrelid = 'fktable'::regclass
ORDER BY
    1,
    2,
    3;

-- temp tables should go away by themselves, need not drop them.
-- test check constraint adding
CREATE TABLE atacc1 (
    test int
);

-- add a check constraint
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 CHECK (test > 3);

-- should fail
INSERT INTO atacc1 (test)
    VALUES (2);

-- should succeed
INSERT INTO atacc1 (test)
    VALUES (4);

DROP TABLE atacc1;

-- let's do one where the check fails when added
CREATE TABLE atacc1 (
    test int
);

-- insert a soon to be failing row
INSERT INTO atacc1 (test)
    VALUES (2);

-- add a check constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 CHECK (test > 3);

INSERT INTO atacc1 (test)
    VALUES (4);

DROP TABLE atacc1;

-- let's do one where the check fails because the column doesn't exist
CREATE TABLE atacc1 (
    test int
);

-- add a check constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 CHECK (test1 > 3);

DROP TABLE atacc1;

-- something a little more complicated
CREATE TABLE atacc1 (
    test int,
    test2 int,
    test3 int
);

-- add a check constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 CHECK (test + test2 < test3 * 4);

-- should fail
INSERT INTO atacc1 (test, test2, test3)
    VALUES (4, 4, 2);

-- should succeed
INSERT INTO atacc1 (test, test2, test3)
    VALUES (4, 4, 5);

DROP TABLE atacc1;

-- lets do some naming tests
CREATE TABLE atacc1 (
    test int CHECK (test > 3),
    test2 int
);

ALTER TABLE atacc1
    ADD CHECK (test2 > test);

-- should fail for $2
INSERT INTO atacc1 (test2, test)
    VALUES (3, 4);

DROP TABLE atacc1;

-- inheritance related tests
CREATE TABLE atacc1 (
    test int
);

CREATE TABLE atacc2 (
    test2 int
);

CREATE TABLE atacc3 (
    test3 int
)
INHERITS (
    atacc1,
    atacc2
);

ALTER TABLE atacc2
    ADD CONSTRAINT foo CHECK (test2 > 0);

-- fail and then succeed on atacc2
INSERT INTO atacc2 (test2)
    VALUES (-3);

INSERT INTO atacc2 (test2)
    VALUES (3);

-- fail and then succeed on atacc3
INSERT INTO atacc3 (test2)
    VALUES (-3);

INSERT INTO atacc3 (test2)
    VALUES (3);

DROP TABLE atacc3;

DROP TABLE atacc2;

DROP TABLE atacc1;

-- same things with one created with INHERIT
CREATE TABLE atacc1 (
    test int
);

CREATE TABLE atacc2 (
    test2 int
);

CREATE TABLE atacc3 (
    test3 int
)
INHERITS (
    atacc1,
    atacc2
);

ALTER TABLE atacc3 NO inherit atacc2;

-- fail
ALTER TABLE atacc3 NO inherit atacc2;

-- make sure it really isn't a child
INSERT INTO atacc3 (test2)
    VALUES (3);

SELECT
    test2
FROM
    atacc2;

-- fail due to missing constraint
ALTER TABLE atacc2
    ADD CONSTRAINT foo CHECK (test2 > 0);

ALTER TABLE atacc3 inherit atacc2;

-- fail due to missing column
ALTER TABLE atacc3 RENAME test2 TO testx;

ALTER TABLE atacc3 inherit atacc2;

-- fail due to mismatched data type
ALTER TABLE atacc3
    ADD test2 bool;

ALTER TABLE atacc3 inherit atacc2;

ALTER TABLE atacc3
    DROP test2;

-- succeed
ALTER TABLE atacc3
    ADD test2 int;

UPDATE
    atacc3
SET
    test2 = 4
WHERE
    test2 IS NULL;

ALTER TABLE atacc3
    ADD CONSTRAINT foo CHECK (test2 > 0);

ALTER TABLE atacc3 inherit atacc2;

-- fail due to duplicates and circular inheritance
ALTER TABLE atacc3 inherit atacc2;

ALTER TABLE atacc2 inherit atacc3;

ALTER TABLE atacc2 inherit atacc2;

-- test that we really are a child now (should see 4 not 3 and cascade should go through)
SELECT
    test2
FROM
    atacc2;

DROP TABLE atacc2 CASCADE;

DROP TABLE atacc1;

-- adding only to a parent is allowed as of 9.2
CREATE TABLE atacc1 (
    test int
);

CREATE TABLE atacc2 (
    test2 int
)
INHERITS (
    atacc1
);

-- ok:
ALTER TABLE atacc1
    ADD CONSTRAINT foo CHECK (test > 0) NO inherit;

-- check constraint is not there on child
INSERT INTO atacc2 (test)
    VALUES (-3);

-- check constraint is there on parent
INSERT INTO atacc1 (test)
    VALUES (-3);

INSERT INTO atacc1 (test)
    VALUES (3);

-- fail, violating row:
ALTER TABLE atacc2
    ADD CONSTRAINT foo CHECK (test > 0) NO inherit;

DROP TABLE atacc2;

DROP TABLE atacc1;

-- test unique constraint adding
CREATE TABLE atacc1 (
    test int
);

-- add a unique constraint
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 UNIQUE (test);

-- insert first value
INSERT INTO atacc1 (test)
    VALUES (2);

-- should fail
INSERT INTO atacc1 (test)
    VALUES (2);

-- should succeed
INSERT INTO atacc1 (test)
    VALUES (4);

-- try to create duplicates via alter table using - should fail
ALTER TABLE atacc1
    ALTER COLUMN test TYPE integer
    USING 0;

DROP TABLE atacc1;

-- let's do one where the unique constraint fails when added
CREATE TABLE atacc1 (
    test int
);

-- insert soon to be failing rows
INSERT INTO atacc1 (test)
    VALUES (2);

INSERT INTO atacc1 (test)
    VALUES (2);

-- add a unique constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 UNIQUE (test);

INSERT INTO atacc1 (test)
    VALUES (3);

DROP TABLE atacc1;

-- let's do one where the unique constraint fails
-- because the column doesn't exist
CREATE TABLE atacc1 (
    test int
);

-- add a unique constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 UNIQUE (test1);

DROP TABLE atacc1;

-- something a little more complicated
CREATE TABLE atacc1 (
    test int,
    test2 int
);

-- add a unique constraint
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 UNIQUE (test, test2);

-- insert initial value
INSERT INTO atacc1 (test, test2)
    VALUES (4, 4);

-- should fail
INSERT INTO atacc1 (test, test2)
    VALUES (4, 4);

-- should all succeed
INSERT INTO atacc1 (test, test2)
    VALUES (4, 5);

INSERT INTO atacc1 (test, test2)
    VALUES (5, 4);

INSERT INTO atacc1 (test, test2)
    VALUES (5, 5);

DROP TABLE atacc1;

-- lets do some naming tests
CREATE TABLE atacc1 (
    test int,
    test2 int,
    UNIQUE (test)
);

ALTER TABLE atacc1
    ADD UNIQUE (test2);

-- should fail for @@ second one @@
INSERT INTO atacc1 (test2, test)
    VALUES (3, 3);

INSERT INTO atacc1 (test2, test)
    VALUES (2, 3);

DROP TABLE atacc1;

-- test primary key constraint adding
CREATE TABLE atacc1 (
    id serial,
    test int
);

-- add a primary key constraint
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 PRIMARY KEY (test);

-- insert first value
INSERT INTO atacc1 (test)
    VALUES (2);

-- should fail
INSERT INTO atacc1 (test)
    VALUES (2);

-- should succeed
INSERT INTO atacc1 (test)
    VALUES (4);

-- inserting NULL should fail
INSERT INTO atacc1 (test)
    VALUES (NULL);

-- try adding a second primary key (should fail)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_oid1 PRIMARY KEY (id);

-- drop first primary key constraint
ALTER TABLE atacc1
    DROP CONSTRAINT atacc_test1 RESTRICT;

-- try adding a primary key on oid (should succeed)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_oid1 PRIMARY KEY (id);

DROP TABLE atacc1;

-- let's do one where the primary key constraint fails when added
CREATE TABLE atacc1 (
    test int
);

-- insert soon to be failing rows
INSERT INTO atacc1 (test)
    VALUES (2);

INSERT INTO atacc1 (test)
    VALUES (2);

-- add a primary key (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 PRIMARY KEY (test);

INSERT INTO atacc1 (test)
    VALUES (3);

DROP TABLE atacc1;

-- let's do another one where the primary key constraint fails when added
CREATE TABLE atacc1 (
    test int
);

-- insert soon to be failing row
INSERT INTO atacc1 (test)
    VALUES (NULL);

-- add a primary key (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 PRIMARY KEY (test);

INSERT INTO atacc1 (test)
    VALUES (3);

DROP TABLE atacc1;

-- let's do one where the primary key constraint fails
-- because the column doesn't exist
CREATE TABLE atacc1 (
    test int
);

-- add a primary key constraint (fails)
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 PRIMARY KEY (test1);

DROP TABLE atacc1;

-- adding a new column as primary key to a non-empty table.
-- should fail unless the column has a non-null default value.
CREATE TABLE atacc1 (
    test int
);

INSERT INTO atacc1 (test)
    VALUES (0);

-- add a primary key column without a default (fails).
ALTER TABLE atacc1
    ADD COLUMN test2 int PRIMARY KEY;

-- now add a primary key column with a default (succeeds).
ALTER TABLE atacc1
    ADD COLUMN test2 int DEFAULT 0 PRIMARY KEY;

DROP TABLE atacc1;

-- this combination used to have order-of-execution problems (bug #15580)
CREATE TABLE atacc1 (
    a int
);

INSERT INTO atacc1
    VALUES (1);

ALTER TABLE atacc1
    ADD COLUMN b float8 NOT NULL DEFAULT random(),
    ADD PRIMARY KEY (a);

DROP TABLE atacc1;

-- something a little more complicated
CREATE TABLE atacc1 (
    test int,
    test2 int
);

-- add a primary key constraint
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test1 PRIMARY KEY (test, test2);

-- try adding a second primary key - should fail
ALTER TABLE atacc1
    ADD CONSTRAINT atacc_test2 PRIMARY KEY (test);

-- insert initial value
INSERT INTO atacc1 (test, test2)
    VALUES (4, 4);

-- should fail
INSERT INTO atacc1 (test, test2)
    VALUES (4, 4);

INSERT INTO atacc1 (test, test2)
    VALUES (NULL, 3);

INSERT INTO atacc1 (test, test2)
    VALUES (3, NULL);

INSERT INTO atacc1 (test, test2)
    VALUES (NULL, NULL);

-- should all succeed
INSERT INTO atacc1 (test, test2)
    VALUES (4, 5);

INSERT INTO atacc1 (test, test2)
    VALUES (5, 4);

INSERT INTO atacc1 (test, test2)
    VALUES (5, 5);

DROP TABLE atacc1;

-- lets do some naming tests
CREATE TABLE atacc1 (
    test int,
    test2 int,
    PRIMARY KEY (test)
);

-- only first should succeed
INSERT INTO atacc1 (test2, test)
    VALUES (3, 3);

INSERT INTO atacc1 (test2, test)
    VALUES (2, 3);

INSERT INTO atacc1 (test2, test)
    VALUES (1, NULL);

DROP TABLE atacc1;

-- alter table / alter column [set/drop] not null tests
-- try altering system catalogs, should fail
ALTER TABLE pg_class
    ALTER COLUMN relname DROP NOT NULL;

ALTER TABLE pg_class
    ALTER relname SET NOT NULL;

-- try altering non-existent table, should fail
ALTER TABLE non_existent
    ALTER COLUMN bar SET NOT NULL;

ALTER TABLE non_existent
    ALTER COLUMN bar DROP NOT NULL;

-- test setting columns to null and not null and vice versa
-- test checking for null values and primary key
CREATE TABLE atacc1 (
    test int NOT NULL
);

ALTER TABLE atacc1
    ADD CONSTRAINT "atacc1_pkey" PRIMARY KEY (test);

ALTER TABLE atacc1
    ALTER COLUMN test DROP NOT NULL;

ALTER TABLE atacc1
    DROP CONSTRAINT "atacc1_pkey";

ALTER TABLE atacc1
    ALTER COLUMN test DROP NOT NULL;

INSERT INTO atacc1
    VALUES (NULL);

ALTER TABLE atacc1
    ALTER test SET NOT NULL;

DELETE FROM atacc1;

ALTER TABLE atacc1
    ALTER test SET NOT NULL;

-- try altering a non-existent column, should fail
ALTER TABLE atacc1
    ALTER bar SET NOT NULL;

ALTER TABLE atacc1
    ALTER bar DROP NOT NULL;

-- try creating a view and altering that, should fail
CREATE VIEW myview AS
SELECT
    *
FROM
    atacc1;

ALTER TABLE myview
    ALTER COLUMN test DROP NOT NULL;

ALTER TABLE myview
    ALTER COLUMN test SET NOT NULL;

DROP VIEW myview;

DROP TABLE atacc1;

-- set not null verified by constraints
CREATE TABLE atacc1 (
    test_a int,
    test_b int
);

INSERT INTO atacc1
    VALUES (NULL, 1);

-- constraint not cover all values, should fail
ALTER TABLE atacc1
    ADD CONSTRAINT atacc1_constr_or CHECK (test_a IS NOT NULL OR test_b < 10);

ALTER TABLE atacc1
    ALTER test_a SET NOT NULL;

ALTER TABLE atacc1
    DROP CONSTRAINT atacc1_constr_or;

-- not valid constraint, should fail
ALTER TABLE atacc1
    ADD CONSTRAINT atacc1_constr_invalid CHECK (test_a IS NOT NULL) NOT valid;

ALTER TABLE atacc1
    ALTER test_a SET NOT NULL;

ALTER TABLE atacc1
    DROP CONSTRAINT atacc1_constr_invalid;

-- with valid constraint
UPDATE
    atacc1
SET
    test_a = 1;

ALTER TABLE atacc1
    ADD CONSTRAINT atacc1_constr_a_valid CHECK (test_a IS NOT NULL);

ALTER TABLE atacc1
    ALTER test_a SET NOT NULL;

DELETE FROM atacc1;

INSERT INTO atacc1
    VALUES (2, NULL);

ALTER TABLE atacc1
    ALTER test_a DROP NOT NULL;

-- test multiple set not null at same time
-- test_a checked by atacc1_constr_a_valid, test_b should fail by table scan
ALTER TABLE atacc1
    ALTER test_a SET NOT NULL,
    ALTER test_b SET NOT NULL;

-- commands order has no importance
ALTER TABLE atacc1
    ALTER test_b SET NOT NULL,
    ALTER test_a SET NOT NULL;

-- valid one by table scan, one by check constraints
UPDATE
    atacc1
SET
    test_b = 1;

ALTER TABLE atacc1
    ALTER test_b SET NOT NULL,
    ALTER test_a SET NOT NULL;

ALTER TABLE atacc1
    ALTER test_a DROP NOT NULL,
    ALTER test_b DROP NOT NULL;

-- both column has check constraints
ALTER TABLE atacc1
    ADD CONSTRAINT atacc1_constr_b_valid CHECK (test_b IS NOT NULL);

ALTER TABLE atacc1
    ALTER test_b SET NOT NULL,
    ALTER test_a SET NOT NULL;

DROP TABLE atacc1;

-- test inheritance
CREATE TABLE parent (
    a int
);

CREATE TABLE child (
    b varchar(255)
)
INHERITS (
    parent
);

ALTER TABLE parent
    ALTER a SET NOT NULL;

INSERT INTO parent
    VALUES (NULL);

INSERT INTO child (a, b)
    VALUES (NULL, 'foo');

ALTER TABLE parent
    ALTER a DROP NOT NULL;

INSERT INTO parent
    VALUES (NULL);

INSERT INTO child (a, b)
    VALUES (NULL, 'foo');

ALTER TABLE ONLY parent
    ALTER a SET NOT NULL;

ALTER TABLE child
    ALTER a SET NOT NULL;

DELETE FROM parent;

ALTER TABLE ONLY parent
    ALTER a SET NOT NULL;

INSERT INTO parent
    VALUES (NULL);

ALTER TABLE child
    ALTER a SET NOT NULL;

INSERT INTO child (a, b)
    VALUES (NULL, 'foo');

DELETE FROM child;

ALTER TABLE child
    ALTER a SET NOT NULL;

INSERT INTO child (a, b)
    VALUES (NULL, 'foo');

DROP TABLE child;

DROP TABLE parent;

-- test setting and removing default values
CREATE TABLE def_test (
    c1 int4 DEFAULT 5,
    c2 text DEFAULT 'initial_default'
);

INSERT INTO def_test DEFAULT VALUES; ALTER TABLE def_test
    ALTER COLUMN c1 DROP DEFAULT;

INSERT INTO def_test DEFAULT VALUES; ALTER TABLE def_test
    ALTER COLUMN c2 DROP DEFAULT;

INSERT INTO def_test DEFAULT VALUES; ALTER TABLE def_test
    ALTER COLUMN c1 SET DEFAULT 10;

ALTER TABLE def_test
    ALTER COLUMN c2 SET DEFAULT 'new_default';

INSERT INTO def_test DEFAULT VALUES;
SELECT
    *
FROM
    def_test;

-- set defaults to an incorrect type: this should fail
ALTER TABLE def_test
    ALTER COLUMN c1 SET DEFAULT 'wrong_datatype';

ALTER TABLE def_test
    ALTER COLUMN c2 SET DEFAULT 20;

-- set defaults on a non-existent column: this should fail
ALTER TABLE def_test
    ALTER COLUMN c3 SET DEFAULT 30;

-- set defaults on views: we need to create a view, add a rule
-- to allow insertions into it, and then alter the view to add
-- a default
CREATE VIEW def_view_test AS
SELECT
    *
FROM
    def_test;

CREATE RULE def_view_test_ins AS ON INSERT TO def_view_test
    DO INSTEAD
    INSERT INTO def_test
    SELECT
        NEW.*;

INSERT INTO def_view_test DEFAULT VALUES; ALTER TABLE def_view_test
    ALTER COLUMN c1 SET DEFAULT 45;

INSERT INTO def_view_test DEFAULT VALUES; ALTER TABLE def_view_test
    ALTER COLUMN c2 SET DEFAULT 'view_default';

INSERT INTO def_view_test DEFAULT VALUES;
SELECT
    *
FROM
    def_view_test;

DROP RULE def_view_test_ins ON def_view_test;

DROP VIEW def_view_test;

DROP TABLE def_test;

-- alter table / drop column tests
-- try altering system catalogs, should fail
ALTER TABLE pg_class
    DROP COLUMN relname;

-- try altering non-existent table, should fail
ALTER TABLE nosuchtable
    DROP COLUMN bar;

-- test dropping columns
CREATE TABLE atacc1 (
    a int4 NOT NULL,
    b int4,
    c int4 NOT NULL,
    d int4
);

INSERT INTO atacc1
    VALUES (1, 2, 3, 4);

ALTER TABLE atacc1
    DROP a;

ALTER TABLE atacc1
    DROP a;

-- SELECTs
SELECT
    *
FROM
    atacc1;

SELECT
    *
FROM
    atacc1
ORDER BY
    a;

SELECT
    *
FROM
    atacc1
ORDER BY
    "........pg.dropped.1........";

SELECT
    *
FROM
    atacc1
GROUP BY
    a;

SELECT
    *
FROM
    atacc1
GROUP BY
    "........pg.dropped.1........";

SELECT
    atacc1.*
FROM
    atacc1;

SELECT
    a
FROM
    atacc1;

SELECT
    atacc1.a
FROM
    atacc1;

SELECT
    b,
    c,
    d
FROM
    atacc1;

SELECT
    a,
    b,
    c,
    d
FROM
    atacc1;

SELECT
    *
FROM
    atacc1
WHERE
    a = 1;

SELECT
    "........pg.dropped.1........"
FROM
    atacc1;

SELECT
    atacc1."........pg.dropped.1........"
FROM
    atacc1;

SELECT
    "........pg.dropped.1........",
    b,
    c,
    d
FROM
    atacc1;

SELECT
    *
FROM
    atacc1
WHERE
    "........pg.dropped.1........" = 1;

-- UPDATEs
UPDATE
    atacc1
SET
    a = 3;

UPDATE
    atacc1
SET
    b = 2
WHERE
    a = 3;

UPDATE
    atacc1
SET
    "........pg.dropped.1........" = 3;

UPDATE
    atacc1
SET
    b = 2
WHERE
    "........pg.dropped.1........" = 3;

-- INSERTs
INSERT INTO atacc1
    VALUES (10, 11, 12, 13);

INSERT INTO atacc1
    VALUES (DEFAULT, 11, 12, 13);

INSERT INTO atacc1
    VALUES (11, 12, 13);

INSERT INTO atacc1 (a)
    VALUES (10);

INSERT INTO atacc1 (a)
    VALUES (DEFAULT);

INSERT INTO atacc1 (a, b, c, d)
    VALUES (10, 11, 12, 13);

INSERT INTO atacc1 (a, b, c, d)
    VALUES (DEFAULT, 11, 12, 13);

INSERT INTO atacc1 (b, c, d)
    VALUES (11, 12, 13);

INSERT INTO atacc1 ("........pg.dropped.1........")
    VALUES (10);

INSERT INTO atacc1 ("........pg.dropped.1........")
    VALUES (DEFAULT);

INSERT INTO atacc1 ("........pg.dropped.1........", b, c, d)
    VALUES (10, 11, 12, 13);

INSERT INTO atacc1 ("........pg.dropped.1........", b, c, d)
    VALUES (DEFAULT, 11, 12, 13);

-- DELETEs
DELETE FROM atacc1
WHERE a = 3;

DELETE FROM atacc1
WHERE "........pg.dropped.1........" = 3;

DELETE FROM atacc1;

-- try dropping a non-existent column, should fail
ALTER TABLE atacc1
    DROP bar;

-- try removing an oid column, should succeed (as it's nonexistant)
ALTER TABLE atacc1 SET WITHOUT OIDS;

-- try adding an oid column, should fail (not supported)
ALTER TABLE atacc1 SET WITH OIDS;

-- try dropping the xmin column, should fail
ALTER TABLE atacc1
    DROP xmin;

-- try creating a view and altering that, should fail
CREATE VIEW myview AS
SELECT
    *
FROM
    atacc1;

SELECT
    *
FROM
    myview;

ALTER TABLE myview
    DROP d;

DROP VIEW myview;

-- test some commands to make sure they fail on the dropped column
ANALYZE atacc1 (a);

ANALYZE atacc1 ("........pg.dropped.1........");

VACUUM ANALYZE atacc1 (a);

VACUUM ANALYZE atacc1 ("........pg.dropped.1........");

COMMENT ON COLUMN atacc1.a IS 'testing';

COMMENT ON COLUMN atacc1."........pg.dropped.1........" IS 'testing';

ALTER TABLE atacc1
    ALTER a SET storage plain;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" SET storage plain;

ALTER TABLE atacc1
    ALTER a SET statistics 0;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" SET statistics 0;

ALTER TABLE atacc1
    ALTER a SET DEFAULT 3;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" SET DEFAULT 3;

ALTER TABLE atacc1
    ALTER a DROP DEFAULT;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" DROP DEFAULT;

ALTER TABLE atacc1
    ALTER a SET NOT NULL;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" SET NOT NULL;

ALTER TABLE atacc1
    ALTER a DROP NOT NULL;

ALTER TABLE atacc1
    ALTER "........pg.dropped.1........" DROP NOT NULL;

ALTER TABLE atacc1 RENAME a TO x;

ALTER TABLE atacc1 RENAME "........pg.dropped.1........" TO x;

ALTER TABLE atacc1
    ADD PRIMARY KEY (a);

ALTER TABLE atacc1
    ADD PRIMARY KEY ("........pg.dropped.1........");

ALTER TABLE atacc1
    ADD UNIQUE (a);

ALTER TABLE atacc1
    ADD UNIQUE ("........pg.dropped.1........");

ALTER TABLE atacc1
    ADD CHECK (a > 3);

ALTER TABLE atacc1
    ADD CHECK ("........pg.dropped.1........" > 3);

CREATE TABLE atacc2 (
    id int4 UNIQUE
);

ALTER TABLE atacc1
    ADD FOREIGN KEY (a) REFERENCES atacc2 (id);

ALTER TABLE atacc1
    ADD FOREIGN KEY ("........pg.dropped.1........") REFERENCES atacc2 (id);

ALTER TABLE atacc2
    ADD FOREIGN KEY (id) REFERENCES atacc1 (a);

ALTER TABLE atacc2
    ADD FOREIGN KEY (id) REFERENCES atacc1 ("........pg.dropped.1........");

DROP TABLE atacc2;

CREATE INDEX "testing_idx" ON atacc1 (a);

CREATE INDEX "testing_idx" ON atacc1 ("........pg.dropped.1........");

-- test create as and select into
INSERT INTO atacc1
    VALUES (21, 22, 23);

CREATE TABLE attest1 AS
SELECT
    *
FROM
    atacc1;

SELECT
    *
FROM
    attest1;

DROP TABLE attest1;

SELECT
    * INTO attest2
FROM
    atacc1;

SELECT
    *
FROM
    attest2;

DROP TABLE attest2;

-- try dropping all columns
ALTER TABLE atacc1
    DROP c;

ALTER TABLE atacc1
    DROP d;

ALTER TABLE atacc1
    DROP b;

SELECT
    *
FROM
    atacc1;

DROP TABLE atacc1;

-- test constraint error reporting in presence of dropped columns
CREATE TABLE atacc1 (
    id serial PRIMARY KEY,
    value int CHECK (value < 10)
);

INSERT INTO atacc1 (value)
    VALUES (100);

ALTER TABLE atacc1
    DROP COLUMN value;

ALTER TABLE atacc1
    ADD COLUMN value int CHECK (value < 10);

INSERT INTO atacc1 (value)
    VALUES (100);

INSERT INTO atacc1 (id, value)
    VALUES (NULL, 0);

DROP TABLE atacc1;

-- test inheritance
CREATE TABLE parent (
    a int,
    b int,
    c int
);

INSERT INTO parent
    VALUES (1, 2, 3);

ALTER TABLE parent
    DROP a;

CREATE TABLE child (
    d varchar(255)
)
INHERITS (
    parent
);

INSERT INTO child
    VALUES (12, 13, 'testing');

SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

ALTER TABLE parent
    DROP c;

SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

DROP TABLE child;

DROP TABLE parent;

-- check error cases for inheritance column merging
CREATE TABLE parent (
    a float8,
    b numeric(10, 4),
    c text COLLATE "C"
);

CREATE TABLE child (
    a float4
)
INHERITS (
    parent
);

-- fail
CREATE TABLE child (
    b decimal(10, 7)
)
INHERITS (
    parent
);

-- fail
CREATE TABLE child (
    c text COLLATE "POSIX"
)
INHERITS (
    parent
);

-- fail
CREATE TABLE child (
    a double precision,
    b decimal(10, 4)
)
INHERITS (
    parent
);

DROP TABLE child;

DROP TABLE parent;

-- test copy in/out
CREATE TABLE attest (
    a int4,
    b int4,
    c int4
);

INSERT INTO attest
    VALUES (1, 2, 3);

ALTER TABLE attest
    DROP a;

SELECT
    *
FROM
    attest;

SELECT
    *
FROM
    attest;

SELECT
    *
FROM
    attest;

DROP TABLE attest;

-- test inheritance
CREATE TABLE dropColumn (
    a int,
    b int,
    e int
);

CREATE TABLE dropColumnChild (
    c int
)
INHERITS (
    dropColumn
);

CREATE TABLE dropColumnAnother (
    d int
)
INHERITS (
    dropColumnChild
);

-- these two should fail
ALTER TABLE dropColumnchild
    DROP COLUMN a;

ALTER TABLE ONLY dropColumnChild
    DROP COLUMN b;

-- these three should work
ALTER TABLE ONLY dropColumn
    DROP COLUMN e;

ALTER TABLE dropColumnChild
    DROP COLUMN c;

ALTER TABLE dropColumn
    DROP COLUMN a;

CREATE TABLE renameColumn (
    a int
);

CREATE TABLE renameColumnChild (
    b int
)
INHERITS (
    renameColumn
);

CREATE TABLE renameColumnAnother (
    c int
)
INHERITS (
    renameColumnChild
);

-- these three should fail
ALTER TABLE renameColumnChild RENAME COLUMN a TO d;

ALTER TABLE ONLY renameColumnChild RENAME COLUMN a TO d;

ALTER TABLE ONLY renameColumn RENAME COLUMN a TO d;

-- these should work
ALTER TABLE renameColumn RENAME COLUMN a TO d;

ALTER TABLE renameColumnChild RENAME COLUMN b TO a;

-- these should work
ALTER TABLE IF EXISTS doesnt_exist_tab RENAME COLUMN a TO d;

ALTER TABLE IF EXISTS doesnt_exist_tab RENAME COLUMN b TO a;

-- this should work
ALTER TABLE renameColumn
    ADD COLUMN w int;

-- this should fail
ALTER TABLE ONLY renameColumn
    ADD COLUMN x int;

-- Test corner cases in dropping of inherited columns
CREATE TABLE p1 (
    f1 int,
    f2 int
);

CREATE TABLE c1 (
    f1 int NOT NULL
)
INHERITS (
    p1
);

-- should be rejected since c1.f1 is inherited
ALTER TABLE c1
    DROP COLUMN f1;

-- should work
ALTER TABLE p1
    DROP COLUMN f1;

-- c1.f1 is still there, but no longer inherited
SELECT
    f1
FROM
    c1;

ALTER TABLE c1
    DROP COLUMN f1;

SELECT
    f1
FROM
    c1;

DROP TABLE p1 CASCADE;

CREATE TABLE p1 (
    f1 int,
    f2 int
);

CREATE TABLE c1 ()
INHERITS (
    p1
);

-- should be rejected since c1.f1 is inherited
ALTER TABLE c1
    DROP COLUMN f1;

ALTER TABLE p1
    DROP COLUMN f1;

-- c1.f1 is dropped now, since there is no local definition for it
SELECT
    f1
FROM
    c1;

DROP TABLE p1 CASCADE;

CREATE TABLE p1 (
    f1 int,
    f2 int
);

CREATE TABLE c1 ()
INHERITS (
    p1
);

-- should be rejected since c1.f1 is inherited
ALTER TABLE c1
    DROP COLUMN f1;

ALTER TABLE ONLY p1
    DROP COLUMN f1;

-- c1.f1 is NOT dropped, but must now be considered non-inherited
ALTER TABLE c1
    DROP COLUMN f1;

DROP TABLE p1 CASCADE;

CREATE TABLE p1 (
    f1 int,
    f2 int
);

CREATE TABLE c1 (
    f1 int NOT NULL
)
INHERITS (
    p1
);

-- should be rejected since c1.f1 is inherited
ALTER TABLE c1
    DROP COLUMN f1;

ALTER TABLE ONLY p1
    DROP COLUMN f1;

-- c1.f1 is still there, but no longer inherited
ALTER TABLE c1
    DROP COLUMN f1;

DROP TABLE p1 CASCADE;

CREATE TABLE p1 (
    id int,
    name text
);

CREATE TABLE p2 (
    id2 int,
    name text,
    height int
);

CREATE TABLE c1 (
    age int
)
INHERITS (
    p1,
    p2
);

CREATE TABLE gc1 ()
INHERITS (
    c1
);

SELECT
    relname,
    attname,
    attinhcount,
    attislocal
FROM
    pg_class
    JOIN pg_attribute ON (pg_class.oid = pg_attribute.attrelid)
WHERE
    relname IN ('p1', 'p2', 'c1', 'gc1')
    AND attnum > 0
    AND NOT attisdropped
ORDER BY
    relname,
    attnum;

-- should work
ALTER TABLE ONLY p1
    DROP COLUMN name;

-- should work. Now c1.name is local and inhcount is 0.
ALTER TABLE p2
    DROP COLUMN name;

-- should be rejected since its inherited
ALTER TABLE gc1
    DROP COLUMN name;

-- should work, and drop gc1.name along
ALTER TABLE c1
    DROP COLUMN name;

-- should fail: column does not exist
ALTER TABLE gc1
    DROP COLUMN name;

-- should work and drop the attribute in all tables
ALTER TABLE p2
    DROP COLUMN height;

-- IF EXISTS test
CREATE TABLE dropColumnExists ();

ALTER TABLE dropColumnExists
    DROP COLUMN non_existing;

--fail
ALTER TABLE dropColumnExists
    DROP COLUMN IF EXISTS non_existing;

--succeed
SELECT
    relname,
    attname,
    attinhcount,
    attislocal
FROM
    pg_class
    JOIN pg_attribute ON (pg_class.oid = pg_attribute.attrelid)
WHERE
    relname IN ('p1', 'p2', 'c1', 'gc1')
    AND attnum > 0
    AND NOT attisdropped
ORDER BY
    relname,
    attnum;

DROP TABLE p1, p2 CASCADE;

-- test attinhcount tracking with merged columns
CREATE TABLE depth0 ();

CREATE TABLE depth1 (
    c text
)
INHERITS (
    depth0
);

CREATE TABLE depth2 ()
INHERITS (
    depth1
);

ALTER TABLE depth0
    ADD c text;

SELECT
    attrelid::regclass,
    attname,
    attinhcount,
    attislocal
FROM
    pg_attribute
WHERE
    attnum > 0
    AND attrelid::regclass IN ('depth0', 'depth1', 'depth2')
ORDER BY
    attrelid::regclass::text,
    attnum;

-- test renumbering of child-table columns in inherited operations
CREATE TABLE p1 (
    f1 int
);

CREATE TABLE c1 (
    f2 text,
    f3 int
)
INHERITS (
    p1
);

ALTER TABLE p1
    ADD COLUMN a1 int CHECK (a1 > 0);

ALTER TABLE p1
    ADD COLUMN f2 text;

INSERT INTO p1
    VALUES (1, 2, 'abc');

INSERT INTO c1
    VALUES (11, 'xyz', 33, 0);

-- should fail
INSERT INTO c1
    VALUES (11, 'xyz', 33, 22);

SELECT
    *
FROM
    p1;

UPDATE
    p1
SET
    a1 = a1 + 1,
    f2 = upper(f2);

SELECT
    *
FROM
    p1;

DROP TABLE p1 CASCADE;

-- test that operations with a dropped column do not try to reference
-- its datatype
CREATE DOMAIN mytype AS text;

CREATE temp TABLE foo (
    f1 text,
    f2 mytype,
    f3 text
);

INSERT INTO foo
    VALUES ('bb', 'cc', 'dd');

SELECT
    *
FROM
    foo;

DROP DOMAIN mytype CASCADE;

SELECT
    *
FROM
    foo;

INSERT INTO foo
    VALUES ('qq', 'rr');

SELECT
    *
FROM
    foo;

UPDATE
    foo
SET
    f3 = 'zz';

SELECT
    *
FROM
    foo;

SELECT
    f3,
    max(f1)
FROM
    foo
GROUP BY
    f3;

-- Simple tests for alter table column type
ALTER TABLE foo
    ALTER f1 TYPE integer;

-- fails
ALTER TABLE foo
    ALTER f1 TYPE varchar(10);

CREATE TABLE anothertab (
    atcol1 serial8,
    atcol2 boolean,
    CONSTRAINT anothertab_chk CHECK (atcol1 <= 3)
);

INSERT INTO anothertab (atcol1, atcol2)
    VALUES (DEFAULT, TRUE);

INSERT INTO anothertab (atcol1, atcol2)
    VALUES (DEFAULT, FALSE);

SELECT
    *
FROM
    anothertab;

ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE boolean;

-- fails
ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE boolean
    USING atcol1::int;

-- fails
ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE integer;

SELECT
    *
FROM
    anothertab;

INSERT INTO anothertab (atcol1, atcol2)
    VALUES (45, NULL);

-- fails
INSERT INTO anothertab (atcol1, atcol2)
    VALUES (DEFAULT, NULL);

SELECT
    *
FROM
    anothertab;

ALTER TABLE anothertab
    ALTER COLUMN atcol2 TYPE text
    USING
        CASE WHEN atcol2 IS TRUE THEN
            'IT WAS TRUE'
        WHEN atcol2 IS FALSE THEN
            'IT WAS FALSE'
        ELSE
            'IT WAS NULL!'
        END;

SELECT
    *
FROM
    anothertab;

ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE boolean
    USING
        CASE WHEN atcol1 % 2 = 0 THEN
            TRUE
        ELSE
            FALSE
        END;

-- fails
ALTER TABLE anothertab
    ALTER COLUMN atcol1 DROP DEFAULT;

ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE boolean
    USING
        CASE WHEN atcol1 % 2 = 0 THEN
            TRUE
        ELSE
            FALSE
        END;

-- fails
ALTER TABLE anothertab
    DROP CONSTRAINT anothertab_chk;

ALTER TABLE anothertab
    DROP CONSTRAINT anothertab_chk;

-- fails
ALTER TABLE anothertab
    DROP CONSTRAINT IF EXISTS anothertab_chk;

-- succeeds
ALTER TABLE anothertab
    ALTER COLUMN atcol1 TYPE boolean
    USING
        CASE WHEN atcol1 % 2 = 0 THEN
            TRUE
        ELSE
            FALSE
        END;

SELECT
    *
FROM
    anothertab;

DROP TABLE anothertab;

CREATE TABLE another (
    f1 int,
    f2 text
);

INSERT INTO another
    VALUES (1, 'one');

INSERT INTO another
    VALUES (2, 'two');

INSERT INTO another
    VALUES (3, 'three');

SELECT
    *
FROM
    another;

ALTER TABLE another
    ALTER f1 TYPE text
    USING f2 || ' more',
    ALTER f2 TYPE bigint
    USING f1 * 10;

SELECT
    *
FROM
    another;

DROP TABLE another;

-- table's row type
CREATE TABLE tab1 (
    a int,
    b text
);

CREATE TABLE tab2 (
    x int,
    y tab1
);

ALTER TABLE tab1
    ALTER COLUMN b TYPE varchar;

-- fails
-- Alter column type that's part of a partitioned index
CREATE TABLE at_partitioned (
    a int,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE at_part_1 PARTITION OF at_partitioned
FOR VALUES FROM (0) TO (1000);

INSERT INTO at_partitioned
    VALUES (512, '0.123');

CREATE TABLE at_part_2 (
    b text,
    a int
);

INSERT INTO at_part_2
    VALUES ('1.234', 1024);

CREATE INDEX ON at_partitioned (b);

CREATE INDEX ON at_partitioned (a);

\d at_part_1
\d at_part_2
ALTER TABLE at_partitioned ATTACH PARTITION at_part_2
FOR VALUES FROM (1000) TO (2000);

\d at_part_2
ALTER TABLE at_partitioned
    ALTER COLUMN b TYPE numeric
    USING b::numeric;

\d at_part_1
\d at_part_2
DROP TABLE at_partitioned;

-- Alter column type when no table rewrite is required
-- Also check that comments are preserved
CREATE TABLE at_partitioned (
    id int,
    name varchar(64),
    UNIQUE (id, name)
)
PARTITION BY HASH (id);

COMMENT ON CONSTRAINT at_partitioned_id_name_key ON at_partitioned IS 'parent constraint';

COMMENT ON INDEX at_partitioned_id_name_key IS 'parent index';

CREATE TABLE at_partitioned_0 PARTITION OF at_partitioned
FOR VALUES WITH (MODULUS 2, REMAINDER 0);

COMMENT ON CONSTRAINT at_partitioned_0_id_name_key ON at_partitioned_0 IS 'child 0 constraint';

COMMENT ON INDEX at_partitioned_0_id_name_key IS 'child 0 index';

CREATE TABLE at_partitioned_1 PARTITION OF at_partitioned
FOR VALUES WITH (MODULUS 2, REMAINDER 1);

COMMENT ON CONSTRAINT at_partitioned_1_id_name_key ON at_partitioned_1 IS 'child 1 constraint';

COMMENT ON INDEX at_partitioned_1_id_name_key IS 'child 1 index';

INSERT INTO at_partitioned
    VALUES (1, 'foo');

INSERT INTO at_partitioned
    VALUES (3, 'bar');

CREATE temp TABLE old_oids AS
SELECT
    relname,
    oid AS oldoid,
    relfilenode AS oldfilenode
FROM
    pg_class
WHERE
    relname LIKE 'at_partitioned%';

SELECT
    relname,
    c.oid = oldoid AS orig_oid,
    CASE relfilenode
    WHEN 0 THEN
        'none'
    WHEN c.oid THEN
        'own'
    WHEN oldfilenode THEN
        'orig'
    ELSE
        'OTHER'
    END AS storage,
    obj_description(c.oid, 'pg_class') AS desc
FROM
    pg_class c
    LEFT JOIN old_oids USING (relname)
WHERE
    relname LIKE 'at_partitioned%'
ORDER BY
    relname;

SELECT
    conname,
    obj_description(oid, 'pg_constraint') AS desc
FROM
    pg_constraint
WHERE
    conname LIKE 'at_partitioned%'
ORDER BY
    conname;

ALTER TABLE at_partitioned
    ALTER COLUMN name TYPE varchar(127);

-- Note: these tests currently show the wrong behavior for comments :-(
SELECT
    relname,
    c.oid = oldoid AS orig_oid,
    CASE relfilenode
    WHEN 0 THEN
        'none'
    WHEN c.oid THEN
        'own'
    WHEN oldfilenode THEN
        'orig'
    ELSE
        'OTHER'
    END AS storage,
    obj_description(c.oid, 'pg_class') AS desc
FROM
    pg_class c
    LEFT JOIN old_oids USING (relname)
WHERE
    relname LIKE 'at_partitioned%'
ORDER BY
    relname;

SELECT
    conname,
    obj_description(oid, 'pg_constraint') AS desc
FROM
    pg_constraint
WHERE
    conname LIKE 'at_partitioned%'
ORDER BY
    conname;

-- Don't remove this DROP, it exposes bug #15672
DROP TABLE at_partitioned;

-- disallow recursive containment of row types
CREATE temp TABLE recur1 (
    f1 int
);

ALTER TABLE recur1
    ADD COLUMN f2 recur1;

-- fails
ALTER TABLE recur1
    ADD COLUMN f2 recur1[];

-- fails
CREATE DOMAIN array_of_recur1 AS recur1[];

ALTER TABLE recur1
    ADD COLUMN f2 array_of_recur1;

-- fails
CREATE temp TABLE recur2 (
    f1 int,
    f2 recur1
);

ALTER TABLE recur1
    ADD COLUMN f2 recur2;

-- fails
ALTER TABLE recur1
    ADD COLUMN f2 int;

ALTER TABLE recur1
    ALTER COLUMN f2 TYPE recur2;

-- fails
-- SET STORAGE may need to add a TOAST table
CREATE TABLE test_storage (
    a text
);

ALTER TABLE test_storage
    ALTER a SET storage plain;

ALTER TABLE test_storage
    ADD b int DEFAULT 0;

-- rewrite table to remove its TOAST table
ALTER TABLE test_storage
    ALTER a SET storage extended;

-- re-add TOAST table
SELECT
    reltoastrelid <> 0 AS has_toast_table
FROM
    pg_class
WHERE
    oid = 'test_storage'::regclass;

-- ALTER COLUMN TYPE with a check constraint and a child table (bug #13779)
CREATE TABLE test_inh_check (
    a float CHECK (a > 10.2),
    b float
);

CREATE TABLE test_inh_check_child ()
INHERITS (
    test_inh_check
);

\d test_inh_check
\d test_inh_check_child
SELECT
    relname,
    conname,
    coninhcount,
    conislocal,
    connoinherit
FROM
    pg_constraint c,
    pg_class r
WHERE
    relname LIKE 'test_inh_check%'
    AND c.conrelid = r.oid
ORDER BY
    1,
    2;

ALTER TABLE test_inh_check
    ALTER COLUMN a TYPE numeric;

\d test_inh_check
\d test_inh_check_child
SELECT
    relname,
    conname,
    coninhcount,
    conislocal,
    connoinherit
FROM
    pg_constraint c,
    pg_class r
WHERE
    relname LIKE 'test_inh_check%'
    AND c.conrelid = r.oid
ORDER BY
    1,
    2;

-- also try noinherit, local, and local+inherited cases
ALTER TABLE test_inh_check
    ADD CONSTRAINT bnoinherit CHECK (b > 100) NO INHERIT;

ALTER TABLE test_inh_check_child
    ADD CONSTRAINT blocal CHECK (b < 1000);

ALTER TABLE test_inh_check_child
    ADD CONSTRAINT bmerged CHECK (b > 1);

ALTER TABLE test_inh_check
    ADD CONSTRAINT bmerged CHECK (b > 1);

\d test_inh_check
\d test_inh_check_child
SELECT
    relname,
    conname,
    coninhcount,
    conislocal,
    connoinherit
FROM
    pg_constraint c,
    pg_class r
WHERE
    relname LIKE 'test_inh_check%'
    AND c.conrelid = r.oid
ORDER BY
    1,
    2;

ALTER TABLE test_inh_check
    ALTER COLUMN b TYPE numeric;

\d test_inh_check
\d test_inh_check_child
SELECT
    relname,
    conname,
    coninhcount,
    conislocal,
    connoinherit
FROM
    pg_constraint c,
    pg_class r
WHERE
    relname LIKE 'test_inh_check%'
    AND c.conrelid = r.oid
ORDER BY
    1,
    2;

-- ALTER COLUMN TYPE with different schema in children
-- Bug at https://postgr.es/m/20170102225618.GA10071@telsasoft.com
CREATE TABLE test_type_diff (
    f1 int
);

CREATE TABLE test_type_diff_c (
    extra smallint
)
INHERITS (
    test_type_diff
);

ALTER TABLE test_type_diff
    ADD COLUMN f2 int;

INSERT INTO test_type_diff_c
    VALUES (1, 2, 3);

ALTER TABLE test_type_diff
    ALTER COLUMN f2 TYPE bigint
    USING f2::bigint;

CREATE TABLE test_type_diff2 (
    int_two int2,
    int_four int4,
    int_eight int8
);

CREATE TABLE test_type_diff2_c1 (
    int_four int4,
    int_eight int8,
    int_two int2
);

CREATE TABLE test_type_diff2_c2 (
    int_eight int8,
    int_two int2,
    int_four int4
);

CREATE TABLE test_type_diff2_c3 (
    int_two int2,
    int_four int4,
    int_eight int8
);

ALTER TABLE test_type_diff2_c1 INHERIT test_type_diff2;

ALTER TABLE test_type_diff2_c2 INHERIT test_type_diff2;

ALTER TABLE test_type_diff2_c3 INHERIT test_type_diff2;

INSERT INTO test_type_diff2_c1
    VALUES (1, 2, 3);

INSERT INTO test_type_diff2_c2
    VALUES (4, 5, 6);

INSERT INTO test_type_diff2_c3
    VALUES (7, 8, 9);

ALTER TABLE test_type_diff2
    ALTER COLUMN int_four TYPE int8
    USING int_four::int8;

-- whole-row references are disallowed
ALTER TABLE test_type_diff2
    ALTER COLUMN int_four TYPE int4
    USING (pg_column_size(test_type_diff2));

-- check for rollback of ANALYZE corrupting table property flags (bug #11638)
CREATE TABLE check_fk_presence_1 (
    id int PRIMARY KEY,
    t text
);

CREATE TABLE check_fk_presence_2 (
    id int REFERENCES check_fk_presence_1,
    t text
);

BEGIN;
ALTER TABLE check_fk_presence_2
    DROP CONSTRAINT check_fk_presence_2_id_fkey;
ANALYZE check_fk_presence_2;
ROLLBACK;

\d check_fk_presence_2
DROP TABLE check_fk_presence_1, check_fk_presence_2;

-- check column addition within a view (bug #14876)
CREATE TABLE at_base_table (
    id int,
    stuff text
);

INSERT INTO at_base_table
    VALUES (23, 'skidoo');

CREATE VIEW at_view_1 AS
SELECT
    *
FROM
    at_base_table bt;

CREATE VIEW at_view_2 AS
SELECT
    *,
    to_json(v1) AS j
FROM
    at_view_1 v1;

\d+ at_view_1
\d+ at_view_2
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    at_view_2;

SELECT
    *
FROM
    at_view_2;

CREATE OR REPLACE VIEW at_view_1 AS
SELECT
    *,
    2 + 2 AS more
FROM
    at_base_table bt;

\d+ at_view_1
\d+ at_view_2
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    *
FROM
    at_view_2;

SELECT
    *
FROM
    at_view_2;

DROP VIEW at_view_2;

DROP VIEW at_view_1;

DROP TABLE at_base_table;

--
-- lock levels
--
DROP TYPE lockmodes;

CREATE TYPE lockmodes AS enum (
    'SIReadLock',
    'AccessShareLock',
    'RowShareLock',
    'RowExclusiveLock',
    'ShareUpdateExclusiveLock',
    'ShareLock',
    'ShareRowExclusiveLock',
    'ExclusiveLock',
    'AccessExclusiveLock'
);

DROP VIEW my_locks;

CREATE OR REPLACE VIEW my_locks AS
SELECT
    CASE WHEN c.relname LIKE 'pg_toast%' THEN
        'pg_toast'
    ELSE
        c.relname
    END,
    max(mode::lockmodes) AS max_lockmode
FROM
    pg_locks l
    JOIN pg_class c ON l.relation = c.oid
WHERE
    virtualtransaction = (
        SELECT
            virtualtransaction
        FROM
            pg_locks
        WHERE
            transactionid = txid_current()::integer)
    AND locktype = 'relation'
    AND relnamespace != (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname = 'pg_catalog')
    AND c.relname != 'my_locks'
GROUP BY
    c.relname;

CREATE TABLE alterlock (
    f1 int PRIMARY KEY,
    f2 text
);

INSERT INTO alterlock
    VALUES (1, 'foo');

CREATE TABLE alterlock2 (
    f3 int PRIMARY KEY,
    f1 int
);

INSERT INTO alterlock2
    VALUES (1, 1);

BEGIN;
ALTER TABLE alterlock
    ALTER COLUMN f2 SET statistics 150;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

BEGIN;
ALTER TABLE alterlock CLUSTER ON alterlock_pkey;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock SET WITHOUT CLUSTER;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock SET (fillfactor = 100);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock RESET (fillfactor);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock SET (toast.autovacuum_enabled = OFF);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock SET (autovacuum_enabled = OFF);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock
    ALTER COLUMN f2 SET (n_distinct = 1);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

-- test that mixing options with different lock levels works as expected
BEGIN;
ALTER TABLE alterlock SET (autovacuum_enabled = OFF, fillfactor = 80);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock
    ALTER COLUMN f2 SET storage extended;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

BEGIN;
ALTER TABLE alterlock
    ALTER COLUMN f2 SET DEFAULT 'x';
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

BEGIN;
CREATE TRIGGER ttdummy
    BEFORE DELETE OR UPDATE ON alterlock FOR EACH ROW
    EXECUTE PROCEDURE ttdummy (1, 1);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

BEGIN;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ALTER TABLE alterlock2
    ADD FOREIGN KEY (f1) REFERENCES alterlock (f1);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

BEGIN;
ALTER TABLE alterlock2
    ADD CONSTRAINT alterlock2nv FOREIGN KEY (f1) REFERENCES alterlock (f1) NOT VALID;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
COMMIT;

BEGIN;
ALTER TABLE alterlock2 validate CONSTRAINT alterlock2nv;
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

CREATE OR REPLACE VIEW my_locks AS
SELECT
    CASE WHEN c.relname LIKE 'pg_toast%' THEN
        'pg_toast'
    ELSE
        c.relname
    END,
    max(mode::lockmodes) AS max_lockmode
FROM
    pg_locks l
    JOIN pg_class c ON l.relation = c.oid
WHERE
    virtualtransaction = (
        SELECT
            virtualtransaction
        FROM
            pg_locks
        WHERE
            transactionid = txid_current()::integer)
    AND locktype = 'relation'
    AND relnamespace != (
        SELECT
            oid
        FROM
            pg_namespace
        WHERE
            nspname = 'pg_catalog')
    AND c.relname = 'my_locks'
GROUP BY
    c.relname;

-- raise exception
ALTER TABLE my_locks SET (autovacuum_enabled = FALSE);

ALTER VIEW my_locks SET (autovacuum_enabled = FALSE);

ALTER TABLE my_locks RESET (autovacuum_enabled);

ALTER VIEW my_locks RESET (autovacuum_enabled);

BEGIN;
ALTER VIEW my_locks SET (security_barrier = OFF);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ALTER VIEW my_locks RESET (security_barrier);
ROLLBACK;

-- this test intentionally applies the ALTER TABLE command against a view, but
-- uses a view option so we expect this to succeed. This form of SQL is
-- accepted for historical reasons, as shown in the docs for ALTER VIEW
BEGIN;
ALTER TABLE my_locks SET (security_barrier = OFF);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ALTER TABLE my_locks RESET (security_barrier);
ROLLBACK;

-- cleanup
DROP TABLE alterlock2;

DROP TABLE alterlock;

DROP VIEW my_locks;

DROP TYPE lockmodes;

--
-- alter function
--
CREATE FUNCTION test_strict (text)
    RETURNS text
    AS '
    SELECT
        coalesce($1, ''got passed a null'');
'
LANGUAGE sql
RETURNS NULL ON NULL input;

SELECT
    test_strict (NULL);

ALTER FUNCTION test_strict (text) called ON NULL input;

SELECT
    test_strict (NULL);

CREATE FUNCTION non_strict (text)
    RETURNS text
    AS '
    SELECT
        coalesce($1, ''got passed a null'');
'
LANGUAGE sql
called ON NULL input;

SELECT
    non_strict (NULL);

ALTER FUNCTION non_strict (text)
RETURNS NULL ON NULL input;

SELECT
    non_strict (NULL);

--
-- alter object set schema
--
CREATE SCHEMA alter1;

CREATE SCHEMA alter2;

CREATE TABLE alter1.t1 (
    f1 serial PRIMARY KEY,
    f2 int CHECK (f2 > 0)
);

CREATE VIEW alter1.v1 AS
SELECT
    *
FROM
    alter1.t1;

CREATE FUNCTION alter1.plus1 (int)
    RETURNS int
    AS '
    SELECT
        $1 + 1;
'
LANGUAGE sql;

CREATE DOMAIN alter1.posint integer CHECK (value > 0);

CREATE TYPE alter1.ctype AS (
    f1 int,
    f2 text
);

CREATE FUNCTION alter1.same (alter1.ctype, alter1.ctype)
    RETURNS boolean
    LANGUAGE sql
    AS '
    SELECT
        $1.f1 IS NOT DISTINCT FROM $2.f1
        AND $1.f2 IS NOT DISTINCT FROM $2.f2;
';

CREATE OPERATOR alter1.= (
    PROCEDURE = alter1.same,
    LEFTARG = alter1.ctype,
    RIGHTARG = alter1.ctype
);

CREATE OPERATOR class alter1.ctype_hash_ops DEFAULT FOR TYPE alter1.ctype
    USING HASH AS
    OPERATOR 1 alter1. = ( alter1.ctype,
        alter1.ctype
);

CREATE conversion alter1.ascii_to_utf8 FOR 'sql_ascii' TO 'utf8' FROM ascii_to_utf8;

CREATE text search parser alter1.prs (
    START = prsd_start,
    gettoken = prsd_nexttoken,
    END = prsd_end,
    lextypes = prsd_lextype
);

CREATE text search configuration alter1.cfg (
    parser = alter1.prs
);

CREATE text search TEMPLATE alter1.tmpl (
    init = dsimple_init,
    LEXIZE = dsimple_lexize
);

CREATE text search dictionary alter1.dict (
    TEMPLATE = alter1.tmpl
);

INSERT INTO alter1.t1 (f2)
    VALUES (11);

INSERT INTO alter1.t1 (f2)
    VALUES (12);

ALTER TABLE alter1.t1 SET SCHEMA alter1;

-- no-op, same schema
ALTER TABLE alter1.t1 SET SCHEMA alter2;

ALTER TABLE alter1.v1 SET SCHEMA alter2;

ALTER FUNCTION alter1.plus1 (int) SET SCHEMA alter2;

ALTER DOMAIN alter1.posint SET SCHEMA alter2;

ALTER OPERATOR class alter1.ctype_hash_ops
    USING HASH SET SCHEMA alter2;

ALTER OPERATOR family alter1.ctype_hash_ops
    USING HASH SET SCHEMA alter2;

ALTER OPERATOR alter1.= (alter1.ctype, alter1.ctype) SET SCHEMA alter2;

ALTER FUNCTION alter1.same (alter1.ctype, alter1.ctype) SET SCHEMA alter2;

ALTER TYPE alter1.ctype SET SCHEMA alter1;

-- no-op, same schema
ALTER TYPE alter1.ctype SET SCHEMA alter2;

ALTER conversion alter1.ascii_to_utf8 SET SCHEMA alter2;

ALTER text search parser alter1.prs SET SCHEMA alter2;

ALTER text search configuration alter1.cfg SET SCHEMA alter2;

ALTER text search TEMPLATE alter1.tmpl SET SCHEMA alter2;

ALTER text search dictionary alter1.dict SET SCHEMA alter2;

-- this should succeed because nothing is left in alter1
DROP SCHEMA alter1;

INSERT INTO alter2.t1 (f2)
    VALUES (13);

INSERT INTO alter2.t1 (f2)
    VALUES (14);

SELECT
    *
FROM
    alter2.t1;

SELECT
    *
FROM
    alter2.v1;

SELECT
    alter2.plus1 (41);

-- clean up
DROP SCHEMA alter2 CASCADE;

--
-- composite types
--
CREATE TYPE test_type AS (
    a int
);

\d test_type
ALTER TYPE nosuchtype
    ADD ATTRIBUTE b text;

-- fails
ALTER TYPE test_type
    ADD ATTRIBUTE b text;

\d test_type
ALTER TYPE test_type
    ADD ATTRIBUTE b text;

-- fails
ALTER TYPE test_type
    ALTER ATTRIBUTE b SET DATA TYPE varchar;

\d test_type
ALTER TYPE test_type
    ALTER ATTRIBUTE b SET DATA TYPE integer;

\d test_type
ALTER TYPE test_type
    DROP ATTRIBUTE b;

\d test_type
ALTER TYPE test_type
    DROP ATTRIBUTE c;

-- fails
ALTER TYPE test_type
    DROP ATTRIBUTE IF EXISTS c;

ALTER TYPE test_type
    DROP ATTRIBUTE a,
    ADD ATTRIBUTE d boolean;

\d test_type
ALTER TYPE test_type RENAME ATTRIBUTE a TO aa;

ALTER TYPE test_type RENAME ATTRIBUTE d TO dd;

\d test_type
DROP TYPE test_type;

CREATE TYPE test_type1 AS (
    a int,
    b text
);

CREATE TABLE test_tbl1 (
    x int,
    y test_type1
);

ALTER TYPE test_type1
    ALTER ATTRIBUTE b TYPE varchar;

-- fails
CREATE TYPE test_type2 AS (
    a int,
    b text
);

CREATE TABLE test_tbl2 OF test_type2;

CREATE TABLE test_tbl2_subclass ()
INHERITS (
    test_tbl2
);

\d test_type2
\d test_tbl2
ALTER TYPE test_type2
    ADD ATTRIBUTE c text;

-- fails
ALTER TYPE test_type2
    ADD ATTRIBUTE c text CASCADE;

\d test_type2
\d test_tbl2
ALTER TYPE test_type2
    ALTER ATTRIBUTE b TYPE varchar;

-- fails
ALTER TYPE test_type2
    ALTER ATTRIBUTE b TYPE varchar CASCADE;

\d test_type2
\d test_tbl2
ALTER TYPE test_type2
    DROP ATTRIBUTE b;

-- fails
ALTER TYPE test_type2
    DROP ATTRIBUTE b CASCADE;

\d test_type2
\d test_tbl2
ALTER TYPE test_type2 RENAME ATTRIBUTE a TO aa;

-- fails
ALTER TYPE test_type2 RENAME ATTRIBUTE a TO aa CASCADE;

\d test_type2
\d test_tbl2
\d test_tbl2_subclass
DROP TABLE test_tbl2_subclass;

CREATE TYPE test_typex AS (
    a int,
    b text
);

CREATE TABLE test_tblx (
    x int,
    y test_typex CHECK ((y).a > 0)
);

ALTER TYPE test_typex
    DROP ATTRIBUTE a;

-- fails
ALTER TYPE test_typex
    DROP ATTRIBUTE a CASCADE;

\d test_tblx
DROP TABLE test_tblx;

DROP TYPE test_typex;

-- This test isn't that interesting on its own, but the purpose is to leave
-- behind a table to test pg_upgrade with. The table has a composite type
-- column in it, and the composite type has a dropped attribute.
CREATE TYPE test_type3 AS (
    a int
);

CREATE TABLE test_tbl3 (
    c
) AS
SELECT
    '(1)'::test_type3;

ALTER TYPE test_type3
    DROP ATTRIBUTE a,
    ADD ATTRIBUTE b int;

CREATE TYPE test_type_empty AS (
);

DROP TYPE test_type_empty;

--
-- typed tables: OF / NOT OF
--
CREATE TYPE tt_t0 AS (
    z inet,
    x int,
    y numeric(8, 2)
);

ALTER TYPE tt_t0
    DROP ATTRIBUTE z;

CREATE TABLE tt0 (
    x int NOT NULL,
    y numeric(8, 2)
);

-- OK
CREATE TABLE tt1 (
    x int,
    y bigint
);

-- wrong base type
CREATE TABLE tt2 (
    x int,
    y numeric(9, 2)
);

-- wrong typmod
CREATE TABLE tt3 (
    y numeric(8, 2),
    x int
);

-- wrong column order
CREATE TABLE tt4 (
    x int
);

-- too few columns
CREATE TABLE tt5 (
    x int,
    y numeric(8, 2),
    z int
);

-- too few columns
CREATE TABLE tt6 ()
INHERITS (
    tt0
);

-- can't have a parent
CREATE TABLE tt7 (
    x int,
    q text,
    y numeric(8, 2)
);

ALTER TABLE tt7
    DROP q;

-- OK
ALTER TABLE tt0 OF tt_t0;

ALTER TABLE tt1 OF tt_t0;

ALTER TABLE tt2 OF tt_t0;

ALTER TABLE tt3 OF tt_t0;

ALTER TABLE tt4 OF tt_t0;

ALTER TABLE tt5 OF tt_t0;

ALTER TABLE tt6 OF tt_t0;

ALTER TABLE tt7 OF tt_t0;

CREATE TYPE tt_t1 AS (
    x int,
    y numeric(8, 2)
);

ALTER TABLE tt7 OF tt_t1;

-- reassign an already-typed table
ALTER TABLE tt7 NOT OF;

\d tt7
-- make sure we can drop a constraint on the parent but it remains on the child
CREATE TABLE test_drop_constr_parent (
    c text CHECK (c IS NOT NULL)
);

CREATE TABLE test_drop_constr_child ()
INHERITS (
    test_drop_constr_parent
);

ALTER TABLE ONLY test_drop_constr_parent
    DROP CONSTRAINT "test_drop_constr_parent_c_check";

-- should fail
INSERT INTO test_drop_constr_child (c)
    VALUES (NULL);

DROP TABLE test_drop_constr_parent CASCADE;

--
-- IF EXISTS test
--
ALTER TABLE IF EXISTS tt8
    ADD COLUMN f int;

ALTER TABLE IF EXISTS tt8
    ADD CONSTRAINT xxx PRIMARY KEY (f);

ALTER TABLE IF EXISTS tt8
    ADD CHECK (f BETWEEN 0 AND 10);

ALTER TABLE IF EXISTS tt8
    ALTER COLUMN f SET DEFAULT 0;

ALTER TABLE IF EXISTS tt8 RENAME COLUMN f TO f1;

ALTER TABLE IF EXISTS tt8 SET SCHEMA alter2;

CREATE TABLE tt8 (
    a int
);

CREATE SCHEMA alter2;

ALTER TABLE IF EXISTS tt8
    ADD COLUMN f int;

ALTER TABLE IF EXISTS tt8
    ADD CONSTRAINT xxx PRIMARY KEY (f);

ALTER TABLE IF EXISTS tt8
    ADD CHECK (f BETWEEN 0 AND 10);

ALTER TABLE IF EXISTS tt8
    ALTER COLUMN f SET DEFAULT 0;

ALTER TABLE IF EXISTS tt8 RENAME COLUMN f TO f1;

ALTER TABLE IF EXISTS tt8 SET SCHEMA alter2;

\d alter2.tt8
DROP TABLE alter2.tt8;

DROP SCHEMA alter2;

--
-- Check conflicts between index and CHECK constraint names
--
CREATE TABLE tt9 (
    c integer
);

ALTER TABLE tt9
    ADD CHECK (c > 1);

ALTER TABLE tt9
    ADD CHECK (c > 2);

-- picks nonconflicting name
ALTER TABLE tt9
    ADD CONSTRAINT foo CHECK (c > 3);

ALTER TABLE tt9
    ADD CONSTRAINT foo CHECK (c > 4);

-- fail, dup name
ALTER TABLE tt9
    ADD UNIQUE (c);

ALTER TABLE tt9
    ADD UNIQUE (c);

-- picks nonconflicting name
ALTER TABLE tt9
    ADD CONSTRAINT tt9_c_key UNIQUE (c);

-- fail, dup name
ALTER TABLE tt9
    ADD CONSTRAINT foo UNIQUE (c);

-- fail, dup name
ALTER TABLE tt9
    ADD CONSTRAINT tt9_c_key CHECK (c > 5);

-- fail, dup name
ALTER TABLE tt9
    ADD CONSTRAINT tt9_c_key2 CHECK (c > 6);

ALTER TABLE tt9
    ADD UNIQUE (c);

-- picks nonconflicting name
\d tt9
DROP TABLE tt9;

-- Check that comments on constraints and indexes are not lost at ALTER TABLE.
CREATE TABLE comment_test (
    id int,
    positive_col int CHECK (positive_col > 0),
    indexed_col int,
    CONSTRAINT comment_test_pk PRIMARY KEY (id)
);

CREATE INDEX comment_test_index ON comment_test (indexed_col);

COMMENT ON COLUMN comment_test.id IS 'Column ''id'' on comment_test';

COMMENT ON INDEX comment_test_index IS 'Simple index on comment_test';

COMMENT ON CONSTRAINT comment_test_positive_col_check ON comment_test IS 'CHECK constraint on comment_test.positive_col';

COMMENT ON CONSTRAINT comment_test_pk ON comment_test IS 'PRIMARY KEY constraint of comment_test';

COMMENT ON INDEX comment_test_pk IS 'Index backing the PRIMARY KEY of comment_test';

SELECT
    col_description('comment_test'::regclass, 1) AS comment;

SELECT
    indexrelid::regclass::text AS index,
    obj_description(indexrelid, 'pg_class') AS comment
FROM
    pg_index
WHERE
    indrelid = 'comment_test'::regclass
ORDER BY
    1,
    2;

SELECT
    conname AS constraint,
    obj_description(oid, 'pg_constraint') AS comment
FROM
    pg_constraint
WHERE
    conrelid = 'comment_test'::regclass
ORDER BY
    1,
    2;

-- Change the datatype of all the columns. ALTER TABLE is optimized to not
-- rebuild an index if the new data type is binary compatible with the old
-- one. Check do a dummy ALTER TABLE that doesn't change the datatype
-- first, to test that no-op codepath, and another one that does.
ALTER TABLE comment_test
    ALTER COLUMN indexed_col SET DATA TYPE int;

ALTER TABLE comment_test
    ALTER COLUMN indexed_col SET DATA TYPE text;

ALTER TABLE comment_test
    ALTER COLUMN id SET DATA TYPE int;

ALTER TABLE comment_test
    ALTER COLUMN id SET DATA TYPE text;

ALTER TABLE comment_test
    ALTER COLUMN positive_col SET DATA TYPE int;

ALTER TABLE comment_test
    ALTER COLUMN positive_col SET DATA TYPE bigint;

-- Check that the comments are intact.
SELECT
    col_description('comment_test'::regclass, 1) AS comment;

SELECT
    indexrelid::regclass::text AS index,
    obj_description(indexrelid, 'pg_class') AS comment
FROM
    pg_index
WHERE
    indrelid = 'comment_test'::regclass
ORDER BY
    1,
    2;

SELECT
    conname AS constraint,
    obj_description(oid, 'pg_constraint') AS comment
FROM
    pg_constraint
WHERE
    conrelid = 'comment_test'::regclass
ORDER BY
    1,
    2;

-- Check compatibility for foreign keys and comments. This is done
-- separately as rebuilding the column type of the parent leads
-- to an error and would reduce the test scope.
CREATE TABLE comment_test_child (
    id text CONSTRAINT comment_test_child_fk REFERENCES comment_test
);

CREATE INDEX comment_test_child_fk ON comment_test_child (id);

COMMENT ON COLUMN comment_test_child.id IS 'Column ''id'' on comment_test_child';

COMMENT ON INDEX comment_test_child_fk IS 'Index backing the FOREIGN KEY of comment_test_child';

COMMENT ON CONSTRAINT comment_test_child_fk ON comment_test_child IS 'FOREIGN KEY constraint of comment_test_child';

-- Change column type of parent
ALTER TABLE comment_test
    ALTER COLUMN id SET DATA TYPE text;

ALTER TABLE comment_test
    ALTER COLUMN id SET DATA TYPE int USING id::integer;

-- Comments should be intact
SELECT
    col_description('comment_test_child'::regclass, 1) AS comment;

SELECT
    indexrelid::regclass::text AS index,
    obj_description(indexrelid, 'pg_class') AS comment
FROM
    pg_index
WHERE
    indrelid = 'comment_test_child'::regclass
ORDER BY
    1,
    2;

SELECT
    conname AS constraint,
    obj_description(oid, 'pg_constraint') AS comment
FROM
    pg_constraint
WHERE
    conrelid = 'comment_test_child'::regclass
ORDER BY
    1,
    2;

-- Check that we map relation oids to filenodes and back correctly.  Only
-- display bad mappings so the test output doesn't change all the time.  A
-- filenode function call can return NULL for a relation dropped concurrently
-- with the call's surrounding query, so ignore a NULL mapped_oid for
-- relations that no longer exist after all calls finish.
CREATE TEMP TABLE filenode_mapping AS
SELECT
    oid,
    mapped_oid,
    reltablespace,
    relfilenode,
    relname
FROM
    pg_class,
    pg_filenode_relation(reltablespace, pg_relation_filenode(oid)) AS mapped_oid
WHERE
    relkind IN ('r', 'i', 'S', 't', 'm')
    AND mapped_oid IS DISTINCT FROM oid;

SELECT
    m.*
FROM
    filenode_mapping m
    LEFT JOIN pg_class c ON c.oid = m.oid
WHERE
    c.oid IS NOT NULL
    OR m.mapped_oid IS NOT NULL;

-- Checks on creating and manipulation of user defined relations in
-- pg_catalog.
--
-- XXX: It would be useful to add checks around trying to manipulate
-- catalog tables, but that might have ugly consequences when run
-- against an existing server with allow_system_table_mods = on.
SHOW allow_system_table_mods;

-- disallowed because of search_path issues with pg_dump
CREATE TABLE pg_catalog.new_system_table ();

-- instead create in public first, move to catalog
CREATE TABLE new_system_table (
    id serial PRIMARY KEY,
    othercol text
);

ALTER TABLE new_system_table SET SCHEMA pg_catalog;

ALTER TABLE new_system_table SET SCHEMA public;

ALTER TABLE new_system_table SET SCHEMA pg_catalog;

-- will be ignored -- already there:
ALTER TABLE new_system_table SET SCHEMA pg_catalog;

ALTER TABLE new_system_table RENAME TO old_system_table;

CREATE INDEX old_system_table__othercol ON old_system_table (othercol);

INSERT INTO old_system_table (othercol)
VALUES
    ('somedata'),
    ('otherdata');

UPDATE
    old_system_table
SET
    id = - id;

DELETE FROM old_system_table
WHERE othercol = 'somedata';

TRUNCATE old_system_table;

ALTER TABLE old_system_table
    DROP CONSTRAINT new_system_table_pkey;

ALTER TABLE old_system_table
    DROP COLUMN othercol;

DROP TABLE old_system_table;

-- set logged
CREATE UNLOGGED TABLE unlogged1 (
    f1 serial PRIMARY KEY,
    f2 text
);

-- check relpersistence of an unlogged table
SELECT
    relname,
    relkind,
    relpersistence
FROM
    pg_class
WHERE
    relname ~ '^unlogged1'
UNION ALL
SELECT
    'toast table',
    t.relkind,
    t.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
WHERE
    r.relname ~ '^unlogged1'
UNION ALL
SELECT
    'toast index',
    ri.relkind,
    ri.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
    JOIN pg_index i ON i.indrelid = t.oid
    JOIN pg_class ri ON ri.oid = i.indexrelid
WHERE
    r.relname ~ '^unlogged1'
ORDER BY
    relname;

CREATE UNLOGGED TABLE unlogged2 (
    f1 serial PRIMARY KEY,
    f2 integer REFERENCES unlogged1
);

-- foreign key
CREATE UNLOGGED TABLE unlogged3 (
    f1 serial PRIMARY KEY,
    f2 integer REFERENCES unlogged3
);

-- self-referencing foreign key
ALTER TABLE unlogged3 SET LOGGED;

-- skip self-referencing foreign key
ALTER TABLE unlogged2 SET LOGGED;

-- fails because a foreign key to an unlogged table exists
ALTER TABLE unlogged1 SET LOGGED;

-- check relpersistence of an unlogged table after changing to permanent
SELECT
    relname,
    relkind,
    relpersistence
FROM
    pg_class
WHERE
    relname ~ '^unlogged1'
UNION ALL
SELECT
    'toast table',
    t.relkind,
    t.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
WHERE
    r.relname ~ '^unlogged1'
UNION ALL
SELECT
    'toast index',
    ri.relkind,
    ri.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
    JOIN pg_index i ON i.indrelid = t.oid
    JOIN pg_class ri ON ri.oid = i.indexrelid
WHERE
    r.relname ~ '^unlogged1'
ORDER BY
    relname;

ALTER TABLE unlogged1 SET LOGGED;

-- silently do nothing
DROP TABLE unlogged3;

DROP TABLE unlogged2;

DROP TABLE unlogged1;

-- set unlogged
CREATE TABLE logged1 (
    f1 serial PRIMARY KEY,
    f2 text
);

-- check relpersistence of a permanent table
SELECT
    relname,
    relkind,
    relpersistence
FROM
    pg_class
WHERE
    relname ~ '^logged1'
UNION ALL
SELECT
    'toast table',
    t.relkind,
    t.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
WHERE
    r.relname ~ '^logged1'
UNION ALL
SELECT
    'toast index',
    ri.relkind,
    ri.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
    JOIN pg_index i ON i.indrelid = t.oid
    JOIN pg_class ri ON ri.oid = i.indexrelid
WHERE
    r.relname ~ '^logged1'
ORDER BY
    relname;

CREATE TABLE logged2 (
    f1 serial PRIMARY KEY,
    f2 integer REFERENCES logged1
);

-- foreign key
CREATE TABLE logged3 (
    f1 serial PRIMARY KEY,
    f2 integer REFERENCES logged3
);

-- self-referencing foreign key
ALTER TABLE logged1 SET UNLOGGED;

-- fails because a foreign key from a permanent table exists
ALTER TABLE logged3 SET UNLOGGED;

-- skip self-referencing foreign key
ALTER TABLE logged2 SET UNLOGGED;

ALTER TABLE logged1 SET UNLOGGED;

-- check relpersistence of a permanent table after changing to unlogged
SELECT
    relname,
    relkind,
    relpersistence
FROM
    pg_class
WHERE
    relname ~ '^logged1'
UNION ALL
SELECT
    'toast table',
    t.relkind,
    t.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
WHERE
    r.relname ~ '^logged1'
UNION ALL
SELECT
    'toast index',
    ri.relkind,
    ri.relpersistence
FROM
    pg_class r
    JOIN pg_class t ON t.oid = r.reltoastrelid
    JOIN pg_index i ON i.indrelid = t.oid
    JOIN pg_class ri ON ri.oid = i.indexrelid
WHERE
    r.relname ~ '^logged1'
ORDER BY
    relname;

ALTER TABLE logged1 SET UNLOGGED;

-- silently do nothing
DROP TABLE logged3;

DROP TABLE logged2;

DROP TABLE logged1;

-- test ADD COLUMN IF NOT EXISTS
CREATE TABLE test_add_column (
    c1 integer
);

\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN c2 integer;

\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN c2 integer;

-- fail because c2 already exists
ALTER TABLE ONLY test_add_column
    ADD COLUMN c2 integer;

-- fail because c2 already exists
\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN IF NOT EXISTS c2 integer;

-- skipping because c2 already exists
ALTER TABLE ONLY test_add_column
    ADD COLUMN IF NOT EXISTS c2 integer;

-- skipping because c2 already exists
\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN c2 integer, -- fail because c2 already exists
    ADD COLUMN c3 integer;

\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN IF NOT EXISTS c2 integer, -- skipping because c2 already exists
    ADD COLUMN c3 integer;

-- fail because c3 already exists
\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN IF NOT EXISTS c2 integer, -- skipping because c2 already exists
    ADD COLUMN IF NOT EXISTS c3 integer;

-- skipping because c3 already exists
\d test_add_column
ALTER TABLE test_add_column
    ADD COLUMN IF NOT EXISTS c2 integer, -- skipping because c2 already exists
    ADD COLUMN IF NOT EXISTS c3 integer, -- skipping because c3 already exists
    ADD COLUMN c4 integer;

\d test_add_column
DROP TABLE test_add_column;

-- unsupported constraint types for partitioned tables
CREATE TABLE partitioned (
    a int,
    b int
)
PARTITION BY RANGE (a, (a + b + 1));

ALTER TABLE partitioned
    ADD EXCLUDE USING gist (a WITH &&);

-- cannot drop column that is part of the partition key
ALTER TABLE partitioned
    DROP COLUMN a;

ALTER TABLE partitioned
    ALTER COLUMN a TYPE char(5);

ALTER TABLE partitioned
    DROP COLUMN b;

ALTER TABLE partitioned
    ALTER COLUMN b TYPE char(5);

-- partitioned table cannot participate in regular inheritance
CREATE TABLE nonpartitioned (
    a int,
    b int
);

ALTER TABLE partitioned INHERIT nonpartitioned;

ALTER TABLE nonpartitioned INHERIT partitioned;

-- cannot add NO INHERIT constraint to partitioned tables
ALTER TABLE partitioned
    ADD CONSTRAINT chk_a CHECK (a > 0) NO INHERIT;

DROP TABLE partitioned, nonpartitioned;

--
-- ATTACH PARTITION
--
-- check that target table is partitioned
CREATE TABLE unparted (
    a int
);

CREATE TABLE fail_part (
    LIKE unparted
);

ALTER TABLE unparted ATTACH PARTITION fail_part
FOR VALUES IN ('a');

DROP TABLE unparted, fail_part;

-- check that partition bound is compatible
CREATE TABLE list_parted (
    a int NOT NULL,
    b char(2) COLLATE "C",
    CONSTRAINT check_a CHECK (a > 0)
)
PARTITION BY LIST (a);

CREATE TABLE fail_part (
    LIKE list_parted
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES FROM (1) TO (10);

DROP TABLE fail_part;

-- check that the table being attached exists
ALTER TABLE list_parted ATTACH PARTITION nonexistant
FOR VALUES IN (1);

-- check ownership of the source table
CREATE ROLE regress_test_me;

CREATE ROLE regress_test_not_me;

CREATE TABLE not_owned_by_me (
    LIKE list_parted
);

ALTER TABLE not_owned_by_me OWNER TO regress_test_not_me;

SET SESSION AUTHORIZATION regress_test_me;

CREATE TABLE owned_by_me (
    a int
)
PARTITION BY LIST (a);

ALTER TABLE owned_by_me ATTACH PARTITION not_owned_by_me
FOR VALUES IN (1);

RESET SESSION AUTHORIZATION;

DROP TABLE owned_by_me, not_owned_by_me;

DROP ROLE regress_test_not_me;

DROP ROLE regress_test_me;

-- check that the table being attached is not part of regular inheritance
CREATE TABLE parent (
    LIKE list_parted
);

CREATE TABLE child ()
INHERITS (
    parent
);

ALTER TABLE list_parted ATTACH PARTITION child
FOR VALUES IN (1);

ALTER TABLE list_parted ATTACH PARTITION parent
FOR VALUES IN (1);

DROP TABLE parent CASCADE;

-- check any TEMP-ness
CREATE TEMP TABLE temp_parted (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE perm_part (
    a int
);

ALTER TABLE temp_parted ATTACH PARTITION perm_part
FOR VALUES IN (1);

DROP TABLE temp_parted, perm_part;

-- check that the table being attached is not a typed table
CREATE TYPE mytype AS (
    a int
);

CREATE TABLE fail_part OF mytype;

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TYPE mytype CASCADE;

-- check that the table being attached has only columns present in the parent
CREATE TABLE fail_part (
    LIKE list_parted,
    c int
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TABLE fail_part;

-- check that the table being attached has every column of the parent
CREATE TABLE fail_part (
    a int NOT NULL
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TABLE fail_part;

-- check that columns match in type, collation and NOT NULL status
CREATE TABLE fail_part (
    b char(3),
    a int NOT NULL
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

ALTER TABLE fail_part
    ALTER b TYPE char(2) COLLATE "POSIX";

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TABLE fail_part;

-- check that the table being attached has all constraints of the parent
CREATE TABLE fail_part (
    b char(2) COLLATE "C",
    a int NOT NULL
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

-- check that the constraint matches in definition with parent's constraint
ALTER TABLE fail_part
    ADD CONSTRAINT check_a CHECK (a >= 0);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TABLE fail_part;

-- check the attributes and constraints after partition is attached
CREATE TABLE part_1 (
    a int NOT NULL,
    b char(2) COLLATE "C",
    CONSTRAINT check_a CHECK (a > 0)
);

ALTER TABLE list_parted ATTACH PARTITION part_1
FOR VALUES IN (1);

-- attislocal and conislocal are always false for merged attributes and constraints respectively.
SELECT
    attislocal,
    attinhcount
FROM
    pg_attribute
WHERE
    attrelid = 'part_1'::regclass
    AND attnum > 0;

SELECT
    conislocal,
    coninhcount
FROM
    pg_constraint
WHERE
    conrelid = 'part_1'::regclass
    AND conname = 'check_a';

-- check that the new partition won't overlap with an existing partition
CREATE TABLE fail_part (
    LIKE part_1 INCLUDING CONSTRAINTS
);

ALTER TABLE list_parted ATTACH PARTITION fail_part
FOR VALUES IN (1);

DROP TABLE fail_part;

-- check that an existing table can be attached as a default partition
CREATE TABLE def_part (
    LIKE list_parted INCLUDING CONSTRAINTS
);

ALTER TABLE list_parted ATTACH PARTITION def_part DEFAULT;

-- check attaching default partition fails if a default partition already
-- exists
CREATE TABLE fail_def_part (
    LIKE part_1 INCLUDING CONSTRAINTS
);

ALTER TABLE list_parted ATTACH PARTITION fail_def_part DEFAULT;

-- check validation when attaching list partitions
CREATE TABLE list_parted2 (
    a int,
    b char
)
PARTITION BY LIST (a);

-- check that violating rows are correctly reported
CREATE TABLE part_2 (
    LIKE list_parted2
);

INSERT INTO part_2
    VALUES (3, 'a');

ALTER TABLE list_parted2 ATTACH PARTITION part_2
FOR VALUES IN (2);

-- should be ok after deleting the bad row
DELETE FROM part_2;

ALTER TABLE list_parted2 ATTACH PARTITION part_2
FOR VALUES IN (2);

-- check partition cannot be attached if default has some row for its values
CREATE TABLE list_parted2_def PARTITION OF list_parted2 DEFAULT;

INSERT INTO list_parted2_def
    VALUES (11, 'z');

CREATE TABLE part_3 (
    LIKE list_parted2
);

ALTER TABLE list_parted2 ATTACH PARTITION part_3
FOR VALUES IN (11);

-- should be ok after deleting the bad row
DELETE FROM list_parted2_def
WHERE a = 11;

ALTER TABLE list_parted2 ATTACH PARTITION part_3
FOR VALUES IN (11);

-- adding constraints that describe the desired partition constraint
-- (or more restrictive) will help skip the validation scan
CREATE TABLE part_3_4 (
    LIKE list_parted2,
    CONSTRAINT check_a CHECK (a IN (3))
);

-- however, if a list partition does not accept nulls, there should be
-- an explicit NOT NULL constraint on the partition key column for the
-- validation scan to be skipped;
ALTER TABLE list_parted2 ATTACH PARTITION part_3_4
FOR VALUES IN (3, 4);

-- adding a NOT NULL constraint will cause the scan to be skipped
ALTER TABLE list_parted2 DETACH PARTITION part_3_4;

ALTER TABLE part_3_4
    ALTER a SET NOT NULL;

ALTER TABLE list_parted2 ATTACH PARTITION part_3_4
FOR VALUES IN (3, 4);

-- check if default partition scan skipped
ALTER TABLE list_parted2_def
    ADD CONSTRAINT check_a CHECK (a IN (5, 6));

CREATE TABLE part_55_66 PARTITION OF list_parted2
FOR VALUES IN (55, 66);

-- check validation when attaching range partitions
CREATE TABLE range_parted (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

-- check that violating rows are correctly reported
CREATE TABLE part1 (
    a int NOT NULL CHECK (a = 1),
    b int NOT NULL CHECK (b >= 1 AND b <= 10)
);

INSERT INTO part1
    VALUES (1, 10);

-- Remember the TO bound is exclusive
ALTER TABLE range_parted ATTACH PARTITION part1
FOR VALUES FROM (1, 1) TO (1, 10);

-- should be ok after deleting the bad row
DELETE FROM part1;

ALTER TABLE range_parted ATTACH PARTITION part1
FOR VALUES FROM (1, 1) TO (1, 10);

-- adding constraints that describe the desired partition constraint
-- (or more restrictive) will help skip the validation scan
CREATE TABLE part2 (
    a int NOT NULL CHECK (a = 1),
    b int NOT NULL CHECK (b >= 10 AND b < 18)
);

ALTER TABLE range_parted ATTACH PARTITION part2
FOR VALUES FROM (1, 10) TO (1, 20);

-- Create default partition
CREATE TABLE partr_def1 PARTITION OF range_parted DEFAULT;

-- Only one default partition is allowed, hence, following should give error
CREATE TABLE partr_def2 (
    LIKE part1 INCLUDING CONSTRAINTS
);

ALTER TABLE range_parted ATTACH PARTITION partr_def2 DEFAULT;

-- Overlapping partitions cannot be attached, hence, following should give error
INSERT INTO partr_def1
    VALUES (2, 10);

CREATE TABLE part3 (
    LIKE range_parted
);

ALTER TABLE range_parted ATTACH PARTITION part3
FOR VALUES FROM (2, 10) TO (2, 20);

-- Attaching partitions should be successful when there are no overlapping rows
ALTER TABLE range_parted ATTACH PARTITION part3
FOR VALUES FROM (3, 10) TO (3, 20);

-- check that leaf partitions are scanned when attaching a partitioned
-- table
CREATE TABLE part_5 (
    LIKE list_parted2
)
PARTITION BY LIST (b);

-- check that violating rows are correctly reported
CREATE TABLE part_5_a PARTITION OF part_5
FOR VALUES IN ('a');

INSERT INTO part_5_a (a, b)
    VALUES (6, 'a');

ALTER TABLE list_parted2 ATTACH PARTITION part_5
FOR VALUES IN (5);

-- delete the faulting row and also add a constraint to skip the scan
DELETE FROM part_5_a
WHERE a NOT IN (3);

ALTER TABLE part_5
    ADD CONSTRAINT check_a CHECK (a IS NOT NULL AND a = 5);

ALTER TABLE list_parted2 ATTACH PARTITION part_5
FOR VALUES IN (5);

ALTER TABLE list_parted2 DETACH PARTITION part_5;

ALTER TABLE part_5
    DROP CONSTRAINT check_a;

-- scan should again be skipped, even though NOT NULL is now a column property
ALTER TABLE part_5
    ADD CONSTRAINT check_a CHECK (a IN (5)),
    ALTER a SET NOT NULL;

ALTER TABLE list_parted2 ATTACH PARTITION part_5
FOR VALUES IN (5);

-- Check the case where attnos of the partitioning columns in the table being
-- attached differs from the parent.  It should not affect the constraint-
-- checking logic that allows to skip the scan.
CREATE TABLE part_6 (
    c int,
    LIKE list_parted2,
    CONSTRAINT check_a CHECK (a IS NOT NULL AND a = 6)
);

ALTER TABLE part_6
    DROP c;

ALTER TABLE list_parted2 ATTACH PARTITION part_6
FOR VALUES IN (6);

-- Similar to above, but the table being attached is a partitioned table
-- whose partition has still different attnos for the root partitioning
-- columns.
CREATE TABLE part_7 (
    LIKE list_parted2,
    CONSTRAINT check_a CHECK (a IS NOT NULL AND a = 7)
)
PARTITION BY LIST (b);

CREATE TABLE part_7_a_null (
    c int,
    d int,
    e int,
    LIKE list_parted2, -- 'a' will have attnum = 4
    CONSTRAINT check_b CHECK (b IS NULL OR b = 'a'),
    CONSTRAINT check_a CHECK (a IS NOT NULL AND a = 7)
);

ALTER TABLE part_7_a_null
    DROP c,
    DROP d,
    DROP e;

ALTER TABLE part_7 ATTACH PARTITION part_7_a_null
FOR VALUES IN ('a', NULL);

ALTER TABLE list_parted2 ATTACH PARTITION part_7
FOR VALUES IN (7);

-- Same example, but check this time that the constraint correctly detects
-- violating rows
ALTER TABLE list_parted2 DETACH PARTITION part_7;

ALTER TABLE part_7
    DROP CONSTRAINT check_a;

-- thusly, scan won't be skipped
INSERT INTO part_7 (a, b)
VALUES
    (8, NULL),
    (9, 'a');

SELECT
    tableoid::regclass,
    a,
    b
FROM
    part_7
ORDER BY
    a;

ALTER TABLE list_parted2 ATTACH PARTITION part_7
FOR VALUES IN (7);

-- check that leaf partitions of default partition are scanned when
-- attaching a partitioned table.
ALTER TABLE part_5
    DROP CONSTRAINT check_a;

CREATE TABLE part5_def PARTITION OF part_5 DEFAULT PARTITION BY LIST (a);

CREATE TABLE part5_def_p1 PARTITION OF part5_def
FOR VALUES IN (5);

INSERT INTO part5_def_p1
    VALUES (5, 'y');

CREATE TABLE part5_p1 (
    LIKE part_5
);

ALTER TABLE part_5 ATTACH PARTITION part5_p1
FOR VALUES IN ('y');

-- should be ok after deleting the bad row
DELETE FROM part5_def_p1
WHERE b = 'y';

ALTER TABLE part_5 ATTACH PARTITION part5_p1
FOR VALUES IN ('y');

-- check that the table being attached is not already a partition
ALTER TABLE list_parted2 ATTACH PARTITION part_2
FOR VALUES IN (2);

-- check that circular inheritance is not allowed
ALTER TABLE part_5 ATTACH PARTITION list_parted2
FOR VALUES IN ('b');

ALTER TABLE list_parted2 ATTACH PARTITION list_parted2
FOR VALUES IN (0);

-- If a partitioned table being created or an existing table being attached
-- as a partition does not have a constraint that would allow validation scan
-- to be skipped, but an individual partition does, then the partition's
-- validation scan is skipped.
CREATE TABLE quuux (
    a int,
    b text
)
PARTITION BY LIST (a);

CREATE TABLE quuux_default PARTITION OF quuux DEFAULT PARTITION BY LIST (b);

CREATE TABLE quuux_default1 PARTITION OF quuux_default (CONSTRAINT check_1 CHECK (a IS NOT NULL AND a = 1))
FOR VALUES IN ('b');

CREATE TABLE quuux1 (
    a int,
    b text
);

ALTER TABLE quuux ATTACH PARTITION quuux1
FOR VALUES IN (1);

-- validate!
CREATE TABLE quuux2 (
    a int,
    b text
);

ALTER TABLE quuux ATTACH PARTITION quuux2
FOR VALUES IN (2);

-- skip validation
DROP TABLE quuux1, quuux2;

-- should validate for quuux1, but not for quuux2
CREATE TABLE quuux1 PARTITION OF quuux
FOR VALUES IN (1);

CREATE TABLE quuux2 PARTITION OF quuux
FOR VALUES IN (2);

DROP TABLE quuux;

-- check validation when attaching hash partitions
-- Use hand-rolled hash functions and operator class to get predictable result
-- on different matchines. part_test_int4_ops is defined in insert.sql.
-- check that the new partition won't overlap with an existing partition
CREATE TABLE hash_parted (
    a int,
    b int
)
PARTITION BY HASH (a part_test_int4_ops);

CREATE TABLE hpart_1 PARTITION OF hash_parted
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE fail_part (
    LIKE hpart_1
);

ALTER TABLE hash_parted ATTACH PARTITION fail_part
FOR VALUES WITH (MODULUS 8, REMAINDER 4);

ALTER TABLE hash_parted ATTACH PARTITION fail_part
FOR VALUES WITH (MODULUS 8, REMAINDER 0);

DROP TABLE fail_part;

-- check validation when attaching hash partitions
-- check that violating rows are correctly reported
CREATE TABLE hpart_2 (
    LIKE hash_parted
);

INSERT INTO hpart_2
    VALUES (3, 0);

ALTER TABLE hash_parted ATTACH PARTITION hpart_2
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

-- should be ok after deleting the bad row
DELETE FROM hpart_2;

ALTER TABLE hash_parted ATTACH PARTITION hpart_2
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

-- check that leaf partitions are scanned when attaching a partitioned
-- table
CREATE TABLE hpart_5 (
    LIKE hash_parted
)
PARTITION BY LIST (b);

-- check that violating rows are correctly reported
CREATE TABLE hpart_5_a PARTITION OF hpart_5
FOR VALUES IN ('1', '2', '3');

INSERT INTO hpart_5_a (a, b)
    VALUES (7, 1);

ALTER TABLE hash_parted ATTACH PARTITION hpart_5
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

-- should be ok after deleting the bad row
DELETE FROM hpart_5_a;

ALTER TABLE hash_parted ATTACH PARTITION hpart_5
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

-- check that the table being attach is with valid modulus and remainder value
CREATE TABLE fail_part (
    LIKE hash_parted
);

ALTER TABLE hash_parted ATTACH PARTITION fail_part
FOR VALUES WITH (MODULUS 0, REMAINDER 1);

ALTER TABLE hash_parted ATTACH PARTITION fail_part
FOR VALUES WITH (MODULUS 8, REMAINDER 8);

ALTER TABLE hash_parted ATTACH PARTITION fail_part
FOR VALUES WITH (MODULUS 3, REMAINDER 2);

DROP TABLE fail_part;

--
-- DETACH PARTITION
--
-- check that the table is partitioned at all
CREATE TABLE regular_table (
    a int
);

ALTER TABLE regular_table DETACH PARTITION any_name;

DROP TABLE regular_table;

-- check that the partition being detached exists at all
ALTER TABLE list_parted2 DETACH PARTITION part_4;

ALTER TABLE hash_parted DETACH PARTITION hpart_4;

-- check that the partition being detached is actually a partition of the parent
CREATE TABLE not_a_part (
    a int
);

ALTER TABLE list_parted2 DETACH PARTITION not_a_part;

ALTER TABLE list_parted2 DETACH PARTITION part_1;

ALTER TABLE hash_parted DETACH PARTITION not_a_part;

DROP TABLE not_a_part;

-- check that, after being detached, attinhcount/coninhcount is dropped to 0 and
-- attislocal/conislocal is set to true
ALTER TABLE list_parted2 DETACH PARTITION part_3_4;

SELECT
    attinhcount,
    attislocal
FROM
    pg_attribute
WHERE
    attrelid = 'part_3_4'::regclass
    AND attnum > 0;

SELECT
    coninhcount,
    conislocal
FROM
    pg_constraint
WHERE
    conrelid = 'part_3_4'::regclass
    AND conname = 'check_a';

DROP TABLE part_3_4;

-- check that a detached partition is not dropped on dropping a partitioned table
CREATE TABLE range_parted2 (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE part_rp PARTITION OF range_parted2
FOR VALUES FROM (0) TO (100);

ALTER TABLE range_parted2 DETACH PARTITION part_rp;

DROP TABLE range_parted2;

SELECT
    *
FROM
    part_rp;

DROP TABLE part_rp;

-- Check ALTER TABLE commands for partitioned tables and partitions
-- cannot add/drop column to/from *only* the parent
ALTER TABLE ONLY list_parted2
    ADD COLUMN c int;

ALTER TABLE ONLY list_parted2
    DROP COLUMN b;

-- cannot add a column to partition or drop an inherited one
ALTER TABLE part_2
    ADD COLUMN c text;

ALTER TABLE part_2
    DROP COLUMN b;

-- Nor rename, alter type
ALTER TABLE part_2 RENAME COLUMN b TO c;

ALTER TABLE part_2
    ALTER COLUMN b TYPE text;

-- cannot add/drop NOT NULL or check constraints to *only* the parent, when
-- partitions exist
ALTER TABLE ONLY list_parted2
    ALTER b SET NOT NULL;

ALTER TABLE ONLY list_parted2
    ADD CONSTRAINT check_b CHECK (b <> 'zz');

ALTER TABLE list_parted2
    ALTER b SET NOT NULL;

ALTER TABLE ONLY list_parted2
    ALTER b DROP NOT NULL;

ALTER TABLE list_parted2
    ADD CONSTRAINT check_b CHECK (b <> 'zz');

ALTER TABLE ONLY list_parted2
    DROP CONSTRAINT check_b;

-- It's alright though, if no partitions are yet created
CREATE TABLE parted_no_parts (
    a int
)
PARTITION BY LIST (a);

ALTER TABLE ONLY parted_no_parts
    ALTER a SET NOT NULL;

ALTER TABLE ONLY parted_no_parts
    ADD CONSTRAINT check_a CHECK (a > 0);

ALTER TABLE ONLY parted_no_parts
    ALTER a DROP NOT NULL;

ALTER TABLE ONLY parted_no_parts
    DROP CONSTRAINT check_a;

DROP TABLE parted_no_parts;

-- cannot drop inherited NOT NULL or check constraints from partition
ALTER TABLE list_parted2
    ALTER b SET NOT NULL,
    ADD CONSTRAINT check_a2 CHECK (a > 0);

ALTER TABLE part_2
    ALTER b DROP NOT NULL;

ALTER TABLE part_2
    DROP CONSTRAINT check_a2;

-- Doesn't make sense to add NO INHERIT constraints on partitioned tables
ALTER TABLE list_parted2
    ADD CONSTRAINT check_b2 CHECK (b <> 'zz') NO INHERIT;

-- check that a partition cannot participate in regular inheritance
CREATE TABLE inh_test ()
INHERITS (
    part_2
);

CREATE TABLE inh_test (
    LIKE part_2
);

ALTER TABLE inh_test INHERIT part_2;

ALTER TABLE part_2 INHERIT inh_test;

-- cannot drop or alter type of partition key columns of lower level
-- partitioned tables; for example, part_5, which is list_parted2's
-- partition, is partitioned on b;
ALTER TABLE list_parted2
    DROP COLUMN b;

ALTER TABLE list_parted2
    ALTER COLUMN b TYPE text;

-- dropping non-partition key columns should be allowed on the parent table.
ALTER TABLE list_parted
    DROP COLUMN b;

SELECT
    *
FROM
    list_parted;

-- cleanup
DROP TABLE list_parted, list_parted2, range_parted;

DROP TABLE fail_def_part;

DROP TABLE hash_parted;

-- more tests for certain multi-level partitioning scenarios
CREATE TABLE p (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE p1 (
    b int,
    a int NOT NULL
)
PARTITION BY RANGE (b);

CREATE TABLE p11 (
    LIKE p1
);

ALTER TABLE p11
    DROP a;

ALTER TABLE p11
    ADD a int;

ALTER TABLE p11
    DROP a;

ALTER TABLE p11
    ADD a int NOT NULL;

-- attnum for key attribute 'a' is different in p, p1, and p11
SELECT
    attrelid::regclass,
    attname,
    attnum
FROM
    pg_attribute
WHERE
    attname = 'a'
    AND (attrelid = 'p'::regclass
        OR attrelid = 'p1'::regclass
        OR attrelid = 'p11'::regclass)
ORDER BY
    attrelid::regclass::text;

ALTER TABLE p1 ATTACH PARTITION p11
FOR VALUES FROM (2) TO (5);

INSERT INTO p1 (a, b)
    VALUES (2, 3);

-- check that partition validation scan correctly detects violating rows
ALTER TABLE p ATTACH PARTITION p1
FOR VALUES FROM (1, 2) TO (1, 10);

-- cleanup
DROP TABLE p;

DROP TABLE p1;

-- validate constraint on partitioned tables should only scan leaf partitions
CREATE TABLE parted_validate_test (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE parted_validate_test_1 PARTITION OF parted_validate_test
FOR VALUES IN (0, 1);

ALTER TABLE parted_validate_test
    ADD CONSTRAINT parted_validate_test_chka CHECK (a > 0) NOT valid;

ALTER TABLE parted_validate_test validate CONSTRAINT parted_validate_test_chka;

DROP TABLE parted_validate_test;

-- test alter column options
CREATE TABLE attmp (
    i integer
);

INSERT INTO attmp
    VALUES (1);

ALTER TABLE attmp
    ALTER COLUMN i SET (n_distinct = 1, n_distinct_inherited = 2);

ALTER TABLE attmp
    ALTER COLUMN i RESET (n_distinct_inherited);

ANALYZE attmp;

DROP TABLE attmp;

DROP USER regress_alter_table_user1;

-- check that violating rows are correctly reported when attaching as the
-- default partition
CREATE TABLE defpart_attach_test (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE defpart_attach_test1 PARTITION OF defpart_attach_test
FOR VALUES IN (1);

CREATE TABLE defpart_attach_test_d (
    LIKE defpart_attach_test
);

INSERT INTO defpart_attach_test_d
VALUES
    (1),
    (2);

-- error because its constraint as the default partition would be violated
-- by the row containing 1
ALTER TABLE defpart_attach_test ATTACH PARTITION defpart_attach_test_d DEFAULT;

DELETE FROM defpart_attach_test_d
WHERE a = 1;

ALTER TABLE defpart_attach_test_d
    ADD CHECK (a > 1);

-- should be attached successfully and without needing to be scanned
ALTER TABLE defpart_attach_test ATTACH PARTITION defpart_attach_test_d DEFAULT;

DROP TABLE defpart_attach_test;

-- check combinations of temporary and permanent relations when attaching
-- partitions.
CREATE TABLE perm_part_parent (
    a int
)
PARTITION BY LIST (a);

CREATE temp TABLE temp_part_parent (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE perm_part_child (
    a int
);

CREATE temp TABLE temp_part_child (
    a int
);

ALTER TABLE temp_part_parent ATTACH PARTITION perm_part_child DEFAULT;

-- error
ALTER TABLE perm_part_parent ATTACH PARTITION temp_part_child DEFAULT;

-- error
ALTER TABLE temp_part_parent ATTACH PARTITION temp_part_child DEFAULT;

-- ok
DROP TABLE perm_part_parent CASCADE;

DROP TABLE temp_part_parent CASCADE;

-- check that attaching partitions to a table while it is being used is
-- prevented
CREATE TABLE tab_part_attach (
    a int
)
PARTITION BY LIST (a);

CREATE OR REPLACE FUNCTION func_part_attach ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE 'create table tab_part_attach_1 (a int)';
    EXECUTE 'alter table tab_part_attach attach partition tab_part_attach_1 for values in (1)';
    RETURN NULL;
END
$$;

CREATE TRIGGER trig_part_attach
    BEFORE INSERT ON tab_part_attach FOR EACH statement
    EXECUTE PROCEDURE func_part_attach ();

INSERT INTO tab_part_attach
    VALUES (1);

DROP TABLE tab_part_attach;

DROP FUNCTION func_part_attach ();

-- test case where the partitioning operator is a SQL function whose
-- evaluation results in the table's relcache being rebuilt partway through
-- the execution of an ATTACH PARTITION command
CREATE FUNCTION at_test_sql_partop (int4, int4)
    RETURNS int
    LANGUAGE sql
    AS $$
    SELECT
        CASE WHEN $1 = $2 THEN
            0
        WHEN $1 > $2 THEN
            1
        ELSE
            -1
        END;
$$;

CREATE OPERATOR class at_test_sql_partop FOR TYPE int4
    USING btree AS
    OPERATOR 1 < (int4, int4),
    OPERATOR 2 <= (int4, int4),
    OPERATOR 3 = (int4, int4),
    OPERATOR 4 >= (int4, int4),
    OPERATOR 5 > (int4, int4),
    FUNCTION 1 at_test_sql_partop (int4, int4
);

CREATE TABLE at_test_sql_partop (
    a int
)
PARTITION BY RANGE (a at_test_sql_partop);

CREATE TABLE at_test_sql_partop_1 (
    a int
);

ALTER TABLE at_test_sql_partop ATTACH PARTITION at_test_sql_partop_1
FOR VALUES FROM (0) TO (10);

DROP TABLE at_test_sql_partop;

DROP OPERATOR class at_test_sql_partop
    USING btree;

DROP FUNCTION at_test_sql_partop;

