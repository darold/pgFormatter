--
-- CREATE_AGGREGATE
--
-- all functions CREATEd
CREATE AGGREGATE newavg (
    SFUNC = int4_avg_accum,
    BASETYPE = int4,
    STYPE = _int8,
    FINALFUNC = int8_avg,
    initcond1 = '{0,0}'
);

-- test comments
COMMENT ON AGGREGATE newavg_wrong (int4) IS 'an agg comment';

COMMENT ON AGGREGATE newavg (int4) IS 'an agg comment';

COMMENT ON AGGREGATE newavg (int4) IS NULL;

-- without finalfunc; test obsolete spellings 'sfunc1' etc
CREATE AGGREGATE newsum (
    SFUNC1 = int4pl,
    BASETYPE = int4,
    STYPE1 = int4,
    initcond1 = '0'
);

-- zero-argument aggregate
CREATE AGGREGATE newcnt (*) (
    SFUNC = int8inc,
    STYPE = int8,
    INITCOND = '0',
    parallel = safe
);

-- old-style spelling of same (except without parallel-safe; that's too new)
CREATE AGGREGATE oldcnt (
    SFUNC = int8inc,
    BASETYPE = 'ANY',
    STYPE = int8,
    INITCOND = '0'
);

-- aggregate that only cares about null/nonnull input
CREATE AGGREGATE newcnt ("any") (
    SFUNC = int8inc_any,
    STYPE = int8,
    INITCOND = '0'
);

COMMENT ON AGGREGATE nosuchagg (*) IS 'should fail';

COMMENT ON AGGREGATE newcnt (*) IS 'an agg(*) comment';

COMMENT ON AGGREGATE newcnt ("any") IS 'an agg(any) comment';

-- multi-argument aggregate
CREATE FUNCTION sum3 (int8, int8, int8)
    RETURNS int8
    AS '
    SELECT
        $1 + $2 + $3;
'
LANGUAGE sql
STRICT IMMUTABLE;

CREATE AGGREGATE sum2 (int8, int8) (
    SFUNC = sum3,
    STYPE = int8,
    INITCOND = '0'
);

-- multi-argument aggregates sensitive to distinct/order, strict/nonstrict
CREATE TYPE aggtype AS (
    a integer,
    b integer,
    c text
);

CREATE FUNCTION aggf_trans (aggtype[], integer, integer, text)
    RETURNS aggtype[]
    AS '
    SELECT
        array_append($1, ROW ($2, $3, $4)::aggtype);
'
LANGUAGE sql
STRICT IMMUTABLE;

CREATE FUNCTION aggfns_trans (aggtype[], integer, integer, text)
    RETURNS aggtype[]
    AS '
    SELECT
        array_append($1, ROW ($2, $3, $4)::aggtype);
'
LANGUAGE sql
IMMUTABLE;

CREATE AGGREGATE aggfstr (integer, integer, text) (
    SFUNC = aggf_trans,
    STYPE = aggtype[],
    INITCOND = '{}'
);

CREATE AGGREGATE aggfns (integer, integer, text) (
    SFUNC = aggfns_trans,
    STYPE = aggtype[],
    SSPACE = 10000,
    INITCOND = '{}'
);

-- variadic aggregate
CREATE FUNCTION least_accum (anyelement, VARIADIC anyarray)
    RETURNS anyelement
    LANGUAGE sql
    AS '
    SELECT
        least ($1, min($2[i]))
    FROM
        generate_subscripts($2, 1) g (i);
';

CREATE AGGREGATE least_agg (VARIADIC items anyarray) (
    STYPE = anyelement,
    SFUNC = least_accum
);

-- test ordered-set aggs using built-in support functions
CREATE AGGREGATE my_percentile_disc (float8 ORDER BY anyelement) (
    STYPE = internal,
    SFUNC = ordered_set_transition,
    FINALFUNC = percentile_disc_final,
    FINALFUNC_EXTRA = TRUE,
    FINALFUNC_MODIFY = READ_WRITE
);

CREATE AGGREGATE my_rank (VARIADIC "any" ORDER BY VARIADIC "any") (
    STYPE = internal,
    SFUNC = ordered_set_transition_multi,
    FINALFUNC = rank_final,
    FINALFUNC_EXTRA = TRUE,
    hypothetical
);

ALTER AGGREGATE my_percentile_disc (float8 ORDER BY anyelement) RENAME TO test_percentile_disc;

ALTER AGGREGATE my_rank (VARIADIC "any" ORDER BY VARIADIC "any") RENAME TO test_rank;

\da test_*
-- moving-aggregate options
CREATE AGGREGATE sumdouble (float8) (
    STYPE = float8,
    SFUNC = float8pl,
    MSTYPE = float8,
    MSFUNC = float8pl,
    MINVFUNC = float8mi
);

-- aggregate combine and serialization functions
-- can't specify just one of serialfunc and deserialfunc
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    SERIALFUNC = numeric_avg_serialize
);

-- serialfunc must have correct parameters
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    SERIALFUNC = numeric_avg_deserialize,
    DESERIALFUNC = numeric_avg_deserialize
);

-- deserialfunc must have correct parameters
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    SERIALFUNC = numeric_avg_serialize,
    DESERIALFUNC = numeric_avg_serialize
);

-- ensure combine function parameters are checked
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    SERIALFUNC = numeric_avg_serialize,
    DESERIALFUNC = numeric_avg_deserialize,
    COMBINEFUNC = int4larger
);

-- ensure create aggregate works.
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    FINALFUNC = numeric_avg,
    SERIALFUNC = numeric_avg_serialize,
    DESERIALFUNC = numeric_avg_deserialize,
    COMBINEFUNC = numeric_avg_combine,
    FINALFUNC_MODIFY = SHAREABLE -- just to test a non-default setting
);

-- Ensure all these functions made it into the catalog
SELECT
    aggfnoid,
    aggtransfn,
    aggcombinefn,
    aggtranstype::regtype,
    aggserialfn,
    aggdeserialfn,
    aggfinalmodify
FROM
    pg_aggregate
WHERE
    aggfnoid = 'myavg'::regproc;

DROP AGGREGATE myavg (numeric);

-- create or replace aggregate
CREATE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    FINALFUNC = numeric_avg
);

CREATE OR REPLACE AGGREGATE myavg (numeric) (
    STYPE = internal,
    SFUNC = numeric_avg_accum,
    FINALFUNC = numeric_avg,
    SERIALFUNC = numeric_avg_serialize,
    DESERIALFUNC = numeric_avg_deserialize,
    COMBINEFUNC = numeric_avg_combine,
    FINALFUNC_MODIFY = SHAREABLE -- just to test a non-default setting
);

-- Ensure all these functions made it into the catalog again
SELECT
    aggfnoid,
    aggtransfn,
    aggcombinefn,
    aggtranstype::regtype,
    aggserialfn,
    aggdeserialfn,
    aggfinalmodify
FROM
    pg_aggregate
WHERE
    aggfnoid = 'myavg'::regproc;

-- can change stype:
CREATE OR REPLACE AGGREGATE myavg (numeric) (
    STYPE = numeric,
    SFUNC = numeric_add
);

SELECT
    aggfnoid,
    aggtransfn,
    aggcombinefn,
    aggtranstype::regtype,
    aggserialfn,
    aggdeserialfn,
    aggfinalmodify
FROM
    pg_aggregate
WHERE
    aggfnoid = 'myavg'::regproc;

-- can't change return type:
CREATE OR REPLACE AGGREGATE myavg (numeric) (
    STYPE = numeric,
    SFUNC = numeric_add,
    FINALFUNC = numeric_out
);

-- can't change to a different kind:
CREATE OR REPLACE AGGREGATE myavg (
ORDER by numeric) (
    STYPE = numeric,
    SFUNC = numeric_add
);

-- can't change plain function to aggregate:
CREATE FUNCTION sum4 (int8, int8, int8, int8)
    RETURNS int8
    AS '
    SELECT
        $1 + $2 + $3 + $4;
'
LANGUAGE sql
STRICT IMMUTABLE;

CREATE OR REPLACE AGGREGATE sum3 (int8, int8, int8) (
    STYPE = int8,
    SFUNC = sum4
);

DROP FUNCTION sum4 (int8, int8, int8, int8);

DROP AGGREGATE myavg (numeric);

-- invalid: bad parallel-safety marking
CREATE AGGREGATE mysum (int) (
    STYPE = int,
    SFUNC = int4pl,
    parallel = pear
);

-- invalid: nonstrict inverse with strict forward function
CREATE FUNCTION float8mi_n (float8, float8)
    RETURNS float8
    AS $$
    SELECT
        $1 - $2;
$$
LANGUAGE SQL;

CREATE AGGREGATE invalidsumdouble (float8) (
    STYPE = float8,
    SFUNC = float8pl,
    MSTYPE = float8,
    MSFUNC = float8pl,
    MINVFUNC = float8mi_n
);

-- invalid: non-matching result types
CREATE FUNCTION float8mi_int (float8, float8)
    RETURNS int
    AS $$
    SELECT
        CAST($1 - $2 AS int);
$$
LANGUAGE SQL;

CREATE AGGREGATE wrongreturntype (float8) (
    STYPE = float8,
    SFUNC = float8pl,
    MSTYPE = float8,
    MSFUNC = float8pl,
    MINVFUNC = float8mi_int
);

-- invalid: non-lowercase quoted identifiers
CREATE AGGREGATE case_agg ( -- old syntax
"Sfunc1" = int4pl, "Basetype" = int4, "Stype1" = int4, "Initcond1" = '0', "Parallel" = safe
);

CREATE AGGREGATE case_agg (float8) (
    "Stype" = internal,
    "Sfunc" = ordered_set_transition,
    "Finalfunc" = percentile_disc_final,
    "Finalfunc_extra" = TRUE,
    "Finalfunc_modify" = READ_WRITE,
    "Parallel" = safe
);

