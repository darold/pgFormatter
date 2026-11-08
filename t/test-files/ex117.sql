SELECT v, b, (v || b) AS concat FROM t;
SELECT testtext || testvarchar AS concat, concat, t.concat FROM t;
SELECT a concat b FROM t;
create function r(t) returns t as $$select $1$$ language sql immutable;
select $$a$$, $1;
