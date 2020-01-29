INSERT INTO test_exists VALUES (NEW.a, NEW.b || NEW.a::text);

CREATE RULE base_tab_def_view_ins_rule AS ON INSERT TO base_tab_def_view
    DO ALSO
    INSERT INTO base_tab_def VALUES (new.a, new.b, new.c, new.d, new.e);

CREATE RULE base_tab_def_view_ins_rule AS ON INSERT TO base_tab_def_view
    DO INSTEAD
    INSERT INTO base_tab_def VALUES (new.a, new.b, new.c, new.d, new.e);

CREATE RULE test_rule_exists AS ON INSERT TO test_exists
    DO INSTEAD
    INSERT INTO test_exists VALUES (NEW.a, NEW.b || NEW.a::text);

DROP RULE test_rule_exists ON test_exists;

DROP SEQUENCE test_sequence_exists;

CREATE GROUP regress_test_g1;

DROP GROUP regress_test_g1;

DROP USER IF EXISTS regress_test_u1, regress_test_u2;

CREATE CONVERSION test_conversion_exists FOR 'LATIN1' TO 'UTF8'
FROM
    iso8859_1_to_utf8;

CREATE DOMAIN test_domain_exists AS int NOT NULL CHECK (
    value > 0
);

DROP OPERATOR @#@ (int, int);

DROP OPERATOR IF EXISTS @#@ (int, int);

CREATE OPERATOR @#@
        (leftarg = int8, rightarg = int8, procedure = int8xor);

DROP OPERATOR @#@ (int8, int8);

create operator alter1.=(procedure = alter1.same, leftarg  = alter1.ctype, rightarg = alter1.ctype);

CREATE OPERATOR !== (
        PROCEDURE = int8ne,
        LEFTARG = bigint,
        RIGHTARG = bigint,
        COMMUTATOR = !==,
        NEGATOR = ===
);

EXPLAIN
(COSTS OFF, ANALYZE
)
SELECT count(*)
FROM quad_point_tbl
WHERE p IS NULL;

CREATE FUNCTION sql_is_distinct_from (anyelement, anyelement)
    RETURNS boolean
    LANGUAGE sql
    AS 'INSERT INTO dom_table VALUES (1, 2, 3)'
;

INSERT INTO dom_table
    VALUES ('1');
INSERT INTO dom_table
    VALUES ('1');

CREATE FUNCTION customcontsel(internal, oid, internal, integer)
RETURNS float8 AS 'contsel' LANGUAGE internal STABLE STRICT;
CREATE VIEW attmp_view (unique1) AS SELECT unique1 FROM tenk1;
CREATE VIEW attmp_view (col1, col2) AS SELECT cola, colb FROM tenk1;

CREATE TABLE a (u) AS SELECT u;

