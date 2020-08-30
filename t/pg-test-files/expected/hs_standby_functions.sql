--
-- Hot Standby tests
--
-- hs_standby_functions.sql
--
-- should fail
SELECT
    txid_current();

SELECT
    length(txid_current_snapshot()::text) >= 4;

SELECT
    pg_start_backup('should fail');

SELECT
    pg_switch_wal ();

SELECT
    pg_stop_backup();

-- should return no rows
SELECT
    *
FROM
    pg_prepared_xacts;

-- just the startup process
SELECT
    locktype,
    virtualxid,
    virtualtransaction,
    mode,
    granted
FROM
    pg_locks
WHERE
    virtualxid = '1/1';

-- suicide is painless
SELECT
    pg_cancel_backend(pg_backend_pid());

