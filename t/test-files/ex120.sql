select sum(c) from gstest2 group by grouping sets((), grouping sets((), grouping sets(((a, b)))));
select a from t group by rollup ((a, b)), cube ((c));
select ((a)) from t where ((b = 1));
