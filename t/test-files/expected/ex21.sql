SELECT
    1 AS a \gset 

\echo :a \\ SELECT :a; 
\unset a
SELECT
    'test' \g testfile.txt

\! cat testfile.txt
SELECT
    CURRENT_TIMESTAMP;

\watch 3

