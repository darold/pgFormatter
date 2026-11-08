--
-- PARALLEL
--
-- Save parallel worker stats, used for comparison at the end
SELECT
    pg_stat_force_next_flush ();

SELECT
    parallel_workers_to_launch AS parallel_workers_to_launch_before,
    parallel_workers_launched AS parallel_workers_launched_before
FROM
    pg_stat_database
WHERE
    datname = current_database() \gset

CREATE FUNCTION sp_parallel_restricted (int)
    RETURNS int
    AS $$
BEGIN
    RETURN $1;
END
$$
LANGUAGE plpgsql
parallel restricted;

BEGIN;
-- encourage use of parallel plans
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
-- Parallel Append with partial-subplans
EXPLAIN (
    COSTS OFF
)
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star;
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star a1;
-- Parallel Append with both partial and non-partial subplans
ALTER TABLE c_star SET (parallel_workers = 0);
ALTER TABLE d_star SET (parallel_workers = 0);
EXPLAIN (
    COSTS OFF
)
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star;
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star a2;
-- Parallel Append with only non-partial subplans
ALTER TABLE a_star SET (parallel_workers = 0);
ALTER TABLE b_star SET (parallel_workers = 0);
ALTER TABLE e_star SET (parallel_workers = 0);
ALTER TABLE f_star SET (parallel_workers = 0);
EXPLAIN (
    COSTS OFF
)
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star;
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star a3;
-- Disable Parallel Append
ALTER TABLE a_star RESET (parallel_workers);
ALTER TABLE b_star RESET (parallel_workers);
ALTER TABLE c_star RESET (parallel_workers);
ALTER TABLE d_star RESET (parallel_workers);
ALTER TABLE e_star RESET (parallel_workers);
ALTER TABLE f_star RESET (parallel_workers);
SET enable_parallel_append TO OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star;
SELECT
    round(avg(aa)),
    sum(aa)
FROM
    a_star a4;
RESET enable_parallel_append;
-- Parallel Append that runs serially
CREATE FUNCTION sp_test_func ()
    RETURNS SETOF text
    AS $$
    SELECT
        'foo'::varchar
    UNION ALL
    SELECT
        'bar'::varchar
$$
LANGUAGE sql
STABLE;
SELECT
    sp_test_func ()
ORDER BY
    1;
-- Parallel Append is not to be used when the subpath depends on the outer param
CREATE TABLE part_pa_test (
    a int,
    b int
)
PARTITION BY RANGE (a);
CREATE TABLE part_pa_test_p1 PARTITION OF part_pa_test
FOR VALUES FROM (MINVALUE) TO (0);
CREATE TABLE part_pa_test_p2 PARTITION OF part_pa_test
FOR VALUES FROM (0) TO (MAXVALUE);
EXPLAIN (
    COSTS OFF
)
SELECT
    (
        SELECT
            max((
                SELECT
                    pa1.b
                FROM part_pa_test pa1
                WHERE
                    pa1.a = pa2.a)))
FROM
    part_pa_test pa2;
DROP TABLE part_pa_test;
-- test with leader participation disabled
SET parallel_leader_participation = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
WHERE
    stringu1 = 'GRAAAA';
SELECT
    count(*)
FROM
    tenk1
WHERE
    stringu1 = 'GRAAAA';
-- test with leader participation disabled, but no workers available (so
-- the leader will have to run the plan despite the setting)
SET max_parallel_workers = 0;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
WHERE
    stringu1 = 'GRAAAA';
SELECT
    count(*)
FROM
    tenk1
WHERE
    stringu1 = 'GRAAAA';
RESET max_parallel_workers;
RESET parallel_leader_participation;
-- test that parallel_restricted function doesn't run in worker
ALTER TABLE tenk1 SET (parallel_workers = 4);
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    sp_parallel_restricted (unique1)
FROM
    tenk1
WHERE
    stringu1 = 'GRAAAA'
ORDER BY
    1;
-- test parallel plan when group by expression is in target list.
EXPLAIN (
    COSTS OFF
)
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
EXPLAIN (
    COSTS OFF
)
SELECT
    stringu1,
    count(*)
FROM
    tenk1
GROUP BY
    stringu1
ORDER BY
    stringu1;
-- test that parallel plan for aggregates is not selected when
-- target list contains parallel restricted clause.
EXPLAIN (
    COSTS OFF
)
SELECT
    sum(sp_parallel_restricted (unique1))
FROM
    tenk1
GROUP BY
    (sp_parallel_restricted (unique1));
-- test prepared statement
PREPARE tenk1_count (integer) AS
SELECT
    count(unique1)
FROM
    tenk1
WHERE
    hundred > $1;
EXPLAIN (
    COSTS OFF
) EXECUTE tenk1_count (1);
EXECUTE tenk1_count (1);
DEALLOCATE tenk1_count;
-- test parallel plans for queries containing un-correlated subplans.
ALTER TABLE tenk2 SET (parallel_workers = 0);
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
WHERE (two, four)
NOT IN (
    SELECT
        hundred,
        thousand
    FROM
        tenk2
    WHERE
        thousand > 100);
SELECT
    count(*)
FROM
    tenk1
WHERE (two, four)
NOT IN (
    SELECT
        hundred,
        thousand
    FROM
        tenk2
    WHERE
        thousand > 100);
-- this is not parallel-safe due to use of random() within SubLink's testexpr:
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
WHERE (unique1 + random())::integer NOT IN (
    SELECT
        ten
    FROM
        tenk2);
ALTER TABLE tenk2 RESET (parallel_workers);
-- test parallel plan for a query containing initplan.
SET enable_indexscan = OFF;
SET enable_indexonlyscan = OFF;
SET enable_bitmapscan = OFF;
ALTER TABLE tenk2 SET (parallel_workers = 2);
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
WHERE
    tenk1.unique1 = (
        SELECT
            max(tenk2.unique1)
        FROM
            tenk2);
SELECT
    count(*)
FROM
    tenk1
WHERE
    tenk1.unique1 = (
        SELECT
            max(tenk2.unique1)
        FROM
            tenk2);
RESET enable_indexscan;
RESET enable_indexonlyscan;
RESET enable_bitmapscan;
ALTER TABLE tenk2 RESET (parallel_workers);
-- test parallel index scans.
SET enable_seqscan TO OFF;
SET enable_bitmapscan TO OFF;
SET random_page_cost = 2;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(unique1)
FROM
    tenk1
WHERE
    hundred > 1;
SELECT
    count(unique1)
FROM
    tenk1
WHERE
    hundred > 1;
-- Parallel ScalarArrayOp index scan
EXPLAIN (
    COSTS OFF
)
SELECT
    count(unique1)
FROM
    tenk1
WHERE
    hundred = ANY ((
            SELECT
                array_agg(i)
            FROM
                generate_series(1, 100, 15) i)::int[]);
SELECT
    count(unique1)
FROM
    tenk1
WHERE
    hundred = ANY ((
            SELECT
                array_agg(i)
            FROM
                generate_series(1, 100, 15) i)::int[]);
-- test parallel index-only scans.
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
WHERE
    thousand > 95;
SELECT
    count(*)
FROM
    tenk1
WHERE
    thousand > 95;
-- test rescan cases too
SET enable_material = FALSE;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        count(unique1)
    FROM
        tenk1
    WHERE
        hundred > 10) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
SELECT
    *
FROM (
    SELECT
        count(unique1)
    FROM
        tenk1
    WHERE
        hundred > 10) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        count(*)
    FROM
        tenk1
    WHERE
        thousand > 99) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
SELECT
    *
FROM (
    SELECT
        count(*)
    FROM
        tenk1
    WHERE
        thousand > 99) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
-- test rescans for a Limit node with a parallel node beneath it.
RESET enable_seqscan;
SET enable_indexonlyscan TO OFF;
SET enable_indexscan TO OFF;
ALTER TABLE tenk1 SET (parallel_workers = 0);
ALTER TABLE tenk2 SET (parallel_workers = 1);
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
    LEFT JOIN (
        SELECT
            tenk2.unique1
        FROM
            tenk2
        ORDER BY
            1
        LIMIT 1000) ss ON tenk1.unique1 < ss.unique1 + 1
WHERE
    tenk1.unique1 < 2;
SELECT
    count(*)
FROM
    tenk1
    LEFT JOIN (
        SELECT
            tenk2.unique1
        FROM
            tenk2
        ORDER BY
            1
        LIMIT 1000) ss ON tenk1.unique1 < ss.unique1 + 1
WHERE
    tenk1.unique1 < 2;
--reset the value of workers for each table as it was before this test.
ALTER TABLE tenk1 SET (parallel_workers = 4);
ALTER TABLE tenk2 RESET (parallel_workers);
RESET enable_material;
RESET enable_bitmapscan;
RESET enable_indexonlyscan;
RESET enable_indexscan;
-- test parallel bitmap heap scan.
SET enable_seqscan TO OFF;
SET enable_indexscan TO OFF;
SET enable_hashjoin TO OFF;
SET enable_mergejoin TO OFF;
SET enable_material TO OFF;
-- test prefetching, if the platform allows it
DO $$
BEGIN
    SET effective_io_concurrency = 50;
EXCEPTION
    WHEN invalid_parameter_value THEN
END
$$;
SET work_mem = '64kB';
--set small work mem to force lossy pages
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1,
    tenk2
WHERE
    tenk1.hundred > 1
    AND tenk2.thousand = 0;
SELECT
    count(*)
FROM
    tenk1,
    tenk2
WHERE
    tenk1.hundred > 1
    AND tenk2.thousand = 0;
CREATE TABLE bmscantest (
    a int,
    t text
);
INSERT INTO bmscantest
SELECT
    r,
    'fooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo'
FROM
    generate_series(1, 100000) r;
CREATE INDEX i_bmtest ON bmscantest (a);
SELECT
    count(*)
FROM
    bmscantest
WHERE
    a > 1;
-- test accumulation of stats for parallel nodes
RESET enable_seqscan;
ALTER TABLE tenk2 SET (parallel_workers = 0);
EXPLAIN (
    ANALYZE,
    timing OFF,
    summary OFF,
    COSTS OFF,
    buffers OFF
)
SELECT
    count(*)
FROM
    tenk1,
    tenk2
WHERE
    tenk1.hundred > 1
    AND tenk2.thousand = 0;
ALTER TABLE tenk2 RESET (parallel_workers);
RESET work_mem;
CREATE FUNCTION explain_parallel_sort_stats ()
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE
    ln text;
BEGIN
    FOR ln IN EXPLAIN (
        ANALYZE,
        timing OFF,
        summary OFF,
        COSTS OFF,
        buffers OFF
)
    SELECT
        *
    FROM (
        SELECT
            ten
        FROM
            tenk1
        WHERE
            ten < 100
        ORDER BY
            ten) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE LOOP
    ln := regexp_replace(ln, 'Memory: \S*', 'Memory: xxx');
        RETURN NEXT ln;
    END LOOP;
END;
$$;
SELECT
    *
FROM
    explain_parallel_sort_stats ();
RESET enable_indexscan;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_material;
RESET effective_io_concurrency;
DROP TABLE bmscantest;
DROP FUNCTION explain_parallel_sort_stats ();
-- test parallel merge join path.
SET enable_hashjoin TO OFF;
SET enable_nestloop TO OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1,
    tenk2
WHERE
    tenk1.unique1 = tenk2.unique1;
SELECT
    count(*)
FROM
    tenk1,
    tenk2
WHERE
    tenk1.unique1 = tenk2.unique1;
RESET enable_hashjoin;
RESET enable_nestloop;
-- test parallel nestloop join path with materialization of the inner path
ALTER TABLE tenk2 SET (parallel_workers = 0);
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1,
    tenk2 t2
WHERE
    t1.two > t2.two;
-- test that parallel nestloop join is not generated if the inner path is
-- not parallel-safe
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 t1
    LEFT JOIN LATERAL (
        SELECT
            t1.unique1 AS x,
            *
        FROM
            tenk2 t2
        ORDER BY
            1) t2 ON TRUE
WHERE
    t1.two > t2.two;
ALTER TABLE tenk2 RESET (parallel_workers);
-- test gather merge
SET enable_hashagg = FALSE;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
GROUP BY
    twenty;
SELECT
    count(*)
FROM
    tenk1
GROUP BY
    twenty;
--test expressions in targetlist are pushed down for gather merge
CREATE FUNCTION sp_simple_func (var1 integer)
    RETURNS integer
    AS $$
BEGIN
    RETURN var1 + 10;
END;
$$
LANGUAGE plpgsql
PARALLEL SAFE;
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    ten,
    sp_simple_func (ten)
FROM
    tenk1
WHERE
    ten < 100
ORDER BY
    ten;
DROP FUNCTION sp_simple_func (integer);
-- test handling of SRFs in targetlist (bug in 10.0)
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*),
    generate_series(1, 2)
FROM
    tenk1
GROUP BY
    twenty;
SELECT
    count(*),
    generate_series(1, 2)
FROM
    tenk1
GROUP BY
    twenty;
-- test gather merge with parallel leader participation disabled
SET parallel_leader_participation = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
GROUP BY
    twenty;
SELECT
    count(*)
FROM
    tenk1
GROUP BY
    twenty;
RESET parallel_leader_participation;
--test rescan behavior of gather merge
SET enable_material = FALSE;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        string4,
        count(unique2)
    FROM
        tenk1
    GROUP BY
        string4
    ORDER BY
        string4) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
SELECT
    *
FROM (
    SELECT
        string4,
        count(unique2)
    FROM
        tenk1
    GROUP BY
        string4
    ORDER BY
        string4) ss
    RIGHT JOIN (
        VALUES (1),
            (2),
            (3)) v (x) ON TRUE;
RESET enable_material;
RESET enable_hashagg;
-- check parallelized int8 aggregate (bug #14897)
EXPLAIN (
    COSTS OFF
)
SELECT
    avg(unique1::int8)
FROM
    tenk1;
SELECT
    avg(unique1::int8)
FROM
    tenk1;
-- gather merge test with a LIMIT
EXPLAIN (
    COSTS OFF
)
SELECT
    fivethous
FROM
    tenk1
ORDER BY
    fivethous
LIMIT 4;
SELECT
    fivethous
FROM
    tenk1
ORDER BY
    fivethous
LIMIT 4;
-- gather merge test with 0 worker
SET max_parallel_workers = 0;
EXPLAIN (
    COSTS OFF
)
SELECT
    string4
FROM
    tenk1
ORDER BY
    string4
LIMIT 5;
SELECT
    string4
FROM
    tenk1
ORDER BY
    string4
LIMIT 5;
-- gather merge test with 0 workers, with parallel leader
-- participation disabled (the leader will have to run the plan
-- despite the setting)
SET parallel_leader_participation = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    string4
FROM
    tenk1
ORDER BY
    string4
LIMIT 5;
SELECT
    string4
FROM
    tenk1
ORDER BY
    string4
LIMIT 5;
RESET parallel_leader_participation;
RESET max_parallel_workers;
CREATE FUNCTION parallel_safe_volatile (a int)
    RETURNS int
    AS $$
BEGIN
    RETURN a;
END;
$$ parallel safe VOLATILE
LANGUAGE plpgsql;
-- Test gather merge atop of a sort of a partial path
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
WHERE
    four = 2
ORDER BY
    four,
    hundred,
    parallel_safe_volatile (thousand);
-- Test gather merge atop of an incremental sort a of partial path
SET min_parallel_index_scan_size = 0;
SET enable_seqscan = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1
WHERE
    four = 2
ORDER BY
    four,
    hundred,
    parallel_safe_volatile (thousand);
RESET min_parallel_index_scan_size;
RESET enable_seqscan;
-- Test GROUP BY with a gather merge path atop of a sort of a partial path
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1
GROUP BY
    twenty,
    parallel_safe_volatile (two);
DROP FUNCTION parallel_safe_volatile (int);
SAVEPOINT settings;
SET LOCAL debug_parallel_query = 1;
EXPLAIN (
    COSTS OFF
)
SELECT
    stringu1::int2
FROM
    tenk1
WHERE
    unique1 = 1;
ROLLBACK TO SAVEPOINT settings;

-- exercise record typmod remapping between backends
CREATE FUNCTION make_record (n int)
    RETURNS RECORD
    LANGUAGE plpgsql
    PARALLEL SAFE
    AS $$
BEGIN
    RETURN CASE n
    WHEN 1 THEN
        ROW (1)
    WHEN 2 THEN
        ROW (1,
            2)
    WHEN 3 THEN
        ROW (1,
            2,
            3)
    WHEN 4 THEN
        ROW (1,
            2,
            3,
            4)
    ELSE
        ROW (1,
            2,
            3,
            4,
            5)
    END;
END;
$$;

SAVEPOINT settings;

SET LOCAL debug_parallel_query = 1;

SELECT
    make_record (x)
FROM (
    SELECT
        generate_series(1, 5) x) ss
ORDER BY
    x;

ROLLBACK TO SAVEPOINT settings;

DROP FUNCTION make_record (n int);

-- test the sanity of parallel query after the active role is dropped.
DROP ROLE IF EXISTS regress_parallel_worker;

CREATE ROLE regress_parallel_worker;

SET ROLE regress_parallel_worker;

RESET session AUTHORIZATION;

DROP ROLE regress_parallel_worker;

SET debug_parallel_query = 1;

SELECT
    count(*)
FROM
    tenk1;

RESET debug_parallel_query;

RESET ROLE;

-- Window function calculation can't be pushed to workers.
EXPLAIN (
    COSTS OFF,
    VERBOSE
)
SELECT
    count(*)
FROM
    tenk1 a
WHERE (unique1, two) IN (
    SELECT
        unique1,
        row_number() OVER ()
    FROM tenk1 b);

-- LIMIT/OFFSET within sub-selects can't be pushed to workers.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    tenk1 a
WHERE
    two IN (
        SELECT
            two
        FROM
            tenk1 b
        WHERE
            stringu1 LIKE '%AAAA'
        LIMIT 3);

-- to increase the parallel query test coverage
SAVEPOINT settings;

SET LOCAL debug_parallel_query = 1;

EXPLAIN (
    ANALYZE,
    timing OFF,
    summary OFF,
    COSTS OFF,
    buffers OFF
)
SELECT
    *
FROM
    tenk1;

ROLLBACK TO SAVEPOINT settings;

-- provoke error in worker
-- (make the error message long enough to require multiple bufferloads)
SAVEPOINT settings;

SET LOCAL debug_parallel_query = 1;

SELECT
    (stringu1 || repeat('abcd', 5000))::int2
FROM
    tenk1
WHERE
    unique1 = 1;

ROLLBACK TO SAVEPOINT settings;

-- test interaction with set-returning functions
SAVEPOINT settings;

-- multiple subqueries under a single Gather node
-- must set parallel_setup_cost > 0 to discourage multiple Gather nodes
SET LOCAL parallel_setup_cost = 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1
WHERE
    fivethous = tenthous + 1
UNION ALL
SELECT
    unique1
FROM
    tenk1
WHERE
    fivethous = tenthous + 1;

ROLLBACK TO SAVEPOINT settings;

-- can't use multiple subqueries under a single Gather node due to initPlans
EXPLAIN (
    COSTS OFF
)
SELECT
    unique1
FROM
    tenk1
WHERE
    fivethous = (
        SELECT
            unique1
        FROM
            tenk1
        WHERE
            fivethous = 1
        LIMIT 1)
UNION ALL
SELECT
    unique1
FROM
    tenk1
WHERE
    fivethous = (
        SELECT
            unique2
        FROM
            tenk1
        WHERE
            fivethous = 1
        LIMIT 1)
ORDER BY
    1;

-- test interaction with SRFs
SELECT
    *
FROM
    information_schema.foreign_data_wrapper_options
ORDER BY
    1,
    2,
    3;

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    generate_series(1, two),
    ARRAY(
        SELECT
            generate_series(1, two))
FROM
    tenk1
ORDER BY
    tenthous;

-- must disallow pushing sort below gather when pathkey contains an SRF
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    unnest(ARRAY[]::integer[]) + 1 AS pathkey
FROM
    tenk1 t1
    JOIN tenk1 t2 ON TRUE
ORDER BY
    pathkey;

-- test passing expanded-value representations to workers
CREATE FUNCTION make_some_array (int, int)
    RETURNS int[]
    AS $$
DECLARE
    x int[];
BEGIN
    x[1] := $1;
    x[2] := $2;
    RETURN x;
END
$$
LANGUAGE plpgsql
parallel safe;

CREATE TABLE fooarr (
    f1 text,
    f2 int[],
    f3 text
);

INSERT INTO fooarr
    VALUES ('1', ARRAY[1, 2], 'one');

PREPARE pstmt (text, int[]) AS
SELECT
    *
FROM
    fooarr
WHERE
    f1 = $1
    AND f2 = $2;

EXPLAIN (
    COSTS OFF
) EXECUTE pstmt ('1', make_some_array (1, 2));

EXECUTE pstmt ('1', make_some_array (1, 2));

DEALLOCATE pstmt;

-- test interaction between subquery and partial_paths
CREATE VIEW tenk1_vw_sec WITH ( security_barrier
) AS
SELECT
    *
FROM
    tenk1;

EXPLAIN (
    COSTS OFF
)
SELECT
    1
FROM
    tenk1_vw_sec
WHERE (
    SELECT
        sum(f1)
    FROM
        int4_tbl
    WHERE
        f1 < unique1) < 100;

ROLLBACK;

-- test that a newly-created session role propagates to workers.
BEGIN;
CREATE ROLE regress_parallel_worker;
SET session AUTHORIZATION regress_parallel_worker;
SELECT
    current_setting('session_authorization');
SET debug_parallel_query = 1;
SELECT
    current_setting('session_authorization');
ROLLBACK;

-- test that function option SET ROLE works in parallel workers.
CREATE ROLE regress_parallel_worker;

CREATE FUNCTION set_and_report_role ()
    RETURNS text
    AS $$
    SELECT
        current_setting('role')
$$
LANGUAGE sql
parallel safe SET ROLE = regress_parallel_worker;

CREATE FUNCTION set_role_and_error (int)
    RETURNS int
    AS $$
    SELECT
        1 / $1
$$
LANGUAGE sql
parallel safe SET ROLE = regress_parallel_worker;

SET debug_parallel_query = 0;

SELECT
    set_and_report_role ();

SELECT
    set_role_and_error (0);

SET debug_parallel_query = 1;

SELECT
    set_and_report_role ();

SELECT
    set_role_and_error (0);

RESET debug_parallel_query;

DROP FUNCTION set_and_report_role ();

DROP FUNCTION set_role_and_error (int);

DROP ROLE regress_parallel_worker;

-- don't freeze in ParallelFinish while holding an LWLock
BEGIN;
CREATE FUNCTION my_cmp (int4, int4)
    RETURNS int
    LANGUAGE sql
    AS $$
    SELECT
        CASE WHEN $1 < $2 THEN
            -1
        WHEN $1 > $2 THEN
            1
        ELSE
            0
        END;
$$;
CREATE TABLE parallel_hang (
    i int4
);
INSERT INTO parallel_hang (
    SELECT
        *
    FROM
        generate_series(1, 400) gs);
CREATE OPERATOR CLASS int4_custom_ops FOR TYPE int4
    USING btree AS
    OPERATOR 1 < (int4, int4),
    OPERATOR 2 <= (int4, int4),
    OPERATOR 3 = (int4, int4),
    OPERATOR 4 >= (int4, int4),
    OPERATOR 5 > (int4, int4),
    FUNCTION 1 my_cmp (int4, int4
);
CREATE UNIQUE INDEX parallel_hang_idx ON parallel_hang USING btree (i int4_custom_ops);
SET debug_parallel_query = ON;
DELETE FROM parallel_hang
WHERE 380 <= i
    AND i <= 420;
ROLLBACK;

-- Check parallel worker stats
SELECT
    pg_stat_force_next_flush ();

SELECT
    parallel_workers_to_launch > :'parallel_workers_to_launch_before' AS wrk_to_launch,
    parallel_workers_launched > :'parallel_workers_launched_before' AS wrk_launched
FROM
    pg_stat_database
WHERE
    datname = current_database();

