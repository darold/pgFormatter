CREATE TABLE public.test (
	value double precision
	, ts1 timestamp(4) with time zone
	, ts2 timestamp with time zone
	, ts1 timestamp(4) without time zone
	, ts2 timestamp without time zone
	, t1 time(4) with time zone
	, t2 time with time zone
	, t1 time(4) without time zone
	, t2 time without time zone
	, d1 interval second (6)
	, d2 interval second
	, d3 interval(6)
);

CREATE TABLE brintest (
	byteacol bytea
	, charcol "char"
	, namecol name
	, int8col bigint
	, int2col smallint
	, int4col integer
	, textcol text
	, oidcol oid
	, tidcol tid
	, float4col real
	, float8col double precision
	, macaddrcol macaddr
	, inetcol inet
	, cidrcol cidr
	, bpcharcol character
	, datecol date
	, timecol time without time zone
	, timestampcol timestamp without time zone
	, timestamptzcol timestamp with time zone
	, intervalcol interval
	, timetzcol time with time zone
	, bitcol bit(10)
	, varbitcol bit varying(16)
	, numericcol numeric
	, uuidcol uuid
	, int4rangecol int4range
	, lsncol pg_lsn
	, boxcol box
)
WITH (
	fillfactor = 10
);

CREATE TABLE reservation (
	room int
	, during tsrange
);

INSERT INTO reservation
	VALUES (1108 , '[2010-01-01
	14:30, 2010-01-01 15:30)');

--  Containment
SELECT int4range(10 , 20) @> 3;

--  Overlaps
SELECT numrange(11.1 , 22.2) &&
 numrange(20.0 , 30.0);

--  Extract the upper bound
SELECT upper(int8range(15 , 25));

--  Compute the intersection
SELECT int4range(10 , 20) *
 int4range(15 , 25);

--  Is the range empty?
SELECT isempty(numrange(1 , 5));

SELECT '(3,7)'::int4range;

-- Example 1: comment in CTE AFTER comma
-- works as expected when formatting
WITH table_A AS (
	SELECT a
		, b + 3 AS c
	FROM table_1
) ,
--  comment 1
table_B AS (
	SELECT a
		, c
	FROM table_2
)
SELECT *
FROM table_B;

-- Example 2: comment in CTE BEFORE comma
-- breaks indentation when formatting
WITH table_A AS (
	SELECT a
		, b + 3 AS c
	FROM table_1
)
--  comment 1
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
	SELECT 1 AS val
	FROM dual
) ,
--
-- Unexpected indentation starts with next CTE segment
--
test2 AS (
	SELECT 2 AS val
	FROM dual
)
--  Test comment 2
, test3 AS (
	SELECT 4 AS val
	FROM dual)
	--  Test comment
SELECT *
	FROM test;
