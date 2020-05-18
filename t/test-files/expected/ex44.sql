SELECT
    *
FROM
    tabl
WHERE (a = c)
    AND (b = c
        OR c = d);

SELECT
    *
FROM
    tabl
WHERE (a = c
    AND b = c)
    OR (c = d);

SELECT
    *
FROM
    tabl
WHERE (a = c)
    AND (b = c)
    OR (c = d);

