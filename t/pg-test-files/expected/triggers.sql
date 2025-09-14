--
-- TRIGGERS
--
CREATE TABLE pkeys (
    pkey1 int4 NOT NULL,
    pkey2 text NOT NULL
);

CREATE TABLE fkeys (
    fkey1 int4,
    fkey2 text,
    fkey3 int
);

CREATE TABLE fkeys2 (
    fkey21 int4,
    fkey22 text,
    pkey23 int NOT NULL
);

CREATE INDEX fkeys_i ON fkeys (fkey1, fkey2);

CREATE INDEX fkeys2_i ON fkeys2 (fkey21, fkey22);

CREATE INDEX fkeys2p_i ON fkeys2 (pkey23);

INSERT INTO pkeys
    VALUES (10, '1');

INSERT INTO pkeys
    VALUES (20, '2');

INSERT INTO pkeys
    VALUES (30, '3');

INSERT INTO pkeys
    VALUES (40, '4');

INSERT INTO pkeys
    VALUES (50, '5');

INSERT INTO pkeys
    VALUES (60, '6');

CREATE UNIQUE INDEX pkeys_i ON pkeys (pkey1, pkey2);

--
-- For fkeys:
-- 	(fkey1, fkey2)	--> pkeys (pkey1, pkey2)
-- 	(fkey3)		--> fkeys2 (pkey23)
--
CREATE TRIGGER check_fkeys_pkey_exist
    BEFORE INSERT OR UPDATE ON fkeys FOR EACH ROW
    EXECUTE FUNCTION check_primary_key ('fkey1', 'fkey2', 'pkeys', 'pkey1', 'pkey2');

CREATE TRIGGER check_fkeys_pkey2_exist
    BEFORE INSERT OR UPDATE ON fkeys FOR EACH ROW
    EXECUTE FUNCTION check_primary_key ('fkey3', 'fkeys2', 'pkey23');

--
-- For fkeys2:
-- 	(fkey21, fkey22)	--> pkeys (pkey1, pkey2)
--
CREATE TRIGGER check_fkeys2_pkey_exist
    BEFORE INSERT OR UPDATE ON fkeys2 FOR EACH ROW
    EXECUTE PROCEDURE check_primary_key ('fkey21', 'fkey22', 'pkeys', 'pkey1', 'pkey2');

-- Test comments
COMMENT ON TRIGGER check_fkeys2_pkey_bad ON fkeys2 IS 'wrong';

COMMENT ON TRIGGER check_fkeys2_pkey_exist ON fkeys2 IS 'right';

COMMENT ON TRIGGER check_fkeys2_pkey_exist ON fkeys2 IS NULL;

--
-- For pkeys:
-- 	ON DELETE/UPDATE (pkey1, pkey2) CASCADE:
-- 		fkeys (fkey1, fkey2) and fkeys2 (fkey21, fkey22)
--
CREATE TRIGGER check_pkeys_fkey_cascade
    BEFORE DELETE OR UPDATE ON pkeys FOR EACH ROW
    EXECUTE PROCEDURE check_foreign_key (2, 'cascade', 'pkey1', 'pkey2', 'fkeys', 'fkey1', 'fkey2', 'fkeys2', 'fkey21', 'fkey22');

--
-- For fkeys2:
-- 	ON DELETE/UPDATE (pkey23) RESTRICT:
-- 		fkeys (fkey3)
--
CREATE TRIGGER check_fkeys2_fkey_restrict
    BEFORE DELETE OR UPDATE ON fkeys2 FOR EACH ROW
    EXECUTE PROCEDURE check_foreign_key (1, 'restrict', 'pkey23', 'fkeys', 'fkey3');

INSERT INTO fkeys2
    VALUES (10, '1', 1);

INSERT INTO fkeys2
    VALUES (30, '3', 2);

INSERT INTO fkeys2
    VALUES (40, '4', 5);

INSERT INTO fkeys2
    VALUES (50, '5', 3);

-- no key in pkeys
INSERT INTO fkeys2
    VALUES (70, '5', 3);

INSERT INTO fkeys
    VALUES (10, '1', 2);

INSERT INTO fkeys
    VALUES (30, '3', 3);

INSERT INTO fkeys
    VALUES (40, '4', 2);

INSERT INTO fkeys
    VALUES (50, '5', 2);

-- no key in pkeys
INSERT INTO fkeys
    VALUES (70, '5', 1);

-- no key in fkeys2
INSERT INTO fkeys
    VALUES (60, '6', 4);

DELETE FROM pkeys
WHERE pkey1 = 30
    AND pkey2 = '3';

DELETE FROM pkeys
WHERE pkey1 = 40
    AND pkey2 = '4';

UPDATE
    pkeys
SET
    pkey1 = 7,
    pkey2 = '70'
WHERE
    pkey1 = 50
    AND pkey2 = '5';

UPDATE
    pkeys
SET
    pkey1 = 7,
    pkey2 = '70'
WHERE
    pkey1 = 10
    AND pkey2 = '1';

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
    event_object_table IN ('pkeys', 'fkeys', 'fkeys2')
ORDER BY
    trigger_name COLLATE "C",
    2;

DROP TABLE pkeys;

DROP TABLE fkeys;

DROP TABLE fkeys2;

-- Check behavior when trigger returns unmodified trigtuple
CREATE TABLE trigtest (
    f1 int,
    f2 text
);

CREATE TRIGGER trigger_return_old
    BEFORE INSERT OR DELETE OR UPDATE ON trigtest FOR EACH ROW
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

DROP TABLE trigtest;

CREATE SEQUENCE ttdummy_seq
    INCREMENT 10 START 0
    MINVALUE 0;

CREATE TABLE tttest (
    price_id int4,
    price_val int4,
    price_on int4,
    price_off int4 DEFAULT 999999
);

CREATE TRIGGER ttdummy
    BEFORE DELETE OR UPDATE ON tttest FOR EACH ROW
    EXECUTE PROCEDURE ttdummy (price_on, price_off);

CREATE TRIGGER ttserial
    BEFORE INSERT OR UPDATE ON tttest FOR EACH ROW
    EXECUTE PROCEDURE autoinc (price_on, ttdummy_seq);

INSERT INTO tttest
    VALUES (1, 1, NULL);

INSERT INTO tttest
    VALUES (2, 2, NULL);

INSERT INTO tttest
    VALUES (3, 3, 0);

SELECT
    *
FROM
    tttest;

DELETE FROM tttest
WHERE price_id = 2;

SELECT
    *
FROM
    tttest;

-- what do we see ?
-- get current prices
SELECT
    *
FROM
    tttest
WHERE
    price_off = 999999;

-- change price for price_id == 3
UPDATE
    tttest
SET
    price_val = 30
WHERE
    price_id = 3;

SELECT
    *
FROM
    tttest;

-- now we want to change pric_id in ALL tuples
-- this gets us not what we need
UPDATE
    tttest
SET
    price_id = 5
WHERE
    price_id = 3;

SELECT
    *
FROM
    tttest;

-- restore data as before last update:
SELECT
    set_ttdummy (0);

DELETE FROM tttest
WHERE price_id = 5;

UPDATE
    tttest
SET
    price_off = 999999
WHERE
    price_val = 30;

SELECT
    *
FROM
    tttest;

-- and try change price_id now!
UPDATE
    tttest
SET
    price_id = 5
WHERE
    price_id = 3;

SELECT
    *
FROM
    tttest;

-- isn't it what we need ?
SELECT
    set_ttdummy (1);

-- we want to correct some "date"
UPDATE
    tttest
SET
    price_on = -1
WHERE
    price_id = 1;

-- but this doesn't work
-- try in this way
SELECT
    set_ttdummy (0);

UPDATE
    tttest
SET
    price_on = -1
WHERE
    price_id = 1;

SELECT
    *
FROM
    tttest;

-- isn't it what we need ?
-- get price for price_id == 5 as it was @ "date" 35
SELECT
    *
FROM
    tttest
WHERE
    price_on <= 35
    AND price_off > 35
    AND price_id = 5;

DROP TABLE tttest;

DROP SEQUENCE ttdummy_seq;

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

CREATE FUNCTION trigger_func ()
    RETURNS TRIGGER
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

SELECT
    *
FROM
    main_table
ORDER BY
    a,
    b;

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
    AFTER UPDATE ON table_with_oids FOR EACH ROW
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
    AS $$
BEGIN
    RAISE NOTICE '% % % %', TG_TABLE_NAME, TG_OP, TG_WHEN, TG_LEVEL;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigtest_b_row_tg
    BEFORE INSERT OR UPDATE OR DELETE ON trigtest FOR EACH ROW
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_a_row_tg
    AFTER INSERT OR UPDATE OR DELETE ON trigtest FOR EACH ROW
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_b_stmt_tg
    BEFORE INSERT OR UPDATE OR DELETE ON trigtest FOR EACH statement
    EXECUTE PROCEDURE trigtest ();

CREATE TRIGGER trigtest_a_stmt_tg
    AFTER INSERT OR UPDATE OR DELETE ON trigtest FOR EACH statement
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    ctry_id int;
BEGIN
    IF NEW.country_name IS NOT NULL THEN
        SELECT
            country_id,
            continent INTO ctry_id,
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
            city_id INTO NEW.city_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER city_insert_trig
    INSTEAD OF INSERT ON city_view
    FOR EACH ROW
    EXECUTE PROCEDURE city_insert ();

CREATE FUNCTION city_delete ()
    RETURNS TRIGGER
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
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    ctry_id int;
BEGIN
    IF NEW.country_name IS DISTINCT FROM OLD.country_name THEN
        SELECT
            country_id,
            continent INTO ctry_id,
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    BEFORE INSERT ON depth_a FOR EACH ROW
    EXECUTE PROCEDURE depth_a_tf ();

CREATE FUNCTION depth_b_tf ()
    RETURNS TRIGGER
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
    BEFORE INSERT ON depth_b FOR EACH ROW
    EXECUTE PROCEDURE depth_b_tf ();

CREATE FUNCTION depth_c_tf ()
    RETURNS TRIGGER
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
    BEFORE INSERT ON depth_c FOR EACH ROW
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
    RETURNS TRIGGER
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
    BEFORE UPDATE ON parent FOR EACH ROW
    EXECUTE PROCEDURE parent_upd_func ();

CREATE FUNCTION parent_del_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM child
    WHERE aid = OLD.aid;
    RETURN old;
END;
$$;

CREATE TRIGGER parent_del_trig
    BEFORE DELETE ON parent FOR EACH ROW
    EXECUTE PROCEDURE parent_del_func ();

CREATE FUNCTION child_ins_func ()
    RETURNS TRIGGER
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
    AFTER INSERT ON child FOR EACH ROW
    EXECUTE PROCEDURE child_ins_func ();

CREATE FUNCTION child_del_func ()
    RETURNS TRIGGER
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
    AFTER DELETE ON child FOR EACH ROW
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    BEFORE INSERT ON self_ref_trigger FOR EACH ROW
    EXECUTE PROCEDURE self_ref_trigger_ins_func ();

CREATE FUNCTION self_ref_trigger_del_func ()
    RETURNS TRIGGER
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
    BEFORE DELETE ON self_ref_trigger FOR EACH ROW
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
    AS $$
BEGIN
    ALTER TABLE trigger_ddl_table
        ADD PRIMARY KEY (col1);
    RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_ddl_func
    BEFORE INSERT ON trigger_ddl_table FOR EACH ROW
    EXECUTE PROCEDURE trigger_ddl_func ();

INSERT INTO trigger_ddl_table
    VALUES (1, 42);

-- fail
CREATE OR REPLACE FUNCTION trigger_ddl_func ()
    RETURNS TRIGGER
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
-- DO UPDATE
--
CREATE TABLE upsert (
    key int4 PRIMARY KEY,
    color text
);

CREATE FUNCTION upsert_before_func ()
    RETURNS TRIGGER
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
    BEFORE INSERT OR UPDATE ON upsert FOR EACH ROW
    EXECUTE PROCEDURE upsert_before_func ();

CREATE FUNCTION upsert_after_func ()
    RETURNS TRIGGER
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
    AFTER INSERT OR UPDATE ON upsert FOR EACH ROW
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
    RETURNS TRIGGER
    AS $$
BEGIN
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER my_trigger
    AFTER UPDATE ON my_view referencing old TABLE AS old_table FOR EACH statement
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
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
END;
$$;

CREATE TRIGGER failed
    BEFORE INSERT OR UPDATE OR DELETE ON parted_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

CREATE TRIGGER failed
    INSTEAD OF UPDATE ON parted_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

CREATE TRIGGER failed
    AFTER UPDATE ON parted_trig referencing old TABLE AS old_table FOR EACH ROW
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
    AFTER INSERT ON trigpart FOR EACH ROW
    EXECUTE PROCEDURE trigger_nothing ();

CREATE TABLE trigpart2 PARTITION OF trigpart
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE trigpart3 (
    LIKE trigpart
);

ALTER TABLE trigpart ATTACH PARTITION trigpart3
FOR VALUES FROM (2000) TO (3000);

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
    RETURNS TRIGGER
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
    BEFORE INSERT ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after
    AFTER INSERT ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before
    BEFORE UPDATE ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after
    AFTER UPDATE ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before
    BEFORE DELETE ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after
    AFTER DELETE ON parted_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete row-level triggers on the parent
CREATE TRIGGER trig_ins_after_parent
    AFTER INSERT ON parted_stmt_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_parent
    AFTER UPDATE ON parted_stmt_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_parent
    AFTER DELETE ON parted_stmt_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete row-level triggers on the first partition
CREATE TRIGGER trig_ins_before_child
    BEFORE INSERT ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after_child
    AFTER INSERT ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before_child
    BEFORE UPDATE ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_child
    AFTER UPDATE ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before_child
    BEFORE DELETE ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_child
    AFTER DELETE ON parted_stmt_trig1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

-- insert/update/delete statement-level triggers on the parent
CREATE TRIGGER trig_ins_before_3
    BEFORE INSERT ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_ins_after_3
    AFTER INSERT ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_before_3
    BEFORE UPDATE ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_upd_after_3
    AFTER UPDATE ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_before_3
    BEFORE DELETE ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER trig_del_after_3
    AFTER DELETE ON parted2_stmt_trig FOR EACH statement
    EXECUTE PROCEDURE trigger_notice ();

WITH ins (
    a
) AS (
INSERT INTO parted2_stmt_trig
    VALUES
        (1),
        (2)
    RETURNING
        a)
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
        a = a)
UPDATE
    parted_stmt_trig
SET
    a = a;

DELETE FROM parted_stmt_trig;

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
    AFTER INSERT ON parted_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER mmm
    AFTER INSERT ON parted_trig_1_1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER aaa
    AFTER INSERT ON parted_trig_1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER bbb
    AFTER INSERT ON parted_trig FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

CREATE TRIGGER qqq
    AFTER INSERT ON parted_trig_1_1 FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice ();

INSERT INTO parted_trig
VALUES
    (50),
    (1500);

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
    RETURNS TRIGGER
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
    AFTER INSERT ON parted_irreg FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE TRIGGER parted_trig_odd
    AFTER INSERT ON parted_irreg FOR EACH ROW
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
    AFTER INSERT ON parted_constr_ancestor DEFERRABLE FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE CONSTRAINT TRIGGER parted_trig_two
    AFTER INSERT ON parted_constr DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
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
    AFTER UPDATE ON parted_trigger FOR EACH ROW
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
    parted_referenced FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE CONSTRAINT TRIGGER parted_trigger
    AFTER UPDATE ON unparted_trigger
FROM
    parted_referenced FOR EACH ROW
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
    AFTER UPDATE OF b ON parted_trigger FOR EACH ROW
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

--
-- Test the interaction between transition tables and both kinds of
-- inheritance.  We'll dump the contents of the transition tables in a
-- format that shows the attribute order, so that we can distinguish
-- tuple formats (though not dropped attributes).
--
CREATE OR REPLACE FUNCTION dump_insert ()
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    RETURNS TRIGGER
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
    AFTER INSERT ON parent referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER parent_update_trig
    AFTER UPDATE ON parent referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER parent_delete_trig
    AFTER DELETE ON parent referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child1_insert_trig
    AFTER INSERT ON child1 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child1_update_trig
    AFTER UPDATE ON child1 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child1_delete_trig
    AFTER DELETE ON child1 referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child2_insert_trig
    AFTER INSERT ON child2 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child2_update_trig
    AFTER UPDATE ON child2 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child2_delete_trig
    AFTER DELETE ON child2 referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child3_insert_trig
    AFTER INSERT ON child3 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child3_update_trig
    AFTER UPDATE ON child3 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child3_delete_trig
    AFTER DELETE ON child3 referencing old TABLE AS old_table FOR EACH statement
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

-- insert into parent with a before trigger on a child tuple before
-- insertion, and we capture the newly modified row in parent format
CREATE OR REPLACE FUNCTION intercept_insert ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.b = NEW.b + 1000;
    RETURN new;
END;
$$;

CREATE TRIGGER intercept_insert_child3
    BEFORE INSERT ON child3 FOR EACH ROW
    EXECUTE PROCEDURE intercept_insert ();

-- insert, parent trigger sees post-modification parent-format tuple
INSERT INTO parent
VALUES
    ('AAA', 42),
    ('BBB', 42),
    ('CCC', 66);

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
    AFTER INSERT ON child referencing new TABLE AS new_table FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- detaching it first works
ALTER TABLE parent DETACH PARTITION child;

CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table FOR EACH ROW
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
    AFTER INSERT ON parent referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER parent_update_trig
    AFTER UPDATE ON parent referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER parent_delete_trig
    AFTER DELETE ON parent referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child1_insert_trig
    AFTER INSERT ON child1 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child1_update_trig
    AFTER UPDATE ON child1 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child1_delete_trig
    AFTER DELETE ON child1 referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child2_insert_trig
    AFTER INSERT ON child2 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child2_update_trig
    AFTER UPDATE ON child2 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child2_delete_trig
    AFTER DELETE ON child2 referencing old TABLE AS old_table FOR EACH statement
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER child3_insert_trig
    AFTER INSERT ON child3 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER child3_update_trig
    AFTER UPDATE ON child3 referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER child3_delete_trig
    AFTER DELETE ON child3 referencing old TABLE AS old_table FOR EACH statement
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

-- same behavior for copy if there is an index (interesting because rows are
-- captured by a different code path in copy.c if there are indexes)
CREATE INDEX ON parent (b);

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
    AFTER INSERT ON child referencing new TABLE AS new_table FOR EACH ROW
    EXECUTE PROCEDURE dump_insert ();

-- disinheriting it first works
ALTER TABLE child NO inherit parent;

CREATE TRIGGER child_row_trig
    AFTER INSERT ON child referencing new TABLE AS new_table FOR EACH ROW
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
    AFTER INSERT ON table1 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER table2_trig
    AFTER INSERT ON table2 referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

WITH wcte AS (
INSERT INTO table1
        VALUES (42))
    INSERT INTO table2
        VALUES ('hello world');

WITH wcte AS (
INSERT INTO table1
        VALUES (43))
    INSERT INTO table1
        VALUES (44);

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
    AFTER INSERT ON my_table referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER my_table_update_trig
    AFTER UPDATE ON my_table referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
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
    AFTER INSERT ON iocdu_tt_parted referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER iocdu_tt_parted_update_trig
    AFTER UPDATE ON iocdu_tt_parted referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
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
    AFTER INSERT OR UPDATE ON my_table referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

--
-- Verify that you can't create a trigger with transition tables with
-- a column list.
--
CREATE TRIGGER my_table_col_update_trig
    AFTER UPDATE OF b ON my_table referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

DROP TABLE my_table;

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
    BEFORE INSERT OR UPDATE OR DELETE ON trig_table FOR EACH statement
    EXECUTE PROCEDURE trigger_func ('trig_table');

CREATE TRIGGER trig_table_insert_trig
    AFTER INSERT ON trig_table referencing new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_insert ();

CREATE TRIGGER trig_table_update_trig
    AFTER UPDATE ON trig_table referencing old TABLE AS old_table new TABLE AS new_table FOR EACH statement
    EXECUTE PROCEDURE dump_update ();

CREATE TRIGGER trig_table_delete_trig
    AFTER DELETE ON trig_table referencing old TABLE AS old_table FOR EACH statement
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
-- self-referential FKs are even more fun
--
CREATE TABLE self_ref (
    a int PRIMARY KEY,
    b int REFERENCES self_ref (a) ON DELETE CASCADE
);

CREATE TRIGGER self_ref_before_trig
    BEFORE DELETE ON self_ref FOR EACH statement
    EXECUTE PROCEDURE trigger_func ('self_ref');

CREATE TRIGGER self_ref_r_trig
    AFTER DELETE ON self_ref referencing old TABLE AS old_table FOR EACH ROW
    EXECUTE PROCEDURE dump_delete ();

CREATE TRIGGER self_ref_s_trig
    AFTER DELETE ON self_ref referencing old TABLE AS old_table FOR EACH statement
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

-- cleanup
DROP FUNCTION dump_insert ();

DROP FUNCTION dump_update ();

DROP FUNCTION dump_delete ();

