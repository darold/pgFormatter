CREATE FUNCTION f (text)
    RETURNS text
    AS :'regresslib'
    LANGUAGE C
    STRICT IMMUTABLE;

SELECT
    f ('/');

SELECT
    f ('/a');

CREATE FUNCTION g (int)
    RETURNS int
    AS :"x"
    LANGUAGE C;

CREATE FUNCTION my_int_eq (int, int)
    RETURNS bool
    LANGUAGE internal
    STRICT
    AS $$int4eq$$;

SELECT
    :"col"
FROM
    :"tab";

