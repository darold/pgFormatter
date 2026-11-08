-- Clauses of a subquery in the arguments of a function
SELECT
    coalesce((
        SELECT
            sum(x + y) s
        FROM generate_series(1, 3) y
        WHERE
            y > 1
        GROUP BY
            y
        HAVING
            count(*) > 0
        ORDER BY
            s
        LIMIT 1), 0)
FROM
    t;

SELECT
    coalesce((
        SELECT
            extract(year FROM d)
        FROM t
        WHERE
            x = 1
        LIMIT 1), 0),
    string_agg(x, ',' ORDER BY y),
    percentile_disc(0.5) WITHIN GROUP (ORDER BY x)
FROM
    t;

SELECT
    row_to_json(ROW ((
            SELECT
                array_agg(x) AS d
            FROM generate_series(5, 10) x)), FALSE);

