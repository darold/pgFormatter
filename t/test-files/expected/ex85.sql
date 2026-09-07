SELECT
    price.column1
FROM (
    SELECT
        library.column1,
        librarystat.column2
    FROM
        library
        LEFT OUTER JOIN db1.v_table3 librarystat ON librarystat.column1 = library.column1
        AND librarystat.column2 = library.column2) AS price
WHERE
    price.column1 < 'R45';

SELECT
    test_c.column1
FROM (
    SELECT
        test_1a.column1
    FROM
        dual
        CROSS JOIN (
            SELECT
                max(2) AS test_b
            FROM
                dual) test_1b) test_c;

