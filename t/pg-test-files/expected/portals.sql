--
-- Cursor regression tests
--
BEGIN;
DECLARE foo1 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo2 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo3 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo4 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo5 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo6 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo7 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo8 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo9 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo10 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo11 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo12 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo13 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo14 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo15 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo16 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo17 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo18 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo19 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo20 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo21 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
DECLARE foo22 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DECLARE foo23 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
FETCH 1 IN foo1;
FETCH 2 IN foo2;
FETCH 3 IN foo3;
FETCH 4 IN foo4;
FETCH 5 IN foo5;
FETCH 6 IN foo6;
FETCH 7 IN foo7;
FETCH 8 IN foo8;
FETCH 9 IN foo9;
FETCH 10 IN foo10;
FETCH 11 IN foo11;
FETCH 12 IN foo12;
FETCH 13 IN foo13;
FETCH 14 IN foo14;
FETCH 15 IN foo15;
FETCH 16 IN foo16;
FETCH 17 IN foo17;
FETCH 18 IN foo18;
FETCH 19 IN foo19;
FETCH 20 IN foo20;
FETCH 21 IN foo21;
FETCH 22 IN foo22;
FETCH 23 IN foo23;
FETCH BACKWARD 1 IN foo23;
FETCH BACKWARD 2 IN foo22;
FETCH BACKWARD 3 IN foo21;
FETCH BACKWARD 4 IN foo20;
FETCH BACKWARD 5 IN foo19;
FETCH BACKWARD 6 IN foo18;
FETCH BACKWARD 7 IN foo17;
FETCH BACKWARD 8 IN foo16;
FETCH BACKWARD 9 IN foo15;
FETCH BACKWARD 10 IN foo14;
FETCH BACKWARD 11 IN foo13;
FETCH BACKWARD 12 IN foo12;
FETCH BACKWARD 13 IN foo11;
FETCH BACKWARD 14 IN foo10;
FETCH BACKWARD 15 IN foo9;
FETCH BACKWARD 16 IN foo8;
FETCH BACKWARD 17 IN foo7;
FETCH BACKWARD 18 IN foo6;
FETCH BACKWARD 19 IN foo5;
FETCH BACKWARD 20 IN foo4;
FETCH BACKWARD 21 IN foo3;
FETCH BACKWARD 22 IN foo2;
FETCH BACKWARD 23 IN foo1;
CLOSE foo1;
CLOSE foo2;
CLOSE foo3;
CLOSE foo4;
CLOSE foo5;
CLOSE foo6;
CLOSE foo7;
CLOSE foo8;
CLOSE foo9;
CLOSE foo10;
CLOSE foo11;
CLOSE foo12;
-- leave some cursors open, to test that auto-close works.
-- record this in the system view as well (don't query the time field there
-- however)
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors
ORDER BY
    1;
END;
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors;
--
-- NO SCROLL disallows backward fetching
--
BEGIN;
DECLARE foo24 NO SCROLL CURSOR FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
FETCH 1 FROM foo24;
FETCH BACKWARD 1 FROM foo24;
-- should fail
END;
--
-- Cursors outside transaction blocks
--
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors;
BEGIN;
DECLARE foo25 SCROLL CURSOR WITH HOLD FOR
    SELECT
        *
    FROM
        tenk2;
FETCH FROM foo25;
FETCH FROM foo25;
COMMIT;

FETCH FROM foo25;

FETCH BACKWARD FROM foo25;

FETCH ABSOLUTE - 1 FROM foo25;

SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors;

CLOSE foo25;

--
-- ROLLBACK should close holdable cursors
--
BEGIN;
DECLARE foo26 CURSOR WITH HOLD FOR
    SELECT
        *
    FROM
        tenk1
    ORDER BY
        unique2;
ROLLBACK;

-- should fail
FETCH
FROM
    foo26;

--
-- Parameterized DECLARE needs to insert param values into the cursor portal
--
BEGIN;
CREATE FUNCTION declares_cursor (text)
    RETURNS void
    AS '
DECLARE
    c CURSOR FOR
        SELECT
            stringu1
        FROM
            tenk1
        WHERE
            stringu1 LIKE $1;
'
LANGUAGE SQL;
SELECT
    declares_cursor ('AB%');
FETCH ALL FROM c;
ROLLBACK;

--
-- Test behavior of both volatile and stable functions inside a cursor;
-- in particular we want to see what happens during commit of a holdable
-- cursor
--
CREATE temp TABLE tt1 (
    f1 int
);

CREATE FUNCTION count_tt1_v ()
    RETURNS int8
    AS '
    SELECT
        count(*)
    FROM
        tt1;
'
LANGUAGE sql
VOLATILE;

CREATE FUNCTION count_tt1_s ()
    RETURNS int8
    AS '
    SELECT
        count(*)
    FROM
        tt1;
'
LANGUAGE sql
STABLE;

BEGIN;
INSERT INTO tt1
    VALUES (1);
DECLARE c1 CURSOR FOR
    SELECT
        count_tt1_v (),
        count_tt1_s ();
INSERT INTO tt1
    VALUES (2);
FETCH ALL FROM c1;
ROLLBACK;

BEGIN;
INSERT INTO tt1
    VALUES (1);
DECLARE c2 CURSOR WITH hold FOR
    SELECT
        count_tt1_v (
),
        count_tt1_s ();
INSERT INTO tt1
    VALUES (2);
COMMIT;

DELETE FROM tt1;

FETCH ALL FROM c2;

DROP FUNCTION count_tt1_v ();

DROP FUNCTION count_tt1_s ();

-- Create a cursor with the BINARY option and check the pg_cursors view
BEGIN;
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors;
DECLARE bc BINARY CURSOR FOR
    SELECT
        *
    FROM
        tenk1;
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors
ORDER BY
    1;
ROLLBACK;

-- We should not see the portal that is created internally to
-- implement EXECUTE in pg_cursors
PREPARE cprep AS
SELECT
    name,
    statement,
    is_holdable,
    is_binary,
    is_scrollable
FROM
    pg_cursors;

EXECUTE cprep;

-- test CLOSE ALL;
SELECT
    name
FROM
    pg_cursors
ORDER BY
    1;

CLOSE ALL;

SELECT
    name
FROM
    pg_cursors
ORDER BY
    1;

BEGIN;
DECLARE foo1 CURSOR WITH HOLD FOR
    SELECT
        1;
DECLARE foo2 CURSOR WITHOUT HOLD FOR
    SELECT
        1;
SELECT
    name
FROM
    pg_cursors
ORDER BY
    1;
CLOSE ALL;
SELECT
    name
FROM
    pg_cursors
ORDER BY
    1;
COMMIT;

--
-- Tests for updatable cursors
--
CREATE TEMP TABLE uctest (
    f1 int,
    f2 text
);

INSERT INTO uctest
VALUES
    (1, 'one'),
    (2, 'two'),
    (3, 'three');

SELECT
    *
FROM
    uctest;

-- Check DELETE WHERE CURRENT
BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest;
FETCH 2 FROM c1;
DELETE FROM uctest
WHERE CURRENT OF c1;
-- should show deletion
SELECT
    *
FROM
    uctest;
-- cursor did not move
FETCH ALL
FROM
    c1;
-- cursor is insensitive
MOVE BACKWARD ALL IN c1;
FETCH ALL FROM c1;
COMMIT;

-- should still see deletion
SELECT
    *
FROM
    uctest;

-- Check UPDATE WHERE CURRENT; this time use FOR UPDATE
BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest
    FOR UPDATE;
FETCH c1;
UPDATE
    uctest
SET
    f1 = 8
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
COMMIT;

SELECT
    *
FROM
    uctest;

-- Check repeated-update and update-then-delete cases
BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest;
FETCH c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
-- insensitive cursor should not show effects of updates or deletes
FETCH RELATIVE 0
FROM
    c1;
DELETE FROM uctest
WHERE CURRENT OF c1;
SELECT
    *
FROM
    uctest;
DELETE FROM uctest
WHERE CURRENT OF c1;
-- no-op
SELECT
    *
FROM
    uctest;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
-- no-op
SELECT
    *
FROM
    uctest;
FETCH RELATIVE 0 FROM c1;
ROLLBACK;

SELECT
    *
FROM
    uctest;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest
    FOR UPDATE;
FETCH c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
DELETE FROM uctest
WHERE CURRENT OF c1;
SELECT
    *
FROM
    uctest;
DELETE FROM uctest
WHERE CURRENT OF c1;
-- no-op
SELECT
    *
FROM
    uctest;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
-- no-op
SELECT
    *
FROM
    uctest;
--- sensitive cursors can't currently scroll back, so this is an error:
FETCH RELATIVE 0
FROM
    c1;
ROLLBACK;

SELECT
    *
FROM
    uctest;

-- Check inheritance cases
CREATE TEMP TABLE ucchild ()
INHERITS (
    uctest
);

INSERT INTO ucchild
    VALUES (100, 'hundred');

SELECT
    *
FROM
    uctest;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest
    FOR UPDATE;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
FETCH 1 FROM c1;
COMMIT;

SELECT
    *
FROM
    uctest;

-- Can update from a self-join, but only if FOR UPDATE says which to use
BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest a,
        uctest b
    WHERE
        a.f1 = b.f1 + 5;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
-- fail
ROLLBACK;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest a,
        uctest b
    WHERE
        a.f1 = b.f1 + 5
    FOR UPDATE;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
-- fail
ROLLBACK;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest a,
        uctest b
    WHERE
        a.f1 = b.f1 + 5 FOR SHARE OF a;
FETCH 1 FROM c1;
UPDATE
    uctest
SET
    f1 = f1 + 10
WHERE
    CURRENT OF c1;
SELECT
    *
FROM
    uctest;
ROLLBACK;

-- Check various error cases
DELETE FROM uctest
WHERE CURRENT OF c1;

-- fail, no such cursor
DECLARE cx CURSOR WITH HOLD FOR
    SELECT
        *
    FROM
        uctest;

DELETE FROM uctest
WHERE CURRENT OF cx;

-- fail, can't use held cursor
BEGIN;
DECLARE c CURSOR FOR
    SELECT
        *
    FROM
        tenk2;
DELETE FROM uctest
WHERE CURRENT OF c;
-- fail, cursor on wrong table
ROLLBACK;

BEGIN;
DECLARE c CURSOR FOR
    SELECT
        *
    FROM
        tenk2 FOR SHARE;
DELETE FROM uctest
WHERE CURRENT OF c;
-- fail, cursor on wrong table
ROLLBACK;

BEGIN;
DECLARE c CURSOR FOR
    SELECT
        *
    FROM
        tenk1
        JOIN tenk2 USING (unique1);
DELETE FROM tenk1
WHERE CURRENT OF c;
-- fail, cursor is on a join
ROLLBACK;

BEGIN;
DECLARE c CURSOR FOR
    SELECT
        f1,
        count(*)
    FROM
        uctest
    GROUP BY
        f1;
DELETE FROM uctest
WHERE CURRENT OF c;
-- fail, cursor is on aggregation
ROLLBACK;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        uctest;
DELETE FROM uctest
WHERE CURRENT OF c1;
-- fail, no current row
ROLLBACK;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        MIN(f1)
    FROM
        uctest
    FOR UPDATE;
ROLLBACK;

-- WHERE CURRENT OF may someday work with views, but today is not that day.
-- For now, just make sure it errors out cleanly.
CREATE TEMP VIEW ucview AS
SELECT
    *
FROM
    uctest;

CREATE RULE ucrule AS ON DELETE TO ucview
    DO INSTEAD
    DELETE FROM uctest
    WHERE f1 = OLD.f1;

BEGIN;
DECLARE c1 CURSOR FOR
    SELECT
        *
    FROM
        ucview;
FETCH FROM c1;
DELETE FROM ucview
WHERE CURRENT OF c1;
-- fail, views not supported
ROLLBACK;

-- Check WHERE CURRENT OF with an index-only scan
BEGIN;
EXPLAIN (
    COSTS OFF
) DECLARE c1 CURSOR FOR
    SELECT
        stringu1
    FROM
        onek
    WHERE
        stringu1 = 'DZAAAA';
DECLARE c1 CURSOR FOR
    SELECT
        stringu1
    FROM
        onek
    WHERE
        stringu1 = 'DZAAAA';
FETCH FROM c1;
DELETE FROM onek
WHERE CURRENT OF c1;
SELECT
    stringu1
FROM
    onek
WHERE
    stringu1 = 'DZAAAA';
ROLLBACK;

-- Check behavior with rewinding to a previous child scan node,
-- as per bug #15395
BEGIN;
CREATE TABLE current_check (
    currentid int,
    payload text
);
CREATE TABLE current_check_1 ()
INHERITS (
    current_check
);
CREATE TABLE current_check_2 ()
INHERITS (
    current_check
);
INSERT INTO current_check_1
SELECT
    i,
    'p' || i
FROM
    generate_series(1, 9) i;
INSERT INTO current_check_2
SELECT
    i,
    'P' || i
FROM
    generate_series(10, 19) i;
DECLARE c1 SCROLL CURSOR FOR
    SELECT
        *
    FROM
        current_check;
-- This tests the fetch-backwards code path
FETCH ABSOLUTE 12
FROM
    c1;
FETCH ABSOLUTE 8 FROM c1;
DELETE FROM current_check
WHERE CURRENT OF c1
RETURNING
    *;
-- This tests the ExecutorRewind code path
FETCH ABSOLUTE 13
FROM
    c1;
FETCH ABSOLUTE 1 FROM c1;
DELETE FROM current_check
WHERE CURRENT OF c1
RETURNING
    *;
SELECT
    *
FROM
    current_check;
ROLLBACK;

-- Make sure snapshot management works okay, per bug report in
-- 235395b90909301035v7228ce63q392931f15aa74b31@mail.gmail.com
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
CREATE TABLE CURSOR (
    a int
);
INSERT INTO CURSOR
    VALUES (1);
DECLARE c1 NO SCROLL CURSOR FOR
    SELECT
        *
    FROM
        CURSOR
    FOR UPDATE;
UPDATE
    CURSOR
SET
    a = 2;
FETCH ALL FROM c1;
COMMIT;

DROP TABLE CURSOR;

-- Check rewinding a cursor containing a stable function in LIMIT,
-- per bug report in 8336843.9833.1399385291498.JavaMail.root@quick
BEGIN;
CREATE FUNCTION nochange (int)
    RETURNS int
    AS '
    SELECT
        $1
    LIMIT 1;
'
LANGUAGE sql
STABLE;
DECLARE c CURSOR FOR
    SELECT
        *
    FROM
        int8_tbl
    LIMIT nochange (3);
FETCH ALL FROM c;
MOVE BACKWARD ALL IN c;
FETCH ALL FROM c;
ROLLBACK;

-- Check handling of non-backwards-scan-capable plans with scroll cursors
BEGIN;
EXPLAIN (
    COSTS OFF
) DECLARE c1 CURSOR FOR
    SELECT
        (
            SELECT
                42) AS x;
EXPLAIN (
    COSTS OFF
) DECLARE c1 SCROLL CURSOR FOR
    SELECT
        (
            SELECT
                42) AS x;
DECLARE c1 SCROLL CURSOR FOR
    SELECT
        (
            SELECT
                42) AS x;
FETCH ALL IN c1;
FETCH BACKWARD ALL IN c1;
ROLLBACK;

BEGIN;
EXPLAIN (
    COSTS OFF
) DECLARE c2 CURSOR FOR
    SELECT
        generate_series(1, 3) AS g;
EXPLAIN (
    COSTS OFF
) DECLARE c2 SCROLL CURSOR FOR
    SELECT
        generate_series(1, 3) AS g;
DECLARE c2 SCROLL CURSOR FOR
    SELECT
        generate_series(1, 3) AS g;
FETCH ALL IN c2;
FETCH BACKWARD ALL IN c2;
ROLLBACK;

