--
-- Test GiST indexes.
--
-- There are other tests to test different GiST opclasses. This is for
-- testing GiST code itself. Vacuuming in particular.
CREATE TABLE gist_point_tbl (
    id int4,
    p point
);

CREATE INDEX gist_pointidx ON gist_point_tbl USING gist (p);

-- Verify the fillfactor and buffering options
CREATE INDEX gist_pointidx2 ON gist_point_tbl USING gist (p) WITH (buffering = ON, fillfactor = 50);

CREATE INDEX gist_pointidx3 ON gist_point_tbl USING gist (p) WITH (buffering = OFF);

CREATE INDEX gist_pointidx4 ON gist_point_tbl USING gist (p) WITH (buffering = auto);

DROP INDEX gist_pointidx2, gist_pointidx3, gist_pointidx4;

-- Make sure bad values are refused
CREATE INDEX gist_pointidx5 ON gist_point_tbl USING gist (p) WITH (buffering = invalid_value);

CREATE INDEX gist_pointidx5 ON gist_point_tbl USING gist (p) WITH (fillfactor = 9);

CREATE INDEX gist_pointidx5 ON gist_point_tbl USING gist (p) WITH (fillfactor = 101);

-- Insert enough data to create a tree that's a couple of levels deep.
INSERT INTO gist_point_tbl (id, p)
SELECT
    g,
    point(g * 10, g * 10)
FROM
    generate_series(1, 10000) g;

INSERT INTO gist_point_tbl (id, p)
SELECT
    g + 100000,
    point(g * 10 + 1, g * 10 + 1)
FROM
    generate_series(1, 10000) g;

-- To test vacuum, delete some entries from all over the index.
DELETE FROM gist_point_tbl
WHERE id % 2 = 1;

-- And also delete some concentration of values.
DELETE FROM gist_point_tbl
WHERE id > 5000;

VACUUM ANALYZE gist_point_tbl;

-- rebuild the index with a different fillfactor
ALTER INDEX gist_pointidx SET (fillfactor = 40);

REINDEX INDEX gist_pointidx;

--
-- Test Index-only plans on GiST indexes
--
CREATE TABLE gist_tbl (
    b box,
    p point,
    c circle
);

INSERT INTO gist_tbl
SELECT
    box(point(0.05 * i, 0.05 * i), point(0.05 * i, 0.05 * i)),
    point(0.05 * i, 0.05 * i),
    circle(point(0.05 * i, 0.05 * i), 1.0)
FROM
    generate_series(0, 10000) AS i;

VACUUM ANALYZE gist_tbl;

SET enable_seqscan = OFF;

SET enable_bitmapscan = OFF;

SET enable_indexonlyscan = ON;

-- Test index-only scan with point opclass
CREATE INDEX gist_tbl_point_index ON gist_tbl USING gist (p);

-- check that the planner chooses an index-only scan
EXPLAIN (
    COSTS OFF
)
SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5));

-- execute the same
SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5));

-- Also test an index-only knn-search
EXPLAIN (
    COSTS OFF
)
SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5))
ORDER BY
    p <-> point(0.201, 0.201);

SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5))
ORDER BY
    p <-> point(0.201, 0.201);

-- Check commuted case as well
EXPLAIN (
    COSTS OFF
)
SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5))
ORDER BY
    point(0.101, 0.101) <-> p;

SELECT
    p
FROM
    gist_tbl
WHERE
    p <@ box(point(0, 0), point(0.5, 0.5))
ORDER BY
    point(0.101, 0.101) <-> p;

-- Check case with multiple rescans (bug #14641)
EXPLAIN (
    COSTS OFF
)
SELECT
    p
FROM (
    VALUES (box(point(0, 0), point(0.5, 0.5))),
        (box(point(0.5, 0.5), point(0.75, 0.75))),
        (box(point(0.8, 0.8), point(1.0, 1.0)))) AS v (bb)
    CROSS JOIN LATERAL (
        SELECT
            p
        FROM
            gist_tbl
        WHERE
            p <@ bb
        ORDER BY
            p <-> bb[0]
        LIMIT 2) ss;

SELECT
    p
FROM (
    VALUES (box(point(0, 0), point(0.5, 0.5))),
        (box(point(0.5, 0.5), point(0.75, 0.75))),
        (box(point(0.8, 0.8), point(1.0, 1.0)))) AS v (bb)
    CROSS JOIN LATERAL (
        SELECT
            p
        FROM
            gist_tbl
        WHERE
            p <@ bb
        ORDER BY
            p <-> bb[0]
        LIMIT 2) ss;

DROP INDEX gist_tbl_point_index;

-- Test index-only scan with box opclass
CREATE INDEX gist_tbl_box_index ON gist_tbl USING gist (b);

-- check that the planner chooses an index-only scan
EXPLAIN (
    COSTS OFF
)
SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6));

-- execute the same
SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6));

-- Also test an index-only knn-search
EXPLAIN (
    COSTS OFF
)
SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6))
ORDER BY
    b <-> point(5.2, 5.91);

SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6))
ORDER BY
    b <-> point(5.2, 5.91);

-- Check commuted case as well
EXPLAIN (
    COSTS OFF
)
SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6))
ORDER BY
    point(5.2, 5.91) <-> b;

SELECT
    b
FROM
    gist_tbl
WHERE
    b <@ box(point(5, 5), point(6, 6))
ORDER BY
    point(5.2, 5.91) <-> b;

DROP INDEX gist_tbl_box_index;

-- Test that an index-only scan is not chosen, when the query involves the
-- circle column (the circle opclass does not support index-only scans).
CREATE INDEX gist_tbl_multi_index ON gist_tbl USING gist (p, c);

EXPLAIN (
    COSTS OFF
)
SELECT
    p,
    c
FROM
    gist_tbl
WHERE
    p <@ box(point(5, 5), point(6, 6));

-- execute the same
SELECT
    b,
    p
FROM
    gist_tbl
WHERE
    b <@ box(point(4.5, 4.5), point(5.5, 5.5))
    AND p <@ box(point(5, 5), point(6, 6));

DROP INDEX gist_tbl_multi_index;

-- Test that we don't try to return the value of a non-returnable
-- column in an index-only scan.  (This isn't GIST-specific, but
-- it only applies to index AMs that can return some columns and not
-- others, so GIST with appropriate opclasses is a convenient test case.)
CREATE INDEX gist_tbl_multi_index ON gist_tbl USING gist (circle(p, 1), p);

EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    circle(p, 1)
FROM
    gist_tbl
WHERE
    p <@ box(point(5, 5), point(5.3, 5.3));

SELECT
    circle(p, 1)
FROM
    gist_tbl
WHERE
    p <@ box(point(5, 5), point(5.3, 5.3));

-- Similarly, test that index rechecks involving a non-returnable column
-- are done correctly.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    p
FROM
    gist_tbl
WHERE
    circle(p, 1) @> circle(point(0, 0), 0.95);

SELECT
    p
FROM
    gist_tbl
WHERE
    circle(p, 1) @> circle(point(0, 0), 0.95);

-- Also check that use_physical_tlist doesn't trigger in such cases.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    count(*)
FROM
    gist_tbl;

SELECT
    count(*)
FROM
    gist_tbl;

-- This case isn't supported, but it should at least EXPLAIN correctly.
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    p
FROM
    gist_tbl
ORDER BY
    circle(p, 1) <-> point(0, 0)
LIMIT 1;

SELECT
    p
FROM
    gist_tbl
ORDER BY
    circle(p, 1) <-> point(0, 0)
LIMIT 1;

-- Test that an index-only scan deforms the tuple it reconstructs with the
-- descriptor the AM formed it with, not the scan slot's descriptor.
CREATE temp TABLE gist_ios_tupdesc (
    a inet,
    r numrange
);

-- range_ops forms its tuples using the opclass input type, the polymorphic
-- anyrange (alignment 'd'), while the scan slot uses the actual range type
-- numrange (alignment 'i').  A buggy implementation will incorrectly access
-- the r/numrange column at the wrong offset.
--
-- The range bounds are made long so the value needs a four-byte varlena
-- header; shorter values get a one-byte header and are stored without
-- alignment padding, which would mask the problem.
INSERT INTO gist_ios_tupdesc
    VALUES ('::1', -- shifts "r" datum value to differing offset
        numrange(repeat('7', 200)::numeric, repeat('8', 200)::numeric));

CREATE INDEX ON gist_ios_tupdesc USING gist (a inet_ops, r);

VACUUM ANALYZE gist_ios_tupdesc;

EXPLAIN (
    COSTS OFF
)
SELECT
    lower(r) = repeat('7', 200)::numeric AS lower_ok,
    upper(r) = repeat('8', 200)::numeric AS upper_ok
FROM
    gist_ios_tupdesc
WHERE
    r && numrange(NULL, NULL);

SELECT
    lower(r) = repeat('7', 200)::numeric AS lower_ok,
    upper(r) = repeat('8', 200)::numeric AS upper_ok
FROM
    gist_ios_tupdesc
WHERE
    r && numrange(NULL, NULL);

DROP TABLE gist_ios_tupdesc;

-- test deletion of LP_DEAD-marked index tuples
CREATE TABLE gist_prune_tbl (
    k int,
    p point
);

CREATE INDEX gist_prune_tbl_p_index ON gist_prune_tbl USING gist (p);

BEGIN;
INSERT INTO gist_prune_tbl
SELECT
    i,
    point(1, i)
FROM
    generate_series(1, 600) i;
ROLLBACK;

SET enable_bitmapscan = OFF;

SET enable_indexonlyscan = OFF;

SET enable_seqscan = OFF;

SELECT
    count(*)
FROM
    gist_prune_tbl
WHERE
    p <@ box(point(0, 0), point(2, 1000));

INSERT INTO gist_prune_tbl
SELECT
    i,
    point(1, i)
FROM
    generate_series(1, 600) i;

SELECT
    count(*)
FROM
    gist_prune_tbl
WHERE
    p <@ box(point(0, 0), point(2, 1000));

RESET enable_bitmapscan;

RESET enable_indexonlyscan;

RESET enable_seqscan;

DROP TABLE gist_prune_tbl;

-- Force an index build using buffering.
CREATE INDEX gist_tbl_box_index_forcing_buffering ON gist_tbl USING gist (p) WITH (buffering = ON, fillfactor = 50);

-- Clean up
RESET enable_seqscan;

RESET enable_bitmapscan;

RESET enable_indexonlyscan;

DROP TABLE gist_tbl;

-- test an unlogged table, mostly to get coverage of gistbuildempty
CREATE UNLOGGED TABLE gist_tbl (
    b box
);

CREATE INDEX gist_tbl_box_index ON gist_tbl USING gist (b);

INSERT INTO gist_tbl
SELECT
    box(point(0.05 * i, 0.05 * i))
FROM
    generate_series(0, 10) AS i;

DROP TABLE gist_tbl;

