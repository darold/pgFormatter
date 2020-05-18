CREATE TABLE public.test (
    value double precision,
    ts1 timestamp (4) with time zone,
    ts2 timestamp with time zone,
    ts1 timestamp (4) without time zone,
    ts2 timestamp without time zone,
    t1 time (4) with time zone,
    t2 time with time zone,
    t1 time (4) without time zone,
    t2 time without time zone,
    d1 interval second (6),
    d2 interval second,
    d3 interval (6)
);

CREATE TABLE brintest (byteacol bytea,
        charcol "char",
        namecol name,
        int8col bigint,
        int2col smallint,
        int4col integer,
        textcol text,
        oidcol oid,
        tidcol tid,
        float4col real,
        float8col double precision,
        macaddrcol macaddr,
        inetcol inet,
        cidrcol cidr,
        bpcharcol character,
        datecol date,
        timecol time without time zone,
        timestampcol timestamp without time zone,
        timestamptzcol timestamp with time zone,
        intervalcol interval,
        timetzcol time with time zone,
        bitcol bit(10),
        varbitcol bit varying(16),
        numericcol numeric,
        uuidcol uuid,
        int4rangecol int4range,
        lsncol pg_lsn,
        boxcol box
) WITH (fillfactor=10);

CREATE TABLE reservation (room int, during tsrange);
INSERT INTO reservation VALUES
    (1108, '[2010-01-01 14:30, 2010-01-01 15:30)');

-- Containment
SELECT int4range(10, 20) @> 3;

-- Overlaps
SELECT numrange(11.1, 22.2) && numrange(20.0, 30.0);

-- Extract the upper bound
SELECT upper(int8range(15, 25));

-- Compute the intersection
SELECT int4range(10, 20) * int4range(15, 25);

-- Is the range empty?
SELECT isempty(numrange(1, 5));

SELECT '(3,7)'::int4range;

-- Example 1: comment in CTE AFTER comma works as expected when formatting
WITH table_A AS (
	SELECT a
		, b + 3 AS c
	FROM table_1
) ,
-- comment 1
table_B AS (
	SELECT a
		, c
	FROM table_2
)
SELECT *
FROM table_B;

-- Example 2: comment in CTE BEFORE comma breaks indentation when formatting
WITH table_A AS (
	SELECT a
		, b + 3 AS c
	FROM table_1)
	-- comment 1
	, table_B AS (
		SELECT a
			, c
		FROM table_2
)
	SELECT *
	FROM table_B;

--
-- Example 1: two blank lines are added after this comment
--
WITH test AS (
	SELECT 1 AS val FROM dual
),
--
-- Unexpected indentation starts with next CTE segment
--
test2 AS (
	SELECT 2 AS val
	FROM dual
)
-- Test comment 2
, test3 AS (
	SELECT 4 AS val
	FROM dual
)
-- Test comment
SELECT *
FROM test;


-- Example 1: BEFORE formatting
-- test comment
WITH
--
-- CTE1 comment
--
test1 AS (
	SELECT
		/* comment X */
		trunc(sysdate) - 1 AS col_a --  test
		, test_c.*
		-- Test aa b pppppppppp zzzzzzzzz xxxxxxx zzzzzzzzzzzz - TODO aa bbbbbbb cccccccccc ddddddddddd
		-- , mid comment 2 - TODO - 2
		-- , mid comment 3
		, 2 AS col_b
		-- comment a1
		-- comment a2
		, trunc(sysdate) AS col_c
		-- Spaces after at line start are added into comments
		, coalesce(1 , 0) AS col_d
		, coalesce(2 , 0) AS col_e
		--
		-- Column group comment:
		-- col_f - x1
		-- col_g - x2
		--
		, 1 AS col_f
		, 3 AS col_g
		--   , 1 AS PARD
		, 4 AS col_h
		, 5 AS col_i
		, 6 AS col_j
		--
		--, 4 as col_h
		--, 5 as col_i
		--, 6 as col_j
	FROM
	--  join comment
	(
		SELECT *
		FROM (
			SELECT /* subquery comment a */ max(1) test_a
			FROM dual
			) test_1a
			CROSS JOIN 
			(
			SELECT /* subquery comment b */ max(2) AS test_b
			FROM dual) test_1b
	) test_c
)
--  CTE2 comment
--
, test2 AS (
	SELECT 1 AS test2_col_a
	FROM dual
)
SELECT *
FROM test2;

-- Example 1: BEFORE formatting
SELECT '
--- 	VAL_1	VAL_2
long text multi line
end of text
--- 
' as text_col_value
from dual;

