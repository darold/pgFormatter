--
-- insert with DEFAULT in the target_list
--
CREATE TABLE inserttest (
    col1 int4,
    col2 int4 NOT NULL,
    col3 text DEFAULT 'testing'
);

INSERT INTO inserttest (col1, col2, col3)
    VALUES (DEFAULT, DEFAULT, DEFAULT);

INSERT INTO inserttest (col2, col3)
    VALUES (3, DEFAULT);

INSERT INTO inserttest (col1, col2, col3)
    VALUES (DEFAULT, 5, DEFAULT);

INSERT INTO inserttest
    VALUES (DEFAULT, 5, 'test');

INSERT INTO inserttest
    VALUES (DEFAULT, 7);

SELECT
    *
FROM
    inserttest;

--
-- insert with similar expression / target_list values (all fail)
--
INSERT INTO inserttest (col1, col2, col3)
    VALUES (DEFAULT, DEFAULT);

INSERT INTO inserttest (col1, col2, col3)
    VALUES (1, 2);

INSERT INTO inserttest (col1)
    VALUES (1, 2);

INSERT INTO inserttest (col1)
    VALUES (DEFAULT, DEFAULT);

SELECT
    *
FROM
    inserttest;

--
-- VALUES test
--
INSERT INTO inserttest
VALUES
    (10, 20, '40'),
    (-1, 2, DEFAULT),
    ((
            SELECT
                2),
            (
                SELECT
                    i
                FROM (
                    VALUES (3)) AS foo (i)),
                'values are fun!');

SELECT
    *
FROM
    inserttest;

--
-- TOASTed value test
--
INSERT INTO inserttest
    VALUES (30, 50, repeat('x', 10000));

SELECT
    col1,
    col2,
    char_length(col3)
FROM
    inserttest;

DROP TABLE inserttest;

--
-- check indirection (field/array assignment), cf bug #14265
--
-- these tests are aware that transformInsertStmt has 3 separate code paths
--
CREATE TYPE insert_test_type AS (
    if1 int,
    if2 text[]
);

CREATE TABLE inserttest (
    f1 int,
    f2 int[],
    f3 insert_test_type,
    f4 insert_test_type[]
);

INSERT INTO inserttest (f2[1], f2[2])
    VALUES (1, 2);

INSERT INTO inserttest (f2[1], f2[2])
VALUES
    (3, 4),
    (5, 6);

INSERT INTO inserttest (f2[1], f2[2])
SELECT
    7,
    8;

INSERT INTO inserttest (f2[1], f2[2])
    VALUES (1, DEFAULT);

-- not supported
INSERT INTO inserttest (f3.if1, f3.if2)
    VALUES (1, ARRAY['foo']);

INSERT INTO inserttest (f3.if1, f3.if2)
VALUES
    (1, '{foo}'),
    (2, '{bar}');

INSERT INTO inserttest (f3.if1, f3.if2)
SELECT
    3,
    '{baz,quux}';

INSERT INTO inserttest (f3.if1, f3.if2)
    VALUES (1, DEFAULT);

-- not supported
INSERT INTO inserttest (f3.if2[1], f3.if2[2])
    VALUES ('foo', 'bar');

INSERT INTO inserttest (f3.if2[1], f3.if2[2])
VALUES
    ('foo', 'bar'),
    ('baz', 'quux');

INSERT INTO inserttest (f3.if2[1], f3.if2[2])
SELECT
    'bear',
    'beer';

INSERT INTO inserttest (f4[1].if2[1], f4[1].if2[2])
    VALUES ('foo', 'bar');

INSERT INTO inserttest (f4[1].if2[1], f4[1].if2[2])
VALUES
    ('foo', 'bar'),
    ('baz', 'quux');

INSERT INTO inserttest (f4[1].if2[1], f4[1].if2[2])
SELECT
    'bear',
    'beer';

SELECT
    *
FROM
    inserttest;

-- also check reverse-listing
CREATE TABLE inserttest2 (
    f1 bigint,
    f2 text
);

CREATE RULE irule1 AS ON INSERT TO inserttest2
    DO ALSO
    INSERT INTO inserttest (f3.if2[1], f3.if2[2])
    VALUES (NEW.f1, NEW.f2);

CREATE RULE irule2 AS ON INSERT TO inserttest2
    DO ALSO
    INSERT INTO inserttest (f4[1].if1, f4[1].if2[2])
    VALUES
        (1, 'fool'),
        (NEW.f1, NEW.f2);

CREATE RULE irule3 AS ON INSERT TO inserttest2
    DO ALSO
    INSERT INTO inserttest (f4[1].if1, f4[1].if2[2])
    SELECT
        NEW.f1,
        NEW.f2;

\d+ inserttest2
DROP TABLE inserttest2;

DROP TABLE inserttest;

DROP TYPE insert_test_type;

-- direct partition inserts should check partition bound constraint
CREATE TABLE range_parted (
    a text,
    b int
)
PARTITION BY RANGE (a, (b + 0));

-- no partitions, so fail
INSERT INTO range_parted
    VALUES ('a', 11);

CREATE TABLE part1 PARTITION OF range_parted
FOR VALUES FROM ('a', 1) TO ('a', 10);

CREATE TABLE part2 PARTITION OF range_parted
FOR VALUES FROM ('a', 10) TO ('a', 20);

CREATE TABLE part3 PARTITION OF range_parted
FOR VALUES FROM ('b', 1) TO ('b', 10);

CREATE TABLE part4 PARTITION OF range_parted
FOR VALUES FROM ('b', 10) TO ('b', 20);

-- fail
INSERT INTO part1
    VALUES ('a', 11);

INSERT INTO part1
    VALUES ('b', 1);

-- ok
INSERT INTO part1
    VALUES ('a', 1);

-- fail
INSERT INTO part4
    VALUES ('b', 21);

INSERT INTO part4
    VALUES ('a', 10);

-- ok
INSERT INTO part4
    VALUES ('b', 10);

-- fail (partition key a has a NOT NULL constraint)
INSERT INTO part1
    VALUES (NULL);

-- fail (expression key (b+0) cannot be null either)
INSERT INTO part1
    VALUES (1);

CREATE TABLE list_parted (
    a text,
    b int
)
PARTITION BY LIST (lower(a));

CREATE TABLE part_aa_bb PARTITION OF list_parted
FOR VALUES IN ('aa', 'bb');

CREATE TABLE part_cc_dd PARTITION OF list_parted
FOR VALUES IN ('cc', 'dd');

CREATE TABLE part_null PARTITION OF list_parted
FOR VALUES IN (NULL);

-- fail
INSERT INTO part_aa_bb
    VALUES ('cc', 1);

INSERT INTO part_aa_bb
    VALUES ('AAa', 1);

INSERT INTO part_aa_bb
    VALUES (NULL);

-- ok
INSERT INTO part_cc_dd
    VALUES ('cC', 1);

INSERT INTO part_null
    VALUES (NULL, 0);

-- check in case of multi-level partitioned table
CREATE TABLE part_ee_ff PARTITION OF list_parted
FOR VALUES IN ('ee', 'ff')
PARTITION BY RANGE (b);

CREATE TABLE part_ee_ff1 PARTITION OF part_ee_ff
FOR VALUES FROM (1) TO (10);

CREATE TABLE part_ee_ff2 PARTITION OF part_ee_ff
FOR VALUES FROM (10) TO (20);

-- test default partition
CREATE TABLE part_default PARTITION OF list_parted DEFAULT;

-- Negative test: a row, which would fit in other partition, does not fit
-- default partition, even when inserted directly
INSERT INTO part_default
    VALUES ('aa', 2);

INSERT INTO part_default
    VALUES (NULL, 2);

-- ok
INSERT INTO part_default
    VALUES ('Zz', 2);

-- test if default partition works as expected for multi-level partitioned
-- table as well as when default partition itself is further partitioned
DROP TABLE part_default;

CREATE TABLE part_xx_yy PARTITION OF list_parted
FOR VALUES IN ('xx', 'yy')
PARTITION BY LIST (a);

CREATE TABLE part_xx_yy_p1 PARTITION OF part_xx_yy
FOR VALUES IN ('xx');

CREATE TABLE part_xx_yy_defpart PARTITION OF part_xx_yy DEFAULT;

CREATE TABLE part_default PARTITION OF list_parted DEFAULT PARTITION BY RANGE (b);

CREATE TABLE part_default_p1 PARTITION OF part_default
FOR VALUES FROM (20) TO (30);

CREATE TABLE part_default_p2 PARTITION OF part_default
FOR VALUES FROM (30) TO (40);

-- fail
INSERT INTO part_ee_ff1
    VALUES ('EE', 11);

INSERT INTO part_default_p2
    VALUES ('gg', 43);

-- fail (even the parent's, ie, part_ee_ff's partition constraint applies)
INSERT INTO part_ee_ff1
    VALUES ('cc', 1);

INSERT INTO part_default
    VALUES ('gg', 43);

-- ok
INSERT INTO part_ee_ff1
    VALUES ('ff', 1);

INSERT INTO part_ee_ff2
    VALUES ('ff', 11);

INSERT INTO part_default_p1
    VALUES ('cd', 25);

INSERT INTO part_default_p2
    VALUES ('de', 35);

INSERT INTO list_parted
    VALUES ('ab', 21);

INSERT INTO list_parted
    VALUES ('xx', 1);

INSERT INTO list_parted
    VALUES ('yy', 2);

SELECT
    tableoid::regclass,
    *
FROM
    list_parted;

-- Check tuple routing for partitioned tables
-- fail
INSERT INTO range_parted
    VALUES ('a', 0);

-- ok
INSERT INTO range_parted
    VALUES ('a', 1);

INSERT INTO range_parted
    VALUES ('a', 10);

-- fail
INSERT INTO range_parted
    VALUES ('a', 20);

-- ok
INSERT INTO range_parted
    VALUES ('b', 1);

INSERT INTO range_parted
    VALUES ('b', 10);

-- fail (partition key (b+0) is null)
INSERT INTO range_parted
    VALUES ('a');

-- Check default partition
CREATE TABLE part_def PARTITION OF range_parted DEFAULT;

-- fail
INSERT INTO part_def
    VALUES ('b', 10);

-- ok
INSERT INTO part_def
    VALUES ('c', 10);

INSERT INTO range_parted
    VALUES (NULL, NULL);

INSERT INTO range_parted
    VALUES ('a', NULL);

INSERT INTO range_parted
    VALUES (NULL, 19);

INSERT INTO range_parted
    VALUES ('b', 20);

SELECT
    tableoid::regclass,
    *
FROM
    range_parted;

-- ok
INSERT INTO list_parted
    VALUES (NULL, 1);

INSERT INTO list_parted (a)
    VALUES ('aA');

-- fail (partition of part_ee_ff not found in both cases)
INSERT INTO list_parted
    VALUES ('EE', 0);

INSERT INTO part_ee_ff
    VALUES ('EE', 0);

-- ok
INSERT INTO list_parted
    VALUES ('EE', 1);

INSERT INTO part_ee_ff
    VALUES ('EE', 10);

SELECT
    tableoid::regclass,
    *
FROM
    list_parted;

-- some more tests to exercise tuple-routing with multi-level partitioning
CREATE TABLE part_gg PARTITION OF list_parted
FOR VALUES IN ('gg')
PARTITION BY RANGE (b);

CREATE TABLE part_gg1 PARTITION OF part_gg
FOR VALUES FROM (MINVALUE) TO (1);

CREATE TABLE part_gg2 PARTITION OF part_gg
FOR VALUES FROM (1) TO (10)
PARTITION BY RANGE (b);

CREATE TABLE part_gg2_1 PARTITION OF part_gg2
FOR VALUES FROM (1) TO (5);

CREATE TABLE part_gg2_2 PARTITION OF part_gg2
FOR VALUES FROM (5) TO (10);

CREATE TABLE part_ee_ff3 PARTITION OF part_ee_ff
FOR VALUES FROM (20) TO (30)
PARTITION BY RANGE (b);

CREATE TABLE part_ee_ff3_1 PARTITION OF part_ee_ff3
FOR VALUES FROM (20) TO (25);

CREATE TABLE part_ee_ff3_2 PARTITION OF part_ee_ff3
FOR VALUES FROM (25) TO (30);

TRUNCATE list_parted;

INSERT INTO list_parted
VALUES
    ('aa'),
    ('cc');

INSERT INTO list_parted
SELECT
    'Ff',
    s.a
FROM
    generate_series(1, 29) s (a);

INSERT INTO list_parted
SELECT
    'gg',
    s.a
FROM
    generate_series(1, 9) s (a);

INSERT INTO list_parted (b)
    VALUES (1);

SELECT
    tableoid::regclass::text,
    a,
    min(b) AS min_b,
    max(b) AS max_b
FROM
    list_parted
GROUP BY
    1,
    2
ORDER BY
    1;

-- direct partition inserts should check hash partition bound constraint
-- Use hand-rolled hash functions and operator classes to get predictable
-- result on different matchines.  The hash function for int4 simply returns
-- the sum of the values passed to it and the one for text returns the length
-- of the non-empty string value passed to it or 0.
CREATE OR REPLACE FUNCTION part_hashint4_noop (value int4, seed int8)
    RETURNS int8
    AS $$
    SELECT
        value + seed;
$$
LANGUAGE sql
IMMUTABLE;

CREATE OPERATOR class part_test_int4_ops FOR TYPE int4
    USING HASH AS
    OPERATOR 1 =,
    FUNCTION 2 part_hashint4_noop (int4, int8
);

CREATE OR REPLACE FUNCTION part_hashtext_length (value text, seed int8)
    RETURNS int8
    AS $$
    SELECT
        length(coalesce(value, ''))::int8
$$
LANGUAGE sql
IMMUTABLE;

CREATE OPERATOR class part_test_text_ops FOR TYPE text
    USING HASH AS
    OPERATOR 1 =,
    FUNCTION 2 part_hashtext_length (text, int8
);

CREATE TABLE hash_parted (
    a int
)
PARTITION BY HASH (a part_test_int4_ops);

CREATE TABLE hpart0 PARTITION OF hash_parted
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE hpart1 PARTITION OF hash_parted
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE hpart2 PARTITION OF hash_parted
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE hpart3 PARTITION OF hash_parted
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO hash_parted
    VALUES (generate_series(1, 10));

-- direct insert of values divisible by 4 - ok;
INSERT INTO hpart0
VALUES
    (12),
    (16);

-- fail;
INSERT INTO hpart0
    VALUES (11);

-- 11 % 4 -> 3 remainder i.e. valid data for hpart3 partition
INSERT INTO hpart3
    VALUES (11);

-- view data
SELECT
    tableoid::regclass AS part,
    a,
    a % 4 AS "remainder = a % 4"
FROM
    hash_parted
ORDER BY
    part;

-- test \d+ output on a table which has both partitioned and unpartitioned
-- partitions
\d+ list_parted
-- cleanup
DROP TABLE range_parted, list_parted;

DROP TABLE hash_parted;

-- test that a default partition added as the first partition accepts any value
-- including null
CREATE TABLE list_parted (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE part_default PARTITION OF list_parted DEFAULT;

\d+ part_default
INSERT INTO part_default
    VALUES (NULL);

INSERT INTO part_default
    VALUES (1);

INSERT INTO part_default
    VALUES (-1);

SELECT
    tableoid::regclass,
    a
FROM
    list_parted;

-- cleanup
DROP TABLE list_parted;

-- more tests for certain multi-level partitioning scenarios
CREATE TABLE mlparted (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE mlparted1 (
    b int NOT NULL,
    a int NOT NULL
)
PARTITION BY RANGE ((b + 0));

CREATE TABLE mlparted11 (
    LIKE mlparted1
);

ALTER TABLE mlparted11
    DROP a;

ALTER TABLE mlparted11
    ADD a int;

ALTER TABLE mlparted11
    DROP a;

ALTER TABLE mlparted11
    ADD a int NOT NULL;

-- attnum for key attribute 'a' is different in mlparted, mlparted1, and mlparted11
SELECT
    attrelid::regclass,
    attname,
    attnum
FROM
    pg_attribute
WHERE
    attname = 'a'
    AND (attrelid = 'mlparted'::regclass
        OR attrelid = 'mlparted1'::regclass
        OR attrelid = 'mlparted11'::regclass)
ORDER BY
    attrelid::regclass::text;

ALTER TABLE mlparted1 ATTACH PARTITION mlparted11
FOR VALUES FROM (2) TO (5);

ALTER TABLE mlparted ATTACH PARTITION mlparted1
FOR VALUES FROM (1, 2) TO (1, 10);

-- check that "(1, 2)" is correctly routed to mlparted11.
INSERT INTO mlparted
    VALUES (1, 2);

SELECT
    tableoid::regclass,
    *
FROM
    mlparted;

-- check that proper message is shown after failure to route through mlparted1
INSERT INTO mlparted (a, b)
    VALUES (1, 5);

TRUNCATE mlparted;

ALTER TABLE mlparted
    ADD CONSTRAINT check_b CHECK (b = 3);

-- have a BR trigger modify the row such that the check_b is violated
CREATE FUNCTION mlparted11_trig_fn ()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.b := 4;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER mlparted11_trig
    BEFORE INSERT ON mlparted11 FOR EACH ROW
    EXECUTE PROCEDURE mlparted11_trig_fn ();

-- check that the correct row is shown when constraint check_b fails after
-- "(1, 2)" is routed to mlparted11 (actually "(1, 4)" would be shown due
-- to the BR trigger mlparted11_trig_fn)
INSERT INTO mlparted
    VALUES (1, 2);

DROP TRIGGER mlparted11_trig ON mlparted11;

DROP FUNCTION mlparted11_trig_fn ();

-- check that inserting into an internal partition successfully results in
-- checking its partition constraint before inserting into the leaf partition
-- selected by tuple-routing
INSERT INTO mlparted1 (a, b)
    VALUES (2, 3);

-- check routing error through a list partitioned table when the key is null
CREATE TABLE lparted_nonullpart (
    a int,
    b char
)
PARTITION BY LIST (b);

CREATE TABLE lparted_nonullpart_a PARTITION OF lparted_nonullpart
FOR VALUES IN ('a');

INSERT INTO lparted_nonullpart
    VALUES (1);

DROP TABLE lparted_nonullpart;

-- check that RETURNING works correctly with tuple-routing
ALTER TABLE mlparted
    DROP CONSTRAINT check_b;

CREATE TABLE mlparted12 PARTITION OF mlparted1
FOR VALUES FROM (5) TO (10);

CREATE TABLE mlparted2 (
    b int NOT NULL,
    a int NOT NULL
);

ALTER TABLE mlparted ATTACH PARTITION mlparted2
FOR VALUES FROM (1, 10) TO (1, 20);

CREATE TABLE mlparted3 PARTITION OF mlparted
FOR VALUES FROM (1, 20) TO (1, 30);

CREATE TABLE mlparted4 (
    LIKE mlparted
);

ALTER TABLE mlparted4
    DROP a;

ALTER TABLE mlparted4
    ADD a int NOT NULL;

ALTER TABLE mlparted ATTACH PARTITION mlparted4
FOR VALUES FROM (1, 30) TO (1, 40);

WITH ins (
    a,
    b,
    c
) AS (
INSERT INTO mlparted (b, a)
    SELECT
        s.a,
        1
    FROM
        generate_series(2, 39) s (a)
    RETURNING
        tableoid::regclass,
        *
)
SELECT
    a,
    b,
    min(c),
    max(c)
FROM
    ins
GROUP BY
    a,
    b
ORDER BY
    1;

ALTER TABLE mlparted
    ADD c text;

CREATE TABLE mlparted5 (
    c text,
    a int NOT NULL,
    b int NOT NULL
)
PARTITION BY LIST (c);

CREATE TABLE mlparted5a (
    a int NOT NULL,
    c text,
    b int NOT NULL
);

ALTER TABLE mlparted5 ATTACH PARTITION mlparted5a
FOR VALUES IN ('a');

ALTER TABLE mlparted ATTACH PARTITION mlparted5
FOR VALUES FROM (1, 40) TO (1, 50);

ALTER TABLE mlparted
    ADD CONSTRAINT check_b CHECK (a = 1 AND b < 45);

INSERT INTO mlparted
    VALUES (1, 45, 'a');

CREATE FUNCTION mlparted5abrtrig_func ()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.c = 'b';
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER mlparted5abrtrig
    BEFORE INSERT ON mlparted5a FOR EACH ROW
    EXECUTE PROCEDURE mlparted5abrtrig_func ();

INSERT INTO mlparted5 (a, b, c)
    VALUES (1, 40, 'a');

DROP TABLE mlparted5;

ALTER TABLE mlparted
    DROP CONSTRAINT check_b;

-- Check multi-level default partition
CREATE TABLE mlparted_def PARTITION OF mlparted DEFAULT PARTITION BY RANGE (a);

CREATE TABLE mlparted_def1 PARTITION OF mlparted_def
FOR VALUES FROM (40) TO (50);

CREATE TABLE mlparted_def2 PARTITION OF mlparted_def
FOR VALUES FROM (50) TO (60);

INSERT INTO mlparted
    VALUES (40, 100);

INSERT INTO mlparted_def1
    VALUES (42, 100);

INSERT INTO mlparted_def2
    VALUES (54, 50);

-- fail
INSERT INTO mlparted
    VALUES (70, 100);

INSERT INTO mlparted_def1
    VALUES (52, 50);

INSERT INTO mlparted_def2
    VALUES (34, 50);

-- ok
CREATE TABLE mlparted_defd PARTITION OF mlparted_def DEFAULT;

INSERT INTO mlparted
    VALUES (70, 100);

SELECT
    tableoid::regclass,
    *
FROM
    mlparted_def;

-- Check multi-level tuple routing with attributes dropped from the
-- top-most parent.  First remove the last attribute.
ALTER TABLE mlparted
    ADD d int,
    ADD e int;

ALTER TABLE mlparted
    DROP e;

CREATE TABLE mlparted5 PARTITION OF mlparted
FOR VALUES FROM (1, 40) TO (1, 50)
PARTITION BY RANGE (c);

CREATE TABLE mlparted5_ab PARTITION OF mlparted5
FOR VALUES FROM ('a') TO ('c')
PARTITION BY LIST (c);

CREATE TABLE mlparted5_a PARTITION OF mlparted5_ab
FOR VALUES IN ('a');

CREATE TABLE mlparted5_b (
    d int,
    b int,
    c text,
    a int
);

ALTER TABLE mlparted5_ab ATTACH PARTITION mlparted5_b
FOR VALUES IN ('b');

TRUNCATE mlparted;

INSERT INTO mlparted
    VALUES (1, 2, 'a', 1);

INSERT INTO mlparted
    VALUES (1, 40, 'a', 1);

-- goes to mlparted5_a
INSERT INTO mlparted
    VALUES (1, 45, 'b', 1);

-- goes to mlparted5_b
SELECT
    tableoid::regclass,
    *
FROM
    mlparted
ORDER BY
    a,
    b,
    c,
    d;

ALTER TABLE mlparted
    DROP d;

TRUNCATE mlparted;

-- Remove the before last attribute.
ALTER TABLE mlparted
    ADD e int,
    ADD d int;

ALTER TABLE mlparted
    DROP e;

INSERT INTO mlparted
    VALUES (1, 2, 'a', 1);

INSERT INTO mlparted
    VALUES (1, 40, 'a', 1);

-- goes to mlparted5_a
INSERT INTO mlparted
    VALUES (1, 45, 'b', 1);

-- goes to mlparted5_b
SELECT
    tableoid::regclass,
    *
FROM
    mlparted
ORDER BY
    a,
    b,
    c,
    d;

ALTER TABLE mlparted
    DROP d;

DROP TABLE mlparted5;

-- check that message shown after failure to find a partition shows the
-- appropriate key description (or none) in various situations
CREATE TABLE key_desc (
    a int,
    b int
)
PARTITION BY LIST ((a + 0));

CREATE TABLE key_desc_1 PARTITION OF key_desc
FOR VALUES IN (1)
PARTITION BY RANGE (b);

CREATE USER regress_insert_other_user;

GRANT SELECT (a) ON key_desc_1 TO regress_insert_other_user;

GRANT INSERT ON key_desc TO regress_insert_other_user;

SET ROLE regress_insert_other_user;

-- no key description is shown
INSERT INTO key_desc
    VALUES (1, 1);

RESET ROLE;

GRANT SELECT (b) ON key_desc_1 TO regress_insert_other_user;

SET ROLE regress_insert_other_user;

-- key description (b)=(1) is now shown
INSERT INTO key_desc
    VALUES (1, 1);

-- key description is not shown if key contains expression
INSERT INTO key_desc
    VALUES (2, 1);

RESET ROLE;

REVOKE ALL ON key_desc FROM regress_insert_other_user;

REVOKE ALL ON key_desc_1 FROM regress_insert_other_user;

DROP ROLE regress_insert_other_user;

DROP TABLE key_desc, key_desc_1;

-- test minvalue/maxvalue restrictions
CREATE TABLE mcrparted (
    a int,
    b int,
    c int
)
PARTITION BY RANGE (a, abs(b), c);

CREATE TABLE mcrparted0 PARTITION OF mcrparted
FOR VALUES FROM (MINVALUE, 0, 0) TO (1,
MAXVALUE,
MAXVALUE);

CREATE TABLE mcrparted2 PARTITION OF mcrparted
FOR VALUES FROM (10, 6,
MINVALUE) TO (10,
MAXVALUE,
MINVALUE);

CREATE TABLE mcrparted4 PARTITION OF mcrparted
FOR VALUES FROM (21,
MINVALUE, 0) TO (30, 20,
MINVALUE);

-- check multi-column range partitioning expression enforces the same
-- constraint as what tuple-routing would determine it to be
CREATE TABLE mcrparted0 PARTITION OF mcrparted
FOR VALUES FROM (MINVALUE,
MINVALUE,
MINVALUE) TO (1,
MAXVALUE,
MAXVALUE);

CREATE TABLE mcrparted1 PARTITION OF mcrparted
FOR VALUES FROM (2, 1,
MINVALUE) TO (10, 5, 10);

CREATE TABLE mcrparted2 PARTITION OF mcrparted
FOR VALUES FROM (10, 6,
MINVALUE) TO (10,
MAXVALUE,
MAXVALUE);

CREATE TABLE mcrparted3 PARTITION OF mcrparted
FOR VALUES FROM (11, 1, 1) TO (20, 10, 10);

CREATE TABLE mcrparted4 PARTITION OF mcrparted
FOR VALUES FROM (21,
MINVALUE,
MINVALUE) TO (30, 20,
MAXVALUE);

CREATE TABLE mcrparted5 PARTITION OF mcrparted
FOR VALUES FROM (30, 21, 20) TO (MAXVALUE,
MAXVALUE,
MAXVALUE);

-- null not allowed in range partition
INSERT INTO mcrparted
    VALUES (NULL, NULL, NULL);

-- routed to mcrparted0
INSERT INTO mcrparted
    VALUES (0, 1, 1);

INSERT INTO mcrparted0
    VALUES (0, 1, 1);

-- routed to mcparted1
INSERT INTO mcrparted
    VALUES (9, 1000, 1);

INSERT INTO mcrparted1
    VALUES (9, 1000, 1);

INSERT INTO mcrparted
    VALUES (10, 5, -1);

INSERT INTO mcrparted1
    VALUES (10, 5, -1);

INSERT INTO mcrparted
    VALUES (2, 1, 0);

INSERT INTO mcrparted1
    VALUES (2, 1, 0);

-- routed to mcparted2
INSERT INTO mcrparted
    VALUES (10, 6, 1000);

INSERT INTO mcrparted2
    VALUES (10, 6, 1000);

INSERT INTO mcrparted
    VALUES (10, 1000, 1000);

INSERT INTO mcrparted2
    VALUES (10, 1000, 1000);

-- no partition exists, nor does mcrparted3 accept it
INSERT INTO mcrparted
    VALUES (11, 1, -1);

INSERT INTO mcrparted3
    VALUES (11, 1, -1);

-- routed to mcrparted5
INSERT INTO mcrparted
    VALUES (30, 21, 20);

INSERT INTO mcrparted5
    VALUES (30, 21, 20);

INSERT INTO mcrparted4
    VALUES (30, 21, 20);

-- error
-- check rows
SELECT
    tableoid::regclass::text,
    *
FROM
    mcrparted
ORDER BY
    1;

-- cleanup
DROP TABLE mcrparted;

-- check that a BR constraint can't make partition contain violating rows
CREATE TABLE brtrigpartcon (
    a int,
    b text
)
PARTITION BY LIST (a);

CREATE TABLE brtrigpartcon1 PARTITION OF brtrigpartcon
FOR VALUES IN (1);

CREATE OR REPLACE FUNCTION brtrigpartcon1trigf ()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.a := 2;
    RETURN new;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER brtrigpartcon1trig
    BEFORE INSERT ON brtrigpartcon1 FOR EACH ROW
    EXECUTE PROCEDURE brtrigpartcon1trigf ();

INSERT INTO brtrigpartcon
    VALUES (1, 'hi there');

INSERT INTO brtrigpartcon1
    VALUES (1, 'hi there');

-- check that the message shows the appropriate column description in a
-- situation where the partitioned table is not the primary ModifyTable node
CREATE TABLE inserttest3 (
    f1 text DEFAULT 'foo',
    f2 text DEFAULT 'bar',
    f3 int
);

CREATE ROLE regress_coldesc_role;

GRANT INSERT ON inserttest3 TO regress_coldesc_role;

GRANT INSERT ON brtrigpartcon TO regress_coldesc_role;

REVOKE SELECT ON brtrigpartcon FROM regress_coldesc_role;

SET ROLE regress_coldesc_role;

WITH result AS (
INSERT INTO brtrigpartcon
        VALUES (1, 'hi there')
    RETURNING
        1)
    INSERT INTO inserttest3 (f3)
    SELECT
        *
    FROM
        result;

RESET ROLE;

-- cleanup
REVOKE ALL ON inserttest3 FROM regress_coldesc_role;

REVOKE ALL ON brtrigpartcon FROM regress_coldesc_role;

DROP ROLE regress_coldesc_role;

DROP TABLE inserttest3;

DROP TABLE brtrigpartcon;

DROP FUNCTION brtrigpartcon1trigf ();

-- check that "do nothing" BR triggers work with tuple-routing (this checks
-- that estate->es_result_relation_info is appropriately set/reset for each
-- routed tuple)
CREATE TABLE donothingbrtrig_test (
    a int,
    b text
)
PARTITION BY LIST (a);

CREATE TABLE donothingbrtrig_test1 (
    b text,
    a int
);

CREATE TABLE donothingbrtrig_test2 (
    c text,
    b text,
    a int
);

ALTER TABLE donothingbrtrig_test2
    DROP COLUMN c;

CREATE OR REPLACE FUNCTION donothingbrtrig_func ()
    RETURNS TRIGGER
    AS $$
BEGIN
    RAISE NOTICE 'b: %', NEW.b;
    RETURN NULL;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER donothingbrtrig1
    BEFORE INSERT ON donothingbrtrig_test1 FOR EACH ROW
    EXECUTE PROCEDURE donothingbrtrig_func ();

CREATE TRIGGER donothingbrtrig2
    BEFORE INSERT ON donothingbrtrig_test2 FOR EACH ROW
    EXECUTE PROCEDURE donothingbrtrig_func ();

ALTER TABLE donothingbrtrig_test ATTACH PARTITION donothingbrtrig_test1
FOR VALUES IN (1);

ALTER TABLE donothingbrtrig_test ATTACH PARTITION donothingbrtrig_test2
FOR VALUES IN (2);

INSERT INTO donothingbrtrig_test
VALUES
    (1, 'foo'),
    (2, 'bar');

SELECT
    tableoid::regclass,
    *
FROM
    donothingbrtrig_test;

-- cleanup
DROP TABLE donothingbrtrig_test;

DROP FUNCTION donothingbrtrig_func ();

-- check multi-column range partitioning with minvalue/maxvalue constraints
CREATE TABLE mcrparted (
    a text,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE mcrparted1_lt_b PARTITION OF mcrparted
FOR VALUES FROM (MINVALUE,
MINVALUE) TO ('b',
MINVALUE);

CREATE TABLE mcrparted2_b PARTITION OF mcrparted
FOR VALUES FROM ('b',
MINVALUE) TO ('c',
MINVALUE);

CREATE TABLE mcrparted3_c_to_common PARTITION OF mcrparted
FOR VALUES FROM ('c',
MINVALUE) TO ('common',
MINVALUE);

CREATE TABLE mcrparted4_common_lt_0 PARTITION OF mcrparted
FOR VALUES FROM ('common',
MINVALUE) TO ('common', 0);

CREATE TABLE mcrparted5_common_0_to_10 PARTITION OF mcrparted
FOR VALUES FROM ('common', 0) TO ('common', 10);

CREATE TABLE mcrparted6_common_ge_10 PARTITION OF mcrparted
FOR VALUES FROM ('common', 10) TO ('common',
MAXVALUE);

CREATE TABLE mcrparted7_gt_common_lt_d PARTITION OF mcrparted
FOR VALUES FROM ('common',
MAXVALUE) TO ('d',
MINVALUE);

CREATE TABLE mcrparted8_ge_d PARTITION OF mcrparted
FOR VALUES FROM ('d',
MINVALUE) TO (MAXVALUE,
MAXVALUE);

\d+ mcrparted
\d+ mcrparted1_lt_b
\d+ mcrparted2_b
\d+ mcrparted3_c_to_common
\d+ mcrparted4_common_lt_0
\d+ mcrparted5_common_0_to_10
\d+ mcrparted6_common_ge_10
\d+ mcrparted7_gt_common_lt_d
\d+ mcrparted8_ge_d
INSERT INTO mcrparted
VALUES
    ('aaa', 0),
    ('b', 0),
    ('bz', 10),
    ('c', -10),
    ('comm', -10),
    ('common', -10),
    ('common', 0),
    ('common', 10),
    ('commons', 0),
    ('d', -10),
    ('e', 0);

SELECT
    tableoid::regclass,
    *
FROM
    mcrparted
ORDER BY
    a,
    b;

DROP TABLE mcrparted;

-- check that wholerow vars in the RETURNING list work with partitioned tables
CREATE TABLE returningwrtest (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE returningwrtest1 PARTITION OF returningwrtest
FOR VALUES IN (1);

INSERT INTO returningwrtest
    VALUES (1)
RETURNING
    returningwrtest;

-- check also that the wholerow vars in RETURNING list are converted as needed
ALTER TABLE returningwrtest
    ADD b text;

CREATE TABLE returningwrtest2 (
    b text,
    c int,
    a int
);

ALTER TABLE returningwrtest2
    DROP c;

ALTER TABLE returningwrtest ATTACH PARTITION returningwrtest2
FOR VALUES IN (2);

INSERT INTO returningwrtest
    VALUES (2, 'foo')
RETURNING
    returningwrtest;

DROP TABLE returningwrtest;

