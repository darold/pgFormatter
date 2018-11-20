CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)) partition by
    range ( id);

create table kbln_p0 partition of kbln for
values from ( minvalue) to ( 500000) partition by hash ( blank_series);

create table kbln_p0_1 partition of kbln_p0 for
values with ( modulus 2, remainder 0);

create table kbln_p0_2 partition of kbln_p0 for
values with ( modulus 2, remainder 1);

alter table t1 detach partition t1_a;
alter table t1 attach partition t1_a for values in (1, 2, 3);

CREATE TABLE kbln (
    id integer NOT NULL,
    blank_series varchar(50) NOT NULL,
    company_id varchar(8)) partition by
    list ( id);

