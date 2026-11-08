--
-- EXPLAIN
--
-- There are many test cases elsewhere that use EXPLAIN as a vehicle for
-- checking something else (usually planner behavior).  This file is
-- concerned with testing EXPLAIN in its own right.
--
-- To produce stable regression test output, it's usually necessary to
-- ignore details such as exact costs or row counts.  These filter
-- functions replace changeable output details with fixed strings.
CREATE FUNCTION explain_filter (text)
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE
    ln text;
BEGIN
    FOR ln IN EXECUTE $1 LOOP
        -- Replace any numeric word with just 'N'
        ln := regexp_replace(ln, '-?\m\d+\M', 'N', 'g');
        -- In sort output, the above won't match units-suffixed numbers
        ln := regexp_replace(ln, '\m\d+kB', 'NkB', 'g');
        -- Ignore text-mode buffers output because it varies depending
        -- on the system state
        CONTINUE
        WHEN (ln ~ ' +Buffers: .*');
        -- Ignore text-mode "Planning:" line because whether it's output
        -- varies depending on the system state
        CONTINUE
        WHEN (ln = 'Planning:');
        RETURN NEXT ln;
    END LOOP;
END;
$$;

-- To produce valid JSON output, replace numbers with "0" or "0.0" not "N"
CREATE FUNCTION explain_filter_to_json (text)
    RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    data text := '';
    ln text;
BEGIN
    FOR ln IN EXECUTE $1 LOOP
        -- Replace any numeric word with just '0'
        ln := regexp_replace(ln, '\m\d+\M', '0', 'g');
        data := data || ln;
    END LOOP;
    RETURN data::jsonb;
END;
$$;

-- Disable JIT, or we'll get different output on machines where that's been
-- forced on
SET jit = OFF;

-- Similarly, disable track_io_timing, to avoid output differences when
-- enabled.
SET track_io_timing = OFF;

-- Simple cases
EXPLAIN (
    COSTS OFF
)
SELECT
    1 AS a,
    2 AS b
HAVING
    FALSE;

SELECT
    explain_filter ('explain select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze, buffers off) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze, buffers off, verbose) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze, buffers, format text) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (buffers, format text) select * from int8_tbl i8');

\a
SELECT
    explain_filter ('explain (analyze, buffers, io, format xml) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze, serialize, buffers, io, format yaml) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (buffers, format json) select * from int8_tbl i8');

\a
-- Check expansion of window definitions
SELECT
    explain_filter ('explain verbose select sum(unique1) over w, sum(unique2) over (w order by hundred), sum(tenthous) over (w order by hundred) from tenk1 window w as (partition by ten)');

SELECT
    explain_filter ('explain verbose select sum(unique1) over w1, sum(unique2) over (w1 order by hundred), sum(tenthous) over (w1 order by hundred rows 10 preceding) from tenk1 window w1 as (partition by ten)');

-- Check output including I/O timings.  These fields are conditional
-- but always set in JSON format, so check them only in this case.
SET track_io_timing = ON;

SELECT
    explain_filter ('explain (analyze, buffers, format json) select * from int8_tbl i8');

SET track_io_timing = OFF;

-- SETTINGS option
-- We have to ignore other settings that might be imposed by the environment,
-- so printing the whole Settings field unfortunately won't do.
BEGIN;
SET local plan_cache_mode = force_generic_plan;
SELECT
    TRUE AS "OK"
FROM
    explain_filter ('explain (settings) select * from int8_tbl i8')
    ln
WHERE
    ln ~ '^ *Settings: .*plan_cache_mode = ''force_generic_plan''';
SELECT
    explain_filter_to_json ('explain (settings, format json) select * from int8_tbl i8') #> '{0,Settings,plan_cache_mode}';
ROLLBACK;

-- GENERIC_PLAN option
SELECT
    explain_filter ('explain (generic_plan) select unique1 from tenk1 where thousand = $1');

-- should fail
SELECT
    explain_filter ('explain (analyze, generic_plan) select unique1 from tenk1 where thousand = $1');

-- MEMORY option
SELECT
    explain_filter ('explain (memory) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (memory, analyze, buffers off) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (memory, summary, format yaml) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (memory, analyze, format json) select * from int8_tbl i8');

PREPARE int8_query AS
SELECT
    *
FROM
    int8_tbl i8;

SELECT
    explain_filter ('explain (memory) execute int8_query');

-- Test EXPLAIN (GENERIC_PLAN) with partition pruning
-- partitions should be pruned at plan time, based on constants,
-- but there should be no pruning based on parameter placeholders
CREATE TABLE gen_part (
    key1 integer NOT NULL,
    key2 integer NOT NULL
)
PARTITION BY LIST (key1);

CREATE TABLE gen_part_1 PARTITION OF gen_part
FOR VALUES IN (1)
PARTITION BY RANGE (key2);

CREATE TABLE gen_part_1_1 PARTITION OF gen_part_1
FOR VALUES FROM (1) TO (2);

CREATE TABLE gen_part_1_2 PARTITION OF gen_part_1
FOR VALUES FROM (2) TO (3);

CREATE TABLE gen_part_2 PARTITION OF gen_part
FOR VALUES IN (2);

-- should scan gen_part_1_1 and gen_part_1_2, but not gen_part_2
SELECT
    explain_filter ('explain (generic_plan) select key1, key2 from gen_part where key1 = 1 and key2 = $1');

DROP TABLE gen_part;

--
-- Test production of per-worker data
--
-- Unfortunately, because we don't know how many worker processes we'll
-- actually get (maybe none at all), we can't examine the "Workers" output
-- in any detail.  We can check that it parses correctly as JSON, and then
-- remove it from the displayed results.
BEGIN;
-- encourage use of parallel plans
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
SELECT
    jsonb_pretty(explain_filter_to_json ('explain (analyze, verbose, buffers, format json)
                         select * from tenk1 order by tenthous')
        -- remove "Workers" node of the Seq Scan plan node
        #- '{0,Plan,Plans,0,Plans,0,Workers}'
        -- remove "Workers" node of the Sort plan node
        #- '{0,Plan,Plans,0,Workers}'
        -- Also remove its sort-type fields, as those aren't 100% stable
        #- '{0,Plan,Plans,0,Sort Method}' #- '{0,Plan,Plans,0,Sort Space Type}');
ROLLBACK;

-- Test display of temporary objects
CREATE temp TABLE t1 (
    f1 float8
);

CREATE FUNCTION pg_temp.mysin (float8)
    RETURNS float8
    LANGUAGE plpgsql
    AS '
BEGIN
    RETURN sin($1);

END;
';

SELECT
    explain_filter ('explain (verbose) select * from t1 where pg_temp.mysin(f1) < 0.5');

-- Test compute_query_id
SET compute_query_id = ON;

SELECT
    explain_filter ('explain (verbose) select * from int8_tbl i8');

-- Test compute_query_id with utility statements containing plannable query
SELECT
    explain_filter ('explain (verbose) declare test_cur cursor for select * from int8_tbl');

SELECT
    explain_filter ('explain (verbose) create table test_ctas as select 1');

-- Test SERIALIZE option
SELECT
    explain_filter ('explain (analyze,buffers off,serialize) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze,serialize text,buffers,timing off) select * from int8_tbl i8');

SELECT
    explain_filter ('explain (analyze,serialize binary,buffers,timing) select * from int8_tbl i8');

-- this tests an edge case where we have no data to return
SELECT
    explain_filter ('explain (analyze,buffers off,serialize) create temp table explain_temp as select * from int8_tbl i8');

-- Test tuplestore storage usage in Window aggregate (memory case)
SELECT
    explain_filter ('explain (analyze,buffers off,costs off) select sum(n) over() from generate_series(1,10) a(n)');

-- Test tuplestore storage usage in Window aggregate (disk case)
SET work_mem TO 64;

SELECT
    explain_filter ('explain (analyze,buffers off,costs off) select sum(n) over() from generate_series(1,2500) a(n)');

-- Test tuplestore storage usage in Window aggregate (memory and disk case, final result is disk)
SELECT
    explain_filter ('explain (analyze,buffers off,costs off) select sum(n) over(partition by m) from (SELECT n < 3 as m, n from generate_series(1,2500) a(n))');

RESET work_mem;

