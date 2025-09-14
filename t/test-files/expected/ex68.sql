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
VALUES
    ('user1', 'user1@email.com', 'password1'),
    ('user2', 'user2@email.com', 'password2'),
    ('user3', 'user3@email.com', 'password3'),
    ('user4', 'user4@email.com', 'password4'),
    ('user5', 'user5@email.com', 'password5');

SELECT
    'a'
    'b'
    'c',
    'hello';

CREATE SCHEMA hollywood
    CREATE TABLE films (
        title text,
        release date,
        awards text[])
    CREATE VIEW winners AS
    SELECT
        title,
        release
    FROM
        films
    WHERE
        awards IS NOT NULL;

CREATE SCHEMA evttrig
    CREATE TABLE one (
        col_a serial PRIMARY KEY,
        col_b text DEFAULT 'forty two')
    CREATE INDEX one_idx ON one (
        col_b)
    CREATE TABLE two (
        col_c integer CHECK (col_c > 0) REFERENCES one DEFAULT 42
);

CREATE SCHEMA test_ns_schema_1
    CREATE UNIQUE INDEX abc_a_idx ON abc (
        a)
    CREATE VIEW abc_view AS
    SELECT
        a + 1 AS a,
        b + 1 AS b
    FROM
        abc
    CREATE TABLE abc (
        a serial,
        b int UNIQUE)
    CREATE UNIQUE INDEX abc_a_idx2 ON abc (
        b
);

CREATE TABLE IF NOT EXISTS hello (
    foo char(20) NOT NULL UNIQUE,
    bar char(25)
);

CREATE TABLE stock (
    id character varying(6) NOT NULL DEFAULT lpad(cast(nextval('stock_id_seq'::regclass) AS character varying(6)), 6, '0'),
    part_number text NOT NULL,
    quantity integer NOT NULL
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

