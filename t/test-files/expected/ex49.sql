-- Round-trip non-ASCII data through xpath().
DO $$
DECLARE
    xml_declaration text := '<?xml version="1.0" encoding="ISO-8859-1"?>';
    degree_symbol text;
    res xml[];
BEGIN
    -- Per the documentation, except when the server encoding is UTF8, xpath()
    -- may not work on non-ASCII data.  The untranslatable_character and
    -- undefined_function traps below, currently dead code, will become relevant
    -- if we remove this limitation.
    IF current_setting('server_encoding') <> 'UTF8' THEN
        RAISE LOG 'skip: encoding % unsupported for xpath', current_setting('server_encoding');
        RETURN;
    END IF;
    degree_symbol := convert_from('\xc2b0', 'UTF8');
    res := xpath('text()', (xml_declaration || '<x>' || degree_symbol || '</x>')::xml);
    IF degree_symbol <> res[1]::text THEN
        RAISE 'expected % (%), got % (%)', degree_symbol, convert_to(degree_symbol, 'UTF8'), res[1], convert_to(res[1]::text, 'UTF8');
    END IF;
EXCEPTION
    -- character with byte sequence 0xc2 0xb0 in encoding "UTF8" has no equivalent in encoding "LATIN8"
    WHEN untranslatable_character
        -- default conversion function for encoding "UTF8" to "MULE_INTERNAL" does not exist
        OR undefined_function
        -- unsupported XML feature
        OR feature_not_supported THEN
        RAISE LOG 'skip: %', SQLERRM;
END
$$;

CREATE TRIGGER invalid_trig
    INSTEAD OF UPDATE ON main_view
    FOR EACH ROW
    WHEN (OLD.a <> NEW.a)
    EXECUTE PROCEDURE view_trigger ('instead_of_upd');

--
-- PARALLEL
--
-- Serializable isolation would disable parallel query, so explicitly use an
-- arbitrary other level.
BEGIN ISOLATION level REPEATABLE read;
-- encourage use of parallel plans
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET max_parallel_workers_per_gather = 4;
--
-- Test write operations that has an underlying query that is eligble
-- for parallel plans
--
EXPLAIN (
    COSTS OFF
) CREATE TABLE parallel_write AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
CREATE TABLE parallel_write AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP TABLE parallel_write;
EXPLAIN (
    COSTS OFF
)
SELECT
    length(stringu1) INTO parallel_write
FROM
    tenk1
GROUP BY
    length(stringu1);
SELECT
    length(stringu1) INTO parallel_write
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP TABLE parallel_write;
EXPLAIN (
    COSTS OFF
) CREATE MATERIALIZED VIEW parallel_mat_view AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
CREATE MATERIALIZED VIEW parallel_mat_view AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
DROP MATERIALIZED VIEW parallel_mat_view;
PREPARE prep_stmt AS
SELECT
    length(stringu1)
FROM
    tenk1
GROUP BY
    length(stringu1);
EXPLAIN (
    COSTS OFF
) CREATE TABLE parallel_write AS
EXECUTE prep_stmt;
CREATE TABLE parallel_write AS
EXECUTE prep_stmt;
DROP TABLE parallel_write;
ROLLBACK;

SELECT
    first_value(unique1) OVER (ORDER BY four ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING EXCLUDE GROUP),
    unique1,
    four
FROM
    tenk1
WHERE
    unique1 < 10;

CREATE AGGREGATE my_avg (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = avg_finalfn
);

CREATE AGGREGATE my_sum_init (int4) (
    STYPE = avg_state,
    SFUNC = avg_transfn,
    FINALFUNC = sum_finalfn,
    INITCOND = '(10,0)'
);

CREATE AGGREGATE balk (int4) (
    SFUNC = balkifnull (int8, int4),
    STYPE = int8,
    PARALLEL = SAFE,
    INITCOND = '0'
);

CREATE AGGREGATE balk (int4) (
    SFUNC = int4_sum(int8, int4),
    STYPE = int8,
    COMBINEFUNC = balkifnull (int8, int8),
    PARALLEL = SAFE,
    INITCOND = '0'
);

CREATE AGGREGATE myaggn08a (
    BASETYPE = anyelement,
    SFUNC = tf2p,
    STYPE = int[],
    FINALFUNC = ffnp,
    INITCOND = '{}'
);

CREATE MATERIALIZED VIEW v AS
SELECT
    sum(x) AS x,
    sum(y) AS y,
    sum(z) AS z
FROM
    t;

CREATE MATERIALIZED VIEW v WITH (storage_param = 1) AS
SELECT
    sum(x) AS x,
    sum(y) AS y,
    sum(z) AS z
FROM
    t;

