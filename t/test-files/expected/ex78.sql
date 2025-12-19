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

