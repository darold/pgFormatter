INSERT INTO table_a (id, name, kind, age)
SELECT
    id,
    name,
    (
        SELECT
            kind
        FROM
            kinds
        WHERE
            name = 'dog'
        LIMIT 1),
    age
FROM
    table_b;

SELECT
    id,
    (
        SELECT
            kind
        FROM
            kinds
        WHERE
            x = 1),
    age,
    (
        SELECT
            kind
        FROM
            kinds
        ORDER BY
            1 OFFSET 2),
    name
FROM
    t;

SELECT
    id,
    (
        SELECT
            a,
            (
                SELECT
                    b
                FROM
                    u
                LIMIT 1),
            c
        FROM
            v
        GROUP BY
            a FETCH FIRST 1 ROW ONLY),
    age
FROM
    t;

