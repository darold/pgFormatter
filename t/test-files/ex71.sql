ALTER TABLE foo ADD COLUMN bar INT;

CREATE OR REPLACE PROCEDURE do_something ()
LANGUAGE plpgsql
AS $$
DECLARE
    salt text;
BEGIN
    -- Create a temporary table
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_id (
        id varchar
    ) ON COMMIT DELETE ROWS;
    TRUNCATE TABLE temp_id;
    INSERT INTO temp_id SELECT id FROM jones;
    INSERT INTO temp_id SELECT id FROM freds;
END;
$$
