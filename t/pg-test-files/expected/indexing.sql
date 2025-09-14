-- Creating an index on a partitioned table makes the partitions
-- automatically get the index
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a);

-- relhassubclass of a partitioned index is false before creating any partition.
-- It will be set after the first partition is created.
CREATE INDEX idxpart_idx ON idxpart (a);

SELECT
    relhassubclass
FROM
    pg_class
WHERE
    relname = 'idxpart_idx';

-- Check that partitioned indexes are present in pg_indexes.
SELECT
    indexdef
FROM
    pg_indexes
WHERE
    indexname LIKE 'idxpart_idx%';

DROP INDEX idxpart_idx;

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (10);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (10) TO (100)
PARTITION BY RANGE (b);

CREATE TABLE idxpart21 PARTITION OF idxpart2
FOR VALUES FROM (0) TO (100);

-- Even with partitions, relhassubclass should not be set if a partitioned
-- index is created only on the parent.
CREATE INDEX idxpart_idx ON ONLY idxpart (a);

SELECT
    relhassubclass
FROM
    pg_class
WHERE
    relname = 'idxpart_idx';

DROP INDEX idxpart_idx;

CREATE INDEX ON idxpart (a);

SELECT
    relname,
    relkind,
    relhassubclass,
    inhparent::regclass
FROM
    pg_class
    LEFT JOIN pg_index ix ON (indexrelid = oid)
    LEFT JOIN pg_inherits ON (ix.indexrelid = inhrelid)
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- Some unsupported features
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (10);

CREATE INDEX CONCURRENTLY ON idxpart (a);

DROP TABLE idxpart;

-- Verify bugfix with query on indexed partitioned table with no partitions
-- https://postgr.es/m/20180124162006.pmapfiznhgngwtjf@alvherre.pgsql
CREATE TABLE idxpart (
    col1 int
)
PARTITION BY RANGE (col1);

CREATE INDEX ON idxpart (col1);

CREATE TABLE idxpart_two (
    col2 int
);

SELECT
    col2
FROM
    idxpart_two fk
    LEFT OUTER JOIN idxpart pk ON (col1 = col2);

DROP TABLE idxpart, idxpart_two;

-- Verify bugfix with index rewrite on ALTER TABLE / SET DATA TYPE
-- https://postgr.es/m/CAKcux6mxNCGsgATwf5CGMF8g4WSupCXicCVMeKUTuWbyxHOMsQ@mail.gmail.com
CREATE TABLE idxpart (
    a int,
    b text,
    c int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (MINVALUE) TO (MAXVALUE);

CREATE INDEX partidx_abc_idx ON idxpart (a, b, c);

INSERT INTO idxpart (a, b, c)
SELECT
    i,
    i,
    i
FROM
    generate_series(1, 50) i;

ALTER TABLE idxpart
    ALTER COLUMN c TYPE numeric;

DROP TABLE idxpart;

-- If a table without index is attached as partition to a table with
-- an index, the index is automatically created
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a);

CREATE INDEX idxparti ON idxpart (a);

CREATE INDEX idxparti2 ON idxpart (b, c);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

\d idxpart1
ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (10);

\d idxpart1
\d+ idxpart1_a_idx
\d+ idxpart1_b_c_idx
DROP TABLE idxpart;

-- If a partition already has an index, don't create a duplicative one
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0, 0) TO (10, 10);

CREATE INDEX ON idxpart1 (a, b);

CREATE INDEX ON idxpart (a, b);

\d idxpart1
SELECT
    relname,
    relkind,
    relhassubclass,
    inhparent::regclass
FROM
    pg_class
    LEFT JOIN pg_index ix ON (indexrelid = oid)
    LEFT JOIN pg_inherits ON (ix.indexrelid = inhrelid)
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- DROP behavior for partitioned indexes
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE INDEX ON idxpart (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (10);

DROP INDEX idxpart1_a_idx;

-- no way
DROP INDEX idxpart_a_idx;

-- both indexes go away
SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

CREATE INDEX ON idxpart (a);

DROP TABLE idxpart1;

-- the index on partition goes away too
SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- ALTER INDEX .. ATTACH, error cases
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0, 0) TO (10, 10);

CREATE INDEX idxpart_a_b_idx ON ONLY idxpart (a, b);

CREATE INDEX idxpart1_a_b_idx ON idxpart1 (a, b);

CREATE INDEX idxpart1_tst1 ON idxpart1 (b, a);

CREATE INDEX idxpart1_tst2 ON idxpart1 USING HASH (a);

CREATE INDEX idxpart1_tst3 ON idxpart1 (a, b)
WHERE
    a > 10;

ALTER INDEX idxpart ATTACH PARTITION idxpart1;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart_a_b_idx;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_b_idx;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_tst1;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_tst2;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_tst3;

-- OK
ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_a_b_idx;

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_a_b_idx;

-- quiet
-- reject dupe
CREATE INDEX idxpart1_2_a_b ON idxpart1 (a, b);

ALTER INDEX idxpart_a_b_idx ATTACH PARTITION idxpart1_2_a_b;

DROP TABLE idxpart;

-- make sure everything's gone
SELECT
    indexrelid::regclass,
    indrelid::regclass
FROM
    pg_index
WHERE
    indexrelid::regclass::text LIKE 'idxpart%';

-- Don't auto-attach incompatible indexes
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    a int,
    b int
);

CREATE INDEX ON idxpart1 USING HASH (a);

CREATE INDEX ON idxpart1 (a)
WHERE
    b > 1;

CREATE INDEX ON idxpart1 ((a + 0));

CREATE INDEX ON idxpart1 (a, a);

CREATE INDEX ON idxpart (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (1000);

\d idxpart1
DROP TABLE idxpart;

-- If CREATE INDEX ONLY, don't create indexes on partitions; and existing
-- indexes on partitions don't change parent.  ALTER INDEX ATTACH can change
-- the parent after the fact.
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (100);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (100) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE idxpart21 PARTITION OF idxpart2
FOR VALUES FROM (100) TO (200);

CREATE TABLE idxpart22 PARTITION OF idxpart2
FOR VALUES FROM (200) TO (300);

CREATE INDEX ON idxpart22 (a);

CREATE INDEX ON ONLY idxpart2 (a);

CREATE INDEX ON idxpart (a);

-- Here we expect that idxpart1 and idxpart2 have a new index, but idxpart21
-- does not; also, idxpart22 is not attached.
\d idxpart1
\d idxpart2
\d idxpart21
SELECT
    indexrelid::regclass,
    indrelid::regclass,
    inhparent::regclass
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
WHERE
    indexrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

ALTER INDEX idxpart2_a_idx ATTACH PARTITION idxpart22_a_idx;

SELECT
    indexrelid::regclass,
    indrelid::regclass,
    inhparent::regclass
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
WHERE
    indexrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

-- attaching idxpart22 is not enough to set idxpart22_a_idx valid ...
ALTER INDEX idxpart2_a_idx ATTACH PARTITION idxpart22_a_idx;

\d idxpart2
-- ... but this one is.
CREATE INDEX ON idxpart21 (a);

ALTER INDEX idxpart2_a_idx ATTACH PARTITION idxpart21_a_idx;

\d idxpart2
DROP TABLE idxpart;

-- When a table is attached a partition and it already has an index, a
-- duplicate index should not get created, but rather the index becomes
-- attached to the parent's index.
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a);

CREATE INDEX idxparti ON idxpart (a);

CREATE INDEX idxparti2 ON idxpart (b, c);

CREATE TABLE idxpart1 (
    LIKE idxpart INCLUDING indexes
);

\d idxpart1
SELECT
    relname,
    relkind,
    inhparent::regclass
FROM
    pg_class
    LEFT JOIN pg_index ix ON (indexrelid = oid)
    LEFT JOIN pg_inherits ON (ix.indexrelid = inhrelid)
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (10);

\d idxpart1
SELECT
    relname,
    relkind,
    inhparent::regclass
FROM
    pg_class
    LEFT JOIN pg_index ix ON (indexrelid = oid)
    LEFT JOIN pg_inherits ON (ix.indexrelid = inhrelid)
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- Verify that attaching an invalid index does not mark the parent index valid.
-- On the other hand, attaching a valid index marks not only its direct
-- ancestor valid, but also any indirect ancestor that was only missing the one
-- that was just made valid
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (1) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE idxpart11 PARTITION OF idxpart1
FOR VALUES FROM (1) TO (100);

CREATE INDEX ON ONLY idxpart1 (a);

CREATE INDEX ON ONLY idxpart (a);

-- this results in two invalid indexes:
SELECT
    relname,
    indisvalid
FROM
    pg_class
    JOIN pg_index ON indexrelid = oid
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

-- idxpart1_a_idx is not valid, so idxpart_a_idx should not become valid:
ALTER INDEX idxpart_a_idx ATTACH PARTITION idxpart1_a_idx;

SELECT
    relname,
    indisvalid
FROM
    pg_class
    JOIN pg_index ON indexrelid = oid
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

-- after creating and attaching this, both idxpart1_a_idx and idxpart_a_idx
-- should become valid
CREATE INDEX ON idxpart11 (a);

ALTER INDEX idxpart1_a_idx ATTACH PARTITION idxpart11_a_idx;

SELECT
    relname,
    indisvalid
FROM
    pg_class
    JOIN pg_index ON indexrelid = oid
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- verify dependency handling during ALTER TABLE DETACH PARTITION
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

CREATE INDEX ON idxpart1 (a);

CREATE INDEX ON idxpart (a);

CREATE TABLE idxpart2 (
    LIKE idxpart
);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0000) TO (1000);

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE idxpart3 PARTITION OF idxpart
FOR VALUES FROM (2000) TO (3000);

SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

-- a) after detaching partitions, the indexes can be dropped independently
ALTER TABLE idxpart DETACH PARTITION idxpart1;

ALTER TABLE idxpart DETACH PARTITION idxpart2;

ALTER TABLE idxpart DETACH PARTITION idxpart3;

DROP INDEX idxpart1_a_idx;

DROP INDEX idxpart2_a_idx;

DROP INDEX idxpart3_a_idx;

SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart, idxpart1, idxpart2, idxpart3;

SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

CREATE INDEX ON idxpart1 (a);

CREATE INDEX ON idxpart (a);

CREATE TABLE idxpart2 (
    LIKE idxpart
);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0000) TO (1000);

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE idxpart3 PARTITION OF idxpart
FOR VALUES FROM (2000) TO (3000);

-- b) after detaching, dropping the index on parent does not remove the others
SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

ALTER TABLE idxpart DETACH PARTITION idxpart1;

ALTER TABLE idxpart DETACH PARTITION idxpart2;

ALTER TABLE idxpart DETACH PARTITION idxpart3;

DROP INDEX idxpart_a_idx;

SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart, idxpart1, idxpart2, idxpart3;

SELECT
    relname,
    relkind
FROM
    pg_class
WHERE
    relname LIKE 'idxpart%'
ORDER BY
    relname;

CREATE TABLE idxpart (
    a int,
    b int,
    c int
)
PARTITION BY RANGE (a);

CREATE INDEX ON idxpart (c);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (250);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (250) TO (500);

ALTER TABLE idxpart DETACH PARTITION idxpart2;

\d idxpart2
ALTER TABLE idxpart2
    DROP COLUMN c;

\d idxpart2
DROP TABLE idxpart, idxpart2;

-- Verify that expression indexes inherit correctly
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

CREATE INDEX ON idxpart1 ((a + b));

CREATE INDEX ON idxpart ((a + b));

CREATE TABLE idxpart2 (
    LIKE idxpart
);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0000) TO (1000);

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE idxpart3 PARTITION OF idxpart
FOR VALUES FROM (2000) TO (3000);

SELECT
    relname AS child,
    inhparent::regclass AS parent,
    pg_get_indexdef AS childdef
FROM
    pg_class
    JOIN pg_inherits ON inhrelid = oid,
    LATERAL pg_get_indexdef(pg_class.oid)
WHERE
    relkind IN ('i', 'I')
    AND relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- Verify behavior for collation (mis)matches
CREATE TABLE idxpart (
    a text
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

CREATE TABLE idxpart2 (
    LIKE idxpart
);

CREATE INDEX ON idxpart2 (a COLLATE "POSIX");

CREATE INDEX ON idxpart2 (a);

CREATE INDEX ON idxpart2 (a COLLATE "C");

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM ('aaa') TO ('bbb');

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM ('bbb') TO ('ccc');

CREATE TABLE idxpart3 PARTITION OF idxpart
FOR VALUES FROM ('ccc') TO ('ddd');

CREATE INDEX ON idxpart (a COLLATE "C");

CREATE TABLE idxpart4 PARTITION OF idxpart
FOR VALUES FROM ('ddd') TO ('eee');

SELECT
    relname AS child,
    inhparent::regclass AS parent,
    pg_get_indexdef AS childdef
FROM
    pg_class
    LEFT JOIN pg_inherits ON inhrelid = oid,
    LATERAL pg_get_indexdef(pg_class.oid)
WHERE
    relkind IN ('i', 'I')
    AND relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- Verify behavior for opclass (mis)matches
CREATE TABLE idxpart (
    a text
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

CREATE TABLE idxpart2 (
    LIKE idxpart
);

CREATE INDEX ON idxpart2 (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM ('aaa') TO ('bbb');

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM ('bbb') TO ('ccc');

CREATE TABLE idxpart3 PARTITION OF idxpart
FOR VALUES FROM ('ccc') TO ('ddd');

CREATE INDEX ON idxpart (a text_pattern_ops);

CREATE TABLE idxpart4 PARTITION OF idxpart
FOR VALUES FROM ('ddd') TO ('eee');

-- must *not* have attached the index we created on idxpart2
SELECT
    relname AS child,
    inhparent::regclass AS parent,
    pg_get_indexdef AS childdef
FROM
    pg_class
    LEFT JOIN pg_inherits ON inhrelid = oid,
    LATERAL pg_get_indexdef(pg_class.oid)
WHERE
    relkind IN ('i', 'I')
    AND relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP INDEX idxpart_a_idx;

CREATE INDEX ON ONLY idxpart (a text_pattern_ops);

-- must reject
ALTER INDEX idxpart_a_idx ATTACH PARTITION idxpart2_a_idx;

DROP TABLE idxpart;

-- Verify that attaching indexes maps attribute numbers correctly
CREATE TABLE idxpart (
    col1 int,
    a int,
    col2 int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    b int,
    col1 int,
    col2 int,
    col3 int,
    a int
);

ALTER TABLE idxpart
    DROP COLUMN col1,
    DROP COLUMN col2;

ALTER TABLE idxpart1
    DROP COLUMN col1,
    DROP COLUMN col2,
    DROP COLUMN col3;

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (1000);

CREATE INDEX idxpart_1_idx ON ONLY idxpart (b, a);

CREATE INDEX idxpart1_1_idx ON idxpart1 (b, a);

CREATE INDEX idxpart1_1b_idx ON idxpart1 (b);

-- test expressions and partial-index predicate, too
CREATE INDEX idxpart_2_idx ON ONLY idxpart ((b + a))
WHERE
    a > 1;

CREATE INDEX idxpart1_2_idx ON idxpart1 ((b + a))
WHERE
    a > 1;

CREATE INDEX idxpart1_2b_idx ON idxpart1 ((a + b))
WHERE
    a > 1;

CREATE INDEX idxpart1_2c_idx ON idxpart1 ((b + a))
WHERE
    b > 1;

ALTER INDEX idxpart_1_idx ATTACH PARTITION idxpart1_1b_idx;

-- fail
ALTER INDEX idxpart_1_idx ATTACH PARTITION idxpart1_1_idx;

ALTER INDEX idxpart_2_idx ATTACH PARTITION idxpart1_2b_idx;

-- fail
ALTER INDEX idxpart_2_idx ATTACH PARTITION idxpart1_2c_idx;

-- fail
ALTER INDEX idxpart_2_idx ATTACH PARTITION idxpart1_2_idx;

-- ok
SELECT
    relname AS child,
    inhparent::regclass AS parent,
    pg_get_indexdef AS childdef
FROM
    pg_class
    LEFT JOIN pg_inherits ON inhrelid = oid,
    LATERAL pg_get_indexdef(pg_class.oid)
WHERE
    relkind IN ('i', 'I')
    AND relname LIKE 'idxpart%'
ORDER BY
    relname;

DROP TABLE idxpart;

-- Make sure the partition columns are mapped correctly
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a);

CREATE INDEX idxparti ON idxpart (a);

CREATE INDEX idxparti2 ON idxpart (c, b);

CREATE TABLE idxpart1 (
    c text,
    a int,
    b int
);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (10);

CREATE TABLE idxpart2 (
    c text,
    a int,
    b int
);

CREATE INDEX ON idxpart2 (a);

CREATE INDEX ON idxpart2 (c, b);

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (10) TO (20);

SELECT
    c.relname,
    pg_get_indexdef(indexrelid)
FROM
    pg_class c
    JOIN pg_index i ON c.oid = i.indexrelid
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- Verify that columns are mapped correctly in expression indexes
CREATE TABLE idxpart (
    col1 int,
    col2 int,
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    col2 int,
    b int,
    col1 int,
    a int
);

CREATE TABLE idxpart2 (
    col1 int,
    col2 int,
    b int,
    a int
);

ALTER TABLE idxpart
    DROP COLUMN col1,
    DROP COLUMN col2;

ALTER TABLE idxpart1
    DROP COLUMN col1,
    DROP COLUMN col2;

ALTER TABLE idxpart2
    DROP COLUMN col1,
    DROP COLUMN col2;

CREATE INDEX ON idxpart2 (abs(b));

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (0) TO (1);

CREATE INDEX ON idxpart (abs(b));

CREATE INDEX ON idxpart ((b + 1));

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (1) TO (2);

SELECT
    c.relname,
    pg_get_indexdef(indexrelid)
FROM
    pg_class c
    JOIN pg_index i ON c.oid = i.indexrelid
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- Verify that columns are mapped correctly for WHERE in a partial index
CREATE TABLE idxpart (
    col1 int,
    a int,
    col3 int,
    b int
)
PARTITION BY RANGE (a);

ALTER TABLE idxpart
    DROP COLUMN col1,
    DROP COLUMN col3;

CREATE TABLE idxpart1 (
    col1 int,
    col2 int,
    col3 int,
    col4 int,
    b int,
    a int
);

ALTER TABLE idxpart1
    DROP COLUMN col1,
    DROP COLUMN col2,
    DROP COLUMN col3,
    DROP COLUMN col4;

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (1000);

CREATE TABLE idxpart2 (
    col1 int,
    col2 int,
    b int,
    a int
);

CREATE INDEX ON idxpart2 (a)
WHERE
    b > 1000;

ALTER TABLE idxpart2
    DROP COLUMN col1,
    DROP COLUMN col2;

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (1000) TO (2000);

CREATE INDEX ON idxpart (a)
WHERE
    b > 1000;

SELECT
    c.relname,
    pg_get_indexdef(indexrelid)
FROM
    pg_class c
    JOIN pg_index i ON c.oid = i.indexrelid
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- Column number mapping: dropped columns in the partition
CREATE TABLE idxpart1 (
    drop_1 int,
    drop_2 int,
    col_keep int,
    drop_3 int
);

ALTER TABLE idxpart1
    DROP COLUMN drop_1;

ALTER TABLE idxpart1
    DROP COLUMN drop_2;

ALTER TABLE idxpart1
    DROP COLUMN drop_3;

CREATE INDEX ON idxpart1 (col_keep);

CREATE TABLE idxpart (
    col_keep int
)
PARTITION BY RANGE (col_keep);

CREATE INDEX ON idxpart (col_keep);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (1000);

\d idxpart
\d idxpart1
SELECT
    attrelid::regclass,
    attname,
    attnum
FROM
    pg_attribute
WHERE
    attrelid::regclass::text LIKE 'idxpart%'
    AND attnum > 0
ORDER BY
    attrelid::regclass,
    attnum;

DROP TABLE idxpart;

-- Column number mapping: dropped columns in the parent table
CREATE TABLE idxpart (
    drop_1 int,
    drop_2 int,
    col_keep int,
    drop_3 int
)
PARTITION BY RANGE (col_keep);

ALTER TABLE idxpart
    DROP COLUMN drop_1;

ALTER TABLE idxpart
    DROP COLUMN drop_2;

ALTER TABLE idxpart
    DROP COLUMN drop_3;

CREATE TABLE idxpart1 (
    col_keep int
);

CREATE INDEX ON idxpart1 (col_keep);

CREATE INDEX ON idxpart (col_keep);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (1000);

\d idxpart
\d idxpart1
SELECT
    attrelid::regclass,
    attname,
    attnum
FROM
    pg_attribute
WHERE
    attrelid::regclass::text LIKE 'idxpart%'
    AND attnum > 0
ORDER BY
    attrelid::regclass,
    attnum;

DROP TABLE idxpart;

--
-- Constraint-related indexes
--
-- Verify that it works to add primary key / unique to partitioned tables
CREATE TABLE idxpart (
    a int PRIMARY KEY,
    b int
)
PARTITION BY RANGE (a);

\d idxpart
-- multiple primary key on child should fail
CREATE TABLE failpart PARTITION OF idxpart (b PRIMARY KEY)
FOR VALUES FROM (0) TO (100);

DROP TABLE idxpart;

-- primary key on child is okay if there's no PK in the parent, though
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1pk PARTITION OF idxpart (a PRIMARY KEY)
FOR VALUES FROM (0) TO (100);

\d idxpart1pk
DROP TABLE idxpart;

-- Failing to use the full partition key is not allowed
CREATE TABLE idxpart (
    a int UNIQUE,
    b int
)
PARTITION BY RANGE (a, b);

CREATE TABLE idxpart (
    a int,
    b int UNIQUE
)
PARTITION BY RANGE (a, b);

CREATE TABLE idxpart (
    a int PRIMARY KEY,
    b int
)
PARTITION BY RANGE (b, a);

CREATE TABLE idxpart (
    a int,
    b int PRIMARY KEY
)
PARTITION BY RANGE (b, a);

-- OK if you use them in some other order
CREATE TABLE idxpart (
    a int,
    b int,
    c text,
    PRIMARY KEY (a, b, c)
)
PARTITION BY RANGE (b, c, a);

DROP TABLE idxpart;

-- not other types of index-based constraints
CREATE TABLE idxpart (
    a int,
    EXCLUDE (a WITH =)
)
PARTITION BY RANGE (a);

-- no expressions in partition key for PK/UNIQUE
CREATE TABLE idxpart (
    a int PRIMARY KEY,
    b int
)
PARTITION BY RANGE ((b + a));

CREATE TABLE idxpart (
    a int UNIQUE,
    b int
)
PARTITION BY RANGE ((b + a));

-- use ALTER TABLE to add a primary key
CREATE TABLE idxpart (
    a int,
    b int,
    c text
)
PARTITION BY RANGE (a, b);

ALTER TABLE idxpart
    ADD PRIMARY KEY (a);

-- not an incomplete one though
ALTER TABLE idxpart
    ADD PRIMARY KEY (a, b);

-- this works
\d idxpart
CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0, 0) TO (1000, 1000);

\d idxpart1
DROP TABLE idxpart;

-- use ALTER TABLE to add a unique constraint
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a, b);

ALTER TABLE idxpart
    ADD UNIQUE (a);

-- not an incomplete one though
ALTER TABLE idxpart
    ADD UNIQUE (b, a);

-- this works
\d idxpart
DROP TABLE idxpart;

-- Exclusion constraints cannot be added
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

ALTER TABLE idxpart
    ADD EXCLUDE (a WITH =);

DROP TABLE idxpart;

-- When (sub)partitions are created, they also contain the constraint
CREATE TABLE idxpart (
    a int,
    b int,
    PRIMARY KEY (a, b)
)
PARTITION BY RANGE (a, b);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (1, 1) TO (10, 10);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (10, 10) TO (20, 20)
PARTITION BY RANGE (b);

CREATE TABLE idxpart21 PARTITION OF idxpart2
FOR VALUES FROM (10) TO (15);

CREATE TABLE idxpart22 PARTITION OF idxpart2
FOR VALUES FROM (15) TO (20);

CREATE TABLE idxpart3 (
    b int NOT NULL,
    a int NOT NULL
);

ALTER TABLE idxpart ATTACH PARTITION idxpart3
FOR VALUES FROM (20, 20) TO (30, 30);

SELECT
    conname,
    contype,
    conrelid::regclass,
    conindid::regclass,
    conkey
FROM
    pg_constraint
WHERE
    conrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    conname;

DROP TABLE idxpart;

-- Verify that multi-layer partitioning honors the requirement that all
-- columns in the partition key must appear in primary/unique key
CREATE TABLE idxpart (
    a int,
    b int,
    PRIMARY KEY (a)
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (b);

-- fail
DROP TABLE idxpart;

-- Ditto for the ATTACH PARTITION case
CREATE TABLE idxpart (
    a int UNIQUE,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    a int NOT NULL,
    b int,
    UNIQUE (a, b)
)
PARTITION BY RANGE (a, b);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (1) TO (1000);

DROP TABLE idxpart, idxpart1;

-- Multi-layer partitioning works correctly in this case:
CREATE TABLE idxpart (
    a int,
    b int,
    PRIMARY KEY (a, b)
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (0) TO (1000)
PARTITION BY RANGE (b);

CREATE TABLE idxpart21 PARTITION OF idxpart2
FOR VALUES FROM (0) TO (1000);

SELECT
    conname,
    contype,
    conrelid::regclass,
    conindid::regclass,
    conkey
FROM
    pg_constraint
WHERE
    conrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    conname;

DROP TABLE idxpart;

-- If a partitioned table has a unique/PK constraint, then it's not possible
-- to drop the corresponding constraint in the children; nor it's possible
-- to drop the indexes individually.  Dropping the constraint in the parent
-- gets rid of the lot.
CREATE TABLE idxpart (
    i int
)
PARTITION BY HASH (i);

CREATE TABLE idxpart0 PARTITION OF idxpart (i)
FOR VALUES WITH (MODULUS 2, REMAINDER 0);

CREATE TABLE idxpart1 PARTITION OF idxpart (i)
FOR VALUES WITH (MODULUS 2, REMAINDER 1);

ALTER TABLE idxpart0
    ADD PRIMARY KEY (i);

ALTER TABLE idxpart
    ADD PRIMARY KEY (i);

SELECT
    indrelid::regclass,
    indexrelid::regclass,
    inhparent::regclass,
    indisvalid,
    conname,
    conislocal,
    coninhcount,
    connoinherit,
    convalidated
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
    LEFT JOIN pg_constraint con ON (idx.indexrelid = con.conindid)
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP INDEX idxpart0_pkey;

-- fail
DROP INDEX idxpart1_pkey;

-- fail
ALTER TABLE idxpart0
    DROP CONSTRAINT idxpart0_pkey;

-- fail
ALTER TABLE idxpart1
    DROP CONSTRAINT idxpart1_pkey;

-- fail
ALTER TABLE idxpart
    DROP CONSTRAINT idxpart_pkey;

-- ok
SELECT
    indrelid::regclass,
    indexrelid::regclass,
    inhparent::regclass,
    indisvalid,
    conname,
    conislocal,
    coninhcount,
    connoinherit,
    convalidated
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
    LEFT JOIN pg_constraint con ON (idx.indexrelid = con.conindid)
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- If the partition to be attached already has a primary key, fail if
-- it doesn't match the parent's PK.
CREATE TABLE idxpart (
    c1 int PRIMARY KEY,
    c2 int,
    c3 varchar(10)
)
PARTITION BY RANGE (c1);

CREATE TABLE idxpart1 (
    LIKE idxpart
);

ALTER TABLE idxpart1
    ADD PRIMARY KEY (c1, c2);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (100) TO (200);

DROP TABLE idxpart, idxpart1;

-- Ditto if there is some distance between the PKs (subpartitioning)
CREATE TABLE idxpart (
    a int,
    b int,
    PRIMARY KEY (a)
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    a int NOT NULL,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart11 (
    a int NOT NULL,
    b int PRIMARY KEY
);

ALTER TABLE idxpart1 ATTACH PARTITION idxpart11
FOR VALUES FROM (0) TO (1000);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (0) TO (10000);

DROP TABLE idxpart, idxpart1, idxpart11;

-- If a partitioned table has a constraint whose index is not valid,
-- attaching a missing partition makes it valid.
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart0 (
    LIKE idxpart
);

ALTER TABLE idxpart0
    ADD PRIMARY KEY (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart0
FOR VALUES FROM (0) TO (1000);

ALTER TABLE ONLY idxpart
    ADD PRIMARY KEY (a);

SELECT
    indrelid::regclass,
    indexrelid::regclass,
    inhparent::regclass,
    indisvalid,
    conname,
    conislocal,
    coninhcount,
    connoinherit,
    convalidated
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
    LEFT JOIN pg_constraint con ON (idx.indexrelid = con.conindid)
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

ALTER INDEX idxpart_pkey ATTACH PARTITION idxpart0_pkey;

SELECT
    indrelid::regclass,
    indexrelid::regclass,
    inhparent::regclass,
    indisvalid,
    conname,
    conislocal,
    coninhcount,
    connoinherit,
    convalidated
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
    LEFT JOIN pg_constraint con ON (idx.indexrelid = con.conindid)
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- Related to the above scenario: ADD PRIMARY KEY on the parent mustn't
-- automatically propagate NOT NULL to child columns.
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart0 (
    LIKE idxpart
);

ALTER TABLE idxpart0
    ADD UNIQUE (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart0 DEFAULT;

ALTER TABLE ONLY idxpart
    ADD PRIMARY KEY (a);

-- fail, no NOT NULL constraint
ALTER TABLE idxpart0
    ALTER COLUMN a SET NOT NULL;

ALTER TABLE ONLY idxpart
    ADD PRIMARY KEY (a);

-- now it works
ALTER TABLE idxpart0
    ALTER COLUMN a DROP NOT NULL;

-- fail, pkey needs it
DROP TABLE idxpart;

-- if a partition has a unique index without a constraint, does not attach
-- automatically; creates a new index instead.
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    a int NOT NULL,
    b int
);

CREATE UNIQUE INDEX ON idxpart1 (a);

ALTER TABLE idxpart
    ADD PRIMARY KEY (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (1) TO (1000);

SELECT
    indrelid::regclass,
    indexrelid::regclass,
    inhparent::regclass,
    indisvalid,
    conname,
    conislocal,
    coninhcount,
    connoinherit,
    convalidated
FROM
    pg_index idx
    LEFT JOIN pg_inherits inh ON (idx.indexrelid = inh.inhrelid)
    LEFT JOIN pg_constraint con ON (idx.indexrelid = con.conindid)
WHERE
    indrelid::regclass::text LIKE 'idxpart%'
ORDER BY
    indexrelid::regclass::text COLLATE "C";

DROP TABLE idxpart;

-- Can't attach an index without a corresponding constraint
CREATE TABLE idxpart (
    a int,
    b int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 (
    a int NOT NULL,
    b int
);

CREATE UNIQUE INDEX ON idxpart1 (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart1
FOR VALUES FROM (1) TO (1000);

ALTER TABLE ONLY idxpart
    ADD PRIMARY KEY (a);

ALTER INDEX idxpart_pkey ATTACH PARTITION idxpart1_a_idx;

-- fail
DROP TABLE idxpart;

-- Test that unique constraints are working
CREATE TABLE idxpart (
    a int,
    b text,
    PRIMARY KEY (a, b)
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (100000);

CREATE TABLE idxpart2 (
    c int,
    LIKE idxpart
);

INSERT INTO idxpart2 (c, a, b)
    VALUES (42, 572814, 'inserted first');

ALTER TABLE idxpart2
    DROP COLUMN c;

CREATE UNIQUE INDEX ON idxpart (a);

ALTER TABLE idxpart ATTACH PARTITION idxpart2
FOR VALUES FROM (100000) TO (1000000);

INSERT INTO idxpart
VALUES
    (0, 'zero'),
    (42, 'life'),
    (2 ^ 16, 'sixteen');

INSERT INTO idxpart
SELECT
    2 ^ g,
    format('two to power of %s', g)
FROM
    generate_series(15, 17) g;

INSERT INTO idxpart
    VALUES (16, 'sixteen');

INSERT INTO idxpart (b, a)
VALUES
    ('one', 142857),
    ('two', 285714);

INSERT INTO idxpart
SELECT
    a * 2,
    b || b
FROM
    idxpart
WHERE
    a BETWEEN 2 ^ 16 AND 2 ^ 19;

INSERT INTO idxpart
    VALUES (572814, 'five');

INSERT INTO idxpart
    VALUES (857142, 'six');

SELECT
    tableoid::regclass,
    *
FROM
    idxpart
ORDER BY
    a;

DROP TABLE idxpart;

-- intentionally leave some objects around
CREATE TABLE idxpart (
    a int
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart1 PARTITION OF idxpart
FOR VALUES FROM (0) TO (100);

CREATE TABLE idxpart2 PARTITION OF idxpart
FOR VALUES FROM (100) TO (1000)
PARTITION BY RANGE (a);

CREATE TABLE idxpart21 PARTITION OF idxpart2
FOR VALUES FROM (100) TO (200);

CREATE TABLE idxpart22 PARTITION OF idxpart2
FOR VALUES FROM (200) TO (300);

CREATE INDEX ON idxpart22 (a);

CREATE INDEX ON ONLY idxpart2 (a);

ALTER INDEX idxpart2_a_idx ATTACH PARTITION idxpart22_a_idx;

CREATE INDEX ON idxpart (a);

CREATE TABLE idxpart_another (
    a int,
    b int,
    PRIMARY KEY (a, b)
)
PARTITION BY RANGE (a);

CREATE TABLE idxpart_another_1 PARTITION OF idxpart_another
FOR VALUES FROM (0) TO (100);

CREATE TABLE idxpart3 (
    c int,
    b int,
    a int
)
PARTITION BY RANGE (a);

ALTER TABLE idxpart3
    DROP COLUMN b,
    DROP COLUMN c;

CREATE TABLE idxpart31 PARTITION OF idxpart3
FOR VALUES FROM (1000) TO (1200);

CREATE TABLE idxpart32 PARTITION OF idxpart3
FOR VALUES FROM (1200) TO (1400);

ALTER TABLE idxpart ATTACH PARTITION idxpart3
FOR VALUES FROM (1000) TO (2000);

-- More objects intentionally left behind, to verify some pg_dump/pg_upgrade
-- behavior; see https://postgr.es/m/20190321204928.GA17535@alvherre.pgsql
CREATE SCHEMA regress_indexing;

SET search_path TO regress_indexing;

CREATE TABLE pk (
    a int PRIMARY KEY
)
PARTITION BY RANGE (a);

CREATE TABLE pk1 PARTITION OF pk
FOR VALUES FROM (0) TO (1000);

CREATE TABLE pk2 (
    b int,
    a int
);

ALTER TABLE pk2
    DROP COLUMN b;

ALTER TABLE pk2
    ALTER a SET NOT NULL;

ALTER TABLE pk ATTACH PARTITION pk2
FOR VALUES FROM (1000) TO (2000);

CREATE TABLE pk3 PARTITION OF pk
FOR VALUES FROM (2000) TO (3000);

CREATE TABLE pk4 (
    LIKE pk
);

ALTER TABLE pk ATTACH PARTITION pk4
FOR VALUES FROM (3000) TO (4000);

CREATE TABLE pk5 (
    LIKE pk
)
PARTITION BY RANGE (a);

CREATE TABLE pk51 PARTITION OF pk5
FOR VALUES FROM (4000) TO (4500);

CREATE TABLE pk52 PARTITION OF pk5
FOR VALUES FROM (4500) TO (5000);

ALTER TABLE pk ATTACH PARTITION pk5
FOR VALUES FROM (4000) TO (5000);

RESET search_path;

-- Test that covering partitioned indexes work in various cases
CREATE TABLE covidxpart (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE UNIQUE INDEX ON covidxpart (a) INCLUDE (b);

CREATE TABLE covidxpart1 PARTITION OF covidxpart
FOR VALUES IN (1);

CREATE TABLE covidxpart2 PARTITION OF covidxpart
FOR VALUES IN (2);

INSERT INTO covidxpart
    VALUES (1, 1);

INSERT INTO covidxpart
    VALUES (1, 1);

CREATE TABLE covidxpart3 (
    b int,
    c int,
    a int
);

ALTER TABLE covidxpart3
    DROP c;

ALTER TABLE covidxpart ATTACH PARTITION covidxpart3
FOR VALUES IN (3);

INSERT INTO covidxpart
    VALUES (3, 1);

INSERT INTO covidxpart
    VALUES (3, 1);

CREATE TABLE covidxpart4 (
    b int,
    a int
);

CREATE UNIQUE INDEX ON covidxpart4 (a) INCLUDE (b);

CREATE UNIQUE INDEX ON covidxpart4 (a);

ALTER TABLE covidxpart ATTACH PARTITION covidxpart4
FOR VALUES IN (4);

INSERT INTO covidxpart
    VALUES (4, 1);

INSERT INTO covidxpart
    VALUES (4, 1);

CREATE UNIQUE INDEX ON covidxpart (b) INCLUDE (a);

-- should fail
-- check that detaching a partition also detaches the primary key constraint
CREATE TABLE parted_pk_detach_test (
    a int PRIMARY KEY
)
PARTITION BY LIST (a);

CREATE TABLE parted_pk_detach_test1 PARTITION OF parted_pk_detach_test
FOR VALUES IN (1);

ALTER TABLE parted_pk_detach_test1
    DROP CONSTRAINT parted_pk_detach_test1_pkey;

-- should fail
ALTER TABLE parted_pk_detach_test DETACH PARTITION parted_pk_detach_test1;

ALTER TABLE parted_pk_detach_test1
    DROP CONSTRAINT parted_pk_detach_test1_pkey;

DROP TABLE parted_pk_detach_test, parted_pk_detach_test1;

CREATE TABLE parted_uniq_detach_test (
    a int UNIQUE
)
PARTITION BY LIST (a);

CREATE TABLE parted_uniq_detach_test1 PARTITION OF parted_uniq_detach_test
FOR VALUES IN (1);

ALTER TABLE parted_uniq_detach_test1
    DROP CONSTRAINT parted_uniq_detach_test1_a_key;

-- should fail
ALTER TABLE parted_uniq_detach_test DETACH PARTITION parted_uniq_detach_test1;

ALTER TABLE parted_uniq_detach_test1
    DROP CONSTRAINT parted_uniq_detach_test1_a_key;

DROP TABLE parted_uniq_detach_test, parted_uniq_detach_test1;

