CREATE POLICY "My policy" ON mytable
    FOR SELECT TO myrole
        USING (_is_org_member ((
            SELECT
                n.org_id
            FROM
                networks n
            WHERE
                network_id = n.id LIMIT 1)));

SELECT
    1.2e-7::double precision;

SELECT
    1.2e+7::double precision;

SELECT
    12e+7::double precision;

CREATE OR REPLACE FUNCTION INCREMENT (i integer)
    RETURNS integer
    AS $$
BEGIN
    IF i IS NULL THEN
        RAISE EXCEPTION 'i is null'
            USING errcode = 'invalid_parameter_value';
        END IF;
        RETURN i + 1;
END;
$$
LANGUAGE plpgsql;

-- atlas:txmode none

-- Create a table.
CREATE TABLE t1 (
    a integer PRIMARY KEY
);

-- Cause migrations to fail.
INSERT INTO t1
VALUES
    (1),
    (1);

