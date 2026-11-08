-- comment one
SELECT 1;
SELECT a -- inline comment
FROM t;
CREATE TABLE r(id int);
\set VERBOSITY terse \\ -- suppress machine-dependent details
REINDEX TABLE r;
\set VERBOSITY default
DROP TABLE r;
\d r
SELECT 1 \gset
SELECT a, -- first column
       b
FROM t WHERE a = 1 -- condition
;
