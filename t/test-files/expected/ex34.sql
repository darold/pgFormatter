SELECT
    count(*) FILTER (WHERE b) AS count_b,
    count(*) FILTER (WHERE c) AS count_c
FROM
    a;

SELECT
    array_agg(a ORDER BY b DESC)
FROM
    TABLE;

SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY income)
FROM
    households;

SELECT
    count(*) AS unfiltered,
    count(*) FILTER (WHERE i < 5) AS filtered
FROM
    generate_series(1, 10) AS s (i);

SELECT
    make,
    model,
    GROUPING (make, model),
    sum(sales)
FROM
    items_sold
GROUP BY
    ROLLUP (make, model);

