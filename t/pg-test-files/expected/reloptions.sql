-- Simple create
CREATE TABLE reloptions_test (
    i int
)
WITH (
    FiLLFaCToR = 30,
    autovacuum_enabled = FALSE,
    autovacuum_analyze_scale_factor = 0.2
);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

-- Fail min/max values check
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = 2
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = 110
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_analyze_scale_factor = -10.0
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_analyze_scale_factor = 110.0
);

-- Fail when option and namespace do not exist
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    not_existing_option = 2
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    not_existing_namespace.fillfactor = 2
);

-- Fail while setting improper values
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = -30.1
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = 'string'
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = TRUE
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_enabled = 12
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_enabled = 30.5
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_enabled = 'string'
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_analyze_scale_factor = 'string'
);

CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    autovacuum_analyze_scale_factor = TRUE
);

-- Fail if option is specified twice
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor = 30,
    fillfactor = 40
);

-- Specifying name only for a non-Boolean option should fail
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    fillfactor
);

-- Simple ALTER TABLE
ALTER TABLE reloptions_test SET (fillfactor = 31, autovacuum_analyze_scale_factor = 0.3);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

-- Set boolean option to true without specifying value
ALTER TABLE reloptions_test SET (autovacuum_enabled, fillfactor = 32);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

-- Check that RESET works well
ALTER TABLE reloptions_test RESET (fillfactor);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

-- Resetting all values causes the column to become null
ALTER TABLE reloptions_test RESET (autovacuum_enabled, autovacuum_analyze_scale_factor);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass
    AND reloptions IS NULL;

-- RESET fails if a value is specified
ALTER TABLE reloptions_test RESET (fillfactor = 12);

-- Test vacuum_truncate option
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test (
    i int NOT NULL,
    j text
)
WITH (
    vacuum_truncate = FALSE,
    toast.vacuum_truncate = FALSE,
    autovacuum_enabled = FALSE
);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

INSERT INTO reloptions_test
VALUES
    (1, NULL),
    (NULL, NULL);

VACUUM reloptions_test;

SELECT
    pg_relation_size('reloptions_test') > 0;

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = (
        SELECT
            reltoastrelid
        FROM
            pg_class
        WHERE
            oid = 'reloptions_test'::regclass);

ALTER TABLE reloptions_test RESET (vacuum_truncate);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

INSERT INTO reloptions_test
VALUES
    (1, NULL),
    (NULL, NULL);

VACUUM reloptions_test;

SELECT
    pg_relation_size('reloptions_test') = 0;

-- Test toast.* options
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test (
    s varchar
)
WITH (
    toast.autovacuum_vacuum_cost_delay = 23
);

SELECT
    reltoastrelid AS toast_oid
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass \gset

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = :toast_oid;

ALTER TABLE reloptions_test SET (toast.autovacuum_vacuum_cost_delay = 24);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = :toast_oid;

ALTER TABLE reloptions_test RESET (toast.autovacuum_vacuum_cost_delay);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = :toast_oid;

-- Fail on non-existent options in toast namespace
CREATE TABLE reloptions_test2 (
    i int
)
WITH (
    toast.not_existing_option = 42
);

-- Mix TOAST & heap
DROP TABLE reloptions_test;

CREATE TABLE reloptions_test (
    s varchar
)
WITH (
    toast.autovacuum_vacuum_cost_delay = 23,
    autovacuum_vacuum_cost_delay = 24,
    fillfactor = 40
);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test'::regclass;

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = (
        SELECT
            reltoastrelid
        FROM
            pg_class
        WHERE
            oid = 'reloptions_test'::regclass);

--
-- CREATE INDEX, ALTER INDEX for btrees
--
CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (fillfactor = 30);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test_idx'::regclass;

-- Fail when option and namespace do not exist
CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (not_existing_option = 2);

CREATE INDEX reloptions_test_idx ON reloptions_test (s) WITH (not_existing_ns.fillfactor = 2);

-- Check allowed ranges
CREATE INDEX reloptions_test_idx2 ON reloptions_test (s) WITH (fillfactor = 1);

CREATE INDEX reloptions_test_idx2 ON reloptions_test (s) WITH (fillfactor = 130);

-- Check ALTER
ALTER INDEX reloptions_test_idx SET (fillfactor = 40);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test_idx'::regclass;

-- Check ALTER on empty reloption list
CREATE INDEX reloptions_test_idx3 ON reloptions_test (s);

ALTER INDEX reloptions_test_idx3 SET (fillfactor = 40);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'reloptions_test_idx3'::regclass;

