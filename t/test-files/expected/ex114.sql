COPY t (a, b) FROM stdin;
1	it's -- x
2	\N
\.

SELECT
    1;

COPY u FROM stdin WITH (FORMAT csv);
1,"a;b"
\.
COPY v FROM STDIN;
X0F	X10
\.
SELECT
    2;

\copy w from stdin
1	x
\.
SELECT
    3;

copy (select * from test1) from stdin;
\.
copy t from stdout;
1	baz
\.
SELECT
    4;

