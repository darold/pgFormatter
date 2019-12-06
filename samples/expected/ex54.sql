SELECT
    CASE WHEN 1 = 1 THEN
        2
    ELSE
        3
    END::text AS col1,
    col2,
    col3
FROM
    tb1;

SELECT
    (
        CASE WHEN 1 = 1 THEN
            2
        ELSE
            3
        END)::text AS col1,
    col2,
    col3
FROM
    tb1;

UPDATE
    point_tbl
SET
    f1[0] = NULL
WHERE
    f1::text = '(10,10)'::point::text
RETURNING
    *;

SELECT
    'TrUe'::text::boolean AS true,
    'fAlse'::text::boolean AS false;

SELECT
    TRUE::boolean::text AS true,
    FALSE::boolean::text AS false;

