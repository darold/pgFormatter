SELECT
    regexp_matches('foobarbequebazilbarfbonk', '(b[^b]+)(b[^b]+)', 'g');

SELECT
    SUBSTRING('XY1234Z', 'Y*([0-9]{1,3})');

SELECT
    m.name AS mname,
    pname
FROM
    manufacturers m,
    LATERAL get_product_names (m.id) pname;

SELECT
    m.name AS mname,
    pname
FROM
    manufacturers m
    LEFT JOIN LATERAL get_product_names (m.id) pname ON TRUE;

WITH one AS (
    SELECT
        1 one
)
SELECT
    count(one),
    avg(one)
FROM
    one;

