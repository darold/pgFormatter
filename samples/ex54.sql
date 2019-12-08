SELECT CASE WHEN 1 = 1 THEN 2 ELSE 3 end::text AS col1, col2, col3 FROM tb1;

SELECT ( CASE WHEN 1 = 1 THEN 2 ELSE 3 END)::text AS col1, col2, col3 FROM tb1;

UPDATE point_tbl SET f1[0] = NULL WHERE f1::text = '(10,10)'::point::text RETURNING *;

SELECT 'TrUe'::text::boolean AS true, 'fAlse'::text::boolean AS false;

SELECT true::boolean::text AS true, false::boolean::text AS false;

CREATE PROCEDURE testns.bar() AS 'select 1' LANGUAGE sql;

ALTER TABLE test9b
    ALTER COLUMN b TYPE priv_testdomain1;

CREATE TYPE test7b AS (
    a int,
    b priv_testdomain1
);
        CREATE TYPE test8b AS (
            a int,
            b int
);
        ALTER TYPE test8b
            ADD ATTRIBUTE c priv_testdomain1;


CREATE OR REPLACE PROCEDURE foo (
)
AS $BODY$
DECLARE
BEGIN
    INSERT INTO bar (COLUMN)
    VALUES (1);
COMMIT;
    BEGIN
        INSERT INTO bar (COLUMN)
        VALUES (2);
    COMMIT;
        BEGIN
            INSERT INTO bar (COLUMN)
            VALUES (3);
        COMMIT;
END;
END;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TEXT SEARCH PARSER addr_ts_prs (
    START = prsd_start,
    gettoken = prsd_nexttoken,
END = prsd_end,
lextypes = prsd_lextype
);

CREATE FUNCTION fonction_reference(refcursor) RETURNS refcursor AS $$
BEGIN
    OPEN $1 FOR SELECT col FROM test;
    RETURN $1;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION foo ()
    RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.role NOT IN ( SELECT rolname FROM pg_authid) THEN
        RAISE EXCEPTION 'role % does not exist.', NEW.role;
    END IF;
END;
$$
LANGUAGE 'plpgsql';


DO $$
DECLARE xml_declaration text := '<?xml version="1.0" encoding="ISO-8859-1"?>';
degree_symbol text;
res xml[];
BEGIN
    -- Per the documentation, except when the server encoding is UTF8, xpath()
    -- may not work on non-ASCII data.  The untranslatable_character and
    -- undefined_function traps below, currently dead code, will become relevant
    -- if we remove this limitation.
    IF current_setting('server_encoding') <> 'UTF8' THEN
        RAISE LOG 'skip: encoding % unsupported for xpath', current_setting('server_encoding');
        RETURN;
    END IF;
    degree_symbol := convert_from('\xc2b0', 'UTF8');
    res := xpath('text()', (xml_declaration || '<x>' || degree_symbol || '</x>')::xml);
    IF degree_symbol <> res[1]::text THEN
        RAISE 'expected % (%), got % (%)', degree_symbol, convert_to(degree_symbol, 'UTF8'), res[1], convert_to(res[1]::text, 'UTF8');
    END IF;
EXCEPTION
            -- character with byte sequence 0xc2 0xb0 in encoding "UTF8" has no equivalent in encoding "LATIN8"
        WHEN untranslatable_character
            -- default conversion function for encoding "UTF8" to "MULE_INTERNAL" does not exist
            OR undefined_function
            -- unsupported XML feature
            OR feature_not_supported THEN
            RAISE LOG 'skip: %', SQLERRM;
END
$$;

CREATE FUNCTION wait_for_stats ()
    RETURNS void
    AS $$
DECLARE
    start_time timestamptz := clock_timestamp();
    updated1 bool;
    updated2 bool;
    updated3 bool;
    updated4 bool;
BEGIN
    -- we don't want to wait forever; loop will exit after 30 seconds
    FOR i IN 1..300 LOOP
        -- With parallel query, the seqscan and indexscan on tenk2 might be done
        -- in parallel worker processes, which will send their stats counters
        -- asynchronously to what our own session does.  So we must check for
        -- those counts to be registered separately from the update counts.
        -- check to see if seqscan has been sensed
        SELECT
            (st.seq_scan >= pr.seq_scan + 1) INTO updated1
        FROM
            pg_stat_user_tables AS st,
            pg_class AS cl,
            prevstats AS pr
        WHERE
            st.relname = 'tenk2'
            AND cl.relname = 'tenk2';
        -- check to see if indexscan has been sensed
        SELECT
            (st.idx_scan >= pr.idx_scan + 1) INTO updated2
        FROM
            pg_stat_user_tables AS st,
            pg_class AS cl,
            prevstats AS pr
        WHERE
            st.relname = 'tenk2'
            AND cl.relname = 'tenk2';
        -- check to see if all updates have been sensed
        SELECT
            (n_tup_ins > 0) INTO updated3
        FROM
            pg_stat_user_tables
        WHERE
            relname = 'trunc_stats_test4';
        -- We must also check explicitly that pg_stat_get_snapshot_timestamp has
        -- advanced, because that comes from the global stats file which might
        -- be older than the per-DB stats file we got the other values from.
        SELECT
            (pr.snap_ts < pg_stat_get_snapshot_timestamp ()) INTO updated4
        FROM
            prevstats AS pr;
        exit
        WHEN updated1
            AND updated2
            AND updated3
            AND updated4;
        -- wait a little
        PERFORM
            pg_sleep_for ('100 milliseconds');
        -- reset stats snapshot so we can test again
        PERFORM
            pg_stat_clear_snapshot();
    END LOOP;
    -- report time waited in postmaster log (where it won't change test output)
    raise log 'wait_for_stats delayed % seconds', extract(epoch FROM clock_timestamp() - start_time);
    END
$$
LANGUAGE plpgsql;

DO $$
DECLARE
    objtype text;
    names text[];
    args text[];
BEGIN
    FOR objtype IN VALUES ('table'),  ('publication relation')
    LOOP
        FOR names IN VALUES ('{eins}'), ('{eins, zwei, drei}')
        LOOP
            FOR args IN VALUES ('{}'), ('{integer}')
            LOOP
                BEGIN
                    PERFORM
                        pg_get_object_address(objtype, names, args);
                    EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING 'error for %,%,%: %', objtype, names, args, sqlerrm;
                    END;
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

-- test successful cases
WITH objects (
    TYPE,
    name,
    args
) AS (
    VALUES ('table', '{addr_nsp, gentable}'::text[], '{}'::text[]),
        ('index', '{addr_nsp, parttable_pkey}', '{}'),
        ('sequence', '{addr_nsp, gentable_a_seq}', '{}'),
        -- toast table
        ('view', '{addr_nsp, genview}', '{}'),
        -- large object
        ('operator', '{+}', '{int4, int4}'),
        -- database
        -- tablespace
        ('foreign-data wrapper', '{addr_fdw}', '{}'),
        -- extension
        -- event trigger
        ('policy', '{addr_nsp, gentable, genpol}', '{}'),
        ('statistics object', '{addr_nsp, gentable_stat}', '{}'))
SELECT
    (pg_identify_object (addr1.classid, addr1.objid, addr1.objsubid)).*,
    -- test roundtrip through pg_identify_object_as_address
    ROW (pg_identify_object (addr1.classid, addr1.objid, addr1.objsubid)) = ROW (pg_identify_object (addr2.classid, addr
2.objid, addr2.objsubid))
FROM
    objects,
    pg_get_object_address(TYPE, name, args) addr1,
    pg_identify_object_as_address(classid, objid, objsubid) ioa (typ, nms, args),
    pg_get_object_address(typ, nms, ioa.args) AS addr2
ORDER BY
    addr1.classid,
    addr1.objid,
    addr1.objsubid;
---
--- Cleanup resources
---
DROP FOREIGN DATA WRAPPER addr_fdw CASCADE;
DROP PUBLICATION addr_pub;
DROP SUBSCRIPTION addr_sub;
DROP SCHEMA addr_nsp CASCADE;
DROP OWNED BY regress_addr_user;
DROP USER regress_addr_user;

CREATE PROCEDURE insert_data (a integer, b integer)
LANGUAGE SQL
AS $$
    INSERT INTO tbl
    VALUES (a);

INSERT INTO tbl
    VALUES (b);

$$;

