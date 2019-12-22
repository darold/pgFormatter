WITH styles AS (
    SELECT
        style,
        color
    FROM
        style_table s
    WHERE
        s.id = 'D'
),
reviews AS (
    SELECT
        style,
        body
    FROM
        review_table
)
SELECT
    *
FROM
    styles s;

