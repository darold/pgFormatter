CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)
)
PARTITION BY RANGE (id);

CREATE TABLE kbln_p0 PARTITION OF kbln
FOR VALUES FROM (MINVALUE) TO (500000)
PARTITION BY HASH (blank_series);

CREATE TABLE kbln_p0_1 PARTITION OF kbln_p0
FOR VALUES WITH (MODULUS 2, REMAINDER 0);

CREATE TABLE kbln_p0_2 PARTITION OF kbln_p0
FOR VALUES WITH (MODULUS 2, REMAINDER 1);

ALTER TABLE t1 DETACH PARTITION t1_a;

ALTER TABLE t1 ATTACH PARTITION t1_a
FOR VALUES IN (1, 2, 3);

CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)
)
PARTITION BY LIST (id);

SELECT
    id,
    for_group,
    some_val,
    sum(some_val) OVER (PARTITION BY for_group ORDER BY id) AS sum_so_far_in_group,
    sum(some_val) OVER (PARTITION BY for_group) AS sum_in_group,
    sum(some_val) OVER (PARTITION BY for_group ORDER BY id RANGE 3 PRECEDING) AS sum_current_and_3_preceeding,
    sum(some_val) OVER (PARTITION BY for_group ORDER BY id RANGE BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS sum_current_and_3_preceeding_and_3_following,
    sum(some_val) OVER (PARTITION BY for_group ORDER BY id RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS sum_current_and_all_following
FROM
    test
ORDER BY
    for_group,
    id;

