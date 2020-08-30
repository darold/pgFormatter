--
-- PARALLEL
--
-- Serializable isolation would disable parallel query, so explicitly use an
-- arbitrary other level.
BEGIN ISOLATION level REPEATABLE read;
-- encourage use of parallel plans
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
--
-- Test write operations that has an underlying query that is eligble
-- for parallel plans
--
EXPLAIN (
    COSTS OFF
) CREATE TABLE parallel_write AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
CREATE TABLE parallel_write AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP TABLE parallel_write;
EXPLAIN (
    COSTS OFF
)
SELECT
    length(stringu1) INTO parallel_write
FROM
    tenk1
GROUP BY
    length(stringu1);
SELECT
    length(stringu1) INTO parallel_write
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP TABLE parallel_write;
EXPLAIN (
    COSTS OFF
) CREATE MATERIALIZED VIEW parallel_mat_view AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
CREATE MATERIALIZED VIEW parallel_mat_view AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP MATERIALIZED VIEW parallel_mat_view;
PREPARE prep_stmt AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
EXPLAIN (
    COSTS OFF
) CREATE TABLE parallel_write AS
EXECUTE prep_stmt;
CREATE TABLE parallel_write AS
EXECUTE prep_stmt;
DROP TABLE parallel_write;
ROLLBACK;

