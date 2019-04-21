SELECT a, b, c, d
FROM t_1, t_2, t3
WHERE a = 10
    AND b = 10
    AND c = 10
    AND d IN (1, 2, 3, 4, 5, 6, 7);

SELECT a, b, c, d
FROM t_1, t_2, (
        SELECT *
        FROM t6) AS t3, t4
WHERE a = 10
    AND b = 10
    AND c = 10
    AND d IN (1, 2, 3, 4, 5, 6, 7);

