--
-- BTREE_INDEX
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

--
-- Test B-tree fast path (cache rightmost leaf page) optimization.
--
-- First create a tree that's at least three levels deep (i.e. has one level
-- between the root and leaf levels). The text inserted is long.  It won't be
-- compressed because we use plain storage in the table.  Only a few index
-- tuples fit on each internal page, allowing us to get a tall tree with few
-- pages.  (A tall tree is required to trigger caching.)
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

--
-- Test vacuum_cleanup_index_scale_factor
--
-- Simple create
CREATE TABLE btree_test (
    a int
);

CREATE INDEX btree_idx1 ON btree_test (a) WITH (vacuum_cleanup_index_scale_factor = 40.0);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'btree_idx1'::regclass;

-- Fail while setting improper values
CREATE INDEX btree_idx_err ON btree_test (a) WITH (vacuum_cleanup_index_scale_factor = -10.0);

CREATE INDEX btree_idx_err ON btree_test (a) WITH (vacuum_cleanup_index_scale_factor = 100.0);

CREATE INDEX btree_idx_err ON btree_test (a) WITH (vacuum_cleanup_index_scale_factor = 'string');

CREATE INDEX btree_idx_err ON btree_test (a) WITH (vacuum_cleanup_index_scale_factor = TRUE);

-- Simple ALTER INDEX
ALTER INDEX btree_idx1 SET (vacuum_cleanup_index_scale_factor = 70.0);

SELECT
    reloptions
FROM
    pg_class
WHERE
    oid = 'btree_idx1'::regclass;

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

