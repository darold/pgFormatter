--
-- Test GIN indexes.
--
-- There are other tests to test different GIN opclasses. This is for testing
-- GIN itself.
-- Create and populate a test table with a GIN index.
CREATE TABLE gin_test_tbl (
    i int4[]
)
WITH (
    autovacuum_enabled = OFF
);

CREATE INDEX gin_test_idx ON gin_test_tbl USING gin (i) WITH (fastupdate = ON, gin_pending_list_limit = 4096);

INSERT INTO gin_test_tbl
SELECT
    ARRAY[1, 2, g]
FROM
    generate_series(1, 20000) g;

INSERT INTO gin_test_tbl
SELECT
    ARRAY[1, 3, g]
FROM
    generate_series(1, 1000) g;

SELECT
    gin_clean_pending_list ('gin_test_idx') > 10 AS many;

-- flush the fastupdate buffers
INSERT INTO gin_test_tbl
SELECT
    ARRAY[3, 1, g]
FROM
    generate_series(1, 1000) g;

VACUUM gin_test_tbl;

-- flush the fastupdate buffers
SELECT
    gin_clean_pending_list ('gin_test_idx');

-- nothing to flush
-- Test vacuuming
DELETE FROM gin_test_tbl
WHERE i @> ARRAY[2];

VACUUM gin_test_tbl;

-- Disable fastupdate, and do more insertions. With fastupdate enabled, most
-- insertions (by flushing the list pages) cause page splits. Without
-- fastupdate, we get more churn in the GIN data leaf pages, and exercise the
-- recompression codepaths.
ALTER INDEX gin_test_idx SET (fastupdate = OFF);

INSERT INTO gin_test_tbl
SELECT
    ARRAY[1, 2, g]
FROM
    generate_series(1, 1000) g;

INSERT INTO gin_test_tbl
SELECT
    ARRAY[1, 3, g]
FROM
    generate_series(1, 1000) g;

DELETE FROM gin_test_tbl
WHERE i @> ARRAY[2];

VACUUM gin_test_tbl;

-- Test for "rare && frequent" searches
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    gin_test_tbl
WHERE
    i @> ARRAY[1, 999];

SELECT
    count(*)
FROM
    gin_test_tbl
WHERE
    i @> ARRAY[1, 999];

-- Very weak test for gin_fuzzy_search_limit
SET gin_fuzzy_search_limit = 1000;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*) > 0 AS ok
FROM
    gin_test_tbl
WHERE
    i @> ARRAY[1];

SELECT
    count(*) > 0 AS ok
FROM
    gin_test_tbl
WHERE
    i @> ARRAY[1];

RESET gin_fuzzy_search_limit;

-- Test optimization of empty queries
CREATE temp TABLE t_gin_test_tbl (
    i int4[],
    j int4[]
);

CREATE INDEX ON t_gin_test_tbl USING gin (i, j);

INSERT INTO t_gin_test_tbl
VALUES
    (NULL, NULL),
    ('{}', NULL),
    ('{1}', NULL),
    ('{1,2}', NULL),
    (NULL, '{}'),
    (NULL, '{10}'),
    ('{1,2}', '{10}'),
    ('{2}', '{10}'),
    ('{1,3}', '{}'),
    ('{1,1}', '{10}');

SET enable_seqscan = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t_gin_test_tbl
WHERE
    ARRAY[0] <@ i;

SELECT
    *
FROM
    t_gin_test_tbl
WHERE
    ARRAY[0] <@ i;

SELECT
    *
FROM
    t_gin_test_tbl
WHERE
    ARRAY[0] <@ i
    AND '{}'::int4[] <@ j;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t_gin_test_tbl
WHERE
    i @> '{}';

SELECT
    *
FROM
    t_gin_test_tbl
WHERE
    i @> '{}';

CREATE FUNCTION explain_query_json (query_sql text)
    RETURNS TABLE (
        explain_line json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    SET enable_seqscan = OFF;
    SET enable_bitmapscan = ON;
    RETURN QUERY EXECUTE 'EXPLAIN (ANALYZE, FORMAT json) ' || query_sql;
END;
$$;

CREATE FUNCTION execute_text_query_index (query_sql text)
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
BEGIN
    SET enable_seqscan = OFF;
    SET enable_bitmapscan = ON;
    RETURN QUERY EXECUTE query_sql;
END;
$$;

CREATE FUNCTION execute_text_query_heap (query_sql text)
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
BEGIN
    SET enable_seqscan = ON;
    SET enable_bitmapscan = OFF;
    RETURN QUERY EXECUTE query_sql;
END;
$$;

-- check number of rows returned by index and removed by recheck
SELECT
    query,
    js -> 0 -> 'Plan' -> 'Plans' -> 0 -> 'Actual Rows' AS "return by index",
    js -> 0 -> 'Plan' -> 'Rows Removed by Index Recheck' AS "removed by recheck",
    (res_index = res_heap) AS "match"
FROM (
    VALUES ($$ i @> '{}' $$),
        ($$ j @> '{}' $$),
        ($$ i @> '{}' and j @> '{}' $$),
        ($$ i @> '{1}' $$),
        ($$ i @> '{1}' and j @> '{}' $$),
        ($$ i @> '{1}' and i @> '{}' and j @> '{}' $$),
        ($$ j @> '{10}' $$),
        ($$ j @> '{10}' and i @> '{}' $$),
        ($$ j @> '{10}' and j @> '{}' and i @> '{}' $$),
        ($$ i @> '{1}' and j @> '{10}' $$)) q (query),
    LATERAL explain_query_json ($$select * from t_gin_test_tbl where $$ || query) js,
    LATERAL execute_text_query_index ($$select string_agg((i, j)::text, ' ') from t_gin_test_tbl where $$ || query) res_index,
    LATERAL execute_text_query_heap ($$select string_agg((i, j)::text, ' ') from t_gin_test_tbl where $$ || query) res_heap;

RESET enable_seqscan;

RESET enable_bitmapscan;

-- re-purpose t_gin_test_tbl to test scans involving posting trees
INSERT INTO t_gin_test_tbl
SELECT
    ARRAY[1, g, g / 10],
    ARRAY[2, g, g / 10]
FROM
    generate_series(1, 20000) g;

SELECT
    gin_clean_pending_list ('t_gin_test_tbl_i_j_idx') IS NOT NULL;

ANALYZE t_gin_test_tbl;

SET enable_seqscan = OFF;

SET enable_bitmapscan = ON;

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[50];

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[50];

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[2];

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[2];

EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> '{}'::int[];

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> '{}'::int[];

-- test vacuuming of posting trees
DELETE FROM t_gin_test_tbl
WHERE j @> ARRAY[2];

VACUUM t_gin_test_tbl;

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[50];

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> ARRAY[2];

SELECT
    count(*)
FROM
    t_gin_test_tbl
WHERE
    j @> '{}'::int[];

RESET enable_seqscan;

RESET enable_bitmapscan;

DROP TABLE t_gin_test_tbl;

-- test an unlogged table, mostly to get coverage of ginbuildempty
CREATE UNLOGGED TABLE t_gin_test_tbl (
    i int4[],
    j int4[]
);

CREATE INDEX ON t_gin_test_tbl USING gin (i, j);

INSERT INTO t_gin_test_tbl
VALUES
    (NULL, NULL),
    ('{}', NULL),
    ('{1}', '{2,3}');

DROP TABLE t_gin_test_tbl;

