CREATE OR REPLACE FUNCTION foo ()
    RETURNS TRIGGER
    AS $$
BEGIN
    CREATE TEMPORARY TABLE tb (
        id integer
    );
    SELECT
        *
    FROM
        NOTHING;
END;
$$
LANGUAGE 'plpgsql';

