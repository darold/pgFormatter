--
-- Test partitioning planner code
--
CREATE TABLE lp (
    a char
)
PARTITION BY LIST (a);

CREATE TABLE lp_default PARTITION OF lp DEFAULT;

CREATE TABLE lp_ef PARTITION OF lp
FOR VALUES IN ('e', 'f');

CREATE TABLE lp_ad PARTITION OF lp
FOR VALUES IN ('a', 'd');

CREATE TABLE lp_bc PARTITION OF lp
FOR VALUES IN ('b', 'c');

CREATE TABLE lp_g PARTITION OF lp
FOR VALUES IN ('g');

CREATE TABLE lp_null PARTITION OF lp
FOR VALUES IN (NULL);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a > 'a'
    AND a < 'd';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a > 'a'
    AND a <= 'd';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a = 'a';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    'a' = a;


/* commuted */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a IS NOT NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a = 'a'
    OR a = 'c';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a IS NOT NULL
    AND (a = 'a'
        OR a = 'c');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a <> 'g';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a <> 'a'
    AND a <> 'd';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a NOT IN ('a', 'd');

-- collation matches the partitioning collation, pruning works
CREATE TABLE coll_pruning (
    a text COLLATE "C"
)
PARTITION BY LIST (a);

CREATE TABLE coll_pruning_a PARTITION OF coll_pruning
FOR VALUES IN ('a');

CREATE TABLE coll_pruning_b PARTITION OF coll_pruning
FOR VALUES IN ('b');

CREATE TABLE coll_pruning_def PARTITION OF coll_pruning DEFAULT;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coll_pruning
WHERE
    a COLLATE "C" = 'a' COLLATE "C";

-- collation doesn't match the partitioning collation, no pruning occurs
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coll_pruning
WHERE
    a COLLATE "POSIX" = 'a' COLLATE "POSIX";

CREATE TABLE rlp (
    a int,
    b varchar
)
PARTITION BY RANGE (a);

CREATE TABLE rlp_default PARTITION OF rlp DEFAULT PARTITION BY LIST (a);

CREATE TABLE rlp_default_default PARTITION OF rlp_default DEFAULT;

CREATE TABLE rlp_default_10 PARTITION OF rlp_default
FOR VALUES IN (10);

CREATE TABLE rlp_default_30 PARTITION OF rlp_default
FOR VALUES IN (30);

CREATE TABLE rlp_default_null PARTITION OF rlp_default
FOR VALUES IN (NULL);

CREATE TABLE rlp1 PARTITION OF rlp
FOR VALUES FROM (MINVALUE) TO (1);

CREATE TABLE rlp2 PARTITION OF rlp
FOR VALUES FROM (1) TO (10);

CREATE TABLE rlp3 (
    b varchar,
    a int
)
PARTITION BY LIST (b varchar_ops);

CREATE TABLE rlp3_default PARTITION OF rlp3 DEFAULT;

CREATE TABLE rlp3abcd PARTITION OF rlp3
FOR VALUES IN ('ab', 'cd');

CREATE TABLE rlp3efgh PARTITION OF rlp3
FOR VALUES IN ('ef', 'gh');

CREATE TABLE rlp3nullxy PARTITION OF rlp3
FOR VALUES IN (NULL, 'xy');

ALTER TABLE rlp ATTACH PARTITION rlp3
FOR VALUES FROM (15) TO (20);

CREATE TABLE rlp4 PARTITION OF rlp
FOR VALUES FROM (20) TO (30)
PARTITION BY RANGE (a);

CREATE TABLE rlp4_default PARTITION OF rlp4 DEFAULT;

CREATE TABLE rlp4_1 PARTITION OF rlp4
FOR VALUES FROM (20) TO (25);

CREATE TABLE rlp4_2 PARTITION OF rlp4
FOR VALUES FROM (25) TO (29);

CREATE TABLE rlp5 PARTITION OF rlp
FOR VALUES FROM (31) TO (MAXVALUE)
PARTITION BY RANGE (a);

CREATE TABLE rlp5_default PARTITION OF rlp5 DEFAULT;

CREATE TABLE rlp5_1 PARTITION OF rlp5
FOR VALUES FROM (31) TO (40);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a < 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    1 > a;


/* commuted */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a <= 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1::bigint;


/* same as above */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1::numeric;


/* no pruning */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a <= 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a < 15;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a <= 15;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 15
    AND b = 'ab';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16
    AND b IN ('not', 'in', 'here');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16
    AND b < 'ab';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16
    AND b <= 'ab';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16
    AND b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 16
    AND b IS NOT NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a IS NOT NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 30;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 30;


/* only default is scanned */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a <= 31;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1
    OR a = 7;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1
    OR b = 'ab';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 20
    AND a < 27;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 29;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a >= 29;

-- redundant clauses are eliminated
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 1
    AND a = 10;


/* only default */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a > 1
    AND a >= 15;


/* rlp3 onwards, including default */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 1
    AND a = 3;


/* empty */
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE (a = 1
    AND a = 3)
    OR (a > 1
        AND a = 15);

-- multi-column keys
CREATE TABLE mc3p (
    a int,
    b int,
    c int
)
PARTITION BY RANGE (a, abs(b), c);

CREATE TABLE mc3p_default PARTITION OF mc3p DEFAULT;

CREATE TABLE mc3p0 PARTITION OF mc3p
FOR VALUES FROM (MINVALUE,
MINVALUE,
MINVALUE) TO (1, 1, 1);

CREATE TABLE mc3p1 PARTITION OF mc3p
FOR VALUES FROM (1, 1, 1) TO (10, 5, 10);

CREATE TABLE mc3p2 PARTITION OF mc3p
FOR VALUES FROM (10, 5, 10) TO (10, 10, 10);

CREATE TABLE mc3p3 PARTITION OF mc3p
FOR VALUES FROM (10, 10, 10) TO (10, 10, 20);

CREATE TABLE mc3p4 PARTITION OF mc3p
FOR VALUES FROM (10, 10, 20) TO (10,
MAXVALUE,
MAXVALUE);

CREATE TABLE mc3p5 PARTITION OF mc3p
FOR VALUES FROM (11, 1, 1) TO (20, 10, 10);

CREATE TABLE mc3p6 PARTITION OF mc3p
FOR VALUES FROM (20, 10, 10) TO (20, 20, 20);

CREATE TABLE mc3p7 PARTITION OF mc3p
FOR VALUES FROM (20, 20, 20) TO (MAXVALUE,
MAXVALUE,
MAXVALUE);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 1
    AND abs(b) < 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 1
    AND abs(b) = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 1
    AND abs(b) = 1
    AND c < 8;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 10
    AND abs(b) BETWEEN 5 AND 35;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a > 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a >= 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a < 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a <= 10
    AND abs(b) < 10;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 11
    AND abs(b) = 0;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 20
    AND abs(b) = 10
    AND c = 100;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a > 20;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a >= 20;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE (a = 1
    AND abs(b) = 1
    AND c = 1)
    OR (a = 10
        AND abs(b) = 5
        AND c = 10)
    OR (a > 11
        AND a < 20);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE (a = 1
    AND abs(b) = 1
    AND c = 1)
    OR (a = 10
        AND abs(b) = 5
        AND c = 10)
    OR (a > 11
        AND a < 20)
    OR a < 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE (a = 1
    AND abs(b) = 1
    AND c = 1)
    OR (a = 10
        AND abs(b) = 5
        AND c = 10)
    OR (a > 11
        AND a < 20)
    OR a < 1
    OR a = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE
    a = 1
    OR abs(b) = 1
    OR c = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE (a = 1
    AND abs(b) = 1)
    OR (a = 10
        AND abs(b) = 10);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc3p
WHERE (a = 1
    AND abs(b) = 1)
    OR (a = 10
        AND abs(b) = 9);

-- a simpler multi-column keys case
CREATE TABLE mc2p (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE mc2p_default PARTITION OF mc2p DEFAULT;

CREATE TABLE mc2p0 PARTITION OF mc2p
FOR VALUES FROM (MINVALUE,
MINVALUE) TO (1,
MINVALUE);

CREATE TABLE mc2p1 PARTITION OF mc2p
FOR VALUES FROM (1,
MINVALUE) TO (1, 1);

CREATE TABLE mc2p2 PARTITION OF mc2p
FOR VALUES FROM (1, 1) TO (2,
MINVALUE);

CREATE TABLE mc2p3 PARTITION OF mc2p
FOR VALUES FROM (2,
MINVALUE) TO (2, 1);

CREATE TABLE mc2p4 PARTITION OF mc2p
FOR VALUES FROM (2, 1) TO (2,
MAXVALUE);

CREATE TABLE mc2p5 PARTITION OF mc2p
FOR VALUES FROM (2,
MAXVALUE) TO (MAXVALUE,
MAXVALUE);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a < 2;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a = 2
    AND b < 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a > 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a = 1
    AND b > 1;

-- all partitions but the default one should be pruned
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a = 1
    AND b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a IS NULL
    AND b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a IS NULL
    AND b = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    a IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p
WHERE
    b IS NULL;

-- boolean partitioning
CREATE TABLE boolpart (
    a bool
)
PARTITION BY LIST (a);

CREATE TABLE boolpart_default PARTITION OF boolpart DEFAULT;

CREATE TABLE boolpart_t PARTITION OF boolpart
FOR VALUES IN ('true');

CREATE TABLE boolpart_f PARTITION OF boolpart
FOR VALUES IN ('false');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IN (TRUE, FALSE);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a = FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    NOT a = FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IS TRUE
    OR a IS NOT TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IS NOT TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IS NOT TRUE
    AND a IS NOT FALSE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IS unknown;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    boolpart
WHERE
    a IS NOT unknown;

-- test scalar-to-array operators
CREATE TABLE coercepart (
    a varchar
)
PARTITION BY LIST (a);

CREATE TABLE coercepart_ab PARTITION OF coercepart
FOR VALUES IN ('ab');

CREATE TABLE coercepart_bc PARTITION OF coercepart
FOR VALUES IN ('bc');

CREATE TABLE coercepart_cd PARTITION OF coercepart
FOR VALUES IN ('cd');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coercepart
WHERE
    a IN ('ab', to_char(125, '999'));

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coercepart
WHERE
    a ~ ANY ('{ab}');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coercepart
WHERE
    a !~ ALL ('{ab}');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coercepart
WHERE
    a ~ ANY ('{ab,bc}');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coercepart
WHERE
    a !~ ALL ('{ab,bc}');

DROP TABLE coercepart;

CREATE TABLE part (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE part_p1 PARTITION OF part
FOR VALUES IN (-2, -1, 0, 1, 2);

CREATE TABLE part_p2 PARTITION OF part DEFAULT PARTITION BY RANGE (a);

CREATE TABLE part_p2_p1 PARTITION OF part_p2 DEFAULT;

INSERT INTO part
VALUES
    (-1, -1),
    (1, 1),
    (2, NULL),
    (NULL, -2),
    (NULL, NULL);

EXPLAIN (
    COSTS OFF
)
SELECT
    tableoid::regclass AS part,
    a,
    b
FROM
    part
WHERE
    a IS NULL
ORDER BY
    1,
    2,
    3;

--
-- some more cases
--
--
-- pruning for partitioned table appearing inside a sub-query
--
-- pruning won't work for mc3p, because some keys are Params
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p t1,
    LATERAL (
        SELECT
            count(*)
        FROM
            mc3p t2
        WHERE
            t2.a = t1.b
            AND abs(t2.b) = 1
            AND t2.c = 1) s
WHERE
    t1.a = 1;

-- pruning should work fine, because values for a prefix of keys (a, b) are
-- available
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p t1,
    LATERAL (
        SELECT
            count(*)
        FROM
            mc3p t2
        WHERE
            t2.c = t1.b
            AND abs(t2.b) = 1
            AND t2.a = 1) s
WHERE
    t1.a = 1;

-- also here, because values for all keys are provided
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    mc2p t1,
    LATERAL (
        SELECT
            count(*)
        FROM
            mc3p t2
        WHERE
            t2.a = 1
            AND abs(t2.b) = 1
            AND t2.c = 1) s
WHERE
    t1.a = 1;

--
-- pruning with clauses containing <> operator
--
-- doesn't prune range partitions
CREATE TABLE rp (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE rp0 PARTITION OF rp
FOR VALUES FROM (MINVALUE) TO (1);

CREATE TABLE rp1 PARTITION OF rp
FOR VALUES FROM (1) TO (2);

CREATE TABLE rp2 PARTITION OF rp
FOR VALUES FROM (2) TO (MAXVALUE);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rp
WHERE
    a <> 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rp
WHERE
    a <> 1
    AND a <> 2;

-- null partition should be eliminated due to strict <> clause.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a <> 'a';

-- ensure we detect contradictions in clauses; a can't be NULL and NOT NULL.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE
    a <> 'a'
    AND a IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lp
WHERE (a <> 'a'
    AND a <> 'd')
    OR a IS NULL;

-- check that it also works for a partitioned table that's not root,
-- which in this case are partitions of rlp that are themselves
-- list-partitioned on b
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rlp
WHERE
    a = 15
    AND b <> 'ab'
    AND b <> 'cd'
    AND b <> 'xy'
    AND b IS NOT NULL;

--
-- different collations for different keys with same expression
--
CREATE TABLE coll_pruning_multi (
    a text
)
PARTITION BY RANGE (substr(a, 1) COLLATE "POSIX", substr(a, 1) COLLATE "C");

CREATE TABLE coll_pruning_multi1 PARTITION OF coll_pruning_multi
FOR VALUES FROM ('a', 'a') TO ('a', 'e');

CREATE TABLE coll_pruning_multi2 PARTITION OF coll_pruning_multi
FOR VALUES FROM ('a', 'e') TO ('a', 'z');

CREATE TABLE coll_pruning_multi3 PARTITION OF coll_pruning_multi
FOR VALUES FROM ('b', 'a') TO ('b', 'e');

-- no pruning, because no value for the leading key
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coll_pruning_multi
WHERE
    substr(a, 1) = 'e' COLLATE "C";

-- pruning, with a value provided for the leading key
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coll_pruning_multi
WHERE
    substr(a, 1) = 'a' COLLATE "POSIX";

-- pruning, with values provided for both keys
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    coll_pruning_multi
WHERE
    substr(a, 1) = 'e' COLLATE "C"
    AND substr(a, 1) = 'a' COLLATE "POSIX";

--
-- LIKE operators don't prune
--
CREATE TABLE like_op_noprune (
    a text
)
PARTITION BY LIST (a);

CREATE TABLE like_op_noprune1 PARTITION OF like_op_noprune
FOR VALUES IN ('ABC');

CREATE TABLE like_op_noprune2 PARTITION OF like_op_noprune
FOR VALUES IN ('BCD');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    like_op_noprune
WHERE
    a LIKE '%BC';

--
-- tests wherein clause value requires a cross-type comparison function
--
CREATE TABLE lparted_by_int2 (
    a smallint
)
PARTITION BY LIST (a);

CREATE TABLE lparted_by_int2_1 PARTITION OF lparted_by_int2
FOR VALUES IN (1);

CREATE TABLE lparted_by_int2_16384 PARTITION OF lparted_by_int2
FOR VALUES IN (16384);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    lparted_by_int2
WHERE
    a = 100000000000000;

CREATE TABLE rparted_by_int2 (
    a smallint
)
PARTITION BY RANGE (a);

CREATE TABLE rparted_by_int2_1 PARTITION OF rparted_by_int2
FOR VALUES FROM (1) TO (10);

CREATE TABLE rparted_by_int2_16384 PARTITION OF rparted_by_int2
FOR VALUES FROM (10) TO (16384);

-- all partitions pruned
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rparted_by_int2
WHERE
    a > 100000000000000;

CREATE TABLE rparted_by_int2_maxvalue PARTITION OF rparted_by_int2
FOR VALUES FROM (16384) TO (MAXVALUE);

-- all partitions but rparted_by_int2_maxvalue pruned
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    rparted_by_int2
WHERE
    a > 100000000000000;

DROP TABLE lp, coll_pruning, rlp, mc3p, mc2p, boolpart, rp, coll_pruning_multi, like_op_noprune, lparted_by_int2, rparted_by_int2;

--
-- Test Partition pruning for HASH partitioning
--
-- Use hand-rolled hash functions and operator classes to get predictable
-- result on different matchines.  See the definitions of
-- part_part_test_int4_ops and part_test_text_ops in insert.sql.
--
CREATE TABLE hp (
    a int,
    b text
)
PARTITION BY HASH (a part_test_int4_ops, b part_test_text_ops);

CREATE TABLE hp0 PARTITION OF hp
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE hp3 PARTITION OF hp
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

CREATE TABLE hp1 PARTITION OF hp
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE hp2 PARTITION OF hp
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

INSERT INTO hp
    VALUES (NULL, NULL);

INSERT INTO hp
    VALUES (1, NULL);

INSERT INTO hp
    VALUES (1, 'xxx');

INSERT INTO hp
    VALUES (NULL, 'xxx');

INSERT INTO hp
    VALUES (2, 'xxx');

INSERT INTO hp
    VALUES (1, 'abcde');

SELECT
    tableoid::regclass,
    *
FROM
    hp
ORDER BY
    1;

-- partial keys won't prune, nor would non-equality conditions
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    b = 'xxx';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a < 1
    AND b = 'xxx';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a <> 1
    AND b = 'yyy';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a <> 1
    AND b <> 'xxx';

-- pruning should work if either a value or a IS NULL clause is provided for
-- each of the keys
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a IS NULL
    AND b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a = 1
    AND b IS NULL;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a = 1
    AND b = 'xxx';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a IS NULL
    AND b = 'xxx';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a = 2
    AND b = 'xxx';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE
    a = 1
    AND b = 'abcde';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    hp
WHERE (a = 1
    AND b = 'abcde')
    OR (a = 2
        AND b = 'xxx')
    OR (a IS NULL
        AND b IS NULL);

DROP TABLE hp;

--
-- Test runtime partition pruning
--
CREATE TABLE ab (
    a int NOT NULL,
    b int NOT NULL
)
PARTITION BY LIST (a);

CREATE TABLE ab_a2 PARTITION OF ab
FOR VALUES IN (2)
PARTITION BY LIST (b);

CREATE TABLE ab_a2_b1 PARTITION OF ab_a2
FOR VALUES IN (1);

CREATE TABLE ab_a2_b2 PARTITION OF ab_a2
FOR VALUES IN (2);

CREATE TABLE ab_a2_b3 PARTITION OF ab_a2
FOR VALUES IN (3);

CREATE TABLE ab_a1 PARTITION OF ab
FOR VALUES IN (1)
PARTITION BY LIST (b);

CREATE TABLE ab_a1_b1 PARTITION OF ab_a1
FOR VALUES IN (1);

CREATE TABLE ab_a1_b2 PARTITION OF ab_a1
FOR VALUES IN (2);

CREATE TABLE ab_a1_b3 PARTITION OF ab_a1
FOR VALUES IN (3);

CREATE TABLE ab_a3 PARTITION OF ab
FOR VALUES IN (3)
PARTITION BY LIST (b);

CREATE TABLE ab_a3_b1 PARTITION OF ab_a3
FOR VALUES IN (1);

CREATE TABLE ab_a3_b2 PARTITION OF ab_a3
FOR VALUES IN (2);

CREATE TABLE ab_a3_b3 PARTITION OF ab_a3
FOR VALUES IN (3);

-- Disallow index only scans as concurrent transactions may stop visibility
-- bits being set causing "Heap Fetches" to be unstable in the EXPLAIN ANALYZE
-- output.
SET enable_indexonlyscan = OFF;

PREPARE ab_q1 (int, int, int) AS
SELECT
    *
FROM
    ab
WHERE
    a BETWEEN $1 AND $2
    AND b <= $3;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE ab_q1 (1, 8, 3);

EXECUTE ab_q1 (1, 8, 3);

EXECUTE ab_q1 (1, 8, 3);

EXECUTE ab_q1 (1, 8, 3);

EXECUTE ab_q1 (1, 8, 3);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q1 (2, 2, 3);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q1 (1, 2, 3);

DEALLOCATE ab_q1;

-- Runtime pruning after optimizer pruning
PREPARE ab_q1 (int, int) AS
SELECT
    a
FROM
    ab
WHERE
    a BETWEEN $1 AND $2
    AND b < 3;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE ab_q1 (1, 8);

EXECUTE ab_q1 (1, 8);

EXECUTE ab_q1 (1, 8);

EXECUTE ab_q1 (1, 8);

EXECUTE ab_q1 (1, 8);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q1 (2, 2);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q1 (2, 4);

-- Ensure a mix of PARAM_EXTERN and PARAM_EXEC Params work together at
-- different levels of partitioning.
PREPARE ab_q2 (int, int) AS
SELECT
    a
FROM
    ab
WHERE
    a BETWEEN $1 AND $2
    AND b < (
        SELECT
            3);

EXECUTE ab_q2 (1, 8);

EXECUTE ab_q2 (1, 8);

EXECUTE ab_q2 (1, 8);

EXECUTE ab_q2 (1, 8);

EXECUTE ab_q2 (1, 8);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q2 (2, 2);

-- As above, but swap the PARAM_EXEC Param to the first partition level
PREPARE ab_q3 (int, int) AS
SELECT
    a
FROM
    ab
WHERE
    b BETWEEN $1 AND $2
    AND a < (
        SELECT
            3);

EXECUTE ab_q3 (1, 8);

EXECUTE ab_q3 (1, 8);

EXECUTE ab_q3 (1, 8);

EXECUTE ab_q3 (1, 8);

EXECUTE ab_q3 (1, 8);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q3 (2, 2);

-- Test a backwards Append scan
CREATE TABLE list_part (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE list_part1 PARTITION OF list_part
FOR VALUES IN (1);

CREATE TABLE list_part2 PARTITION OF list_part
FOR VALUES IN (2);

CREATE TABLE list_part3 PARTITION OF list_part
FOR VALUES IN (3);

CREATE TABLE list_part4 PARTITION OF list_part
FOR VALUES IN (4);

INSERT INTO list_part
SELECT
    generate_series(1, 4);

BEGIN;
-- Don't select an actual value out of the table as the order of the Append's
-- subnodes may not be stable.
DECLARE cur SCROLL CURSOR FOR
    SELECT
        1
    FROM
        list_part
    WHERE
        a > (
            SELECT
                1)
        AND a < (
            SELECT
                4);
-- move beyond the final row
MOVE 3
FROM
    cur;
-- Ensure we get two rows.
FETCH BACKWARD ALL
FROM
    cur;
COMMIT;

BEGIN;
-- Test run-time pruning using stable functions
CREATE FUNCTION list_part_fn (int)
    RETURNS int
    AS $$
BEGIN
    RETURN $1;
END;
$$
LANGUAGE plpgsql
STABLE;
-- Ensure pruning works using a stable function containing no Vars
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    list_part
WHERE
    a = list_part_fn (1);
-- Ensure pruning does not take place when the function has a Var parameter
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    list_part
WHERE
    a = list_part_fn (a);
-- Ensure pruning does not take place when the expression contains a Var.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    list_part
WHERE
    a = list_part_fn (1) + a;
ROLLBACK;

DROP TABLE list_part;

-- Parallel append
-- Suppress the number of loops each parallel node runs for.  This is because
-- more than one worker may run the same parallel node if timing conditions
-- are just right, which destabilizes the test.
CREATE FUNCTION explain_parallel_append (text)
    RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE
    ln text;
BEGIN
    FOR ln IN EXECUTE format('explain (analyze, costs off, summary off, timing off) %s', $1)
    LOOP
        IF ln LIKE '%Parallel%' THEN
            ln := regexp_replace(ln, 'loops=\d*', 'loops=N');
        END IF;
        RETURN NEXT ln;
    END LOOP;
END;
$$;

PREPARE ab_q4 (int, int) AS
SELECT
    avg(a)
FROM
    ab
WHERE
    a BETWEEN $1 AND $2
    AND b < 4;

-- Encourage use of parallel plans
SET parallel_setup_cost = 0;

SET parallel_tuple_cost = 0;

SET min_parallel_table_scan_size = 0;

SET max_parallel_workers_per_gather = 2;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE ab_q4 (1, 8);

EXECUTE ab_q4 (1, 8);

EXECUTE ab_q4 (1, 8);

EXECUTE ab_q4 (1, 8);

EXECUTE ab_q4 (1, 8);

SELECT
    explain_parallel_append ('execute ab_q4 (2, 2)');

-- Test run-time pruning with IN lists.
PREPARE ab_q5 (int, int, int) AS
SELECT
    avg(a)
FROM
    ab
WHERE
    a IN ($1, $2, $3)
    AND b < 4;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE ab_q5 (1, 2, 3);

EXECUTE ab_q5 (1, 2, 3);

EXECUTE ab_q5 (1, 2, 3);

EXECUTE ab_q5 (1, 2, 3);

EXECUTE ab_q5 (1, 2, 3);

SELECT
    explain_parallel_append ('execute ab_q5 (1, 1, 1)');

SELECT
    explain_parallel_append ('execute ab_q5 (2, 3, 3)');

-- Try some params whose values do not belong to any partition.
-- We'll still get a single subplan in this case, but it should not be scanned.
SELECT
    explain_parallel_append ('execute ab_q5 (33, 44, 55)');

-- Test Parallel Append with PARAM_EXEC Params
SELECT
    explain_parallel_append ('select count(*) from ab where (a = (select 1) or a = (select 3)) and b = 2');

-- Test pruning during parallel nested loop query
CREATE TABLE lprt_a (
    a int NOT NULL
);

-- Insert some values we won't find in ab
INSERT INTO lprt_a
SELECT
    0
FROM
    generate_series(1, 100);

-- and insert some values that we should find.
INSERT INTO lprt_a
VALUES
    (1),
    (1);

ANALYZE lprt_a;

CREATE INDEX ab_a2_b1_a_idx ON ab_a2_b1 (a);

CREATE INDEX ab_a2_b2_a_idx ON ab_a2_b2 (a);

CREATE INDEX ab_a2_b3_a_idx ON ab_a2_b3 (a);

CREATE INDEX ab_a1_b1_a_idx ON ab_a1_b1 (a);

CREATE INDEX ab_a1_b2_a_idx ON ab_a1_b2 (a);

CREATE INDEX ab_a1_b3_a_idx ON ab_a1_b3 (a);

CREATE INDEX ab_a3_b1_a_idx ON ab_a3_b1 (a);

CREATE INDEX ab_a3_b2_a_idx ON ab_a3_b2 (a);

CREATE INDEX ab_a3_b3_a_idx ON ab_a3_b3 (a);

SET enable_hashjoin = 0;

SET enable_mergejoin = 0;

SELECT
    explain_parallel_append ('select avg(ab.a) from ab inner join lprt_a a on ab.a = a.a where a.a in(0, 0, 1)');

-- Ensure the same partitions are pruned when we make the nested loop
-- parameter an Expr rather than a plain Param.
SELECT
    explain_parallel_append ('select avg(ab.a) from ab inner join lprt_a a on ab.a = a.a + 0 where a.a in(0, 0, 1)');

INSERT INTO lprt_a
VALUES
    (3),
    (3);

SELECT
    explain_parallel_append ('select avg(ab.a) from ab inner join lprt_a a on ab.a = a.a where a.a in(1, 0, 3)');

SELECT
    explain_parallel_append ('select avg(ab.a) from ab inner join lprt_a a on ab.a = a.a where a.a in(1, 0, 0)');

DELETE FROM lprt_a
WHERE a = 1;

SELECT
    explain_parallel_append ('select avg(ab.a) from ab inner join lprt_a a on ab.a = a.a where a.a in(1, 0, 0)');

RESET enable_hashjoin;

RESET enable_mergejoin;

RESET parallel_setup_cost;

RESET parallel_tuple_cost;

RESET min_parallel_table_scan_size;

RESET max_parallel_workers_per_gather;

-- Test run-time partition pruning with an initplan
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    ab
WHERE
    a = (
        SELECT
            max(a)
        FROM
            lprt_a)
    AND b = (
        SELECT
            max(a) - 1
        FROM
            lprt_a);

-- Test run-time partition pruning with UNION ALL parents
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        ab
    WHERE
        a = 1
    UNION ALL
    SELECT
        *
    FROM
        ab) ab
WHERE
    b = (
        SELECT
            1);

-- A case containing a UNION ALL with a non-partitioned child.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        ab
    WHERE
        a = 1
    UNION ALL (
        VALUES (10, 5))
    UNION ALL
    SELECT
        *
    FROM
        ab) ab
WHERE
    b = (
        SELECT
            1);

-- Another UNION ALL test, but containing a mix of exec init and exec run-time pruning.
CREATE TABLE xy_1 (
    x int,
    y int
);

INSERT INTO xy_1
    VALUES (100, -10);

SET enable_bitmapscan = 0;

SET enable_indexscan = 0;

SET plan_cache_mode = 'force_generic_plan';

PREPARE ab_q6 AS
SELECT
    *
FROM (
    SELECT
        tableoid::regclass,
        a,
        b
    FROM
        ab
    UNION ALL
    SELECT
        tableoid::regclass,
        x,
        y
    FROM
        xy_1
    UNION ALL
    SELECT
        tableoid::regclass,
        a,
        b
    FROM
        ab) ab
WHERE
    a = $1
    AND b = (
        SELECT
            -10);

-- Ensure the xy_1 subplan is not pruned.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE ab_q6 (1);

-- Ensure we see just the xy_1 row.
EXECUTE ab_q6 (100);

RESET enable_bitmapscan;

RESET enable_indexscan;

RESET plan_cache_mode;

DEALLOCATE ab_q1;

DEALLOCATE ab_q2;

DEALLOCATE ab_q3;

DEALLOCATE ab_q4;

DEALLOCATE ab_q5;

DEALLOCATE ab_q6;

-- UPDATE on a partition subtree has been seen to have problems.
INSERT INTO ab
    VALUES (1, 2);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) UPDATE
    ab_a1
SET
    b = 3
FROM
    ab
WHERE
    ab.a = 1
    AND ab.a = ab_a1.a;

TABLE ab;

-- Test UPDATE where source relation has run-time pruning enabled
TRUNCATE ab;

INSERT INTO ab
VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (2, 1);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) UPDATE
    ab_a1
SET
    b = 3
FROM
    ab_a2
WHERE
    ab_a2.b = (
        SELECT
            1);

SELECT
    tableoid::regclass,
    *
FROM
    ab;

DROP TABLE ab, lprt_a;

-- Join
CREATE TABLE tbl1 (
    col1 int
);

INSERT INTO tbl1
VALUES
    (501),
    (505);

-- Basic table
CREATE TABLE tprt (
    col1 int
)
PARTITION BY RANGE (col1);

CREATE TABLE tprt_1 PARTITION OF tprt
FOR VALUES FROM (1) TO (501);

CREATE TABLE tprt_2 PARTITION OF tprt
FOR VALUES FROM (501) TO (1001);

CREATE TABLE tprt_3 PARTITION OF tprt
FOR VALUES FROM (1001) TO (2001);

CREATE TABLE tprt_4 PARTITION OF tprt
FOR VALUES FROM (2001) TO (3001);

CREATE TABLE tprt_5 PARTITION OF tprt
FOR VALUES FROM (3001) TO (4001);

CREATE TABLE tprt_6 PARTITION OF tprt
FOR VALUES FROM (4001) TO (5001);

CREATE INDEX tprt1_idx ON tprt_1 (col1);

CREATE INDEX tprt2_idx ON tprt_2 (col1);

CREATE INDEX tprt3_idx ON tprt_3 (col1);

CREATE INDEX tprt4_idx ON tprt_4 (col1);

CREATE INDEX tprt5_idx ON tprt_5 (col1);

CREATE INDEX tprt6_idx ON tprt_6 (col1);

INSERT INTO tprt
VALUES
    (10),
    (20),
    (501),
    (502),
    (505),
    (1001),
    (4500);

SET enable_hashjoin = OFF;

SET enable_mergejoin = OFF;

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    JOIN tprt ON tbl1.col1 > tprt.col1;

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    JOIN tprt ON tbl1.col1 = tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 > tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 = tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

-- Multiple partitions
INSERT INTO tbl1
VALUES
    (1001),
    (1010),
    (1011);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 > tprt.col1;

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 = tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 > tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 = tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

-- Last partition
DELETE FROM tbl1;

INSERT INTO tbl1
    VALUES (4400);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    JOIN tprt ON tbl1.col1 < tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 < tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

-- No matching partition
DELETE FROM tbl1;

INSERT INTO tbl1
    VALUES (10000);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    tbl1
    JOIN tprt ON tbl1.col1 = tprt.col1;

SELECT
    tbl1.col1,
    tprt.col1
FROM
    tbl1
    INNER JOIN tprt ON tbl1.col1 = tprt.col1
ORDER BY
    tbl1.col1,
    tprt.col1;

DROP TABLE tbl1, tprt;

-- Test with columns defined in varying orders between each level
CREATE TABLE part_abc (
    a int NOT NULL,
    b int NOT NULL,
    c int NOT NULL
)
PARTITION BY LIST (a);

CREATE TABLE part_bac (
    b int NOT NULL,
    a int NOT NULL,
    c int NOT NULL
)
PARTITION BY LIST (b);

CREATE TABLE part_cab (
    c int NOT NULL,
    a int NOT NULL,
    b int NOT NULL
)
PARTITION BY LIST (c);

CREATE TABLE part_abc_p1 (
    a int NOT NULL,
    b int NOT NULL,
    c int NOT NULL
);

ALTER TABLE part_abc ATTACH PARTITION part_bac
FOR VALUES IN (1);

ALTER TABLE part_bac ATTACH PARTITION part_cab
FOR VALUES IN (2);

ALTER TABLE part_cab ATTACH PARTITION part_abc_p1
FOR VALUES IN (3);

PREPARE part_abc_q1 (int, int, int) AS
SELECT
    *
FROM
    part_abc
WHERE
    a = $1
    AND b = $2
    AND c = $3;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE part_abc_q1 (1, 2, 3);

EXECUTE part_abc_q1 (1, 2, 3);

EXECUTE part_abc_q1 (1, 2, 3);

EXECUTE part_abc_q1 (1, 2, 3);

EXECUTE part_abc_q1 (1, 2, 3);

-- Single partition should be scanned.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE part_abc_q1 (1, 2, 3);

DEALLOCATE part_abc_q1;

DROP TABLE part_abc;

-- Ensure that an Append node properly handles a sub-partitioned table
-- matching without any of its leaf partitions matching the clause.
CREATE TABLE listp (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE listp_1 PARTITION OF listp
FOR VALUES IN (1)
PARTITION BY LIST (b);

CREATE TABLE listp_1_1 PARTITION OF listp_1
FOR VALUES IN (1);

CREATE TABLE listp_2 PARTITION OF listp
FOR VALUES IN (2)
PARTITION BY LIST (b);

CREATE TABLE listp_2_1 PARTITION OF listp_2
FOR VALUES IN (2);

SELECT
    *
FROM
    listp
WHERE
    b = 1;

-- Ensure that an Append node properly can handle selection of all first level
-- partitions before finally detecting the correct set of 2nd level partitions
-- which match the given parameter.
PREPARE q1 (int,
    int) AS
SELECT
    *
FROM
    listp
WHERE
    b IN ($1, $2);

EXECUTE q1 (1,
    2);

EXECUTE q1 (1,
    2);

EXECUTE q1 (1,
    2);

EXECUTE q1 (1,
    2);

EXECUTE q1 (1,
    2);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE q1 (1,
    1);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE q1 (2,
    2);

-- Try with no matching partitions. One subplan should remain in this case,
-- but it shouldn't be executed.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE q1 (0,
    0);

DEALLOCATE q1;

-- Test more complex cases where a not-equal condition further eliminates partitions.
PREPARE q1 (int,
    int,
    int,
    int) AS
SELECT
    *
FROM
    listp
WHERE
    b IN ($1, $2)
    AND $3 <> b
    AND $4 <> b;

EXECUTE q1 (1,
    2,
    3,
    4);

EXECUTE q1 (1,
    2,
    3,
    4);

EXECUTE q1 (1,
    2,
    3,
    4);

EXECUTE q1 (1,
    2,
    3,
    4);

EXECUTE q1 (1,
    2,
    3,
    4);

-- Both partitions allowed by IN clause, but one disallowed by <> clause
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE q1 (1,
    2,
    2,
    0);

-- Both partitions allowed by IN clause, then both excluded again by <> clauses.
-- One subplan will remain in this case, but it should not be executed.
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE q1 (1,
    2,
    2,
    1);

-- Ensure Params that evaluate to NULL properly prune away all partitions
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    listp
WHERE
    a = (
        SELECT
            NULL::int);

DROP TABLE listp;

-- Ensure runtime pruning works with initplans params with boolean types
CREATE TABLE boolvalues (
    value bool NOT NULL
);

INSERT INTO boolvalues
VALUES
    ('t'),
    ('f');

CREATE TABLE boolp (
    a bool
)
PARTITION BY LIST (a);

CREATE TABLE boolp_t PARTITION OF boolp
FOR VALUES IN ('t');

CREATE TABLE boolp_f PARTITION OF boolp
FOR VALUES IN ('f');

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    boolp
WHERE
    a = (
        SELECT
            value
        FROM
            boolvalues
        WHERE
            value);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    boolp
WHERE
    a = (
        SELECT
            value
        FROM
            boolvalues
        WHERE
            NOT value);

DROP TABLE boolp;

--
-- Test run-time pruning of MergeAppend subnodes
--
SET enable_seqscan = OFF;

SET enable_sort = OFF;

CREATE TABLE ma_test (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE ma_test_p1 PARTITION OF ma_test
FOR VALUES FROM (0) TO (10);

CREATE TABLE ma_test_p2 PARTITION OF ma_test
FOR VALUES FROM (10) TO (20);

CREATE TABLE ma_test_p3 PARTITION OF ma_test
FOR VALUES FROM (20) TO (30);

INSERT INTO ma_test
SELECT
    x,
    x
FROM
    generate_series(0, 29) t (x);

CREATE INDEX ON ma_test (b);

ANALYZE ma_test;

PREPARE mt_q1 (int) AS
SELECT
    a
FROM
    ma_test
WHERE
    a >= $1
    AND a % 10 = 5
ORDER BY
    b;

-- Execute query 5 times to allow choose_custom_plan
-- to start considering a generic plan.
EXECUTE mt_q1 (0);

EXECUTE mt_q1 (0);

EXECUTE mt_q1 (0);

EXECUTE mt_q1 (0);

EXECUTE mt_q1 (0);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE mt_q1 (15);

EXECUTE mt_q1 (15);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE mt_q1 (25);

EXECUTE mt_q1 (25);

-- Ensure MergeAppend behaves correctly when no subplans match
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
) EXECUTE mt_q1 (35);

EXECUTE mt_q1 (35);

DEALLOCATE mt_q1;

-- ensure initplan params properly prune partitions
EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    ma_test
WHERE
    a >= (
        SELECT
            min(b)
        FROM
            ma_test_p2)
ORDER BY
    b;

RESET enable_seqscan;

RESET enable_sort;

DROP TABLE ma_test;

RESET enable_indexonlyscan;

--
-- check that pruning works properly when the partition key is of a
-- pseudotype
--
-- array type list partition key
CREATE TABLE pp_arrpart (
    a int[]
)
PARTITION BY LIST (a);

CREATE TABLE pp_arrpart1 PARTITION OF pp_arrpart
FOR VALUES IN ('{1}');

CREATE TABLE pp_arrpart2 PARTITION OF pp_arrpart
FOR VALUES IN ('{2, 3}', '{4, 5}');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_arrpart
WHERE
    a = '{1}';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_arrpart
WHERE
    a = '{1, 2}';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_arrpart
WHERE
    a IN ('{4, 5}', '{1}');

EXPLAIN (
    COSTS OFF
) UPDATE
    pp_arrpart
SET
    a = a
WHERE
    a = '{1}';

EXPLAIN (
    COSTS OFF
) DELETE FROM pp_arrpart
WHERE a = '{1}';

DROP TABLE pp_arrpart;

-- array type hash partition key
CREATE TABLE pph_arrpart (
    a int[]
)
PARTITION BY HASH (a);

CREATE TABLE pph_arrpart1 PARTITION OF pph_arrpart
FOR VALUES WITH (MODULUS 2, REMAINDER 0);

CREATE TABLE pph_arrpart2 PARTITION OF pph_arrpart
FOR VALUES WITH (MODULUS 2, REMAINDER 1);

INSERT INTO pph_arrpart
VALUES
    ('{1}'),
    ('{1, 2}'),
    ('{4, 5}');

SELECT
    tableoid::regclass,
    *
FROM
    pph_arrpart
ORDER BY
    1;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pph_arrpart
WHERE
    a = '{1}';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pph_arrpart
WHERE
    a = '{1, 2}';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pph_arrpart
WHERE
    a IN ('{4, 5}', '{1}');

DROP TABLE pph_arrpart;

-- enum type list partition key
CREATE TYPE pp_colors AS enum (
    'green',
    'blue',
    'black'
);

CREATE TABLE pp_enumpart (
    a pp_colors
)
PARTITION BY LIST (a);

CREATE TABLE pp_enumpart_green PARTITION OF pp_enumpart
FOR VALUES IN ('green');

CREATE TABLE pp_enumpart_blue PARTITION OF pp_enumpart
FOR VALUES IN ('blue');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_enumpart
WHERE
    a = 'blue';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_enumpart
WHERE
    a = 'black';

DROP TABLE pp_enumpart;

DROP TYPE pp_colors;

-- record type as partition key
CREATE TYPE pp_rectype AS (
    a int,
    b int
);

CREATE TABLE pp_recpart (
    a pp_rectype
)
PARTITION BY LIST (a);

CREATE TABLE pp_recpart_11 PARTITION OF pp_recpart
FOR VALUES IN ('(1,1)');

CREATE TABLE pp_recpart_23 PARTITION OF pp_recpart
FOR VALUES IN ('(2,3)');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_recpart
WHERE
    a = '(1,1)'::pp_rectype;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_recpart
WHERE
    a = '(1,2)'::pp_rectype;

DROP TABLE pp_recpart;

DROP TYPE pp_rectype;

-- range type partition key
CREATE TABLE pp_intrangepart (
    a int4range
)
PARTITION BY LIST (a);

CREATE TABLE pp_intrangepart12 PARTITION OF pp_intrangepart
FOR VALUES IN ('[1,2]');

CREATE TABLE pp_intrangepart2inf PARTITION OF pp_intrangepart
FOR VALUES IN ('[2,)');

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_intrangepart
WHERE
    a = '[1,2]'::int4range;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_intrangepart
WHERE
    a = '(1,2)'::int4range;

DROP TABLE pp_intrangepart;

--
-- Ensure the enable_partition_prune GUC properly disables partition pruning.
--
CREATE TABLE pp_lp (
    a int,
    value int
)
PARTITION BY LIST (a);

CREATE TABLE pp_lp1 PARTITION OF pp_lp
FOR VALUES IN (1);

CREATE TABLE pp_lp2 PARTITION OF pp_lp
FOR VALUES IN (2);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_lp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) UPDATE
    pp_lp
SET
    value = 10
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) DELETE FROM pp_lp
WHERE a = 1;

SET enable_partition_pruning = OFF;

SET constraint_exclusion = 'partition';

-- this should not affect the result.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_lp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) UPDATE
    pp_lp
SET
    value = 10
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) DELETE FROM pp_lp
WHERE a = 1;

SET constraint_exclusion = 'off';

-- this should not affect the result.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_lp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) UPDATE
    pp_lp
SET
    value = 10
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) DELETE FROM pp_lp
WHERE a = 1;

DROP TABLE pp_lp;

-- Ensure enable_partition_prune does not affect non-partitioned tables.
CREATE TABLE inh_lp (
    a int,
    value int
);

CREATE TABLE inh_lp1 (
    a int,
    value int,
    CHECK (a = 1)
)
INHERITS (
    inh_lp
);

CREATE TABLE inh_lp2 (
    a int,
    value int,
    CHECK (a = 2)
)
INHERITS (
    inh_lp
);

SET constraint_exclusion = 'partition';

-- inh_lp2 should be removed in the following 3 cases.
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    inh_lp
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) UPDATE
    inh_lp
SET
    value = 10
WHERE
    a = 1;

EXPLAIN (
    COSTS OFF
) DELETE FROM inh_lp
WHERE a = 1;

-- Ensure we don't exclude normal relations when we only expect to exclude
-- inheritance children
EXPLAIN (
    COSTS OFF
) UPDATE
    inh_lp1
SET
    value = 10
WHERE
    a = 2;

DROP TABLE inh_lp CASCADE;

RESET enable_partition_pruning;

RESET constraint_exclusion;

-- Check pruning for a partition tree containing only temporary relations
CREATE temp TABLE pp_temp_parent (
    a int
)
PARTITION BY LIST (a);

CREATE temp TABLE pp_temp_part_1 PARTITION OF pp_temp_parent
FOR VALUES IN (1);

CREATE temp TABLE pp_temp_part_def PARTITION OF pp_temp_parent DEFAULT;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_temp_parent
WHERE
    TRUE;

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pp_temp_parent
WHERE
    a = 2;

DROP TABLE pp_temp_parent;

-- Stress run-time partition pruning a bit more, per bug reports
CREATE temp TABLE p (
    a int,
    b int,
    c int
)
PARTITION BY LIST (a);

CREATE temp TABLE p1 PARTITION OF p
FOR VALUES IN (1);

CREATE temp TABLE p2 PARTITION OF p
FOR VALUES IN (2);

CREATE temp TABLE q (
    a int,
    b int,
    c int
)
PARTITION BY LIST (a);

CREATE temp TABLE q1 PARTITION OF q
FOR VALUES IN (1)
PARTITION BY LIST (b);

CREATE temp TABLE q11 PARTITION OF q1
FOR VALUES IN (1)
PARTITION BY LIST (c);

CREATE temp TABLE q111 PARTITION OF q11
FOR VALUES IN (1);

CREATE temp TABLE q2 PARTITION OF q
FOR VALUES IN (2)
PARTITION BY LIST (b);

CREATE temp TABLE q21 PARTITION OF q2
FOR VALUES IN (1);

CREATE temp TABLE q22 PARTITION OF q2
FOR VALUES IN (2);

INSERT INTO q22
    VALUES (2, 2, 3);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM (
    SELECT
        *
    FROM
        p
    UNION ALL
    SELECT
        *
    FROM
        q1
    UNION ALL
    SELECT
        1,
        1,
        1) s (a,
    b,
    c)
WHERE
    s.a = 1
    AND s.b = 1
    AND s.c = (
        SELECT
            1);

SELECT
    *
FROM (
    SELECT
        *
    FROM
        p
    UNION ALL
    SELECT
        *
    FROM
        q1
    UNION ALL
    SELECT
        1,
        1,
        1) s (a,
    b,
    c)
WHERE
    s.a = 1
    AND s.b = 1
    AND s.c = (
        SELECT
            1);

PREPARE q (int,
    int) AS
SELECT
    *
FROM (
    SELECT
        *
    FROM
        p
    UNION ALL
    SELECT
        *
    FROM
        q1
    UNION ALL
    SELECT
        1,
        1,
        1) s (a,
    b,
    c)
WHERE
    s.a = $1
    AND s.b = $2
    AND s.c = (
        SELECT
            1);

SET plan_cache_mode TO force_generic_plan;

EXPLAIN (
    COSTS OFF
) EXECUTE q (1,
    1);

EXECUTE q (1,
    1);

RESET plan_cache_mode;

DROP TABLE p, q;

-- Ensure run-time pruning works correctly when we match a partitioned table
-- on the first level but find no matching partitions on the second level.
CREATE TABLE listp (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE listp1 PARTITION OF listp
FOR VALUES IN (1);

CREATE TABLE listp2 PARTITION OF listp
FOR VALUES IN (2)
PARTITION BY LIST (b);

CREATE TABLE listp2_10 PARTITION OF listp2
FOR VALUES IN (10);

EXPLAIN (
    ANALYZE,
    COSTS OFF,
    summary OFF,
    timing OFF
)
SELECT
    *
FROM
    listp
WHERE
    a = (
        SELECT
            2)
    AND b <> 10;

--
-- check that a partition directly accessed in a query is excluded with
-- constraint_exclusion = on
--
-- turn off partition pruning, so that it doesn't interfere
SET enable_partition_pruning TO OFF;

-- setting constraint_exclusion to 'partition' disables exclusion
SET constraint_exclusion TO 'partition';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    listp1
WHERE
    a = 2;

EXPLAIN (
    COSTS OFF
) UPDATE
    listp1
SET
    a = 1
WHERE
    a = 2;

-- constraint exclusion enabled
SET constraint_exclusion TO 'on';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    listp1
WHERE
    a = 2;

EXPLAIN (
    COSTS OFF
) UPDATE
    listp1
SET
    a = 1
WHERE
    a = 2;

RESET constraint_exclusion;

RESET enable_partition_pruning;

DROP TABLE listp;

