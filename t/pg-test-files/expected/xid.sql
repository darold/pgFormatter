-- xid and xid8
-- values in range, in octal, decimal, hex
SELECT
    '010'::xid,
    '42'::xid,
    '0xffffffff'::xid,
    '-1'::xid,
    '010'::xid8,
    '42'::xid8,
    '0xffffffffffffffff'::xid8,
    '-1'::xid8;

-- garbage values
SELECT
    ''::xid;

SELECT
    'asdf'::xid;

SELECT
    ''::xid8;

SELECT
    'asdf'::xid8;

-- Also try it with non-error-throwing API
SELECT
    pg_input_is_valid ('42', 'xid');

SELECT
    pg_input_is_valid ('asdf', 'xid');

SELECT
    *
FROM
    pg_input_error_info ('0xffffffffff', 'xid');

SELECT
    pg_input_is_valid ('42', 'xid8');

SELECT
    pg_input_is_valid ('asdf', 'xid8');

SELECT
    *
FROM
    pg_input_error_info ('0xffffffffffffffffffff', 'xid8');

-- equality
SELECT
    '1'::xid = '1'::xid;

SELECT
    '1'::xid != '1'::xid;

SELECT
    '1'::xid8 = '1'::xid8;

SELECT
    '1'::xid8 != '1'::xid8;

-- conversion
SELECT
    '1'::xid = '1'::xid8::xid;

SELECT
    '1'::xid != '1'::xid8::xid;

-- we don't want relational operators for xid, due to use of modular arithmetic
SELECT
    '1'::xid < '2'::xid;

SELECT
    '1'::xid <= '2'::xid;

SELECT
    '1'::xid > '2'::xid;

SELECT
    '1'::xid >= '2'::xid;

-- we want them for xid8 though
SELECT
    '1'::xid8 < '2'::xid8,
    '2'::xid8 < '2'::xid8,
    '2'::xid8 < '1'::xid8;

SELECT
    '1'::xid8 <= '2'::xid8,
    '2'::xid8 <= '2'::xid8,
    '2'::xid8 <= '1'::xid8;

SELECT
    '1'::xid8 > '2'::xid8,
    '2'::xid8 > '2'::xid8,
    '2'::xid8 > '1'::xid8;

SELECT
    '1'::xid8 >= '2'::xid8,
    '2'::xid8 >= '2'::xid8,
    '2'::xid8 >= '1'::xid8;

-- we also have a 3way compare for btrees
SELECT
    xid8cmp ('1', '2'),
    xid8cmp ('2', '2'),
    xid8cmp ('2', '1');

-- min() and max() for xid8
CREATE TABLE xid8_t1 (
    x xid8
);

INSERT INTO xid8_t1
VALUES
    ('0'),
    ('010'),
    ('42'),
    ('0xffffffffffffffff'),
    ('-1');

SELECT
    min(x),
    max(x)
FROM
    xid8_t1;

-- xid8 has btree and hash opclasses
CREATE INDEX ON xid8_t1 USING btree (x);

CREATE INDEX ON xid8_t1 USING HASH (x);

DROP TABLE xid8_t1;

-- pg_snapshot data type and related functions
-- Note: another set of tests similar to this exists in txid.sql, for a limited
-- time (the relevant functions share C code)
-- i/o
SELECT
    '12:13:'::pg_snapshot;

SELECT
    '12:18:14,16'::pg_snapshot;

SELECT
    '12:16:14,14'::pg_snapshot;

-- errors
SELECT
    '31:12:'::pg_snapshot;

SELECT
    '0:1:'::pg_snapshot;

SELECT
    '12:13:0'::pg_snapshot;

SELECT
    '12:16:14,13'::pg_snapshot;

-- also try it with non-error-throwing API
SELECT
    pg_input_is_valid ('12:13:', 'pg_snapshot');

SELECT
    pg_input_is_valid ('31:12:', 'pg_snapshot');

SELECT
    *
FROM
    pg_input_error_info ('31:12:', 'pg_snapshot');

SELECT
    pg_input_is_valid ('12:16:14,13', 'pg_snapshot');

SELECT
    *
FROM
    pg_input_error_info ('12:16:14,13', 'pg_snapshot');

CREATE temp TABLE snapshot_test (
    nr integer,
    snap pg_snapshot
);

INSERT INTO snapshot_test
    VALUES (1, '12:13:');

INSERT INTO snapshot_test
    VALUES (2, '12:20:13,15,18');

INSERT INTO snapshot_test
    VALUES (3, '100001:100009:100005,100007,100008');

INSERT INTO snapshot_test
    VALUES (4, '100:150:101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131');

SELECT
    snap
FROM
    snapshot_test
ORDER BY
    nr;

SELECT
    pg_snapshot_xmin (snap),
    pg_snapshot_xmax (snap),
    pg_snapshot_xip (snap)
FROM
    snapshot_test
ORDER BY
    nr;

SELECT
    id,
    pg_visible_in_snapshot (id::text::xid8, snap)
FROM
    snapshot_test,
    generate_series(11, 21) id
WHERE
    nr = 2;

-- test bsearch
SELECT
    id,
    pg_visible_in_snapshot (id::text::xid8, snap)
FROM
    snapshot_test,
    generate_series(90, 160) id
WHERE
    nr = 4;

-- test current values also
SELECT
    pg_current_xact_id () >= pg_snapshot_xmin (pg_current_snapshot ());

-- we can't assume current is always less than xmax, however
SELECT
    pg_visible_in_snapshot (pg_current_xact_id (), pg_current_snapshot ());

-- test 64bitness
SELECT
    pg_snapshot '1000100010001000:1000100010001100:1000100010001012,1000100010001013';

SELECT
    pg_visible_in_snapshot ('1000100010001012', '1000100010001000:1000100010001100:1000100010001012,1000100010001013');

SELECT
    pg_visible_in_snapshot ('1000100010001015', '1000100010001000:1000100010001100:1000100010001012,1000100010001013');

-- test 64bit overflow
SELECT
    pg_snapshot '1:9223372036854775807:3';

SELECT
    pg_snapshot '1:9223372036854775808:3';

-- test pg_current_xact_id_if_assigned
BEGIN;
SELECT
    pg_current_xact_id_if_assigned () IS NULL;
SELECT
    pg_current_xact_id () \gset
SELECT
    pg_current_xact_id_if_assigned () IS NOT DISTINCT FROM xid8 :'pg_current_xact_id';
COMMIT;

-- test xid status functions
BEGIN;
SELECT
    pg_current_xact_id () AS committed \gset
COMMIT;

BEGIN;
SELECT
    pg_current_xact_id () AS rolledback \gset
ROLLBACK;

BEGIN;
SELECT
    pg_current_xact_id () AS inprogress \gset
SELECT
    pg_xact_status (:committed::text::xid8) AS committed;
SELECT
    pg_xact_status (:rolledback::text::xid8) AS rolledback;
SELECT
    pg_xact_status (:inprogress::text::xid8) AS inprogress;
SELECT
    pg_xact_status ('1'::xid8);
-- BootstrapTransactionId is always committed
SELECT
    pg_xact_status ('2'::xid8);
-- FrozenTransactionId is always committed
SELECT
    pg_xact_status ('3'::xid8);
-- in regress testing FirstNormalTransactionId will always be behind oldestXmin
COMMIT;

BEGIN;
CREATE FUNCTION test_future_xid_status (xid8)
    RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM
        pg_xact_status ($1);
    RAISE EXCEPTION 'didn''t ERROR at xid in the future as expected';
EXCEPTION
    WHEN invalid_parameter_value THEN
        RAISE NOTICE 'Got expected error for xid in the future';
END;
$$;
SELECT
    test_future_xid_status ((:inprogress + 10000)::text::xid8);
ROLLBACK;

