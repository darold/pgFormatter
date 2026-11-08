--
-- COPY
--
-- directory paths are passed to us in environment variables
\getenv abs_srcdir PG_ABS_SRCDIR

\getenv abs_builddir PG_ABS_BUILDDIR

--- test copying in CSV mode with various styles
--- of embedded line ending characters
CREATE temp TABLE copytest (
    style text,
    test text,
    filler int
);

INSERT INTO copytest
    VALUES ('DOS', E'abc\r\ndef', 1);

INSERT INTO copytest
    VALUES ('Unix', E'abc\ndef', 2);

INSERT INTO copytest
    VALUES ('Mac', E'abc\rdef', 3);

INSERT INTO copytest
    VALUES (E'esc\\ape', E'a\\r\\\r\\\n\\nb', 4);

\set filename :abs_builddir '/results/copytest.csv'
COPY copytest TO :'filename' csv;

CREATE temp TABLE copytest2 (
    LIKE copytest
);

COPY copytest2
FROM
    :'filename' csv;

SELECT
    *
FROM
    copytest
EXCEPT
SELECT
    *
FROM
    copytest2;

TRUNCATE copytest2;

--- same test but with an escape char different from quote char
COPY copytest TO :'filename' csv quote '''' escape E'\\';

COPY copytest2
FROM
    :'filename' csv quote '''' escape E'\\';

SELECT
    *
FROM
    copytest
EXCEPT
SELECT
    *
FROM
    copytest2;

--- test unquoted \. as data inside CSV
-- do not use copy out to export the data, as it would quote \.
\o :filename
\qecho line1
\qecho '\\.'
\qecho line2
\o
-- get the data back in with copy
TRUNCATE copytest2;

COPY copytest2 (test)
FROM
    :'filename' csv;

SELECT
    test
FROM
    copytest2
ORDER BY
    test COLLATE "C";

-- in text mode, \. must be alone on its line
TRUNCATE copytest2;

copy copytest2(test) from stdin;
line1
line2
foo\.
line3
\.
copy copytest2(test) from stdin;
line4
line5
\.foo
line6
\.
SELECT
    test
FROM
    copytest2;

-- test header line feature
CREATE temp TABLE copytest3 (
    c1 int,
    "col with , comma" text,
    "col with "" quote" int
);

copy copytest3 from stdin csv header;
this is just a line full of junk that would error out if parsed
1,a,1
2,b,2
\.
COPY copytest3 TO stdout csv header;

-- testing explicit column order
CREATE temp TABLE copytest_order (
    a int,
    b int,
    c int
);

copy copytest_order from stdin;
1	2	3
\.
COPY copytest_order (c, b, a)
TO stdout;

COPY copytest_order (c, b, a)
TO stdout (format csv);

COPY copytest_order (c, b, a)
TO stdout (format json);

--- test copying in JSON mode with various styles
COPY (
    SELECT
        1
    UNION ALL
    SELECT
        2)
TO stdout WITH (
    format json);

COPY (
    SELECT
        1 AS foo
    UNION ALL
    SELECT
        2)
TO stdout WITH (
    format json);

COPY (
    VALUES (1),
        (2))
    TO stdout WITH (
        format json);

COPY (
    SELECT
        1
    UNION ALL
    SELECT
        2)
TO stdout WITH (
    format json,
    force_array TRUE);

COPY (
    VALUES (1),
        (2))
    TO stdout WITH (
        format json, force_array TRUE);

COPY copytest TO stdout json;

COPY copytest TO stdout (format json);

COPY (
    SELECT
        *
    FROM
        copytest)
    TO stdout (format json);

-- keys are the query's column names, also when a scan does not project
COPY (
    SELECT
        a AS x,
        b AS y,
        c AS z
    FROM
        copytest_order)
    TO stdout (format json);

CREATE temp TABLE copytest_order2 (
    c int,
    b int,
    a int
);

INSERT INTO copytest_order2
    VALUES (4, 5, 6);

COPY (
    SELECT
        *
    FROM
        copytest_order
    UNION ALL
    SELECT
        *
    FROM
        copytest_order2)
    TO stdout (format json);

-- columns with missing values force a projection
ALTER TABLE copytest_order2
    ADD COLUMN d int DEFAULT 7;

COPY (
    SELECT
        *
    FROM
        copytest_order2)
    TO stdout (format json);

-- all of the following should yield error
COPY copytest TO stdout (format json, DELIMITER '|');

COPY copytest TO stdout (format json, NULL '\N');

COPY copytest TO stdout (format json, DEFAULT '|');

COPY copytest TO stdout (format json, header);

COPY copytest TO stdout (format json, header 1);

COPY copytest TO stdout (format json, quote '"');

COPY copytest TO stdout (format json, escape '"');

COPY copytest TO stdout (format json, force_quote *);

COPY copytest TO stdout (format json, force_not_null *);

COPY copytest TO stdout (format json, force_null *);

COPY copytest TO stdout (format json, on_error ignore);

COPY copytest TO stdout (format json, reject_limit 1);

copy copytest from stdin(format json);
\.
-- all of the above should yield error
-- column list with json format
COPY copytest (style, test, filler)
TO stdout (format json);

-- should fail: force_array requires json format
COPY copytest TO stdout (format csv, force_array TRUE);

-- force_array variants
COPY copytest TO stdout (format json, force_array);

COPY copytest (style, test)
TO stdout (format json, force_array TRUE);

COPY copytest TO stdout (format json, force_array FALSE);

-- force_array with empty result set
COPY (
    SELECT
        1
    WHERE
        FALSE)
TO stdout (format json, force_array);

-- column list with diverse data types
CREATE temp TABLE copyjsontest_types (
    id int,
    js json,
    jsb jsonb,
    arr int[],
    n numeric(10, 2),
    b boolean,
    ts timestamp,
    t text
);

INSERT INTO copyjsontest_types
VALUES
    (1, '{"a":1}', '{"b":2}', '{1,2,3}', 3.14, TRUE, '2024-01-15 10:30:00', 'hello'),
    (2, '[1,null,"x"]', '{"nested":{"k":"v"}}', '{4,5}', -99.99, FALSE, '2024-06-30 23:59:59', 'world'),
    (3, 'null', 'null', '{}', NULL, NULL, NULL, NULL);

-- full table
COPY copyjsontest_types TO stdout (format json);

-- column subsets exercising each type
COPY copyjsontest_types (id, js, jsb)
TO stdout (format json);

COPY copyjsontest_types (id, arr, n, b)
TO stdout (format json);

COPY copyjsontest_types (jsb, t)
TO stdout (format json);

COPY copyjsontest_types (id, ts)
TO stdout (format json);

-- single column: json and jsonb
COPY copyjsontest_types (js)
TO stdout (format json);

COPY copyjsontest_types (jsb)
TO stdout (format json);

DROP TABLE copyjsontest_types;

-- embedded escaped characters
CREATE temp TABLE copyjsontest (
    id bigserial,
    f1 text,
    f2 timestamptz
);

INSERT INTO copyjsontest
SELECT
    g.i,
    CASE WHEN g.i % 2 = 0 THEN
        'line with '' in it: ' || g.i::text
    ELSE
        'line with " in it: ' || g.i::text
    END,
    'Mon Feb 10 17:32:01 1997 PST'
FROM
    generate_series(1, 5) AS g (i);

INSERT INTO copyjsontest (f1)
VALUES
    (E'aaa\"bbb'::text),
    (E'aaa\\bbb'::text),
    (E'aaa\/bbb'::text),
    (E'aaa\bbbb'::text),
    (E'aaa\fbbb'::text),
    (E'aaa\nbbb'::text),
    (E'aaa\rbbb'::text),
    (E'aaa\tbbb'::text);

COPY copyjsontest TO stdout json;

CREATE temp TABLE copytest4 (
    c1 int,
    "colname with tab: 	" text
);

copy copytest4 from stdin (header);
this is just a line full of junk that would error out if parsed
1	a
2	b
\.
COPY copytest4 TO stdout (header);

-- test multi-line header line feature
CREATE temp TABLE copytest5 (
    c1 int
);

copy copytest5 from stdin (format csv, header 2);
this is a first header line.
this is a second header line.
1
2
\.
COPY copytest5 TO stdout (header);

TRUNCATE copytest5;

copy copytest5 from stdin (format csv, header 4);
this is a first header line.
this is a second header line.
1
2
\.
SELECT
    count(*)
FROM
    copytest5;

TRUNCATE copytest5;

copy copytest5 from stdin (format csv, header 5);
this is a first header line.
this is a second header line.
1
2
\.
SELECT
    count(*)
FROM
    copytest5;

-- test header line feature (given as strings)
TRUNCATE copytest5;

copy copytest5 from stdin (format csv, header '0');
1
2
\.
SELECT
    *
FROM
    copytest5
ORDER BY
    c1;

TRUNCATE copytest5;

copy copytest5 from stdin (format csv, header '1');
1
2
\.
SELECT
    *
FROM
    copytest5
ORDER BY
    c1;

-- test copy from with a partitioned table
CREATE TABLE parted_copytest (
    a int,
    b int,
    c text
)
PARTITION BY LIST (b);

CREATE TABLE parted_copytest_a1 (
    c text,
    b int,
    a int
);

CREATE TABLE parted_copytest_a2 (
    a int,
    c text,
    b int
);

ALTER TABLE parted_copytest ATTACH PARTITION parted_copytest_a1
FOR VALUES IN (1);

ALTER TABLE parted_copytest ATTACH PARTITION parted_copytest_a2
FOR VALUES IN (2);

-- We must insert enough rows to trigger multi-inserts.  These are only
-- enabled adaptively when there are few enough partition changes.
INSERT INTO parted_copytest
SELECT
    x,
    1,
    'One'
FROM
    generate_series(1, 1000) x;

INSERT INTO parted_copytest
SELECT
    x,
    2,
    'Two'
FROM
    generate_series(1001, 1010) x;

INSERT INTO parted_copytest
SELECT
    x,
    1,
    'One'
FROM
    generate_series(1011, 1020) x;

\set filename :abs_builddir '/results/parted_copytest.csv'
COPY (
    SELECT
        *
    FROM
        parted_copytest
    ORDER BY
        a)
    TO :'filename';

TRUNCATE parted_copytest;

COPY parted_copytest
FROM
    :'filename';

-- Ensure COPY FREEZE errors for partitioned tables.
BEGIN;
TRUNCATE parted_copytest;
COPY parted_copytest
FROM
    :'filename' (FREEZE);
ROLLBACK;

SELECT
    tableoid::regclass,
    count(*),
    sum(a)
FROM
    parted_copytest
GROUP BY
    tableoid
ORDER BY
    tableoid::regclass::name;

TRUNCATE parted_copytest;

-- create before insert row trigger on parted_copytest_a2
CREATE FUNCTION part_ins_func ()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN new;
END;
$$;

CREATE TRIGGER part_ins_trig
    BEFORE INSERT ON parted_copytest_a2
    FOR EACH ROW
    EXECUTE PROCEDURE part_ins_func ();

COPY parted_copytest
FROM
    :'filename';

SELECT
    tableoid::regclass,
    count(*),
    sum(a)
FROM
    parted_copytest
GROUP BY
    tableoid
ORDER BY
    tableoid::regclass::name;

TRUNCATE TABLE parted_copytest;

CREATE INDEX ON parted_copytest (b);

DROP TRIGGER part_ins_trig ON parted_copytest_a2;

copy parted_copytest from stdin;
1	1	str1
2	2	str2
\.
-- Ensure index entries were properly added during the copy.
SELECT
    *
FROM
    parted_copytest
WHERE
    b = 1;

SELECT
    *
FROM
    parted_copytest
WHERE
    b = 2;

DROP TABLE parted_copytest;

--
-- Progress reporting for COPY
--
CREATE TABLE tab_progress_reporting (
    name text,
    age int4,
    location point,
    salary int4,
    manager name
);

-- Add a trigger to catch and print the contents of the catalog view
-- pg_stat_progress_copy during data insertion.  This allows to test
-- the validation of some progress reports for COPY FROM where the trigger
-- would fire.
CREATE FUNCTION notice_after_tab_progress_reporting ()
    RETURNS trigger
    AS $$
DECLARE
    report record;
BEGIN
    -- The fields ignored here are the ones that may not remain
    -- consistent across multiple runs.  The sizes reported may differ
    -- across platforms, so just check if these are strictly positive.
    WITH progress_data AS (
        SELECT
            relid::regclass::text AS relname,
            command,
            type,
            bytes_processed > 0 AS has_bytes_processed,
            bytes_total > 0 AS has_bytes_total,
            tuples_processed,
            tuples_excluded,
            tuples_skipped
        FROM
            pg_stat_progress_copy
        WHERE
            pid = pg_backend_pid()
    )
    SELECT
    INTO
        report (to_jsonb (r)) AS value
    FROM
        progress_data r;
    RAISE info 'progress: %', report.value::text;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER check_after_tab_progress_reporting
    AFTER INSERT ON tab_progress_reporting
    FOR EACH statement
    EXECUTE FUNCTION notice_after_tab_progress_reporting ();

-- Generate COPY FROM report with PIPE.
copy tab_progress_reporting from stdin;
sharon	25	(15,12)	1000	sam
sam	30	(10,5)	2000	bill
bill	20	(11,10)	1000	sharon
\.
-- Generate COPY FROM report with FILE, with some excluded tuples.
TRUNCATE tab_progress_reporting;

\set filename :abs_srcdir '/data/emp.data'
COPY tab_progress_reporting
FROM
    :'filename'
WHERE (salary < 2000);

-- Generate COPY FROM report with PIPE, with some skipped tuples.
copy tab_progress_reporting from stdin(on_error ignore);
sharon	x	(15,12)	x	sam
sharon	25	(15,12)	1000	sam
sharon	y	(15,12)	x	sam
\.
DROP TRIGGER check_after_tab_progress_reporting ON tab_progress_reporting;

DROP FUNCTION notice_after_tab_progress_reporting ();

DROP TABLE tab_progress_reporting;

-- Test header matching feature
CREATE TABLE header_copytest (
    a int,
    b int,
    c text
);

-- Make sure it works with dropped columns
ALTER TABLE header_copytest
    DROP COLUMN c;

ALTER TABLE header_copytest
    ADD COLUMN c text;

COPY header_copytest TO stdout WITH (
    header MATCH);

copy header_copytest from stdin with (header wrong_choice);
\.
-- works
copy header_copytest from stdin with (header match);
a	b	c
1	2	foo
\.
copy header_copytest (c, a, b) from stdin with (header match);
c	a	b
bar	3	4
\.

copy header_copytest from stdin with (header match, format csv);
a,b,c
5,6,baz
\.
-- errors
copy header_copytest (c, b, a) from stdin with (header match);
a	b	c
1	2	foo
\.

copy header_copytest from stdin with (header match);
a	b	\N
1	2	foo
\.
copy header_copytest from stdin with (header match);
a	b
1	2
\.
copy header_copytest from stdin with (header match);
a	b	c	d
1	2	foo	bar
\.
copy header_copytest from stdin with (header match);
a	b	d
1	2	foo
\.
SELECT
    *
FROM
    header_copytest
ORDER BY
    a;

-- Drop an extra column, in the middle of the existing set.
ALTER TABLE header_copytest
    DROP COLUMN b;

-- works
copy header_copytest (c, a) from stdin with (header match);
c	a
foo	7
\.

copy header_copytest (a, c) from stdin with (header match);
a	c
8	foo
\.

-- errors
copy header_copytest from stdin with (header match);
a	........pg.dropped.2........	c
1	2	foo
\.
copy header_copytest (a, c) from stdin with (header match);
a	c	b
1	foo	2
\.

SELECT
    *
FROM
    header_copytest
ORDER BY
    a;

DROP TABLE header_copytest;

-- test COPY with overlong column defaults
CREATE temp TABLE oversized_column_default (
    col1 varchar(5) DEFAULT 'more than 5 chars',
    col2 varchar(5)
);

-- normal COPY should work
copy oversized_column_default from stdin;
\.
-- error if the column is excluded
copy oversized_column_default (col2) from stdin;
\.

-- error if the DEFAULT option is given
copy oversized_column_default from stdin (default '');
\.
DROP TABLE oversized_column_default;

--
-- Create partitioned table that does not allow bulk insertions, to test bugs
-- related to the reuse of BulkInsertState across partitions (only done when
-- not using bulk insert).  Switching between partitions often makes it more
-- likely to encounter these bugs, so we just switch on roughly every insert
-- by having an even/odd number partition and inserting evenly distributed
-- data.
--
CREATE TABLE parted_si (
    id int NOT NULL,
    data text NOT NULL,
    -- prevent use of bulk insert by having a volatile function
    rand float8 NOT NULL DEFAULT random()
)
PARTITION BY LIST ((id % 2));

CREATE TABLE parted_si_p_even PARTITION OF parted_si
FOR VALUES IN (0);

CREATE TABLE parted_si_p_odd PARTITION OF parted_si
FOR VALUES IN (1);

-- Test that bulk relation extension handles reusing a single BulkInsertState
-- across partitions.  Without the fix applied, this reliably reproduces
-- #18130 unless shared_buffers is extremely small (preventing any use of bulk
-- relation extension). See
-- https://postgr.es/m/18130-7a86a7356a75209d%40postgresql.org
-- https://postgr.es/m/257696.1695670946%40sss.pgh.pa.us
\set filename :abs_srcdir '/data/desc.data'
COPY parted_si (id, data)
FROM
    :'filename';

-- An earlier bug (see commit b1ecb9b3fcf) could end up using a buffer from
-- the wrong partition. This test is *not* guaranteed to trigger that bug, but
-- does so when shared_buffers is small enough.  To test if we encountered the
-- bug, check that the partition condition isn't violated.
SELECT
    tableoid::regclass,
    id % 2 = 0 is_even,
    count(*)
FROM
    parted_si
GROUP BY
    1,
    2
ORDER BY
    1;

DROP TABLE parted_si;

-- ensure COPY FREEZE errors for foreign tables
BEGIN;
CREATE FOREIGN data wrapper copytest_wrapper;
CREATE SERVER copytest_server FOREIGN data wrapper copytest_wrapper;
CREATE FOREIGN TABLE copytest_foreign_table (
    a int)
SERVER copytest_server;
copy copytest_foreign_table from stdin (freeze);
1
\.
ROLLBACK;

-- Tests for COPY TO with materialized views.
-- COPY TO should fail for an unpopulated materialized view
-- but succeed for a populated one.
CREATE MATERIALIZED VIEW copytest_mv AS
SELECT
    1 AS id WITH NO DATA;

COPY copytest_mv (id)
TO stdout WITH (
    header);

REFRESH MATERIALIZED VIEW copytest_mv;

COPY copytest_mv (id)
TO stdout WITH (
    header);

DROP MATERIALIZED VIEW copytest_mv;

-- Tests for COPY TO with partitioned tables.
-- The child table pp_2 has a different column order than the root table pp.
-- Check if COPY TO exports tuples as the root table's column order.
CREATE TABLE pp (
    id int,
    val int
)
PARTITION BY RANGE (id);

CREATE TABLE pp_1 (
    val int,
    id int
)
PARTITION BY RANGE (id);

CREATE TABLE pp_2 (
    id int,
    val int
)
PARTITION BY RANGE (id);

ALTER TABLE pp ATTACH PARTITION pp_1
FOR VALUES FROM (1) TO (5);

ALTER TABLE pp ATTACH PARTITION pp_2
FOR VALUES FROM (5) TO (10);

CREATE TABLE pp_15 PARTITION OF pp_1
FOR VALUES FROM (1) TO (5);

CREATE TABLE pp_510 PARTITION OF pp_2
FOR VALUES FROM (5) TO (10);

INSERT INTO pp
SELECT
    g,
    10 + g
FROM
    generate_series(1, 6) g;

COPY pp TO stdout (header);

DROP TABLE PP;

-- Check if COPY TO handles dropped columns in partitions.
CREATE TABLE pp_dropcol (
    id int,
    val int
)
PARTITION BY RANGE (id);

CREATE TABLE pp_dropcol_1 (
    dropme int,
    id int,
    val int
);

ALTER TABLE pp_dropcol_1
    DROP COLUMN dropme;

ALTER TABLE pp_dropcol ATTACH PARTITION pp_dropcol_1
FOR VALUES FROM (1) TO (10);

INSERT INTO pp_dropcol
VALUES
    (1, 11),
    (2, 12);

COPY pp_dropcol TO stdout (header);

DROP TABLE pp_dropcol;

