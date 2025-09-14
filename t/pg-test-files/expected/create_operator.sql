--
-- CREATE_OPERATOR
--
CREATE OPERATOR ## (
    LEFTARG = path,
    RIGHTARG = path,
    FUNCTION = path_inter,
    commutator = ##
);

CREATE OPERATOR <% (
    LEFTARG = point,
    RIGHTARG = widget,
    PROCEDURE = pt_in_widget,
    commutator = >%,
    negator = >=%
);

CREATE OPERATOR @#@ (
    RIGHTARG = int8, -- left unary
    PROCEDURE = numeric_fac
);

CREATE OPERATOR #@# (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac
);

CREATE OPERATOR #%# (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac
);

-- Test operator created above
SELECT
    point '(1,2)' <% widget '(0,0,3)' AS t,
    point '(1,2)' <% widget '(0,0,1)' AS f;

-- Test comments
COMMENT ON OPERATOR ## ## ## (int4,
    NONE) IS 'bad right unary';

-- => is disallowed now
CREATE OPERATOR => (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac
);

-- lexing of <=, >=, <>, != has a number of edge cases
-- (=> is tested elsewhere)
-- this is legal because ! is not allowed in sql ops
CREATE OPERATOR !=- (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac
);

SELECT
    2 != -;

-- make sure lexer returns != as <> even in edge cases
SELECT
    2 !=
    /**/
    1,
    2 !=
    /**/
    2;

SELECT
    2 != -- comment to be removed by psql
    1;

DO $$
-- use DO to protect -- from psql
DECLARE
    r boolean;
BEGIN
    EXECUTE $e$ select 2 !=-- comment
      1 $e$ INTO r;
    RAISE info 'r = %', r;
END;
$$;

-- check that <= etc. followed by more operator characters are returned
-- as the correct token with correct precedence
SELECT
    TRUE <> - 1 BETWEEN 1 AND 1;

-- BETWEEN has prec. above <> but below Op
SELECT
    FALSE <>
    /**/
    1 BETWEEN 1 AND 1;

SELECT
    FALSE <= -1 BETWEEN 1 AND 1;

SELECT
    FALSE >= -1 BETWEEN 1 AND 1;

SELECT
    2 <=
    /**/
    3,
    3 >=
    /**/
    2,
    2 <>
    /**/
    3;

SELECT
    3 <=
    /**/
    2,
    2 >=
    /**/
    3,
    2 <>
    /**/
    2;

-- Should fail. CREATE OPERATOR requires USAGE on SCHEMA
BEGIN TRANSACTION;
CREATE ROLE regress_rol_op1;
CREATE SCHEMA schema_op1;
GRANT USAGE ON SCHEMA schema_op1 TO PUBLIC;
REVOKE USAGE ON SCHEMA schema_op1 FROM regress_rol_op1;
SET ROLE regress_rol_op1;
CREATE OPERATOR schema_op1. # * # (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac
);
ROLLBACK;
-- Should fail. SETOF type functions not allowed as argument (testing leftarg)
BEGIN TRANSACTION;
CREATE OPERATOR "#*#" (
    LEFTARG = SETOF int8,
    PROCEDURE = numeric_fac
);
ROLLBACK;
-- Should fail. SETOF type functions not allowed as argument (testing rightarg)
BEGIN TRANSACTION;
CREATE OPERATOR "#*#" (
    RIGHTARG = SETOF int8,
    PROCEDURE = numeric_fac
);
ROLLBACK;
-- Should work. Sample text-book case
BEGIN TRANSACTION;
CREATE OR REPLACE FUNCTION fn_op2 (boolean, boolean)
    RETURNS boolean
    AS $$
    SELECT
        NULL::boolean;
$$
LANGUAGE sql
IMMUTABLE;
CREATE OPERATOR === (
    LEFTARG = boolean,
    RIGHTARG = boolean,
    PROCEDURE = fn_op2,
    COMMUTATOR = ===,
    NEGATOR = !==,
    RESTRICT = contsel,
    JOIN = contjoinsel,
    SORT1,
    SORT2,
    LTCMP,
    GTCMP,
    HASHES,
    MERGES
);
ROLLBACK;
-- Should fail. Invalid attribute
CREATE OPERATOR #@%# (
    LEFTARG = int8, -- right unary
    PROCEDURE = numeric_fac,
    invalid_att = int8
);
-- Should fail. At least leftarg or rightarg should be mandatorily specified
CREATE OPERATOR #@%# (
    PROCEDURE = numeric_fac
);
-- Should fail. Procedure should be mandatorily specified
CREATE OPERATOR #@%# (
    LEFTARG = int8
);
-- Should fail. CREATE OPERATOR requires USAGE on TYPE
BEGIN TRANSACTION;
CREATE ROLE regress_rol_op3;
CREATE TYPE type_op3 AS ENUM (
    'new',
    'open',
    'closed'
);
CREATE FUNCTION fn_op3 (type_op3, int8)
    RETURNS int8
    AS $$
    SELECT
        NULL::int8;
$$
LANGUAGE sql
IMMUTABLE;
REVOKE USAGE ON TYPE type_op3 FROM regress_rol_op3;
REVOKE USAGE ON TYPE type_op3 FROM PUBLIC;
-- Need to do this so that regress_rol_op3 is not allowed USAGE via PUBLIC
SET ROLE regress_rol_op3;
CREATE OPERATOR "#*#" (
    LEFTARG = type_op3,
    RIGHTARG = int8,
    PROCEDURE = fn_op3
);
ROLLBACK;

-- Should fail. CREATE OPERATOR requires USAGE on TYPE (need to check separately for rightarg)
BEGIN TRANSACTION;
CREATE ROLE regress_rol_op4;
CREATE TYPE type_op4 AS ENUM (
    'new',
    'open',
    'closed'
);
CREATE FUNCTION fn_op4 (int8, type_op4)
    RETURNS int8
    AS $$
    SELECT
        NULL::int8;
$$
LANGUAGE sql
IMMUTABLE;
REVOKE USAGE ON TYPE type_op4 FROM regress_rol_op4;
REVOKE USAGE ON TYPE type_op4 FROM PUBLIC;
-- Need to do this so that regress_rol_op3 is not allowed USAGE via PUBLIC
SET ROLE regress_rol_op4;
CREATE OPERATOR "#*#" (
    LEFTARG = int8,
    RIGHTARG = type_op4,
    PROCEDURE = fn_op4
);
ROLLBACK;

-- Should fail. CREATE OPERATOR requires EXECUTE on function
BEGIN TRANSACTION;
CREATE ROLE regress_rol_op5;
CREATE TYPE type_op5 AS ENUM (
    'new',
    'open',
    'closed'
);
CREATE FUNCTION fn_op5 (int8, int8)
    RETURNS int8
    AS $$
    SELECT
        NULL::int8;
$$
LANGUAGE sql
IMMUTABLE;
REVOKE EXECUTE ON FUNCTION fn_op5 (int8, int8) FROM regress_rol_op5;
REVOKE EXECUTE ON FUNCTION fn_op5 (int8, int8) FROM PUBLIC;
-- Need to do this so that regress_rol_op3 is not allowed EXECUTE via PUBLIC
SET ROLE regress_rol_op5;
CREATE OPERATOR "#*#" (
    LEFTARG = int8,
    RIGHTARG = int8,
    PROCEDURE = fn_op5
);
ROLLBACK;

-- Should fail. CREATE OPERATOR requires USAGE on return TYPE
BEGIN TRANSACTION;
CREATE ROLE regress_rol_op6;
CREATE TYPE type_op6 AS ENUM (
    'new',
    'open',
    'closed'
);
CREATE FUNCTION fn_op6 (int8, int8)
    RETURNS type_op6
    AS $$
    SELECT
        NULL::type_op6;
$$
LANGUAGE sql
IMMUTABLE;
REVOKE USAGE ON TYPE type_op6 FROM regress_rol_op6;
REVOKE USAGE ON TYPE type_op6 FROM PUBLIC;
-- Need to do this so that regress_rol_op3 is not allowed USAGE via PUBLIC
SET ROLE regress_rol_op6;
CREATE OPERATOR "#*#" (
    LEFTARG = int8,
    RIGHTARG = int8,
    PROCEDURE = fn_op6
);
ROLLBACK;

-- invalid: non-lowercase quoted identifiers
CREATE OPERATOR === (
    "Leftarg" = box,
    "Rightarg" = box,
    "Procedure" = area_equal_function,
    "Commutator" = == =,
    "Negator" = != =,
    "Restrict" = area_restriction_function,
    "Join" = area_join_function,
    "Hashes",
    "Merges"
);

