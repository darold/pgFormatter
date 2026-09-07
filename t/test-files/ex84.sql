select a.col, b.name, count(*) as total, myschema.mytable.id from myschema.mytable a join other_tbl b on a.id = b.ref_id where a.status = 1 and b."MixedCol" > 0;
select t."weird.name", schema."My.Tbl".plaincol, val::integer from public.users t;
create table app.orders (id integer, customer_id integer, order_date timestamp);

