--
-- Hot Standby tests
--
-- hs_standby_allowed.sql
--
-- SELECT
SELECT
    count(*) AS should_be_1
FROM
    hs1;

SELECT
    count(*) AS should_be_2
FROM
    hs2;

SELECT
    count(*) AS should_be_3
FROM
    hs3;

\! cat /tmp/copy_test
-- Access sequence directly
SELECT
    is_called
FROM
    hsseq;

-- Transactions
BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
END;
BEGIN TRANSACTION read ONLY;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
END;
BEGIN TRANSACTION ISOLATION level REPEATABLE read;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
COMMIT;

BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
COMMIT;

BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
abort;
START TRANSACTION;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
COMMIT;

BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
ROLLBACK;

BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
SAVEPOINT s;
SELECT
    count(*) AS should_be_2
FROM
    hs2;
COMMIT;

BEGIN;
SELECT
    count(*) AS should_be_1
FROM
    hs1;
SAVEPOINT s;
SELECT
    count(*) AS should_be_2
FROM
    hs2;
release SAVEPOINT s;
SELECT
    count(*) AS should_be_2
FROM
    hs2;
SAVEPOINT s;
SELECT
    count(*) AS should_be_3
FROM
    hs3;
ROLLBACK TO SAVEPOINT s;

SELECT
    count(*) AS should_be_2
FROM
    hs2;

COMMIT;

-- SET parameters
-- has no effect on read only transactions, but we can still set it
SET synchronous_commit = ON;

SHOW synchronous_commit;

RESET synchronous_commit;

discard temp;

discard ALL;

-- CURSOR commands
BEGIN;
DECLARE hsc CURSOR FOR
    SELECT
        *
    FROM
        hs3;
FETCH NEXT FROM hsc;
FETCH FIRST FROM hsc;
FETCH LAST FROM hsc;
FETCH 1 FROM hsc;
CLOSE hsc;
COMMIT;

-- Prepared plans
PREPARE hsp AS
SELECT
    count(*)
FROM
    hs1;

PREPARE hsp_noexec (integer) AS
INSERT INTO hs1
    VALUES ($1);

EXECUTE hsp;

DEALLOCATE hsp;

-- LOCK
BEGIN;
LOCK hs1 IN ACCESS SHARE MODE;
LOCK hs1 IN ROW SHARE MODE;
LOCK hs1 IN ROW EXCLUSIVE MODE;
COMMIT;

-- UNLISTEN
UNLISTEN a;

UNLISTEN *;

-- LOAD
-- should work, easier if there is no test for that...
-- ALLOWED COMMANDS
CHECKPOINT;

discard ALL;

