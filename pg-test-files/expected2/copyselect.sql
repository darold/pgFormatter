--
-- Test cases for COPY (select) TO
--

CREATE TABLE test1 (
    id serial,
    t text
);

INSERT INTO test1 (t)
    VALUES ('a');

INSERT INTO test1 (t)
    VALUES ('b');

INSERT INTO test1 (t)
    VALUES ('c');

INSERT INTO test1 (t)
    VALUES ('d');

INSERT INTO test1 (t)
    VALUES ('e');

CREATE TABLE test2 (
    id serial,
    t text
);

INSERT INTO test2 (t)
    VALUES ('A');

INSERT INTO test2 (t)
    VALUES ('B');

INSERT INTO test2 (t)
    VALUES ('C');

INSERT INTO test2 (t)
    VALUES ('D');

INSERT INTO test2 (t)
    VALUES ('E');

CREATE VIEW v_test1 AS
SELECT
    'v_' || t
FROM
    test1;

--
-- Test COPY table TO
--

COPY test1 TO stdout;

--
-- This should fail
--

COPY v_test1 TO stdout;

--
-- Test COPY (select) TO
--

COPY (
    SELECT
        t
    FROM
        test1
    WHERE
        id = 1)
TO stdout;

--
-- Test COPY (select for update) TO
--

COPY (
    SELECT
        t
    FROM
        test1
    WHERE
        id = 3
    FOR UPDATE)
TO stdout;

--
-- This should fail
--

COPY (
    SELECT
        t INTO temp test3
    FROM
        test1
    WHERE
        id = 3)
TO stdout;

--
-- This should fail
--

COPY (
    SELECT
        *
    FROM
        test1)
FROM
    stdin;

--
-- This should fail
--

COPY (
    SELECT
        *
    FROM
        test1) (t,
    id)
    TO stdout;

--
-- Test JOIN
--

COPY (
    SELECT
        *
    FROM
        test1
        JOIN test2 USING (id))
    TO stdout;

--
-- Test UNION SELECT
--

COPY (
    SELECT
        t
    FROM
        test1
    WHERE
        id = 1
    UNION
    SELECT
        *
    FROM
        v_test1
    ORDER BY
        1)
    TO stdout;

--
-- Test subselect
--

COPY (
    SELECT
        *
    FROM (
        SELECT
            t
        FROM
            test1
        WHERE
            id = 1
        UNION
        SELECT
            *
        FROM
            v_test1
        ORDER BY
            1) t1)
    TO stdout;

--
-- Test headers, CSV and quotes
--

COPY (
    SELECT
        t
    FROM
        test1
    WHERE
        id = 1)
TO stdout csv header force quote t;

--
-- Test psql builtins, plain table
--

\copy test1 to stdout
--
-- This should fail
--

\copy v_test1 to stdout
--
-- Test \copy (select ...)
--

\copy (select "id",'id','id""'||t,(id + 1)*id,t,"test1"."t" from test1 where id=3) to stdout
--
-- Drop everything
--

DROP TABLE test2;

DROP VIEW v_test1;

DROP TABLE test1;

-- psql handling of COPY in multi-command strings
COPY (
    SELECT
        1)
TO stdout;

SELECT
    1 / 0;

-- row, then error
SELECT
    1 / 0;

COPY (
    SELECT
        1)
TO stdout;

-- error only
COPY (
    SELECT
        1)
TO stdout;

COPY (
    SELECT
        2)
TO stdout;

SELECT
    0;

SELECT
    3;

-- 1 2 3
CREATE TABLE test3 (
    c int
);

SELECT
    0;

COPY test3
FROM
    stdin;

COPY test3
FROM
    stdin;

SELECT
    1;

-- 1
1.2.
SELECT
    *
FROM
    test3;

DROP TABLE test3;

