\getenv abs_srcdir PG_ABS_SRCDIR

\set filename :abs_srcdir '/data/onek.data'
COPY onek
FROM
    :'filename';

\startpipeline
SELECT
    1 \bind \sendpipeline

\endpipeline
\dconfig work_mem
\restrict abc
SELECT
    2;

SELECT
    current_setting('server_encoding') <> 'UTF8' AS skip_test \gset

\if :skip_test
\quit
\endif
SELECT
    $1,
    $2 \parse stmt3

\bind_named stmt3 1 2 \g

\close_prepared stmt3
SELECT
    3;

\a
\t
SELECT
    4;

\d+x tbl_heap
\d+x
