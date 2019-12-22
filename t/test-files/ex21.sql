SELECT 1 as a \gset 
\echo :a \\ SELECT :a; \unset a
SELECT 'test' \g testfile.txt
\! cat testfile.txt
SELECT current_timestamp;
\watch 3

