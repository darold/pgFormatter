--
-- SELECT
--
-- btree index
-- awk '{if($1<10){print;}else{next;}}' onek.data | sort +0n -1
--
SELECT
    *
FROM
    onek
WHERE
    onek.unique1 < 10
ORDER BY
    onek.unique1;

--
-- awk '{if($1<20){print $1,$14;}else{next;}}' onek.data | sort +0nr -1
--
SELECT
    onek.unique1,
    onek.stringu1
FROM
    onek
WHERE
    onek.unique1 < 20
ORDER BY
    unique1 USING >;

--
-- awk '{if($1>980){print $1,$14;}else{next;}}' onek.data | sort +1d -2
--
SELECT
    onek.unique1,
    onek.stringu1
FROM
    onek
WHERE
    onek.unique1 > 980
ORDER BY
    stringu1 USING <;

--
-- awk '{if($1>980){print $1,$16;}else{next;}}' onek.data |
-- sort +1d -2 +0nr -1
--
SELECT
    onek.unique1,
    onek.string4
FROM
    onek
WHERE
    onek.unique1 > 980
ORDER BY
    string4 USING <,
    unique1 USING >;

--
-- awk '{if($1>980){print $1,$16;}else{next;}}' onek.data |
-- sort +1dr -2 +0n -1
--
SELECT
    onek.unique1,
    onek.string4
FROM
    onek
WHERE
    onek.unique1 > 980
ORDER BY
    string4 USING >,
    unique1 USING <;

--
-- awk '{if($1<20){print $1,$16;}else{next;}}' onek.data |
-- sort +0nr -1 +1d -2
--
SELECT
    onek.unique1,
    onek.string4
FROM
    onek
WHERE
    onek.unique1 < 20
ORDER BY
    unique1 USING >,
    string4 USING <;

--
-- awk '{if($1<20){print $1,$16;}else{next;}}' onek.data |
-- sort +0n -1 +1dr -2
--
SELECT
    onek.unique1,
    onek.string4
FROM
    onek
WHERE
    onek.unique1 < 20
ORDER BY
    unique1 USING <,
    string4 USING >;

--
-- test partial btree indexes
--
-- As of 7.2, planner probably won't pick an indexscan without stats,
-- so ANALYZE first.  Also, we want to prevent it from picking a bitmapscan
-- followed by sort, because that could hide index ordering problems.
--
ANALYZE onek2;

SET enable_seqscan TO OFF;

SET enable_bitmapscan TO OFF;

SET enable_sort TO OFF;

--
-- awk '{if($1<10){print $0;}else{next;}}' onek.data | sort +0n -1
--
SELECT
    onek2.*
FROM
    onek2
WHERE
    onek2.unique1 < 10;

--
-- awk '{if($1<20){print $1,$14;}else{next;}}' onek.data | sort +0nr -1
--
SELECT
    onek2.unique1,
    onek2.stringu1
FROM
    onek2
WHERE
    onek2.unique1 < 20
ORDER BY
    unique1 USING >;

--
-- awk '{if($1>980){print $1,$14;}else{next;}}' onek.data | sort +1d -2
--
SELECT
    onek2.unique1,
    onek2.stringu1
FROM
    onek2
WHERE
    onek2.unique1 > 980;

RESET enable_seqscan;

RESET enable_bitmapscan;

RESET enable_sort;

SELECT
    two,
    stringu1,
    ten,
    string4 INTO TABLE tmp
FROM
    onek;

--
-- awk '{print $1,$2;}' person.data |
-- awk '{if(NF!=2){print $3,$2;}else{print;}}' - emp.data |
-- awk '{if(NF!=2){print $3,$2;}else{print;}}' - student.data |
-- awk 'BEGIN{FS="      ";}{if(NF!=2){print $4,$5;}else{print;}}' - stud_emp.data
--
-- SELECT name, age FROM person*; ??? check if different
SELECT
    p.name,
    p.age
FROM
    person * p;

--
-- awk '{print $1,$2;}' person.data |
-- awk '{if(NF!=2){print $3,$2;}else{print;}}' - emp.data |
-- awk '{if(NF!=2){print $3,$2;}else{print;}}' - student.data |
-- awk 'BEGIN{FS="      ";}{if(NF!=1){print $4,$5;}else{print;}}' - stud_emp.data |
-- sort +1nr -2
--
SELECT
    p.name,
    p.age
FROM
    person * p
ORDER BY
    age USING >,
    name;

--
-- Test some cases involving whole-row Var referencing a subquery
--
SELECT
    foo
FROM (
    SELECT
        1 OFFSET 0) AS foo;

SELECT
    foo
FROM (
    SELECT
        NULL OFFSET 0) AS foo;

SELECT
    foo
FROM (
    SELECT
        'xyzzy',
        1,
        NULL OFFSET 0) AS foo;

--
-- Test VALUES lists
--
SELECT
    *
FROM
    onek,
    (
        VALUES (147, 'RFAAAA'),
            (931, 'VJAAAA')) AS v (i, j)
WHERE
    onek.unique1 = v.i
    AND onek.stringu1 = v.j;

-- a more complex case
-- looks like we're coding lisp :-)
SELECT
    *
FROM
    onek,
    (
        VALUES ((
                    SELECT
                        i
                    FROM (
                        VALUES (10000), (2), (389), (1000), (2000), (
                                SELECT
                                    10029)) AS foo (i)
                    ORDER BY
                        i ASC
                    LIMIT 1))) bar (i)
WHERE
    onek.unique1 = bar.i;

-- try VALUES in a subquery
SELECT
    *
FROM
    onek
WHERE (unique1, ten) IN (
    VALUES (1, 1),
        (20, 0),
        (99, 9),
        (17, 99))
ORDER BY
    unique1;

-- VALUES is also legal as a standalone query or a set-operation member
VALUES (1,
    2),
(3,
    4 + 4),
(7,
    77.7);

VALUES (1,
    2),
(3,
    4 + 4),
(7,
    77.7)
UNION ALL
SELECT
    2 + 2,
    57
UNION ALL TABLE int8_tbl;

--
-- Test ORDER BY options
--
CREATE TEMP TABLE foo (
    f1 int
);

INSERT INTO foo
VALUES
    (42),
    (3),
    (10),
    (7),
    (NULL),
    (NULL),
    (1);

SELECT
    *
FROM
    foo
ORDER BY
    f1;

SELECT
    *
FROM
    foo
ORDER BY
    f1 ASC;

-- same thing
SELECT
    *
FROM
    foo
ORDER BY
    f1 NULLS FIRST;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC NULLS LAST;

-- check if indexscans do the right things
CREATE INDEX fooi ON foo (f1);

SET enable_sort = FALSE;

SELECT
    *
FROM
    foo
ORDER BY
    f1;

SELECT
    *
FROM
    foo
ORDER BY
    f1 NULLS FIRST;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC NULLS LAST;

DROP INDEX fooi;

CREATE INDEX fooi ON foo (f1 DESC);

SELECT
    *
FROM
    foo
ORDER BY
    f1;

SELECT
    *
FROM
    foo
ORDER BY
    f1 NULLS FIRST;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC NULLS LAST;

DROP INDEX fooi;

CREATE INDEX fooi ON foo (f1 DESC NULLS LAST);

SELECT
    *
FROM
    foo
ORDER BY
    f1;

SELECT
    *
FROM
    foo
ORDER BY
    f1 NULLS FIRST;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC;

SELECT
    *
FROM
    foo
ORDER BY
    f1 DESC NULLS LAST;

--
-- Test planning of some cases with partial indexes
--
-- partial index is usable
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 = 'ATAAAA';

SELECT
    *
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 = 'ATAAAA';

-- actually run the query with an analyze to use the partial index
EXPLAIN (
    COSTS OFF,
    ANALYZE ON,
    timing OFF,
    summary OFF
)
SELECT
    *
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 = 'ATAAAA';

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 = 'ATAAAA';

SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 = 'ATAAAA';

-- partial index predicate implies clause, so no need for retest
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

SELECT
    *
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

-- but if it's an update target, must retest anyway
EXPLAIN (
    COSTS OFF
)
SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B'
FOR UPDATE;

SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B'
FOR UPDATE;

-- partial index is not applicable
EXPLAIN (
    COSTS OFF
)
SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'C';

SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'C';

-- partial index implies clause, but bitmap scan must recheck predicate anyway
SET enable_indexscan TO OFF;

EXPLAIN (
    COSTS OFF
)
SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

SELECT
    unique2
FROM
    onek2
WHERE
    unique2 = 11
    AND stringu1 < 'B';

RESET enable_indexscan;

-- check multi-index cases too
EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    unique2
FROM
    onek2
WHERE (unique2 = 11
    OR unique1 = 0)
AND stringu1 < 'B';

SELECT
    unique1,
    unique2
FROM
    onek2
WHERE (unique2 = 11
    OR unique1 = 0)
AND stringu1 < 'B';

EXPLAIN (
    COSTS OFF
)
SELECT
    unique1,
    unique2
FROM
    onek2
WHERE (unique2 = 11
    AND stringu1 < 'B')
    OR unique1 = 0;

SELECT
    unique1,
    unique2
FROM
    onek2
WHERE (unique2 = 11
    AND stringu1 < 'B')
    OR unique1 = 0;

--
-- Test some corner cases that have been known to confuse the planner
--
-- ORDER BY on a constant doesn't really need any sorting
SELECT
    1 AS x
ORDER BY
    x;

-- But ORDER BY on a set-valued expression does
CREATE FUNCTION sillysrf (int)
    RETURNS SETOF int
    AS '
    VALUES (1),
    (10),
    (2),
    ($1);
'
LANGUAGE sql
IMMUTABLE;

SELECT
    sillysrf (42);

SELECT
    sillysrf (-1)
ORDER BY
    1;

DROP FUNCTION sillysrf (int);

-- X = X isn't a no-op, it's effectively X IS NOT NULL assuming = is strict
-- (see bug #5084)
SELECT
    *
FROM (
    VALUES (2),
        (NULL),
        (1)) v (k)
WHERE
    k = k
ORDER BY
    k;

SELECT
    *
FROM (
    VALUES (2),
        (NULL),
        (1)) v (k)
WHERE
    k = k;

-- Test partitioned tables with no partitions, which should be handled the
-- same as the non-inheritance case when expanding its RTE.
CREATE TABLE list_parted_tbl (
    a int,
    b int
)
PARTITION BY LIST (a);

CREATE TABLE list_parted_tbl1 PARTITION OF list_parted_tbl
FOR VALUES IN (1)
PARTITION BY LIST (b);

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    list_parted_tbl;

DROP TABLE list_parted_tbl;

