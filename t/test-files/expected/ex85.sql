DO $$
BEGIN
    IF TRUE THEN
        CREATE TABLE t (
            id int DEFAULT abs(-1)
        );
        PERFORM
            1;
    ELSIF FALSE THEN
        CREATE TEMP TABLE t2 (
            id int
        );
    ELSE
        PERFORM
            2;
    END IF;
    PERFORM
        3;
END
$$;

