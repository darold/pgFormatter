--
-- Tests to exercise the plan caching/invalidation mechanism
--
CREATE TEMP TABLE pcachetest AS
SELECT
    *
FROM
    int8_tbl;

-- create and use a cached plan
PREPARE prepstmt AS
SELECT
    *
FROM
    pcachetest;

EXECUTE prepstmt;

-- and one with parameters
PREPARE prepstmt2 (bigint) AS
SELECT
    *
FROM
    pcachetest
WHERE
    q1 = $1;

EXECUTE prepstmt2 (123);

-- invalidate the plans and see what happens
DROP TABLE pcachetest;

EXECUTE prepstmt;

EXECUTE prepstmt2 (123);

-- recreate the temp table (this demonstrates that the raw plan is
-- purely textual and doesn't depend on OIDs, for instance)
CREATE TEMP TABLE pcachetest AS
SELECT
    *
FROM
    int8_tbl
ORDER BY
    2;

EXECUTE prepstmt;

EXECUTE prepstmt2 (123);

-- prepared statements should prevent change in output tupdesc,
-- since clients probably aren't expecting that to change on the fly
ALTER TABLE pcachetest
    ADD COLUMN q3 bigint;

EXECUTE prepstmt;

EXECUTE prepstmt2 (123);

-- but we're nice guys and will let you undo your mistake
ALTER TABLE pcachetest
    DROP COLUMN q3;

EXECUTE prepstmt;

EXECUTE prepstmt2 (123);

-- Try it with a view, which isn't directly used in the resulting plan
-- but should trigger invalidation anyway
CREATE TEMP VIEW pcacheview AS
SELECT
    *
FROM
    pcachetest;

PREPARE vprep AS
SELECT
    *
FROM
    pcacheview;

EXECUTE vprep;

CREATE OR REPLACE TEMP VIEW pcacheview AS
SELECT
    q1,
    q2 / 2 AS q2
FROM
    pcachetest;

EXECUTE vprep;

-- Check basic SPI plan invalidation
CREATE FUNCTION cache_test (int)
    RETURNS int
    AS $$
DECLARE
    total int;
BEGIN
    CREATE temp TABLE t1 (
        f1 int
    );
INSERT INTO t1
    VALUES ($1);
INSERT INTO t1
    VALUES (11);
INSERT INTO t1
    VALUES (12);
INSERT INTO t1
    VALUES (13);
    SELECT
        sum(f1) INTO total
    FROM
        t1;
    DROP TABLE t1;
    RETURN total;
END
$$
LANGUAGE plpgsql;

SELECT
    cache_test (1);

SELECT
    cache_test (2);

SELECT
    cache_test (3);

-- Check invalidation of plpgsql "simple expression"
CREATE temp VIEW v1 AS
SELECT
    2 + 2 AS f1;

CREATE FUNCTION cache_test_2 ()
    RETURNS int
    AS $$
BEGIN
    RETURN f1
FROM
    v1;
END
$$
LANGUAGE plpgsql;

SELECT
    cache_test_2 ();

CREATE OR REPLACE temp VIEW v1 AS
SELECT
    2 + 2 + 4 AS f1;

SELECT
    cache_test_2 ();

CREATE OR REPLACE temp VIEW v1 AS
SELECT
    2 + 2 + 4 + (
        SELECT
            max(unique1)
        FROM tenk1) AS f1;

SELECT
    cache_test_2 ();

--- Check that change of search_path is honored when re-using cached plan
CREATE SCHEMA s1
    CREATE TABLE abc (
        f1 int
);

CREATE SCHEMA s2
    CREATE TABLE abc (
        f1 int
);

INSERT INTO s1.abc
    VALUES (123);

INSERT INTO s2.abc
    VALUES (456);

SET search_path = s1;

PREPARE p1 AS
SELECT
    f1
FROM
    abc;

EXECUTE p1;

SET search_path = s2;

SELECT
    f1
FROM
    abc;

EXECUTE p1;

ALTER TABLE s1.abc
    ADD COLUMN f2 float8;

-- force replan
EXECUTE p1;

DROP SCHEMA s1 CASCADE;

DROP SCHEMA s2 CASCADE;

RESET search_path;

-- Check that invalidation deals with regclass constants
CREATE temp SEQUENCE seq;

PREPARE p2 AS
SELECT
    nextval('seq');

EXECUTE p2;

DROP SEQUENCE seq;

CREATE temp SEQUENCE seq;

EXECUTE p2;

-- Check DDL via SPI, immediately followed by SPI plan re-use
-- (bug in original coding)
CREATE FUNCTION cachebug ()
    RETURNS void
    AS $$
DECLARE
    r int;
BEGIN
    DROP TABLE IF EXISTS temptable CASCADE;
    CREATE temp TABLE temptable AS
    SELECT
        *
    FROM
        generate_series(1, 3) AS f1;
    CREATE temp VIEW vv AS
    SELECT
        *
    FROM
        temptable;
    FOR r IN
    SELECT
        *
    FROM
        vv LOOP
            RAISE NOTICE '%', r;
        END LOOP;
END
$$
LANGUAGE plpgsql;

SELECT
    cachebug ();

SELECT
    cachebug ();

-- Check that addition or removal of any partition is correctly dealt with by
-- default partition table when it is being used in prepared statement.
CREATE TABLE pc_list_parted (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE pc_list_part_null PARTITION OF pc_list_parted
FOR VALUES IN (NULL);

CREATE TABLE pc_list_part_1 PARTITION OF pc_list_parted
FOR VALUES IN (1);

CREATE TABLE pc_list_part_def PARTITION OF pc_list_parted DEFAULT;

PREPARE pstmt_def_insert (int) AS
INSERT INTO pc_list_part_def
    VALUES ($1);

-- should fail
EXECUTE pstmt_def_insert (NULL);

EXECUTE pstmt_def_insert (1);

CREATE TABLE pc_list_part_2 PARTITION OF pc_list_parted
FOR VALUES IN (2);

EXECUTE pstmt_def_insert (2);

ALTER TABLE pc_list_parted DETACH PARTITION pc_list_part_null;

-- should be ok
EXECUTE pstmt_def_insert (NULL);

DROP TABLE pc_list_part_1;

-- should be ok
EXECUTE pstmt_def_insert (1);

DROP TABLE pc_list_parted, pc_list_part_null;

DEALLOCATE pstmt_def_insert;

-- Test plan_cache_mode
CREATE TABLE test_mode (
    a int
);

INSERT INTO test_mode
SELECT
    1
FROM
    generate_series(1, 1000)
UNION ALL
SELECT
    2;

CREATE INDEX ON test_mode (a);

ANALYZE test_mode;

PREPARE test_mode_pp (int) AS
SELECT
    count(*)
FROM
    test_mode
WHERE
    a = $1;

-- up to 5 executions, custom plan is used
EXPLAIN (
    COSTS OFF
) EXECUTE test_mode_pp (2);

-- force generic plan
SET plan_cache_mode TO force_generic_plan;

EXPLAIN (
    COSTS OFF
) EXECUTE test_mode_pp (2);

-- get to generic plan by 5 executions
SET plan_cache_mode TO auto;

EXECUTE test_mode_pp (1);

-- 1x
EXECUTE test_mode_pp (1);

-- 2x
EXECUTE test_mode_pp (1);

-- 3x
EXECUTE test_mode_pp (1);

-- 4x
EXECUTE test_mode_pp (1);

-- 5x
-- we should now get a really bad plan
EXPLAIN (
    COSTS OFF
) EXECUTE test_mode_pp (2);

-- but we can force a custom plan
SET plan_cache_mode TO force_custom_plan;

EXPLAIN (
    COSTS OFF
) EXECUTE test_mode_pp (2);

DROP TABLE test_mode;

