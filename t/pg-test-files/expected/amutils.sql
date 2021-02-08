--
-- Test index AM property-reporting functions
--
SELECT
    prop,
    pg_indexam_has_property(a.oid, prop) AS "AM",
    pg_index_has_property('onek_hundred'::regclass, prop) AS "Index",
    pg_index_column_has_property('onek_hundred'::regclass, 1, prop) AS "Column"
FROM
    pg_am a,
    unnest(ARRAY['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls', 'clusterable', 'index_scan', 'bitmap_scan', 'backward_scan', 'can_order', 'can_unique', 'can_multi_col', 'can_exclude', 'can_include', 'bogus']::text[])
    WITH ORDINALITY AS u (prop, ord)
WHERE
    a.amname = 'btree'
ORDER BY
    ord;

SELECT
    prop,
    pg_indexam_has_property(a.oid, prop) AS "AM",
    pg_index_has_property('gcircleind'::regclass, prop) AS "Index",
    pg_index_column_has_property('gcircleind'::regclass, 1, prop) AS "Column"
FROM
    pg_am a,
    unnest(ARRAY['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls', 'clusterable', 'index_scan', 'bitmap_scan', 'backward_scan', 'can_order', 'can_unique', 'can_multi_col', 'can_exclude', 'can_include', 'bogus']::text[])
    WITH ORDINALITY AS u (prop, ord)
WHERE
    a.amname = 'gist'
ORDER BY
    ord;

SELECT
    prop,
    pg_index_column_has_property('onek_hundred'::regclass, 1, prop) AS btree,
    pg_index_column_has_property('hash_i4_index'::regclass, 1, prop) AS hash,
    pg_index_column_has_property('gcircleind'::regclass, 1, prop) AS gist,
    pg_index_column_has_property('sp_radix_ind'::regclass, 1, prop) AS spgist_radix,
    pg_index_column_has_property('sp_quad_ind'::regclass, 1, prop) AS spgist_quad,
    pg_index_column_has_property('botharrayidx'::regclass, 1, prop) AS gin,
    pg_index_column_has_property('brinidx'::regclass, 1, prop) AS brin
FROM
    unnest(ARRAY['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls', 'bogus']::text[])
    WITH ORDINALITY AS u (prop, ord)
ORDER BY
    ord;

SELECT
    prop,
    pg_index_has_property('onek_hundred'::regclass, prop) AS btree,
    pg_index_has_property('hash_i4_index'::regclass, prop) AS hash,
    pg_index_has_property('gcircleind'::regclass, prop) AS gist,
    pg_index_has_property('sp_radix_ind'::regclass, prop) AS spgist,
    pg_index_has_property('botharrayidx'::regclass, prop) AS gin,
    pg_index_has_property('brinidx'::regclass, prop) AS brin
FROM
    unnest(ARRAY['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan', 'bogus']::text[])
    WITH ORDINALITY AS u (prop, ord)
ORDER BY
    ord;

SELECT
    amname,
    prop,
    pg_indexam_has_property(a.oid, prop) AS p
FROM
    pg_am a,
    unnest(ARRAY['can_order', 'can_unique', 'can_multi_col', 'can_exclude', 'can_include', 'bogus']::text[])
    WITH ORDINALITY AS u (prop, ord)
WHERE
    amtype = 'i'
ORDER BY
    amname,
    ord;

--
-- additional checks for pg_index_column_has_property
--
CREATE TEMP TABLE foo (
    f1 int,
    f2 int,
    f3 int,
    f4 int
);

CREATE INDEX fooindex ON foo (f1 DESC, f2 ASC, f3 nulls FIRST, f4 nulls LAST);

SELECT
    col,
    prop,
    pg_index_column_has_property(o, col, prop)
FROM (
    VALUES ('fooindex'::regclass)) v1 (o),
    (
        VALUES (1, 'orderable'), (2, 'asc'), (3, 'desc'), (4, 'nulls_first'), (5, 'nulls_last'), (6, 'bogus')) v2 (idx, prop),
    generate_series(1, 4) col
ORDER BY
    col,
    idx;

CREATE INDEX foocover ON foo (f1) INCLUDE (f2, f3);

SELECT
    col,
    prop,
    pg_index_column_has_property(o, col, prop)
FROM (
    VALUES ('foocover'::regclass)) v1 (o),
    (
        VALUES (1, 'orderable'), (2, 'asc'), (3, 'desc'), (4, 'nulls_first'), (5, 'nulls_last'), (6, 'distance_orderable'), (7, 'returnable'), (8, 'bogus')) v2 (idx, prop),
    generate_series(1, 3) col
ORDER BY
    col,
    idx;

