--
-- SELECT_DISTINCT_ON
--
SELECT DISTINCT ON (string4)
    string4,
    two,
    ten
FROM
    tmp
ORDER BY
    string4 USING <,
    two USING >,
    ten USING <;

-- this will fail due to conflict of ordering requirements
SELECT DISTINCT ON (string4, ten)
    string4,
    two,
    ten
FROM
    tmp
ORDER BY
    string4 USING <,
    two USING <,
    ten USING <;

SELECT DISTINCT ON (string4, ten)
    string4,
    ten,
    two
FROM
    tmp
ORDER BY
    string4 USING <,
    ten USING >,
    two USING <;

-- bug #5049: early 8.4.x chokes on volatile DISTINCT ON clauses
SELECT DISTINCT ON (1)
    floor(random()) AS r,
    f1
FROM
    int4_tbl
ORDER BY
    1,
    2;

