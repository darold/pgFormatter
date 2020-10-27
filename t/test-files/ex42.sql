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
        style, body
    FROM
        review_table
)
SELECT
    *
FROM
    styles s;


WITH cte AS NOT MATERIALIZED (
    SELECT id, jsonb_strip_nulls ( jsonb_build_object( 'name', name)) AS data FROM t
) SELECT * FROM cte;

WITH cte AS (
    SELECT id, jsonb_strip_nulls ( jsonb_build_object( 'name', name)) AS data FROM t
) SELECT * FROM cte;

