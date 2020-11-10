-- test placeholder: perl pg_format samples/ex9.sql -p '<<(?:.*)?>>'
SELECT
    *
FROM
    projects
WHERE
    projectnumber IN << internalprojects >>
    AND username = << loginname >>;

CREATE TEMPORARY TABLE tt_monthly_data AS
WITH a1 AS (
    SELECT
        *
    FROM
        test1
)
SELECT
    ROUND(AVG(t1)) avg_da,
    ROUND(AVG(t2))
FROM
    a1;

