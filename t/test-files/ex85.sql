SELECT
    tyap0.tyap_code
    , appel.frap_tyap_code
FROM
    tyap
    LEFT OUTER JOIN ab_frap@link_serveur appel ON appel.frap_tyap_code = tyap.tyap_code
        AND appel.frap_imme_no = tyap.tyap_imme_no
    LEFT OUTER JOIN bud ON bud.budg_tyap_direct = tyap.tyap_direct;

SELECT
    a.id
FROM
    a
    INNER JOIN b ON b.id = a.id
    CROSS JOIN c ON true
    NATURAL JOIN d ON true
    RIGHT JOIN e ON e.id = a.id
    FULL JOIN f ON f.id = a.id;

SELECT
    x.v
FROM
    x
    JOIN y ON y.k = x.k
    LEFT JOIN z ON z.k = x.k;
