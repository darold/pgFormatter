DROP OPERATOR === ();

CREATE TYPE jwt_token AS (
    token text,
    field: text
);

CREATE TABLE IF NOT EXISTS relationships (
    id serial PRIMARY KEY,
    users_id integer NOT NULL REFERENCES users (id),
    students_id integer NOT NULL REFERENCES students (id),
    communication boolean NOT NULL
);

CREATE TABLE nulltest (
    col1 dnotnull,
    col2 dnotnull NULL, -- NOT NULL in the domain cannot be overridden
    col3 dnull NOT NULL,
    col4 dnull,
    col5 dcheck CHECK (col5 IN ('c', 'd'))
);

CREATE TABLE new_table_test (
    start_date timestamp NOT NULL,
    end_date timestamp NOT NULL,
    name varchar(40) NOT NULL CHECK (name <> ''),
    fk_organization_unit_id numeric(20),
    fk_product_id numeric(20),
    id numeric(20) NOT NULL PRIMARY KEY,
    migrated varchar(1)
);

SELECT
    Date_trunc('day', last_updated_on),
    Count(*)
FROM
    exports.a
GROUP BY
    Date_trunc('day', last_updated_on)
ORDER BY
    Date_trunc('day', last_updated_on),
    toto DESC;

CREATE FUNCTION customcontsel (internal, oid, internal, integer)
    RETURNS float8
    AS 'contsel'
    LANGUAGE internal
    STABLE STRICT;

CREATE FUNCTION ADD (integer, integer)
    RETURNS integer
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $_$
    SELECT
        $1 + $2;
$_$;

DO $$
BEGIN
    INSERT INTO table01 (id, user_id, group_id)
    SELECT
        nextval('foobar'),
        ug.user_id,
        14
    FROM
        table01 ug
    WHERE
        ug.group_id = 13
        AND NOT EXISTS (
            SELECT
                *
            FROM
                table01 ug2
            WHERE
                ug2 = ug.user_id
                AND ug2.group_id = 14);
END;
$$;

WITH ins (
    a,
    b,
    c
) AS (
INSERT INTO mlparted (b, a)
    SELECT
        s.a,
        1
    FROM
        generate_series(2, 39) s (a)
    RETURNING
        tableoid::regclass,
        *
)
SELECT
    a,
    b,
    min(c),
    max(c)
FROM
    ins
GROUP BY
    a,
    b
ORDER BY
    1;

CREATE OR REPLACE FUNCTION chkrolattr ()
    RETURNS TABLE (
        "role" name,
        rolekeyword text,
        canlogin bool,
        replication bool
    )
    AS $$
    SELECT
        r.rolname,
        v.keyword,
        r.rolcanlogin,
        r.rolreplication
    FROM
        pg_roles r
        JOIN (
            VALUES (CURRENT_USER, 'current_user'),
                (SESSION_USER, 'session_user'),
                ('current_user', '-'),
                ('session_user', '-'),
                ('Public', '-'),
                ('None', '-')) AS v (uname, keyword) ON (r.rolname = v.uname)
    ORDER BY
        1;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION hash_join_batches (query text)
    RETURNS TABLE (
        original int,
        final int)
    LANGUAGE plpgsql
    AS $$
DECLARE
    whole_plan json;
    hash_node json;
BEGIN
    FOR whole_plan IN EXECUTE 'explain (analyze, format ''json'') ' || query LOOP
        hash_node := find_hash (json_extract_path(whole_plan, '0', 'Plan'));
        original := hash_node ->> 'Original Hash Batches';
        final := hash_node ->> 'Hash Batches';
        RETURN NEXT;
    END LOOP;
END;
$$;

CREATE TABLE nv_child_2009 (
    CHECK (d BETWEEN '2009-01-01'::date AND '2009-12-31'::date)
)
INHERITS (
    nv_parent
);

CREATE TABLE part1 (
    a int NOT NULL CHECK (a = 1),
    b int NOT NULL CHECK (b >= 1 AND b <= 10)
);

CREATE TRIGGER parted_trig
    AFTER INSERT ON parted_irreg FOR EACH ROW
    EXECUTE PROCEDURE trigger_notice_ab ();

CREATE CONSTRAINT TRIGGER parted_trig_two
    AFTER INSERT ON parted_constr DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
    WHEN (bark (new.b) AND new.a % 2 = 1)
    EXECUTE PROCEDURE trigger_notice_ab ();

BEGIN;
CREATE TRIGGER ttdummy
    BEFORE DELETE OR UPDATE ON alterlock FOR EACH ROW
    EXECUTE PROCEDURE ttdummy (1, 1);
SELECT
    *
FROM
    my_locks
ORDER BY
    1;
ROLLBACK;

CREATE TRIGGER base_tab_def_view_instrig
    INSTEAD OF INSERT ON base_tab_def_view
    FOR EACH ROW
    EXECUTE FUNCTION base_tab_def_view_instrig_func ();

