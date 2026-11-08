--
-- Tests for psql features that aren't closely connected to any
-- specific server features
--
-- \set
-- fail: invalid name
\set invalid/name foo
-- fail: invalid value for special variable
\set AUTOCOMMIT foo
\set FETCH_COUNT foo
-- check handling of built-in boolean variable
\echo :ON_ERROR_ROLLBACK
\set ON_ERROR_ROLLBACK
\echo :ON_ERROR_ROLLBACK
\set ON_ERROR_ROLLBACK foo
\echo :ON_ERROR_ROLLBACK
\set ON_ERROR_ROLLBACK on
\echo :ON_ERROR_ROLLBACK
\unset ON_ERROR_ROLLBACK
\echo :ON_ERROR_ROLLBACK
-- \g and \gx
SELECT
    1 AS one,
    2 AS two \g

\gx

SELECT
    3 AS three,
    4 AS four \gx

\g

-- \gx should work in FETCH_COUNT mode too
\set FETCH_COUNT 1
SELECT
    1 AS one,
    2 AS two \g

\gx

SELECT
    3 AS three,
    4 AS four \gx

\g

\unset FETCH_COUNT
-- \g/\gx with pset options
SELECT
    1 AS one,
    2 AS two \g (format=csv csv_fieldsep='\t')

\g

SELECT
    1 AS one,
    2 AS two \gx (title='foo bar')

\g

-- \parse (extended query protocol)
\parse

SELECT
    1 \parse ''

SELECT
    2 \parse stmt1

SELECT
    $1 \parse stmt2

SELECT
    $1,
    $2 \parse stmt3

-- \bind_named (extended query protocol)
\bind_named
\bind_named '' \g

\bind_named stmt1 \g

\bind_named stmt2 'foo' \g

\bind_named stmt3 'foo' 'bar' \g

-- Repeated calls.  The second call generates an error, cleaning up the
-- statement name set by the first call.
\bind_named stmt4
\bind_named
\g

-- Last \bind_named wins
\bind_named stmt2 'foo' \bind_named stmt3 'foo2' 'bar2' \g

-- Multiple \g calls mean multiple executions
\bind_named stmt2 'foo3' \g \bind_named stmt3 'foo4' 'bar4' \g

-- \close_prepared (extended query protocol)
\close_prepared
\close_prepared ''
\close_prepared stmt2
\close_prepared stmt2
SELECT
    name,
    statement
FROM
    pg_prepared_statements
ORDER BY
    name;

-- \bind (extended query protocol)
SELECT
    1 \bind \g

SELECT
    $1 \bind 'foo' \g

SELECT
    $1,
    $2 \bind 'foo' 'bar' \g

-- last \bind wins
SELECT
    $1::int AS col \bind 'foo' \bind 2 \g

-- Multiple \g calls mean multiple executions
SELECT
    $1::int AS col \bind 1 \g \bind 2 \g

-- errors
-- parse error
SELECT
    foo \bind \g

-- tcop error
SELECT
    1\;

SELECT
    2 \bind \g

-- bind error
SELECT
    $1,
    $2 \bind 'foo' \g

-- bind_named error
\bind_named stmt2 'baz' \g

\bind_named stmt3 'baz' \g

-- \gset
SELECT
    10 AS test01,
    20 AS test02,
    'Hello' AS test03 \gset pref01_

\echo :pref01_test01 :pref01_test02 :pref01_test03
-- should fail: bad variable name
SELECT
    10 AS "bad name" \gset

SELECT
    97 AS "EOF",
    'ok' AS _foo \gset IGNORE

\echo :IGNORE_foo :IGNOREEOF
-- multiple backslash commands in one line
SELECT
    1 AS x,
    2 AS y \gset pref01_ \\ 

\echo :pref01_x
SELECT
    3 AS x,
    4 AS y \gset pref01_ 

\echo :pref01_x 
\echo :pref01_y
SELECT
    5 AS x,
    6 AS y \gset pref01_ \\ \g 

\echo :pref01_x :pref01_y
SELECT
    7 AS x,
    8 AS y \g \gset pref01_ 

\echo :pref01_x :pref01_y
-- NULL should unset the variable
\set var2 xyz
SELECT
    1 AS var1,
    NULL AS var2,
    3 AS var3 \gset

\echo :var1 :var2 :var3
-- \gset requires just one tuple
SELECT
    10 AS test01,
    20 AS test02
FROM
    generate_series(1, 3) \gset

SELECT
    10 AS test01,
    20 AS test02
FROM
    generate_series(1, 0) \gset

-- \gset returns no tuples
SELECT
    a
FROM
    generate_series(1, 10) AS a
WHERE
    a = 11 \gset

\echo :ROW_COUNT
-- \gset should work in FETCH_COUNT mode too
\set FETCH_COUNT 1
SELECT
    1 AS x,
    2 AS y \gset pref01_ \\ 

\echo :pref01_x
SELECT
    3 AS x,
    4 AS y \gset pref01_ 

\echo :pref01_x 
\echo :pref01_y
SELECT
    10 AS test01,
    20 AS test02
FROM
    generate_series(1, 3) \gset

SELECT
    10 AS test01,
    20 AS test02
FROM
    generate_series(1, 0) \gset

\unset FETCH_COUNT
-- \gdesc
SELECT
    NULL AS zero,
    1 AS one,
    2.0 AS two,
    'three' AS three,
    $1 AS four,
    sin($2) AS five,
    'foo'::varchar(4) AS six,
    CURRENT_DATE AS now \gdesc

-- should work with tuple-returning utilities, such as EXECUTE
PREPARE test AS
SELECT
    1 AS first,
    2 AS second;

EXECUTE test \gdesc

EXPLAIN EXECUTE test \gdesc

-- should fail cleanly - syntax error
SELECT
    1 + \gdesc

-- check behavior with empty results
SELECT
    \gdesc

CREATE TABLE bububu (
    a int) \gdesc

-- subject command should not have executed
TABLE bububu;

-- fail
-- query buffer should remain unchanged
SELECT
    1 AS x,
    'Hello',
    2 AS y,
    TRUE AS "dirty\name" \gdesc

\g

-- all on one line
SELECT
    3 AS x,
    'Hello',
    4 AS y,
    TRUE AS "dirty\name" \gdesc \g

-- test for server bug #17983 with empty statement in aborted transaction
SET search_path = DEFAULT;

BEGIN;
bogus;
;
\gdesc
ROLLBACK;

-- \gexec
CREATE TEMPORARY TABLE gexec_test (
    a int,
    b text,
    c date,
    d float
);

SELECT
    format('create index on gexec_test(%I)', attname)
FROM
    pg_attribute
WHERE
    attrelid = 'gexec_test'::regclass
    AND attnum > 0
ORDER BY
    attnum \gexec

-- \gexec should work in FETCH_COUNT mode too
-- (though the fetch limit applies to the executed queries not the meta query)
\set FETCH_COUNT 1
SELECT
    'select 1 as ones',
    'select x.y, x.y*2 as double from generate_series(1,4) as x(y)'
UNION ALL
SELECT
    'drop table gexec_test',
    NULL
UNION ALL
SELECT
    'drop table gexec_test',
    'select ''2000-01-01''::date as party_over' \gexec

\unset FETCH_COUNT
-- \setenv, \getenv
-- ensure MYVAR isn't set
\setenv MYVAR
-- in which case, reading it doesn't change the target
\getenv res MYVAR

\echo :res
-- now set it
\setenv MYVAR 'environment value'
\getenv res MYVAR

\echo :res
-- show all pset options
\pset
-- test the simple display substitution settings
PREPARE q AS
SELECT
    NULL AS n,
    TRUE AS t,
    FALSE AS f;

\pset null '(null)'
\pset display_true 'true'
\pset display_false 'false'
EXECUTE q;

\pset null
\pset display_true
\pset display_false
EXECUTE q;

\pset null ''
\pset display_true 't'
\pset display_false 'f'
EXECUTE q;

DEALLOCATE q;

-- test multi-line headers, wrapping, and newline indicators
-- in aligned, unaligned, and wrapped formats
PREPARE q AS
SELECT
    array_to_string(array_agg(repeat('x', 2 * n)), E'\n') AS "ab

c",
    array_to_string(array_agg(repeat('y', 20 - 2 * n)), E'\n') AS "a
bc"
FROM
    generate_series(1, 10) AS n (n)
GROUP BY
    n > 1
ORDER BY
    n > 1;

\pset linestyle ascii
\pset expanded off
\pset columns 40
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset expanded on
\pset columns 20
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset linestyle old-ascii
\pset expanded off
\pset columns 40
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset expanded on
\pset columns 20
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

DEALLOCATE q;

-- test single-line header and data
PREPARE q AS
SELECT
    repeat('x', 2 * n) AS "0123456789abcdef",
    repeat('y', 20 - 2 * n) AS "0123456789"
FROM
    generate_series(1, 10) AS n;

\pset linestyle ascii
\pset expanded off
\pset columns 40
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset expanded on
\pset columns 30
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset expanded on
\pset columns 20
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset linestyle old-ascii
\pset expanded off
\pset columns 40
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset expanded on
\pset border 0
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 1
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

\pset border 2
\pset format unaligned
EXECUTE q;

\pset format aligned
EXECUTE q;

\pset format wrapped
EXECUTE q;

DEALLOCATE q;

-- expanded output with short-width columns
\pset border 2
\pset expanded on
CREATE TABLE psql_short_tab (
    a int,
    b int
);

INSERT INTO psql_short_tab
VALUES
    (10, 20),
    (30, 40);

\pset format aligned
SELECT
    *
FROM
    psql_short_tab;

\pset format wrapped
SELECT
    *
FROM
    psql_short_tab;

DROP TABLE psql_short_tab;

\pset linestyle ascii
\pset border 1
-- support table for output-format tests (useful to create a footer)
CREATE TABLE psql_serial_tab (
    id serial
);

-- test header/footer/tuples_only behavior in aligned/unaligned/wrapped cases
\pset format aligned
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\dfx exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
-- empty table is a special case for this format
SELECT
    1
WHERE
    FALSE;

\pset format unaligned
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset format wrapped
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
-- check conditional am display
\pset expanded off
CREATE SCHEMA tableam_display;

CREATE ROLE regress_display_role;

ALTER SCHEMA tableam_display OWNER TO regress_display_role;

SET search_path TO tableam_display;

CREATE ACCESS METHOD heap_psql TYPE TABLE HANDLER heap_tableam_handler;

SET ROLE TO regress_display_role;

-- Use only relations with a physical size of zero.
CREATE TABLE tbl_heap_psql (
    f1 int,
    f2 char(100))
USING heap_psql;

CREATE TABLE tbl_heap (
    f1 int,
    f2 char(100))
USING heap;

CREATE VIEW view_heap_psql AS
SELECT
    f1
FROM
    tbl_heap_psql;

CREATE MATERIALIZED VIEW mat_view_heap_psql USING heap_psql AS
SELECT
    f1
FROM
    tbl_heap_psql;

\d+ tbl_heap_psql
\d+ tbl_heap
\set HIDE_TABLEAM off
\d+ tbl_heap_psql
\d+ tbl_heap
-- AM is displayed for tables, indexes and materialized views.
\d+
\dt+
\dm+
-- But not for views and sequences.
\dv+
\set HIDE_TABLEAM on
\d+
-- \d with 'x' enables expanded mode, but only without a pattern
\d+x tbl_heap
\d+x
RESET ROLE;

RESET search_path;

DROP SCHEMA tableam_display CASCADE;

DROP ACCESS METHOD heap_psql;

DROP ROLE regress_display_role;

-- test numericlocale (as best we can without control of psql's locale)
\pset format aligned
\pset expanded off
\pset numericlocale true
SELECT
    n,
    - n AS m,
    n * 111 AS x,
    '1e90'::float8 AS f
FROM
    generate_series(0, 3) n;

\pset numericlocale false
-- test asciidoc output format
\pset format asciidoc
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some|text' AS "a|title",
    '        ' AS "empty ",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset expanded on
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

DEALLOCATE q;

-- test csv output format
\pset format csv
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some"text' AS "a""title",
    E'  <foo>\n<bar>' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
EXECUTE q;

\pset expanded on
EXECUTE q;

DEALLOCATE q;

-- special cases
\pset expanded off
SELECT
    'comma,comma' AS comma,
    'semi;semi' AS semi;

\pset csv_fieldsep ';'
SELECT
    'comma,comma' AS comma,
    'semi;semi' AS semi;

SELECT
    '\.' AS data;

\pset csv_fieldsep '.'
SELECT
    '\' AS d1,
    '' AS d2;

-- illegal csv separators
\pset csv_fieldsep ''
\pset csv_fieldsep '\0'
\pset csv_fieldsep '\n'
\pset csv_fieldsep '\r'
\pset csv_fieldsep '"'
\pset csv_fieldsep ',,'
\pset csv_fieldsep ','
-- test html output format
\pset format html
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some"text' AS "a&title",
    E'  <foo>\n<bar>' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset tableattr foobar
EXECUTE q;

\pset tableattr
\pset expanded on
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset tableattr foobar
EXECUTE q;

\pset tableattr
DEALLOCATE q;

-- test latex output format
\pset format latex
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some\more_text' AS "a$title",
    E'  #<foo>%&^~|\n{bar}' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset border 3
EXECUTE q;

\pset expanded on
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset border 3
EXECUTE q;

DEALLOCATE q;

-- test latex-longtable output format
\pset format latex-longtable
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some\more_text' AS "a$title",
    E'  #<foo>%&^~|\n{bar}' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset border 3
EXECUTE q;

\pset tableattr lr
EXECUTE q;

\pset tableattr
\pset expanded on
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset border 3
EXECUTE q;

\pset tableattr lr
EXECUTE q;

\pset tableattr
DEALLOCATE q;

-- test troff-ms output format
\pset format troff-ms
\pset border 1
\pset expanded off
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
\pset expanded on
\d psql_serial_tab_id_seq
\pset tuples_only true
\df exp
\pset tuples_only false
PREPARE q AS
SELECT
    'some\text' AS "a\title",
    E'  <foo>\n<bar>' AS "junk",
    '   ' AS "empty",
    n AS int
FROM
    generate_series(1, 2) AS n;

\pset expanded off
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

\pset expanded on
\pset border 0
EXECUTE q;

\pset border 1
EXECUTE q;

\pset border 2
EXECUTE q;

DEALLOCATE q;

-- check ambiguous format requests
\pset format a
\pset format l
-- clean up after output format tests
DROP TABLE psql_serial_tab;

\pset format aligned
\pset expanded off
\pset border 1
-- \echo and allied features
\echo this is a test
\echo -n without newline
\echo with -n newline
\echo '-n' with newline
\set foo bar
\echo foo = :foo
\qecho this is a test
\qecho foo = :foo
\warn this is a test
\warn foo = :foo
-- tests for \if ... \endif
\if true
SELECT
    'okay';

SELECT
    'still okay';

\else
NOT okay;

still NOT okay \endif
-- at this point query buffer should still have last valid line
\g

-- \if should work okay on part of a query
SELECT
    \if true
    42 \else
    (bogus \endif
        forty_two;

SELECT
    \if false \\ (bogus \else \\ 42 \endif \\ forty_two;
    -- test a large nested if using a variety of true-equivalents
    \if true
    \if 1
    \if yes
    \if on
    \echo 'all true'
    \else
    \echo 'should not print #1-1'
    \endif
    \else
    \echo 'should not print #1-2'
    \endif
    \else
    \echo 'should not print #1-3'
    \endif
    \else
    \echo 'should not print #1-4'
    \endif
    -- test a variety of false-equivalents in an if/elif/else structure
    \if false
    \echo 'should not print #2-1'
    \elif 0
    \echo 'should not print #2-2'
    \elif no
    \echo 'should not print #2-3'
    \elif off
    \echo 'should not print #2-4'
    \else
    \echo 'all false'
    \endif
    -- test true-false elif after initial true branch
    \if true
    \echo 'should print #2-5'
    \elif true
    \echo 'should not print #2-6'
    \elif false
    \echo 'should not print #2-7'
    \else
    \echo 'should not print #2-8'
    \endif
    -- test simple true-then-else
    \if true
    \echo 'first thing true'
    \else
    \echo 'should not print #3-1'
    \endif
    -- test simple false-true-else
    \if false
    \echo 'should not print #4-1'
    \elif true
    \echo 'second thing true'
    \else
    \echo 'should not print #5-1'
    \endif
    -- invalid boolean expressions are false
    \if invalid boolean expression
    \echo 'will not print #6-1'
    \else
    \echo 'will print anyway #6-2'
    \endif
    -- test un-matched endif
    \endif
    -- test un-matched else
    \else
    -- test un-matched elif
    \elif
    -- test double-else error
    \if true
    \else
    \else
    \endif
    -- test elif out-of-order
    \if false
    \else
    \elif
    \endif
    -- test if-endif matching in a false branch
    \if false
    \if false
    \echo 'should not print #7-1'
    \else
    \echo 'should not print #7-2'
    \endif
    \echo 'should not print #7-3'
    \else
    \echo 'should print #7-4'
    \endif
    -- show that vars and backticks are not expanded when ignoring extra args
    \set foo bar
    \echo :foo :'foo' :"foo"
    \pset fieldsep | `nosuchcommand` :foo :'foo' :"foo"
    -- show that vars and backticks are not expanded and commands are ignored
    -- when in a false if-branch
    \set try_to_quit '\\q'
    \if false
    :try_to_quit \echo `nosuchcommand` :foo :'foo' :"foo"
    \pset fieldsep | `nosuchcommand` :foo :'foo' :"foo"
    \a
    SELECT
        $1 \bind 1 \g

\bind_named stmt1 1 2 \g

\C arg1
\c arg1 arg2 arg3 arg4
\cd arg1
\close_prepared stmt1
\conninfo
\copy arg1 arg2 arg3 arg4 arg5 arg6
\copyright
SELECT
    1 AS one,
    2,
    3 \crosstabview

\dt arg1
\e arg1 arg2
\ef whole_line
\ev whole_line
\echo arg1 arg2 arg3 arg4 arg5
\echo arg1
\encoding arg1
\endpipeline
\errverbose
\f arg1
\flush
\flushrequest
\g arg1

\gx arg1

\gexec

\getresults

SELECT
    1 AS one \gset

\h
\?
\html
\i arg1
\ir arg1
\l arg1
\lo arg1 arg2
\lo_list
\o arg1
\p
SELECT
    1 \parse

\password arg1
\prompt arg1 arg2
\pset arg1 arg2
\q
\reset
\restrict test
\s arg1
\sendpipeline

\set arg1 arg2 arg3 arg4 arg5 arg6 arg7
\setenv arg1 arg2
\sf whole_line
\sv whole_line
\startpipeline
\syncpipeline
\t arg1
\T arg1
\timing arg1
\unrestrict not_valid
\unset arg1
\w arg1
\watch arg1 arg2

\x arg1
-- \else here is eaten as part of OT_FILEPIPE argument
\w |/no/such/file \else
-- \endif here is eaten as part of whole-line argument
\! whole_line \endif
\z
\else
\echo 'should print #8-1'
\endif
-- test that begin/end matching ignores to-be-ignored text
CREATE FUNCTION silly_function (int)
    RETURNS int
BEGIN ATOMIC
    SELECT
        $1;
\if false
END \endif
;
END;
\sf silly_function(int)
DROP FUNCTION silly_function (int);
-- :{?...} defined variable test
\set i 1
\if :{?i}
\echo '#9-1 ok, variable i is defined'
\else
\echo 'should not print #9-2'
\endif
\if :{?no_such_variable}
\echo 'should not print #10-1'
\else
\echo '#10-2 ok, variable no_such_variable is not defined'
\endif
SELECT
    : {?i} AS i_is_defined;
SELECT
    NOT : {?no_such_var} AS no_such_var_is_not_defined;
-- SHOW_CONTEXT
\set SHOW_CONTEXT never
DO $$
BEGIN
    RAISE NOTICE 'foo';
    RAISE EXCEPTION 'bar';
END
$$;
\set SHOW_CONTEXT errors
DO $$
BEGIN
    RAISE NOTICE 'foo';
    RAISE EXCEPTION 'bar';
END
$$;
\set SHOW_CONTEXT always
DO $$
BEGIN
    RAISE NOTICE 'foo';
    RAISE EXCEPTION 'bar';
END
$$;
-- test printing and clearing the query buffer
SELECT
    1;
\p
SELECT
    2 \r
    \p
    SELECT
        3 \p
    UNION
    SELECT
        4 \p
    UNION
    SELECT
        5
    ORDER BY
        1;
\r
\p
-- tests for special result variables
-- working query, 2 rows selected
SELECT
    1 AS stuff
UNION
SELECT
    2;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
-- syntax error
SELECT
    1
UNION
;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
\echo 'last error message:' :LAST_ERROR_MESSAGE
\echo 'last error code:' :LAST_ERROR_SQLSTATE
-- empty query
;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
-- must have kept previous values
\echo 'last error message:' :LAST_ERROR_MESSAGE
\echo 'last error code:' :LAST_ERROR_SQLSTATE
-- other query error
DROP TABLE this_table_does_not_exist;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
\echo 'last error message:' :LAST_ERROR_MESSAGE
\echo 'last error code:' :LAST_ERROR_SQLSTATE
-- nondefault verbosity error settings (except verbose, which is too unstable)
\set VERBOSITY terse
SELECT
    1
UNION
;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'last error message:' :LAST_ERROR_MESSAGE
\set VERBOSITY sqlstate
SELECT
    1 / 0;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'last error message:' :LAST_ERROR_MESSAGE
\set VERBOSITY default
-- working \gdesc
SELECT
    3 AS three,
    4 AS four \gdesc
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
-- \gdesc with an error
SELECT
    4 AS \gdesc
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
\echo 'last error message:' :LAST_ERROR_MESSAGE
\echo 'last error code:' :LAST_ERROR_SQLSTATE
-- check row count for a query with chunked results
\set FETCH_COUNT 10
SELECT
    unique2
FROM
    tenk1
ORDER BY
    unique2
LIMIT 19;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
-- chunked results with an error after the first chunk
-- (we must disable parallel query here, else the behavior is timing-dependent)
SET debug_parallel_query = OFF;
SELECT
    1 / (15 - unique2)
FROM
    tenk1
ORDER BY
    unique2
LIMIT 19;
\echo 'error:' :ERROR
\echo 'error code:' :SQLSTATE
\echo 'number of rows:' :ROW_COUNT
\echo 'last error message:' :LAST_ERROR_MESSAGE
\echo 'last error code:' :LAST_ERROR_SQLSTATE
RESET debug_parallel_query;
\unset FETCH_COUNT
CREATE SCHEMA testpart;
CREATE ROLE regress_partitioning_role;
ALTER SCHEMA testpart OWNER TO regress_partitioning_role;
SET ROLE TO regress_partitioning_role;
-- run test inside own schema and hide other partitions
SET search_path TO testpart;
CREATE TABLE testtable_apple (
    logdate date
);
CREATE TABLE testtable_orange (
    logdate date
);
CREATE INDEX testtable_apple_index ON testtable_apple (logdate);
CREATE INDEX testtable_orange_index ON testtable_orange (logdate);
CREATE TABLE testpart_apple (
    logdate date
)
PARTITION BY RANGE (logdate);
CREATE TABLE testpart_orange (
    logdate date
)
PARTITION BY RANGE (logdate);
CREATE INDEX testpart_apple_index ON testpart_apple (logdate);
CREATE INDEX testpart_orange_index ON testpart_orange (logdate);
-- only partition related object should be displayed
\dP test*apple*
\dPt test*apple*
\dPi test*apple*
DROP TABLE testtable_apple;
DROP TABLE testtable_orange;
DROP TABLE testpart_apple;
DROP TABLE testpart_orange;
CREATE TABLE parent_tab (
    id int
)
PARTITION BY RANGE (id);
CREATE INDEX parent_index ON parent_tab (id);
CREATE TABLE child_0_10 PARTITION OF parent_tab
FOR VALUES FROM (0) TO (10);
CREATE TABLE child_10_20 PARTITION OF parent_tab
FOR VALUES FROM (10) TO (20);
CREATE TABLE child_20_30 PARTITION OF parent_tab
FOR VALUES FROM (20) TO (30);
INSERT INTO parent_tab
    VALUES (generate_series(0, 29));
CREATE TABLE child_30_40 PARTITION OF parent_tab
FOR VALUES FROM (30) TO (40)
PARTITION BY RANGE (id);
CREATE TABLE child_30_35 PARTITION OF child_30_40
FOR VALUES FROM (30) TO (35);
CREATE TABLE child_35_40 PARTITION OF child_30_40
FOR VALUES FROM (35) TO (40);
INSERT INTO parent_tab
    VALUES (generate_series(30, 39));
\dPt
\dPi
\dP testpart.*
\dP
\dPtn
\dPin
\dPn
\dPn testpart.*
DROP TABLE parent_tab CASCADE;
DROP SCHEMA testpart;
SET search_path TO DEFAULT;
SET ROLE TO DEFAULT;
DROP ROLE regress_partitioning_role;
-- \d on toast table (use pg_statistic's toast table, which has a known name)
\d pg_toast.pg_toast_2619
-- check printing info about access methods
\dA
\dA *
\dA h*
\dA foo
\dA foo bar
\dA+
\dA+ *
\dA+ h*
\dA+ foo
\dAc brin pg*.oid*
\dAf spgist
\dAf btree int4
\dAo+ btree array_ops|float_ops
\dAo * pg_catalog.jsonb_path_ops
\dAp+ btree float_ops
\dApx+ btree time_ops
\dAp * pg_catalog.uuid_ops
-- check \dconfig
SET work_mem = 10240;
\dconfig work_mem
\dconfig+ work*
RESET work_mem;
-- check \df, \do with argument specifications
\df *sqrt
\df *sqrt num*
\df int*pl
\df int*pl int4
\df int*pl * pg_catalog.int8
\df acl* aclitem[]
\df has_database_privilege oid text
\df has_database_privilege oid text -
\dfa bit* small*
\df *._pg_expandarray
\do - pg_catalog.int4
\do && anyarray *
-- check \df+
-- we have to use functions with a predictable owner name, so make a role
CREATE ROLE regress_psql_user superuser;
BEGIN;
SET session AUTHORIZATION regress_psql_user;
CREATE FUNCTION psql_df_internal (float8)
    RETURNS float8
    LANGUAGE internal
    IMMUTABLE parallel safe STRICT
    AS 'dsin';
CREATE FUNCTION psql_df_sql (x integer)
    RETURNS integer
    SECURITY DEFINER
BEGIN ATOMIC
    SELECT
        x + 1;
END;
CREATE FUNCTION psql_df_plpgsql ()
    RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN;
END;
$$;
COMMENT ON FUNCTION psql_df_plpgsql () IS 'some comment';
\df+ psql_df_*
ROLLBACK;

DROP ROLE regress_psql_user;

-- check \sf
\sf information_schema._pg_index_position
\sf+ information_schema._pg_index_position
\sf+ interval_pl_time
\sf ts_debug(text);
\sf+ ts_debug(text)
-- AUTOCOMMIT
CREATE TABLE ac_test (
    a int
);

\set AUTOCOMMIT off
INSERT INTO ac_test
    VALUES (1);

COMMIT;

SELECT
    *
FROM
    ac_test;

COMMIT;

INSERT INTO ac_test
    VALUES (2);

ROLLBACK;

SELECT
    *
FROM
    ac_test;

COMMIT;

BEGIN;
INSERT INTO ac_test
    VALUES (3);
COMMIT;

SELECT
    *
FROM
    ac_test;

COMMIT;

BEGIN;
INSERT INTO ac_test
    VALUES (4);
ROLLBACK;

SELECT
    *
FROM
    ac_test;

COMMIT;

\set AUTOCOMMIT on
DROP TABLE ac_test;

SELECT
    *
FROM
    ac_test;

-- should be gone now
-- ON_ERROR_ROLLBACK
\set ON_ERROR_ROLLBACK on
CREATE TABLE oer_test (
    a int
);

BEGIN;
INSERT INTO oer_test
    VALUES (1);
INSERT INTO oer_test
    VALUES ('foo');
INSERT INTO oer_test
    VALUES (3);
COMMIT;

SELECT
    *
FROM
    oer_test;

BEGIN;
INSERT INTO oer_test
    VALUES (4);
ROLLBACK;

SELECT
    *
FROM
    oer_test;

BEGIN;
INSERT INTO oer_test
    VALUES (5);
COMMIT
    AND CHAIN;

INSERT INTO oer_test
    VALUES (6);

COMMIT;

SELECT
    *
FROM
    oer_test;

DROP TABLE oer_test;

\set ON_ERROR_ROLLBACK off
-- ECHO errors
\set ECHO errors
SELECT
    *
FROM
    notexists;

\set ECHO all
--
-- combined queries
--
CREATE FUNCTION warn (msg text)
    RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'warn %', msg;
    RETURN TRUE;
END
$$;

-- show both
SELECT
    1 AS one\;

SELECT
    warn ('1.5')\;

SELECT
    2 AS two;

-- \gset applies to last query only
SELECT
    3 AS three\;

SELECT
    warn ('3.5')\;

SELECT
    4 AS four \gset

\echo :three :four
-- syntax error stops all processing
SELECT
    5\;

SELECT
    6 +\;

SELECT
    warn ('6.5')\;

SELECT
    7;

-- with aborted transaction, stop on first error
BEGIN\;
SELECT
    8 AS eight\;
SELECT
    9 / 0 AS nine\;
ROLLBACK\;

SELECT
    10 AS ten;

-- close previously aborted transaction
ROLLBACK;

-- miscellaneous SQL commands
-- (non SELECT output is sent to stderr, thus is not shown in expected results)
SELECT
    'ok' AS "begin"\;

CREATE TABLE psql_comics (
    s text
)\;

INSERT INTO psql_comics
VALUES
    ('Calvin'),
    ('hobbes')\;

COPY psql_comics FROM STDIN \;
UPDATE psql_comics SET s = 'Hobbes' WHERE s = 'hobbes' \;
DELETE FROM psql_comics WHERE s = 'Moe' \;
COPY psql_comics TO STDOUT \;
TRUNCATE psql_comics \;
DROP TABLE psql_comics \;
SELECT 'ok' AS "done" ;
Moe
Susie
\.
\set SHOW_ALL_RESULTS off
SELECT
    1 AS one\;

SELECT
    warn ('1.5')\;

SELECT
    2 AS two;

\set SHOW_ALL_RESULTS on
DROP FUNCTION warn (TEXT);

--
-- \g with file
--
\getenv abs_builddir PG_ABS_BUILDDIR

\set g_out_file :abs_builddir '/results/psql-output1'
CREATE TEMPORARY TABLE reload_output (
    lineno int NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

SELECT
    1 AS a \g :g_out_file

COPY reload_output (line)
FROM
    :'g_out_file';

SELECT
    2 AS b\;

SELECT
    3 AS c\;

SELECT
    4 AS d \g :g_out_file

COPY reload_output (line)
FROM
    :'g_out_file';

COPY (
    SELECT
        'foo')
TO STDOUT\;

COPY (
    SELECT
        'bar')
TO STDOUT \g :g_out_file

COPY reload_output (line)
FROM
    :'g_out_file';

SELECT
    line
FROM
    reload_output
ORDER BY
    lineno;

TRUNCATE TABLE reload_output;

--
-- \o with file
--
\set o_out_file :abs_builddir '/results/psql-output2'
\o :o_out_file
SELECT
    max(unique1)
FROM
    onek;

SELECT
    1 AS a\;

SELECT
    2 AS b\;

SELECT
    3 AS c;

-- COPY TO file
-- The data goes to :g_out_file and the status to :o_out_file
\set QUIET false
COPY (
    SELECT
        unique1
    FROM
        onek
    ORDER BY
        unique1
    LIMIT 10)
    TO :'g_out_file';

-- DML command status
UPDATE
    onek
SET
    unique1 = unique1
WHERE
    FALSE;

\set QUIET true
\o
-- Check the contents of the files generated.
COPY reload_output (line)
FROM
    :'g_out_file';

SELECT
    line
FROM
    reload_output
ORDER BY
    lineno;

TRUNCATE TABLE reload_output;

COPY reload_output (line)
FROM
    :'o_out_file';

SELECT
    line
FROM
    reload_output
ORDER BY
    lineno;

TRUNCATE TABLE reload_output;

-- Multiple COPY TO STDOUT with output file
\o :o_out_file
-- The data goes to :o_out_file with no status generated.
COPY (
    SELECT
        'foo1')
TO STDOUT\;

COPY (
    SELECT
        'bar1')
TO STDOUT;

-- Combination of \o and \g file with multiple COPY queries.
COPY (
    SELECT
        'foo2')
TO STDOUT\;

COPY (
    SELECT
        'bar2')
TO STDOUT \g :g_out_file

\o
-- Check the contents of the files generated.
COPY reload_output (line)
FROM
    :'g_out_file';

SELECT
    line
FROM
    reload_output
ORDER BY
    lineno;

TRUNCATE TABLE reload_output;

COPY reload_output (line)
FROM
    :'o_out_file';

SELECT
    line
FROM
    reload_output
ORDER BY
    lineno;

DROP TABLE reload_output;

-- \copy must skip in-line data, even if the issued COPY command fails.
\copy no_such_table from stdin
foo
\echo this should not get output
bar
\echo this should not get output
\.
\echo this should get output
--
-- AUTOCOMMIT and combined queries
--
\set AUTOCOMMIT off
\echo '# AUTOCOMMIT:' :AUTOCOMMIT
-- BEGIN is now implicit
CREATE TABLE foo (
    s text
)\;

ROLLBACK;

CREATE TABLE foo (
    s text
)\;

INSERT INTO foo (s)
VALUES
    ('hello'),
    ('world')\;

COMMIT;

DROP TABLE foo\;

ROLLBACK;

-- table foo is still there
SELECT
    *
FROM
    foo
ORDER BY
    1\;

DROP TABLE foo\;

COMMIT;

\set AUTOCOMMIT on
\echo '# AUTOCOMMIT:' :AUTOCOMMIT
-- BEGIN now explicit for multi-statement transactions
BEGIN\;
CREATE TABLE foo (
    s text
)\;
INSERT INTO foo (s)
VALUES
    ('hello'),
    ('world')\;
COMMIT;

BEGIN\;
DROP TABLE foo\;
ROLLBACK\;

-- implicit transactions
SELECT
    *
FROM
    foo
ORDER BY
    1\;

DROP TABLE foo;

--
-- test ON_ERROR_ROLLBACK and combined queries
--
CREATE FUNCTION psql_error (msg text)
    RETURNS boolean
    AS $$
BEGIN
    RAISE EXCEPTION 'error %', msg;
END;
$$
LANGUAGE plpgsql;

\set ON_ERROR_ROLLBACK on
\echo '# ON_ERROR_ROLLBACK:' :ON_ERROR_ROLLBACK
\echo '# AUTOCOMMIT:' :AUTOCOMMIT
BEGIN;
CREATE TABLE bla (
    s NO_SUCH_TYPE
);
-- fails
CREATE TABLE bla (
    s text
);
-- succeeds
SELECT
    psql_error ('oops!');
-- fails
INSERT INTO bla
VALUES
    ('Calvin'),
    ('Hobbes');
COMMIT;

SELECT
    *
FROM
    bla
ORDER BY
    1;

BEGIN;
INSERT INTO bla
    VALUES ('Susie');
-- succeeds
-- now with combined queries
INSERT INTO bla
    VALUES ('Rosalyn')\;
-- will rollback
SELECT
    'before error' AS show\;
-- will show nevertheless!
SELECT
    psql_error ('boum!')\;
-- failure
SELECT
    'after error' AS noshow;
-- hidden by preceding error
INSERT INTO bla (s)
    VALUES ('Moe')\;
-- will rollback
SELECT
    psql_error ('bam!');
INSERT INTO bla
    VALUES ('Miss Wormwood');
-- succeeds
COMMIT;

SELECT
    *
FROM
    bla
ORDER BY
    1;

-- some with autocommit off
\set AUTOCOMMIT off
\echo '# AUTOCOMMIT:' :AUTOCOMMIT
-- implicit BEGIN
INSERT INTO bla
    VALUES ('Dad');

-- succeeds
SELECT
    psql_error ('bad!');

-- implicit partial rollback
INSERT INTO bla
    VALUES ('Mum')\;

-- will rollback
SELECT
    COUNT(*) AS "#mum"
FROM
    bla
WHERE
    s = 'Mum'\;

-- but be counted here
SELECT
    psql_error ('bad!');

-- implicit partial rollback
COMMIT;

SELECT
    COUNT(*) AS "#mum"
FROM
    bla
WHERE
    s = 'Mum'\;

-- no mum here
SELECT
    *
FROM
    bla
ORDER BY
    1;

COMMIT;

-- reset all
\set AUTOCOMMIT on
\set ON_ERROR_ROLLBACK off
\echo '# final ON_ERROR_ROLLBACK:' :ON_ERROR_ROLLBACK
DROP TABLE bla;

DROP FUNCTION psql_error;

-- check describing invalid multipart names
\dA regression.heap
\dA nonesuch.heap
\dt host.regression.pg_catalog.pg_class
\dt |.pg_catalog.pg_class
\dt nonesuch.pg_catalog.pg_class
\da host.regression.pg_catalog.sum
\da +.pg_catalog.sum
\da nonesuch.pg_catalog.sum
\dAc nonesuch.brin
\dAc regression.brin
\dAf nonesuch.brin
\dAf regression.brin
\dAo nonesuch.brin
\dAo regression.brin
\dAp nonesuch.brin
\dAp regression.brin
\db nonesuch.pg_default
\db regression.pg_default
\dc host.regression.public.conversion
\dc (.public.conversion
\dc nonesuch.public.conversion
\dC host.regression.pg_catalog.int8
\dC ).pg_catalog.int8
\dC nonesuch.pg_catalog.int8
\dd host.regression.pg_catalog.pg_class
\dd [.pg_catalog.pg_class
\dd nonesuch.pg_catalog.pg_class
\dD host.regression.public.gtestdomain1
\dD ].public.gtestdomain1
\dD nonesuch.public.gtestdomain1
\ddp host.regression.pg_catalog.pg_class
\ddp {.pg_catalog.pg_class
\ddp nonesuch.pg_catalog.pg_class
\dE host.regression.public.ft
\dE }.public.ft
\dE nonesuch.public.ft
\di host.regression.public.tenk1_hundred
\di ..public.tenk1_hundred
\di nonesuch.public.tenk1_hundred
\dm host.regression.public.mvtest_bb
\dm ^.public.mvtest_bb
\dm nonesuch.public.mvtest_bb
\ds host.regression.public.check_seq
\ds regression|mydb.public.check_seq
\ds nonesuch.public.check_seq
\dt host.regression.public.b_star
\dt regres+ion.public.b_star
\dt nonesuch.public.b_star
\dv host.regression.public.shoe
\dv regress(ion).public.shoe
\dv nonesuch.public.shoe
\des nonesuch.server
\des regression.server
\des nonesuch.server
\des regression.server
\des nonesuch.username
\des regression.username
\dew nonesuch.fdw
\dew regression.fdw
\df host.regression.public.namelen
\df regres[qrstuv]ion.public.namelen
\df nonesuch.public.namelen
\dF host.regression.pg_catalog.arabic
\dF regres{1,2}ion.pg_catalog.arabic
\dF nonesuch.pg_catalog.arabic
\dFd host.regression.pg_catalog.arabic_stem
\dFd regres?ion.pg_catalog.arabic_stem
\dFd nonesuch.pg_catalog.arabic_stem
\dFp host.regression.pg_catalog.default
\dFp ^regression.pg_catalog.default
\dFp nonesuch.pg_catalog.default
\dFt host.regression.pg_catalog.ispell
\dFt regression$.pg_catalog.ispell
\dFt nonesuch.pg_catalog.ispell
\dg nonesuch.pg_database_owner
\dg regression.pg_database_owner
\dL host.regression.plpgsql
\dL *.plpgsql
\dL nonesuch.plpgsql
\dn host.regression.public
\dn """".public
\dn nonesuch.public
\do host.regression.public.!=-
\do "regression|mydb".public.!=-
\do nonesuch.public.!=-
\dO host.regression.pg_catalog.POSIX
\dO .pg_catalog.POSIX
\dO nonesuch.pg_catalog.POSIX
\dp host.regression.public.a_star
\dp "regres+ion".public.a_star
\dp nonesuch.public.a_star
\dP host.regression.public.mlparted
\dP "regres(sion)".public.mlparted
\dP nonesuch.public.mlparted
\drds nonesuch.lc_messages
\drds regression.lc_messages
\dRp public.mypub
\dRp regression.mypub
\dRs public.mysub
\dRs regression.mysub
\dT host.regression.public.widget
\dT "regression{1,2}".public.widget
\dT nonesuch.public.widget
\dx regression.plpgsql
\dx nonesuch.plpgsql
\dX host.regression.public.func_deps_stat
\dX "^regression$".public.func_deps_stat
\dX nonesuch.public.func_deps_stat
\dy regression.myevt
\dy nonesuch.myevt
-- check that dots within quoted name segments are not counted
\dA "no.such.access.method"
\dt "no.such.table.relation"
\da "no.such.aggregate.function"
\dAc "no.such.operator.class"
\dAf "no.such.operator.family"
\dAo "no.such.operator.of.operator.family"
\dAp "no.such.operator.support.function.of.operator.family"
\db "no.such.tablespace"
\dc "no.such.conversion"
\dC "no.such.cast"
\dd "no.such.object.description"
\dD "no.such.domain"
\ddp "no.such.default.access.privilege"
\di "no.such.index.relation"
\dm "no.such.materialized.view"
\ds "no.such.relation"
\dt "no.such.relation"
\dv "no.such.relation"
\des "no.such.foreign.server"
\dew "no.such.foreign.data.wrapper"
\df "no.such.function"
\dF "no.such.text.search.configuration"
\dFd "no.such.text.search.dictionary"
\dFp "no.such.text.search.parser"
\dFt "no.such.text.search.template"
\dg "no.such.role"
\dL "no.such.language"
\dn "no.such.schema"
\do "no.such.operator"
\dO "no.such.collation"
\dp "no.such.access.privilege"
\dP "no.such.partitioned.relation"
\drds "no.such.setting"
\dRp "no.such.publication"
\dRs "no.such.subscription"
\dT "no.such.data.type"
\dx "no.such.installed.extension"
\dX "no.such.extended.statistics"
\dy "no.such.event.trigger"
-- again, but with dotted schema qualifications.
\dA "no.such.schema"."no.such.access.method"
\dt "no.such.schema"."no.such.table.relation"
\da "no.such.schema"."no.such.aggregate.function"
\dAc "no.such.schema"."no.such.operator.class"
\dAf "no.such.schema"."no.such.operator.family"
\dAo "no.such.schema"."no.such.operator.of.operator.family"
\dAp "no.such.schema"."no.such.operator.support.function.of.operator.family"
\db "no.such.schema"."no.such.tablespace"
\dc "no.such.schema"."no.such.conversion"
\dC "no.such.schema"."no.such.cast"
\dd "no.such.schema"."no.such.object.description"
\dD "no.such.schema"."no.such.domain"
\ddp "no.such.schema"."no.such.default.access.privilege"
\di "no.such.schema"."no.such.index.relation"
\dm "no.such.schema"."no.such.materialized.view"
\ds "no.such.schema"."no.such.relation"
\dt "no.such.schema"."no.such.relation"
\dv "no.such.schema"."no.such.relation"
\des "no.such.schema"."no.such.foreign.server"
\dew "no.such.schema"."no.such.foreign.data.wrapper"
\df "no.such.schema"."no.such.function"
\dF "no.such.schema"."no.such.text.search.configuration"
\dFd "no.such.schema"."no.such.text.search.dictionary"
\dFp "no.such.schema"."no.such.text.search.parser"
\dFt "no.such.schema"."no.such.text.search.template"
\dg "no.such.schema"."no.such.role"
\dL "no.such.schema"."no.such.language"
\do "no.such.schema"."no.such.operator"
\dO "no.such.schema"."no.such.collation"
\dp "no.such.schema"."no.such.access.privilege"
\dP "no.such.schema"."no.such.partitioned.relation"
\drds "no.such.schema"."no.such.setting"
\dRp "no.such.schema"."no.such.publication"
\dRs "no.such.schema"."no.such.subscription"
\dT "no.such.schema"."no.such.data.type"
\dx "no.such.schema"."no.such.installed.extension"
\dX "no.such.schema"."no.such.extended.statistics"
\dy "no.such.schema"."no.such.event.trigger"
-- again, but with current database and dotted schema qualifications.
\dt regression."no.such.schema"."no.such.table.relation"
\da regression."no.such.schema"."no.such.aggregate.function"
\dc regression."no.such.schema"."no.such.conversion"
\dC regression."no.such.schema"."no.such.cast"
\dd regression."no.such.schema"."no.such.object.description"
\dD regression."no.such.schema"."no.such.domain"
\di regression."no.such.schema"."no.such.index.relation"
\dm regression."no.such.schema"."no.such.materialized.view"
\ds regression."no.such.schema"."no.such.relation"
\dt regression."no.such.schema"."no.such.relation"
\dv regression."no.such.schema"."no.such.relation"
\df regression."no.such.schema"."no.such.function"
\dF regression."no.such.schema"."no.such.text.search.configuration"
\dFd regression."no.such.schema"."no.such.text.search.dictionary"
\dFp regression."no.such.schema"."no.such.text.search.parser"
\dFt regression."no.such.schema"."no.such.text.search.template"
\do regression."no.such.schema"."no.such.operator"
\dO regression."no.such.schema"."no.such.collation"
\dp regression."no.such.schema"."no.such.access.privilege"
\dP regression."no.such.schema"."no.such.partitioned.relation"
\dT regression."no.such.schema"."no.such.data.type"
\dX regression."no.such.schema"."no.such.extended.statistics"
-- again, but with dotted database and dotted schema qualifications.
\dt "no.such.database"."no.such.schema"."no.such.table.relation"
\da "no.such.database"."no.such.schema"."no.such.aggregate.function"
\dc "no.such.database"."no.such.schema"."no.such.conversion"
\dC "no.such.database"."no.such.schema"."no.such.cast"
\dd "no.such.database"."no.such.schema"."no.such.object.description"
\dD "no.such.database"."no.such.schema"."no.such.domain"
\ddp "no.such.database"."no.such.schema"."no.such.default.access.privilege"
\di "no.such.database"."no.such.schema"."no.such.index.relation"
\dm "no.such.database"."no.such.schema"."no.such.materialized.view"
\ds "no.such.database"."no.such.schema"."no.such.relation"
\dt "no.such.database"."no.such.schema"."no.such.relation"
\dv "no.such.database"."no.such.schema"."no.such.relation"
\df "no.such.database"."no.such.schema"."no.such.function"
\dF "no.such.database"."no.such.schema"."no.such.text.search.configuration"
\dFd "no.such.database"."no.such.schema"."no.such.text.search.dictionary"
\dFp "no.such.database"."no.such.schema"."no.such.text.search.parser"
\dFt "no.such.database"."no.such.schema"."no.such.text.search.template"
\do "no.such.database"."no.such.schema"."no.such.operator"
\dO "no.such.database"."no.such.schema"."no.such.collation"
\dp "no.such.database"."no.such.schema"."no.such.access.privilege"
\dP "no.such.database"."no.such.schema"."no.such.partitioned.relation"
\dT "no.such.database"."no.such.schema"."no.such.data.type"
\dX "no.such.database"."no.such.schema"."no.such.extended.statistics"
-- check \drg and \du
CREATE ROLE regress_du_role0;

CREATE ROLE regress_du_role1;

CREATE ROLE regress_du_role2;

CREATE ROLE regress_du_admin;

GRANT regress_du_role0 TO regress_du_admin WITH ADMIN TRUE;

GRANT regress_du_role1 TO regress_du_admin WITH ADMIN TRUE;

GRANT regress_du_role2 TO regress_du_admin WITH ADMIN TRUE;

GRANT regress_du_role0 TO regress_du_role1 WITH ADMIN TRUE,
INHERIT TRUE,
SET TRUE GRANTED BY
    regress_du_admin;

GRANT regress_du_role0 TO regress_du_role2 WITH ADMIN TRUE,
INHERIT FALSE,
SET FALSE GRANTED BY
    regress_du_admin;

GRANT regress_du_role1 TO regress_du_role2 WITH ADMIN TRUE,
INHERIT FALSE,
SET TRUE GRANTED BY
    regress_du_admin;

GRANT regress_du_role0 TO regress_du_role1 WITH ADMIN FALSE,
INHERIT TRUE,
SET FALSE GRANTED BY
    regress_du_role1;

GRANT regress_du_role0 TO regress_du_role2 WITH ADMIN FALSE,
INHERIT TRUE,
SET TRUE GRANTED BY
    regress_du_role1;

GRANT regress_du_role0 TO regress_du_role1 WITH ADMIN FALSE,
INHERIT FALSE,
SET TRUE GRANTED BY
    regress_du_role2;

GRANT regress_du_role0 TO regress_du_role2 WITH ADMIN FALSE,
INHERIT FALSE,
SET FALSE GRANTED BY
    regress_du_role2;

\drg regress_du_role*
\du regress_du_role*
DROP ROLE regress_du_role0;

DROP ROLE regress_du_role1;

DROP ROLE regress_du_role2;

DROP ROLE regress_du_admin;

-- Test display of empty privileges.
BEGIN;
-- Create an owner for tested objects because output contains owner name.
CREATE ROLE regress_zeropriv_owner;
SET LOCAL ROLE regress_zeropriv_owner;
CREATE DOMAIN regress_zeropriv_domain AS int;
REVOKE ALL ON DOMAIN regress_zeropriv_domain FROM CURRENT_USER, PUBLIC;
\dD+ regress_zeropriv_domain
CREATE PROCEDURE regress_zeropriv_proc ()
LANGUAGE sql
AS ''
;
    REVOKE ALL ON PROCEDURE regress_zeropriv_proc () FROM CURRENT_USER, PUBLIC;
    \df+ regress_zeropriv_proc
    CREATE TABLE regress_zeropriv_tbl (
        a int
    );
    REVOKE ALL ON TABLE regress_zeropriv_tbl FROM CURRENT_USER;
    \dp regress_zeropriv_tbl
    CREATE TYPE regress_zeropriv_type AS (
        a int
);
    REVOKE ALL ON TYPE regress_zeropriv_type FROM CURRENT_USER, PUBLIC;
    \dT+ regress_zeropriv_type
    ROLLBACK;
    -- Test display of default privileges with \pset null.
    CREATE TABLE defprivs (
        a int
    );
    \pset null '(default)'
    \z defprivs
    \zx defprivs
    \pset null 
'' DROP TABLE defprivs;
