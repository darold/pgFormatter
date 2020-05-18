CREATE TABLE test (
    col text
);

INSERT INTO test
    VALUES ('123');

CREATE FUNCTION fonction_reference (refcursor)
    RETURNS refcursor
    AS $$
BEGIN
    OPEN $1 FOR
        SELECT
            col
        FROM
            test;
    RETURN $1;
END;
$$
LANGUAGE plpgsql;

BEGIN;
SELECT
    fonction_reference ('curseur_fonction');
FETCH ALL IN curseur_fonction;
COMMIT;

