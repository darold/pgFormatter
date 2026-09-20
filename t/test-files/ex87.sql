-- Join indentation inside a sub-query: a join on a plain relation must align
-- with that relation, one level below FROM, exactly as it does at top level.
SELECT price.column1
FROM (
    SELECT library.column1, librarystat.column2
    FROM library
    LEFT OUTER JOIN db1.v_table3 librarystat
        ON librarystat.column1 = library.column1
    LEFT OUTER JOIN db1.v_table3 librarystat2
        ON librarystat2.column1 = library.column1
) AS price;

-- Top level (must be unchanged).
SELECT a.c1, b.c2
FROM library a
LEFT OUTER JOIN t3 b ON b.c1 = a.c1;

-- Several joins in a sub-query.
SELECT x.c1
FROM (
    SELECT a.c1
    FROM t1 a
    INNER JOIN t2 b ON b.a = a.a
    LEFT JOIN t3 c ON c.a = a.a
) AS x;

-- Doubly nested sub-query.
SELECT *
FROM (
    SELECT *
    FROM (
        SELECT a.c1
        FROM library a
        RIGHT OUTER JOIN t3 b ON b.c1 = a.c1
    ) y
) z;

-- When the joined relation is itself a parenthesised sub-query the join must
-- stay aligned with the FROM keyword, not be pushed one level deeper.
SELECT o.c1
FROM (
    SELECT s.c1
    FROM (
        SELECT c1 FROM base
    ) AS s
    LEFT OUTER JOIN t3 st ON st.c1 = s.c1
) AS o;
