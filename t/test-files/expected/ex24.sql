SELECT
    id,
    count(test),
    CASE WHEN TRUE THEN
        1
    END AS looks_good,
    count(
        CASE WHEN TRUE THEN
            1
        END) AS looks_wrong_and_indent_is_off,
    count(
        CASE WHEN FALSE THEN
            1
        END) AS looks_wrong
FROM
    test;

