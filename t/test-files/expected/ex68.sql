CREATE FUNCTION rw_view1_trig_fn ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF tg_op = 'insert' THEN
        INSERT INTO base_tbl
            VALUES (NEW.a, NEW.b);
        RETURN new;
    ELSIF tg_op = 'update' THEN
        UPDATE
            base_tbl
        SET
            b = NEW.b
        WHERE
            a = OLD.a;
        RETURN new;
    ELSIF tg_op = 'delete' THEN
        DELETE FROM base_tbl
        WHERE a = OLD.a;
        RETURN old;
    END IF;
END;
$$
LANGUAGE plpgsql;

INSERT INTO users ("username", "email", "password")
    VALUES ('user1', 'user1@email.com', 'password1'),
    ('user2', 'user2@email.com', 'password2'),
    ('user3', 'user3@email.com', 'password3'),
    ('user4', 'user4@email.com', 'password4'),
    ('user5', 'user5@email.com', 'password5');

SELECT
    'a'
    'b'
    'c',
    'hello';

