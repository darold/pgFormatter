SELECT
    sum(c)
FROM
    gstest2
GROUP BY
    GROUPING SETS ((),
    GROUPING SETS ((),
    GROUPING SETS (((a,
                b)))));

SELECT
    a
FROM
    t
GROUP BY
    ROLLUP ((a, b)),
    CUBE ((c));

SELECT
    (a)
FROM
    t
WHERE ((b = 1));

