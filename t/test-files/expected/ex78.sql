CREATE OR REPLACE FUNCTION myf ()
    RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    foo := 0.5;
    bar := 1;
    baz := GREATEST (baz, 1.0);
    CASE result.attribute_value
    WHEN 'asdf' THEN
        foo := 0.5;
        bar := 1;
        baz := GREATEST (baz, 1.0);
    END CASE;
END;
$$;

SELECT
    z.zoo_id,
    z.log_date,
    a.firstname,
    a.lastname,
    zb.break_start
FROM
    zoo z
    JOIN animals a ON z.animal_id = a.animal_id
        AND z.zoo_id = 9
    JOIN zoo_breaks zb ON z.zoo_id = zb.zoo_id
        AND Date_trunc('minute', zb.break_start) - Date_trunc('minute', z.opening_time) < '2 hours'::interval
        AND zb.automatic = TRUE
WHERE
    z.log_date >= '2022-01-01'
ORDER BY
    z.worker_id;

