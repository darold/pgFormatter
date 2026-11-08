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

-- should fail, can't call it as a plain function
SELECT
    test_event_trigger ();

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
    object_type text,
    schema_name text,
    object_name text,
    object_identity text,
    address_names text[],
    address_args text[],
    is_temporary bool,
    original bool,
    normal bool
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
        INSERT INTO dropped_objects (object_type, schema_name, object_name, object_identity, address_names, address_args, is_temporary, original, normal)
            VALUES (obj.object_type, obj.schema_name, obj.object_name, obj.object_identity, obj.address_names, obj.address_args, obj.is_temporary, obj.original, obj.normal);
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

-- exclude TOAST objects because they have unstable names
SELECT
    *
FROM
    dropped_objects
WHERE
    schema_name IS NULL
    OR schema_name <> 'pg_toast';

DROP OWNED BY regress_evt_user;

SELECT
    *
FROM
    dropped_objects
WHERE
    object_type = 'schema';

DROP ROLE regress_evt_user;

DROP EVENT TRIGGER regress_event_trigger_drop_objects;

DROP EVENT TRIGGER undroppable;

-- Event triggers on relations.
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
        RAISE NOTICE 'NORMAL: orig=% normal=% istemp=% type=% identity=% schema=% name=% addr=% args=%', r.original, r.normal, r.is_temporary, r.object_type, r.object_identity, r.schema_name, r.object_name, r.address_names, r.address_args;
    END LOOP;
END;
$$;

CREATE EVENT TRIGGER regress_event_trigger_report_dropped ON sql_drop
    EXECUTE PROCEDURE event_trigger_report_dropped ();

CREATE OR REPLACE FUNCTION event_trigger_report_end ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
    SELECT
        *
    FROM
        pg_event_trigger_ddl_commands ()
    LOOP
        RAISE NOTICE 'END: command_tag=% type=% identity=%', r.command_tag, r.object_type, r.object_identity;
    END LOOP;
END;
$$;

CREATE EVENT TRIGGER regress_event_trigger_report_end ON ddl_command_end
    EXECUTE PROCEDURE event_trigger_report_end ();

CREATE SCHEMA evttrig
    CREATE TABLE one (
        col_a serial PRIMARY KEY,
        col_b text DEFAULT 'forty two',
        col_c serial)
    CREATE INDEX one_idx ON one (
        col_b)
    CREATE TABLE two (
        col_c integer CHECK (col_c > 0) REFERENCES one DEFAULT 42)
    CREATE TABLE id (
        col_d int NOT NULL GENERATED ALWAYS AS IDENTITY)
    CREATE VIEW one_view AS
    SELECT
        *
    FROM
        two;

-- View with column additions
CREATE OR REPLACE VIEW evttrig.one_view AS
SELECT
    *
FROM
    evttrig.two,
    evttrig.id;

DROP VIEW evttrig.one_view;

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

ALTER TABLE evttrig.one
    DROP COLUMN col_c;

ALTER TABLE evttrig.id
    ALTER COLUMN col_d SET DATA TYPE bigint;

ALTER TABLE evttrig.id
    ALTER COLUMN col_d
    DROP IDENTITY,
    ALTER COLUMN col_d SET DATA TYPE int;

DROP INDEX evttrig.one_idx;

DROP SCHEMA evttrig CASCADE;

DROP TABLE a_temp_tbl;

-- check unfiltered results, too
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
        RAISE NOTICE 'DROP: orig=% normal=% istemp=% type=% identity=% schema=% name=% addr=% args=%', r.original, r.normal, r.is_temporary, r.object_type, r.object_identity, r.schema_name, r.object_name, r.address_names, r.address_args;
    END LOOP;
END;
$$;

CREATE FUNCTION event_trigger_dummy_trigger ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN new;
END;
$$;

CREATE TABLE evtrg_nontemp_table (
    f1 int PRIMARY KEY,
    f2 int DEFAULT 42
);

CREATE TRIGGER evtrg_nontemp_trig
    BEFORE INSERT ON evtrg_nontemp_table
    EXECUTE FUNCTION event_trigger_dummy_trigger ();

CREATE POLICY evtrg_nontemp_pol ON evtrg_nontemp_table
    USING (f2 > 0);

DROP TABLE evtrg_nontemp_table;

CREATE TEMP TABLE a_temp_tbl (
    f1 int PRIMARY KEY,
    f2 int DEFAULT 42
);

CREATE TRIGGER a_temp_trig
    BEFORE INSERT ON a_temp_tbl
    EXECUTE FUNCTION event_trigger_dummy_trigger ();

CREATE POLICY a_temp_pol ON a_temp_tbl
    USING (f2 > 0);

DROP TABLE a_temp_tbl;

DROP FUNCTION event_trigger_dummy_trigger ();

-- CREATE OPERATOR CLASS without FAMILY clause should report
-- both CREATE OPERATOR FAMILY and CREATE OPERATOR CLASS
CREATE OPERATOR CLASS evttrigopclass FOR TYPE int
    USING btree AS STORAGE int;

DROP EVENT TRIGGER regress_event_trigger_report_dropped;

DROP EVENT TRIGGER regress_event_trigger_report_end;

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

-- matview rewrite when changing access method
CREATE MATERIALIZED VIEW heapmv USING heap AS
SELECT
    1 AS a;

ALTER MATERIALIZED VIEW heapmv SET ACCESS METHOD heap2;

DROP MATERIALIZED VIEW heapmv;

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

-- Tests for REINDEX
CREATE OR REPLACE FUNCTION reindex_start_command ()
    RETURNS event_trigger
    AS $$
BEGIN
    RAISE NOTICE 'REINDEX START: % %', tg_event, tg_tag;
END;
$$
LANGUAGE plpgsql;

CREATE EVENT TRIGGER regress_reindex_start ON ddl_command_start
    WHEN TAG IN ('REINDEX')
        EXECUTE PROCEDURE reindex_start_command ();

CREATE FUNCTION reindex_end_command ()
    RETURNS event_trigger
    AS $$
DECLARE
    obj record;
BEGIN
    FOR obj IN
    SELECT
        *
    FROM
        pg_event_trigger_ddl_commands ()
    LOOP
        RAISE NOTICE 'REINDEX END: command_tag=% type=% identity=%', obj.command_tag, obj.object_type, obj.object_identity;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

CREATE EVENT TRIGGER regress_reindex_end ON ddl_command_end
    WHEN TAG IN ('REINDEX')
        EXECUTE PROCEDURE reindex_end_command ();

-- Extra event to force the use of a snapshot.
CREATE FUNCTION reindex_end_command_snap ()
    RETURNS EVENT_TRIGGER
    AS $$
BEGIN
    PERFORM
        1;
END
$$
LANGUAGE plpgsql;

CREATE EVENT TRIGGER regress_reindex_end_snap ON ddl_command_end
    EXECUTE FUNCTION reindex_end_command_snap ();

-- With simple relation
CREATE TABLE concur_reindex_tab (
    c1 int
);

CREATE INDEX concur_reindex_ind ON concur_reindex_tab (c1);

-- Both start and end triggers enabled.
REINDEX INDEX concur_reindex_ind;

REINDEX TABLE concur_reindex_tab;

REINDEX INDEX CONCURRENTLY concur_reindex_ind;

REINDEX TABLE CONCURRENTLY concur_reindex_tab;

-- with start trigger disabled.
ALTER EVENT TRIGGER regress_reindex_start DISABLE;

REINDEX INDEX concur_reindex_ind;

REINDEX INDEX CONCURRENTLY concur_reindex_ind;

-- without an index
DROP INDEX concur_reindex_ind;

REINDEX TABLE concur_reindex_tab;

REINDEX TABLE CONCURRENTLY concur_reindex_tab;

-- With a Schema
CREATE SCHEMA concur_reindex_schema;

-- No indexes
REINDEX SCHEMA concur_reindex_schema;

REINDEX SCHEMA CONCURRENTLY concur_reindex_schema;

CREATE TABLE concur_reindex_schema.tab (
    a int
);

CREATE INDEX ind ON concur_reindex_schema.tab (a);

-- One index reported
REINDEX SCHEMA concur_reindex_schema;

REINDEX SCHEMA CONCURRENTLY concur_reindex_schema;

-- One table on schema but no indexes
DROP INDEX concur_reindex_schema.ind;

REINDEX SCHEMA concur_reindex_schema;

REINDEX SCHEMA CONCURRENTLY concur_reindex_schema;

DROP SCHEMA concur_reindex_schema CASCADE;

-- With a partitioned table, and nothing else.
CREATE TABLE concur_reindex_part (
    id int
)
PARTITION BY RANGE (id);

REINDEX TABLE concur_reindex_part;

REINDEX TABLE CONCURRENTLY concur_reindex_part;

-- Partition that would be reindexed, still nothing.
CREATE TABLE concur_reindex_child PARTITION OF concur_reindex_part
FOR VALUES FROM (0) TO (10);

REINDEX TABLE concur_reindex_part;

REINDEX TABLE CONCURRENTLY concur_reindex_part;

-- Now add some indexes.
CREATE INDEX concur_reindex_partidx ON concur_reindex_part (id);

REINDEX INDEX concur_reindex_partidx;

REINDEX INDEX CONCURRENTLY concur_reindex_partidx;

REINDEX TABLE concur_reindex_part;

REINDEX TABLE CONCURRENTLY concur_reindex_part;

DROP TABLE concur_reindex_part;

-- Clean up
DROP EVENT TRIGGER regress_reindex_start;

DROP EVENT TRIGGER regress_reindex_end;

DROP EVENT TRIGGER regress_reindex_end_snap;

DROP FUNCTION reindex_end_command ();

DROP FUNCTION reindex_end_command_snap ();

DROP FUNCTION reindex_start_command ();

DROP TABLE concur_reindex_tab;

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

-- Check the object addresses of all the event triggers.
SELECT
    e.evtname,
    pg_describe_object('pg_event_trigger'::regclass, e.oid, 0) AS descr,
    b.type,
    b.object_names,
    b.object_args,
    pg_identify_object (a.classid, a.objid, a.objsubid) AS ident
FROM
    pg_event_trigger AS e,
    LATERAL pg_identify_object_as_address('pg_event_trigger'::regclass, e.oid, 0) AS b,
    LATERAL pg_get_object_address(b.type, b.object_names, b.object_args) AS a
ORDER BY
    e.evtname;

DROP EVENT TRIGGER start_rls_command;

DROP EVENT TRIGGER end_rls_command;

DROP EVENT TRIGGER sql_drop_command;

-- Check the GUC for disabling event triggers
CREATE FUNCTION test_event_trigger_guc ()
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
        RAISE NOTICE '% dropped %', tg_tag, obj.object_type;
    END LOOP;
END;
$$;

CREATE EVENT TRIGGER test_event_trigger_guc ON sql_drop
    WHEN TAG IN ('DROP POLICY')
        EXECUTE FUNCTION test_event_trigger_guc ();

SET event_triggers = 'on';

CREATE POLICY pguc ON event_trigger_test
    USING (FALSE);

DROP POLICY pguc ON event_trigger_test;

CREATE POLICY pguc ON event_trigger_test
    USING (FALSE);

SET event_triggers = 'off';

DROP POLICY pguc ON event_trigger_test;

