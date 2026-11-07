-- Issue #195: several comment lines between two CTE definitions
WITH
--
-- CTE comment 1
--
cte_1 AS (
    SELECT
        max(1) AS col_b
    FROM
        dual
    GROUP BY
        dummy
    HAVING
        max(dummy) > (
            SELECT
                'x'
            FROM
                dual)
        OR max(dummy) = 'y'
),
--
-- CTE comment 2
--
cte_2 AS (
    SELECT
        dummy,
        max(1) AS col_c
    FROM
        dual
    GROUP BY
        dummy
    HAVING
        max(dummy) = '2'
)
SELECT
    *
FROM
    cte_2;

WITH a AS (
    SELECT
        1
),
-- c
-- d
/* e */
b AS (
    SELECT
        2
)
SELECT
    *
FROM
    a,
    b;

