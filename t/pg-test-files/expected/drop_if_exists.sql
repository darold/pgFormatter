--
-- IF EXISTS tests
--
-- table (will be really dropped at the end)
DROP TABLE test_exists;

DROP TABLE IF EXISTS test_exists;

CREATE TABLE test_exists (
    a int,
    b text
);

-- view
DROP VIEW test_view_exists;

DROP VIEW IF EXISTS test_view_exists;

CREATE VIEW test_view_exists AS
SELECT
    *
FROM
    test_exists;

DROP VIEW IF EXISTS test_view_exists;

DROP VIEW test_view_exists;

-- index
DROP INDEX test_index_exists;

DROP INDEX IF EXISTS test_index_exists;

CREATE INDEX test_index_exists ON test_exists (a);

DROP INDEX IF EXISTS test_index_exists;

DROP INDEX test_index_exists;

-- sequence
DROP SEQUENCE test_sequence_exists;

DROP SEQUENCE IF EXISTS test_sequence_exists;

CREATE SEQUENCE test_sequence_exists;

DROP SEQUENCE IF EXISTS test_sequence_exists;

DROP SEQUENCE test_sequence_exists;

-- schema
DROP SCHEMA test_schema_exists;

DROP SCHEMA IF EXISTS test_schema_exists;

CREATE SCHEMA test_schema_exists;

DROP SCHEMA IF EXISTS test_schema_exists;

DROP SCHEMA test_schema_exists;

-- type
DROP TYPE test_type_exists;

DROP TYPE IF EXISTS test_type_exists;

CREATE TYPE test_type_exists AS (
    a int,
    b text
);

DROP TYPE IF EXISTS test_type_exists;

DROP TYPE test_type_exists;

-- domain
DROP DOMAIN test_domain_exists;

DROP DOMAIN IF EXISTS test_domain_exists;

CREATE DOMAIN test_domain_exists AS int NOT NULL CHECK (value > 0);

DROP DOMAIN IF EXISTS test_domain_exists;

DROP DOMAIN test_domain_exists;

---
--- role/user/group
---
CREATE USER regress_test_u1;

CREATE ROLE regress_test_r1;

CREATE GROUP regress_test_g1;

DROP USER regress_test_u2;

DROP USER IF EXISTS regress_test_u1, regress_test_u2;

DROP USER regress_test_u1;

DROP ROLE regress_test_r2;

DROP ROLE IF EXISTS regress_test_r1, regress_test_r2;

DROP ROLE regress_test_r1;

DROP GROUP regress_test_g2;

DROP GROUP IF EXISTS regress_test_g1, regress_test_g2;

DROP GROUP regress_test_g1;

-- collation
DROP COLLATION IF EXISTS test_collation_exists;

-- conversion
DROP CONVERSION test_conversion_exists;

DROP CONVERSION IF EXISTS test_conversion_exists;

CREATE CONVERSION test_conversion_exists FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

DROP CONVERSION test_conversion_exists;

-- text search parser
DROP TEXT SEARCH PARSER test_tsparser_exists;

DROP TEXT SEARCH PARSER IF EXISTS test_tsparser_exists;

-- text search dictionary
DROP TEXT SEARCH DICTIONARY test_tsdict_exists;

DROP TEXT SEARCH DICTIONARY IF EXISTS test_tsdict_exists;

CREATE TEXT SEARCH DICTIONARY test_tsdict_exists (
    TEMPLATE = ispell,
    DictFile = ispell_sample,
    AffFile = ispell_sample
);

DROP TEXT SEARCH DICTIONARY test_tsdict_exists;

-- test search template
DROP TEXT SEARCH TEMPLATE test_tstemplate_exists;

DROP TEXT SEARCH TEMPLATE IF EXISTS test_tstemplate_exists;

-- text search configuration
DROP TEXT SEARCH CONFIGURATION test_tsconfig_exists;

DROP TEXT SEARCH CONFIGURATION IF EXISTS test_tsconfig_exists;

CREATE TEXT SEARCH CONFIGURATION test_tsconfig_exists (
    COPY = english
);

DROP TEXT SEARCH CONFIGURATION test_tsconfig_exists;

-- extension
DROP EXTENSION test_extension_exists;

DROP EXTENSION IF EXISTS test_extension_exists;

-- functions
DROP FUNCTION test_function_exists ();

DROP FUNCTION IF EXISTS test_function_exists ();

DROP FUNCTION test_function_exists (int, text, int[]);

DROP FUNCTION IF EXISTS test_function_exists (int, text, int[]);

-- aggregate
DROP AGGREGATE test_aggregate_exists (*);

DROP AGGREGATE IF EXISTS test_aggregate_exists (*);

DROP AGGREGATE test_aggregate_exists (int);

DROP AGGREGATE IF EXISTS test_aggregate_exists (int);

-- operator
DROP OPERATOR @#@ (int, int);

DROP OPERATOR IF EXISTS @#@ (int, int);

CREATE OPERATOR @#@ (
    LEFTARG = int8,
    RIGHTARG = int8,
    PROCEDURE = int8xor
);

DROP OPERATOR @#@ (int8, int8);

-- language
CREATE FUNCTION test_ambiguous_funcname (int)
    RETURNS int
    AS $$
    SELECT
        $1;
$$
LANGUAGE sql;

CREATE FUNCTION test_ambiguous_funcname (text)
    RETURNS text
    AS $$
    SELECT
        $1;
$$
LANGUAGE sql;

DROP FUNCTION test_ambiguous_funcname;

DROP FUNCTION IF EXISTS test_ambiguous_funcname;

-- cleanup
DROP FUNCTION test_ambiguous_funcname (int);

DROP FUNCTION test_ambiguous_funcname (text);

-- Likewise for procedures.
CREATE PROCEDURE test_ambiguous_procname (int)
    AS $$
BEGIN
END;
$$
LANGUAGE plpgsql;

CREATE PROCEDURE test_ambiguous_procname (text)
    AS $$
BEGIN
END;
$$
LANGUAGE plpgsql;

DROP PROCEDURE test_ambiguous_procname;

DROP PROCEDURE IF EXISTS test_ambiguous_procname;

-- Check we get a similar error if we use ROUTINE instead of PROCEDURE.
DROP ROUTINE IF EXISTS test_ambiguous_procname;

-- cleanup
DROP PROCEDURE test_ambiguous_procname (int);

DROP PROCEDURE test_ambiguous_procname (text);

