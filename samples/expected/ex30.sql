CREATE OR REPLACE FUNCTION foo ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF NEW.role NOT IN (
        SELECT
            rolname
        FROM
            pg_authid) THEN
        RAISE EXCEPTION 'role % does not exist.', NEW.role;
    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION plpython_demo ()
    RETURNS void
    AS $$
	from this import s, d

	for char in s:
		print(d.get(char, char), end="")

	print()
$$
LANGUAGE 'plpython3u';

CREATE OR REPLACE FUNCTION plpython_demo2 ()
    RETURNS void
    LANGUAGE 'plpython3u'
    AS $body$
	from this import u, f

	for char in u:
		print(f.get(char, char), end="")

	print()
$body$;

CREATE FUNCTION ADD (integer, integer)
    RETURNS integer
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $_$
    SELECT
        $1 + $2;
$_$;

CREATE FUNCTION dup (integer, OUT f1 integer, OUT f2 text)
    RETURNS record
    LANGUAGE sql
    AS $_$
    SELECT
        $1,
        CAST($1 AS text) || ' is text'
$_$;

CREATE TABLE IF NOT EXISTS foo (
    id bigint PRIMARY KEY,
    /*
     This text will receive an extra level of indentation
     every time pg_format is executed
     */
    bar text NOT NULL
    /* this is the end*/
);

COMMENT ON TABLE xx.yy IS 'Line 1
- Line 2
- Line 3';

CREATE TABLE IF NOT EXISTS foo (
    /*******************************************************
     * This text will receive an extra level of indentation *
     * every time pg_format is executed                     *
     ********************************************************/
    id bigint PRIMARY KEY,
    /*
     This text will receive an extra level of indentation
     every time pg_format is executed
     */
    bar text NOT NULL
    /* this is the end*/
);

ALTER TABLE app_public.users ENABLE ROW LEVEL SECURITY;

COMMENT ON FUNCTION my_function () IS 'Here is my function that has a comment; will this become a sql clause or statement?';

