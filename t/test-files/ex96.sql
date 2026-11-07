-- Issue #177: closing parenthesis of a subquery on its own line (--matching-paren-newline)
-- and indentation of the condition following a subquery inside a subquery
select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substring(c_phone from 1 for 2) as cntrycode, c_acctbal from customer where substring(c_phone from 1 for 2) in ('13', '31', '23', '29', '30', '18', '17') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substring(c_phone from 1 for 2) in ('13', '31', '23', '29', '30', '18', '17')) and not exists ( select * from orders where o_custkey = c_custkey)) as custsale group by cntrycode order by cntrycode;
select s.a from (select a from t where a = 1 and b > (select x from u where y = 1) and c <> all (select z from v) and d in (select w from x) group by a) s where s.a = 1;
select * from (select 1 union all (select 2)) s1 cross join lateral ((select 3) union all (select 4)) s2;
