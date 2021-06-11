SELECT
    date_trunc('month', 日期)
FROM
    ti;

SELECT
    CASE WHEN test = 1 THEN
        (test_table.end_date - ('1 month'::interval) - '1 day'::interval)
    ELSE
        (test_table.end_date - (test_table.number_days * '1 day'::interval) - '1 day'::interval)::date
    END test_start_date
FROM
    test_table;

