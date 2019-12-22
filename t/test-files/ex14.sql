SELECT regexp_matches('foobarbequebazilbarfbonk', '(b[^b]+)(b[^b]+)', 'g');
SELECT SUBSTRING('XY1234Z', 'Y*([0-9]{1,3})');
SELECT m.name AS mname, pname
FROM manufacturers m, LATERAL get_product_names(m.id) pname;
SELECT m.name AS mname, pname
FROM manufacturers m LEFT JOIN LATERAL get_product_names(m.id) pname ON true;
with one as (select 1 one) select count(one),avg(one) from one;
SELECT * FROM a FULL JOIN b USING (c);
SELECT * FROM a FULL OUTER JOIN b USING (c);
CREATE TYPE jwt_token AS (token TEXT, field: TEXT);
