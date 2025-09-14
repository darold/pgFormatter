--
-- FOREIGN KEY
--
-- MATCH FULL
--
-- First test, check and cascade
--
CREATE TABLE PKTABLE (
    ptest1 int PRIMARY KEY,
    ptest2 text
);

CREATE TABLE FKTABLE (
    ftest1 int REFERENCES PKTABLE MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
    ftest2 int
);

-- Insert test data into PKTABLE
INSERT INTO PKTABLE
    VALUES (1, 'Test1');

INSERT INTO PKTABLE
    VALUES (2, 'Test2');

INSERT INTO PKTABLE
    VALUES (3, 'Test3');

INSERT INTO PKTABLE
    VALUES (4, 'Test4');

INSERT INTO PKTABLE
    VALUES (5, 'Test5');

-- Insert successful rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (1, 2);

INSERT INTO FKTABLE
    VALUES (2, 3);

INSERT INTO FKTABLE
    VALUES (3, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 1);

-- Insert a failed row into FK TABLE
INSERT INTO FKTABLE
    VALUES (100, 2);

-- Check FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Delete a row from PK TABLE
DELETE FROM PKTABLE
WHERE ptest1 = 1;

-- Check FKTABLE for removal of matched row
SELECT
    *
FROM
    FKTABLE;

-- Update a row from PK TABLE
UPDATE
    PKTABLE
SET
    ptest1 = 1
WHERE
    ptest1 = 2;

-- Check FKTABLE for update of matched row
SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

--
-- check set NULL and table constraint on multiple columns
--
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 text,
    PRIMARY KEY (ptest1, ptest2)
);

CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 int,
    ftest3 int,
    CONSTRAINT constrname FOREIGN KEY (ftest1, ftest2) REFERENCES PKTABLE MATCH FULL ON DELETE SET NULL ON UPDATE SET NULL
);

-- Test comments
COMMENT ON CONSTRAINT constrname_wrong ON FKTABLE IS 'fk constraint comment';

COMMENT ON CONSTRAINT constrname ON FKTABLE IS 'fk constraint comment';

COMMENT ON CONSTRAINT constrname ON FKTABLE IS NULL;

-- Insert test data into PKTABLE
INSERT INTO PKTABLE
    VALUES (1, 2, 'Test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 'Test1-2');

INSERT INTO PKTABLE
    VALUES (2, 4, 'Test2');

INSERT INTO PKTABLE
    VALUES (3, 6, 'Test3');

INSERT INTO PKTABLE
    VALUES (4, 8, 'Test4');

INSERT INTO PKTABLE
    VALUES (5, 10, 'Test5');

-- Insert successful rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (1, 2, 4);

INSERT INTO FKTABLE
    VALUES (1, 3, 5);

INSERT INTO FKTABLE
    VALUES (2, 4, 8);

INSERT INTO FKTABLE
    VALUES (3, 6, 12);

INSERT INTO FKTABLE
    VALUES (NULL, NULL, 0);

-- Insert failed rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (100, 2, 4);

INSERT INTO FKTABLE
    VALUES (2, 2, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 4);

INSERT INTO FKTABLE
    VALUES (1, NULL, 4);

-- Check FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Delete a row from PK TABLE
DELETE FROM PKTABLE
WHERE ptest1 = 1
    AND ptest2 = 2;

-- Check FKTABLE for removal of matched row
SELECT
    *
FROM
    FKTABLE;

-- Delete another row from PK TABLE
DELETE FROM PKTABLE
WHERE ptest1 = 5
    AND ptest2 = 10;

-- Check FKTABLE (should be no change)
SELECT
    *
FROM
    FKTABLE;

-- Update a row from PK TABLE
UPDATE
    PKTABLE
SET
    ptest1 = 1
WHERE
    ptest1 = 2;

-- Check FKTABLE for update of matched row
SELECT
    *
FROM
    FKTABLE;

-- Check update with part of key null
UPDATE
    FKTABLE
SET
    ftest1 = NULL
WHERE
    ftest1 = 1;

-- Check update with old and new key values equal
UPDATE
    FKTABLE
SET
    ftest1 = 1
WHERE
    ftest1 = 1;

-- Try altering the column type where foreign keys are involved
ALTER TABLE PKTABLE
    ALTER COLUMN ptest1 TYPE bigint;

ALTER TABLE FKTABLE
    ALTER COLUMN ftest1 TYPE bigint;

SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE PKTABLE CASCADE;

DROP TABLE FKTABLE;

--
-- check set default and table constraint on multiple columns
--
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 text,
    PRIMARY KEY (ptest1, ptest2)
);

CREATE TABLE FKTABLE (
    ftest1 int DEFAULT -1,
    ftest2 int DEFAULT -2,
    ftest3 int,
    CONSTRAINT constrname2 FOREIGN KEY (ftest1, ftest2) REFERENCES PKTABLE MATCH FULL ON DELETE SET DEFAULT ON UPDATE SET DEFAULT
);

-- Insert a value in PKTABLE for default
INSERT INTO PKTABLE
    VALUES (-1, -2, 'The Default!');

-- Insert test data into PKTABLE
INSERT INTO PKTABLE
    VALUES (1, 2, 'Test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 'Test1-2');

INSERT INTO PKTABLE
    VALUES (2, 4, 'Test2');

INSERT INTO PKTABLE
    VALUES (3, 6, 'Test3');

INSERT INTO PKTABLE
    VALUES (4, 8, 'Test4');

INSERT INTO PKTABLE
    VALUES (5, 10, 'Test5');

-- Insert successful rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (1, 2, 4);

INSERT INTO FKTABLE
    VALUES (1, 3, 5);

INSERT INTO FKTABLE
    VALUES (2, 4, 8);

INSERT INTO FKTABLE
    VALUES (3, 6, 12);

INSERT INTO FKTABLE
    VALUES (NULL, NULL, 0);

-- Insert failed rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (100, 2, 4);

INSERT INTO FKTABLE
    VALUES (2, 2, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 4);

INSERT INTO FKTABLE
    VALUES (1, NULL, 4);

-- Check FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Delete a row from PK TABLE
DELETE FROM PKTABLE
WHERE ptest1 = 1
    AND ptest2 = 2;

-- Check FKTABLE to check for removal
SELECT
    *
FROM
    FKTABLE;

-- Delete another row from PK TABLE
DELETE FROM PKTABLE
WHERE ptest1 = 5
    AND ptest2 = 10;

-- Check FKTABLE (should be no change)
SELECT
    *
FROM
    FKTABLE;

-- Update a row from PK TABLE
UPDATE
    PKTABLE
SET
    ptest1 = 1
WHERE
    ptest1 = 2;

-- Check FKTABLE for update of matched row
SELECT
    *
FROM
    FKTABLE;

-- this should fail for lack of CASCADE
DROP TABLE PKTABLE;

DROP TABLE PKTABLE CASCADE;

DROP TABLE FKTABLE;

--
-- First test, check with no on delete or on update
--
CREATE TABLE PKTABLE (
    ptest1 int PRIMARY KEY,
    ptest2 text
);

CREATE TABLE FKTABLE (
    ftest1 int REFERENCES PKTABLE MATCH FULL,
    ftest2 int
);

-- Insert test data into PKTABLE
INSERT INTO PKTABLE
    VALUES (1, 'Test1');

INSERT INTO PKTABLE
    VALUES (2, 'Test2');

INSERT INTO PKTABLE
    VALUES (3, 'Test3');

INSERT INTO PKTABLE
    VALUES (4, 'Test4');

INSERT INTO PKTABLE
    VALUES (5, 'Test5');

-- Insert successful rows into FK TABLE
INSERT INTO FKTABLE
    VALUES (1, 2);

INSERT INTO FKTABLE
    VALUES (2, 3);

INSERT INTO FKTABLE
    VALUES (3, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 1);

-- Insert a failed row into FK TABLE
INSERT INTO FKTABLE
    VALUES (100, 2);

-- Check FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Check PKTABLE
SELECT
    *
FROM
    PKTABLE;

-- Delete a row from PK TABLE (should fail)
DELETE FROM PKTABLE
WHERE ptest1 = 1;

-- Delete a row from PK TABLE (should succeed)
DELETE FROM PKTABLE
WHERE ptest1 = 5;

-- Check PKTABLE for deletes
SELECT
    *
FROM
    PKTABLE;

-- Update a row from PK TABLE (should fail)
UPDATE
    PKTABLE
SET
    ptest1 = 0
WHERE
    ptest1 = 2;

-- Update a row from PK TABLE (should succeed)
UPDATE
    PKTABLE
SET
    ptest1 = 0
WHERE
    ptest1 = 4;

-- Check PKTABLE for updates
SELECT
    *
FROM
    PKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

--
-- Check initial check upon ALTER TABLE
--
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    PRIMARY KEY (ptest1, ptest2)
);

CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 int
);

INSERT INTO PKTABLE
    VALUES (1, 2);

INSERT INTO FKTABLE
    VALUES (1, NULL);

ALTER TABLE FKTABLE
    ADD FOREIGN KEY (ftest1, ftest2) REFERENCES PKTABLE MATCH FULL;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- MATCH SIMPLE
-- Base test restricting update/delete
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 int,
    ptest4 text,
    PRIMARY KEY (ptest1, ptest2, ptest3)
);

CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 int,
    ftest3 int,
    ftest4 int,
    CONSTRAINT constrname3 FOREIGN KEY (ftest1, ftest2, ftest3) REFERENCES PKTABLE
);

-- Insert Primary Key values
INSERT INTO PKTABLE
    VALUES (1, 2, 3, 'test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 3, 'test2');

INSERT INTO PKTABLE
    VALUES (2, 3, 4, 'test3');

INSERT INTO PKTABLE
    VALUES (2, 4, 5, 'test4');

-- Insert Foreign Key values
INSERT INTO FKTABLE
    VALUES (1, 2, 3, 1);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 3, 2);

INSERT INTO FKTABLE
    VALUES (2, NULL, 3, 3);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 7, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 3, 4, 5);

-- Insert a failed values
INSERT INTO FKTABLE
    VALUES (1, 2, 7, 6);

-- Show FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Try to update something that should fail
UPDATE
    PKTABLE
SET
    ptest2 = 5
WHERE
    ptest2 = 2;

-- Try to update something that should succeed
UPDATE
    PKTABLE
SET
    ptest1 = 1
WHERE
    ptest2 = 3;

-- Try to delete something that should fail
DELETE FROM PKTABLE
WHERE ptest1 = 1
    AND ptest2 = 2
    AND ptest3 = 3;

-- Try to delete something that should work
DELETE FROM PKTABLE
WHERE ptest1 = 2;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- restrict with null values
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 int,
    ptest4 text,
    UNIQUE (ptest1, ptest2, ptest3)
);

CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 int,
    ftest3 int,
    ftest4 int,
    CONSTRAINT constrname3 FOREIGN KEY (ftest1, ftest2, ftest3) REFERENCES PKTABLE (ptest1, ptest2, ptest3)
);

INSERT INTO PKTABLE
    VALUES (1, 2, 3, 'test1');

INSERT INTO PKTABLE
    VALUES (1, 3, NULL, 'test2');

INSERT INTO PKTABLE
    VALUES (2, NULL, 4, 'test3');

INSERT INTO FKTABLE
    VALUES (1, 2, 3, 1);

DELETE FROM PKTABLE
WHERE ptest1 = 2;

SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- cascade update/delete
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 int,
    ptest4 text,
    PRIMARY KEY (ptest1, ptest2, ptest3)
);

CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 int,
    ftest3 int,
    ftest4 int,
    CONSTRAINT constrname3 FOREIGN KEY (ftest1, ftest2, ftest3) REFERENCES PKTABLE ON DELETE CASCADE ON UPDATE CASCADE
);

-- Insert Primary Key values
INSERT INTO PKTABLE
    VALUES (1, 2, 3, 'test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 3, 'test2');

INSERT INTO PKTABLE
    VALUES (2, 3, 4, 'test3');

INSERT INTO PKTABLE
    VALUES (2, 4, 5, 'test4');

-- Insert Foreign Key values
INSERT INTO FKTABLE
    VALUES (1, 2, 3, 1);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 3, 2);

INSERT INTO FKTABLE
    VALUES (2, NULL, 3, 3);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 7, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 3, 4, 5);

-- Insert a failed values
INSERT INTO FKTABLE
    VALUES (1, 2, 7, 6);

-- Show FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Try to update something that will cascade
UPDATE
    PKTABLE
SET
    ptest2 = 5
WHERE
    ptest2 = 2;

-- Try to update something that should not cascade
UPDATE
    PKTABLE
SET
    ptest1 = 1
WHERE
    ptest2 = 3;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should cascade
DELETE FROM PKTABLE
WHERE ptest1 = 1
    AND ptest2 = 5
    AND ptest3 = 3;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should not have a cascade
DELETE FROM PKTABLE
WHERE ptest1 = 2;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- set null update / set default delete
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 int,
    ptest4 text,
    PRIMARY KEY (ptest1, ptest2, ptest3)
);

CREATE TABLE FKTABLE (
    ftest1 int DEFAULT 0,
    ftest2 int,
    ftest3 int,
    ftest4 int,
    CONSTRAINT constrname3 FOREIGN KEY (ftest1, ftest2, ftest3) REFERENCES PKTABLE ON DELETE SET DEFAULT ON UPDATE SET NULL
);

-- Insert Primary Key values
INSERT INTO PKTABLE
    VALUES (1, 2, 3, 'test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 3, 'test2');

INSERT INTO PKTABLE
    VALUES (2, 3, 4, 'test3');

INSERT INTO PKTABLE
    VALUES (2, 4, 5, 'test4');

-- Insert Foreign Key values
INSERT INTO FKTABLE
    VALUES (1, 2, 3, 1);

INSERT INTO FKTABLE
    VALUES (2, 3, 4, 1);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 3, 2);

INSERT INTO FKTABLE
    VALUES (2, NULL, 3, 3);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 7, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 3, 4, 5);

-- Insert a failed values
INSERT INTO FKTABLE
    VALUES (1, 2, 7, 6);

-- Show FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Try to update something that will set null
UPDATE
    PKTABLE
SET
    ptest2 = 5
WHERE
    ptest2 = 2;

-- Try to update something that should not set null
UPDATE
    PKTABLE
SET
    ptest2 = 2
WHERE
    ptest2 = 3
    AND ptest1 = 1;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should set default
DELETE FROM PKTABLE
WHERE ptest1 = 2
    AND ptest2 = 3
    AND ptest3 = 4;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should not set default
DELETE FROM PKTABLE
WHERE ptest2 = 5;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- set default update / set null delete
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    ptest3 int,
    ptest4 text,
    PRIMARY KEY (ptest1, ptest2, ptest3)
);

CREATE TABLE FKTABLE (
    ftest1 int DEFAULT 0,
    ftest2 int DEFAULT -1,
    ftest3 int DEFAULT -2,
    ftest4 int,
    CONSTRAINT constrname3 FOREIGN KEY (ftest1, ftest2, ftest3) REFERENCES PKTABLE ON DELETE SET NULL ON UPDATE SET DEFAULT
);

-- Insert Primary Key values
INSERT INTO PKTABLE
    VALUES (1, 2, 3, 'test1');

INSERT INTO PKTABLE
    VALUES (1, 3, 3, 'test2');

INSERT INTO PKTABLE
    VALUES (2, 3, 4, 'test3');

INSERT INTO PKTABLE
    VALUES (2, 4, 5, 'test4');

INSERT INTO PKTABLE
    VALUES (2, -1, 5, 'test5');

-- Insert Foreign Key values
INSERT INTO FKTABLE
    VALUES (1, 2, 3, 1);

INSERT INTO FKTABLE
    VALUES (2, 3, 4, 1);

INSERT INTO FKTABLE
    VALUES (2, 4, 5, 1);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 3, 2);

INSERT INTO FKTABLE
    VALUES (2, NULL, 3, 3);

INSERT INTO FKTABLE
    VALUES (NULL, 2, 7, 4);

INSERT INTO FKTABLE
    VALUES (NULL, 3, 4, 5);

-- Insert a failed values
INSERT INTO FKTABLE
    VALUES (1, 2, 7, 6);

-- Show FKTABLE
SELECT
    *
FROM
    FKTABLE;

-- Try to update something that will fail
UPDATE
    PKTABLE
SET
    ptest2 = 5
WHERE
    ptest2 = 2;

-- Try to update something that will set default
UPDATE
    PKTABLE
SET
    ptest1 = 0,
    ptest2 = -1,
    ptest3 = -2
WHERE
    ptest2 = 2;

UPDATE
    PKTABLE
SET
    ptest2 = 10
WHERE
    ptest2 = 4;

-- Try to update something that should not set default
UPDATE
    PKTABLE
SET
    ptest2 = 2
WHERE
    ptest2 = 3
    AND ptest1 = 1;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should set null
DELETE FROM PKTABLE
WHERE ptest1 = 2
    AND ptest2 = 3
    AND ptest3 = 4;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

-- Try to delete something that should not set null
DELETE FROM PKTABLE
WHERE ptest2 = -1
    AND ptest3 = 5;

-- Show PKTABLE and FKTABLE
SELECT
    *
FROM
    PKTABLE;

SELECT
    *
FROM
    FKTABLE;

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

CREATE TABLE PKTABLE (
    ptest1 int PRIMARY KEY
);

CREATE TABLE FKTABLE_FAIL1 (
    ftest1 int,
    CONSTRAINT fkfail1 FOREIGN KEY (ftest2) REFERENCES PKTABLE
);

CREATE TABLE FKTABLE_FAIL2 (
    ftest1 int,
    CONSTRAINT fkfail1 FOREIGN KEY (ftest1) REFERENCES PKTABLE (ptest2)
);

DROP TABLE FKTABLE_FAIL1;

DROP TABLE FKTABLE_FAIL2;

DROP TABLE PKTABLE;

-- Test for referencing column number smaller than referenced constraint
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 int,
    UNIQUE (ptest1, ptest2)
);

CREATE TABLE FKTABLE_FAIL1 (
    ftest1 int REFERENCES pktable (ptest1)
);

DROP TABLE FKTABLE_FAIL1;

DROP TABLE PKTABLE;

--
-- Tests for mismatched types
--
-- Basic one column, two table setup
CREATE TABLE PKTABLE (
    ptest1 int PRIMARY KEY
);

INSERT INTO PKTABLE
    VALUES (42);

-- This next should fail, because int=inet does not exist
CREATE TABLE FKTABLE (
    ftest1 inet REFERENCES pktable
);

-- This should also fail for the same reason, but here we
-- give the column name
CREATE TABLE FKTABLE (
    ftest1 inet REFERENCES pktable (ptest1)
);

-- This should succeed, even though they are different types,
-- because int=int8 exists and is a member of the integer opfamily
CREATE TABLE FKTABLE (
    ftest1 int8 REFERENCES pktable
);

-- Check it actually works
INSERT INTO FKTABLE
    VALUES (42);

-- should succeed
INSERT INTO FKTABLE
    VALUES (43);

-- should fail
UPDATE
    FKTABLE
SET
    ftest1 = ftest1;

-- should succeed
UPDATE
    FKTABLE
SET
    ftest1 = ftest1 + 1;

-- should fail
DROP TABLE FKTABLE;

-- This should fail, because we'd have to cast numeric to int which is
-- not an implicit coercion (or use numeric=numeric, but that's not part
-- of the integer opfamily)
CREATE TABLE FKTABLE (
    ftest1 numeric REFERENCES pktable
);

DROP TABLE PKTABLE;

-- On the other hand, this should work because int implicitly promotes to
-- numeric, and we allow promotion on the FK side
CREATE TABLE PKTABLE (
    ptest1 numeric PRIMARY KEY
);

INSERT INTO PKTABLE
    VALUES (42);

CREATE TABLE FKTABLE (
    ftest1 int REFERENCES pktable
);

-- Check it actually works
INSERT INTO FKTABLE
    VALUES (42);

-- should succeed
INSERT INTO FKTABLE
    VALUES (43);

-- should fail
UPDATE
    FKTABLE
SET
    ftest1 = ftest1;

-- should succeed
UPDATE
    FKTABLE
SET
    ftest1 = ftest1 + 1;

-- should fail
DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- Two columns, two tables
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    PRIMARY KEY (ptest1, ptest2)
);

-- This should fail, because we just chose really odd types
CREATE TABLE FKTABLE (
    ftest1 cidr,
    ftest2 timestamp,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable
);

-- Again, so should this...
CREATE TABLE FKTABLE (
    ftest1 cidr,
    ftest2 timestamp,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest1, ptest2)
);

-- This fails because we mixed up the column ordering
CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest2, ftest1) REFERENCES pktable
);

-- As does this...
CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest2, ftest1) REFERENCES pktable (ptest1, ptest2)
);

-- And again..
CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest2, ptest1)
);

-- This works...
CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest2, ftest1) REFERENCES pktable (ptest2, ptest1)
);

DROP TABLE FKTABLE;

-- As does this
CREATE TABLE FKTABLE (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest1, ptest2)
);

DROP TABLE FKTABLE;

DROP TABLE PKTABLE;

-- Two columns, same table
-- Make sure this still works...
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    ptest3 int,
    ptest4 inet,
    PRIMARY KEY (ptest1, ptest2),
    FOREIGN KEY (ptest3, ptest4) REFERENCES pktable (ptest1, ptest2)
);

DROP TABLE PKTABLE;

-- And this,
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    ptest3 int,
    ptest4 inet,
    PRIMARY KEY (ptest1, ptest2),
    FOREIGN KEY (ptest3, ptest4) REFERENCES pktable
);

DROP TABLE PKTABLE;

-- This shouldn't (mixed up columns)
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    ptest3 int,
    ptest4 inet,
    PRIMARY KEY (ptest1, ptest2),
    FOREIGN KEY (ptest3, ptest4) REFERENCES pktable (ptest2, ptest1)
);

-- Nor should this... (same reason, we have 4,3 referencing 1,2 which mismatches types
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    ptest3 int,
    ptest4 inet,
    PRIMARY KEY (ptest1, ptest2),
    FOREIGN KEY (ptest4, ptest3) REFERENCES pktable (ptest1, ptest2)
);

-- Not this one either... Same as the last one except we didn't defined the columns being referenced.
CREATE TABLE PKTABLE (
    ptest1 int,
    ptest2 inet,
    ptest3 int,
    ptest4 inet,
    PRIMARY KEY (ptest1, ptest2),
    FOREIGN KEY (ptest4, ptest3) REFERENCES pktable
);

--
-- Now some cases with inheritance
-- Basic 2 table case: 1 column of matching types.
CREATE TABLE pktable_base (
    base1 int NOT NULL
);

CREATE TABLE pktable (
    ptest1 int,
    PRIMARY KEY (base1),
    UNIQUE (base1, ptest1)
)
INHERITS (
    pktable_base
);

CREATE TABLE fktable (
    ftest1 int REFERENCES pktable (base1)
);

-- now some ins, upd, del
INSERT INTO pktable (base1)
    VALUES (1);

INSERT INTO pktable (base1)
    VALUES (2);

--  let's insert a non-existent fktable value
INSERT INTO fktable (ftest1)
    VALUES (3);

--  let's make a valid row for that
INSERT INTO pktable (base1)
    VALUES (3);

INSERT INTO fktable (ftest1)
    VALUES (3);

-- let's try removing a row that should fail from pktable
DELETE FROM pktable
WHERE base1 > 2;

-- okay, let's try updating all of the base1 values to *4
-- which should fail.
UPDATE
    pktable
SET
    base1 = base1 * 4;

-- okay, let's try an update that should work.
UPDATE
    pktable
SET
    base1 = base1 * 4
WHERE
    base1 < 3;

-- and a delete that should work
DELETE FROM pktable
WHERE base1 > 3;

-- cleanup
DROP TABLE fktable;

DELETE FROM pktable;

-- Now 2 columns 2 tables, matching types
CREATE TABLE fktable (
    ftest1 int,
    ftest2 int,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (base1, ptest1)
);

-- now some ins, upd, del
INSERT INTO pktable (base1, ptest1)
    VALUES (1, 1);

INSERT INTO pktable (base1, ptest1)
    VALUES (2, 2);

--  let's insert a non-existent fktable value
INSERT INTO fktable (ftest1, ftest2)
    VALUES (3, 1);

--  let's make a valid row for that
INSERT INTO pktable (base1, ptest1)
    VALUES (3, 1);

INSERT INTO fktable (ftest1, ftest2)
    VALUES (3, 1);

-- let's try removing a row that should fail from pktable
DELETE FROM pktable
WHERE base1 > 2;

-- okay, let's try updating all of the base1 values to *4
-- which should fail.
UPDATE
    pktable
SET
    base1 = base1 * 4;

-- okay, let's try an update that should work.
UPDATE
    pktable
SET
    base1 = base1 * 4
WHERE
    base1 < 3;

-- and a delete that should work
DELETE FROM pktable
WHERE base1 > 3;

-- cleanup
DROP TABLE fktable;

DROP TABLE pktable;

DROP TABLE pktable_base;

-- Now we'll do one all in 1 table with 2 columns of matching types
CREATE TABLE pktable_base (
    base1 int NOT NULL,
    base2 int
);

CREATE TABLE pktable (
    ptest1 int,
    ptest2 int,
    PRIMARY KEY (base1, ptest1),
    FOREIGN KEY (base2, ptest2) REFERENCES pktable (base1, ptest1)
)
INHERITS (
    pktable_base
);

INSERT INTO pktable (base1, ptest1, base2, ptest2)
    VALUES (1, 1, 1, 1);

INSERT INTO pktable (base1, ptest1, base2, ptest2)
    VALUES (2, 1, 1, 1);

INSERT INTO pktable (base1, ptest1, base2, ptest2)
    VALUES (2, 2, 2, 1);

INSERT INTO pktable (base1, ptest1, base2, ptest2)
    VALUES (1, 3, 2, 2);

-- fails (3,2) isn't in base1, ptest1
INSERT INTO pktable (base1, ptest1, base2, ptest2)
    VALUES (2, 3, 3, 2);

-- fails (2,2) is being referenced
DELETE FROM pktable
WHERE base1 = 2;

-- fails (1,1) is being referenced (twice)
UPDATE
    pktable
SET
    base1 = 3
WHERE
    base1 = 1;

-- this sequence of two deletes will work, since after the first there will be no (2,*) references
DELETE FROM pktable
WHERE base2 = 2;

DELETE FROM pktable
WHERE base1 = 2;

DROP TABLE pktable;

DROP TABLE pktable_base;

-- 2 columns (2 tables), mismatched types
CREATE TABLE pktable_base (
    base1 int NOT NULL
);

CREATE TABLE pktable (
    ptest1 inet,
    PRIMARY KEY (base1, ptest1)
)
INHERITS (
    pktable_base
);

-- just generally bad types (with and without column references on the referenced table)
CREATE TABLE fktable (
    ftest1 cidr,
    ftest2 int[],
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable
);

CREATE TABLE fktable (
    ftest1 cidr,
    ftest2 int[],
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (base1, ptest1)
);

-- let's mix up which columns reference which
CREATE TABLE fktable (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest2, ftest1) REFERENCES pktable
);

CREATE TABLE fktable (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest2, ftest1) REFERENCES pktable (base1, ptest1)
);

CREATE TABLE fktable (
    ftest1 int,
    ftest2 inet,
    FOREIGN KEY (ftest1, ftest2) REFERENCES pktable (ptest1, base1)
);

DROP TABLE pktable;

DROP TABLE pktable_base;

-- 2 columns (1 table), mismatched types
CREATE TABLE pktable_base (
    base1 int NOT NULL,
    base2 int
);

CREATE TABLE pktable (
    ptest1 inet,
    ptest2 inet[],
    PRIMARY KEY (base1, ptest1),
    FOREIGN KEY (base2, ptest2) REFERENCES pktable (base1, ptest1)
)
INHERITS (
    pktable_base
);

CREATE TABLE pktable (
    ptest1 inet,
    ptest2 inet,
    PRIMARY KEY (base1, ptest1),
    FOREIGN KEY (base2, ptest2) REFERENCES pktable (ptest1, base1)
)
INHERITS (
    pktable_base
);

CREATE TABLE pktable (
    ptest1 inet,
    ptest2 inet,
    PRIMARY KEY (base1, ptest1),
    FOREIGN KEY (ptest2, base2) REFERENCES pktable (base1, ptest1)
)
INHERITS (
    pktable_base
);

CREATE TABLE pktable (
    ptest1 inet,
    ptest2 inet,
    PRIMARY KEY (base1, ptest1),
    FOREIGN KEY (ptest2, base2) REFERENCES pktable (base1, ptest1)
)
INHERITS (
    pktable_base
);

DROP TABLE pktable;

DROP TABLE pktable_base;

--
-- Deferrable constraints
--
-- deferrable, explicitly deferred
CREATE TABLE pktable (
    id int4 PRIMARY KEY,
    other int4
);

CREATE TABLE fktable (
    id int4 PRIMARY KEY,
    fk int4 REFERENCES pktable DEFERRABLE
);

-- default to immediate: should fail
INSERT INTO fktable
    VALUES (5, 10);

-- explicitly defer the constraint
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
INSERT INTO fktable
    VALUES (10, 15);
INSERT INTO pktable
    VALUES (15, 0);
-- make the FK insert valid
COMMIT;

DROP TABLE fktable, pktable;

-- deferrable, initially deferred
CREATE TABLE pktable (
    id int4 PRIMARY KEY,
    other int4
);

CREATE TABLE fktable (
    id int4 PRIMARY KEY,
    fk int4 REFERENCES pktable DEFERRABLE INITIALLY DEFERRED
);

-- default to deferred, should succeed
BEGIN;
INSERT INTO fktable
    VALUES (100, 200);
INSERT INTO pktable
    VALUES (200, 500);
-- make the FK insert valid
COMMIT;

-- default to deferred, explicitly make immediate
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;
-- should fail
INSERT INTO fktable
    VALUES (500, 1000);
COMMIT;

DROP TABLE fktable, pktable;

-- tricky behavior: according to SQL99, if a deferred constraint is set
-- to 'immediate' mode, it should be checked for validity *immediately*,
-- not when the current transaction commits (i.e. the mode change applies
-- retroactively)
CREATE TABLE pktable (
    id int4 PRIMARY KEY,
    other int4
);

CREATE TABLE fktable (
    id int4 PRIMARY KEY,
    fk int4 REFERENCES pktable DEFERRABLE
);

BEGIN;
SET CONSTRAINTS ALL DEFERRED;
-- should succeed, for now
INSERT INTO fktable
    VALUES (1000, 2000);
-- should cause transaction abort, due to preceding error
SET CONSTRAINTS ALL IMMEDIATE;
INSERT INTO pktable
    VALUES (2000, 3);
-- too late
COMMIT;

DROP TABLE fktable, pktable;

-- deferrable, initially deferred
CREATE TABLE pktable (
    id int4 PRIMARY KEY,
    other int4
);

CREATE TABLE fktable (
    id int4 PRIMARY KEY,
    fk int4 REFERENCES pktable DEFERRABLE INITIALLY DEFERRED
);

BEGIN;
-- no error here
INSERT INTO fktable
    VALUES (100, 200);
-- error here on commit
COMMIT;

DROP TABLE pktable, fktable;

-- test notice about expensive referential integrity checks,
-- where the index cannot be used because of type incompatibilities.
CREATE TEMP TABLE pktable (
    id1 int4 PRIMARY KEY,
    id2 varchar(4) UNIQUE,
    id3 real UNIQUE,
    UNIQUE (id1, id2, id3)
);

CREATE TEMP TABLE fktable (
    x1 int4 REFERENCES pktable (id1),
    x2 varchar(4) REFERENCES pktable (id2),
    x3 real REFERENCES pktable (id3),
    x4 text,
    x5 int2
);

-- check individual constraints with alter table.
-- should fail
-- varchar does not promote to real
ALTER TABLE fktable
    ADD CONSTRAINT fk_2_3 FOREIGN KEY (x2) REFERENCES pktable (id3);

-- nor to int4
ALTER TABLE fktable
    ADD CONSTRAINT fk_2_1 FOREIGN KEY (x2) REFERENCES pktable (id1);

-- real does not promote to int4
ALTER TABLE fktable
    ADD CONSTRAINT fk_3_1 FOREIGN KEY (x3) REFERENCES pktable (id1);

-- int4 does not promote to text
ALTER TABLE fktable
    ADD CONSTRAINT fk_1_2 FOREIGN KEY (x1) REFERENCES pktable (id2);

-- should succeed
-- int4 promotes to real
ALTER TABLE fktable
    ADD CONSTRAINT fk_1_3 FOREIGN KEY (x1) REFERENCES pktable (id3);

-- text is compatible with varchar
ALTER TABLE fktable
    ADD CONSTRAINT fk_4_2 FOREIGN KEY (x4) REFERENCES pktable (id2);

-- int2 is part of integer opfamily as of 8.0
ALTER TABLE fktable
    ADD CONSTRAINT fk_5_1 FOREIGN KEY (x5) REFERENCES pktable (id1);

-- check multikey cases, especially out-of-order column lists
-- these should work
ALTER TABLE fktable
    ADD CONSTRAINT fk_123_123 FOREIGN KEY (x1, x2, x3) REFERENCES pktable (id1, id2, id3);

ALTER TABLE fktable
    ADD CONSTRAINT fk_213_213 FOREIGN KEY (x2, x1, x3) REFERENCES pktable (id2, id1, id3);

ALTER TABLE fktable
    ADD CONSTRAINT fk_253_213 FOREIGN KEY (x2, x5, x3) REFERENCES pktable (id2, id1, id3);

-- these should fail
ALTER TABLE fktable
    ADD CONSTRAINT fk_123_231 FOREIGN KEY (x1, x2, x3) REFERENCES pktable (id2, id3, id1);

ALTER TABLE fktable
    ADD CONSTRAINT fk_241_132 FOREIGN KEY (x2, x4, x1) REFERENCES pktable (id1, id3, id2);

DROP TABLE pktable, fktable;

-- test a tricky case: we can elide firing the FK check trigger during
-- an UPDATE if the UPDATE did not change the foreign key
-- field. However, we can't do this if our transaction was the one that
-- created the updated row and the trigger is deferred, since our UPDATE
-- will have invalidated the original newly-inserted tuple, and therefore
-- cause the on-INSERT RI trigger not to be fired.
CREATE TEMP TABLE pktable (
    id int PRIMARY KEY,
    other int
);

CREATE TEMP TABLE fktable (
    id int PRIMARY KEY,
    fk int REFERENCES pktable DEFERRABLE INITIALLY DEFERRED
);

INSERT INTO pktable
    VALUES (5, 10);

BEGIN;
-- doesn't match PK, but no error yet
INSERT INTO fktable
    VALUES (0, 20);
-- don't change FK
UPDATE
    fktable
SET
    id = id + 1;
-- should catch error from initial INSERT
COMMIT;

-- check same case when insert is in a different subtransaction than update
BEGIN;
-- doesn't match PK, but no error yet
INSERT INTO fktable
    VALUES (0, 20);
-- UPDATE will be in a subxact
SAVEPOINT savept1;
-- don't change FK
UPDATE
    fktable
SET
    id = id + 1;
-- should catch error from initial INSERT
COMMIT;

BEGIN;
-- INSERT will be in a subxact
SAVEPOINT savept1;
-- doesn't match PK, but no error yet
INSERT INTO fktable
    VALUES (0, 20);
RELEASE SAVEPOINT savept1;
-- don't change FK
UPDATE
    fktable
SET
    id = id + 1;
-- should catch error from initial INSERT
COMMIT;

BEGIN;
-- doesn't match PK, but no error yet
INSERT INTO fktable
    VALUES (0, 20);
-- UPDATE will be in a subxact
SAVEPOINT savept1;
-- don't change FK
UPDATE
    fktable
SET
    id = id + 1;
-- Roll back the UPDATE
ROLLBACK TO savept1;

-- should catch error from initial INSERT
COMMIT;

--
-- check ALTER CONSTRAINT
--
INSERT INTO fktable
    VALUES (1, 5);

ALTER TABLE fktable
    ALTER CONSTRAINT fktable_fk_fkey DEFERRABLE INITIALLY IMMEDIATE;

BEGIN;
-- doesn't match FK, should throw error now
UPDATE
    pktable
SET
    id = 10
WHERE
    id = 5;
COMMIT;

BEGIN;
-- doesn't match PK, should throw error now
INSERT INTO fktable
    VALUES (0, 20);
COMMIT;

-- try additional syntax
ALTER TABLE fktable
    ALTER CONSTRAINT fktable_fk_fkey NOT DEFERRABLE;

-- illegal option
ALTER TABLE fktable
    ALTER CONSTRAINT fktable_fk_fkey NOT DEFERRABLE INITIALLY DEFERRED;

-- test order of firing of FK triggers when several RI-induced changes need to
-- be made to the same row.  This was broken by subtransaction-related
-- changes in 8.0.
CREATE TEMP TABLE users (
    id int PRIMARY KEY,
    name varchar NOT NULL
);

INSERT INTO users
    VALUES (1, 'Jozko');

INSERT INTO users
    VALUES (2, 'Ferko');

INSERT INTO users
    VALUES (3, 'Samko');

CREATE TEMP TABLE tasks (
    id int PRIMARY KEY,
    owner INT REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL,
    worker int REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL,
    checked_by int REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO tasks
    VALUES (1, 1, NULL, NULL);

INSERT INTO tasks
    VALUES (2, 2, 2, NULL);

INSERT INTO tasks
    VALUES (3, 3, 3, 3);

SELECT
    *
FROM
    tasks;

UPDATE
    users
SET
    id = 4
WHERE
    id = 3;

SELECT
    *
FROM
    tasks;

DELETE FROM users
WHERE id = 4;

SELECT
    *
FROM
    tasks;

-- could fail with only 2 changes to make, if row was already updated
BEGIN;
UPDATE
    tasks
SET
    id = id
WHERE
    id = 2;
SELECT
    *
FROM
    tasks;
DELETE FROM users
WHERE id = 2;
SELECT
    *
FROM
    tasks;
COMMIT;

--
-- Test self-referential FK with CASCADE (bug #6268)
--
CREATE temp TABLE selfref (
    a int PRIMARY KEY,
    b int,
    FOREIGN KEY (b) REFERENCES selfref (a) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO selfref (a, b)
VALUES
    (0, 0),
    (1, 1);

BEGIN;
UPDATE
    selfref
SET
    a = 123
WHERE
    a = 0;
SELECT
    a,
    b
FROM
    selfref;
UPDATE
    selfref
SET
    a = 456
WHERE
    a = 123;
SELECT
    a,
    b
FROM
    selfref;
COMMIT;

--
-- Test that SET DEFAULT actions recognize updates to default values
--
CREATE temp TABLE defp (
    f1 int PRIMARY KEY
);

CREATE temp TABLE defc (
    f1 int DEFAULT 0 REFERENCES defp ON DELETE SET DEFAULT
);

INSERT INTO defp
VALUES
    (0),
    (1),
    (2);

INSERT INTO defc
    VALUES (2);

SELECT
    *
FROM
    defc;

DELETE FROM defp
WHERE f1 = 2;

SELECT
    *
FROM
    defc;

DELETE FROM defp
WHERE f1 = 0;

-- fail
ALTER TABLE defc
    ALTER COLUMN f1 SET DEFAULT 1;

DELETE FROM defp
WHERE f1 = 0;

SELECT
    *
FROM
    defc;

DELETE FROM defp
WHERE f1 = 1;

-- fail
--
-- Test the difference between NO ACTION and RESTRICT
--
CREATE temp TABLE pp (
    f1 int PRIMARY KEY
);

CREATE temp TABLE cc (
    f1 int REFERENCES pp ON UPDATE NO action ON DELETE NO action
);

INSERT INTO pp
    VALUES (12);

INSERT INTO pp
    VALUES (11);

UPDATE
    pp
SET
    f1 = f1 + 1;

INSERT INTO cc
    VALUES (13);

UPDATE
    pp
SET
    f1 = f1 + 1;

UPDATE
    pp
SET
    f1 = f1 + 1;

-- fail
DELETE FROM pp
WHERE f1 = 13;

-- fail
DROP TABLE pp, cc;

CREATE temp TABLE pp (
    f1 int PRIMARY KEY
);

CREATE temp TABLE cc (
    f1 int REFERENCES pp ON UPDATE RESTRICT ON DELETE RESTRICT
);

INSERT INTO pp
    VALUES (12);

INSERT INTO pp
    VALUES (11);

UPDATE
    pp
SET
    f1 = f1 + 1;

INSERT INTO cc
    VALUES (13);

UPDATE
    pp
SET
    f1 = f1 + 1;

-- fail
DELETE FROM pp
WHERE f1 = 13;

-- fail
DROP TABLE pp, cc;

--
-- Test interaction of foreign-key optimization with rules (bug #14219)
--
CREATE temp TABLE t1 (
    a integer PRIMARY KEY,
    b text
);

CREATE temp TABLE t2 (
    a integer PRIMARY KEY,
    b integer REFERENCES t1
);

CREATE RULE r1 AS ON DELETE TO t1 DO DELETE FROM t2
WHERE t2.b = OLD.a;

EXPLAIN (
    COSTS OFF
) DELETE FROM t1
WHERE a = 1;

DELETE FROM t1
WHERE a = 1;

-- Test a primary key with attributes located in later attnum positions
-- compared to the fk attributes.
CREATE TABLE pktable2 (
    a int,
    b int,
    c int,
    d int,
    e int,
    PRIMARY KEY (d, e)
);

CREATE TABLE fktable2 (
    d int,
    e int,
    FOREIGN KEY (d, e) REFERENCES pktable2
);

INSERT INTO pktable2
    VALUES (1, 2, 3, 4, 5);

INSERT INTO fktable2
    VALUES (4, 5);

DELETE FROM pktable2;

UPDATE
    pktable2
SET
    d = 5;

DROP TABLE pktable2, fktable2;

-- Test truncation of long foreign key names
CREATE TABLE pktable1 (
    a int PRIMARY KEY
);

CREATE TABLE pktable2 (
    a int,
    b int,
    PRIMARY KEY (a, b)
);

CREATE TABLE fktable2 (
    a int,
    b int,
    very_very_long_column_name_to_exceed_63_characters int,
    FOREIGN KEY (very_very_long_column_name_to_exceed_63_characters) REFERENCES pktable1,
    FOREIGN KEY (a, very_very_long_column_name_to_exceed_63_characters) REFERENCES pktable2,
    FOREIGN KEY (a, very_very_long_column_name_to_exceed_63_characters) REFERENCES pktable2
);

SELECT
    conname
FROM
    pg_constraint
WHERE
    conrelid = 'fktable2'::regclass
ORDER BY
    conname;

DROP TABLE pktable1, pktable2, fktable2;

--
-- Test deferred FK check on a tuple deleted by a rolled-back subtransaction
--
CREATE TABLE pktable2 (
    f1 int PRIMARY KEY
);

CREATE TABLE fktable2 (
    f1 int REFERENCES pktable2 DEFERRABLE INITIALLY DEFERRED
);

INSERT INTO pktable2
    VALUES (1);

BEGIN;
INSERT INTO fktable2
    VALUES (1);
SAVEPOINT x;
DELETE FROM fktable2;
ROLLBACK TO x;

COMMIT;

BEGIN;
INSERT INTO fktable2
    VALUES (2);
SAVEPOINT x;
DELETE FROM fktable2;
ROLLBACK TO x;

COMMIT;

-- fail
--
-- Test that we prevent dropping FK constraint with pending trigger events
--
BEGIN;
INSERT INTO fktable2
    VALUES (2);
ALTER TABLE fktable2
    DROP CONSTRAINT fktable2_f1_fkey;
COMMIT;

BEGIN;
DELETE FROM pktable2
WHERE f1 = 1;
ALTER TABLE fktable2
    DROP CONSTRAINT fktable2_f1_fkey;
COMMIT;

DROP TABLE pktable2, fktable2;

--
-- Test keys that "look" different but compare as equal
--
CREATE TABLE pktable2 (
    a float8,
    b float8,
    PRIMARY KEY (a, b)
);

CREATE TABLE fktable2 (
    x float8,
    y float8,
    FOREIGN KEY (x, y) REFERENCES pktable2 (a, b) ON UPDATE CASCADE
);

INSERT INTO pktable2
    VALUES ('-0', '-0');

INSERT INTO fktable2
    VALUES ('-0', '-0');

SELECT
    *
FROM
    pktable2;

SELECT
    *
FROM
    fktable2;

UPDATE
    pktable2
SET
    a = '0'
WHERE
    a = '-0';

SELECT
    *
FROM
    pktable2;

-- should have updated fktable2.x
SELECT
    *
FROM
    fktable2;

DROP TABLE pktable2, fktable2;

--
-- Foreign keys and partitioned tables
--
-- Creation of a partitioned hierarchy with irregular definitions
CREATE TABLE fk_notpartitioned_pk (
    fdrop1 int,
    a int,
    fdrop2 int,
    b int,
    PRIMARY KEY (a, b)
);

ALTER TABLE fk_notpartitioned_pk
    DROP COLUMN fdrop1,
    DROP COLUMN fdrop2;

CREATE TABLE fk_partitioned_fk (
    b int,
    fdrop1 int,
    a int
)
PARTITION BY RANGE (a, b);

ALTER TABLE fk_partitioned_fk
    DROP COLUMN fdrop1;

CREATE TABLE fk_partitioned_fk_1 (
    fdrop1 int,
    fdrop2 int,
    a int,
    fdrop3 int,
    b int
);

ALTER TABLE fk_partitioned_fk_1
    DROP COLUMN fdrop1,
    DROP COLUMN fdrop2,
    DROP COLUMN fdrop3;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_1
FOR VALUES FROM (0, 0) TO (1000, 1000);

ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk;

CREATE TABLE fk_partitioned_fk_2 (
    b int,
    fdrop1 int,
    fdrop2 int,
    a int
);

ALTER TABLE fk_partitioned_fk_2
    DROP COLUMN fdrop1,
    DROP COLUMN fdrop2;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_2
FOR VALUES FROM (1000, 1000) TO (2000, 2000);

CREATE TABLE fk_partitioned_fk_3 (
    fdrop1 int,
    fdrop2 int,
    fdrop3 int,
    fdrop4 int,
    b int,
    a int
)
PARTITION BY HASH (a);

ALTER TABLE fk_partitioned_fk_3
    DROP COLUMN fdrop1,
    DROP COLUMN fdrop2,
    DROP COLUMN fdrop3,
    DROP COLUMN fdrop4;

CREATE TABLE fk_partitioned_fk_3_0 PARTITION OF fk_partitioned_fk_3
FOR VALUES WITH (MODULUS 5, REMAINDER 0);

CREATE TABLE fk_partitioned_fk_3_1 PARTITION OF fk_partitioned_fk_3
FOR VALUES WITH (MODULUS 5, REMAINDER 1);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_3
FOR VALUES FROM (2000, 2000) TO (3000, 3000);

-- Creating a foreign key with ONLY on a partitioned table referencing
-- a non-partitioned table fails.
ALTER TABLE ONLY fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk;

-- Adding a NOT VALID foreign key on a partitioned table referencing
-- a non-partitioned table fails.
ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk NOT VALID;

-- these inserts, targeting both the partition directly as well as the
-- partitioned table, should all fail
INSERT INTO fk_partitioned_fk (a, b)
    VALUES (500, 501);

INSERT INTO fk_partitioned_fk_1 (a, b)
    VALUES (500, 501);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (1500, 1501);

INSERT INTO fk_partitioned_fk_2 (a, b)
    VALUES (1500, 1501);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (2500, 2502);

INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2500, 2502);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (2501, 2503);

INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2501, 2503);

-- but if we insert the values that make them valid, then they work
INSERT INTO fk_notpartitioned_pk
VALUES
    (500, 501),
    (1500, 1501),
    (2500, 2502),
    (2501, 2503);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (500, 501);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (1500, 1501);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (2500, 2502);

INSERT INTO fk_partitioned_fk (a, b)
    VALUES (2501, 2503);

-- this update fails because there is no referenced row
UPDATE
    fk_partitioned_fk
SET
    a = a + 1
WHERE
    a = 2501;

-- but we can fix it thusly:
INSERT INTO fk_notpartitioned_pk (a, b)
    VALUES (2502, 2503);

UPDATE
    fk_partitioned_fk
SET
    a = a + 1
WHERE
    a = 2501;

-- these updates would leave lingering rows in the referencing table; disallow
UPDATE
    fk_notpartitioned_pk
SET
    b = 502
WHERE
    a = 500;

UPDATE
    fk_notpartitioned_pk
SET
    b = 1502
WHERE
    a = 1500;

UPDATE
    fk_notpartitioned_pk
SET
    b = 2504
WHERE
    a = 2500;

-- check psql behavior
\d fk_notpartitioned_pk
ALTER TABLE fk_partitioned_fk
    DROP CONSTRAINT fk_partitioned_fk_a_b_fkey;

-- done.
DROP TABLE fk_notpartitioned_pk, fk_partitioned_fk;

-- Altering a type referenced by a foreign key needs to drop/recreate the FK.
-- Ensure that works.
CREATE TABLE fk_notpartitioned_pk (
    a int,
    PRIMARY KEY (a),
    CHECK (a > 0)
);

CREATE TABLE fk_partitioned_fk (
    a int REFERENCES fk_notpartitioned_pk (a) PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE fk_partitioned_fk_1 PARTITION OF fk_partitioned_fk
FOR VALUES FROM (MINVALUE) TO (MAXVALUE);

INSERT INTO fk_notpartitioned_pk
    VALUES (1);

INSERT INTO fk_partitioned_fk
    VALUES (1);

ALTER TABLE fk_notpartitioned_pk
    ALTER COLUMN a TYPE bigint;

DELETE FROM fk_notpartitioned_pk
WHERE a = 1;

DROP TABLE fk_notpartitioned_pk, fk_partitioned_fk;

-- Test some other exotic foreign key features: MATCH SIMPLE, ON UPDATE/DELETE
-- actions
CREATE TABLE fk_notpartitioned_pk (
    a int,
    b int,
    PRIMARY KEY (a, b)
);

CREATE TABLE fk_partitioned_fk (
    a int DEFAULT 2501,
    b int DEFAULT 142857
)
PARTITION BY LIST (a);

CREATE TABLE fk_partitioned_fk_1 PARTITION OF fk_partitioned_fk
FOR VALUES IN (NULL, 500, 501, 502);

ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk MATCH SIMPLE ON DELETE SET NULL ON UPDATE SET NULL;

CREATE TABLE fk_partitioned_fk_2 PARTITION OF fk_partitioned_fk
FOR VALUES IN (1500, 1502);

CREATE TABLE fk_partitioned_fk_3 (
    a int,
    b int
);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_3
FOR VALUES IN (2500, 2501, 2502, 2503);

-- this insert fails
INSERT INTO fk_partitioned_fk (a, b)
    VALUES (2502, 2503);

INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2502, 2503);

-- but since the FK is MATCH SIMPLE, this one doesn't
INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2502, NULL);

-- now create the referenced row ...
INSERT INTO fk_notpartitioned_pk
    VALUES (2502, 2503);

--- and now the same insert work
INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2502, 2503);

-- this always works
INSERT INTO fk_partitioned_fk (a, b)
    VALUES (NULL, NULL);

-- MATCH FULL
INSERT INTO fk_notpartitioned_pk
    VALUES (1, 2);

CREATE TABLE fk_partitioned_fk_full (
    x int,
    y int
)
PARTITION BY RANGE (x);

CREATE TABLE fk_partitioned_fk_full_1 PARTITION OF fk_partitioned_fk_full DEFAULT;

INSERT INTO fk_partitioned_fk_full
    VALUES (1, NULL);

ALTER TABLE fk_partitioned_fk_full
    ADD FOREIGN KEY (x, y) REFERENCES fk_notpartitioned_pk MATCH FULL;

-- fails
TRUNCATE fk_partitioned_fk_full;

ALTER TABLE fk_partitioned_fk_full
    ADD FOREIGN KEY (x, y) REFERENCES fk_notpartitioned_pk MATCH FULL;

INSERT INTO fk_partitioned_fk_full
    VALUES (1, NULL);

-- fails
DROP TABLE fk_partitioned_fk_full;

-- ON UPDATE SET NULL
SELECT
    tableoid::regclass,
    a,
    b
FROM
    fk_partitioned_fk
WHERE
    b IS NULL
ORDER BY
    a;

UPDATE
    fk_notpartitioned_pk
SET
    a = a + 1
WHERE
    a = 2502;

SELECT
    tableoid::regclass,
    a,
    b
FROM
    fk_partitioned_fk
WHERE
    b IS NULL
ORDER BY
    a;

-- ON DELETE SET NULL
INSERT INTO fk_partitioned_fk
    VALUES (2503, 2503);

SELECT
    count(*)
FROM
    fk_partitioned_fk
WHERE
    a IS NULL;

DELETE FROM fk_notpartitioned_pk;

SELECT
    count(*)
FROM
    fk_partitioned_fk
WHERE
    a IS NULL;

-- ON UPDATE/DELETE SET DEFAULT
ALTER TABLE fk_partitioned_fk
    DROP CONSTRAINT fk_partitioned_fk_a_b_fkey;

ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk ON DELETE SET DEFAULT ON UPDATE SET DEFAULT;

INSERT INTO fk_notpartitioned_pk
    VALUES (2502, 2503);

INSERT INTO fk_partitioned_fk_3 (a, b)
    VALUES (2502, 2503);

-- this fails, because the defaults for the referencing table are not present
-- in the referenced table:
UPDATE
    fk_notpartitioned_pk
SET
    a = 1500
WHERE
    a = 2502;

-- but inserting the row we can make it work:
INSERT INTO fk_notpartitioned_pk
    VALUES (2501, 142857);

UPDATE
    fk_notpartitioned_pk
SET
    a = 1500
WHERE
    a = 2502;

SELECT
    *
FROM
    fk_partitioned_fk
WHERE
    b = 142857;

-- ON UPDATE/DELETE CASCADE
ALTER TABLE fk_partitioned_fk
    DROP CONSTRAINT fk_partitioned_fk_a_b_fkey;

ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk ON DELETE CASCADE ON UPDATE CASCADE;

UPDATE
    fk_notpartitioned_pk
SET
    a = 2502
WHERE
    a = 2501;

SELECT
    *
FROM
    fk_partitioned_fk
WHERE
    b = 142857;

-- Now you see it ...
SELECT
    *
FROM
    fk_partitioned_fk
WHERE
    b = 142857;

DELETE FROM fk_notpartitioned_pk
WHERE b = 142857;

-- now you don't.
SELECT
    *
FROM
    fk_partitioned_fk
WHERE
    a = 142857;

-- verify that DROP works
DROP TABLE fk_partitioned_fk_2;

-- Test behavior of the constraint together with attaching and detaching
-- partitions.
CREATE TABLE fk_partitioned_fk_2 PARTITION OF fk_partitioned_fk
FOR VALUES IN (1500, 1502);

ALTER TABLE fk_partitioned_fk DETACH PARTITION fk_partitioned_fk_2;

BEGIN;
DROP TABLE fk_partitioned_fk;
-- constraint should still be there
\d fk_partitioned_fk_2;
ROLLBACK;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_2
FOR VALUES IN (1500, 1502);

DROP TABLE fk_partitioned_fk_2;

CREATE TABLE fk_partitioned_fk_2 (
    b int,
    c text,
    a int,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk ON UPDATE CASCADE ON DELETE CASCADE
);

ALTER TABLE fk_partitioned_fk_2
    DROP COLUMN c;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_2
FOR VALUES IN (1500, 1502);

-- should have only one constraint
\d fk_partitioned_fk_2
DROP TABLE fk_partitioned_fk_2;

CREATE TABLE fk_partitioned_fk_4 (
    a int,
    b int,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b) ON UPDATE CASCADE ON DELETE CASCADE
)
PARTITION BY RANGE (b, a);

CREATE TABLE fk_partitioned_fk_4_1 PARTITION OF fk_partitioned_fk_4
FOR VALUES FROM (1, 1) TO (100, 100);

CREATE TABLE fk_partitioned_fk_4_2 (
    a int,
    b int,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b) ON UPDATE SET NULL
);

ALTER TABLE fk_partitioned_fk_4 ATTACH PARTITION fk_partitioned_fk_4_2
FOR VALUES FROM (100, 100) TO (1000, 1000);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_4
FOR VALUES IN (3500, 3502);

ALTER TABLE fk_partitioned_fk DETACH PARTITION fk_partitioned_fk_4;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_4
FOR VALUES IN (3500, 3502);

-- should only have one constraint
\d fk_partitioned_fk_4
\d fk_partitioned_fk_4_1
-- this one has an FK with mismatched properties
\d fk_partitioned_fk_4_2
CREATE TABLE fk_partitioned_fk_5 (
    a int,
    b int,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
)
PARTITION BY RANGE (a);

CREATE TABLE fk_partitioned_fk_5_1 (
    a int,
    b int,
    FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk
);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_5
FOR VALUES IN (4500);

ALTER TABLE fk_partitioned_fk_5 ATTACH PARTITION fk_partitioned_fk_5_1
FOR VALUES FROM (0) TO (10);

ALTER TABLE fk_partitioned_fk DETACH PARTITION fk_partitioned_fk_5;

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_5
FOR VALUES IN (4500);

-- this one has two constraints, similar but not quite the one in the parent,
-- so it gets a new one
\d fk_partitioned_fk_5
-- verify that it works to reattaching a child with multiple candidate
-- constraints
ALTER TABLE fk_partitioned_fk_5 DETACH PARTITION fk_partitioned_fk_5_1;

ALTER TABLE fk_partitioned_fk_5 ATTACH PARTITION fk_partitioned_fk_5_1
FOR VALUES FROM (0) TO (10);

\d fk_partitioned_fk_5_1
-- verify that attaching a table checks that the existing data satisfies the
-- constraint
CREATE TABLE fk_partitioned_fk_2 (
    a int,
    b int
)
PARTITION BY RANGE (b);

CREATE TABLE fk_partitioned_fk_2_1 PARTITION OF fk_partitioned_fk_2
FOR VALUES FROM (0) TO (1000);

CREATE TABLE fk_partitioned_fk_2_2 PARTITION OF fk_partitioned_fk_2
FOR VALUES FROM (1000) TO (2000);

INSERT INTO fk_partitioned_fk_2
VALUES
    (1600, 601),
    (1600, 1601);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_2
FOR VALUES IN (1600);

INSERT INTO fk_notpartitioned_pk
VALUES
    (1600, 601),
    (1600, 1601);

ALTER TABLE fk_partitioned_fk ATTACH PARTITION fk_partitioned_fk_2
FOR VALUES IN (1600);

-- leave these tables around intentionally
-- test the case when the referenced table is owned by a different user
CREATE ROLE regress_other_partitioned_fk_owner;

GRANT REFERENCES ON fk_notpartitioned_pk TO regress_other_partitioned_fk_owner;

SET ROLE regress_other_partitioned_fk_owner;

CREATE TABLE other_partitioned_fk (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE other_partitioned_fk_1 PARTITION OF other_partitioned_fk
FOR VALUES IN (2048);

INSERT INTO other_partitioned_fk
SELECT
    2048,
    x
FROM
    generate_series(1, 10) x;

-- this should fail
ALTER TABLE other_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b);

-- add the missing keys and retry
RESET ROLE;

INSERT INTO fk_notpartitioned_pk (a, b)
SELECT
    2048,
    x
FROM
    generate_series(1, 10) x;

SET ROLE regress_other_partitioned_fk_owner;

ALTER TABLE other_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk (a, b);

-- clean up
DROP TABLE other_partitioned_fk;

RESET ROLE;

REVOKE ALL ON fk_notpartitioned_pk FROM regress_other_partitioned_fk_owner;

DROP ROLE regress_other_partitioned_fk_owner;

-- Test creating a constraint at the parent that already exists in partitions.
-- There should be no duplicated constraints, and attempts to drop the
-- constraint in partitions should raise appropriate errors.
CREATE SCHEMA fkpart0
    CREATE TABLE pkey (
        a int PRIMARY KEY)
    CREATE TABLE fk_part (
        a int
)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_1 PARTITION OF fk_part (FOREIGN KEY (a) REFERENCES fkpart0.pkey)
FOR VALUES IN (1)
    CREATE TABLE fk_part_23 PARTITION OF fk_part (FOREIGN KEY (a) REFERENCES fkpart0.pkey)
FOR VALUES IN (2, 3)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_23_2 PARTITION OF fk_part_23
FOR VALUES IN (2);

ALTER TABLE fkpart0.fk_part
    ADD FOREIGN KEY (a) REFERENCES fkpart0.pkey;

\d fkpart0.fk_part_1	\\ -- should have only one FK
ALTER TABLE fkpart0.fk_part_1
    DROP CONSTRAINT fk_part_1_a_fkey;

\d fkpart0.fk_part_23	\\ -- should have only one FK
\d fkpart0.fk_part_23_2	\\ -- should have only one FK
ALTER TABLE fkpart0.fk_part_23
    DROP CONSTRAINT fk_part_23_a_fkey;

ALTER TABLE fkpart0.fk_part_23_2
    DROP CONSTRAINT fk_part_23_a_fkey;

CREATE TABLE fkpart0.fk_part_4 PARTITION OF fkpart0.fk_part
FOR VALUES IN (4);

\d fkpart0.fk_part_4
ALTER TABLE fkpart0.fk_part_4
    DROP CONSTRAINT fk_part_a_fkey;

CREATE TABLE fkpart0.fk_part_56 PARTITION OF fkpart0.fk_part
FOR VALUES IN (5, 6)
PARTITION BY LIST (a);

CREATE TABLE fkpart0.fk_part_56_5 PARTITION OF fkpart0.fk_part_56
FOR VALUES IN (5);

\d fkpart0.fk_part_56
ALTER TABLE fkpart0.fk_part_56
    DROP CONSTRAINT fk_part_a_fkey;

ALTER TABLE fkpart0.fk_part_56_5
    DROP CONSTRAINT fk_part_a_fkey;

-- verify that attaching and detaching partitions maintains the right set of
-- triggers
CREATE SCHEMA fkpart1
    CREATE TABLE pkey (
        a int PRIMARY KEY)
    CREATE TABLE fk_part (
        a int
)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_1 PARTITION OF fk_part
FOR VALUES IN (1)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_1_1 PARTITION OF fk_part_1
FOR VALUES IN (1);

ALTER TABLE fkpart1.fk_part
    ADD FOREIGN KEY (a) REFERENCES fkpart1.pkey;

INSERT INTO fkpart1.fk_part
    VALUES (1);

-- should fail
INSERT INTO fkpart1.pkey
    VALUES (1);

INSERT INTO fkpart1.fk_part
    VALUES (1);

DELETE FROM fkpart1.pkey
WHERE a = 1;

-- should fail
ALTER TABLE fkpart1.fk_part DETACH PARTITION fkpart1.fk_part_1;

CREATE TABLE fkpart1.fk_part_1_2 PARTITION OF fkpart1.fk_part_1
FOR VALUES IN (2);

INSERT INTO fkpart1.fk_part_1
    VALUES (2);

-- should fail
DELETE FROM fkpart1.pkey
WHERE a = 1;

-- verify that attaching and detaching partitions manipulates the inheritance
-- properties of their FK constraints correctly
CREATE SCHEMA fkpart2
    CREATE TABLE pkey (
        a int PRIMARY KEY)
    CREATE TABLE fk_part (
        a int,
        CONSTRAINT fkey FOREIGN KEY (a) REFERENCES fkpart2.pkey
)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_1 PARTITION OF fkpart2.fk_part
FOR VALUES IN (1)
PARTITION BY LIST (a)
    CREATE TABLE fk_part_1_1 (a int, CONSTRAINT my_fkey FOREIGN KEY (a) REFERENCES fkpart2.pkey);

ALTER TABLE fkpart2.fk_part_1 ATTACH PARTITION fkpart2.fk_part_1_1
FOR VALUES IN (1);

ALTER TABLE fkpart2.fk_part_1
    DROP CONSTRAINT fkey;

-- should fail
ALTER TABLE fkpart2.fk_part_1_1
    DROP CONSTRAINT my_fkey;

-- should fail
ALTER TABLE fkpart2.fk_part DETACH PARTITION fkpart2.fk_part_1;

ALTER TABLE fkpart2.fk_part_1
    DROP CONSTRAINT fkey;

-- ok
ALTER TABLE fkpart2.fk_part_1_1
    DROP CONSTRAINT my_fkey;

-- doesn't exist
DROP SCHEMA fkpart0, fkpart1, fkpart2 CASCADE;

-- Test a partitioned table as referenced table.
-- Verify basic functionality with a regular partition creation and a partition
-- with a different column layout, as well as partitions added (created and
-- attached) after creating the foreign key.
CREATE SCHEMA fkpart3;

SET search_path TO fkpart3;

CREATE TABLE pk (
    a int PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE pk1 PARTITION OF pk
FOR VALUES FROM (0) TO (1000);

CREATE TABLE pk2 (
    b int,
    a int
);

ALTER TABLE pk2
    DROP COLUMN b;

ALTER TABLE pk2
    ALTER a SET NOT NULL;

ALTER TABLE pk ATTACH PARTITION pk2
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE fk (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES FROM (0) TO (750);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk;

CREATE TABLE fk2 (
    b int,
    a int
);

ALTER TABLE fk2
    DROP COLUMN b;

ALTER TABLE fk ATTACH PARTITION fk2
FOR VALUES FROM (750) TO (3500);

CREATE TABLE pk3 PARTITION OF pk
FOR VALUES FROM (2000) TO (3000);

CREATE TABLE pk4 (
    LIKE pk
);

ALTER TABLE pk ATTACH PARTITION pk4
FOR VALUES FROM (3000) TO (4000);

CREATE TABLE pk5 (
    c int,
    b int,
    a int NOT NULL
)
PARTITION BY RANGE (a);

ALTER TABLE pk5
    DROP COLUMN b,
    DROP COLUMN c;

CREATE TABLE pk51 PARTITION OF pk5
FOR VALUES FROM (4000) TO (4500);

CREATE TABLE pk52 PARTITION OF pk5
FOR VALUES FROM (4500) TO (5000);

ALTER TABLE pk ATTACH PARTITION pk5
FOR VALUES FROM (4000) TO (5000);

CREATE TABLE fk3 PARTITION OF fk
FOR VALUES FROM (3500) TO (5000);

-- these should fail: referenced value not present
INSERT INTO fk
    VALUES (1);

INSERT INTO fk
    VALUES (1000);

INSERT INTO fk
    VALUES (2000);

INSERT INTO fk
    VALUES (3000);

INSERT INTO fk
    VALUES (4000);

INSERT INTO fk
    VALUES (4500);

-- insert into the referenced table, now they should work
INSERT INTO pk
VALUES
    (1),
    (1000),
    (2000),
    (3000),
    (4000),
    (4500);

INSERT INTO fk
VALUES
    (1),
    (1000),
    (2000),
    (3000),
    (4000),
    (4500);

-- should fail: referencing value present
DELETE FROM pk
WHERE a = 1;

DELETE FROM pk
WHERE a = 1000;

DELETE FROM pk
WHERE a = 2000;

DELETE FROM pk
WHERE a = 3000;

DELETE FROM pk
WHERE a = 4000;

DELETE FROM pk
WHERE a = 4500;

UPDATE
    pk
SET
    a = 2
WHERE
    a = 1;

UPDATE
    pk
SET
    a = 1002
WHERE
    a = 1000;

UPDATE
    pk
SET
    a = 2002
WHERE
    a = 2000;

UPDATE
    pk
SET
    a = 3002
WHERE
    a = 3000;

UPDATE
    pk
SET
    a = 4002
WHERE
    a = 4000;

UPDATE
    pk
SET
    a = 4502
WHERE
    a = 4500;

-- now they should work
DELETE FROM fk;

UPDATE
    pk
SET
    a = 2
WHERE
    a = 1;

DELETE FROM pk
WHERE a = 2;

UPDATE
    pk
SET
    a = 1002
WHERE
    a = 1000;

DELETE FROM pk
WHERE a = 1002;

UPDATE
    pk
SET
    a = 2002
WHERE
    a = 2000;

DELETE FROM pk
WHERE a = 2002;

UPDATE
    pk
SET
    a = 3002
WHERE
    a = 3000;

DELETE FROM pk
WHERE a = 3002;

UPDATE
    pk
SET
    a = 4002
WHERE
    a = 4000;

DELETE FROM pk
WHERE a = 4002;

UPDATE
    pk
SET
    a = 4502
WHERE
    a = 4500;

DELETE FROM pk
WHERE a = 4502;

CREATE SCHEMA fkpart4;

SET search_path TO fkpart4;

-- dropping/detaching PARTITIONs is prevented if that would break
-- a foreign key's existing data
CREATE TABLE droppk (
    a int PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE droppk1 PARTITION OF droppk
FOR VALUES FROM (0) TO (1000);

CREATE TABLE droppk_d PARTITION OF droppk DEFAULT;

CREATE TABLE droppk2 PARTITION OF droppk
FOR VALUES FROM (1000) TO (2000)
PARTITION BY RANGE (a);

CREATE TABLE droppk21 PARTITION OF droppk2
FOR VALUES FROM (1000) TO (1400);

CREATE TABLE droppk2_d PARTITION OF droppk2 DEFAULT;

INSERT INTO droppk
VALUES
    (1),
    (1000),
    (1500),
    (2000);

CREATE TABLE dropfk (
    a int REFERENCES droppk
);

INSERT INTO dropfk
VALUES
    (1),
    (1000),
    (1500),
    (2000);

-- these should all fail
ALTER TABLE droppk DETACH PARTITION droppk_d;

ALTER TABLE droppk2 DETACH PARTITION droppk2_d;

ALTER TABLE droppk DETACH PARTITION droppk1;

ALTER TABLE droppk DETACH PARTITION droppk2;

ALTER TABLE droppk2 DETACH PARTITION droppk21;

-- dropping partitions is disallowed
DROP TABLE droppk_d;

DROP TABLE droppk2_d;

DROP TABLE droppk1;

DROP TABLE droppk2;

DROP TABLE droppk21;

DELETE FROM dropfk;

-- dropping partitions is disallowed, even when no referencing values
DROP TABLE droppk_d;

DROP TABLE droppk2_d;

DROP TABLE droppk1;

-- but DETACH is allowed, and DROP afterwards works
ALTER TABLE droppk2 DETACH PARTITION droppk21;

DROP TABLE droppk2;

-- Verify that initial constraint creation and cloning behave correctly
CREATE SCHEMA fkpart5;

SET search_path TO fkpart5;

CREATE TABLE pk (
    a int PRIMARY KEY
)
PARTITION BY LIST (a);

CREATE TABLE pk1 PARTITION OF pk
FOR VALUES IN (1)
PARTITION BY LIST (a);

CREATE TABLE pk11 PARTITION OF pk1
FOR VALUES IN (1);

CREATE TABLE fk (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES IN (1)
PARTITION BY LIST (a);

CREATE TABLE fk11 PARTITION OF fk1
FOR VALUES IN (1);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk;

CREATE TABLE pk2 PARTITION OF pk
FOR VALUES IN (2);

CREATE TABLE pk3 (
    a int NOT NULL
)
PARTITION BY LIST (a);

CREATE TABLE pk31 PARTITION OF pk3
FOR VALUES IN (31);

CREATE TABLE pk32 (
    b int,
    a int NOT NULL
);

ALTER TABLE pk32
    DROP COLUMN b;

ALTER TABLE pk3 ATTACH PARTITION pk32
FOR VALUES IN (32);

ALTER TABLE pk ATTACH PARTITION pk3
FOR VALUES IN (31, 32);

CREATE TABLE fk2 PARTITION OF fk
FOR VALUES IN (2);

CREATE TABLE fk3 (
    b int,
    a int
);

ALTER TABLE fk3
    DROP COLUMN b;

ALTER TABLE fk ATTACH PARTITION fk3
FOR VALUES IN (3);

SELECT
    pg_describe_object('pg_constraint'::regclass, oid, 0),
    confrelid::regclass,
    CASE WHEN conparentid <> 0 THEN
        pg_describe_object('pg_constraint'::regclass, conparentid, 0)
    ELSE
        'TOP'
    END
FROM
    pg_catalog.pg_constraint
WHERE
    conrelid IN (
        SELECT
            relid
        FROM
            pg_partition_tree ('fk'))
ORDER BY
    conrelid::regclass::text,
    conname;

CREATE TABLE fk4 (
    LIKE fk
);

INSERT INTO fk4
    VALUES (50);

ALTER TABLE fk ATTACH PARTITION fk4
FOR VALUES IN (50);

-- Verify ON UPDATE/DELETE behavior
CREATE SCHEMA fkpart6;

SET search_path TO fkpart6;

CREATE TABLE pk (
    a int PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE pk1 PARTITION OF pk
FOR VALUES FROM (1) TO (100)
PARTITION BY RANGE (a);

CREATE TABLE pk11 PARTITION OF pk1
FOR VALUES FROM (1) TO (50);

CREATE TABLE pk12 PARTITION OF pk1
FOR VALUES FROM (50) TO (100);

CREATE TABLE fk (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES FROM (1) TO (100)
PARTITION BY RANGE (a);

CREATE TABLE fk11 PARTITION OF fk1
FOR VALUES FROM (1) TO (10);

CREATE TABLE fk12 PARTITION OF fk1
FOR VALUES FROM (10) TO (100);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE fk_d PARTITION OF fk DEFAULT;

INSERT INTO pk
    VALUES (1);

INSERT INTO fk
    VALUES (1);

UPDATE
    pk
SET
    a = 20;

SELECT
    tableoid::regclass,
    *
FROM
    fk;

DELETE FROM pk
WHERE a = 20;

SELECT
    tableoid::regclass,
    *
FROM
    fk;

DROP TABLE fk;

TRUNCATE TABLE pk;

INSERT INTO pk
VALUES
    (20),
    (50);

CREATE TABLE fk (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES FROM (1) TO (100)
PARTITION BY RANGE (a);

CREATE TABLE fk11 PARTITION OF fk1
FOR VALUES FROM (1) TO (10);

CREATE TABLE fk12 PARTITION OF fk1
FOR VALUES FROM (10) TO (100);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk ON UPDATE SET NULL ON DELETE SET NULL;

CREATE TABLE fk_d PARTITION OF fk DEFAULT;

INSERT INTO fk
VALUES
    (20),
    (50);

UPDATE
    pk
SET
    a = 21
WHERE
    a = 20;

DELETE FROM pk
WHERE a = 50;

SELECT
    tableoid::regclass,
    *
FROM
    fk;

DROP TABLE fk;

TRUNCATE TABLE pk;

INSERT INTO pk
VALUES
    (20),
    (30),
    (50);

CREATE TABLE fk (
    id int,
    a int DEFAULT 50
)
PARTITION BY RANGE (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES FROM (1) TO (100)
PARTITION BY RANGE (a);

CREATE TABLE fk11 PARTITION OF fk1
FOR VALUES FROM (1) TO (10);

CREATE TABLE fk12 PARTITION OF fk1
FOR VALUES FROM (10) TO (100);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk ON UPDATE SET DEFAULT ON DELETE SET DEFAULT;

CREATE TABLE fk_d PARTITION OF fk DEFAULT;

INSERT INTO fk
VALUES
    (1, 20),
    (2, 30);

DELETE FROM pk
WHERE a = 20
RETURNING
    *;

UPDATE
    pk
SET
    a = 90
WHERE
    a = 30
RETURNING
    *;

SELECT
    tableoid::regclass,
    *
FROM
    fk;

DROP TABLE fk;

TRUNCATE TABLE pk;

INSERT INTO pk
VALUES
    (20),
    (30);

CREATE TABLE fk (
    a int DEFAULT 50
)
PARTITION BY RANGE (a);

CREATE TABLE fk1 PARTITION OF fk
FOR VALUES FROM (1) TO (100)
PARTITION BY RANGE (a);

CREATE TABLE fk11 PARTITION OF fk1
FOR VALUES FROM (1) TO (10);

CREATE TABLE fk12 PARTITION OF fk1
FOR VALUES FROM (10) TO (100);

ALTER TABLE fk
    ADD FOREIGN KEY (a) REFERENCES pk ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE TABLE fk_d PARTITION OF fk DEFAULT;

INSERT INTO fk
VALUES
    (20),
    (30);

DELETE FROM pk
WHERE a = 20;

UPDATE
    pk
SET
    a = 90
WHERE
    a = 30;

SELECT
    tableoid::regclass,
    *
FROM
    fk;

DROP TABLE fk;

-- test for reported bug: relispartition not set
-- https://postgr.es/m/CA+HiwqHMsRtRYRWYTWavKJ8x14AFsv7bmAV46mYwnfD3vy8goQ@mail.gmail.com
CREATE SCHEMA fkpart7
    CREATE TABLE pkpart (
        a int
)
PARTITION BY LIST (a)
    CREATE TABLE pkpart1 PARTITION OF pkpart
FOR VALUES IN (1);

ALTER TABLE fkpart7.pkpart1
    ADD PRIMARY KEY (a);

ALTER TABLE fkpart7.pkpart
    ADD PRIMARY KEY (a);

CREATE TABLE fkpart7.fk (
    a int REFERENCES fkpart7.pkpart
);

DROP SCHEMA fkpart7 CASCADE;

