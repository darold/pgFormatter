--
-- BTREE_INDEX
--
-- directory paths are passed to us in environment variables
\getenv abs_srcdir PG_ABS_SRCDIR

CREATE TABLE bt_i4_heap (
    seqno int4,
    random int4
);

CREATE TABLE bt_name_heap (
    seqno name,
    random int4
);

CREATE TABLE bt_txt_heap (
    seqno text,
    random int4
);

CREATE TABLE bt_f8_heap (
    seqno float8,
    random int4
);

\set filename :abs_srcdir '/data/desc.data'
COPY bt_i4_heap
FROM
    :'filename';

\set filename :abs_srcdir '/data/hash.data'
COPY bt_name_heap
FROM
    :'filename';

\set filename :abs_srcdir '/data/desc.data'
COPY bt_txt_heap
FROM
    :'filename';

\set filename :abs_srcdir '/data/hash.data'
COPY bt_f8_heap
FROM
    :'filename';

ANALYZE bt_i4_heap;

ANALYZE bt_name_heap;

ANALYZE bt_txt_heap;

ANALYZE bt_f8_heap;

--
-- BTREE ascending/descending cases
--
-- we load int4/text from pure descending data (each key is a new
-- low key) and name/f8 from pure ascending data (each key is a new
-- high key).  we had a bug where new low keys would sometimes be
-- "lost".
--
CREATE INDEX bt_i4_index ON bt_i4_heap USING btree (seqno int4_ops);

CREATE INDEX bt_name_index ON bt_name_heap USING btree (seqno name_ops);

CREATE INDEX bt_txt_index ON bt_txt_heap USING btree (seqno text_ops);

CREATE INDEX bt_f8_index ON bt_f8_heap USING btree (seqno float8_ops);

--
-- test retrieval of min/max keys for each index
--
SELECT
    b.*
FROM
    bt_i4_heap b
WHERE
    b.seqno < 1;

SELECT
    b.*
FROM
    bt_i4_heap b
WHERE
    b.seqno >= 9999;

SELECT
    b.*
FROM
    bt_i4_heap b
WHERE
    b.seqno = 4500;

SELECT
    b.*
FROM
    bt_name_heap b
WHERE
    b.seqno < '1'::name;

SELECT
    b.*
FROM
    bt_name_heap b
WHERE
    b.seqno >= '9999'::name;

SELECT
    b.*
FROM
    bt_name_heap b
WHERE
    b.seqno = '4500'::name;

SELECT
    b.*
FROM
    bt_txt_heap b
WHERE
    b.seqno < '1'::text;

SELECT
    b.*
FROM
    bt_txt_heap b
WHERE
    b.seqno >= '9999'::text;

SELECT
    b.*
FROM
    bt_txt_heap b
WHERE
    b.seqno = '4500'::text;

SELECT
    b.*
FROM
    bt_f8_heap b
WHERE
    b.seqno < '1'::float8;

SELECT
    b.*
FROM
    bt_f8_heap b
WHERE
    b.seqno >= '9999'::float8;

SELECT
    b.*
FROM
    bt_f8_heap b
WHERE
    b.seqno = '4500'::float8;

--
-- Add coverage of RowCompare quals whose row omits a column ("proargtypes")
-- that's after the first column, but before the final column.  The scan's
-- initial positioning strategy must become >= here (it's not the > strategy,
-- since the absence of "proargtypes" makes that tighter constraint unsafe).
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, pronamespace) > ('abs', 0)
ORDER BY
    proname,
    proargtypes,
    pronamespace
LIMIT 1;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, pronamespace) > ('abs', 0)
ORDER BY
    proname,
    proargtypes,
    pronamespace
LIMIT 1;

--
-- Similar to the previous test case, but this time it's a backwards scan
-- using a < RowCompare.  Must use the <= strategy (and not the < strategy).
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, pronamespace) < ('abs', 1_000_000)
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC
LIMIT 1;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, pronamespace) < ('abs', 1_000_000)
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC
LIMIT 1;

--
-- Forwards scan RowCompare qual whose row arg has a NULL that affects our
-- initial positioning strategy
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, proargtypes) >= ('abs', NULL)
    AND proname <= 'abs'
ORDER BY
    proname,
    proargtypes,
    pronamespace;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, proargtypes) >= ('abs', NULL)
    AND proname <= 'abs'
ORDER BY
    proname,
    proargtypes,
    pronamespace;

--
-- Forwards scan RowCompare quals whose row arg has a NULL that ends scan
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname >= 'abs'
    AND (proname,
        proargtypes) < ('abs',
        NULL)
ORDER BY
    proname,
    proargtypes,
    pronamespace;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname >= 'abs'
    AND (proname,
        proargtypes) < ('abs',
        NULL)
ORDER BY
    proname,
    proargtypes,
    pronamespace;

--
-- Backwards scan RowCompare qual whose row arg has a NULL that affects our
-- initial positioning strategy
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname >= 'abs'
    AND (proname,
        proargtypes) <= ('abs',
        NULL)
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname >= 'abs'
    AND (proname,
        proargtypes) <= ('abs',
        NULL)
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC;

--
-- Backwards scan RowCompare qual whose row arg has a NULL that ends scan
--
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, proargtypes) > ('abs', NULL)
    AND proname <= 'abs'
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE (proname, proargtypes) > ('abs', NULL)
    AND proname <= 'abs'
ORDER BY
    proname DESC,
    proargtypes DESC,
    pronamespace DESC;

-- Makes B-Tree preprocessing deal with unmarking redundant keys that were
-- initially marked required (test case relies on current row compare
-- preprocessing limitations)
EXPLAIN (
    COSTS OFF
)
SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname = 'zzzzzz'
    AND (proname,
        proargtypes) > ('abs',
        NULL)
    AND pronamespace IN (1, 2, 3)
    AND proargtypes IN ('26 23', '5077')
ORDER BY
    proname,
    proargtypes,
    pronamespace;

SELECT
    proname,
    proargtypes,
    pronamespace
FROM
    pg_proc
WHERE
    proname = 'zzzzzz'
    AND (proname,
        proargtypes) > ('abs',
        NULL)
    AND pronamespace IN (1, 2, 3)
    AND proargtypes IN ('26 23', '5077')
ORDER BY
    proname,
    proargtypes,
    pronamespace;

--
-- Test RowCompare handling within _bt_set_startikey, which decides whether
-- every tuple on a page (a page beyond the scan's first) must satisfy the
-- scan's RowCompare qual.
--
-- The index mixes an ASC column with a DESC column (so RowCompare members
-- don't all use the same inequality strategy and are not marked required),
-- uses a low fillfactor (so scans read several pages), and disables
-- deduplication (so the "b" NULLs span more than one page).
CREATE temp TABLE btree_rowcompare_tab (
    a int,
    b int,
    c int
);

INSERT INTO btree_rowcompare_tab
SELECT
    a,
    b,
    b
FROM
    generate_series(1, 3) a,
    generate_series(1, 150) b;

INSERT INTO btree_rowcompare_tab
SELECT
    2,
    NULL,
    NULL
FROM
    generate_series(1, 50);

CREATE INDEX btree_rowcompare_idx ON btree_rowcompare_tab (a, b DESC, c) WITH (fillfactor = 10, deduplicate_items = OFF);

VACUUM ANALYZE btree_rowcompare_tab;

SET enable_seqscan TO FALSE;

SET enable_bitmapscan TO FALSE;

-- RowCompare satisfied by every tuple on many pages (decided by its first
-- member on "a = 3" pages, and by its final member on "a = 2" pages)
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, b) >= (2, 75);

SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, b) >= (2, 75);

-- Reaches the RowCompare's unsatisfiable NULL member argument on "a = 2"
-- pages (the "a = 2" key positions the scan within the "a = 2" group, which
-- the RowCompare qual alone would not).  The combined quals are
-- contradictory, but preprocessing cannot detect that.
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE
    a = 2
    AND (a,
        b) >= (2,
        NULL);

SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE
    a = 2
    AND (a,
        b) >= (2,
        NULL);

-- RowCompare's row omits the index's second column, so on pages whose "b"
-- values change _bt_set_startikey can't prove that every tuple satisfies the
-- RowCompare.
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, c) >= (2, 100);

SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, c) >= (2, 100);

-- Variant that uses the remaining inequality strategies
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, b) < (2, 10);

SELECT
    count(*)
FROM
    btree_rowcompare_tab
WHERE (a, b) < (2, 10);

DROP TABLE btree_rowcompare_tab;

--
-- Test SAOP array handling within _bt_set_startikey
--
CREATE temp TABLE btree_saop_tab (
    a int,
    b int,
    c int
);

INSERT INTO btree_saop_tab
SELECT
    a,
    b,
    b
FROM
    generate_series(1, 3) a,
    generate_series(1, 150) b;

INSERT INTO btree_saop_tab
SELECT
    2,
    0,
    7
FROM
    generate_series(1, 60);

CREATE INDEX btree_saop_idx ON btree_saop_tab (a, b DESC, c) WITH (fillfactor = 10, deduplicate_items = OFF);

VACUUM ANALYZE btree_saop_tab;

-- SAOP on the leading column: pages beyond each primitive scan's first page
-- have a single "a" value that a binary search finds in the array, so the
-- scan starts past the SAOP key (forcing the nonrequired key protocol)
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a IN (1, 3)
    AND b >= 100;

SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a IN (1, 3)
    AND b >= 100;

-- Skip array on "b" precedes the "c" SAOP; pages whose "b" values change
-- prevent starting past the "c" SAOP key
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a = 2
    AND c IN (101, 105);

SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a = 2
    AND c IN (101, 105);

-- "c" SAOP follows the "b" inequality; on pages that lie wholly within the
-- duplicate "(2, 0, 7)" run, the scan starts past all of its scan keys,
-- including the SAOP key
EXPLAIN (
    COSTS OFF
)
SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a = 2
    AND b < 1
    AND c IN (6, 7);

SELECT
    count(*)
FROM
    btree_saop_tab
WHERE
    a = 2
    AND b < 1
    AND c IN (6, 7);

RESET enable_seqscan;

RESET enable_bitmapscan;

DROP TABLE btree_saop_tab;

--
-- Performs a recheck of > key following array advancement on previous (left
-- sibling) page that used a high key whose attribute value corresponding to
-- the > key was -inf (due to being truncated when the high key was created).
--
-- XXX This relies on the assumption that tenk1_thous_tenthous has a truncated
-- high key "(183, -inf)" on the first page that we'll scan.  The test will only
-- provide useful coverage when the default 8K BLCKSZ is in use.
--
EXPLAIN (
    COSTS OFF
)
SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE
    thousand IN (182, 183)
    AND tenthous > 7550;

SELECT
    thousand,
    tenthous
FROM
    tenk1
WHERE
    thousand IN (182, 183)
    AND tenthous > 7550;

--
-- Add coverage for optimization of backwards scan index descents
--
-- Here we expect _bt_search to descend straight to a leaf page containing a
-- non-pivot tuple with the value '47', which comes last (after 11 similar
-- non-pivot tuples).  Query execution should only need to visit a single
-- leaf page here.
--
-- Test case relies on tenk1_hundred index having a leaf page whose high key
-- is '(48, -inf)'.  We use a low cardinality index to make our test case less
-- sensitive to implementation details that may change in the future.
SET enable_seqscan TO FALSE;

SET enable_indexscan TO TRUE;

SET enable_bitmapscan TO FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    hundred,
    twenty
FROM
    tenk1
WHERE
    hundred < 48
ORDER BY
    hundred DESC
LIMIT 1;

SELECT
    hundred,
    twenty
FROM
    tenk1
WHERE
    hundred < 48
ORDER BY
    hundred DESC
LIMIT 1;

-- This variant of the query need only return a single tuple located to the immediate
-- right of the '(48, -inf)' high key.  It also only needs to scan one single
-- leaf page (the right sibling of the page scanned by the last test case):
EXPLAIN (
    COSTS OFF
)
SELECT
    hundred,
    twenty
FROM
    tenk1
WHERE
    hundred <= 48
ORDER BY
    hundred DESC
LIMIT 1;

SELECT
    hundred,
    twenty
FROM
    tenk1
WHERE
    hundred <= 48
ORDER BY
    hundred DESC
LIMIT 1;

--
-- Add coverage for ScalarArrayOp btree quals with pivot tuple constants
--
EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    hundred
FROM
    tenk1
WHERE
    hundred IN (47, 48, 72, 82);

SELECT DISTINCT
    hundred
FROM
    tenk1
WHERE
    hundred IN (47, 48, 72, 82);

EXPLAIN (
    COSTS OFF
) SELECT DISTINCT
    hundred
FROM
    tenk1
WHERE
    hundred IN (47, 48, 72, 82)
ORDER BY
    hundred DESC;

SELECT DISTINCT
    hundred
FROM
    tenk1
WHERE
    hundred IN (47, 48, 72, 82)
ORDER BY
    hundred DESC;

EXPLAIN (
    COSTS OFF
)
SELECT
    thousand
FROM
    tenk1
WHERE
    thousand IN (364, 366, 380)
    AND tenthous = 200000;

SELECT
    thousand
FROM
    tenk1
WHERE
    thousand IN (364, 366, 380)
    AND tenthous = 200000;

--
-- Check correct optimization of LIKE (special index operator support)
-- for both indexscan and bitmapscan cases
--
SET enable_seqscan TO FALSE;

SET enable_indexscan TO TRUE;

SET enable_bitmapscan TO FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname LIKE E'RI\\_FKey%del'
ORDER BY
    1;

SELECT
    proname
FROM
    pg_proc
WHERE
    proname LIKE E'RI\\_FKey%del'
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE '00%foo'
ORDER BY
    1;

SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE '00%foo'
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE 'ri%foo'
ORDER BY
    1;

SET enable_indexscan TO FALSE;

SET enable_bitmapscan TO TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname LIKE E'RI\\_FKey%del'
ORDER BY
    1;

SELECT
    proname
FROM
    pg_proc
WHERE
    proname LIKE E'RI\\_FKey%del'
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE '00%foo'
ORDER BY
    1;

SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE '00%foo'
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    proname
FROM
    pg_proc
WHERE
    proname ILIKE 'ri%foo'
ORDER BY
    1;

RESET enable_seqscan;

RESET enable_indexscan;

RESET enable_bitmapscan;

-- Also check LIKE optimization with binary-compatible cases
CREATE temp TABLE btree_bpchar (
    f1 text COLLATE "C"
);

CREATE INDEX ON btree_bpchar (f1 bpchar_ops) WITH (deduplicate_items = ON);

INSERT INTO btree_bpchar
VALUES
    ('foo'),
    ('fool'),
    ('bar'),
    ('quux');

-- doesn't match index:
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    btree_bpchar
WHERE
    f1 LIKE 'foo';

SELECT
    *
FROM
    btree_bpchar
WHERE
    f1 LIKE 'foo';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    btree_bpchar
WHERE
    f1 LIKE 'foo%';

SELECT
    *
FROM
    btree_bpchar
WHERE
    f1 LIKE 'foo%';

-- these do match the index:
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    btree_bpchar
WHERE
    f1::bpchar LIKE 'foo';

SELECT
    *
FROM
    btree_bpchar
WHERE
    f1::bpchar LIKE 'foo';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    btree_bpchar
WHERE
    f1::bpchar LIKE 'foo%';

SELECT
    *
FROM
    btree_bpchar
WHERE
    f1::bpchar LIKE 'foo%';

--
-- Perform unique checking, with and without the use of deduplication
--
CREATE TABLE dedup_unique_test_table (
    a int
)
WITH (
    autovacuum_enabled = FALSE
);

CREATE UNIQUE INDEX dedup_unique ON dedup_unique_test_table (a) WITH (deduplicate_items = ON);

CREATE UNIQUE INDEX plain_unique ON dedup_unique_test_table (a) WITH (deduplicate_items = OFF);

-- Generate enough garbage tuples in index to ensure that even the unique index
-- with deduplication enabled has to check multiple leaf pages during unique
-- checking (at least with a BLCKSZ of 8192 or less)
DO $$
BEGIN
    FOR r IN 1..1350 LOOP
        DELETE FROM dedup_unique_test_table;
        INSERT INTO dedup_unique_test_table
        SELECT
            1;
    END LOOP;
END
$$;

-- Exercise the LP_DEAD-bit-set tuple deletion code with a posting list tuple.
-- The implementation prefers deleting existing items to merging any duplicate
-- tuples into a posting list, so we need an explicit test to make sure we get
-- coverage (note that this test also assumes BLCKSZ is 8192 or less):
DROP INDEX plain_unique;

DELETE FROM dedup_unique_test_table
WHERE a = 1;

INSERT INTO dedup_unique_test_table
SELECT
    i
FROM
    generate_series(0, 450) i;

--
-- Test B-tree fast path (cache rightmost leaf page) optimization.
--
-- First create a tree that's at least three levels deep (i.e. has one level
-- between the root and leaf levels). The text inserted is long.  It won't be
-- TOAST compressed because we use plain storage in the table.  Only a few
-- index tuples fit on each internal page, allowing us to get a tall tree with
-- few pages.  (A tall tree is required to trigger caching.)
--
-- The text column must be the leading column in the index, since suffix
-- truncation would otherwise truncate tuples on internal pages, leaving us
-- with a short tree.
CREATE TABLE btree_tall_tbl (
    id int4,
    t text
);

ALTER TABLE btree_tall_tbl
    ALTER COLUMN t SET storage plain;

CREATE INDEX btree_tall_idx ON btree_tall_tbl (t, id) WITH (fillfactor = 10);

INSERT INTO btree_tall_tbl
SELECT
    g,
    repeat('x', 250)
FROM
    generate_series(1, 130) g;

INSERT INTO btree_tall_tbl
SELECT
    g,
    NULL
FROM
    generate_series(50, 60) g;

--
-- Test for skip scan with type that lacks skip support (text)
--
SET enable_seqscan TO FALSE;

SET enable_bitmapscan TO FALSE;

-- Forwards scan
SELECT
    id
FROM
    btree_tall_tbl
WHERE
    id = 55
ORDER BY
    t,
    id;

EXPLAIN (
    COSTS OFF
)
SELECT
    id
FROM
    btree_tall_tbl
WHERE
    id = 55
ORDER BY
    t,
    id;

-- Backwards scan
SELECT
    id
FROM
    btree_tall_tbl
WHERE
    id = 55
ORDER BY
    t DESC,
    id DESC;

EXPLAIN (
    COSTS OFF
)
SELECT
    id
FROM
    btree_tall_tbl
WHERE
    id = 55
ORDER BY
    t DESC,
    id DESC;

RESET enable_seqscan;

RESET enable_bitmapscan;

--
-- Test for multilevel page deletion
--
CREATE TABLE delete_test_table (
    a bigint,
    b bigint,
    c bigint,
    d bigint
);

INSERT INTO delete_test_table
SELECT
    i,
    1,
    2,
    3
FROM
    generate_series(1, 80000) i;

ALTER TABLE delete_test_table
    ADD PRIMARY KEY (a, b, c, d);

-- Delete most entries, and vacuum, deleting internal pages and creating "fast
-- root"
DELETE FROM delete_test_table
WHERE a < 79990;

VACUUM delete_test_table;

--
-- Test B-tree insertion with a metapage update (XLOG_BTREE_INSERT_META
-- WAL record type). This happens when a "fast root" page is split.  This
-- also creates coverage for nbtree FSM page recycling.
--
-- The vacuum above should've turned the leaf page into a fast root. We just
-- need to insert some rows to cause the fast root page to split.
INSERT INTO delete_test_table
SELECT
    i,
    1,
    2,
    3
FROM
    generate_series(1, 1000) i;

-- Test unsupported btree opclass parameters
CREATE INDEX ON btree_tall_tbl (id int4_ops (foo = 1));

-- test parallel build with immutable function.
CREATE TABLE btree_test_expr (
    n int
);

CREATE FUNCTION btree_test_func ()
    RETURNS int
    LANGUAGE sql
    IMMUTABLE RETURN 0;

BEGIN;
SET LOCAL min_parallel_table_scan_size = 0;
SET LOCAL max_parallel_maintenance_workers = 4;
CREATE INDEX btree_test_expr_idx ON btree_test_expr USING btree (btree_test_func ());
COMMIT;
DROP TABLE btree_test_expr;
DROP FUNCTION btree_test_func ();
-- Test case of ALTER INDEX with abuse of column names for indexes.
-- This grammar is not officially supported, but the parser allows it.
CREATE INDEX btree_tall_idx2 ON btree_tall_tbl (id);
ALTER INDEX btree_tall_idx2
    ALTER COLUMN id SET (n_distinct = 100);
DROP INDEX btree_tall_idx2;
-- Partitioned index
CREATE TABLE btree_part (
    id int4
)
PARTITION BY RANGE (id);
CREATE INDEX btree_part_idx ON btree_part (id);
ALTER INDEX btree_part_idx
    ALTER COLUMN id SET (n_distinct = 100);
DROP TABLE btree_part;
