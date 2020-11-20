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

create table position (
	latitude double precision,
	longitude double precision,
	name text
);

-- pg_trgm operators
SELECT t, similarity(t, 'word') AS sml
  FROM test_trgm
  WHERE t % 'word'
  ORDER BY sml DESC, t;

SELECT t, t <-> 'word' AS dist
  FROM test_trgm
  ORDER BY dist LIMIT 10;

SELECT t, word_similarity('word', t) AS sml
  FROM test_trgm
  WHERE 'word' <% t AND 'hello' %> t
  ORDER BY sml DESC, t;

SELECT t, 'word' <<-> t AS dist
  FROM test_trgm
  ORDER BY dist LIMIT 10;

SELECT t, 'word' <->> t AS dist
  FROM test_trgm
  ORDER BY dist LIMIT 10;

