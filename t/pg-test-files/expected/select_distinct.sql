--
-- SELECT_DISTINCT
--
--
-- awk '{print $3;}' onek.data | sort -n | uniq
--
SELECT DISTINCT
    two
FROM
    tmp
ORDER BY
    1;

--
-- awk '{print $5;}' onek.data | sort -n | uniq
--
SELECT DISTINCT
    ten
FROM
    tmp
ORDER BY
    1;

--
-- awk '{print $16;}' onek.data | sort -d | uniq
--
SELECT DISTINCT
    string4
FROM
    tmp
ORDER BY
    1;

--
-- awk '{print $3,$16,$5;}' onek.data | sort -d | uniq |
-- sort +0n -1 +1d -2 +2n -3
--
SELECT DISTINCT
    two,
    string4,
    ten
FROM
    tmp
ORDER BY
    two USING <,
    string4 USING <,
    ten USING <;

--
-- awk '{print $2;}' person.data |
-- awk '{if(NF!=1){print $2;}else{print;}}' - emp.data |
-- awk '{if(NF!=1){print $2;}else{print;}}' - student.data |
-- awk 'BEGIN{FS="      ";}{if(NF!=1){print $5;}else{print;}}' - stud_emp.data |
-- sort -n -r | uniq
--
SELECT DISTINCT
    p.age
FROM
    person * p
ORDER BY
    age USING >;

--
-- Check mentioning same column more than once
--
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    count(*)
FROM ( SELECT DISTINCT
        two,
        four,
        two
    FROM
        tenk1) ss;

SELECT
    count(*)
FROM ( SELECT DISTINCT
        two,
        four,
        two
    FROM
        tenk1) ss;

--
-- Also, some tests of IS DISTINCT FROM, which doesn't quite deserve its
-- very own regression file.
--
CREATE TEMP TABLE disttable (
    f1 integer
);

INSERT INTO DISTTABLE
    VALUES (1);

INSERT INTO DISTTABLE
    VALUES (2);

INSERT INTO DISTTABLE
    VALUES (3);

INSERT INTO DISTTABLE
    VALUES (NULL);

-- basic cases
SELECT
    f1,
    f1 IS DISTINCT FROM 2 AS "not 2"
FROM
    disttable;

SELECT
    f1,
    f1 IS DISTINCT FROM NULL AS "not null"
FROM
    disttable;

SELECT
    f1,
    f1 IS DISTINCT FROM f1 AS "false"
FROM
    disttable;

SELECT
    f1,
    f1 IS DISTINCT FROM f1 + 1 AS "not null"
FROM
    disttable;

-- check that optimizer constant-folds it properly
SELECT
    1 IS DISTINCT FROM 2 AS "yes";

SELECT
    2 IS DISTINCT FROM 2 AS "no";

SELECT
    2 IS DISTINCT FROM NULL AS "yes";

SELECT
    NULL IS DISTINCT FROM NULL AS "no";

-- negated form
SELECT
    1 IS NOT DISTINCT FROM 2 AS "no";

SELECT
    2 IS NOT DISTINCT FROM 2 AS "yes";

SELECT
    2 IS NOT DISTINCT FROM NULL AS "no";

SELECT
    NULL IS NOT DISTINCT FROM NULL AS "yes";

