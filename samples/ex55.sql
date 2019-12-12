CREATE FUNCTION job_next ()
    RETURNS SETOF job
    AS $$
DECLARE
    id uuid;
BEGIN
    SELECT
        id INTO id
    FROM
        job
    WHERE
        state = 'sched'
        AND scheduled >= now()
    ORDER BY
        scheduled,
        modified
    LIMIT 1
FOR UPDATE SKIP LOCKED;  -- ### 1 indent lost
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM (
    SELECT
        *
    FROM
        mytable
    FOR UPDATE) AS ss
WHERE
    col1 = 5;

BEGIN;
SELECT
    *
FROM
    mytable
WHERE
    KEY = 1
FOR NO KEY UPDATE;
END;
