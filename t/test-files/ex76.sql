insert into videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
on conflict (sha, idx)
    do update set
        sha = excluded.sha, idx = excluded.idx, title = excluded.title, codec = excluded.codec, mime_codec = excluded.mime_codec, width = excluded.width, height = excluded.height, is_default = excluded.is_default, bitrate = excluded.bitrate;

insert into videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
on conflict (sha, idx)
    do update set
         (a, b, c) = (excluded.a, excluded.b, excluded.c);

INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (KEY, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS ( SELECT 1 FROM insertconflicttest ii WHERE ii.key = excluded.key);

insert into upsert values(1, 'val') on conflict (key) do update set val = 'seen with subselect ' || (select f1 from int4_tbl where f1 != 0 limit 1)::text;

CREATE OR REPLACE FUNCTION whatever ()
    RETURNS text
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $body$
DECLARE
    v_sql text;
BEGIN
    v_sql := format($sql$ GRANT usage ON SCHEMA dba_tools TO %s;
    $sql$,
    v_sql_role);
    EXECUTE v_sql;
    RETURN v_sql;
END;
$body$;

SELECT format('Hello %s', 'World');

SELECT format('Testing %s, %s, %s, %%', 'one', 'two', 'three');

SELECT format('INSERT INTO %I VALUES(%L)', 'Foo bar', E'O\'Reilly');

SELECT format('INSERT INTO %I VALUES(%L)', 'locations', 'C:\Program Files');

SELECT format('|%10s|', 'foo');

SELECT format('|%-10s|', 'foo');

SELECT format('|%*s|', 10, 'foo');

SELECT format('|%*s|', -10, 'foo');

SELECT format('|%-*s|', 10, 'foo');

SELECT format('|%-*s|', -10, 'foo');

SELECT format('Testing %3$s, %2$s, %1$s', 'one', 'two', 'three');

SELECT format('|%*2$s|', 'foo', 10, 'bar');

SELECT format('|%1$*2$s|', 'foo', 10, 'bar');

SELECT format('Testing %3$s, %2$s, %s', 'one', 'two', 'three');

DO $$
DECLARE
    _variable int := 42;
BEGIN

    -- This is a comment
    CREATE TEMP TABLE IF NOT EXISTS tempy_mc_tempface (
        test text
    );
    TRUNCATE TABLE tempy_mc_tempface;

    INSERT INTO tempy_mc_tempface
    VALUES
        ('tempy'),
        ('mc'),
        ('tempface');
        
    -- Another Comment
    INSERT INTO tempy_mc_tempface
        VALUES ('another', 'world');

END
$$;
