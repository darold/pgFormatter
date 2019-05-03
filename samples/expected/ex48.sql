INSERT INTO test_exists
    VALUES (NEW.a, NEW.b || NEW.a::text);
CREATE RULE test_rule_exists AS ON INSERT TO test_exists
    DO INSTEAD
    INSERT INTO test_exists VALUES (NEW.a, NEW.b || NEW.a::text);

DROP RULE test_rule_exists ON test_exists;

