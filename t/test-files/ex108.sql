DROP OPERATOR IF EXISTS @#@ (int, int);
CREATE OPERATOR @#@
        (leftarg = int8, rightarg = int8, procedure = int8xor);
DROP OPERATOR @#@ (int8, int8);

-- language
DROP LANGUAGE l;
CREATE FUNCTION f(int) RETURNS int AS $$ SELECT 1; $$ LANGUAGE sql;
SELECT 2;
CREATE FUNCTION g(int) RETURNS int AS $$ SELECT 1 $$ LANGUAGE sql;
CREATE LANGUAGE alt_lang1 HANDLER plpgsql_call_handler;
ALTER LANGUAGE alt_lang1 RENAME TO alt_lang2;
DROP LANGUAGE alt_lang2;
