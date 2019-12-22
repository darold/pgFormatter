drop operator === ();
CREATE TYPE jwt_token AS (token TEXT, field: TEXT);

CREATE TABLE IF NOT EXISTS relationships (
  id SERIAL PRIMARY KEY,
  users_id INTEGER NOT NULL REFERENCES users (id),
students_id INTEGER NOT NULL REFERENCES students (id),
communication BOOLEAN NOT NULL
);

CREATE TABLE nulltest (
    col1 dnotnull,
    col2 dnotnull NULL -- NOT NULL in the domain cannot be overridden
,
    col3 dnull NOT NULL,
    col4 dnull,
    col5 dcheck CHECK (col5 IN ('c',
    'd'))
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

Select
  Date_trunc('day' , last_updated_on)
  , Count(*)
From
  exports.a
Group By
  Date_trunc('day' , last_updated_on)
Order By
  Date_trunc('day' , last_updated_on), toto
  Desc;


CREATE FUNCTION customcontsel(internal, oid, internal, integer)
RETURNS float8 AS 'contsel' LANGUAGE internal STABLE STRICT;

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

with ins (a, b, c) as
  (insert into mlparted (b, a) select s.a, 1 from generate_series(2, 39) s(a) returning tableoid::regclass, *)
  select a, b, min(c), max(c) from ins group by a, b order by 1;

CREATE OR REPLACE FUNCTION chkrolattr()
 RETURNS TABLE ("role" name, rolekeyword text, canlogin bool, replication bool)
 AS $$
SELECT r.rolname, v.keyword, r.rolcanlogin, r.rolreplication
 FROM pg_roles r
 JOIN (VALUES(CURRENT_USER, 'current_user'),
             (SESSION_USER, 'session_user'),
             ('current_user', '-'),
             ('session_user', '-'),
             ('Public', '-'),
             ('None', '-'))
      AS v(uname, keyword)
      ON (r.rolname = v.uname)
 ORDER BY 1;
$$ LANGUAGE SQL;

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

create table nv_child_2009 (check (d between '2009-01-01'::date and '2009-12-31'::date)) inherits (nv_parent);
create table part1 (
        a int not null check (a = 1),
        b int not null check (b >= 1 and b <= 10)
);

create trigger parted_trig
    after insert on parted_irreg for each row
    execute procedure trigger_notice_ab ();

create constraint trigger parted_trig_two after insert on parted_constr deferrable initially deferred for each row
when (
        bark (new.b)
        and new.a % 2 = 1)
    execute procedure trigger_notice_ab ();

begin;
create trigger ttdummy
	before delete or update on alterlock
	for each row
	execute procedure
	ttdummy (1, 1);
select * from my_locks order by 1;
rollback;

CREATE TRIGGER base_tab_def_view_instrig INSTEAD OF INSERT ON base_tab_def_view FOR EACH ROW
EXECUTE FUNCTION base_tab_def_view_instrig_func ();

