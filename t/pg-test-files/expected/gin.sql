--
-- Test GIN indexes.
--
-- There are other tests to test different GIN opclassed. This is for testing
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

