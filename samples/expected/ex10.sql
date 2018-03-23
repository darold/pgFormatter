WITH a AS (
    SELECT
        x,
        y,
        z
    FROM
        twelve
        JOIN nine ON a = 2
            AND b = a
),
b AS (
    SELECT
        *
    FROM
        a
)
SELECT
    *
FROM
    b;

