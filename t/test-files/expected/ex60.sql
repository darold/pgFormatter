CREATE TABLE public.test (
    value DOUBLE PRECISION,
    ts1 TIMESTAMP(4) WITH TIME ZONE,
    ts2 TIMESTAMP WITH TIME ZONE,
    ts1 TIMESTAMP(4) WITHOUT TIME ZONE,
    ts2 TIMESTAMP WITHOUT TIME ZONE,
    t1 TIME(4) WITH TIME ZONE,
    t2 TIME WITH TIME ZONE,
    t1 TIME(4) WITHOUT TIME ZONE,
    t2 TIME WITHOUT TIME ZONE,
    d1 INTERVAL second (6),
    d2 INTERVAL second,
    d3 INTERVAL(6)
);

CREATE TABLE brintest (
    byteacol BYTEA,
    charcol "char",
    namecol NAME,
    int8col BIGINT,
    int2col SMALLINT,
    int4col INTEGER,
    textcol TEXT,
    oidcol OID,
    tidcol TID,
    float4col REAL,
    float8col DOUBLE PRECISION,
    macaddrcol MACADDR,
    inetcol INET,
    cidrcol CIDR,
    bpcharcol CHARACTER,
    datecol DATE,
    timecol TIME WITHOUT TIME ZONE,
    timestampcol TIMESTAMP WITHOUT TIME ZONE,
    timestamptzcol TIMESTAMP WITH TIME ZONE,
    intervalcol INTERVAL,
    timetzcol TIME WITH TIME ZONE,
    bitcol BIT(10),
    varbitcol BIT VARYING(16),
    numericcol NUMERIC,
    uuidcol UUID,
    int4rangecol INT4RANGE,
    lsncol PG_LSN,
    boxcol BOX
)
WITH (
    fillfactor = 10
);

CREATE TABLE reservation (
    room INT,
    during TSRANGE
);

INSERT INTO reservation
    VALUES (1108, '[2010-01-01 14:30, 2010-01-01 15:30)');

-- Containment
SELECT
    INT4RANGE(10, 20) @> 3;

-- Overlaps
SELECT
    NUMRANGE(11.1, 22.2) && NUMRANGE(20.0, 30.0);

-- Extract the upper bound
SELECT
    UPPER(INT8RANGE(15, 25));

-- Compute the intersection
SELECT
    INT4RANGE(10, 20) * INT4RANGE(15, 25);

-- Is the range empty?
SELECT
    ISEMPTY(NUMRANGE(1, 5));

SELECT
    '(3,7)'::INT4RANGE;

CREATE TABLE position (
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    name TEXT
);

-- pg_trgm operators
SELECT
    t,
    similarity (t, 'word') AS sml
FROM
    test_trgm
WHERE
    t % 'word'
ORDER BY
    sml DESC,
    t;

SELECT
    t,
    t <-> 'word' AS dist
FROM
    test_trgm
ORDER BY
    dist
LIMIT 10;

SELECT
    t,
    word_similarity ('word', t) AS sml
FROM
    test_trgm
WHERE
    'word' <% t
    AND 'hello' %> t
ORDER BY
    sml DESC,
    t;

SELECT
    t,
    'word' <<-> t AS dist
FROM
    test_trgm
ORDER BY
    dist
LIMIT 10;

SELECT
    t,
    'word' <->> t AS dist
FROM
    test_trgm
ORDER BY
    dist
LIMIT 10;

