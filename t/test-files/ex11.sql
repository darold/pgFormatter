SELECT * FROM a, ONLY (c) JOIN b USING (id, id2) LEFT JOIN d USING (id) WHERE id > 10 AND id <= 20;

CREATE OR REPLACE FUNCTION test_evtrig_no_rewrite() RETURNS event_trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE NOTICE 'Table ''%'' is being rewritten (reason = %)',
               pg_event_trigger_table_rewrite_oid()::regclass,
               pg_event_trigger_table_rewrite_reason();
END;
$$;

SELECT
  lives_ok ('INSERT INTO "order".v_order (status, order_id, name)
    VALUES (''complete'', ''' || get_order_id () || ''', '' caleb ''', 'with all parameters');

prepare q as
  select 'some"text' as "a""title", E'  <foo>\n<bar>' as "junk",
         '   ' as "empty", n as int
  from generate_series(1,2) as n;

select websearch_to_tsquery('''abc''''def''');

create function raise_exprs() returns void as $$
declare
    a integer[] = '{10,20,30}';
    c varchar = 'xyz';
    i integer;
begin
    i := 2;
    raise notice '%; %; %; %; %; %', a, a[i], c, (select c || 'abc'), row(10,'aaa',NULL,30), NULL;
end;$$ language plpgsql;

