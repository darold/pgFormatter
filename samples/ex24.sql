SELECT
    id,
    count(test),
    CASE WHEN true THEN 1 END AS looks_good,
    count( CASE WHEN true THEN 1 END) AS looks_wrong_and_indent_is_off,
    count( CASE WHEN false THEN 1 END) AS looks_wrong
FROM test;
