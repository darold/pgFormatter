-- Issue #177: closing parenthesis of a subquery on its own line (--matching-paren-newline)
-- and indentation of the condition following a subquery inside a subquery
SELECT
    cntrycode,
    count(*) AS numcust,
    sum(c_acctbal) AS totacctbal
FROM (
    SELECT
        substring(c_phone FROM 1 FOR 2) AS cntrycode,
        c_acctbal
    FROM
        customer
    WHERE
        substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17')
        AND c_acctbal > (
            SELECT
                avg(c_acctbal)
            FROM
                customer
            WHERE
                c_acctbal > 0.00
                AND substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17'))
        AND NOT EXISTS (
            SELECT
                *
            FROM
                orders
            WHERE
                o_custkey = c_custkey)) AS custsale
GROUP BY
    cntrycode
ORDER BY
    cntrycode;

SELECT
    s.a
FROM (
    SELECT
        a
    FROM
        t
    WHERE
        a = 1
        AND b > (
            SELECT
                x
            FROM
                u
            WHERE
                y = 1)
        AND c <> ALL (
            SELECT
                z
            FROM
                v)
        AND d IN (
            SELECT
                w
            FROM
                x)
    GROUP BY
        a) s
WHERE
    s.a = 1;

SELECT
    *
FROM (
    SELECT
        1
    UNION ALL (
        SELECT
            2)) s1
    CROSS JOIN LATERAL ((
            SELECT
                3)
    UNION ALL (
        SELECT
            4)) s2;

