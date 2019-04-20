WITH cte1 AS (
    SELECT
        *
    FROM
        table_a a
        -- Comment out or remove this JOIN to fix the indentation issue below
        INNER JOIN table_b b ON a.id = b.id
),
cte2 AS (
    SELECT
        CASE WHEN TRUE THEN
            TRUE
        WHEN NULL IS NULL
            OR TRUE = FALSE THEN
            NULL
            -- Indentation is off starting here
        WHEN FALSE
            AND TRUE THEN
            TRUE
        ELSE
            FALSE
        END AS value
    FROM
        cte1
        -- Indentation is correct after this line
)
SELECT
    *
FROM
    cte2;

SELECT
    *,
    SUM((
        SELECT
            count(*)
            FROM b)) AS something,
    SUM((
        SELECT
            count(*)
            FROM b)) AS something,
    a.b
FROM
    a;

