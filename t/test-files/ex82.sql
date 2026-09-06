-- Simplest reproduction: a single CTE with a sub-query in WHERE.
WITH a AS (SELECT x FROM t WHERE y IN (SELECT z FROM u)) SELECT * FROM a;

-- Chained CTEs where the last one ends with a sub-query.
WITH a AS (SELECT 1), b AS (SELECT x FROM t WHERE x IN (SELECT y FROM u)) SELECT * FROM b;

-- Nested CTE example from the PostgreSQL documentation.
WITH regional_sales AS (SELECT region, SUM(amount) AS total_sales FROM orders GROUP BY region), top_regions AS (SELECT region FROM regional_sales WHERE total_sales > (SELECT SUM(total_sales) / 10 FROM regional_sales)) SELECT region, product, SUM(quantity) FROM orders WHERE region IN (SELECT region FROM top_regions) GROUP BY region, product;

-- Data-modifying CTE (writable CTE) ending with a sub-query.
WITH a AS (SELECT id FROM t WHERE id IN (SELECT id FROM u)) INSERT INTO d (id) SELECT id FROM a;
