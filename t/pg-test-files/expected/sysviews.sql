--
-- Test assorted system views
--
-- This test is mainly meant to provide some code coverage for the
-- set-returning functions that underlie certain system views.
-- The output of most of these functions is very environment-dependent,
-- so our ability to test with fixed expected output is pretty limited;
-- but even a trivial check of count(*) will exercise the normal code path
-- through the SRF.
SELECT
    count(*) >= 0 AS ok
FROM
    pg_available_extension_versions;

SELECT
    count(*) >= 0 AS ok
FROM
    pg_available_extensions;

-- The entire output of pg_backend_memory_contexts is not stable,
-- we test only the existence and basic condition of TopMemoryContext.
SELECT
    type,
    name,
    ident,
    level,
    total_bytes >= free_bytes
FROM
    pg_backend_memory_contexts
WHERE
    level = 1;

-- We can exercise some MemoryContext type stats functions.  Most of the
-- column values are too platform-dependent to display.
-- Ensure stats from the bump allocator look sane.  Bump isn't a commonly
-- used context, but it is used in tuplesort.c, so open a cursor to keep
-- the tuplesort alive long enough for us to query the context stats.
BEGIN;
DECLARE cur CURSOR FOR
    SELECT
    LEFT (a,
        10),
    b
FROM (
    VALUES (repeat('a', 512 * 1024),
            1),
        (repeat('b', 512),
            2)) v (a, b)
ORDER BY
    v.a DESC;
FETCH 1 FROM cur;
SELECT
    type,
    name,
    total_bytes > 0,
    total_nblocks,
    free_bytes > 0,
    free_chunks
FROM
    pg_backend_memory_contexts
WHERE
    name = 'Caller tuples';
ROLLBACK;

-- Further sanity checks on pg_backend_memory_contexts.  We expect
-- CacheMemoryContext to have multiple children.  Ensure that's the case.
WITH contexts AS (
    SELECT
        *
    FROM
        pg_backend_memory_contexts
)
SELECT
    count(*) > 1
FROM
    contexts c1,
    contexts c2
WHERE
    c2.name = 'CacheMemoryContext'
    AND c1.path[c2.level] = c2.path[c2.level];

-- At introduction, pg_config had 23 entries; it may grow
SELECT
    count(*) > 20 AS ok
FROM
    pg_config;

-- We expect no cursors in this test; see also portals.sql
SELECT
    count(*) = 0 AS ok
FROM
    pg_cursors;

SELECT
    count(*) >= 0 AS ok
FROM
    pg_file_settings;

-- There will surely be at least one rule, with no errors.
SELECT
    count(*) > 0 AS ok,
    count(*) FILTER (WHERE error IS NOT NULL) = 0 AS no_err
FROM
    pg_hba_file_rules;

-- There may be no rules, and there should be no errors.
SELECT
    count(*) >= 0 AS ok,
    count(*) FILTER (WHERE error IS NOT NULL) = 0 AS no_err
FROM
    pg_ident_file_mappings;

-- There will surely be at least one active lock
SELECT
    count(*) > 0 AS ok
FROM
    pg_locks;

-- We expect no prepared statements in this test; see also prepare.sql
SELECT
    count(*) = 0 AS ok
FROM
    pg_prepared_statements;

-- See also prepared_xacts.sql
SELECT
    count(*) >= 0 AS ok
FROM
    pg_prepared_xacts;

-- There will surely be at least one SLRU cache
SELECT
    count(*) > 0 AS ok
FROM
    pg_stat_slru;

-- There must be only one record
SELECT
    count(*) = 1 AS ok
FROM
    pg_stat_wal;

-- We expect no walreceiver running in this test
SELECT
    count(*) = 0 AS ok
FROM
    pg_stat_wal_receiver;

-- We expect no recovery state in this test (running on primary)
SELECT
    count(*) = 0 AS ok
FROM
    pg_stat_recovery;

-- This is to record the prevailing planner enable_foo settings during
-- a regression test run.
SELECT
    name,
    setting
FROM
    pg_settings
WHERE
    name LIKE 'enable%';

-- There are always wait event descriptions for various types.  InjectionPoint
-- may be present or absent, depending on history since last postmaster start.
SELECT
    type,
    count(*) > 0 AS ok
FROM
    pg_wait_events
WHERE
    type <> 'InjectionPoint'
GROUP BY
    type
ORDER BY
    type COLLATE "C";

-- Test that the pg_timezone_names and pg_timezone_abbrevs views are
-- more-or-less working.  We can't test their contents in any great detail
-- without the outputs changing anytime IANA updates the underlying data,
-- but it seems reasonable to expect at least one entry per major meridian.
-- (At the time of writing, the actual counts are around 38 because of
-- zones using fractional GMT offsets, so this is a pretty loose test.)
SELECT
    count(DISTINCT utc_offset) >= 24 AS ok
FROM
    pg_timezone_names;

SELECT
    count(DISTINCT utc_offset) >= 24 AS ok
FROM
    pg_timezone_abbrevs;

-- Let's check the non-default timezone abbreviation sets, too
SET timezone_abbreviations = 'Australia';

SELECT
    count(DISTINCT utc_offset) >= 24 AS ok
FROM
    pg_timezone_abbrevs;

SET timezone_abbreviations = 'India';

SELECT
    count(DISTINCT utc_offset) >= 24 AS ok
FROM
    pg_timezone_abbrevs;

-- One specific case we can check without much fear of breakage
-- is the historical local-mean-time value used for America/Los_Angeles.
SELECT
    *
FROM
    pg_timezone_abbrevs
WHERE
    abbrev = 'LMT';

