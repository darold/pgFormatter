-- Issue #308: option --split-in-param, one value per line in the list of an IN clause
SELECT username, first_name, last_name, start_of_employment, end_of_employment FROM employees WHERE username IN ('tcbgpF46JJ', '5m6PFQ60Gd', 'z7vz3WJH6E', 'S5JPy48rLI', 'bKj3C-z1UI') ORDER BY start_of_employment;
SELECT * FROM t WHERE a NOT IN (1, 2, 3) AND b IN (SELECT x FROM u) AND e IN (f(1, 2), g(3)) AND h IN (1);
SELECT * FROM t WHERE (c, d) IN ((1, 2), (3, 4), (5, 6));
SELECT * FROM t JOIN u ON u.id = t.id AND u.k IN ('a', 'b') WHERE b = ANY (ARRAY[1, 2, 3]) AND position('a' IN 'abc') > 0;
CREATE TABLE p1 PARTITION OF p FOR VALUES IN (1, 2, 3);
CREATE FUNCTION f() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  FOR i IN 1..3 LOOP
    IF i IN (1, 3) THEN RAISE NOTICE 'x'; END IF;
  END LOOP;
END $$;
