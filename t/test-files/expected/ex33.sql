SELECT
    CASE WHEN my_col IS NOT NULL THEN
        'Y'
    ELSE
        'N'
    END AS my_new_col,
    CASE WHEN TRIM(my_other_col) = 'confirmed' THEN
        'Y'
    ELSE
        'N'
    END AS new_col
FROM
    my_table;

SELECT DISTINCT ON (a, b)
    a,
    b,
    c
FROM
    d
ORDER BY
    a,
    b,
    c;

SELECT DISTINCT
    a,
    b,
    b,
    c
FROM
    d
ORDER BY
    a,
    b,
    c;

