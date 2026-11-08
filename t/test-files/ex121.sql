SELECT 1\; SELECT 2\; SELECT 3;
insert into i_table values(2)\; select * from i_table\; select 1/0;
begin\; insert into i_table values(3)\; commit;
