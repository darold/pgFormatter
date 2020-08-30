GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA foo TO role_bar, role_baz;

SELECT
    *
FROM
    t
WHERE
    a IS NOT DISTINCT FROM b;

-- Deploy schemas/custom/grants/grant_schema_to_authenticated to pg
-- requires: schemas/custom/schema
BEGIN;
GRANT USAGE ON SCHEMA custom TO authenticated;
GRANT USAGE ON SCHEMA custom TO authenticated;
COMMIT;

