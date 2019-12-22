CREATE PROCEDURE insert_data (a integer, b integer)
LANGUAGE SQL
AS $$
    INSERT INTO tbl
        VALUES (a);
    INSERT INTO tbl
        VALUES (b);
$$;

CALL insert_data (1, 2);

ALTER PROCEDURE insert_data1 (integer, integer) RENAME TO insert_record;

ALTER PROCEDURE insert_data2 (integer, integer) OWNER TO joe;

ALTER PROCEDURE insert_data3 (integer, integer) SET SCHEMA accounting;

ALTER PROCEDURE insert_data4 (integer, integer) DEPENDS ON EXTENSION myext;

ALTER PROCEDURE check_password1 (text) SET search_path = admin, pg_temp;

ALTER PROCEDURE check_password2 (text) RESET search_path;

ALTER ROUTINE foo1 (integer) RENAME TO foobar;

ALTER ROUTINE foo2 (integer, varchar(255)) OWNER TO ufoo;

ALTER ROUTINE foo3 (integer, varchar(255), boolean) SET SCHEMA sfoo;

ALTER ROUTINE foo4 (varchar(25), integer) DEPENDS ON EXTENSION fooext;

ALTER ROUTINE foo5 (integer) IMMUTABLE;

ALTER ROUTINE foo6 (integer) SECURITY INVOKER;

ALTER ROUTINE foo7 (integer) RESET ALL;

ALTER ROUTINE foo8 (integer) SET work_mem = '1GB';

ALTER ROUTINE foo9 (integer) SET work_mem FROM CURRENT;

CREATE PUBLICATION mypublication1 FOR TABLE ONLY emps;

CREATE PUBLICATION mypublication2 FOR TABLE users, departments;

CREATE PUBLICATION alltables FOR ALL TABLES;

CREATE PUBLICATION insert_only FOR TABLE mydata WITH (publish = 'insert');

SELECT
    my_func (p_type_cd => t.type_cd) AS my_func_result
FROM
    tab t
WHERE
    t.id = 12;

