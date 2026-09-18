-- Procedural existence checks must open an indentation level, unlike DDL guards.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM widgets WHERE id = 1 AND enabled) THEN
        IF EXISTS (SELECT 1 FROM other_widgets WHERE id = 1 OR id = 2) AND true THEN
            EXECUTE $sql$SELECT 1;$sql$;
        ELSE
            RAISE NOTICE 'missing';
        END IF;
    ELSE
        PERFORM 2;
    END IF;
    PERFORM 3;
END
$$;

CREATE TABLE IF NOT EXISTS widgets (id integer, enabled boolean);
DROP TABLE IF EXISTS widgets;
