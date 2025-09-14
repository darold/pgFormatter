-- should fail, return type mismatch
CREATE EVENT TRIGGER regress_event_trigger ON ddl_command_start
    EXECUTE PROCEDURE pg_backend_pid();

-- OK
CREATE FUNCTION test_event_trigger ()
    RETURNS event_trigger
    AS $$
BEGIN
    RAISE NOTICE 'test_event_trigger: % %', tg_event, tg_tag;
END
$$
LANGUAGE plpgsql;

-- should fail, event triggers cannot have declared arguments
CREATE FUNCTION test_event_trigger_arg (name text)
    RETURNS event_trigger
    AS $$
BEGIN
    RETURN 1;
END
$$
LANGUAGE plpgsql;

-- should fail, SQL functions cannot be event triggers
CREATE FUNCTION test_event_trigger_sql ()
    RETURNS event_trigger
    AS $$
    SELECT
        1
$$
LANGUAGE sql;

-- should fail, no elephant_bootstrap entry point
CREATE EVENT TRIGGER regress_event_trigger ON elephant_bootstrap
    EXECUTE PROCEDURE test_event_trigger ();

-- OK
CREATE EVENT TRIGGER regress_event_trigger ON ddl_command_start
    EXECUTE PROCEDURE test_event_trigger ();

-- OK
CREATE EVENT TRIGGER regress_event_trigger_end ON ddl_command_end
    EXECUTE FUNCTION test_event_trigger ();

-- should fail, food is not a valid filter variable
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN food IN ('sandwich')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, sandwich is not a valid command tag
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('sandwich')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, create skunkcabbage is not a valid command tag
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('create table', 'create skunkcabbage')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have event triggers on event triggers
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('DROP EVENT TRIGGER')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have event triggers on global objects
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('CREATE ROLE')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have event triggers on global objects
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('CREATE DATABASE')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have event triggers on global objects
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('CREATE TABLESPACE')
        EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have same filter variable twice
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('create table') AND tag IN ('CREATE FUNCTION')
            EXECUTE PROCEDURE test_event_trigger ();

-- should fail, can't have arguments
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    EXECUTE PROCEDURE test_event_trigger ('argument not allowed');

-- OK
CREATE EVENT TRIGGER regress_event_trigger2 ON ddl_command_start
    WHEN tag IN ('create table', 'CREATE FUNCTION')
        EXECUTE PROCEDURE test_event_trigger ();

-- OK
COMMENT ON EVENT TRIGGER regress_event_trigger IS 'test comment';

-- drop as non-superuser should fail
CREATE ROLE regress_evt_user;

SET ROLE regress_evt_user;

CREATE EVENT TRIGGER regress_event_trigger_noperms ON ddl_command_start
    EXECUTE PROCEDURE test_event_trigger ();

RESET ROLE;

-- test enabling and disabling
ALTER EVENT TRIGGER regress_event_trigger DISABLE;

-- fires _trigger2 and _trigger_end should fire, but not _trigger
CREATE TABLE event_trigger_fire1 (
    a int
);

ALTER EVENT TRIGGER regress_event_trigger ENABLE;

SET session_replication_role = REPLICA;

-- fires nothing
CREATE TABLE event_trigger_fire2 (
    a int
);

ALTER EVENT TRIGGER regress_event_trigger ENABLE REPLICA;

-- fires only _trigger
CREATE TABLE event_trigger_fire3 (
    a int
);

ALTER EVENT TRIGGER regress_event_trigger ENABLE ALWAYS;

-- fires only _trigger
CREATE TABLE event_trigger_fire4 (
    a int
);

RESET session_replication_role;

-- fires all three
CREATE TABLE event_trigger_fire5 (
    a int
);

-- non-top-level command
CREATE FUNCTION f1 ()
    RETURNS int
    LANGUAGE plpgsql
    AS $$
BEGIN
    CREATE TABLE event_trigger_fire6 (
        a int
    );
    RETURN 0;
END
$$;

SELECT
    f1 ();

-- non-top-level command
CREATE PROCEDURE p1 ()
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TABLE event_trigger_fire7 (
        a int
    );
END
$$;

CALL p1 ();

-- clean up
ALTER EVENT TRIGGER regress_event_trigger DISABLE;

DROP TABLE event_trigger_fire2, event_trigger_fire3, event_trigger_fire4, event_trigger_fire5, event_trigger_fire6, event_trigger_fire7;

DROP ROUTINE f1 (), p1 ();

-- regress_event_trigger_end should fire on these commands
GRANT ALL ON TABLE event_trigger_fire1 TO public;

COMMENT ON TABLE event_trigger_fire1 IS 'here is a comment';

REVOKE ALL ON TABLE event_trigger_fire1 FROM public;

DROP TABLE event_trigger_fire1;

CREATE FOREIGN data wrapper useless;

CREATE SERVER useless_server FOREIGN data wrapper useless;

CREATE USER MAPPING FOR regress_evt_user SERVER useless_server;

ALTER DEFAULT privileges FOR ROLE regress_evt_user REVOKE DELETE ON tables FROM regress_evt_user;

-- alter owner to non-superuser should fail
ALTER EVENT TRIGGER regress_event_trigger OWNER TO regress_evt_user;

-- alter owner to superuser should work
ALTER ROLE regress_evt_user superuser;

ALTER EVENT TRIGGER regress_event_trigger OWNER TO regress_evt_user;

-- should fail, name collision
ALTER EVENT TRIGGER regress_event_trigger RENAME TO regress_event_trigger2;

-- OK
ALTER EVENT TRIGGER regress_event_trigger RENAME TO regress_event_trigger3;

-- should fail, doesn't exist any more
DROP EVENT TRIGGER regress_event_trigger;

-- should fail, regress_evt_user owns some objects
DROP ROLE regress_evt_user;

-- cleanup before next test
-- these are all OK; the second one should emit a NOTICE
DROP EVENT TRIGGER IF EXISTS regress_event_trigger2;

DROP EVENT TRIGGER IF EXISTS regress_event_trigger2;

DROP EVENT TRIGGER regress_event_trigger3;

DROP EVENT TRIGGER regress_event_trigger_end;

-- test support for dropped objects
CREATE SCHEMA schema_one AUTHORIZATION regress_evt_user;

CREATE SCHEMA schema_two AUTHORIZATION regress_evt_user;

CREATE SCHEMA audit_tbls AUTHORIZATION regress_evt_user;

CREATE TEMP TABLE a_temp_tbl ();

SET SESSION AUTHORIZATION regress_evt_user;

CREATE TABLE schema_one.table_one (
    a int
);

CREATE TABLE schema_one. "table two" (
    a int
);

CREATE TABLE schema_one.table_three (
    a int
);

CREATE TABLE audit_tbls.schema_one_table_two (
    the_value text
);

CREATE TABLE schema_two.table_two (
    a int
);

CREATE TABLE schema_two.table_three (
    a int,
    b text
);

CREATE TABLE audit_tbls.schema_two_table_three (
    the_value text
);

CREATE OR REPLACE FUNCTION schema_two.add (int, int)
    RETURNS int
    LANGUAGE plpgsql
    CALLED ON NULL INPUT
    AS $$
BEGIN
    RETURN coalesce($1, 0) + coalesce($2, 0);
END;
$$;

CREATE AGGREGATE schema_two.newton (
    BASETYPE = int,
    SFUNC = schema_two.add,
    STYPE = int
);

RESET SESSION AUTHORIZATION;

CREATE TABLE undroppable_objs (
    object_type text,
    object_identity text
);

INSERT INTO undroppable_objs
VALUES
    ('table', 'schema_one.table_three'),
    ('table', 'audit_tbls.schema_two_table_three');

CREATE TABLE dropped_objects (
    type text,
    schema text,
    object text
);

-- This tests errors raised within event triggers; the one in audit_tbls
-- uses 2nd-level recursive invocation via test_evtrig_dropped_objects().
CREATE OR REPLACE FUNCTION undroppable ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    obj record;
BEGIN
    PERFORM
        1
    FROM
        pg_tables
    WHERE
        tablename = 'undroppable_objs';
    IF NOT FOUND THEN
        RAISE NOTICE 'table undroppable_objs not found, skipping';
        RETURN;
    END IF;
    FOR obj IN
    SELECT
        *
    FROM
        pg_event_trigger_dropped_objects ()
        JOIN undroppable_objs USING (object_type, object_identity)
    LOOP
        RAISE EXCEPTION 'object % of type % cannot be dropped', obj.object_identity, obj.object_type;
    END LOOP;
END;
$$;

CREATE EVENT TRIGGER undroppable ON sql_drop
    EXECUTE PROCEDURE undroppable ();

CREATE OR REPLACE FUNCTION test_evtrig_dropped_objects ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    obj record;
BEGIN
    FOR obj IN
    SELECT
        *
    FROM
        pg_event_trigger_dropped_objects ()
        LOOP
            IF obj.object_type = 'table' THEN
                EXECUTE format('DROP TABLE IF EXISTS audit_tbls.%I', format('%s_%s', obj.schema_name, obj.object_name));
            END IF;
            INSERT INTO dropped_objects (type, schema, object)
                VALUES (obj.object_type, obj.schema_name, obj.object_identity);
        END LOOP;
END
$$;

CREATE EVENT TRIGGER regress_event_trigger_drop_objects ON sql_drop
    WHEN TAG IN ('drop table', 'drop function', 'drop view', 'drop owned', 'drop schema', 'alter table')
        EXECUTE PROCEDURE test_evtrig_dropped_objects ();

ALTER TABLE schema_one.table_one
    DROP COLUMN a;

DROP SCHEMA schema_one, schema_two CASCADE;

DELETE FROM undroppable_objs
WHERE object_identity = 'audit_tbls.schema_two_table_three';

DROP SCHEMA schema_one, schema_two CASCADE;

DELETE FROM undroppable_objs
WHERE object_identity = 'schema_one.table_three';

DROP SCHEMA schema_one, schema_two CASCADE;

SELECT
    *
FROM
    dropped_objects
WHERE
    SCHEMA IS NULL
    OR SCHEMA <> 'pg_toast';

DROP OWNED BY regress_evt_user;

SELECT
    *
FROM
    dropped_objects
WHERE
    type = 'schema';

DROP ROLE regress_evt_user;

DROP EVENT TRIGGER regress_event_trigger_drop_objects;

DROP EVENT TRIGGER undroppable;

CREATE OR REPLACE FUNCTION event_trigger_report_dropped ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    r record;
BEGIN
    FOR r IN
    SELECT
        *
    FROM
        pg_event_trigger_dropped_objects ()
        LOOP
            IF NOT r.normal AND NOT r.original THEN
                CONTINUE;
            END IF;
            RAISE NOTICE 'NORMAL: orig=% normal=% istemp=% type=% identity=% name=% args=%', r.original, r.normal, r.is_temporary, r.object_type, r.object_identity, r.address_names, r.address_args;
        END LOOP;
END;
$$;

CREATE EVENT TRIGGER regress_event_trigger_report_dropped ON sql_drop
    EXECUTE PROCEDURE event_trigger_report_dropped ();

CREATE SCHEMA evttrig
    CREATE TABLE one (
        col_a serial PRIMARY KEY,
        col_b text DEFAULT 'forty two')
    CREATE INDEX one_idx ON one (
        col_b)
    CREATE TABLE two (
        col_c integer CHECK (col_c > 0) REFERENCES one DEFAULT 42
);

-- Partitioned tables with a partitioned index
CREATE TABLE evttrig.parted (
    id int PRIMARY KEY
)
PARTITION BY RANGE (id);

CREATE TABLE evttrig.part_1_10 PARTITION OF evttrig.parted (id)
FOR VALUES FROM (1) TO (10);

CREATE TABLE evttrig.part_10_20 PARTITION OF evttrig.parted (id)
FOR VALUES FROM (10) TO (20)
PARTITION BY RANGE (id);

CREATE TABLE evttrig.part_10_15 PARTITION OF evttrig.part_10_20 (id)
FOR VALUES FROM (10) TO (15);

CREATE TABLE evttrig.part_15_20 PARTITION OF evttrig.part_10_20 (id)
FOR VALUES FROM (15) TO (20);

ALTER TABLE evttrig.two
    DROP COLUMN col_c;

ALTER TABLE evttrig.one
    ALTER COLUMN col_b DROP DEFAULT;

ALTER TABLE evttrig.one
    DROP CONSTRAINT one_pkey;

DROP INDEX evttrig.one_idx;

DROP SCHEMA evttrig CASCADE;

DROP TABLE a_temp_tbl;

DROP EVENT TRIGGER regress_event_trigger_report_dropped;

-- only allowed from within an event trigger function, should fail
SELECT
    pg_event_trigger_table_rewrite_oid ();

-- test Table Rewrite Event Trigger
CREATE OR REPLACE FUNCTION test_evtrig_no_rewrite ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'rewrites not allowed';
END;
$$;

CREATE EVENT TRIGGER no_rewrite_allowed ON table_rewrite
    EXECUTE PROCEDURE test_evtrig_no_rewrite ();

CREATE TABLE rewriteme (
    id serial PRIMARY KEY,
    foo float,
    bar timestamptz
);

INSERT INTO rewriteme
SELECT
    x * 1.001
FROM
    generate_series(1, 500) AS t (x);

ALTER TABLE rewriteme
    ALTER COLUMN foo TYPE numeric;

ALTER TABLE rewriteme
    ADD COLUMN baz int DEFAULT 0;

-- test with more than one reason to rewrite a single table
CREATE OR REPLACE FUNCTION test_evtrig_no_rewrite ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Table ''%'' is being rewritten (reason = %)', pg_event_trigger_table_rewrite_oid ()::regclass, pg_event_trigger_table_rewrite_reason ();
END;
$$;

ALTER TABLE rewriteme
    ADD COLUMN onemore int DEFAULT 0,
    ADD COLUMN another int DEFAULT -1,
    ALTER COLUMN foo TYPE numeric(10, 4);

-- shouldn't trigger a table_rewrite event
ALTER TABLE rewriteme
    ALTER COLUMN foo TYPE numeric(12, 4);

BEGIN;
SET timezone TO 'UTC';
ALTER TABLE rewriteme
    ALTER COLUMN bar TYPE timestamp;
SET timezone TO '0';
ALTER TABLE rewriteme
    ALTER COLUMN bar TYPE timestamptz;
SET timezone TO 'Europe/London';
ALTER TABLE rewriteme
    ALTER COLUMN bar TYPE timestamp;
-- does rewrite
ROLLBACK;

-- typed tables are rewritten when their type changes.  Don't emit table
-- name, because firing order is not stable.
CREATE OR REPLACE FUNCTION test_evtrig_no_rewrite ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Table is being rewritten (reason = %)', pg_event_trigger_table_rewrite_reason ();
END;
$$;

CREATE TYPE rewritetype AS (
    a int
);

CREATE TABLE rewritemetoo1 OF rewritetype;

CREATE TABLE rewritemetoo2 OF rewritetype;

ALTER TYPE rewritetype
    ALTER attribute a TYPE text CASCADE;

-- but this doesn't work
CREATE TABLE rewritemetoo3 (
    a rewritetype
);

ALTER TYPE rewritetype
    ALTER attribute a TYPE varchar CASCADE;

DROP TABLE rewriteme;

DROP EVENT TRIGGER no_rewrite_allowed;

DROP FUNCTION test_evtrig_no_rewrite ();

-- test Row Security Event Trigger
RESET SESSION AUTHORIZATION;

CREATE TABLE event_trigger_test (
    a integer,
    b text
);

CREATE OR REPLACE FUNCTION start_command ()
    RETURNS event_trigger
    AS $$
BEGIN
    RAISE NOTICE '% - ddl_command_start', tg_tag;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION end_command ()
    RETURNS event_trigger
    AS $$
BEGIN
    RAISE NOTICE '% - ddl_command_end', tg_tag;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drop_sql_command ()
    RETURNS event_trigger
    AS $$
BEGIN
    RAISE NOTICE '% - sql_drop', tg_tag;
END;
$$
LANGUAGE plpgsql;

CREATE EVENT TRIGGER start_rls_command ON ddl_command_start
    WHEN TAG IN ('CREATE POLICY', 'ALTER POLICY', 'DROP POLICY')
        EXECUTE PROCEDURE start_command ();

CREATE EVENT TRIGGER end_rls_command ON ddl_command_end
    WHEN TAG IN ('CREATE POLICY', 'ALTER POLICY', 'DROP POLICY')
        EXECUTE PROCEDURE end_command ();

CREATE EVENT TRIGGER sql_drop_command ON sql_drop
    WHEN TAG IN ('DROP POLICY')
        EXECUTE PROCEDURE drop_sql_command ();

CREATE POLICY p1 ON event_trigger_test
    USING (FALSE);

ALTER POLICY p1 ON event_trigger_test
    USING (TRUE);

ALTER POLICY p1 ON event_trigger_test RENAME TO p2;

DROP POLICY p2 ON event_trigger_test;

DROP EVENT TRIGGER start_rls_command;

DROP EVENT TRIGGER end_rls_command;

DROP EVENT TRIGGER sql_drop_command;

