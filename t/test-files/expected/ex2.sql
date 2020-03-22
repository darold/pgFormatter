SELECT
    n.nspname AS "Schema",
    p.proname AS "Name",
    pg_catalog.pg_get_function_result(p.oid) AS "Result data type",
    pg_catalog.pg_get_function_arguments(p.oid) AS "Argument data types",
    CASE WHEN p.proisagg THEN
        'agg'
    WHEN p.proiswindow THEN
        'window'
    WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN
        'trigger'
    ELSE
        'normal'
    END AS "Type"
FROM
    pg_catalog.pg_proc p
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE
    p.proname ~ '^(version)$'
    AND pg_catalog.pg_function_is_visible(p.oid)
ORDER BY
    1,
    2,
    4;

SELECT
    CASE WHEN (FALSE) THEN
        0
    WHEN (TRUE) THEN
        2
    END AS dummy1
FROM
    my_table;

CREATE OR REPLACE FUNCTION task_job_maint_after ()
    RETURNS TRIGGER
    AS $$
BEGIN
    CASE NEW.state
    WHEN 'final' THEN
        NOTIFY task_job_final;
    ELSE
        NULL;
    END CASE;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

