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

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f (x)
WINDOW w AS ();

SELECT name, department, salary, RANK() OVER s AS dept_rank, RANK() OVER () AS global_rank
FROM empa
WINDOW s AS (PARTITION BY department ORDER BY salary DESC)
ORDER BY department, salary DESC;

SELECT name, department, salary, RANK() OVER () AS global_rank, RANK() OVER s AS dept_rank
FROM empb
WINDOW s AS (PARTITION BY department ORDER BY salary DESC)
ORDER BY department, salary DESC;

UPDATE mvcc_demo
SET val = val + 1
WHERE val > 0;

WITH driver (name) AS (
    SELECT DISTINCT
        unnest(xpath('//driver/text()',
                doc))::text
    FROM printer
)
SELECT name
FROM driver
WHERE name LIKE 'hp%'
ORDER BY 1;

WITH source (x1, x2) AS (
    SELECT 1
)
SELECT *
FROM source;

SELECT DISTINCT relkind, relname
FROM pg_class
ORDER BY 1, 2;

SELECT
    salary,
    RANK() OVER s
FROM emp
WINDOW s AS (
ORDER BY salary DESC)
ORDER BY
    salary DESC;

CREATE TRIGGER test_trigger_exists
    BEFORE UPDATE ON test_exists
    FOR EACH ROW EXECUTE PROCEDURE suppress_redundant_updates_trigger();

CREATE RULE test_rule_exists AS ON INSERT TO test_exists
    DO INSTEAD
    INSERT INTO test_exists VALUES (NEW.a, NEW.b || NEW.a::text);
DROP RULE test_rule_exists ON test_exists;

