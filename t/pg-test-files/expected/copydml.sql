--
-- Test cases for COPY (INSERT/UPDATE/DELETE) TO
--
CREATE TABLE copydml_test (
    id serial,
    t text
);

INSERT INTO copydml_test (t)
    VALUES ('a');

INSERT INTO copydml_test (t)
    VALUES ('b');

INSERT INTO copydml_test (t)
    VALUES ('c');

INSERT INTO copydml_test (t)
    VALUES ('d');

INSERT INTO copydml_test (t)
    VALUES ('e');

--
-- Test COPY (insert/update/delete ...)
--
COPY (INSERT INTO copydml_test (t)
        VALUES ('f')
    RETURNING
        id)
    TO stdout;

COPY ( UPDATE
        copydml_test
    SET
        t = 'g'
    WHERE
        t = 'f'
    RETURNING
        id)
    TO stdout;

COPY ( DELETE FROM copydml_test
    WHERE t = 'g'
    RETURNING
        id)
    TO stdout;

--
-- Test \copy (insert/update/delete ...)
--
\copy (insert into copydml_test (t) values ('f') returning id) to stdout;
\copy (update copydml_test set t = 'g' where t = 'f' returning id) to stdout;
\copy (delete from copydml_test where t = 'g' returning id) to stdout;
-- Error cases
COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

COPY ( UPDATE
        copydml_test
    SET
        t = 'g')
    TO stdout;

COPY ( DELETE FROM copydml_test)
    TO stdout;

CREATE RULE qqq AS ON INSERT TO copydml_test
    DO INSTEAD
    NOTHING;

COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON INSERT TO copydml_test
    DO ALSO
    DELETE FROM copydml_test;

COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON INSERT TO copydml_test
    DO INSTEAD
    ( DELETE FROM copydml_test;

DELETE FROM copydml_test);

COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON INSERT TO copydml_test WHERE
    NEW.t <> 'f'
        DO INSTEAD
        DELETE FROM copydml_test;

COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON UPDATE
    TO copydml_test
        DO INSTEAD
        NOTHING;

COPY ( UPDATE
        copydml_test
    SET
        t = 'f')
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON UPDATE
    TO copydml_test
        DO ALSO
        DELETE FROM copydml_test;

COPY ( UPDATE
        copydml_test
    SET
        t = 'f')
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON UPDATE
    TO copydml_test
        DO INSTEAD
        ( DELETE FROM copydml_test;

DELETE FROM copydml_test);

COPY ( UPDATE
        copydml_test
    SET
        t = 'f')
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON UPDATE
    TO copydml_test WHERE
    NEW.t <> 'f'
        DO INSTEAD
        DELETE FROM copydml_test;

COPY ( UPDATE
        copydml_test
    SET
        t = 'f')
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON DELETE TO copydml_test
    DO INSTEAD
    NOTHING;

COPY ( DELETE FROM copydml_test)
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON DELETE TO copydml_test
    DO ALSO
    INSERT INTO copydml_test DEFAULT VALUES; COPY ( DELETE FROM copydml_test)
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON DELETE TO copydml_test
    DO INSTEAD
    (INSERT INTO copydml_test DEFAULT VALUES; INSERT INTO copydml_test DEFAULT
    values
);

COPY ( DELETE FROM copydml_test)
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON DELETE TO copydml_test
WHERE OLD.t <> 'f'
        DO INSTEAD
        INSERT INTO copydml_test DEFAULT VALUES; COPY ( DELETE FROM copydml_test)
    TO stdout;

DROP RULE qqq ON copydml_test;

CREATE RULE qqq AS ON INSERT TO copydml_test
    DO INSTEAD
    NOTIFY copydml_test;

COPY (INSERT INTO copydml_test DEFAULT
        values
)
        TO stdout;

DROP RULE qqq ON copydml_test;

-- triggers
CREATE FUNCTION qqq_trig ()
    RETURNS trigger
    AS $$
BEGIN
    IF tg_op IN ('INSERT', 'UPDATE') THEN
        RAISE NOTICE '% % %', tg_when, tg_op, NEW.id;
        RETURN new;
    ELSE
        RAISE NOTICE '% % %', tg_when, tg_op, OLD.id;
        RETURN old;
    END IF;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER qqqbef
    BEFORE INSERT OR UPDATE OR DELETE ON copydml_test
    FOR EACH ROW
    EXECUTE PROCEDURE qqq_trig ();

CREATE TRIGGER qqqaf
    AFTER INSERT OR UPDATE OR DELETE ON copydml_test
    FOR EACH ROW
    EXECUTE PROCEDURE qqq_trig ();

COPY (INSERT INTO copydml_test (t)
        VALUES ('f')
    RETURNING
        id)
    TO stdout;

COPY ( UPDATE
        copydml_test
    SET
        t = 'g'
    WHERE
        t = 'f'
    RETURNING
        id)
    TO stdout;

COPY ( DELETE FROM copydml_test
    WHERE t = 'g'
    RETURNING
        id)
    TO stdout;

DROP TABLE copydml_test;

DROP FUNCTION qqq_trig ();

