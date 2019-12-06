SELECT CASE WHEN 1 = 1 THEN 2 ELSE 3 end::text AS col1, col2, col3 FROM tb1;

SELECT ( CASE WHEN 1 = 1 THEN 2 ELSE 3 END)::text AS col1, col2, col3 FROM tb1;

UPDATE point_tbl SET f1[0] = NULL WHERE f1::text = '(10,10)'::point::text RETURNING *;

SELECT 'TrUe'::text::boolean AS true, 'fAlse'::text::boolean AS false;

SELECT true::boolean::text AS true, false::boolean::text AS false;

CREATE PROCEDURE testns.bar() AS 'select 1' LANGUAGE sql;

ALTER TABLE test9b
    ALTER COLUMN b TYPE priv_testdomain1;

CREATE TYPE test7b AS (
    a int,
    b priv_testdomain1
);
        CREATE TYPE test8b AS (
            a int,
            b int
);
        ALTER TYPE test8b
            ADD ATTRIBUTE c priv_testdomain1;


