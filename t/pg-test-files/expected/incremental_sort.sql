-- When there is a LIMIT clause, incremental sort is beneficial because
-- it only has to sort some of the groups, and not the entire table.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        four) t
ORDER BY
    four,
    ten
LIMIT 1;

-- When work_mem is not enough to sort the entire table, incremental sort
-- may be faster if individual groups still fit into work_mem.
SET work_mem TO '2MB';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        four) t
ORDER BY
    four,
    ten;

RESET work_mem;

CREATE TABLE t (
    a integer,
    b integer
);

CREATE OR REPLACE FUNCTION explain_analyze_without_memory (query text)
    RETURNS TABLE (
        out_line text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    line text;
BEGIN
    FOR line IN EXECUTE 'explain (analyze, costs off, summary off, timing off, buffers off) ' || query LOOP
        out_line := regexp_replace(line, '\d+kB', 'NNkB', 'g');
        RETURN NEXT;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION explain_analyze_inc_sort_nodes (query text)
    RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    elements jsonb;
    element jsonb;
    matching_nodes jsonb := '[]'::jsonb;
BEGIN
    EXECUTE 'explain (analyze, costs off, summary off, timing off, buffers off, format ''json'') ' || query INTO STRICT elements;
    WHILE jsonb_array_length(elements) > 0 LOOP
        element := elements -> 0;
        elements := elements - 0;
        CASE jsonb_typeof(element)
        WHEN 'array' THEN
            IF jsonb_array_length(element) > 0 THEN
                    elements := elements || element;
                END IF;
        WHEN 'object' THEN
            IF element ? 'Plan' THEN
                elements := elements || jsonb_build_array(element -> 'Plan');
                element := element - 'Plan';
            ELSE
                IF element ? 'Plans' THEN
                    elements := elements || jsonb_build_array(element -> 'Plans');
                    element := element - 'Plans';
                END IF;
                IF (element ->> 'Node Type')::text = 'Incremental Sort' THEN
                    matching_nodes := matching_nodes || element;
                END IF;
            END IF;
        END CASE;
    END LOOP;
    RETURN matching_nodes;
END;
$$;

CREATE OR REPLACE FUNCTION explain_analyze_inc_sort_nodes_without_memory (query text)
    RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    nodes jsonb := '[]'::jsonb;
    node jsonb;
    group_key text;
    space_key text;
BEGIN
    FOR node IN
    SELECT
        *
    FROM
        jsonb_array_elements(explain_analyze_inc_sort_nodes (query)) t LOOP
        FOR group_key IN
        SELECT
            unnest(ARRAY['Full-sort Groups', 'Pre-sorted Groups']::text[]) t LOOP
        FOR space_key IN
        SELECT
            unnest(ARRAY['Sort Space Memory', 'Sort Space Disk']::text[]) t LOOP
        node := jsonb_set(node, ARRAY[group_key, space_key, 'Average Sort Space Used'], '"NN"', FALSE);
        node := jsonb_set(node, ARRAY[group_key, space_key, 'Peak Sort Space Used'], '"NN"', FALSE);
    END LOOP;
    END LOOP;
        nodes := nodes || node;
    END LOOP;
    RETURN nodes;
END;
$$;

CREATE OR REPLACE FUNCTION explain_analyze_inc_sort_nodes_verify_invariants (query text)
    RETURNS bool
    LANGUAGE plpgsql
    AS $$
DECLARE
    node jsonb;
    group_stats jsonb;
    group_key text;
    space_key text;
BEGIN
    FOR node IN
    SELECT
        *
    FROM
        jsonb_array_elements(explain_analyze_inc_sort_nodes (query)) t LOOP
        FOR group_key IN
        SELECT
            unnest(ARRAY['Full-sort Groups', 'Pre-sorted Groups']::text[]) t LOOP
        group_stats := node -> group_key;
        FOR space_key IN
        SELECT
            unnest(ARRAY['Sort Space Memory', 'Sort Space Disk']::text[]) t LOOP
                IF (group_stats -> space_key -> 'Peak Sort Space Used')::bigint < (group_stats -> space_key -> 'Peak Sort Space Used')::bigint THEN
                    RAISE EXCEPTION '% has invalid max space < average space', group_key;
                END IF;
            END LOOP;
    END LOOP;
    END LOOP;
    RETURN TRUE;
END;
$$;

-- A single large group tested around each mode transition point.
INSERT INTO t (a, b)
SELECT
    i / 100 + 1,
    i + 1
FROM
    generate_series(0, 999) n (i);

ANALYZE t;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

DELETE FROM t;

-- An initial large group followed by a small group.
INSERT INTO t (a, b)
SELECT
    i / 50 + 1,
    i + 1
FROM
    generate_series(0, 999) n (i);

ANALYZE t;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 55;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 55;

-- Test EXPLAIN ANALYZE with only a fullsort group.
SELECT
    explain_analyze_without_memory ('select * from (select * from t order by a) s order by a, b limit 55');

SELECT
    jsonb_pretty(explain_analyze_inc_sort_nodes_without_memory ('select * from (select * from t order by a) s order by a, b limit 55'));

SELECT
    explain_analyze_inc_sort_nodes_verify_invariants ('select * from (select * from t order by a) s order by a, b limit 55');

DELETE FROM t;

-- An initial small group followed by a large group.
INSERT INTO t (a, b)
SELECT
    (
        CASE WHEN i < 5 THEN
            i
        ELSE
            9
        END),
    i
FROM
    generate_series(1, 1000) n (i);

ANALYZE t;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 70;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 70;

-- Checks case where we hit a group boundary at the last tuple of a batch.
-- Because the full sort state is bounded, we scan 64 tuples (the mode
-- transition point) but only retain 5. Thus when we transition modes, all
-- tuples in the full sort state have different prefix keys.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 5;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 5;

-- Test rescan.
BEGIN;
-- We force the planner to choose a plan with incremental sort on the right side
-- of a nested loop join node. That way we trigger the rescan code path.
SET local enable_hashjoin = OFF;
SET local enable_mergejoin = OFF;
SET local enable_material = OFF;
SET local enable_sort = OFF;
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t
    LEFT JOIN (
        SELECT
            *
        FROM (
            SELECT
                *
            FROM
                t
            ORDER BY
                a) v
        ORDER BY
            a,
            b) s ON s.a = t.a
WHERE
    t.a IN (1, 2);
SELECT
    *
FROM
    t
    LEFT JOIN (
        SELECT
            *
        FROM (
            SELECT
                *
            FROM
                t
            ORDER BY
                a) v
        ORDER BY
            a,
            b) s ON s.a = t.a
WHERE
    t.a IN (1, 2);
ROLLBACK;

-- Test EXPLAIN ANALYZE with both fullsort and presorted groups.
SELECT
    explain_analyze_without_memory ('select * from (select * from t order by a) s order by a, b limit 70');

SELECT
    jsonb_pretty(explain_analyze_inc_sort_nodes_without_memory ('select * from (select * from t order by a) s order by a, b limit 70'));

SELECT
    explain_analyze_inc_sort_nodes_verify_invariants ('select * from (select * from t order by a) s order by a, b limit 70');

DELETE FROM t;

-- Small groups of 10 tuples each tested around each mode transition point.
INSERT INTO t (a, b)
SELECT
    i / 10,
    i
FROM
    generate_series(1, 1000) n (i);

ANALYZE t;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

DELETE FROM t;

-- Small groups of only 1 tuple each tested around each mode transition point.
INSERT INTO t (a, b)
SELECT
    i,
    i
FROM
    generate_series(1, 1000) n (i);

ANALYZE t;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 31;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 32;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 33;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 65;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        t
    ORDER BY
        a) s
ORDER BY
    a,
    b
LIMIT 66;

DELETE FROM t;

DROP TABLE t;

-- Incremental sort vs. parallel queries
SET min_parallel_table_scan_size = '1kB';

SET min_parallel_index_scan_size = '1kB';

SET parallel_setup_cost = 0;

SET parallel_tuple_cost = 0;

SET max_parallel_workers_per_gather = 2;

CREATE TABLE t (
    a int,
    b int,
    c int
);

INSERT INTO t
SELECT
    mod(i, 10),
    mod(i, 10),
    i
FROM
    generate_series(1, 10000) s (i);

CREATE INDEX ON t (a);

ANALYZE t;

SET enable_incremental_sort = OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(c)
FROM
    t
GROUP BY
    1,
    2
ORDER BY
    1,
    2,
    3
LIMIT 1;

SET enable_incremental_sort = ON;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    sum(c)
FROM
    t
GROUP BY
    1,
    2
ORDER BY
    1,
    2,
    3
LIMIT 1;

-- Incremental sort vs. set operations with varno 0
SET enable_hashagg TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    t
UNION
SELECT
    *
FROM
    t
ORDER BY
    1,
    3;

-- Full sort, not just incremental sort can be pushed below a gather merge path
-- by generate_useful_gather_paths.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    a,
    b
FROM
    t;

DROP TABLE t;

-- Sort pushdown can't go below where expressions are part of the rel target.
-- In particular this is interesting for volatile expressions which have to
-- go above joins since otherwise we'll incorrectly use expression evaluations
-- across multiple rows.
SET enable_hashagg = OFF;

SET enable_seqscan = OFF;

SET enable_incremental_sort = OFF;

SET parallel_tuple_cost = 0;

SET parallel_setup_cost = 0;

SET min_parallel_table_scan_size = 0;

SET min_parallel_index_scan_size = 0;

-- Parallel sort below join.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    sub.unique1,
    stringu1
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub;

EXPLAIN (
    COSTS OFF
)
SELECT
    sub.unique1,
    stringu1
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub
ORDER BY
    1,
    2;

-- Parallel sort but with expression that can be safely generated at the base rel.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    sub.unique1,
    md5(stringu1)
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub;

EXPLAIN (
    COSTS OFF
)
SELECT
    sub.unique1,
    md5(stringu1)
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub
ORDER BY
    1,
    2;

-- Parallel sort with an aggregate that can be safely generated in parallel,
-- but we can't sort by partial aggregate values.
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    tenk1 t1
    JOIN tenk1 t2 ON t1.unique1 = t2.unique2
    JOIN tenk1 t3 ON t2.unique1 = t3.unique1
ORDER BY
    count(*);

-- Parallel sort but with expression (correlated subquery) that
-- is prohibited in parallel plans.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    unique1,
    (
        SELECT
            t.unique1
        FROM
            tenk1
        WHERE
            tenk1.unique1 = t.unique1)
FROM
    tenk1 t,
    generate_series(1, 1000);

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    (
        SELECT
            t.unique1
        FROM
            tenk1
        WHERE
            tenk1.unique1 = t.unique1)
FROM
    tenk1 t,
    generate_series(1, 1000)
ORDER BY
    1,
    2;

-- Parallel sort but with expression not available until the upper rel.
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    sub.unique1,
    stringu1 || random()::text
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub;

EXPLAIN (
    COSTS OFF
)
SELECT
    sub.unique1,
    stringu1 || random()::text
FROM
    tenk1,
    LATERAL (
        SELECT
            tenk1.unique1
        FROM
            generate_series(1, 1000)) AS sub
ORDER BY
    1,
    2;

RESET enable_hashagg;

RESET enable_seqscan;

RESET enable_incremental_sort;

RESET parallel_tuple_cost;

RESET parallel_setup_cost;

RESET min_parallel_table_scan_size;

RESET min_parallel_index_scan_size;

-- Ensure incremental sorts work for amcanorderbyop type indexes
CREATE TABLE point_table (
    a point,
    b int
);

CREATE INDEX point_table_a_idx ON point_table USING gist (a);

-- Ensure we get an incremental sort plan for both of the following queries
EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    a <-> point(5, 5) dist
FROM
    point_table
ORDER BY
    dist,
    b
LIMIT 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    a,
    b,
    a <-> point(5, 5) dist
FROM
    point_table
ORDER BY
    dist,
    b DESC
LIMIT 1;

-- Ensure we get an incremental sort on the outer side of the mergejoin
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        four) t1
    JOIN tenk1 t2 ON t1.four = t2.four
        AND t1.two = t2.two
    ORDER BY
        t1.four,
        t1.two
    LIMIT 1;

--
-- Test incremental sort for Append/MergeAppend
--
CREATE TABLE prt_tbl (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE prt_tbl_1 PARTITION OF prt_tbl
FOR VALUES FROM (0) TO (100);

CREATE TABLE prt_tbl_2 PARTITION OF prt_tbl
FOR VALUES FROM (100) TO (200);

INSERT INTO prt_tbl
SELECT
    i % 200,
    i
FROM
    generate_series(1, 1000) i;

CREATE INDEX ON prt_tbl_1 (a);

CREATE INDEX ON prt_tbl_2 (a, b);

ANALYZE prt_tbl;

SET enable_seqscan TO OFF;

SET enable_bitmapscan TO OFF;

-- Ensure we get an incremental sort for the subpath of Append
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    prt_tbl
ORDER BY
    a,
    b;

-- Ensure we get an incremental sort for the subpath of MergeAppend
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    prt_tbl_1
UNION ALL
SELECT
    *
FROM
    prt_tbl_2
ORDER BY
    a,
    b;

RESET enable_bitmapscan;

RESET enable_seqscan;

DROP TABLE prt_tbl;

