-- ARRAY ( subquery ) formatted like a function call, ARRAY keeps the keyword case
select t1.a, (array (select (b, array (select b from t2)) from t2)) from t1;
SELECT ARRAY(SELECT sum(x + y) s FROM generate_series(1, 3) y GROUP BY y ORDER BY s) FROM generate_series(1, 3) x;
SELECT ARRAY(SELECT extract(year FROM d) FROM t WHERE x = 1), ARRAY[1, 2, 3], array_agg(x), x = ANY (ARRAY(SELECT y FROM u WHERE z IN (1, 2))) FROM t;
CREATE TABLE ta (a int ARRAY, b int ARRAY[3], c int[] DEFAULT ARRAY(SELECT 1));
