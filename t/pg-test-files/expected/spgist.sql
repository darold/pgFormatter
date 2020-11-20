--
-- Test SP-GiST indexes.
--
-- There are other tests to test different SP-GiST opclasses. This is for
-- testing SP-GiST code itself.
CREATE TABLE spgist_point_tbl (
    id int4,
    p point
);

CREATE INDEX spgist_point_idx ON spgist_point_tbl USING spgist (p) WITH (fillfactor = 75);

-- Test vacuum-root operation. It gets invoked when the root is also a leaf,
-- i.e. the index is very small.
INSERT INTO spgist_point_tbl (id, p)
SELECT
    g,
    point(g * 10, g * 10)
FROM
    generate_series(1, 10) g;

DELETE FROM spgist_point_tbl
WHERE id < 5;

VACUUM spgist_point_tbl;

-- Insert more data, to make the index a few levels deep.
INSERT INTO spgist_point_tbl (id, p)
SELECT
    g,
    point(g * 10, g * 10)
FROM
    generate_series(1, 10000) g;

INSERT INTO spgist_point_tbl (id, p)
SELECT
    g + 100000,
    point(g * 10 + 1, g * 10 + 1)
FROM
    generate_series(1, 10000) g;

-- To test vacuum, delete some entries from all over the index.
DELETE FROM spgist_point_tbl
WHERE id % 2 = 1;

-- And also delete some concentration of values. (SP-GiST doesn't currently
-- attempt to delete pages even when they become empty, but if it did, this
-- would exercise it)
DELETE FROM spgist_point_tbl
WHERE id < 10000;

VACUUM spgist_point_tbl;

-- Test rescan paths (cf. bug #15378)
-- use box and && rather than point, so that rescan happens when the
-- traverse stack is non-empty
CREATE TABLE spgist_box_tbl (
    id serial,
    b box
);

INSERT INTO spgist_box_tbl (b)
SELECT
    box(point(i, j), point(i + s, j + s))
FROM
    generate_series(1, 100, 5) i,
    generate_series(1, 100, 5) j,
    generate_series(1, 10) s;

CREATE INDEX spgist_box_idx ON spgist_box_tbl USING spgist (b);

SELECT
    count(*)
FROM (
    VALUES (point(5, 5)),
        (point(8, 8)),
        (point(12, 12))) v (p)
WHERE
    EXISTS (
        SELECT
            *
        FROM
            spgist_box_tbl b
        WHERE
            b.b && box(v.p, v.p));

-- The point opclass's choose method only uses the spgMatchNode action,
-- so the other actions are not tested by the above. Create an index using
-- text opclass, which uses the others actions.
CREATE TABLE spgist_text_tbl (
    id int4,
    t text
);

CREATE INDEX spgist_text_idx ON spgist_text_tbl USING spgist (t);

INSERT INTO spgist_text_tbl (id, t)
SELECT
    g,
    'f' || repeat('o', 100) || g
FROM
    generate_series(1, 10000) g
UNION ALL
SELECT
    g,
    'baaaaaaaaaaaaaar' || g
FROM
    generate_series(1, 1000) g;

-- Do a lot of insertions that have to split an existing node. Hopefully
-- one of these will cause the page to run out of space, causing the inner
-- tuple to be moved to another page.
INSERT INTO spgist_text_tbl (id, t)
SELECT
    - g,
    'f' || repeat('o', 100 - g) || 'surprise'
FROM
    generate_series(1, 100) g;

-- Test out-of-range fillfactor values
CREATE INDEX spgist_point_idx2 ON spgist_point_tbl USING spgist (p) WITH (fillfactor = 9);

CREATE INDEX spgist_point_idx2 ON spgist_point_tbl USING spgist (p) WITH (fillfactor = 101);

-- Modify fillfactor in existing index
ALTER INDEX spgist_point_idx SET (fillfactor = 90);

REINDEX INDEX spgist_point_idx;

