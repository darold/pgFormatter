--
-- Verify system catalog foreign key relationships
--
DO $doblock$
DECLARE
    fk record;
    nkeys integer;
    cmd text;
    err record;
BEGIN
    FOR fk IN
    SELECT
        *
    FROM
        pg_get_catalog_foreign_keys ()
    LOOP
        RAISE NOTICE 'checking % % => % %', fk.fktable, fk.fkcols, fk.pktable, fk.pkcols;
        nkeys := array_length(fk.fkcols, 1);
        cmd := 'SELECT ctid';
        FOR i IN 1..nkeys LOOP
            cmd := cmd || ', ' || quote_ident(fk.fkcols[i]);
        END LOOP;
        IF fk.is_array THEN
            cmd := cmd || ' FROM (SELECT ctid';
            FOR i IN 1..nkeys - 1 LOOP
                cmd := cmd || ', ' || quote_ident(fk.fkcols[i]);
            END LOOP;
            cmd := cmd || ', unnest(' || quote_ident(fk.fkcols[nkeys]);
            cmd := cmd || ') as ' || quote_ident(fk.fkcols[nkeys]);
            cmd := cmd || ' FROM ' || fk.fktable::text || ') fk WHERE ';
        ELSE
            cmd := cmd || ' FROM ' || fk.fktable::text || ' fk WHERE ';
        END IF;
        IF fk.is_opt THEN
            FOR i IN 1..nkeys LOOP
                cmd := cmd || quote_ident(fk.fkcols[i]) || ' != 0 AND ';
            END LOOP;
        END IF;
        cmd := cmd || 'NOT EXISTS(SELECT 1 FROM ' || fk.pktable::text || ' pk WHERE ';
        FOR i IN 1..nkeys LOOP
            IF i > 1 THEN
                cmd := cmd || ' AND ';
            END IF;
            cmd := cmd || 'pk.' || quote_ident(fk.pkcols[i]);
            cmd := cmd || ' = fk.' || quote_ident(fk.fkcols[i]);
        END LOOP;
        cmd := cmd || ')';
        -- raise notice 'cmd = %', cmd;
        FOR err IN EXECUTE cmd LOOP
            RAISE warning 'FK VIOLATION IN %(%): %', fk.fktable, fk.fkcols, err;
        END LOOP;
    END LOOP;
END
$doblock$;

