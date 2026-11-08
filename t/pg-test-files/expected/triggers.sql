--
-- TRIGGERS
--
-- directory paths and dlsuffix are passed to us in environment variables
\getenv libdir PG_LIBDIR

\getenv dlsuffix PG_DLSUFFIX

\set regresslib :libdir '/regress' :dlsuffix
CREATE FUNCTION trigger_return_old ()
    RETURNS trigger
    AS :'regresslib'
    LANGUAGE C;

-- Check behavior when trigger returns unmodified trigtuple
CREATE TABLE trigtest (
    f1 int,
    f2 text
);

CREATE TRIGGER trigger_return_old
    BEFORE INSERT OR DELETE OR UPDATE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_return_old ();

INSERT INTO trigtest
    VALUES (1, 'foo');

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    f2 = f2 || 'bar';

SELECT
    *
FROM
    trigtest;

DELETE FROM trigtest;

SELECT
    *
FROM
    trigtest;

-- Also check what happens when such a trigger runs before or after others
CREATE FUNCTION f1_times_10 ()
    RETURNS trigger
    AS $$
BEGIN
    NEW.f1 := NEW.f1 * 10;
    RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_alpha
    BEFORE INSERT OR UPDATE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE f1_times_10 ();

INSERT INTO trigtest
    VALUES (1, 'foo');

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    f2 = f2 || 'bar';

SELECT
    *
FROM
    trigtest;

DELETE FROM trigtest;

SELECT
    *
FROM
    trigtest;

CREATE TRIGGER trigger_zed
    BEFORE INSERT OR UPDATE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE f1_times_10 ();

INSERT INTO trigtest
    VALUES (1, 'foo');

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    f2 = f2 || 'bar';

SELECT
    *
FROM
    trigtest;

DELETE FROM trigtest;

SELECT
    *
FROM
    trigtest;

DROP TRIGGER trigger_alpha ON trigtest;

INSERT INTO trigtest
    VALUES (1, 'foo');

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    f2 = f2 || 'bar';

SELECT
    *
FROM
    trigtest;

DELETE FROM trigtest;

SELECT
    *
FROM
    trigtest;

DROP TABLE trigtest;

-- Check behavior with an implicit column default, too (bug #16644)
CREATE TABLE trigtest (
    a integer,
    b bool DEFAULT TRUE NOT NULL,
    c text DEFAULT 'xyzzy' NOT NULL
);

CREATE TRIGGER trigger_return_old
    BEFORE INSERT OR DELETE OR UPDATE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_return_old ();

INSERT INTO trigtest
    VALUES (1);

SELECT
    *
FROM
    trigtest;

ALTER TABLE trigtest
    ADD COLUMN d integer DEFAULT 42 NOT NULL;

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    a = 2
WHERE
    a = 1
RETURNING
    *;

SELECT
    *
FROM
    trigtest;

ALTER TABLE trigtest
    DROP COLUMN b;

SELECT
    *
FROM
    trigtest;

UPDATE
    trigtest
SET
    a = 2
WHERE
    a = 1
RETURNING
    *;

SELECT
    *
FROM
    trigtest;

DROP TABLE trigtest;

--
-- tests for per-statement triggers
--
CREATE TABLE log_table (
    tstamp timestamp DEFAULT timeofday()::timestamp
);

CREATE TABLE main_table (
    a int UNIQUE,
    b int
);

COPY main_table (a,b) FROM stdin;
5	10
20	20
30	10
50	35
80	15
\.

CREATE FUNCTION trigger_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    RAISE NOTICE ''trigger_func(%) called: action = %, when = %, level = %'', TG_ARGV[0], TG_OP, TG_WHEN, TG_LEVEL;
    RETURN NULL;
END;
';

CREATE TRIGGER before_ins_stmt_trig
    BEFORE INSERT ON main_table
    FOR EACH STATEMENT
    EXECUTE PROCEDURE trigger_func ('before_ins_stmt');

CREATE TRIGGER after_ins_stmt_trig
    AFTER INSERT ON main_table
    FOR EACH STATEMENT
    EXECUTE PROCEDURE trigger_func ('after_ins_stmt');

--
-- if neither 'FOR EACH ROW' nor 'FOR EACH STATEMENT' was specified,
-- CREATE TRIGGER should default to 'FOR EACH STATEMENT'
--
CREATE TRIGGER after_upd_stmt_trig
    AFTER UPDATE ON main_table
    EXECUTE PROCEDURE trigger_func ('after_upd_stmt');

-- Both insert and update statement level triggers (before and after) should
-- fire.  Doesn't fire UPDATE before trigger, but only because one isn't
-- defined.
INSERT INTO main_table (a, b)
    VALUES (5, 10)
ON CONFLICT (a)
    DO UPDATE SET
        b = EXCLUDED.b;

CREATE TRIGGER after_upd_row_trig
    AFTER UPDATE ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('after_upd_row');

INSERT INTO main_table DEFAULT VALUES; UPDATE
    main_table
SET
    a = a + 1
WHERE
    b < 30;

-- UPDATE that effects zero rows should still call per-statement trigger
UPDATE
    main_table
SET
    a = a + 2
WHERE
    b > 100;

-- constraint now unneeded
ALTER TABLE main_table
    DROP CONSTRAINT main_table_a_key;

-- COPY should fire per-row and per-statement INSERT triggers
COPY main_table (a, b) FROM stdin;
30	40
50	60
\.

SELECT
    *
FROM
    main_table
ORDER BY
    a,
    b;

-- Test comments
COMMENT ON TRIGGER no_such_trigger ON main_table IS 'wrong';

COMMENT ON TRIGGER before_ins_stmt_trig ON main_table IS 'right';

COMMENT ON TRIGGER before_ins_stmt_trig ON main_table IS NULL;

--
-- test triggers with WHEN clause
--
CREATE TRIGGER modified_a
    BEFORE UPDATE OF a ON main_table
    FOR EACH ROW
    WHEN (OLD.a <> NEW.a)
    EXECUTE PROCEDURE trigger_func ('modified_a');

CREATE TRIGGER modified_any
    BEFORE UPDATE OF a ON main_table
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE PROCEDURE trigger_func ('modified_any');

CREATE TRIGGER insert_a
    AFTER INSERT ON main_table
    FOR EACH ROW
    WHEN (NEW.a = 123)
    EXECUTE PROCEDURE trigger_func ('insert_a');

CREATE TRIGGER delete_a
    AFTER DELETE ON main_table
    FOR EACH ROW
    WHEN (OLD.a = 123)
    EXECUTE PROCEDURE trigger_func ('delete_a');

CREATE TRIGGER insert_when
    BEFORE INSERT ON main_table
    FOR EACH STATEMENT
    WHEN (TRUE)
    EXECUTE PROCEDURE trigger_func ('insert_when');

CREATE TRIGGER delete_when
    AFTER DELETE ON main_table
    FOR EACH STATEMENT
    WHEN (TRUE)
    EXECUTE PROCEDURE trigger_func ('delete_when');

SELECT
    trigger_name,
    event_manipulation,
    event_object_schema,
    event_object_table,
    action_order,
    action_condition,
    action_orientation,
    action_timing,
    action_reference_old_table,
    action_reference_new_table
FROM
    information_schema.triggers
WHERE
    event_object_table IN ('main_table')
ORDER BY
    trigger_name COLLATE "C",
    2;

INSERT INTO main_table (a)
VALUES
    (123),
    (456);

COPY main_table FROM stdin;
123	999
456	999
\.
DELETE FROM main_table
WHERE a IN (123, 456);

UPDATE
    main_table
SET
    a = 50,
    b = 60;

SELECT
    *
FROM
    main_table
ORDER BY
    a,
    b;

SELECT
    pg_get_triggerdef(oid, TRUE)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'modified_a';

SELECT
    pg_get_triggerdef(oid, FALSE)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'modified_a';

SELECT
    pg_get_triggerdef(oid, TRUE)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'modified_any';

-- Test RENAME TRIGGER
ALTER TRIGGER modified_a ON main_table RENAME TO modified_modified_a;

SELECT
    count(*)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'modified_a';

SELECT
    count(*)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'modified_modified_a';

DROP TRIGGER modified_modified_a ON main_table;

DROP TRIGGER modified_any ON main_table;

DROP TRIGGER insert_a ON main_table;

DROP TRIGGER delete_a ON main_table;

DROP TRIGGER insert_when ON main_table;

DROP TRIGGER delete_when ON main_table;

-- Test WHEN condition accessing system columns.
CREATE TABLE table_with_oids (
    a int
);

INSERT INTO table_with_oids
    VALUES (1);

CREATE TRIGGER oid_unchanged_trig
    AFTER UPDATE ON table_with_oids
    FOR EACH ROW
    WHEN (new.tableoid = old.tableoid AND new.tableoid <> 0)
    EXECUTE PROCEDURE trigger_func ('after_upd_oid_unchanged');

UPDATE
    table_with_oids
SET
    a = a + 1;

DROP TABLE table_with_oids;

-- Test column-level triggers
DROP TRIGGER after_upd_row_trig ON main_table;

CREATE TRIGGER before_upd_a_row_trig
    BEFORE UPDATE OF a ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_upd_a_row');

CREATE TRIGGER after_upd_b_row_trig
    AFTER UPDATE OF b ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('after_upd_b_row');

CREATE TRIGGER after_upd_a_b_row_trig
    AFTER UPDATE OF a,
    b ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('after_upd_a_b_row');

CREATE TRIGGER before_upd_a_stmt_trig
    BEFORE UPDATE OF a ON main_table
    FOR EACH STATEMENT
    EXECUTE PROCEDURE trigger_func ('before_upd_a_stmt');

CREATE TRIGGER after_upd_b_stmt_trig
    AFTER UPDATE OF b ON main_table
    FOR EACH STATEMENT
    EXECUTE PROCEDURE trigger_func ('after_upd_b_stmt');

SELECT
    pg_get_triggerdef(oid)
FROM
    pg_trigger
WHERE
    tgrelid = 'main_table'::regclass
    AND tgname = 'after_upd_a_b_row_trig';

UPDATE
    main_table
SET
    a = 50;

UPDATE
    main_table
SET
    b = 10;

--
-- Test case for bug with BEFORE trigger followed by AFTER trigger with WHEN
--
CREATE TABLE some_t (
    some_col boolean NOT NULL
);

CREATE FUNCTION dummy_update_func ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'dummy_update_func(%) called: action = %, old = %, new = %', TG_ARGV[0], TG_OP, OLD, NEW;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER some_trig_before
    BEFORE UPDATE ON some_t
    FOR EACH ROW
    EXECUTE PROCEDURE dummy_update_func ('before');

CREATE TRIGGER some_trig_aftera
    AFTER UPDATE ON some_t
    FOR EACH ROW
    WHEN (NOT OLD.some_col AND NEW.some_col)
    EXECUTE PROCEDURE dummy_update_func ('aftera');

CREATE TRIGGER some_trig_afterb
    AFTER UPDATE ON some_t
    FOR EACH ROW
    WHEN (NOT NEW.some_col)
    EXECUTE PROCEDURE dummy_update_func ('afterb');

INSERT INTO some_t
    VALUES (TRUE);

UPDATE
    some_t
SET
    some_col = TRUE;

UPDATE
    some_t
SET
    some_col = FALSE;

UPDATE
    some_t
SET
    some_col = TRUE;

DROP TABLE some_t;

-- bogus cases
CREATE TRIGGER error_upd_and_col
    BEFORE UPDATE OR UPDATE OF a ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('error_upd_and_col');

CREATE TRIGGER error_upd_a_a
    BEFORE UPDATE OF a,
    a ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('error_upd_a_a');

CREATE TRIGGER error_ins_a
    BEFORE INSERT OF a ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('error_ins_a');

CREATE TRIGGER error_ins_when
    BEFORE INSERT OR UPDATE ON main_table
    FOR EACH ROW
    WHEN (OLD.a <> NEW.a)
    EXECUTE PROCEDURE trigger_func ('error_ins_old');

CREATE TRIGGER error_del_when
    BEFORE DELETE OR UPDATE ON main_table
    FOR EACH ROW
    WHEN (OLD.a <> NEW.a)
    EXECUTE PROCEDURE trigger_func ('error_del_new');

CREATE TRIGGER error_del_when
    BEFORE INSERT OR UPDATE ON main_table
    FOR EACH ROW
    WHEN (NEW.tableoid <> 0)
    EXECUTE PROCEDURE trigger_func ('error_when_sys_column');

CREATE TRIGGER error_stmt_when
    BEFORE UPDATE OF a ON main_table
    FOR EACH STATEMENT
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE PROCEDURE trigger_func ('error_stmt_when');

-- check dependency restrictions
ALTER TABLE main_table
    DROP COLUMN b;

-- this should succeed, but we'll roll it back to keep the triggers around
BEGIN;
DROP TRIGGER after_upd_a_b_row_trig ON main_table;
DROP TRIGGER after_upd_b_row_trig ON main_table;
DROP TRIGGER after_upd_b_stmt_trig ON main_table;
ALTER TABLE main_table
    DROP COLUMN b;
ROLLBACK;

-- Test enable/disable triggers
CREATE TABLE trigtest (
    i serial PRIMARY KEY
);

-- test that disabling RI triggers works
CREATE TABLE trigtest2 (
    i int REFERENCES trigtest (i) ON DELETE CASCADE
);

CREATE FUNCTION trigtest ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE '% % % %', TG_TABLE_NAME, TG_OP, TG_WHEN, TG_LEVEL;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigtest_b_row_tg
    BEFORE INSERT OR UPDATE OR DELETE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_a_row_tg
    AFTER INSERT OR UPDATE OR DELETE ON trigtest
    FOR EACH ROW
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_b_stmt_tg
    BEFORE INSERT OR UPDATE OR DELETE ON trigtest
    FOR EACH statement
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_a_stmt_tg
    AFTER INSERT OR UPDATE OR DELETE ON trigtest
    FOR EACH statement
    EXECUTE PROCEDURE trigtest ();

INSERT INTO trigtest DEFAULT VALUES; ALTER TABLE trigtest DISABLE TRIGGER trigtest_b_row_tg;

INSERT INTO trigtest DEFAULT VALUES; ALTER TABLE trigtest DISABLE TRIGGER USER;

INSERT INTO trigtest DEFAULT VALUES; ALTER TABLE trigtest ENABLE TRIGGER trigtest_a_stmt_tg;

INSERT INTO trigtest DEFAULT VALUES; SET session_replication_role = REPLICA;

INSERT INTO trigtest DEFAULT VALUES; -- does not trigger
ALTER TABLE trigtest ENABLE ALWAYS TRIGGER trigtest_a_stmt_tg;

INSERT INTO trigtest DEFAULT VALUES; -- now it does
RESET session_replication_role;

INSERT INTO trigtest2
    VALUES (1);

INSERT INTO trigtest2
    VALUES (2);

DELETE FROM trigtest
WHERE i = 2;

SELECT
    *
FROM
    trigtest2;

ALTER TABLE trigtest DISABLE TRIGGER ALL;

DELETE FROM trigtest
WHERE i = 1;

SELECT
    *
FROM
    trigtest2;

-- ensure we still insert, even when all triggers are disabled
INSERT INTO trigtest DEFAULT VALUES;
SELECT
    *
FROM
    trigtest;

DROP TABLE trigtest2;

DROP TABLE trigtest;

-- dump trigger data
CREATE TABLE trigger_test (
    i int,
    v varchar
);

CREATE OR REPLACE FUNCTION trigger_data ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    argstr text;
    relid text;
BEGIN
    relid := TG_relid::regclass;
    -- plpgsql can't discover its trigger data in a hash like perl and python
    -- can, or by a sort of reflection like tcl can,
    -- so we have to hard code the names.
    RAISE NOTICE 'TG_NAME: %', TG_name;
    RAISE NOTICE 'TG_WHEN: %', TG_when;
    RAISE NOTICE 'TG_LEVEL: %', TG_level;
    RAISE NOTICE 'TG_OP: %', TG_op;
    RAISE NOTICE 'TG_RELID::regclass: %', relid;
    RAISE NOTICE 'TG_RELNAME: %', TG_relname;
    RAISE NOTICE 'TG_TABLE_NAME: %', TG_table_name;
    RAISE NOTICE 'TG_TABLE_SCHEMA: %', TG_table_schema;
    RAISE NOTICE 'TG_NARGS: %', TG_nargs;
    argstr := '[';
    FOR i IN 0..TG_nargs - 1 LOOP
        IF i > 0 THEN
            argstr := argstr || ', ';
        END IF;
        argstr := argstr || TG_argv[i];
    END LOOP;
    argstr := argstr || ']';
    RAISE NOTICE 'TG_ARGV: %', argstr;
    IF TG_OP != 'INSERT' THEN
        RAISE NOTICE 'OLD: %', OLD;
    END IF;
    IF TG_OP != 'DELETE' THEN
        RAISE NOTICE 'NEW: %', NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER show_trigger_data_trig
    BEFORE INSERT OR UPDATE OR DELETE ON trigger_test
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_data (23, 'skidoo');

INSERT INTO trigger_test
    VALUES (1, 'insert');

UPDATE
    trigger_test
SET
    v = 'update'
WHERE
    i = 1;

DELETE FROM trigger_test;

DROP TRIGGER show_trigger_data_trig ON trigger_test;

DROP FUNCTION trigger_data ();

DROP TABLE trigger_test;

--
-- Test use of row comparisons on OLD/NEW
--
CREATE TABLE trigger_test (
    f1 int,
    f2 text,
    f3 text
);

-- this is the obvious (and wrong...) way to compare rows
CREATE FUNCTION mytrigger ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF ROW (OLD.*) = ROW (NEW.*) THEN
        RAISE NOTICE 'row % not changed', NEW.f1;
    ELSE
        RAISE NOTICE 'row % changed', NEW.f1;
    END IF;
    RETURN new;
END
$$;

CREATE TRIGGER t
    BEFORE UPDATE ON trigger_test
    FOR EACH ROW
    EXECUTE PROCEDURE mytrigger ();

INSERT INTO trigger_test
    VALUES (1, 'foo', 'bar');

INSERT INTO trigger_test
    VALUES (2, 'baz', 'quux');

UPDATE
    trigger_test
SET
    f3 = 'bar';

UPDATE
    trigger_test
SET
    f3 = NULL;

-- this demonstrates that the above isn't really working as desired:
UPDATE
    trigger_test
SET
    f3 = NULL;

-- the right way when considering nulls is
CREATE OR REPLACE FUNCTION mytrigger ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF ROW (OLD.*) IS DISTINCT FROM ROW (NEW.*) THEN
        RAISE NOTICE 'row % changed', NEW.f1;
    ELSE
        RAISE NOTICE 'row % not changed', NEW.f1;
    END IF;
    RETURN new;
END
$$;

UPDATE
    trigger_test
SET
    f3 = 'bar';

UPDATE
    trigger_test
SET
    f3 = NULL;

UPDATE
    trigger_test
SET
    f3 = NULL;

DROP TABLE trigger_test;

DROP FUNCTION mytrigger ();

-- Test snapshot management in serializable transactions involving triggers
-- per bug report in 6bc73d4c0910042358k3d1adff3qa36f8df75198ecea@mail.gmail.com
CREATE FUNCTION serializable_update_trig ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec record;
BEGIN
    NEW.description = 'updated in trigger';
    RETURN new;
END;
$$;

CREATE TABLE serializable_update_tab (
    id int,
    filler text,
    description text
);

CREATE TRIGGER serializable_update_trig
    BEFORE UPDATE ON serializable_update_tab
    FOR EACH ROW
    EXECUTE PROCEDURE serializable_update_trig ();

INSERT INTO serializable_update_tab
SELECT
    a,
    repeat('xyzxz', 100),
    'new'
FROM
    generate_series(1, 50) a;

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE
    serializable_update_tab
SET
    description = 'no no',
    id = 1
WHERE
    id = 1;
COMMIT;

SELECT
    description
FROM
    serializable_update_tab
WHERE
    id = 1;

DROP TABLE serializable_update_tab;

-- minimal update trigger
CREATE TABLE min_updates_test (
    f1 text,
    f2 int,
    f3 int
);

INSERT INTO min_updates_test
VALUES
    ('a', 1, 2),
    ('b', '2', NULL);

CREATE TRIGGER z_min_update
    BEFORE UPDATE ON min_updates_test
    FOR EACH ROW
    EXECUTE PROCEDURE suppress_redundant_updates_trigger ();

\set QUIET false
UPDATE
    min_updates_test
SET
    f1 = f1;

UPDATE
    min_updates_test
SET
    f2 = f2 + 1;

UPDATE
    min_updates_test
SET
    f3 = 2
WHERE
    f3 IS NULL;

\set QUIET true
SELECT
    *
FROM
    min_updates_test;

DROP TABLE min_updates_test;

--
-- Test triggers on views
--
CREATE VIEW main_view AS
SELECT
    a,
    b
FROM
    main_table;

-- VIEW trigger function
CREATE OR REPLACE FUNCTION view_trigger ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    argstr text := '';
BEGIN
    FOR i IN 0..TG_nargs - 1 LOOP
        IF i > 0 THEN
            argstr := argstr || ', ';
        END IF;
        argstr := argstr || TG_argv[i];
    END LOOP;
    RAISE NOTICE '% % % % (%)', TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL, argstr;
    IF TG_LEVEL = 'ROW' THEN
        IF TG_OP = 'INSERT' THEN
            RAISE NOTICE 'NEW: %', NEW;
            INSERT INTO main_table
                VALUES (NEW.a, NEW.b);
            RETURN NEW;
        END IF;
        IF TG_OP = 'UPDATE' THEN
            RAISE NOTICE 'OLD: %, NEW: %', OLD, NEW;
            UPDATE
                main_table
            SET
                a = NEW.a,
                b = NEW.b
            WHERE
                a = OLD.a
                AND b = OLD.b;
            IF NOT FOUND THEN
                RETURN NULL;
            END IF;
            RETURN NEW;
        END IF;
        IF TG_OP = 'DELETE' THEN
            RAISE NOTICE 'OLD: %', OLD;
            DELETE FROM main_table
            WHERE a = OLD.a
                AND b = OLD.b;
            IF NOT FOUND THEN
                RETURN NULL;
            END IF;
            RETURN OLD;
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

-- Before row triggers aren't allowed on views
CREATE TRIGGER invalid_trig
    BEFORE INSERT ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_ins_row');

CREATE TRIGGER invalid_trig
    BEFORE UPDATE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_upd_row');

CREATE TRIGGER invalid_trig
    BEFORE DELETE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_del_row');

-- After row triggers aren't allowed on views
CREATE TRIGGER invalid_trig
    AFTER INSERT ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_ins_row');

CREATE TRIGGER invalid_trig
    AFTER UPDATE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_upd_row');

CREATE TRIGGER invalid_trig
    AFTER DELETE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_func ('before_del_row');

-- Truncate triggers aren't allowed on views
CREATE TRIGGER invalid_trig
    BEFORE TRUNCATE ON main_view
    EXECUTE PROCEDURE trigger_func ('before_tru_row');

CREATE TRIGGER invalid_trig
    AFTER TRUNCATE ON main_view
    EXECUTE PROCEDURE trigger_func ('before_tru_row');

-- INSTEAD OF triggers aren't allowed on tables
CREATE TRIGGER invalid_trig
    INSTEAD OF INSERT ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_ins');

CREATE TRIGGER invalid_trig
    INSTEAD OF UPDATE ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

CREATE TRIGGER invalid_trig
    INSTEAD OF DELETE ON main_table
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_del');

-- Don't support WHEN clauses with INSTEAD OF triggers
CREATE TRIGGER invalid_trig
    INSTEAD OF UPDATE ON main_view
    FOR EACH ROW
    WHEN (OLD.a <> NEW.a)
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

-- Don't support column-level INSTEAD OF triggers
CREATE TRIGGER invalid_trig
    INSTEAD OF UPDATE OF a ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

-- Don't support statement-level INSTEAD OF triggers
CREATE TRIGGER invalid_trig
    INSTEAD OF UPDATE ON main_view
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

-- Valid INSTEAD OF triggers
CREATE TRIGGER instead_of_insert_trig
    INSTEAD OF INSERT ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_ins');

CREATE TRIGGER instead_of_update_trig
    INSTEAD OF UPDATE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

CREATE TRIGGER instead_of_delete_trig
    INSTEAD OF DELETE ON main_view
    FOR EACH ROW
    EXECUTE PROCEDURE view_trigger ('instead_of_del');

-- Valid BEFORE statement VIEW triggers
CREATE TRIGGER before_ins_stmt_trig
    BEFORE INSERT ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('before_view_ins_stmt');

CREATE TRIGGER before_upd_stmt_trig
    BEFORE UPDATE ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('before_view_upd_stmt');

CREATE TRIGGER before_del_stmt_trig
    BEFORE DELETE ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('before_view_del_stmt');

-- Valid AFTER statement VIEW triggers
CREATE TRIGGER after_ins_stmt_trig
    AFTER INSERT ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('after_view_ins_stmt');

CREATE TRIGGER after_upd_stmt_trig
    AFTER UPDATE ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('after_view_upd_stmt');

CREATE TRIGGER after_del_stmt_trig
    AFTER DELETE ON main_view
    FOR EACH STATEMENT
    EXECUTE PROCEDURE view_trigger ('after_view_del_stmt');

\set QUIET false
-- Insert into view using trigger
INSERT INTO main_view
    VALUES (20, 30);

INSERT INTO main_view
    VALUES (21, 31)
RETURNING
    a, b;

-- Table trigger will prevent updates
UPDATE
    main_view
SET
    b = 31
WHERE
    a = 20;

UPDATE
    main_view
SET
    b = 32
WHERE
    a = 21
    AND b = 31
RETURNING
    a,
    b;

-- Remove table trigger to allow updates
DROP TRIGGER before_upd_a_row_trig ON main_table;

UPDATE
    main_view
SET
    b = 31
WHERE
    a = 20;

UPDATE
    main_view
SET
    b = 32
WHERE
    a = 21
    AND b = 31
RETURNING
    a,
    b;

-- Before and after stmt triggers should fire even when no rows are affected
UPDATE
    main_view
SET
    b = 0
WHERE
    FALSE;

-- Delete from view using trigger
DELETE FROM main_view
WHERE a IN (20, 21);

DELETE FROM main_view
WHERE a = 31
RETURNING
    a,
    b;

\set QUIET true
-- Describe view should list triggers
\d main_view
-- Test dropping view triggers
DROP TRIGGER instead_of_insert_trig ON main_view;

DROP TRIGGER instead_of_delete_trig ON main_view;

\d+ main_view
DROP VIEW main_view;

--
-- Test triggers on a join view
--
CREATE TABLE country_table (
    country_id serial PRIMARY KEY,
    country_name text UNIQUE NOT NULL,
    continent text NOT NULL
);

INSERT INTO country_table (country_name, continent)
VALUES
    ('Japan', 'Asia'),
    ('UK', 'Europe'),
    ('USA', 'North America')
RETURNING
    *;

CREATE TABLE city_table (
    city_id serial PRIMARY KEY,
    city_name text NOT NULL,
    population bigint,
    country_id int REFERENCES country_table
);

CREATE VIEW city_view AS
SELECT
    city_id,
    city_name,
    population,
    country_name,
    continent
FROM
    city_table ci
    LEFT JOIN country_table co ON co.country_id = ci.country_id;

CREATE FUNCTION city_insert ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    ctry_id int;
BEGIN
    IF NEW.country_name IS NOT NULL THEN
        SELECT
            country_id,
            continent
        INTO
            ctry_id,
            NEW.continent
        FROM
            country_table
        WHERE
            country_name = NEW.country_name;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such country: "%"', NEW.country_name;
        END IF;
    ELSE
        NEW.continent := NULL;
    END IF;
    IF NEW.city_id IS NOT NULL THEN
        INSERT INTO city_table
            VALUES (NEW.city_id, NEW.city_name, NEW.population, ctry_id);
    ELSE
        INSERT INTO city_table (city_name, population, country_id)
            VALUES (NEW.city_name, NEW.population, ctry_id)
        RETURNING
            city_id
        INTO
            NEW.city_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER city_insert_trig
    INSTEAD OF INSERT ON city_view
    FOR EACH ROW
    EXECUTE PROCEDURE city_insert ();

CREATE FUNCTION city_delete ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM city_table
    WHERE city_id = OLD.city_id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER city_delete_trig
    INSTEAD OF DELETE ON city_view
    FOR EACH ROW
    EXECUTE PROCEDURE city_delete ();

CREATE FUNCTION city_update ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    ctry_id int;
BEGIN
    IF NEW.country_name IS DISTINCT FROM OLD.country_name THEN
        SELECT
            country_id,
            continent
        INTO
            ctry_id,
            NEW.continent
        FROM
            country_table
        WHERE
            country_name = NEW.country_name;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such country: "%"', NEW.country_name;
        END IF;
        UPDATE
            city_table
        SET
            city_name = NEW.city_name,
            population = NEW.population,
            country_id = ctry_id
        WHERE
            city_id = OLD.city_id;
    ELSE
        UPDATE
            city_table
        SET
            city_name = NEW.city_name,
            population = NEW.population
        WHERE
            city_id = OLD.city_id;
        NEW.continent := OLD.continent;
    END IF;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER city_update_trig
    INSTEAD OF UPDATE ON city_view
    FOR EACH ROW
    EXECUTE PROCEDURE city_update ();

\set QUIET false
-- INSERT .. RETURNING
INSERT INTO city_view (city_name)
    VALUES ('Tokyo')
RETURNING
    *;

INSERT INTO city_view (city_name, population)
    VALUES ('London', 7556900)
RETURNING
    *;

INSERT INTO city_view (city_name, country_name)
    VALUES ('Washington DC', 'USA')
RETURNING
    *;

INSERT INTO city_view (city_id, city_name)
    VALUES (123456, 'New York')
RETURNING
    *;

INSERT INTO city_view
    VALUES (234567, 'Birmingham', 1016800, 'UK', 'EU')
RETURNING
    *;

-- UPDATE .. RETURNING
UPDATE
    city_view
SET
    country_name = 'Japon'
WHERE
    city_name = 'Tokyo';

-- error
UPDATE
    city_view
SET
    country_name = 'Japan'
WHERE
    city_name = 'Takyo';

-- no match
UPDATE
    city_view
SET
    country_name = 'Japan'
WHERE
    city_name = 'Tokyo'
RETURNING
    *;

-- OK
UPDATE
    city_view
SET
    population = 13010279
WHERE
    city_name = 'Tokyo'
RETURNING
    *;

UPDATE
    city_view
SET
    country_name = 'UK'
WHERE
    city_name = 'New York'
RETURNING
    *;

UPDATE
    city_view
SET
    country_name = 'USA',
    population = 8391881
WHERE
    city_name = 'New York'
RETURNING
    *;

UPDATE
    city_view
SET
    continent = 'EU'
WHERE
    continent = 'Europe'
RETURNING
    *;

UPDATE
    city_view v1
SET
    country_name = v2.country_name
FROM
    city_view v2
WHERE
    v2.city_name = 'Birmingham'
    AND v1.city_name = 'London'
RETURNING
    *;

-- DELETE .. RETURNING
DELETE FROM city_view
WHERE city_name = 'Birmingham'
RETURNING
    *;

\set QUIET true
-- read-only view with WHERE clause
CREATE VIEW european_city_view AS
SELECT
    *
FROM
    city_view
WHERE
    continent = 'Europe';

SELECT
    count(*)
FROM
    european_city_view;

CREATE FUNCTION no_op_trig_fn ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    RETURN NULL;

END;
';

CREATE TRIGGER no_op_trig
    INSTEAD OF INSERT OR UPDATE OR DELETE ON european_city_view
    FOR EACH ROW
    EXECUTE PROCEDURE no_op_trig_fn ();

\set QUIET false
INSERT INTO european_city_view
    VALUES (0, 'x', 10000, 'y', 'z');

UPDATE
    european_city_view
SET
    population = 10000;

DELETE FROM european_city_view;

\set QUIET true
-- rules bypassing no-op triggers
CREATE RULE european_city_insert_rule AS ON INSERT TO european_city_view
    DO INSTEAD
    INSERT INTO city_view VALUES (NEW.city_id, NEW.city_name, NEW.population, NEW.country_name, NEW.continent)
RETURNING
    *;

CREATE RULE european_city_update_rule AS ON UPDATE
    TO european_city_view
        DO INSTEAD
        UPDATE
            city_view SET
            city_name = NEW.city_name,
            population = NEW.population,
            country_name = NEW.country_name WHERE
            city_id = OLD.city_id RETURNING
            NEW.*;

CREATE RULE european_city_delete_rule AS ON DELETE TO european_city_view
    DO INSTEAD
    DELETE FROM city_view
    WHERE city_id = OLD.city_id RETURNING
        *;

\set QUIET false
-- INSERT not limited by view's WHERE clause, but UPDATE AND DELETE are
INSERT INTO european_city_view (city_name, country_name)
    VALUES ('Cambridge', 'USA')
RETURNING
    *;

UPDATE
    european_city_view
SET
    country_name = 'UK'
WHERE
    city_name = 'Cambridge';

DELETE FROM european_city_view
WHERE city_name = 'Cambridge';

-- UPDATE and DELETE via rule and trigger
UPDATE
    city_view
SET
    country_name = 'UK'
WHERE
    city_name = 'Cambridge'
RETURNING
    *;

UPDATE
    european_city_view
SET
    population = 122800
WHERE
    city_name = 'Cambridge'
RETURNING
    *;

DELETE FROM european_city_view
WHERE city_name = 'Cambridge'
RETURNING
    *;

-- join UPDATE test
UPDATE
    city_view v
SET
    population = 599657
FROM
    city_table ci,
    country_table co
WHERE
    ci.city_name = 'Washington DC'
    AND co.country_name = 'USA'
    AND v.city_id = ci.city_id
    AND v.country_name = co.country_name
RETURNING
    co.country_id,
    v.country_name,
    v.city_id,
    v.city_name,
    v.population;

\set QUIET true
SELECT
    *
FROM
    city_view;

DROP TABLE city_table CASCADE;

DROP TABLE country_table;

-- Test pg_trigger_depth()
CREATE TABLE depth_a (
    id int NOT NULL PRIMARY KEY
);

CREATE TABLE depth_b (
    id int NOT NULL PRIMARY KEY
);

CREATE TABLE depth_c (
    id int NOT NULL PRIMARY KEY
);

CREATE FUNCTION depth_a_tf ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    INSERT INTO depth_b
        VALUES (NEW.id);
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    RETURN new;
END;
$$;

CREATE TRIGGER depth_a_tr
    BEFORE INSERT ON depth_a
    FOR EACH ROW
    EXECUTE PROCEDURE depth_a_tf ();

CREATE FUNCTION depth_b_tf ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    BEGIN
        EXECUTE 'insert into depth_c values (' || NEW.id::text || ')';
    EXCEPTION
        WHEN sqlstate 'U9999' THEN
            RAISE NOTICE 'SQLSTATE = U9999: depth = %', pg_trigger_depth();
    END;
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    IF NEW.id = 1 THEN
        EXECUTE 'insert into depth_c values (' || NEW.id::text || ')';
        END IF;
        RETURN new;
END;

$$;

CREATE TRIGGER depth_b_tr
    BEFORE INSERT ON depth_b
    FOR EACH ROW
    EXECUTE PROCEDURE depth_b_tf ();

CREATE FUNCTION depth_c_tf ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    IF NEW.id = 1 THEN
        RAISE EXCEPTION sqlstate 'U9999';
    END IF;
    RAISE NOTICE '%: depth = %', tg_name, pg_trigger_depth();
    RETURN new;
END;
$$;

CREATE TRIGGER depth_c_tr
    BEFORE INSERT ON depth_c
    FOR EACH ROW
    EXECUTE PROCEDURE depth_c_tf ();

SELECT
    pg_trigger_depth();

INSERT INTO depth_a
    VALUES (1);

SELECT
    pg_trigger_depth();

INSERT INTO depth_a
    VALUES (2);

SELECT
    pg_trigger_depth();

DROP TABLE depth_a, depth_b, depth_c;

DROP FUNCTION depth_a_tf ();

DROP FUNCTION depth_b_tf ();

DROP FUNCTION depth_c_tf ();

--
-- Test updates to rows during firing of BEFORE ROW triggers.
-- As of 9.2, such cases should be rejected (see bug #6123).
--
CREATE temp TABLE parent (
    aid int NOT NULL PRIMARY KEY,
    val1 text,
    val2 text,
    val3 text,
    val4 text,
    bcnt int NOT NULL DEFAULT 0
);

CREATE temp TABLE child (
    bid int NOT NULL PRIMARY KEY,
    aid int NOT NULL,
    val1 text
);

CREATE FUNCTION parent_upd_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.val1 <> NEW.val1 THEN
        NEW.val2 = NEW.val1;
        DELETE FROM child
        WHERE child.aid = NEW.aid
            AND child.val1 = NEW.val1;
    END IF;
    RETURN new;
END;
$$;

CREATE TRIGGER parent_upd_trig
    BEFORE UPDATE ON parent
    FOR EACH ROW
    EXECUTE PROCEDURE parent_upd_func ();

CREATE FUNCTION parent_del_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM child
    WHERE aid = OLD.aid;
    RETURN old;
END;
$$;

CREATE TRIGGER parent_del_trig
    BEFORE DELETE ON parent
    FOR EACH ROW
    EXECUTE PROCEDURE parent_del_func ();

CREATE FUNCTION child_ins_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE
        parent
    SET
        bcnt = bcnt + 1
    WHERE
        aid = NEW.aid;
    RETURN new;
END;
$$;

CREATE TRIGGER child_ins_trig
    AFTER INSERT ON child
    FOR EACH ROW
    EXECUTE PROCEDURE child_ins_func ();

CREATE FUNCTION child_del_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE
        parent
    SET
        bcnt = bcnt - 1
    WHERE
        aid = OLD.aid;
    RETURN old;
END;
$$;

CREATE TRIGGER child_del_trig
    AFTER DELETE ON child
    FOR EACH ROW
    EXECUTE PROCEDURE child_del_func ();

INSERT INTO parent
    VALUES (1, 'a', 'a', 'a', 'a', 0);

INSERT INTO child
    VALUES (10, 1, 'b');

SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

UPDATE
    parent
SET
    val1 = 'b'
WHERE
    aid = 1;

-- should fail
merge INTO parent p
    USING ( VALUES (1)) AS v (id) ON p.aid = v.id
    WHEN matched THEN
        UPDATE SET val1 = 'b';

-- should fail
SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

DELETE FROM parent
WHERE aid = 1;

-- should fail
merge INTO parent p
    USING ( VALUES (1)) AS v (id) ON p.aid = v.id
    WHEN matched THEN
        DELETE;

-- should fail
SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

-- replace the trigger function with one that restarts the deletion after
-- having modified a child
CREATE OR REPLACE FUNCTION parent_del_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM child
    WHERE aid = OLD.aid;
    IF found THEN
        DELETE FROM parent
        WHERE aid = OLD.aid;
        RETURN NULL;
        -- cancel outer deletion
    END IF;
    RETURN old;
END;
$$;

DELETE FROM parent
WHERE aid = 1;

SELECT
    *
FROM
    parent;

SELECT
    *
FROM
    child;

DROP TABLE parent, child;

DROP FUNCTION parent_upd_func ();

DROP FUNCTION parent_del_func ();

DROP FUNCTION child_ins_func ();

DROP FUNCTION child_del_func ();

-- similar case, but with a self-referencing FK so that parent and child
-- rows can be affected by a single operation
CREATE temp TABLE self_ref_trigger (
    id int PRIMARY KEY,
    parent int REFERENCES self_ref_trigger,
    data text,
    nchildren int NOT NULL DEFAULT 0
);

CREATE FUNCTION self_ref_trigger_ins_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.parent IS NOT NULL THEN
        UPDATE
            self_ref_trigger
        SET
            nchildren = nchildren + 1
        WHERE
            id = NEW.parent;
    END IF;
    RETURN new;
END;
$$;

CREATE TRIGGER self_ref_trigger_ins_trig
    BEFORE INSERT ON self_ref_trigger
    FOR EACH ROW
    EXECUTE PROCEDURE self_ref_trigger_ins_func ();

CREATE FUNCTION self_ref_trigger_del_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.parent IS NOT NULL THEN
        UPDATE
            self_ref_trigger
        SET
            nchildren = nchildren - 1
        WHERE
            id = OLD.parent;
    END IF;
    RETURN old;
END;
$$;

CREATE TRIGGER self_ref_trigger_del_trig
    BEFORE DELETE ON self_ref_trigger
    FOR EACH ROW
    EXECUTE PROCEDURE self_ref_trigger_del_func ();

INSERT INTO self_ref_trigger
    VALUES (1, NULL, 'root');

INSERT INTO self_ref_trigger
    VALUES (2, 1, 'root child A');

INSERT INTO self_ref_trigger
    VALUES (3, 1, 'root child B');

INSERT INTO self_ref_trigger
    VALUES (4, 2, 'grandchild 1');

INSERT INTO self_ref_trigger
    VALUES (5, 3, 'grandchild 2');

UPDATE
    self_ref_trigger
SET
    data = 'root!'
WHERE
    id = 1;

SELECT
    *
FROM
    self_ref_trigger;

DELETE FROM self_ref_trigger;

SELECT
    *
FROM
    self_ref_trigger;

DROP TABLE self_ref_trigger;

DROP FUNCTION self_ref_trigger_ins_func ();

DROP FUNCTION self_ref_trigger_del_func ();

--
-- Check that statement triggers work correctly even with all children excluded
--
CREATE TABLE stmt_trig_on_empty_upd (
    a int
);

CREATE TABLE stmt_trig_on_empty_upd1 ()
INHERITS (
    stmt_trig_on_empty_upd
);

CREATE FUNCTION update_stmt_notice ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'updating %', TG_TABLE_NAME;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER before_stmt_trigger
    BEFORE UPDATE ON stmt_trig_on_empty_upd
    EXECUTE PROCEDURE update_stmt_notice ();

CREATE TRIGGER before_stmt_trigger
    BEFORE UPDATE ON stmt_trig_on_empty_upd1
    EXECUTE PROCEDURE update_stmt_notice ();

-- inherited no-op update
UPDATE
    stmt_trig_on_empty_upd
SET
    a = a
WHERE
    FALSE
RETURNING
    a + 1 AS aa;

-- simple no-op update
UPDATE
    stmt_trig_on_empty_upd1
SET
    a = a
WHERE
    FALSE
RETURNING
    a + 1 AS aa;

DROP TABLE stmt_trig_on_empty_upd CASCADE;

DROP FUNCTION update_stmt_notice ();

--
-- Check that index creation (or DDL in general) is prohibited in a trigger
--
CREATE TABLE trigger_ddl_table (
    col1 integer,
    col2 integer
);

CREATE FUNCTION trigger_ddl_func ()
    RETURNS trigger
    AS $$
BEGIN
    ALTER TABLE trigger_ddl_table
        ADD PRIMARY KEY (col1);
    RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_ddl_func
    BEFORE INSERT ON trigger_ddl_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_ddl_func ();

INSERT INTO trigger_ddl_table
    VALUES (1, 42);

-- fail
CREATE OR REPLACE FUNCTION trigger_ddl_func ()
    RETURNS trigger
    AS $$
BEGIN
    CREATE INDEX ON trigger_ddl_table (col2);
    RETURN new;
END
$$
LANGUAGE plpgsql;

INSERT INTO trigger_ddl_table
    VALUES (1, 42);

-- fail
DROP TABLE trigger_ddl_table;

DROP FUNCTION trigger_ddl_func ();

--
-- Verify behavior of before and after triggers with INSERT...ON CONFLICT
-- DO UPDATE and DO SELECT
--
CREATE TABLE upsert (
    key int4 PRIMARY KEY,
    color text
);

CREATE FUNCTION upsert_before_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE warning 'before update (old): %', OLD.*::text;
        RAISE warning 'before update (new): %', NEW.*::text;
    ELSIF (TG_OP = 'INSERT') THEN
        RAISE warning 'before insert (new): %', NEW.*::text;
        IF NEW.key % 2 = 0 THEN
            NEW.key := NEW.key + 1;
            NEW.color := NEW.color || ' trig modified';
            RAISE warning 'before insert (new, modified): %', NEW.*::text;
        END IF;
    END IF;
    RETURN new;
END;
$$;

CREATE TRIGGER upsert_before_trig
    BEFORE INSERT OR UPDATE ON upsert
    FOR EACH ROW
    EXECUTE PROCEDURE upsert_before_func ();

CREATE FUNCTION upsert_after_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE warning 'after update (old): %', OLD.*::text;
        RAISE warning 'after update (new): %', NEW.*::text;
    ELSIF (TG_OP = 'INSERT') THEN
        RAISE warning 'after insert (new): %', NEW.*::text;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER upsert_after_trig
    AFTER INSERT OR UPDATE ON upsert
    FOR EACH ROW
    EXECUTE PROCEDURE upsert_after_func ();

INSERT INTO upsert
    VALUES (1, 'black')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (2, 'red')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (3, 'orange')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (4, 'green')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (5, 'purple')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (6, 'white')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (7, 'pink')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (8, 'yellow')
ON CONFLICT (key)
    DO UPDATE SET
        color = 'updated ' || upsert.color;

INSERT INTO upsert
    VALUES (8, 'blue')
ON CONFLICT (key)
DO
SELECT
    FOR UPDATE
WHERE
    upsert.color = 'yellow trig modified'
RETURNING
    old.*,
    new.*,
    upsert.*;

SELECT
    *
FROM
    upsert;

DROP TABLE upsert;

DROP FUNCTION upsert_before_func ();

DROP FUNCTION upsert_after_func ();

--
-- Verify that triggers with transition tables are not allowed on
-- views
--
CREATE TABLE my_table (
    i int
);

CREATE VIEW my_view AS
SELECT
    *
FROM
    my_table;

CREATE FUNCTION my_trigger_function ()
    RETURNS trigger
    AS $$
BEGIN
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER my_trigger
    AFTER UPDATE ON my_view referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE my_trigger_function ();

DROP FUNCTION my_trigger_function ();

DROP VIEW my_view;

DROP TABLE my_table;

--
-- Verify cases that are unsupported with partitioned tables
--
CREATE TABLE parted_trig (
    a int
)
PARTITION BY LIST (a);

CREATE FUNCTION trigger_nothing ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
END;
$$;

CREATE TRIGGER failed
    INSTEAD OF UPDATE ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

CREATE TRIGGER failed
    AFTER UPDATE ON parted_trig referencing old TABLE AS old_table
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

DROP TABLE parted_trig;

--
-- Verify trigger creation for partitioned tables, and drop behavior
--
CREATE TABLE trigpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE trigpart1 PARTITION OF trigpart
FOR VALUES FROM (0) TO (1000);

CREATE TRIGGER trg1
    AFTER INSERT ON trigpart
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

CREATE TABLE trigpart2 PARTITION OF trigpart
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE trigpart3 (
    LIKE trigpart
);

ALTER TABLE trigpart ATTACH PARTITION trigpart3
FOR VALUES FROM (2000) TO (3000);

CREATE TABLE trigpart4 PARTITION OF trigpart
FOR VALUES FROM (3000) TO (4000)
PARTITION BY RANGE (a);

CREATE TABLE trigpart41 PARTITION OF trigpart4
FOR VALUES FROM (3000) TO (3500);

CREATE TABLE trigpart42 (
    LIKE trigpart
);

ALTER TABLE trigpart4 ATTACH PARTITION trigpart42
FOR VALUES FROM (3500) TO (4000);

SELECT
    tgrelid::regclass,
    tgname,
    tgfoid::regproc
FROM
    pg_trigger
WHERE
    tgrelid::regclass::text LIKE 'trigpart%'
ORDER BY
    tgrelid::regclass::text;

DROP TRIGGER trg1 ON trigpart1;

-- fail
DROP TRIGGER trg1 ON trigpart2;

-- fail
DROP TRIGGER trg1 ON trigpart3;

-- fail
DROP TABLE trigpart2;

-- ok, trigger should be gone in that partition
SELECT
    tgrelid::regclass,
    tgname,
    tgfoid::regproc
FROM
    pg_trigger
WHERE
    tgrelid::regclass::text LIKE 'trigpart%'
ORDER BY
    tgrelid::regclass::text;

DROP TRIGGER trg1 ON trigpart;

-- ok, all gone
SELECT
    tgrelid::regclass,
    tgname,
    tgfoid::regproc
FROM
    pg_trigger
WHERE
    tgrelid::regclass::text LIKE 'trigpart%'
ORDER BY
    tgrelid::regclass::text;

-- check detach behavior
CREATE TRIGGER trg1
    AFTER INSERT ON trigpart
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

\d trigpart3
ALTER TABLE trigpart DETACH PARTITION trigpart3;

DROP TRIGGER trg1 ON trigpart3;

-- fail due to "does not exist"
ALTER TABLE trigpart DETACH PARTITION trigpart4;

DROP TRIGGER trg1 ON trigpart41;

-- fail due to "does not exist"
DROP TABLE trigpart4;

ALTER TABLE trigpart ATTACH PARTITION trigpart3
FOR VALUES FROM (2000) TO (3000);

ALTER TABLE trigpart DETACH PARTITION trigpart3;

ALTER TABLE trigpart ATTACH PARTITION trigpart3
FOR VALUES FROM (2000) TO (3000);

DROP TABLE trigpart3;

SELECT
    tgrelid::regclass::text,
    tgname,
    tgfoid::regproc,
    tgenabled,
    tgisinternal
FROM
    pg_trigger
WHERE
    tgname ~ '^trg1'
ORDER BY
    1;

CREATE TABLE trigpart3 (
    LIKE trigpart
);

CREATE TRIGGER trg1
    AFTER INSERT ON trigpart3
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

\d trigpart3
ALTER TABLE trigpart ATTACH PARTITION trigpart3
FOR VALUES FROM (2000) TO (3000);

-- fail
DROP TABLE trigpart3;

-- check display of unrelated triggers
CREATE TRIGGER samename
    AFTER DELETE ON trigpart
    EXECUTE FUNCTION trigger_nothing ();

CREATE TRIGGER samename
    AFTER DELETE ON trigpart1
    EXECUTE FUNCTION trigger_nothing ();

\d trigpart1
DROP TABLE trigpart;

DROP FUNCTION trigger_nothing ();

--
-- Verify that triggers are fired for partitioned tables
--
CREATE TABLE parted_stmt_trig (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE parted_stmt_trig1 PARTITION OF parted_stmt_trig
FOR VALUES IN (1);

CREATE TABLE parted_stmt_trig2 PARTITION OF parted_stmt_trig
FOR VALUES IN (2);

CREATE TABLE parted2_stmt_trig (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE parted2_stmt_trig1 PARTITION OF parted2_stmt_trig
FOR VALUES IN (1);

CREATE TABLE parted2_stmt_trig2 PARTITION OF parted2_stmt_trig
FOR VALUES IN (2);

CREATE OR REPLACE FUNCTION trigger_notice ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'trigger % on % % % for %', TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL;
    IF TG_LEVEL = 'ROW' THEN
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

-- insert/update/delete statement-level triggers on the parent
CREATE TRIGGER trig_ins_before
    BEFORE INSERT ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after
    AFTER INSERT ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before
    BEFORE UPDATE ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after
    AFTER UPDATE ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before
    BEFORE DELETE ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after
    AFTER DELETE ON parted_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete row-level triggers on the parent
CREATE TRIGGER trig_ins_after_parent
    AFTER INSERT ON parted_stmt_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_parent
    AFTER UPDATE ON parted_stmt_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_parent
    AFTER DELETE ON parted_stmt_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete row-level triggers on the first partition
CREATE TRIGGER trig_ins_before_child
    BEFORE INSERT ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after_child
    AFTER INSERT ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before_child
    BEFORE UPDATE ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_child
    AFTER UPDATE ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before_child
    BEFORE DELETE ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_child
    AFTER DELETE ON parted_stmt_trig1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete statement-level triggers on the parent
CREATE TRIGGER trig_ins_before_3
    BEFORE INSERT ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after_3
    AFTER INSERT ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before_3
    BEFORE UPDATE ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_3
    AFTER UPDATE ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before_3
    BEFORE DELETE ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_3
    AFTER DELETE ON parted2_stmt_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

WITH ins (
    a
) AS (
    INSERT INTO parted2_stmt_trig
    VALUES
        (1),
        (2)
    RETURNING
        a
)
INSERT INTO parted_stmt_trig
SELECT
    a
FROM
    ins
RETURNING
    tableoid::regclass,
    a;

WITH upd AS (
    UPDATE
        parted2_stmt_trig
    SET
        a = a
)
UPDATE
    parted_stmt_trig
SET
    a = a;

DELETE FROM parted_stmt_trig;

-- insert via copy on the parent
copy parted_stmt_trig(a) from stdin;
1
2
\.
-- insert via copy on the first partition
copy parted_stmt_trig1(a) from stdin;
1
\.
-- Disabling a trigger in the parent table should disable children triggers too
ALTER TABLE parted_stmt_trig DISABLE TRIGGER trig_ins_after_parent;

INSERT INTO parted_stmt_trig
    VALUES (1);

ALTER TABLE parted_stmt_trig ENABLE TRIGGER trig_ins_after_parent;

INSERT INTO parted_stmt_trig
    VALUES (1);

DROP TABLE parted_stmt_trig, parted2_stmt_trig;

-- Verify that triggers fire in alphabetical order
CREATE TABLE parted_trig (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE parted_trig_1 PARTITION OF parted_trig
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE parted_trig_1_1 PARTITION OF parted_trig_1
FOR VALUES FROM (0) TO (100);

CREATE TABLE parted_trig_2 PARTITION OF parted_trig
FOR VALUES FROM (1000) TO (2000);

CREATE TRIGGER zzz
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER mmm
    AFTER INSERT ON parted_trig_1_1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER aaa
    AFTER INSERT ON parted_trig_1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER bbb
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER qqq
    AFTER INSERT ON parted_trig_1_1
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

INSERT INTO parted_trig
VALUES
    (50),
    (1500);

DROP TABLE parted_trig;

-- Verify that the correct triggers fire for cross-partition updates
CREATE TABLE parted_trig (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE parted_trig1 PARTITION OF parted_trig
FOR VALUES IN (1);

CREATE TABLE parted_trig2 PARTITION OF parted_trig
FOR VALUES IN (2);

INSERT INTO parted_trig
    VALUES (1);

CREATE OR REPLACE FUNCTION trigger_notice ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'trigger % on % % % for %', TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL;
    IF TG_LEVEL = 'ROW' THEN
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER parted_trig_before_stmt
    BEFORE INSERT OR UPDATE OR DELETE ON parted_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER parted_trig_before_row
    BEFORE INSERT OR UPDATE OR DELETE ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER parted_trig_after_row
    AFTER INSERT OR UPDATE OR DELETE ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER parted_trig_after_stmt
    AFTER INSERT OR UPDATE OR DELETE ON parted_trig
    FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

UPDATE
    parted_trig
SET
    a = 2
WHERE
    a = 1;

-- update action in merge should behave the same
merge INTO parted_trig
    USING (
        SELECT
            1) AS ss ON TRUE
    WHEN matched AND a = 2 THEN
        UPDATE SET a = 1;

DROP TABLE parted_trig;

-- Verify propagation of trigger arguments to partitions
CREATE TABLE parted_trig (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE parted_trig1 PARTITION OF parted_trig
FOR VALUES IN (1);

CREATE OR REPLACE FUNCTION trigger_notice ()
    RETURNS trigger
    AS $$
DECLARE
    arg1 text = TG_ARGV[0];
    arg2 integer = TG_ARGV[1];
BEGIN
    RAISE NOTICE 'trigger % on % % % for % args % %', TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL, arg1, arg2;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER aaa
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ('quirky', 1);

-- Verify propagation of trigger arguments to partitions attached after creating trigger
CREATE TABLE parted_trig2 PARTITION OF parted_trig
FOR VALUES IN (2);

CREATE TABLE parted_trig3 (
    LIKE parted_trig
);

ALTER TABLE parted_trig ATTACH PARTITION parted_trig3
FOR VALUES IN (3);

INSERT INTO parted_trig
VALUES
    (1),
    (2),
    (3);

DROP TABLE parted_trig;

-- test irregular partitions (i.e., different column definitions),
-- including that the WHEN clause works
CREATE FUNCTION bark (text)
    RETURNS bool
    LANGUAGE plpgsql
    IMMUTABLE
    AS $$
BEGIN
    RAISE NOTICE '% <- woof!', $1;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_notice_ab ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'trigger % on % % % for %: (a,b)=(%,%)', TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL, NEW.a, NEW.b;
    IF TG_LEVEL = 'ROW' THEN
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TABLE parted_irreg_ancestor (
    fd text,
    b text,
    fd2 int,
    fd3 int,
    a int
)
PARTITION BY RANGE (b);

ALTER TABLE parted_irreg_ancestor
    DROP COLUMN fd,
    DROP COLUMN fd2,
    DROP COLUMN fd3;

CREATE TABLE parted_irreg (
    fd int,
    a int,
    fd2 int,
    b text
)
PARTITION BY RANGE (b);

ALTER TABLE parted_irreg
    DROP COLUMN fd,
    DROP COLUMN fd2;

ALTER TABLE parted_irreg_ancestor ATTACH PARTITION parted_irreg
FOR VALUES FROM ('aaaa') TO ('zzzz');

CREATE TABLE parted1_irreg (
    b text,
    fd int,
    a int
);

ALTER TABLE parted1_irreg
    DROP COLUMN fd;

ALTER TABLE parted_irreg ATTACH PARTITION parted1_irreg
FOR VALUES FROM ('aaaa') TO ('bbbb');

CREATE TRIGGER parted_trig
    AFTER INSERT ON parted_irreg
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE TRIGGER parted_trig_odd
    AFTER INSERT ON parted_irreg
    FOR EACH ROW
    WHEN (bark (new.b) AND new.a % 2 = 1)
    EXECUTE PROCEDURE trigger_notice_ab ();

-- we should hear barking for every insert, but parted_trig_odd only emits
-- noise for odd values of a. parted_trig does it for all inserts.
INSERT INTO parted_irreg
VALUES
    (1, 'aardvark'),
    (2, 'aanimals');

INSERT INTO parted1_irreg
    VALUES ('aardwolf', 2);

INSERT INTO parted_irreg_ancestor
    VALUES ('aasvogel', 3);

DROP TABLE parted_irreg_ancestor;

-- Before triggers and partitions
CREATE TABLE parted (
    a int,
    b int,
    c text
)
PARTITION BY LIST (a);

CREATE TABLE parted_1 PARTITION OF parted
FOR VALUES IN (1)
PARTITION BY LIST (b);

CREATE TABLE parted_1_1 PARTITION OF parted_1
FOR VALUES IN (1);

CREATE FUNCTION parted_trigfunc ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.a = NEW.a + 1;
    RETURN new;
END;
$$;

INSERT INTO parted
    VALUES (1, 1, 'uno uno v1');

-- works
CREATE TRIGGER t
    BEFORE INSERT OR UPDATE OR DELETE ON parted
    FOR EACH ROW
    EXECUTE FUNCTION parted_trigfunc ();

INSERT INTO parted
    VALUES (1, 1, 'uno uno v2');

-- fail
UPDATE
    parted
SET
    c = c || 'v3';

-- fail
CREATE OR REPLACE FUNCTION parted_trigfunc ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.b = NEW.b + 1;
    RETURN new;
END;
$$;

INSERT INTO parted
    VALUES (1, 1, 'uno uno v4');

-- fail
UPDATE
    parted
SET
    c = c || 'v5';

-- fail
CREATE OR REPLACE FUNCTION parted_trigfunc ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.c = NEW.c || ' did ' || TG_OP;
    RETURN new;
END;
$$;

INSERT INTO parted
    VALUES (1, 1, 'uno uno');

-- works
UPDATE
    parted
SET
    c = c || ' v6';

-- works
SELECT
    tableoid::regclass,
    *
FROM
    parted;

-- update itself moves tuple to new partition; trigger still works
TRUNCATE TABLE parted;

CREATE TABLE parted_2 PARTITION OF parted
FOR VALUES IN (2);

INSERT INTO parted
    VALUES (1, 1, 'uno uno v5');

UPDATE
    parted
SET
    a = 2;

SELECT
    tableoid::regclass,
    *
FROM
    parted;

-- both trigger and update change the partition
CREATE OR REPLACE FUNCTION parted_trigfunc2 ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.a = NEW.a + 1;
    RETURN new;
END;
$$;

CREATE TRIGGER t2
    BEFORE UPDATE ON parted
    FOR EACH ROW
    EXECUTE FUNCTION parted_trigfunc2 ();

TRUNCATE TABLE parted;

INSERT INTO parted
    VALUES (1, 1, 'uno uno v6');

CREATE TABLE parted_3 PARTITION OF parted
FOR VALUES IN (3);

UPDATE
    parted
SET
    a = a + 1;

SELECT
    tableoid::regclass,
    *
FROM
    parted;

-- there's no partition for a=0, but this update works anyway because
-- the trigger causes the tuple to be routed to another partition
UPDATE
    parted
SET
    a = 0;

SELECT
    tableoid::regclass,
    *
FROM
    parted;

DROP TABLE parted;

CREATE TABLE parted (
    a int,
    b int,
    c text
)
PARTITION BY LIST ((a + b));

CREATE OR REPLACE FUNCTION parted_trigfunc ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.a = NEW.a + NEW.b;
    RETURN new;
END;
$$;

CREATE TABLE parted_1 PARTITION OF parted
FOR VALUES IN (1, 2);

CREATE TABLE parted_2 PARTITION OF parted
FOR VALUES IN (3, 4);

CREATE TRIGGER t
    BEFORE INSERT OR UPDATE ON parted
    FOR EACH ROW
    EXECUTE FUNCTION parted_trigfunc ();

INSERT INTO parted
    VALUES (0, 1, 'zero win');

INSERT INTO parted
    VALUES (1, 1, 'one fail');

INSERT INTO parted
    VALUES (1, 2, 'two fail');

SELECT
    *
FROM
    parted;

DROP TABLE parted;

DROP FUNCTION parted_trigfunc ();

--
-- Constraint triggers
--
CREATE CONSTRAINT TRIGGER crtr
    AFTER INSERT ON foo NOT valid
    FOR EACH ROW
    EXECUTE PROCEDURE foo ();

CREATE CONSTRAINT TRIGGER crtr
    AFTER INSERT ON foo NO inherit
    FOR EACH ROW
    EXECUTE PROCEDURE foo ();

CREATE CONSTRAINT TRIGGER crtr
    AFTER INSERT ON foo NOT enforced
    FOR EACH ROW
    EXECUTE PROCEDURE foo ();

-- Test exception handling in a deferred constraint trigger at COMMIT.
CREATE TABLE deferred_trigger_test (
    a int
);

CREATE FUNCTION deferred_trigger_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM
        1 / 0;
    RETURN new;
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'caught division_by_zero';
        RETURN new;
END;

$$;

CREATE CONSTRAINT TRIGGER deferred_trigger
    AFTER INSERT ON deferred_trigger_test DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION deferred_trigger_func ();

BEGIN;
INSERT INTO deferred_trigger_test
    VALUES (1);
COMMIT;

SELECT
    *
FROM
    deferred_trigger_test;

DROP TABLE deferred_trigger_test;

DROP FUNCTION deferred_trigger_func ();

--
-- Constraint triggers and partitioned tables
CREATE TABLE parted_constr_ancestor (
    a int,
    b text
)
PARTITION BY RANGE (b);

CREATE TABLE parted_constr (
    a int,
    b text
)
PARTITION BY RANGE (b);

ALTER TABLE parted_constr_ancestor ATTACH PARTITION parted_constr
FOR VALUES FROM ('aaaa') TO ('zzzz');

CREATE TABLE parted1_constr (
    a int,
    b text
);

ALTER TABLE parted_constr ATTACH PARTITION parted1_constr
FOR VALUES FROM ('aaaa') TO ('bbbb');

CREATE CONSTRAINT TRIGGER parted_trig
    AFTER INSERT ON parted_constr_ancestor DEFERRABLE
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE CONSTRAINT TRIGGER parted_trig_two
    AFTER INSERT ON parted_constr DEFERRABLE INITIALLY DEFERRED enforced
    FOR EACH ROW
    WHEN (bark (new.b) AND new.a % 2 = 1)
    EXECUTE PROCEDURE trigger_notice_ab ();

-- The immediate constraint is fired immediately; the WHEN clause of the
-- deferred constraint is also called immediately.  The deferred constraint
-- is fired at commit time.
BEGIN;
INSERT INTO parted_constr
    VALUES (1, 'aardvark');
INSERT INTO parted1_constr
    VALUES (2, 'aardwolf');
INSERT INTO parted_constr_ancestor
    VALUES (3, 'aasvogel');
COMMIT;

-- The WHEN clause is immediate, and both constraint triggers are fired at
-- commit time.
BEGIN;
SET constraints parted_trig DEFERRED;
INSERT INTO parted_constr
    VALUES (1, 'aardvark');
INSERT INTO parted1_constr
VALUES
    (2, 'aardwolf'),
    (3, 'aasvogel');
COMMIT;

DROP TABLE parted_constr_ancestor;

DROP FUNCTION bark (text);

-- Test that the WHEN clause is set properly to partitions
CREATE TABLE parted_trigger (
    a int,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE parted_trigger_1 PARTITION OF parted_trigger
FOR VALUES FROM (0) TO (1000);

CREATE TABLE parted_trigger_2 (
    drp int,
    a int,
    b text
);

ALTER TABLE parted_trigger_2
    DROP COLUMN drp;

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_2
FOR VALUES FROM (1000) TO (2000);

CREATE TRIGGER parted_trigger
    AFTER UPDATE ON parted_trigger
    FOR EACH ROW
    WHEN (new.a % 2 = 1 AND length(old.b) >= 2)
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE TABLE parted_trigger_3 (
    b text,
    a int
)
PARTITION BY RANGE (length(b));

CREATE TABLE parted_trigger_3_1 PARTITION OF parted_trigger_3
FOR VALUES FROM (1) TO (3);

CREATE TABLE parted_trigger_3_2 PARTITION OF parted_trigger_3
FOR VALUES FROM (3) TO (5);

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_3
FOR VALUES FROM (2000) TO (3000);

INSERT INTO parted_trigger
VALUES
    (0, 'a'),
    (1, 'bbb'),
    (2, 'bcd'),
    (3, 'c'),
    (1000, 'c'),
    (1001, 'ddd'),
    (1002, 'efg'),
    (1003, 'f'),
    (2000, 'e'),
    (2001, 'fff'),
    (2002, 'ghi'),
    (2003, 'h');

UPDATE
    parted_trigger
SET
    a = a + 2;

-- notice for odd 'a' values, long 'b' values
DROP TABLE parted_trigger;

-- try a constraint trigger, also
CREATE TABLE parted_referenced (
    a int
);

CREATE TABLE unparted_trigger (
    a int,
    b text
);

-- for comparison purposes
CREATE TABLE parted_trigger (
    a int,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE parted_trigger_1 PARTITION OF parted_trigger
FOR VALUES FROM (0) TO (1000);

CREATE TABLE parted_trigger_2 (
    drp int,
    a int,
    b text
);

ALTER TABLE parted_trigger_2
    DROP COLUMN drp;

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_2
FOR VALUES FROM (1000) TO (2000);

CREATE CONSTRAINT TRIGGER parted_trigger
    AFTER UPDATE ON parted_trigger
FROM
    parted_referenced
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE CONSTRAINT TRIGGER parted_trigger
    AFTER UPDATE ON unparted_trigger
FROM
    parted_referenced
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE TABLE parted_trigger_3 (
    b text,
    a int
)
PARTITION BY RANGE (length(b));

CREATE TABLE parted_trigger_3_1 PARTITION OF parted_trigger_3
FOR VALUES FROM (1) TO (3);

CREATE TABLE parted_trigger_3_2 PARTITION OF parted_trigger_3
FOR VALUES FROM (3) TO (5);

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_3
FOR VALUES FROM (2000) TO (3000);

SELECT
    tgname,
    conname,
    t.tgrelid::regclass,
    t.tgconstrrelid::regclass,
    c.conrelid::regclass,
    c.confrelid::regclass
FROM
    pg_trigger t
    JOIN pg_constraint c ON (t.tgconstraint = c.oid)
WHERE
    tgname = 'parted_trigger'
ORDER BY
    t.tgrelid::regclass::text;

DROP TABLE parted_referenced, parted_trigger, unparted_trigger;

-- verify that the "AFTER UPDATE OF columns" event is propagated correctly
CREATE TABLE parted_trigger (
    a int,
    b text
)
PARTITION BY RANGE (a);

CREATE TABLE parted_trigger_1 PARTITION OF parted_trigger
FOR VALUES FROM (0) TO (1000);

CREATE TABLE parted_trigger_2 (
    drp int,
    a int,
    b text
);

ALTER TABLE parted_trigger_2
    DROP COLUMN drp;

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_2
FOR VALUES FROM (1000) TO (2000);

CREATE TRIGGER parted_trigger
    AFTER UPDATE OF b ON parted_trigger
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE TABLE parted_trigger_3 (
    b text,
    a int
)
PARTITION BY RANGE (length(b));

CREATE TABLE parted_trigger_3_1 PARTITION OF parted_trigger_3
FOR VALUES FROM (1) TO (4);

CREATE TABLE parted_trigger_3_2 PARTITION OF parted_trigger_3
FOR VALUES FROM (4) TO (8);

ALTER TABLE parted_trigger ATTACH PARTITION parted_trigger_3
FOR VALUES FROM (2000) TO (3000);

INSERT INTO parted_trigger
VALUES
    (0, 'a'),
    (1000, 'c'),
    (2000, 'e'),
    (2001, 'eeee');

UPDATE
    parted_trigger
SET
    a = a + 2;

-- no notices here
UPDATE
    parted_trigger
SET
    b = b || 'b';

-- all triggers should fire
DROP TABLE parted_trigger;

DROP FUNCTION trigger_notice_ab ();

-- Make sure we don't end up with unnecessary copies of triggers, when
-- cloning them.
CREATE TABLE trg_clone (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE trg_clone1 PARTITION OF trg_clone
FOR VALUES FROM (0) TO (1000);

ALTER TABLE trg_clone
    ADD CONSTRAINT uniq UNIQUE (a) DEFERRABLE;

CREATE TABLE trg_clone2 PARTITION OF trg_clone
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE trg_clone3 PARTITION OF trg_clone
FOR VALUES FROM (2000) TO (3000)
PARTITION BY RANGE (a);

CREATE TABLE trg_clone_3_3 PARTITION OF trg_clone3
FOR VALUES FROM (2000) TO (2100);

SELECT
    tgrelid::regclass,
    count(*)
FROM
    pg_trigger
WHERE
    tgrelid::regclass IN ('trg_clone', 'trg_clone1', 'trg_clone2', 'trg_clone3', 'trg_clone_3_3')
GROUP BY
    tgrelid::regclass
ORDER BY
    tgrelid::regclass;

DROP TABLE trg_clone;

-- Test the interaction between ALTER TABLE .. DISABLE TRIGGER and
-- both kinds of inheritance.  Historically, legacy inheritance has
-- not recursed to children, so that behavior is preserved.
CREATE TABLE parent (
    a int
);

CREATE TABLE child1 ()
INHERITS (
    parent
);

CREATE FUNCTION trig_nothing ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN NULL;
END
$$;

CREATE TRIGGER tg
    AFTER INSERT ON parent
    FOR EACH ROW
    EXECUTE FUNCTION trig_nothing ();

CREATE TRIGGER tg
    AFTER INSERT ON child1
    FOR EACH ROW
    EXECUTE FUNCTION trig_nothing ();

ALTER TABLE parent DISABLE TRIGGER tg;

SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text;

ALTER TABLE ONLY parent ENABLE ALWAYS TRIGGER tg;

SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text;

DROP TABLE parent, child1;

CREATE TABLE parent (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE child1 PARTITION OF parent
FOR VALUES IN (1);

CREATE TRIGGER tg
    AFTER INSERT ON parent
    FOR EACH ROW
    EXECUTE PROCEDURE trig_nothing ();

CREATE TRIGGER tg_stmt
    AFTER INSERT ON parent FOR statement
    EXECUTE PROCEDURE trig_nothing ();

SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgname;

ALTER TABLE ONLY parent ENABLE ALWAYS TRIGGER tg;

-- no recursion because ONLY
ALTER TABLE parent ENABLE ALWAYS TRIGGER tg_stmt;

-- no recursion because statement trigger
SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgname;

-- The following is a no-op for the parent trigger but not so
-- for the child trigger, so recursion should be applied.
ALTER TABLE parent ENABLE ALWAYS TRIGGER tg;

SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgname;

-- This variant malfunctioned in some releases.
ALTER TABLE parent DISABLE TRIGGER USER;

SELECT
    tgrelid::regclass,
    tgname,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgname;

DROP TABLE parent, child1;

-- Check processing of foreign key triggers
CREATE TABLE parent (
    a int PRIMARY KEY,
    f int REFERENCES parent
)
PARTITION BY LIST (a);

CREATE TABLE child1 PARTITION OF parent
FOR VALUES IN (1);

SELECT
    tgrelid::regclass,
    rtrim(tgname, '0123456789') AS tgname,
    tgfoid::regproc,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgfoid;

ALTER TABLE parent DISABLE TRIGGER ALL;

SELECT
    tgrelid::regclass,
    rtrim(tgname, '0123456789') AS tgname,
    tgfoid::regproc,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid IN ('parent'::regclass, 'child1'::regclass)
ORDER BY
    tgrelid::regclass::text,
    tgfoid;

DROP TABLE parent, child1;

-- Verify that firing state propagates correctly on creation, too
CREATE TABLE trgfire (
    i int
)
PARTITION BY RANGE (i);

CREATE TABLE trgfire1 PARTITION OF trgfire
FOR VALUES FROM (1) TO (10);

CREATE OR REPLACE FUNCTION tgf ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'except';
END
$$;

CREATE TRIGGER tg
    AFTER INSERT ON trgfire
    FOR EACH ROW
    EXECUTE FUNCTION tgf ();

INSERT INTO trgfire
    VALUES (1);

ALTER TABLE trgfire DISABLE TRIGGER tg;

INSERT INTO trgfire
    VALUES (1);

CREATE TABLE trgfire2 PARTITION OF trgfire
FOR VALUES FROM (10) TO (20);

INSERT INTO trgfire
    VALUES (11);

CREATE TABLE trgfire3 (
    LIKE trgfire
);

ALTER TABLE trgfire ATTACH PARTITION trgfire3
FOR VALUES FROM (20) TO (30);

INSERT INTO trgfire
    VALUES (21);

CREATE TABLE trgfire4 PARTITION OF trgfire
FOR VALUES FROM (30) TO (40)
PARTITION BY LIST (i);

CREATE TABLE trgfire4_30 PARTITION OF trgfire4
FOR VALUES IN (30);

INSERT INTO trgfire
    VALUES (30);

CREATE TABLE trgfire5 (
    LIKE trgfire
)
PARTITION BY LIST (i);

CREATE TABLE trgfire5_40 PARTITION OF trgfire5
FOR VALUES IN (40);

ALTER TABLE trgfire ATTACH PARTITION trgfire5
FOR VALUES FROM (40) TO (50);

INSERT INTO trgfire
    VALUES (40);

SELECT
    tgrelid::regclass,
    tgenabled
FROM
    pg_trigger
WHERE
    tgrelid::regclass IN (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname LIKE 'trgfire%')
ORDER BY
    tgrelid::regclass::text;

ALTER TABLE trgfire ENABLE TRIGGER tg;

INSERT INTO trgfire
    VALUES (1);

INSERT INTO trgfire
    VALUES (11);

INSERT INTO trgfire
    VALUES (21);

INSERT INTO trgfire
    VALUES (30);

INSERT INTO trgfire
    VALUES (40);

DROP TABLE trgfire;

DROP FUNCTION tgf ();

--
-- Test the interaction between transition tables and both kinds of
-- inheritance.  We'll dump the contents of the transition tables in a
-- format that shows the attribute order, so that we can distinguish
-- tuple formats (though not dropped attributes).
--
CREATE OR REPLACE FUNCTION dump_insert ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, new table = %', TG_NAME, (
        SELECT
            string_agg(new_table::text, ', ' ORDER BY a)
        FROM
            new_table);
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION dump_update ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, old table = %, new table = %', TG_NAME, (
        SELECT
            string_agg(old_table::text, ', ' ORDER BY a)
        FROM
            old_table),
    (
        SELECT
            string_agg(new_table::text, ', ' ORDER BY a)
        FROM
            new_table);
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION dump_delete ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, old table = %', TG_NAME, (
        SELECT
            string_agg(old_table::text, ', ' ORDER BY a)
        FROM
            old_table);
    RETURN NULL;
END;
$$;

--
-- Verify behavior of statement triggers on partition hierarchy with
-- transition tables.  Tuples should appear to each trigger in the
-- format of the relation the trigger is attached to.
--
-- set up a partition hierarchy with some different TupleDescriptors
CREATE TABLE parent (
    a text,
    b int
)
PARTITION BY LIST (a);

-- a child matching parent
CREATE TABLE child1 PARTITION OF parent
FOR VALUES IN ('AAA');

-- a child with a dropped column
CREATE TABLE child2 (
    x int,
    a text,
    b int
);

ALTER TABLE child2
    DROP COLUMN x;

ALTER TABLE parent ATTACH PARTITION child2
FOR VALUES IN ('BBB');

-- a child with a different column order
CREATE TABLE child3 (
    b int,
    a text
);

ALTER TABLE parent ATTACH PARTITION child3
FOR VALUES IN ('CCC');

CREATE TRIGGER parent_insert_trig
    AFTER INSERT ON parent referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER parent_update_trig
    AFTER UPDATE ON parent referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER parent_delete_trig
    AFTER DELETE ON parent referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child1_insert_trig
    AFTER INSERT ON child1 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child1_update_trig
    AFTER UPDATE ON child1 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child1_delete_trig
    AFTER DELETE ON child1 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child2_insert_trig
    AFTER INSERT ON child2 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child2_update_trig
    AFTER UPDATE ON child2 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child2_delete_trig
    AFTER DELETE ON child2 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child3_insert_trig
    AFTER INSERT ON child3 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child3_update_trig
    AFTER UPDATE ON child3 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child3_delete_trig
    AFTER DELETE ON child3 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

SELECT
    trigger_name,
    event_manipulation,
    event_object_schema,
    event_object_table,
    action_order,
    action_condition,
    action_orientation,
    action_timing,
    action_reference_old_table,
    action_reference_new_table
FROM
    information_schema.triggers
WHERE
    event_object_table IN ('parent', 'child1', 'child2', 'child3')
ORDER BY
    trigger_name COLLATE "C",
    2;

-- insert directly into children sees respective child-format tuples
INSERT INTO child1
    VALUES ('AAA', 42);

INSERT INTO child2
    VALUES ('BBB', 42);

INSERT INTO child3
    VALUES (42, 'CCC');

-- update via parent sees parent-format tuples
UPDATE
    parent
SET
    b = b + 1;

-- delete via parent sees parent-format tuples
DELETE FROM parent;

-- insert into parent sees parent-format tuples
INSERT INTO parent
    VALUES ('AAA', 42);

INSERT INTO parent
    VALUES ('BBB', 42);

INSERT INTO parent
    VALUES ('CCC', 42);

-- delete from children sees respective child-format tuples
DELETE FROM child1;

DELETE FROM child2;

DELETE FROM child3;

-- copy into parent sees parent-format tuples
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- check detach/reattach behavior; statement triggers with transition tables
-- should not prevent a table from becoming a partition again
ALTER TABLE parent DETACH PARTITION child1;

ALTER TABLE parent ATTACH PARTITION child1
FOR VALUES IN ('AAA');

-- DML affecting parent sees tuples collected from children even if
-- there is no transition table trigger on the children
DROP TRIGGER child1_insert_trig ON child1;

DROP TRIGGER child1_update_trig ON child1;

DROP TRIGGER child1_delete_trig ON child1;

DROP TRIGGER child2_insert_trig ON child2;

DROP TRIGGER child2_update_trig ON child2;

DROP TRIGGER child2_delete_trig ON child2;

DROP TRIGGER child3_insert_trig ON child3;

DROP TRIGGER child3_update_trig ON child3;

DROP TRIGGER child3_delete_trig ON child3;

DELETE FROM parent;

-- copy into parent sees tuples collected from children even if there
-- is no transition-table trigger on the children
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- insert into parent with a before trigger on a child tuple before
-- insertion, and we capture the newly modified row in parent format
CREATE OR REPLACE FUNCTION intercept_insert ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.b = NEW.b + 1000;
    RETURN new;
END;
$$;

CREATE TRIGGER intercept_insert_child3
    BEFORE INSERT ON child3
    FOR EACH ROW
    EXECUTE PROCEDURE intercept_insert ();

-- insert, parent trigger sees post-modification parent-format tuple
INSERT INTO parent
VALUES
    ('AAA', 42),
    ('BBB', 42),
    ('CCC', 66);

-- copy, parent trigger sees post-modification parent-format tuple
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	234
\.

DROP TABLE child1, child2, child3, parent;

DROP FUNCTION intercept_insert ();

--
-- Verify prohibition of row triggers with transition triggers on
-- partitions
--
CREATE TABLE parent (
    a text,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE child PARTITION OF parent
FOR VALUES IN ('AAA');

-- adding row trigger with transition table fails
CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table
    FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- detaching it first works
ALTER TABLE parent DETACH PARTITION child;

CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table
    FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- but now we're not allowed to reattach it
ALTER TABLE parent ATTACH PARTITION child
FOR VALUES IN ('AAA');

-- drop the trigger, and now we're allowed to attach it again
DROP TRIGGER child_row_trig ON child;

ALTER TABLE parent ATTACH PARTITION child
FOR VALUES IN ('AAA');

DROP TABLE child, parent;

--
-- Verify access of transition tables with UPDATE triggers and tuples
-- moved across partitions.
--
CREATE OR REPLACE FUNCTION dump_update_new ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, new table = %', TG_NAME, (
        SELECT
            string_agg(new_table::text, ', ' ORDER BY a)
        FROM
            new_table);
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION dump_update_old ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, old table = %', TG_NAME, (
        SELECT
            string_agg(old_table::text, ', ' ORDER BY a)
        FROM
            old_table);
    RETURN NULL;
END;
$$;

CREATE TABLE trans_tab_parent (
    a text
)
PARTITION BY LIST (a);

CREATE TABLE trans_tab_child1 PARTITION OF trans_tab_parent
FOR VALUES IN ('AAA1', 'AAA2');

CREATE TABLE trans_tab_child2 PARTITION OF trans_tab_parent
FOR VALUES IN ('BBB1', 'BBB2');

CREATE TRIGGER trans_tab_parent_update_trig
    AFTER UPDATE ON trans_tab_parent referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update_old ();

CREATE TRIGGER trans_tab_parent_insert_trig
    AFTER INSERT ON trans_tab_parent referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER trans_tab_parent_delete_trig
    AFTER DELETE ON trans_tab_parent referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

INSERT INTO trans_tab_parent
VALUES
    ('AAA1'),
    ('BBB1');

-- should not trigger access to new table when moving across partitions.
UPDATE
    trans_tab_parent
SET
    a = 'BBB2'
WHERE
    a = 'AAA1';

DROP TRIGGER trans_tab_parent_update_trig ON trans_tab_parent;

CREATE TRIGGER trans_tab_parent_update_trig
    AFTER UPDATE ON trans_tab_parent referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update_new ();

-- should not trigger access to old table when moving across partitions.
UPDATE
    trans_tab_parent
SET
    a = 'AAA2'
WHERE
    a = 'BBB1';

DELETE FROM trans_tab_parent;

-- clean up
DROP TABLE trans_tab_parent, trans_tab_child1, trans_tab_child2;

DROP FUNCTION dump_update_new, dump_update_old;

--
-- Verify behavior of statement triggers on (non-partition)
-- inheritance hierarchy with transition tables; similar to the
-- partition case, except there is no rerouting on insertion and child
-- tables can have extra columns
--
-- set up inheritance hierarchy with different TupleDescriptors
CREATE TABLE parent (
    a text,
    b int
);

-- a child matching parent
CREATE TABLE child1 ()
INHERITS (
    parent
);

-- a child with a different column order
CREATE TABLE child2 (
    b int,
    a text
);

ALTER TABLE child2 inherit parent;

-- a child with an extra column
CREATE TABLE child3 (
    c text
)
INHERITS (
    parent
);

CREATE TRIGGER parent_insert_trig
    AFTER INSERT ON parent referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER parent_update_trig
    AFTER UPDATE ON parent referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER parent_delete_trig
    AFTER DELETE ON parent referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child1_insert_trig
    AFTER INSERT ON child1 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child1_update_trig
    AFTER UPDATE ON child1 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child1_delete_trig
    AFTER DELETE ON child1 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child2_insert_trig
    AFTER INSERT ON child2 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child2_update_trig
    AFTER UPDATE ON child2 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child2_delete_trig
    AFTER DELETE ON child2 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child3_insert_trig
    AFTER INSERT ON child3 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child3_update_trig
    AFTER UPDATE ON child3 referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child3_delete_trig
    AFTER DELETE ON child3 referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

-- insert directly into children sees respective child-format tuples
INSERT INTO child1
    VALUES ('AAA', 42);

INSERT INTO child2
    VALUES (42, 'BBB');

INSERT INTO child3
    VALUES ('CCC', 42, 'foo');

-- update via parent sees parent-format tuples
UPDATE
    parent
SET
    b = b + 1;

-- delete via parent sees parent-format tuples
DELETE FROM parent;

-- reinsert values into children for next test...
INSERT INTO child1
    VALUES ('AAA', 42);

INSERT INTO child2
    VALUES (42, 'BBB');

INSERT INTO child3
    VALUES ('CCC', 42, 'foo');

-- delete from children sees respective child-format tuples
DELETE FROM child1;

DELETE FROM child2;

DELETE FROM child3;

-- copy into parent sees parent-format tuples (no rerouting, so these
-- are really inserted into the parent)
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- same behavior for copy if there is an index (interesting because rows are
-- captured by a different code path in copyfrom.c if there are indexes)
CREATE INDEX ON parent (b);

copy parent (a, b) from stdin;
DDD	42
\.

-- check disinherit/reinherit behavior; statement triggers with transition
-- tables should not prevent a table from becoming an inheritance child again
ALTER TABLE child1 NO inherit parent;

ALTER TABLE child1 inherit parent;

-- DML affecting parent sees tuples collected from children even if
-- there is no transition table trigger on the children
DROP TRIGGER child1_insert_trig ON child1;

DROP TRIGGER child1_update_trig ON child1;

DROP TRIGGER child1_delete_trig ON child1;

DROP TRIGGER child2_insert_trig ON child2;

DROP TRIGGER child2_update_trig ON child2;

DROP TRIGGER child2_delete_trig ON child2;

DROP TRIGGER child3_insert_trig ON child3;

DROP TRIGGER child3_update_trig ON child3;

DROP TRIGGER child3_delete_trig ON child3;

DELETE FROM parent;

DROP TABLE child1, child2, child3, parent;

--
-- Verify prohibition of row triggers with transition triggers on
-- inheritance children
--
CREATE TABLE parent (
    a text,
    b int
);

CREATE TABLE child ()
INHERITS (
    parent
);

-- adding row trigger with transition table fails
CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table
    FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- disinheriting it first works
ALTER TABLE child NO inherit parent;

CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table
    FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- but now we're not allowed to make it inherit anymore
ALTER TABLE child inherit parent;

-- drop the trigger, and now we're allowed to make it inherit again
DROP TRIGGER child_row_trig ON child;

ALTER TABLE child inherit parent;

DROP TABLE child, parent;

--
-- Verify behavior of queries with wCTEs, where multiple transition
-- tuplestores can be active at the same time because there are
-- multiple DML statements that might fire triggers with transition
-- tables
--
CREATE TABLE table1 (
    a int
);

CREATE TABLE table2 (
    a text
);

CREATE TRIGGER table1_trig
    AFTER INSERT ON table1 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER table2_trig
    AFTER INSERT ON table2 referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

WITH wcte AS (
    INSERT INTO table1
        VALUES (42)
)
INSERT INTO table2
    VALUES ('hello world');

WITH wcte AS (
    INSERT INTO table1
        VALUES (43)
)
INSERT INTO table1
    VALUES (44);

WITH wcte AS (
    INSERT INTO table1
        VALUES (45)
)
merge INTO table1
    USING ( VALUES (46)) AS v (a) ON table1.a = v.a
    WHEN NOT matched THEN
        INSERT VALUES (v.a);

SELECT
    *
FROM
    table1;

SELECT
    *
FROM
    table2;

DROP TABLE table1;

DROP TABLE table2;

--
-- Verify behavior of INSERT ... ON CONFLICT DO UPDATE ... with
-- transition tables.
--
CREATE TABLE my_table (
    a int PRIMARY KEY,
    b text
);

CREATE TRIGGER my_table_insert_trig
    AFTER INSERT ON my_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER my_table_update_trig
    AFTER UPDATE ON my_table referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

-- inserts only
INSERT INTO my_table
VALUES
    (1, 'AAA'),
    (2, 'BBB')
ON CONFLICT (a)
    DO UPDATE SET
        b = my_table.b || ':' || excluded.b;

-- mixture of inserts and updates
INSERT INTO my_table
VALUES
    (1, 'AAA'),
    (2, 'BBB'),
    (3, 'CCC'),
    (4, 'DDD')
ON CONFLICT (a)
    DO UPDATE SET
        b = my_table.b || ':' || excluded.b;

-- updates only
INSERT INTO my_table
VALUES
    (3, 'CCC'),
    (4, 'DDD')
ON CONFLICT (a)
    DO UPDATE SET
        b = my_table.b || ':' || excluded.b;

--
-- now using a partitioned table
--
CREATE TABLE iocdu_tt_parted (
    a int PRIMARY KEY,
    b text
)
PARTITION BY LIST (a);

CREATE TABLE iocdu_tt_parted1 PARTITION OF iocdu_tt_parted
FOR VALUES IN (1);

CREATE TABLE iocdu_tt_parted2 PARTITION OF iocdu_tt_parted
FOR VALUES IN (2);

CREATE TABLE iocdu_tt_parted3 PARTITION OF iocdu_tt_parted
FOR VALUES IN (3);

CREATE TABLE iocdu_tt_parted4 PARTITION OF iocdu_tt_parted
FOR VALUES IN (4);

CREATE TRIGGER iocdu_tt_parted_insert_trig
    AFTER INSERT ON iocdu_tt_parted referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER iocdu_tt_parted_update_trig
    AFTER UPDATE ON iocdu_tt_parted referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

-- inserts only
INSERT INTO iocdu_tt_parted
VALUES
    (1, 'AAA'),
    (2, 'BBB')
ON CONFLICT (a)
    DO UPDATE SET
        b = iocdu_tt_parted.b || ':' || excluded.b;

-- mixture of inserts and updates
INSERT INTO iocdu_tt_parted
VALUES
    (1, 'AAA'),
    (2, 'BBB'),
    (3, 'CCC'),
    (4, 'DDD')
ON CONFLICT (a)
    DO UPDATE SET
        b = iocdu_tt_parted.b || ':' || excluded.b;

-- updates only
INSERT INTO iocdu_tt_parted
VALUES
    (3, 'CCC'),
    (4, 'DDD')
ON CONFLICT (a)
    DO UPDATE SET
        b = iocdu_tt_parted.b || ':' || excluded.b;

DROP TABLE iocdu_tt_parted;

--
-- Verify that you can't create a trigger with transition tables for
-- more than one event.
--
CREATE TRIGGER my_table_multievent_trig
    AFTER INSERT OR UPDATE ON my_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

--
-- Verify that you can't create a trigger with transition tables with
-- a column list.
--
CREATE TRIGGER my_table_col_update_trig
    AFTER UPDATE OF b ON my_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

DROP TABLE my_table;

--
-- Verify that transition tables can't be used in, eg, a view.
--
CREATE TABLE my_table (
    a int
);

CREATE FUNCTION make_bogus_matview ()
    RETURNS trigger
    AS $$
BEGIN
    CREATE MATERIALIZED VIEW transition_test_mv AS
    SELECT
        *
    FROM
        new_table;
    RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER make_bogus_matview
    AFTER INSERT ON my_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE FUNCTION make_bogus_matview ();

INSERT INTO my_table
    VALUES (42);

-- error
DROP TABLE my_table;

DROP FUNCTION make_bogus_matview ();

--
-- Test firing of triggers with transition tables by foreign key cascades
--
CREATE TABLE refd_table (
    a int PRIMARY KEY,
    b text
);

CREATE TABLE trig_table (
    a int,
    b text,
    FOREIGN KEY (a) REFERENCES refd_table ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TRIGGER trig_table_before_trig
    BEFORE INSERT OR UPDATE OR DELETE ON trig_table
    FOR EACH statement
    EXECUTE PROCEDURE trigger_func ('trig_table');

CREATE TRIGGER trig_table_insert_trig
    AFTER INSERT ON trig_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER trig_table_update_trig
    AFTER UPDATE ON trig_table referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER trig_table_delete_trig
    AFTER DELETE ON trig_table referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

INSERT INTO refd_table
VALUES
    (1, 'one'),
    (2, 'two'),
    (3, 'three');

INSERT INTO trig_table
VALUES
    (1, 'one a'),
    (1, 'one b'),
    (2, 'two a'),
    (2, 'two b'),
    (3, 'three a'),
    (3, 'three b');

UPDATE
    refd_table
SET
    a = 11
WHERE
    b = 'one';

SELECT
    *
FROM
    trig_table;

DELETE FROM refd_table
WHERE length(b) = 3;

SELECT
    *
FROM
    trig_table;

DROP TABLE refd_table, trig_table;

--
-- Test that we can drop a not-yet-fired deferred trigger
--
CREATE TABLE refd_table (
    id int PRIMARY KEY
);

CREATE TABLE trig_table (
    fk int REFERENCES refd_table INITIALLY DEFERRED
);

BEGIN;
INSERT INTO trig_table
    VALUES (1);
DROP TABLE refd_table CASCADE;
COMMIT;

DROP TABLE trig_table;

--
-- self-referential FKs are even more fun
--
CREATE TABLE self_ref (
    a int PRIMARY KEY,
    b int REFERENCES self_ref (a) ON DELETE CASCADE
);

CREATE TRIGGER self_ref_before_trig
    BEFORE DELETE ON self_ref
    FOR EACH statement
    EXECUTE PROCEDURE trigger_func ('self_ref');

CREATE TRIGGER self_ref_r_trig
    AFTER DELETE ON self_ref referencing old TABLE AS old_table
    FOR EACH ROW
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER self_ref_s_trig
    AFTER DELETE ON self_ref referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

INSERT INTO self_ref
VALUES
    (1, NULL),
    (2, 1),
    (3, 2);

DELETE FROM self_ref
WHERE a = 1;

-- without AR trigger, cascaded deletes all end up in one transition table
DROP TRIGGER self_ref_r_trig ON self_ref;

INSERT INTO self_ref
VALUES
    (1, NULL),
    (2, 1),
    (3, 2),
    (4, 3);

DELETE FROM self_ref
WHERE a = 1;

DROP TABLE self_ref;

--
-- test transition tables with MERGE
--
CREATE TABLE merge_target_table (
    a int PRIMARY KEY,
    b text
);

CREATE TRIGGER merge_target_table_insert_trig
    AFTER INSERT ON merge_target_table referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER merge_target_table_update_trig
    AFTER UPDATE ON merge_target_table referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER merge_target_table_delete_trig
    AFTER DELETE ON merge_target_table referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TABLE merge_source_table (
    a int,
    b text
);

INSERT INTO merge_source_table
VALUES
    (1, 'initial1'),
    (2, 'initial2'),
    (3, 'initial3'),
    (4, 'initial4');

merge INTO merge_target_table t
    USING merge_source_table s ON t.a = s.a
    WHEN NOT matched THEN
        INSERT VALUES (a, b);

merge INTO merge_target_table t
    USING merge_source_table s ON t.a = s.a
    WHEN matched AND s.a <= 2 THEN
        UPDATE SET b = t.b || ' updated by merge'
    WHEN matched AND s.a > 2 THEN
        DELETE
    WHEN NOT matched THEN
        INSERT VALUES (a, b);

merge INTO merge_target_table t
    USING merge_source_table s ON t.a = s.a
    WHEN matched AND s.a <= 2 THEN
        UPDATE SET b = t.b || ' updated again by merge'
    WHEN matched AND s.a > 2 THEN
        DELETE
    WHEN NOT matched THEN
        INSERT VALUES (a, b);

DROP TABLE merge_source_table, merge_target_table;

-- cleanup
DROP FUNCTION dump_insert ();

DROP FUNCTION dump_update ();

DROP FUNCTION dump_delete ();

--
-- Tests for CREATE OR REPLACE TRIGGER
--
CREATE TABLE my_table (
    id integer
);

CREATE FUNCTION funcA ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'hello from funcA';
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION funcB ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE NOTICE 'hello from funcB';
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER my_trig
    AFTER INSERT ON my_table
    FOR EACH ROW
    EXECUTE PROCEDURE funcA ();

CREATE TRIGGER my_trig
    BEFORE INSERT ON my_table
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

-- should fail
INSERT INTO my_table
    VALUES (1);

CREATE OR REPLACE TRIGGER my_trig
    BEFORE INSERT ON my_table
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

-- OK
INSERT INTO my_table
    VALUES (2);

-- this insert should become a no-op
TABLE my_table;

DROP TABLE my_table;

-- test CREATE OR REPLACE TRIGGER on partition table
CREATE TABLE parted_trig (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE parted_trig_1 PARTITION OF parted_trig
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE parted_trig_1_1 PARTITION OF parted_trig_1
FOR VALUES FROM (0) TO (100);

CREATE TABLE parted_trig_2 PARTITION OF parted_trig
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE default_parted_trig PARTITION OF parted_trig DEFAULT;

-- test that trigger can be replaced by another one
-- at the same level of partition table
CREATE OR REPLACE TRIGGER my_trig
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE funcA ();

INSERT INTO parted_trig (a)
    VALUES (50);

CREATE OR REPLACE TRIGGER my_trig
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

INSERT INTO parted_trig (a)
    VALUES (50);

-- test that child trigger cannot be replaced directly
CREATE OR REPLACE TRIGGER my_trig
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE funcA ();

INSERT INTO parted_trig (a)
    VALUES (50);

CREATE OR REPLACE TRIGGER my_trig
    AFTER INSERT ON parted_trig_1
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

-- should fail
INSERT INTO parted_trig (a)
    VALUES (50);

DROP TRIGGER my_trig ON parted_trig;

INSERT INTO parted_trig (a)
    VALUES (50);

-- test that user trigger can be overwritten by one defined at upper level
CREATE TRIGGER my_trig
    AFTER INSERT ON parted_trig_1
    FOR EACH ROW
    EXECUTE PROCEDURE funcA ();

INSERT INTO parted_trig (a)
    VALUES (50);

CREATE TRIGGER my_trig
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

-- should fail
INSERT INTO parted_trig (a)
    VALUES (50);

CREATE OR REPLACE TRIGGER my_trig
    AFTER INSERT ON parted_trig
    FOR EACH ROW
    EXECUTE PROCEDURE funcB ();

INSERT INTO parted_trig (a)
    VALUES (50);

-- cleanup
DROP TABLE parted_trig;

DROP FUNCTION funcA ();

DROP FUNCTION funcB ();

-- Leave around some objects for other tests
CREATE TABLE trigger_parted (
    a int PRIMARY KEY
)
PARTITION BY LIST (a);

CREATE FUNCTION trigger_parted_trigfunc ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
END;
$$;

CREATE TRIGGER aft_row
    AFTER INSERT OR UPDATE ON trigger_parted
    FOR EACH ROW
    EXECUTE FUNCTION trigger_parted_trigfunc ();

CREATE TABLE trigger_parted_p1 PARTITION OF trigger_parted
FOR VALUES IN (1)
PARTITION BY LIST (a);

CREATE TABLE trigger_parted_p1_1 PARTITION OF trigger_parted_p1
FOR VALUES IN (1);

CREATE TABLE trigger_parted_p2 PARTITION OF trigger_parted
FOR VALUES IN (2)
PARTITION BY LIST (a);

CREATE TABLE trigger_parted_p2_2 PARTITION OF trigger_parted_p2
FOR VALUES IN (2);

ALTER TABLE ONLY trigger_parted_p2 DISABLE TRIGGER aft_row;

ALTER TABLE trigger_parted_p2_2 ENABLE ALWAYS TRIGGER aft_row;

-- verify transition table conversion slot's lifetime
-- https://postgr.es/m/39a71864-b120-5a5c-8cc5-c632b6f16761@amazon.com
CREATE TABLE convslot_test_parent (
    col1 text PRIMARY KEY
);

CREATE TABLE convslot_test_child (
    col1 text PRIMARY KEY,
    FOREIGN KEY (col1) REFERENCES convslot_test_parent (col1) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE convslot_test_child
    ADD COLUMN col2 text NOT NULL DEFAULT 'tutu';

INSERT INTO convslot_test_parent (col1)
    VALUES ('1');

INSERT INTO convslot_test_child (col1)
    VALUES ('1');

INSERT INTO convslot_test_parent (col1)
    VALUES ('3');

INSERT INTO convslot_test_child (col1)
    VALUES ('3');

CREATE FUNCTION convslot_trig1 ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, old_table = %', TG_NAME, (
        SELECT
            string_agg(old_table::text, ', ' ORDER BY col1)
        FROM
            old_table);
    RETURN NULL;
END;
$$;

CREATE FUNCTION convslot_trig2 ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, new table = %', TG_NAME, (
        SELECT
            string_agg(new_table::text, ', ' ORDER BY col1)
        FROM
            new_table);
    RETURN NULL;
END;
$$;

CREATE TRIGGER but_trigger
    AFTER UPDATE ON convslot_test_child referencing new TABLE AS new_table
    FOR EACH statement
    EXECUTE FUNCTION convslot_trig2 ();

UPDATE
    convslot_test_parent
SET
    col1 = col1 || '1';

CREATE FUNCTION convslot_trig3 ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'trigger = %, old_table = %, new table = %', TG_NAME, (
        SELECT
            string_agg(old_table::text, ', ' ORDER BY col1)
        FROM
            old_table),
    (
        SELECT
            string_agg(new_table::text, ', ' ORDER BY col1)
        FROM
            new_table);
    RETURN NULL;
END;
$$;

CREATE TRIGGER but_trigger2
    AFTER UPDATE ON convslot_test_child referencing old TABLE AS old_table new TABLE AS new_table
    FOR EACH statement
    EXECUTE FUNCTION convslot_trig3 ();

UPDATE
    convslot_test_parent
SET
    col1 = col1 || '1';

CREATE TRIGGER bdt_trigger
    AFTER DELETE ON convslot_test_child referencing old TABLE AS old_table
    FOR EACH statement
    EXECUTE FUNCTION convslot_trig1 ();

DELETE FROM convslot_test_parent;

DROP TABLE convslot_test_child, convslot_test_parent;

DROP FUNCTION convslot_trig1 ();

DROP FUNCTION convslot_trig2 ();

DROP FUNCTION convslot_trig3 ();

-- Bug #17607: variant of above in which trigger function raises an error;
-- we don't see any ill effects unless trigger tuple requires mapping
CREATE TABLE convslot_test_parent (
    id int PRIMARY KEY,
    val int
)
PARTITION BY RANGE (id);

CREATE TABLE convslot_test_part (
    val int,
    id int NOT NULL
);

ALTER TABLE convslot_test_parent ATTACH PARTITION convslot_test_part
FOR VALUES FROM (1) TO (1000);

CREATE FUNCTION convslot_trig4 ()
    RETURNS trigger
    AS $$
BEGIN
    RAISE EXCEPTION 'BOOM!';
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER convslot_test_parent_update
    AFTER UPDATE ON convslot_test_parent referencing old TABLE AS old_rows new TABLE AS new_rows
    FOR EACH statement
    EXECUTE PROCEDURE convslot_trig4 ();

INSERT INTO convslot_test_parent (id, val)
    VALUES (1, 2);

BEGIN;
SAVEPOINT svp;
UPDATE
    convslot_test_parent
SET
    val = 3;
-- error expected
ROLLBACK TO SAVEPOINT svp;

ROLLBACK;

DROP TABLE convslot_test_parent;

DROP FUNCTION convslot_trig4 ();

-- Test trigger renaming on partitioned tables
CREATE TABLE grandparent (
    id int,
    PRIMARY KEY (id)
)
PARTITION BY RANGE (id);

CREATE TABLE middle PARTITION OF grandparent
FOR VALUES FROM (1) TO (10)
PARTITION BY RANGE (id);

CREATE TABLE chi PARTITION OF middle
FOR VALUES FROM (1) TO (5);

CREATE TABLE cho PARTITION OF middle
FOR VALUES FROM (6) TO (10);

CREATE FUNCTION f ()
    RETURNS trigger
    AS $$
BEGIN
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER a
    AFTER INSERT ON grandparent
    FOR EACH ROW
    EXECUTE PROCEDURE f ();

ALTER TRIGGER a ON grandparent RENAME TO b;

SELECT
    tgrelid::regclass,
    tgname,
    (
        SELECT
            tgname
        FROM
            pg_trigger tr
        WHERE
            tr.oid = pg_trigger.tgparentid) parent_tgname
FROM
    pg_trigger
WHERE
    tgrelid IN (
        SELECT
            relid
        FROM
            pg_partition_tree ('grandparent'))
ORDER BY
    tgname,
    tgrelid::regclass::text COLLATE "C";

ALTER TRIGGER a ON ONLY grandparent RENAME TO b;

-- ONLY not supported
ALTER TRIGGER b ON middle RENAME TO c;

-- can't rename trigger on partition
CREATE TRIGGER c
    AFTER INSERT ON middle
    FOR EACH ROW
    EXECUTE PROCEDURE f ();

ALTER TRIGGER b ON grandparent RENAME TO c;

-- Rename cascading does not affect statement triggers
CREATE TRIGGER p
    AFTER INSERT ON grandparent
    FOR EACH statement
    EXECUTE FUNCTION f ();

CREATE TRIGGER p
    AFTER INSERT ON middle
    FOR EACH statement
    EXECUTE FUNCTION f ();

ALTER TRIGGER p ON grandparent RENAME TO q;

SELECT
    tgrelid::regclass,
    tgname,
    (
        SELECT
            tgname
        FROM
            pg_trigger tr
        WHERE
            tr.oid = pg_trigger.tgparentid) parent_tgname
FROM
    pg_trigger
WHERE
    tgrelid IN (
        SELECT
            relid
        FROM
            pg_partition_tree ('grandparent'))
ORDER BY
    tgname,
    tgrelid::regclass::text COLLATE "C";

DROP TABLE grandparent;

-- Trigger renaming does not recurse on legacy inheritance
CREATE TABLE parent (
    a int
);

CREATE TABLE child ()
INHERITS (
    parent
);

CREATE TRIGGER parenttrig
    AFTER INSERT ON parent
    FOR EACH ROW
    EXECUTE PROCEDURE f ();

CREATE TRIGGER parenttrig
    AFTER INSERT ON child
    FOR EACH ROW
    EXECUTE PROCEDURE f ();

ALTER TRIGGER parenttrig ON parent RENAME TO anothertrig;

\d+ child
DROP TABLE parent, child;

DROP FUNCTION f ();

-- Test who runs deferred trigger functions
-- setup
CREATE ROLE regress_caller;

CREATE ROLE regress_fn_owner;

CREATE FUNCTION whoami ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'I am %', CURRENT_USER;
    RETURN NULL;
END;
$$;

ALTER FUNCTION whoami () OWNER TO regress_fn_owner;

CREATE TABLE defer_trig (
    id integer
);

GRANT INSERT ON defer_trig TO public;

CREATE CONSTRAINT TRIGGER whoami
    AFTER INSERT ON defer_trig DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION whoami ();

-- deferred triggers must run as the user that queued the trigger
BEGIN;
SET ROLE regress_caller;
INSERT INTO defer_trig
    VALUES (1);
RESET ROLE;
SET ROLE regress_fn_owner;
INSERT INTO defer_trig
    VALUES (2);
RESET ROLE;
COMMIT;

-- security definer functions override the user who queued the trigger
ALTER FUNCTION whoami () SECURITY DEFINER;

BEGIN;
SET ROLE regress_caller;
INSERT INTO defer_trig
    VALUES (3);
RESET ROLE;
COMMIT;

ALTER FUNCTION whoami () SECURITY INVOKER;

-- make sure the current user is restored after error
CREATE OR REPLACE FUNCTION whoami ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'I am %', CURRENT_USER;
    PERFORM
        1 / 0;
    RETURN NULL;
END;
$$;

BEGIN;
SET ROLE regress_caller;
INSERT INTO defer_trig
    VALUES (4);
RESET ROLE;
COMMIT;

-- error expected
SELECT
    CURRENT_USER = SESSION_USER;

-- clean up
DROP TABLE defer_trig;

DROP FUNCTION whoami ();

DROP ROLE regress_fn_owner;

DROP ROLE regress_caller;

