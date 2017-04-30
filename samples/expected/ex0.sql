SELECT
    a,
    b,
    c
FROM
    tablea
    JOIN tableb ON (tablea.a = tableb.a)
    JOIN tablec ON (tablec.a = tableb.a)
    LEFT OUTER JOIN tabled ON (tabled.a = tableb.a)
    LEFT JOIN tablee ON (tabled.a = tableb.a)
WHERE
    tablea.x = 1
    AND tableb.y = 1
GROUP BY
    tablea.a,
    tablec.c
ORDER BY
    tablea.a,
    tablec.c;

