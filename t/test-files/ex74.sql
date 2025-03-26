WITH example AS (SELECT a, b FROM tablename)
INSERT INTO example2 (a, b) SELECT COALESCE(a, 1) as a, b FROM example
