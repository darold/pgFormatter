-- CTE in the query of CREATE TABLE ... AS ( ... ) and in a subquery
CREATE TEMPORARY TABLE IF NOT EXISTS square_poly2 AS (WITH united AS (SELECT level, st_union(st_buffer(geom, 0.01)) AS geom FROM osmgrid._a_polygones GROUP BY level), united2 AS (SELECT level, st_union(st_buffer(geom, 0.01)) AS geom FROM osmgrid._a_polygones GROUP BY level) SELECT * FROM united);
CREATE TABLE t2 (a, b) AS (SELECT f(x) AS a, g(y) AS b FROM z) WITH NO DATA;
CREATE TABLE t3 AS (VALUES (1, 'a'), (2, 'b'));
CREATE TABLE t4 (a int, b text DEFAULT 'x', c numeric(10, 2));
CREATE TYPE ty AS (a int, b text);
SELECT * FROM (WITH a AS (SELECT 1 FROM x), b AS (SELECT 2 FROM y) SELECT * FROM a) s WHERE s.c = 1;
CREATE FUNCTION fn() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tt AS (WITH u AS (SELECT 1 AS a), v AS (SELECT 2 AS b) SELECT * FROM u, v);
  RAISE NOTICE 'x';
END $$;
