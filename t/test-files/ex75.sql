WITH example AS (SELECT a, b FROM tablename),
example2 AS (SELECT COALESCE(a, 1) AS a, b FROM example)
INSERT INTO example3 (a, b)
SELECT a, b FROM example
