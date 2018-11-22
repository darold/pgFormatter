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

select
    id,
    for_group,
    some_val,
    sum(some_val) over (partition by for_group order by id) as sum_so_far_in_group,
    sum(some_val) over (partition by for_group) as sum_in_group,
    sum(some_val) over (partition by for_group order by id range 3 preceding) as sum_current_and_3_preceeding,
    sum(some_val) over (partition by for_group order by id range between 3 preceding and 3 following) as sum_current_and_3_preceeding_and_3_following,
    sum(some_val) over (partition by for_group order by id range between current row and unbounded following) as sum_current_and_all_following
from test
order by for_group, id;

