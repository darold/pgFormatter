--
-- TEMP
-- Test temp relations and indexes
--
-- test temp table/index masking
CREATE TABLE temptest (
    col int
);

CREATE INDEX i_temptest ON temptest (col);

CREATE TEMP TABLE temptest (
    tcol int
);

CREATE INDEX i_temptest ON temptest (tcol);

SELECT
    *
FROM
    temptest;

DROP INDEX i_temptest;

DROP TABLE temptest;

SELECT
    *
FROM
    temptest;

DROP INDEX i_temptest;

DROP TABLE temptest;

-- test temp table selects
CREATE TABLE temptest (
    col int
);

INSERT INTO temptest
    VALUES (1);

CREATE TEMP TABLE temptest (
    tcol float
);

INSERT INTO temptest
    VALUES (2.1);

SELECT
    *
FROM
    temptest;

DROP TABLE temptest;

SELECT
    *
FROM
    temptest;

DROP TABLE temptest;

-- test temp table deletion
CREATE TEMP TABLE temptest (
    col int
);

\c
SELECT
    *
FROM
    temptest;

-- Test ON COMMIT DELETE ROWS
CREATE TEMP TABLE temptest (
    col int
) ON COMMIT DELETE ROWS;

BEGIN;
INSERT INTO temptest
    VALUES (1);
INSERT INTO temptest
    VALUES (2);
SELECT
    *
FROM
    temptest;
COMMIT;

SELECT
    *
FROM
    temptest;

DROP TABLE temptest;

BEGIN;
CREATE TEMP TABLE temptest (
    col
) ON COMMIT DELETE ROWS AS
SELECT
    1;
SELECT
    *
FROM
    temptest;
COMMIT;

SELECT
    *
FROM
    temptest;

DROP TABLE temptest;

-- Test ON COMMIT DROP
BEGIN;
CREATE TEMP TABLE temptest (
    col int
) ON COMMIT DROP;
INSERT INTO temptest
    VALUES (1);
INSERT INTO temptest
    VALUES (2);
SELECT
    *
FROM
    temptest;
COMMIT;

SELECT
    *
FROM
    temptest;

BEGIN;
CREATE TEMP TABLE temptest (
    col
) ON COMMIT DROP AS
SELECT
    1;
SELECT
    *
FROM
    temptest;
COMMIT;

SELECT
    *
FROM
    temptest;

-- ON COMMIT is only allowed for TEMP
CREATE TABLE temptest (
    col int
) ON COMMIT DELETE ROWS;

CREATE TABLE temptest (
    col
) ON COMMIT DELETE ROWS AS
SELECT
    1;

-- Test foreign keys
BEGIN;
CREATE TEMP TABLE temptest1 (
    col int PRIMARY KEY
);
CREATE TEMP TABLE temptest2 (
    col int REFERENCES temptest1
) ON COMMIT DELETE ROWS;
INSERT INTO temptest1
    VALUES (1);
INSERT INTO temptest2
    VALUES (1);
COMMIT;

SELECT
    *
FROM
    temptest1;

SELECT
    *
FROM
    temptest2;

BEGIN;
CREATE TEMP TABLE temptest3 (
    col int PRIMARY KEY
) ON COMMIT DELETE ROWS;
CREATE TEMP TABLE temptest4 (
    col int REFERENCES temptest3
);
COMMIT;

-- Test manipulation of temp schema's placement in search path
CREATE TABLE public.whereami (
    f1 text
);

INSERT INTO public.whereami
    VALUES ('public');

CREATE temp TABLE whereami (
    f1 text
);

INSERT INTO whereami
    VALUES ('temp');

CREATE FUNCTION public.whoami ()
    RETURNS text
    AS $$
    SELECT
        'public'::text
$$
LANGUAGE sql;

CREATE FUNCTION pg_temp.whoami ()
    RETURNS text
    AS $$
    SELECT
        'temp'::text
$$
LANGUAGE sql;

-- default should have pg_temp implicitly first, but only for tables
SELECT
    *
FROM
    whereami;

SELECT
    whoami ();

-- can list temp first explicitly, but it still doesn't affect functions
SET search_path = pg_temp, public;

SELECT
    *
FROM
    whereami;

SELECT
    whoami ();

-- or put it last for security
SET search_path = public, pg_temp;

SELECT
    *
FROM
    whereami;

SELECT
    whoami ();

-- you can invoke a temp function explicitly, though
SELECT
    pg_temp.whoami ();

DROP TABLE public.whereami;

-- For partitioned temp tables, ON COMMIT actions ignore storage-less
-- partitioned tables.
BEGIN;
CREATE temp TABLE temp_parted_oncommit (
    a int
)
PARTITION BY LIST (a) ON COMMIT DELETE ROWS;
CREATE temp TABLE temp_parted_oncommit_1 PARTITION OF temp_parted_oncommit
FOR VALUES IN (1) ON COMMIT DELETE ROWS;
INSERT INTO temp_parted_oncommit
    VALUES (1);
COMMIT;

-- partitions are emptied by the previous commit
SELECT
    *
FROM
    temp_parted_oncommit;

DROP TABLE temp_parted_oncommit;

-- Check dependencies between ON COMMIT actions with a partitioned
-- table and its partitions.  Using ON COMMIT DROP on a parent removes
-- the whole set.
BEGIN;
CREATE temp TABLE temp_parted_oncommit_test (
    a int
)
PARTITION BY LIST (a) ON COMMIT DROP;
CREATE temp TABLE temp_parted_oncommit_test1 PARTITION OF temp_parted_oncommit_test
FOR VALUES IN (1) ON COMMIT DELETE ROWS;
CREATE temp TABLE temp_parted_oncommit_test2 PARTITION OF temp_parted_oncommit_test
FOR VALUES IN (2) ON COMMIT DROP;
INSERT INTO temp_parted_oncommit_test
VALUES
    (1),
    (2);
COMMIT;

-- no relations remain in this case.
SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'temp_parted_oncommit_test%';

-- Using ON COMMIT DELETE on a partitioned table does not remove
-- all rows if partitions preserve their data.
BEGIN;
CREATE temp TABLE temp_parted_oncommit_test (
    a int
)
PARTITION BY LIST (a) ON COMMIT DELETE ROWS;
CREATE temp TABLE temp_parted_oncommit_test1 PARTITION OF temp_parted_oncommit_test
FOR VALUES IN (1) ON COMMIT preserve ROWS;
CREATE temp TABLE temp_parted_oncommit_test2 PARTITION OF temp_parted_oncommit_test
FOR VALUES IN (2) ON COMMIT DROP;
INSERT INTO temp_parted_oncommit_test
VALUES
    (1),
    (2);
COMMIT;

-- Data from the remaining partition is still here as its rows are
-- preserved.
SELECT
    *
FROM
    temp_parted_oncommit_test;

-- two relations remain in this case.
SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'temp_parted_oncommit_test%';

DROP TABLE temp_parted_oncommit_test;

-- Check dependencies between ON COMMIT actions with inheritance trees.
-- Using ON COMMIT DROP on a parent removes the whole set.
BEGIN;
CREATE temp TABLE temp_inh_oncommit_test (
    a int
) ON COMMIT DROP;
CREATE temp TABLE temp_inh_oncommit_test1 ()
INHERITS (
    temp_inh_oncommit_test
) ON COMMIT DELETE ROWS;
INSERT INTO temp_inh_oncommit_test1
    VALUES (1);
COMMIT;

-- no relations remain in this case
SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'temp_inh_oncommit_test%';

-- Data on the parent is removed, and the child goes away.
BEGIN;
CREATE temp TABLE temp_inh_oncommit_test (
    a int
) ON COMMIT DELETE ROWS;
CREATE temp TABLE temp_inh_oncommit_test1 ()
INHERITS (
    temp_inh_oncommit_test
) ON COMMIT DROP;
INSERT INTO temp_inh_oncommit_test1
    VALUES (1);
INSERT INTO temp_inh_oncommit_test
    VALUES (1);
COMMIT;

SELECT
    *
FROM
    temp_inh_oncommit_test;

-- one relation remains
SELECT
    relname
FROM
    pg_class
WHERE
    relname LIKE 'temp_inh_oncommit_test%';

DROP TABLE temp_inh_oncommit_test;

-- Tests with two-phase commit
-- Transactions creating objects in a temporary namespace cannot be used
-- with two-phase commit.
-- These cases generate errors about temporary namespace.
-- Function creation
BEGIN;
CREATE FUNCTION pg_temp.twophase_func ()
    RETURNS void
    AS $$
    SELECT
        '2pc_func'::text
$$
LANGUAGE sql;
PREPARE TRANSACTION 'twophase_func';
-- Function drop
CREATE FUNCTION pg_temp.twophase_func ()
    RETURNS void
    AS $$
    SELECT
        '2pc_func'::text
$$
LANGUAGE sql;
BEGIN;
DROP FUNCTION pg_temp.twophase_func ();
PREPARE TRANSACTION 'twophase_func';
-- Operator creation
BEGIN;
CREATE OPERATOR pg_temp. @@ (
    LEFTARG = int4,
    RIGHTARG = int4,
    PROCEDURE = int4mi
);
PREPARE TRANSACTION 'twophase_operator';
-- These generate errors about temporary tables.
BEGIN;
CREATE TYPE pg_temp.twophase_type AS (
    a int
);
PREPARE TRANSACTION 'twophase_type';
BEGIN;
CREATE VIEW pg_temp.twophase_view AS
SELECT
    1;
PREPARE TRANSACTION 'twophase_view';
BEGIN;
CREATE SEQUENCE pg_temp.twophase_seq;
PREPARE TRANSACTION 'twophase_sequence';
-- Temporary tables cannot be used with two-phase commit.
CREATE temp TABLE twophase_tab (
    a int
);
BEGIN;
SELECT
    a
FROM
    twophase_tab;
PREPARE TRANSACTION 'twophase_tab';
BEGIN;
INSERT INTO twophase_tab
    VALUES (1);
PREPARE TRANSACTION 'twophase_tab';
BEGIN;
LOCK twophase_tab IN access exclusive mode;
PREPARE TRANSACTION 'twophase_tab';
BEGIN;
DROP TABLE twophase_tab;
PREPARE TRANSACTION 'twophase_tab';
-- Corner case: current_schema may create a temporary schema if namespace
-- creation is pending, so check after that.  First reset the connection
-- to remove the temporary namespace.
\c -
SET search_path TO 'pg_temp';
BEGIN;
SELECT
    current_schema() ~ 'pg_temp' AS is_temp_schema;
PREPARE TRANSACTION 'twophase_search';
