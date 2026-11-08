COPY t (a, b) FROM stdin;
1	it's -- x
2	\N
\.
select 1;
COPY u FROM stdin WITH (FORMAT csv);
1,"a;b"
\.
COPY v FROM STDIN;
X0F	X10
\.
select 2;
\copy w from stdin
1	x
\.
select 3;
copy (select * from test1) from stdin;
\.
copy t from stdout;
1	baz
\.
select 4;
