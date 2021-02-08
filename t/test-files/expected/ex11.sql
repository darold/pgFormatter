SELECT
    *
FROM
    a,
    ONLY (c)
    JOIN b USING (id, id2)
    LEFT JOIN d USING (id)
WHERE
    id > 10
    AND id <= 20;

CREATE OR REPLACE FUNCTION test_evtrig_no_rewrite ()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Table ''%'' is being rewritten (reason = %)', pg_event_trigger_table_rewrite_oid ()::regclass, pg_event_trigger_table_rewrite_reason ();
END;
$$;

SELECT
    lives_ok ('INSERT INTO "order".v_order (status, order_id, name)
    VALUES (''complete'', ''' || get_order_id () || ''', '' caleb ''', 'with all parameters');

PREPARE q AS
SELECT
    'some"text' AS "a""title",
    E'  <foo>\n<bar>' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

SELECT
    websearch_to_tsquery('''abc''''def''');

CREATE FUNCTION raise_exprs ()
    RETURNS void
    AS $$
DECLARE
    a integer[] = '{10,20,30}';
    c varchar = 'xyz';
    i integer;
BEGIN
    i := 2;
    RAISE NOTICE '%; %; %; %; %; %', a, a[i], c, (
        SELECT
            c || 'abc'),
    ROW (10,
        'aaa',
        NULL,
        30),
    NULL;
END;
$$
LANGUAGE plpgsql;

