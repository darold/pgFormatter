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
-- \gset
SELECT
    10 AS test01,
    20 AS test02,
    'Hello' AS test03 \gset pref01_

\echo :pref01_test01 :pref01_test02 :pref01_test03
-- should fail: bad variable name
SELECT
    10 AS "bad name" \gset

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
-- show all pset options
\pset
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
-- check conditional tableam display
-- Create a heap2 table am handler with heapam handler
CREATE ACCESS METHOD heap_psql TYPE TABLE HANDLER heap_tableam_handler;

CREATE TABLE tbl_heap_psql (
    f1 int,
    f2 char(100))
USING heap_psql;

CREATE TABLE tbl_heap (
    f1 int,
    f2 char(100))
USING heap;

\d+ tbl_heap_psql
\d+ tbl_heap
\set HIDE_TABLEAM off
\d+ tbl_heap_psql
\d+ tbl_heap
\set HIDE_TABLEAM on
DROP TABLE tbl_heap, tbl_heap_psql;

DROP ACCESS METHOD heap_psql;

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
    \a \C arg1 \c arg1 arg2 arg3 arg4 
    \cd arg1 
    \conninfo
    \copy arg1 arg2 arg3 arg4 arg5 arg6
    \copyright \dt arg1 \e arg1 arg2
    \ef whole_line
    \ev whole_line
    \echo arg1 arg2 arg3 arg4 arg5 
    \echo arg1 
    \encoding arg1 \errverbose
    \g arg1 \gx arg1 \gexec \h 

\html \i arg1 \ir arg1 \l arg1 \lo arg1 arg2
\o arg1 \p 
\password arg1 
\prompt arg1 arg2 
\pset arg1 arg2 
\q
\reset \s arg1 
\set arg1 arg2 arg3 arg4 arg5 arg6 arg7 
\setenv arg1 arg2
\sf whole_line
\sv whole_line
\t arg1 \T arg1 
\timing arg1 
\unset arg1 \w arg1 
\watch arg1 \x arg1

-- \else here is eaten as part of OT_FILEPIPE argument
\w |/no/such/file \else
-- \endif here is eaten as part of whole-line argument
\! whole_line \endif
\else
\echo 'should print #8-1'
\endif
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
-- check row count for a cursor-fetched query
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
-- cursor-fetched query with an error after the first group
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
\unset FETCH_COUNT
CREATE SCHEMA testpart;

CREATE ROLE testrole_partitioning;

ALTER SCHEMA testpart OWNER TO testrole_partitioning;

SET ROLE TO testrole_partitioning;

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

DROP ROLE testrole_partitioning;

