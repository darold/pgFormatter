-- pg_regress should ensure that this default value applies; however
-- we can't rely on any specific default value of vacuum_cost_delay
SHOW datestyle;

-- Check output style of CamelCase enum options
SET intervalstyle TO 'asd';

-- SET to some nondefault value
SET vacuum_cost_delay TO 40;

SET datestyle = 'ISO, YMD';

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- Check handling of list GUCs
SET search_path = 'pg_catalog', Foo, 'Bar', '';

SHOW search_path;

SET search_path = NULL;

-- means empty list
SHOW search_path;

SET search_path = NULL, NULL;

-- syntax error
SET enable_seqscan = NULL;

-- error
RESET search_path;

-- Check syntax validation of output_plugin_libraries
SELECT
    set_config('output_plugin_libraries', 'pgoutput,', TRUE);

-- SET LOCAL has no effect outside of a transaction
SET LOCAL vacuum_cost_delay TO 50;

SHOW vacuum_cost_delay;

SET LOCAL datestyle = 'SQL';

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- SET LOCAL within a transaction that commits
BEGIN;
SET LOCAL vacuum_cost_delay TO 50;
SHOW vacuum_cost_delay;
SET LOCAL datestyle = 'SQL';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
COMMIT;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- SET should be reverted after ROLLBACK
BEGIN;
SET vacuum_cost_delay TO 60;
SHOW vacuum_cost_delay;
SET datestyle = 'German';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
ROLLBACK;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- Some tests with subtransactions
BEGIN;
SET vacuum_cost_delay TO 70;
SET datestyle = 'MDY';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
SAVEPOINT first_sp;
SET vacuum_cost_delay TO 80.1;
SHOW vacuum_cost_delay;
SET datestyle = 'German, DMY';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
ROLLBACK TO first_sp;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

SAVEPOINT second_sp;

SET vacuum_cost_delay TO '900us';

SET datestyle = 'SQL, YMD';

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

SAVEPOINT third_sp;

SET vacuum_cost_delay TO 100;

SHOW vacuum_cost_delay;

SET datestyle = 'Postgres, MDY';

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

ROLLBACK TO third_sp;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

ROLLBACK TO second_sp;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

ROLLBACK;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- SET LOCAL with Savepoints
BEGIN;
SHOW vacuum_cost_delay;
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
SAVEPOINT sp;
SET LOCAL vacuum_cost_delay TO 30;
SHOW vacuum_cost_delay;
SET LOCAL datestyle = 'Postgres, MDY';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
ROLLBACK TO sp;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

ROLLBACK;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- SET LOCAL persists through RELEASE (which was not true in 8.0-8.2)
BEGIN;
SHOW vacuum_cost_delay;
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
SAVEPOINT sp;
SET LOCAL vacuum_cost_delay TO 30;
SHOW vacuum_cost_delay;
SET LOCAL datestyle = 'Postgres, MDY';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
RELEASE SAVEPOINT sp;
SHOW vacuum_cost_delay;
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
ROLLBACK;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- SET followed by SET LOCAL
BEGIN;
SET vacuum_cost_delay TO 40;
SET LOCAL vacuum_cost_delay TO 50;
SHOW vacuum_cost_delay;
SET datestyle = 'ISO, DMY';
SET LOCAL datestyle = 'Postgres, MDY';
SHOW datestyle;
SELECT
    '2006-08-13 12:34:56'::timestamptz;
COMMIT;

SHOW vacuum_cost_delay;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

--
-- Test RESET.  We use datestyle because the reset value is forced by
-- pg_regress, so it doesn't depend on the installation's configuration.
--
SET datestyle = iso, ymd;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

RESET datestyle;

SHOW datestyle;

SELECT
    '2006-08-13 12:34:56'::timestamptz;

-- Test some simple error cases
SET seq_page_cost TO 'NaN';

SET vacuum_cost_delay TO '10s';

SET no_such_variable TO 42;

-- Test "custom" GUCs created on the fly (which aren't really an
-- intended feature, but many people use them).
SHOW custom.my_guc;

-- error, not known yet
SET custom.my_guc = 42;

SHOW custom.my_guc;

RESET custom.my_guc;

-- this makes it go to empty, not become unknown again
SHOW custom.my_guc;

SET custom.my.qualified.guc = 'foo';

SHOW custom.my.qualified.guc;

SET custom."bad-guc" = 42;

-- disallowed because -c cannot set this name
SHOW custom."bad-guc";

SET special. "weird name" = 'foo';

-- could be allowed, but we choose not to
SHOW special. "weird name";

-- Check what happens when you try to set a "custom" GUC within the
-- namespace of an extension.
SET plpgsql.extra_foo_warnings = TRUE;

-- allowed if plpgsql is not loaded yet
LOAD 'plpgsql';

-- this will throw a warning and delete the variable
SET plpgsql.extra_foo_warnings = TRUE;

-- now, it's an error
SHOW plpgsql.extra_foo_warnings;

--
-- Test DISCARD TEMP
--
CREATE TEMP TABLE reset_test (
    data text
) ON COMMIT DELETE ROWS;

SELECT
    relname
FROM
    pg_class
WHERE
    relname = 'reset_test';

DISCARD TEMP;

SELECT
    relname
FROM
    pg_class
WHERE
    relname = 'reset_test';

--
-- Test DISCARD ALL
--
-- do changes
DECLARE foo CURSOR WITH HOLD FOR
    SELECT
        1;

PREPARE foo AS
SELECT
    1;

LISTEN foo_event;

SET vacuum_cost_delay = 13;

CREATE TEMP TABLE tmp_foo (
    data text
) ON COMMIT DELETE ROWS;

CREATE ROLE regress_guc_user;

SET SESSION AUTHORIZATION regress_guc_user;

-- look changes
SELECT
    pg_listening_channels();

SELECT
    name
FROM
    pg_prepared_statements;

SELECT
    name
FROM
    pg_cursors;

SHOW vacuum_cost_delay;

SELECT
    relname
FROM
    pg_class
WHERE
    relname = 'tmp_foo';

SELECT
    CURRENT_USER = 'regress_guc_user';

-- discard everything
DISCARD ALL;

-- look again
SELECT
    pg_listening_channels();

SELECT
    name
FROM
    pg_prepared_statements;

SELECT
    name
FROM
    pg_cursors;

SHOW vacuum_cost_delay;

SELECT
    relname
FROM
    pg_class
WHERE
    relname = 'tmp_foo';

SELECT
    CURRENT_USER = 'regress_guc_user';

DROP ROLE regress_guc_user;

--
-- search_path should react to changes in pg_namespace
--
SET search_path = foo, public, not_there_initially;

SELECT
    current_schemas(FALSE);

CREATE SCHEMA not_there_initially;

SELECT
    current_schemas(FALSE);

DROP SCHEMA not_there_initially;

SELECT
    current_schemas(FALSE);

RESET search_path;

--
-- Test parsing of log_min_messages
--
SET log_min_messages TO foo;

-- fail
SET log_min_messages TO fatal;

SHOW log_min_messages;

SET log_min_messages TO 'fatal';

SHOW log_min_messages;

SET log_min_messages TO 'checkpointer:debug2, autovacuum:debug1';

-- fail
SET log_min_messages TO 'debug1, backend:error, fatal';

-- fail
SET log_min_messages TO 'backend:error, debug1, backend:warning';

-- fail
SET log_min_messages TO 'backend:error, foo:fatal, archiver:debug1';

-- fail
SET log_min_messages TO 'backend:error, checkpointer:bar, archiver:debug1';

-- fail
SET log_min_messages TO 'backend:error, checkpointer:debug3, fatal, archiver:debug2, autovacuum:debug1, walsender:debug3';

SHOW log_min_messages;

SET log_min_messages TO 'warning, autovacuum:debug1';

SHOW log_min_messages;

SET log_min_messages TO 'autovacuum:debug1, warning';

SHOW log_min_messages;

RESET log_min_messages;

--
-- Tests for function-local GUC settings
--
SET work_mem = '3MB';

CREATE FUNCTION report_guc (text)
    RETURNS text
    AS $$
    SELECT
        current_setting($1)
$$
LANGUAGE sql
SET work_mem = '1MB';

SELECT
    report_guc ('work_mem'),
    current_setting('work_mem');

ALTER FUNCTION report_guc (text) SET work_mem = '2MB';

SELECT
    report_guc ('work_mem'),
    current_setting('work_mem');

ALTER FUNCTION report_guc (text) RESET ALL;

SELECT
    report_guc ('work_mem'),
    current_setting('work_mem');

-- SET LOCAL is restricted by a function SET option
CREATE OR REPLACE FUNCTION myfunc (int)
    RETURNS text
    AS $$
BEGIN
    SET local work_mem = '2MB';
    RETURN current_setting('work_mem');
END
$$
LANGUAGE plpgsql
SET work_mem = '1MB';

SELECT
    myfunc (0),
    current_setting('work_mem');

ALTER FUNCTION myfunc (int) RESET ALL;

SELECT
    myfunc (0),
    current_setting('work_mem');

SET work_mem = '3MB';

-- but SET isn't
CREATE OR REPLACE FUNCTION myfunc (int)
    RETURNS text
    AS $$
BEGIN
    SET work_mem = '2MB';
    RETURN current_setting('work_mem');
END
$$
LANGUAGE plpgsql
SET work_mem = '1MB';

SELECT
    myfunc (0),
    current_setting('work_mem');

SET work_mem = '3MB';

-- it should roll back on error, though
CREATE OR REPLACE FUNCTION myfunc (int)
    RETURNS text
    AS $$
BEGIN
    SET work_mem = '2MB';
    PERFORM
        1 / $1;
    RETURN current_setting('work_mem');
END
$$
LANGUAGE plpgsql
SET work_mem = '1MB';

SELECT
    myfunc (0);

SELECT
    current_setting('work_mem');

SELECT
    myfunc (1),
    current_setting('work_mem');

-- check current_setting()'s behavior with invalid setting name
SELECT
    current_setting('nosuch.setting');

-- FAIL
SELECT
    current_setting('nosuch.setting', FALSE);

-- FAIL
SELECT
    current_setting('nosuch.setting', TRUE) IS NULL;

-- after this, all three cases should yield 'nada'
SET nosuch.setting = 'nada';

SELECT
    current_setting('nosuch.setting');

SELECT
    current_setting('nosuch.setting', FALSE);

SELECT
    current_setting('nosuch.setting', TRUE);

-- Normally, CREATE FUNCTION should complain about invalid values in
-- function SET options; but not if check_function_bodies is off,
-- because that creates ordering hazards for pg_dump
CREATE FUNCTION func_with_bad_set ()
    RETURNS int
    AS $$
    SELECT
        1
$$
LANGUAGE sql
SET default_text_search_config = no_such_config;

SET check_function_bodies = OFF;

CREATE FUNCTION func_with_bad_set ()
    RETURNS int
    AS $$
    SELECT
        1
$$
LANGUAGE sql
SET default_text_search_config = no_such_config;

SELECT
    func_with_bad_set ();

RESET check_function_bodies;

SET default_with_oids TO f;

-- Should not allow to set it to true.
SET default_with_oids TO t;

-- Test that disabling track_activities disables query ID reporting in
-- pg_stat_activity.
SET compute_query_id = ON;

SET track_activities = ON;

SELECT
    query_id IS NOT NULL AS qid_set
FROM
    pg_stat_activity
WHERE
    pid = pg_backend_pid();

SET track_activities = OFF;

SELECT
    query_id IS NOT NULL AS qid_set
FROM
    pg_stat_activity
WHERE
    pid = pg_backend_pid();

RESET track_activities;

RESET compute_query_id;

-- Test GUC_SHOW_IN_OCTAL
SELECT
    name,
    min_val,
    max_val,
    boot_val
FROM
    pg_settings
WHERE
    name IN ('data_directory_mode', 'log_file_mode', 'unix_socket_permissions');

ALTER SYSTEM SET log_file_mode = 0640;

-- decimal, so out of range
-- Test GUC categories and flag patterns
SELECT
    pg_settings_get_flags (NULL);

SELECT
    pg_settings_get_flags ('does_not_exist');

CREATE TABLE tab_settings_flags AS
SELECT
    name,
    category,
    'EXPLAIN' = ANY (flags) AS explain,
    'NO_RESET' = ANY (
        flags
) AS no_reset,
    'NO_RESET_ALL' = ANY (flags) AS no_reset_all,
    'NOT_IN_SAMPLE' = ANY (flags) AS not_in_sample,
    'RUNTIME_COMPUTED' = ANY (flags) AS runtime_computed
FROM
    pg_show_all_settings() AS psas,
    pg_settings_get_flags (psas.name) AS flags;

-- Developer GUCs should be flagged with GUC_NOT_IN_SAMPLE:
SELECT
    name
FROM
    tab_settings_flags
WHERE
    category = 'Developer Options'
    AND NOT not_in_sample
ORDER BY
    1;

-- Most query-tuning GUCs are flagged as valid for EXPLAIN.
-- default_statistics_target is an exception.
SELECT
    name
FROM
    tab_settings_flags
WHERE
    category ~ '^Query Tuning'
    AND NOT EXPLAIN
ORDER BY
    1;

-- Runtime-computed GUCs should be part of the preset category.
SELECT
    name
FROM
    tab_settings_flags
WHERE
    NOT category = 'Preset Options'
    AND runtime_computed
ORDER BY
    1;

-- Preset GUCs are flagged as NOT_IN_SAMPLE.
SELECT
    name
FROM
    tab_settings_flags
WHERE
    category = 'Preset Options'
    AND NOT not_in_sample
ORDER BY
    1;

-- NO_RESET implies NO_RESET_ALL.
SELECT
    name
FROM
    tab_settings_flags
WHERE
    no_reset
    AND NOT no_reset_all
ORDER BY
    1;

DROP TABLE tab_settings_flags;

