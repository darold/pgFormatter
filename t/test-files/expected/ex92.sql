-- LOOP following a closing parenthesis must be at the same level as WHILE/FOR
CREATE FUNCTION f (p int, a int[])
    RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    i int := 1;
    n int;
    r record;
BEGIN
    WHILE (i < 3)
    LOOP
        i := i + 1;
    END LOOP;
    WHILE i < array_length(a, 1)
    LOOP
        i := i + 1;
    END LOOP;
    FOR j IN 1..2 LOOP
        WHILE NOT EXISTS (
            SELECT
                1
            FROM
                t
            WHERE
                id = i)
        LOOP
            i := i + 1;
        END LOOP;
        WHILE (i < 3)
            AND (n > 0)
        LOOP
            i := i + 1;
        END LOOP;
    END LOOP;
    IF p = 0 THEN
        RAISE NOTICE 'z';
    ELSIF p > 1 THEN
        FOR r IN
        SELECT
            *
        FROM
            t
        WHERE
            id IN (1, 2)
        LOOP
            RAISE NOTICE 'r';
        END LOOP;
    END IF;
    FOR r IN
    SELECT
        *
    FROM
        a
        JOIN b USING (x, y)
    LOOP
        RAISE NOTICE 'j';
    END LOOP;
    RAISE NOTICE 'end';
END
$$;

