CREATE OR REPLACE FUNCTION foo ()
    RETURNS trigger
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

