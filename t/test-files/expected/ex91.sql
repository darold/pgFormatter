-- Issue #437: USING clause inside a loop must not shift the following code
CREATE FUNCTION f (p int)
    RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    n int;
    s text;
    r record;
BEGIN
    FOR i IN 1..2 LOOP
        EXECUTE s INTO n
        USING p;
    END LOOP;
    RAISE NOTICE 'done';
    FOR i IN 1..2 LOOP
        FOR j IN 1..2 LOOP
            IF p > 0 THEN
                EXECUTE s INTO n
                USING p, i;
            ELSE
                EXECUTE s
                USING j;
            END IF;
        END LOOP;
        CASE p
        WHEN 1 THEN
            EXECUTE s
            USING p;
        ELSE
            RAISE NOTICE 'x';
        END CASE;
    END LOOP;
    FOR i IN 1..2 LOOP
        DELETE FROM t USING u
        WHERE t.id = u.id;
    END LOOP;
    FOR i IN 1..2 LOOP
        RAISE EXCEPTION 'x'
            USING hint = 'y';
    END LOOP;
    FOR i IN 1..2 LOOP
        RAISE EXCEPTION 'x'
            USING errcode = 'P0001';
    END LOOP;
    FOR r IN EXECUTE s
    USING p LOOP
        RAISE NOTICE 'r';
    END LOOP;
    RAISE NOTICE 'end';
END
$$;

