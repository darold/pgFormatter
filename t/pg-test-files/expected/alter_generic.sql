--
-- Test for ALTER some_object {RENAME TO, OWNER TO, SET SCHEMA}
--
-- Clean up in case a prior regression run failed
SET client_min_messages TO 'warning';

DROP ROLE IF EXISTS regress_alter_generic_user1;

DROP ROLE IF EXISTS regress_alter_generic_user2;

DROP ROLE IF EXISTS regress_alter_generic_user3;

RESET client_min_messages;

CREATE USER regress_alter_generic_user3;

CREATE USER regress_alter_generic_user2;

CREATE USER regress_alter_generic_user1 IN ROLE regress_alter_generic_user3;

CREATE SCHEMA alt_nsp1;

CREATE SCHEMA alt_nsp2;

GRANT ALL ON SCHEMA alt_nsp1, alt_nsp2 TO public;

SET search_path = alt_nsp1, public;

--
-- Function and Aggregate
--
SET SESSION AUTHORIZATION regress_alter_generic_user1;

CREATE FUNCTION alt_func1 (int)
    RETURNS int
    LANGUAGE sql
    AS '
    SELECT
        $1 + 1;
';

CREATE FUNCTION alt_func2 (int)
    RETURNS int
    LANGUAGE sql
    AS '
    SELECT
        $1 - 1;
';

CREATE AGGREGATE alt_agg1 (
    SFUNC1 = int4pl,
    BASETYPE = int4,
    STYPE1 = int4,
    INITCOND = 0
);

CREATE AGGREGATE alt_agg2 (
    SFUNC1 = int4mi,
    BASETYPE = int4,
    STYPE1 = int4,
    INITCOND = 0
);

ALTER AGGREGATE alt_func1 (int) RENAME TO alt_func3;

-- failed (not aggregate)
ALTER AGGREGATE alt_func1 (int) OWNER TO regress_alter_generic_user3;

-- failed (not aggregate)
ALTER AGGREGATE alt_func1 (int) SET SCHEMA alt_nsp2;

-- failed (not aggregate)
ALTER FUNCTION alt_func1 (int) RENAME TO alt_func2;

-- failed (name conflict)
ALTER FUNCTION alt_func1 (int) RENAME TO alt_func3;

-- OK
ALTER FUNCTION alt_func2 (int) OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER FUNCTION alt_func2 (int) OWNER TO regress_alter_generic_user3;

-- OK
ALTER FUNCTION alt_func2 (int) SET SCHEMA alt_nsp1;

-- OK, already there
ALTER FUNCTION alt_func2 (int) SET SCHEMA alt_nsp2;

-- OK
ALTER AGGREGATE alt_agg1 (int) RENAME TO alt_agg2;

-- failed (name conflict)
ALTER AGGREGATE alt_agg1 (int) RENAME TO alt_agg3;

-- OK
ALTER AGGREGATE alt_agg2 (int) OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER AGGREGATE alt_agg2 (int) OWNER TO regress_alter_generic_user3;

-- OK
ALTER AGGREGATE alt_agg2 (int) SET SCHEMA alt_nsp2;

-- OK
SET SESSION AUTHORIZATION regress_alter_generic_user2;

CREATE FUNCTION alt_func1 (int)
    RETURNS int
    LANGUAGE sql
    AS '
    SELECT
        $1 + 2;
';

CREATE FUNCTION alt_func2 (int)
    RETURNS int
    LANGUAGE sql
    AS '
    SELECT
        $1 - 2;
';

CREATE AGGREGATE alt_agg1 (
    SFUNC1 = int4pl,
    BASETYPE = int4,
    STYPE1 = int4,
    INITCOND = 100
);

CREATE AGGREGATE alt_agg2 (
    SFUNC1 = int4mi,
    BASETYPE = int4,
    STYPE1 = int4,
    INITCOND = -100
);

ALTER FUNCTION alt_func3 (int) RENAME TO alt_func4;

-- failed (not owner)
ALTER FUNCTION alt_func1 (int) RENAME TO alt_func4;

-- OK
ALTER FUNCTION alt_func3 (int) OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER FUNCTION alt_func2 (int) OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER FUNCTION alt_func3 (int) SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER FUNCTION alt_func2 (int) SET SCHEMA alt_nsp2;

-- failed (name conflicts)
ALTER AGGREGATE alt_agg3 (int) RENAME TO alt_agg4;

-- failed (not owner)
ALTER AGGREGATE alt_agg1 (int) RENAME TO alt_agg4;

-- OK
ALTER AGGREGATE alt_agg3 (int) OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER AGGREGATE alt_agg2 (int) OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER AGGREGATE alt_agg3 (int) SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER AGGREGATE alt_agg2 (int) SET SCHEMA alt_nsp2;

-- failed (name conflict)
RESET SESSION AUTHORIZATION;

SELECT
    n.nspname,
    proname,
    prorettype::regtype,
    prokind,
    a.rolname
FROM
    pg_proc p,
    pg_namespace n,
    pg_authid a
WHERE
    p.pronamespace = n.oid
    AND p.proowner = a.oid
    AND n.nspname IN ('alt_nsp1', 'alt_nsp2')
ORDER BY
    nspname,
    proname;

--
-- We would test collations here, but it's not possible because the error
-- messages tend to be nonportable.
--
--
-- Conversion
--
SET SESSION AUTHORIZATION regress_alter_generic_user1;

CREATE CONVERSION alt_conv1 FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

CREATE CONVERSION alt_conv2 FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

ALTER CONVERSION alt_conv1 RENAME TO alt_conv2;

-- failed (name conflict)
ALTER CONVERSION alt_conv1 RENAME TO alt_conv3;

-- OK
ALTER CONVERSION alt_conv2 OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER CONVERSION alt_conv2 OWNER TO regress_alter_generic_user3;

-- OK
ALTER CONVERSION alt_conv2 SET SCHEMA alt_nsp2;

-- OK
SET SESSION AUTHORIZATION regress_alter_generic_user2;

CREATE CONVERSION alt_conv1 FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

CREATE CONVERSION alt_conv2 FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

ALTER CONVERSION alt_conv3 RENAME TO alt_conv4;

-- failed (not owner)
ALTER CONVERSION alt_conv1 RENAME TO alt_conv4;

-- OK
ALTER CONVERSION alt_conv3 OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER CONVERSION alt_conv2 OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER CONVERSION alt_conv3 SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER CONVERSION alt_conv2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
RESET SESSION AUTHORIZATION;

SELECT
    n.nspname,
    c.conname,
    a.rolname
FROM
    pg_conversion c,
    pg_namespace n,
    pg_authid a
WHERE
    c.connamespace = n.oid
    AND c.conowner = a.oid
    AND n.nspname IN ('alt_nsp1', 'alt_nsp2')
ORDER BY
    nspname,
    conname;

--
-- Foreign Data Wrapper and Foreign Server
--
CREATE FOREIGN DATA WRAPPER alt_fdw1;

CREATE FOREIGN DATA WRAPPER alt_fdw2;

CREATE SERVER alt_fserv1 FOREIGN DATA WRAPPER alt_fdw1;

CREATE SERVER alt_fserv2 FOREIGN DATA WRAPPER alt_fdw2;

ALTER FOREIGN DATA WRAPPER alt_fdw1 RENAME TO alt_fdw2;

-- failed (name conflict)
ALTER FOREIGN DATA WRAPPER alt_fdw1 RENAME TO alt_fdw3;

-- OK
ALTER SERVER alt_fserv1 RENAME TO alt_fserv2;

-- failed (name conflict)
ALTER SERVER alt_fserv1 RENAME TO alt_fserv3;

-- OK
SELECT
    fdwname
FROM
    pg_foreign_data_wrapper
WHERE
    fdwname LIKE 'alt_fdw%';

SELECT
    srvname
FROM
    pg_foreign_server
WHERE
    srvname LIKE 'alt_fserv%';

--
-- Procedural Language
--
CREATE FUNCTION fn_opf12 (int4, int2)
    RETURNS bigint
    AS '
    SELECT
        NULL::bigint;
'
LANGUAGE SQL;

ALTER OPERATOR FAMILY alt_opf12
    USING btree
        ADD FUNCTION 1 fn_opf12 (int4, int2);

DROP OPERATOR FAMILY alt_opf12
    USING btree;

ROLLBACK;

-- Should fail. hash comparison functions should return INTEGER in ALTER OPERATOR FAMILY ... ADD FUNCTION
BEGIN TRANSACTION;
CREATE OPERATOR FAMILY alt_opf13
    USING HASH;
CREATE FUNCTION fn_opf13 (int4)
    RETURNS bigint
    AS '
    SELECT
        NULL::bigint;
'
LANGUAGE SQL;
ALTER OPERATOR FAMILY alt_opf13
    USING HASH
        ADD FUNCTION 1 fn_opf13 (int4);
DROP OPERATOR FAMILY alt_opf13
    USING HASH;
ROLLBACK;

-- Should fail. btree comparison functions should have two arguments in ALTER OPERATOR FAMILY ... ADD FUNCTION
BEGIN TRANSACTION;
CREATE OPERATOR FAMILY alt_opf14
    USING btree;
CREATE FUNCTION fn_opf14 (int4)
    RETURNS bigint
    AS '
    SELECT
        NULL::bigint;
'
LANGUAGE SQL;
ALTER OPERATOR FAMILY alt_opf14
    USING btree
        ADD FUNCTION 1 fn_opf14 (int4);
DROP OPERATOR FAMILY alt_opf14
    USING btree;
ROLLBACK;

-- Should fail. hash comparison functions should have one argument in ALTER OPERATOR FAMILY ... ADD FUNCTION
BEGIN TRANSACTION;
CREATE OPERATOR FAMILY alt_opf15
    USING HASH;
CREATE FUNCTION fn_opf15 (int4, int2)
    RETURNS bigint
    AS '
    SELECT
        NULL::bigint;
'
LANGUAGE SQL;
ALTER OPERATOR FAMILY alt_opf15
    USING HASH
        ADD FUNCTION 1 fn_opf15 (int4, int2);
DROP OPERATOR FAMILY alt_opf15
    USING HASH;
ROLLBACK;

-- Should fail. In gist throw an error when giving different data types for function argument
-- without defining left / right type in ALTER OPERATOR FAMILY ... ADD FUNCTION
CREATE OPERATOR FAMILY alt_opf16
    USING gist;

ALTER OPERATOR FAMILY alt_opf16
    USING gist
        ADD FUNCTION 1 btint42cmp(int4, int2);

DROP OPERATOR FAMILY alt_opf16
    USING gist;

-- Should fail. duplicate operator number / function number in ALTER OPERATOR FAMILY ... ADD FUNCTION
CREATE OPERATOR FAMILY alt_opf17
    USING btree;

ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int4),
        OPERATOR 1 < (int4, int4);

-- operator # appears twice in same statement
ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int4);

-- operator 1 requested first-time
ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int4);

-- operator 1 requested again in separate statement
ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int2),
        OPERATOR 2 <= (int4, int2),
        OPERATOR 3 = (int4, int2),
        OPERATOR 4 >= (int4, int2),
        OPERATOR 5 > (int4, int2),
        FUNCTION 1 btint42cmp(int4, int2),
        FUNCTION 1 btint42cmp(int4, int2);

-- procedure 1 appears twice in same statement
ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int2),
        OPERATOR 2 <= (int4, int2),
        OPERATOR 3 = (int4, int2),
        OPERATOR 4 >= (int4, int2),
        OPERATOR 5 > (int4, int2),
        FUNCTION 1 btint42cmp(int4, int2);

-- procedure 1 appears first time
ALTER OPERATOR FAMILY alt_opf17
    USING btree
        ADD OPERATOR 1 < (int4, int2),
        OPERATOR 2 <= (int4, int2),
        OPERATOR 3 = (int4, int2),
        OPERATOR 4 >= (int4, int2),
        OPERATOR 5 > (int4, int2),
        FUNCTION 1 btint42cmp(int4, int2);

-- procedure 1 requested again in separate statement
DROP OPERATOR FAMILY alt_opf17
    USING btree;

-- Should fail. Ensure that DROP requests for missing OPERATOR / FUNCTIONS
-- return appropriate message in ALTER OPERATOR FAMILY ... DROP OPERATOR  / FUNCTION
CREATE OPERATOR FAMILY alt_opf18
    USING btree;

ALTER OPERATOR FAMILY alt_opf18
    USING btree
        DROP OPERATOR 1 (int4, int4);

ALTER OPERATOR FAMILY alt_opf18
    USING btree
        ADD OPERATOR 1 < (int4, int2),
        OPERATOR 2 <= (int4, int2),
        OPERATOR 3 = (int4, int2),
        OPERATOR 4 >= (int4, int2),
        OPERATOR 5 > (int4, int2),
        FUNCTION 1 btint42cmp(int4, int2);

ALTER OPERATOR FAMILY alt_opf18
    USING btree
        DROP FUNCTION 2 (int4, int4);

DROP OPERATOR FAMILY alt_opf18
    USING btree;

--
-- Statistics
--
SET SESSION AUTHORIZATION regress_alter_generic_user1;

CREATE TABLE alt_regress_1 (
    a integer,
    b integer
);

CREATE STATISTICS alt_stat1 ON a, b FROM alt_regress_1;

CREATE STATISTICS alt_stat2 ON a, b FROM alt_regress_1;

ALTER STATISTICS alt_stat1 RENAME TO alt_stat2;

-- failed (name conflict)
ALTER STATISTICS alt_stat1 RENAME TO alt_stat3;

-- failed (name conflict)
ALTER STATISTICS alt_stat2 OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER STATISTICS alt_stat2 OWNER TO regress_alter_generic_user3;

-- OK
ALTER STATISTICS alt_stat2 SET SCHEMA alt_nsp2;

-- OK
SET SESSION AUTHORIZATION regress_alter_generic_user2;

CREATE TABLE alt_regress_2 (
    a integer,
    b integer
);

CREATE STATISTICS alt_stat1 ON a, b FROM alt_regress_2;

CREATE STATISTICS alt_stat2 ON a, b FROM alt_regress_2;

ALTER STATISTICS alt_stat3 RENAME TO alt_stat4;

-- failed (not owner)
ALTER STATISTICS alt_stat1 RENAME TO alt_stat4;

-- OK
ALTER STATISTICS alt_stat3 OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER STATISTICS alt_stat2 OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER STATISTICS alt_stat3 SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER STATISTICS alt_stat2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
RESET SESSION AUTHORIZATION;

SELECT
    nspname,
    stxname,
    rolname
FROM
    pg_statistic_ext s,
    pg_namespace n,
    pg_authid a
WHERE
    s.stxnamespace = n.oid
    AND s.stxowner = a.oid
    AND n.nspname IN ('alt_nsp1', 'alt_nsp2')
ORDER BY
    nspname,
    stxname;

--
-- Text Search Dictionary
--
SET SESSION AUTHORIZATION regress_alter_generic_user1;

CREATE TEXT SEARCH DICTIONARY alt_ts_dict1 (
    TEMPLATE = simple
);

CREATE TEXT SEARCH DICTIONARY alt_ts_dict2 (
    TEMPLATE = simple
);

ALTER TEXT SEARCH DICTIONARY alt_ts_dict1 RENAME TO alt_ts_dict2;

-- failed (name conflict)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict1 RENAME TO alt_ts_dict3;

-- OK
ALTER TEXT SEARCH DICTIONARY alt_ts_dict2 OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict2 OWNER TO regress_alter_generic_user3;

-- OK
ALTER TEXT SEARCH DICTIONARY alt_ts_dict2 SET SCHEMA alt_nsp2;

-- OK
SET SESSION AUTHORIZATION regress_alter_generic_user2;

CREATE TEXT SEARCH DICTIONARY alt_ts_dict1 (
    TEMPLATE = simple
);

CREATE TEXT SEARCH DICTIONARY alt_ts_dict2 (
    TEMPLATE = simple
);

ALTER TEXT SEARCH DICTIONARY alt_ts_dict3 RENAME TO alt_ts_dict4;

-- failed (not owner)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict1 RENAME TO alt_ts_dict4;

-- OK
ALTER TEXT SEARCH DICTIONARY alt_ts_dict3 OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict2 OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict3 SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER TEXT SEARCH DICTIONARY alt_ts_dict2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
RESET SESSION AUTHORIZATION;

SELECT
    nspname,
    dictname,
    rolname
FROM
    pg_ts_dict t,
    pg_namespace n,
    pg_authid a
WHERE
    t.dictnamespace = n.oid
    AND t.dictowner = a.oid
    AND n.nspname IN ('alt_nsp1', 'alt_nsp2')
ORDER BY
    nspname,
    dictname;

--
-- Text Search Configuration
--
SET SESSION AUTHORIZATION regress_alter_generic_user1;

CREATE TEXT SEARCH CONFIGURATION alt_ts_conf1 (
    COPY = english
);

CREATE TEXT SEARCH CONFIGURATION alt_ts_conf2 (
    COPY = english
);

ALTER TEXT SEARCH CONFIGURATION alt_ts_conf1 RENAME TO alt_ts_conf2;

-- failed (name conflict)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf1 RENAME TO alt_ts_conf3;

-- OK
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf2 OWNER TO regress_alter_generic_user2;

-- failed (no role membership)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf2 OWNER TO regress_alter_generic_user3;

-- OK
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf2 SET SCHEMA alt_nsp2;

-- OK
SET SESSION AUTHORIZATION regress_alter_generic_user2;

CREATE TEXT SEARCH CONFIGURATION alt_ts_conf1 (
    COPY = english
);

CREATE TEXT SEARCH CONFIGURATION alt_ts_conf2 (
    COPY = english
);

ALTER TEXT SEARCH CONFIGURATION alt_ts_conf3 RENAME TO alt_ts_conf4;

-- failed (not owner)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf1 RENAME TO alt_ts_conf4;

-- OK
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf3 OWNER TO regress_alter_generic_user2;

-- failed (not owner)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf2 OWNER TO regress_alter_generic_user3;

-- failed (no role membership)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf3 SET SCHEMA alt_nsp2;

-- failed (not owner)
ALTER TEXT SEARCH CONFIGURATION alt_ts_conf2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
RESET SESSION AUTHORIZATION;

SELECT
    nspname,
    cfgname,
    rolname
FROM
    pg_ts_config t,
    pg_namespace n,
    pg_authid a
WHERE
    t.cfgnamespace = n.oid
    AND t.cfgowner = a.oid
    AND n.nspname IN ('alt_nsp1', 'alt_nsp2')
ORDER BY
    nspname,
    cfgname;

--
-- Text Search Template
--
CREATE TEXT SEARCH TEMPLATE alt_ts_temp1 (
    LEXIZE = dsimple_lexize
);

CREATE TEXT SEARCH TEMPLATE alt_ts_temp2 (
    LEXIZE = dsimple_lexize
);

ALTER TEXT SEARCH TEMPLATE alt_ts_temp1 RENAME TO alt_ts_temp2;

-- failed (name conflict)
ALTER TEXT SEARCH TEMPLATE alt_ts_temp1 RENAME TO alt_ts_temp3;

-- OK
ALTER TEXT SEARCH TEMPLATE alt_ts_temp2 SET SCHEMA alt_nsp2;

-- OK
CREATE TEXT SEARCH TEMPLATE alt_ts_temp2 (
    LEXIZE = dsimple_lexize
);

ALTER TEXT SEARCH TEMPLATE alt_ts_temp2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
-- invalid: non-lowercase quoted identifiers
CREATE TEXT SEARCH TEMPLATE tstemp_case (
    "Init" = init_function
);

SELECT
    nspname,
    tmplname
FROM
    pg_ts_template t,
    pg_namespace n
WHERE
    t.tmplnamespace = n.oid
    AND nspname LIKE 'alt_nsp%'
ORDER BY
    nspname,
    tmplname;

--
-- Text Search Parser
--
CREATE TEXT SEARCH PARSER alt_ts_prs1 (
    START = prsd_start,
    gettoken = prsd_nexttoken,
    END = prsd_end,
    lextypes = prsd_lextype
);

CREATE TEXT SEARCH PARSER alt_ts_prs2 (
    START = prsd_start,
    gettoken = prsd_nexttoken,
    END = prsd_end,
    lextypes = prsd_lextype
);

ALTER TEXT SEARCH PARSER alt_ts_prs1 RENAME TO alt_ts_prs2;

-- failed (name conflict)
ALTER TEXT SEARCH PARSER alt_ts_prs1 RENAME TO alt_ts_prs3;

-- OK
ALTER TEXT SEARCH PARSER alt_ts_prs2 SET SCHEMA alt_nsp2;

-- OK
CREATE TEXT SEARCH PARSER alt_ts_prs2 (
    START = prsd_start,
    gettoken = prsd_nexttoken,
    END = prsd_end,
    lextypes = prsd_lextype
);

ALTER TEXT SEARCH PARSER alt_ts_prs2 SET SCHEMA alt_nsp2;

-- failed (name conflict)
-- invalid: non-lowercase quoted identifiers
CREATE TEXT SEARCH PARSER tspars_case (
    "Start" = start_function
);

SELECT
    nspname,
    prsname
FROM
    pg_ts_parser t,
    pg_namespace n
WHERE
    t.prsnamespace = n.oid
    AND nspname LIKE 'alt_nsp%'
ORDER BY
    nspname,
    prsname;

---
--- Cleanup resources
---
DROP FOREIGN DATA WRAPPER alt_fdw2 CASCADE;

DROP FOREIGN DATA WRAPPER alt_fdw3 CASCADE;

