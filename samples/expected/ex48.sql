INSERT INTO test_exists
    VALUES (NEW.a, NEW.b || NEW.a::text);
CREATE RULE test_rule_exists AS ON INSERT TO test_exists
    DO INSTEAD
    INSERT INTO test_exists VALUES (NEW.a, NEW.b || NEW.a::text);

DROP RULE test_rule_exists ON test_exists;

CREATE FUNCTION sql_is_distinct_from (anyelement, anyelement)
    RETURNS boolean
    LANGUAGE sql
    AS 'INSERT INTO dom_table VALUES (1, 2, 3)'
;
INSERT INTO dom_table
    VALUES ('1');
INSERT INTO dom_table
    VALUES ('1');
