CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)
)
PARTITION BY RANGE (id);

CREATE TABLE kbln_p0 of kbln
FOR VALUES FROM (MINVALUE) TO (500000)
PARTITION BY HASH (blank_series);

CREATE TABLE kbln_p0_1 of kbln_p0
FOR VALUES WITH (MODULUS 2, remainder 0);

CREATE TABLE kbln_p0_2 of kbln_p0
FOR VALUES WITH (MODULUS 2, remainder 1);

ALTER TABLE t1 DETACH t1_a;

ALTER TABLE t1 ATTACH t1_a
FOR VALUES IN (1, 2, 3);

CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)
)
PARTITION BY LIST (id);

