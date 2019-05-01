WITH source AS source2 AS (
        DELETE FROM items USING source2
)
INSERT INTO old_orders SELECT order_id FROM source2;

SELECT '--data' FROM test;

DECLARE c_mvcc_demo CURSOR FOR
        SELECT xmin, xmax, cmax, *
        FROM mvcc_demo;
SELECT 1;

SELECT * FROM pg_class ORDER BY relname;

SELECT RANK() OVER s AS dept_rank
FROM emp
WINDOW s AS (PARTITION BY department ORDER BY salary DESC)
ORDER BY department, salary DESC;

