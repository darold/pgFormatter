SET client_encoding TO 'UTF8';

UPDATE
    weather
SET
    temp_lo = temp_lo + 1,
    temp_hi = temp_lo + 15,
    prcp = DEFAULT
WHERE
    city = 'San Francisco'
    AND date = '2003-07-03'
RETURNING
    temp_lo,
    temp_hi,
    prcp;

\set ON_ERROR_STOP ON
SELECT
    *
FROM (
    SELECT
        *
    FROM
        mytable
    FOR UPDATE) AS ss
WHERE
    col1 = 5;

BEGIN;
SELECT
    *
FROM
    mytable
WHERE
    KEY = 1
FOR NO KEY UPDATE;
SAVEPOINT s;
UPDATE
    mytable
SET
    col1 = NULL
WHERE
    KEY = 1;
ROLLBACK TO s;
