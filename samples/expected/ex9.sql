-- test placeholder: perl pg_format samples/ex9.sql -p '<<(?:.*)?>>'
SELECT
    *
FROM
    projects
WHERE
    projectnumber IN << internalprojects >>
    AND username = << loginname >>;

