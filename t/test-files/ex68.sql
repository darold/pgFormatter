create function rw_view1_trig_fn()
returns trigger as
$$
begin
  if tg_op = 'insert' then
    insert into base_tbl values (new.a, new.b);
    return new;
  elsif tg_op = 'update' then
    update base_tbl set b=new.b where a=old.a;
    return new;
  elsif tg_op = 'delete' then
    delete from base_tbl where a=old.a;
    return old;
  end if;
end;
$$
language plpgsql;


INSERT INTO users ("username", "email", "password")
    VALUES ('user1', 'user1@email.com', 'password1'),
    ('user2', 'user2@email.com', 'password2'),
    ('user3', 'user3@email.com', 'password3'),
    ('user4', 'user4@email.com', 'password4'),
    ('user5', 'user5@email.com', 'password5');

SELECT 'a'
'b'
'c',
'hello';


CREATE SCHEMA hollywood
    CREATE TABLE films (title text, release date, awards text[])
    CREATE VIEW winners AS
        SELECT title, release FROM films WHERE awards IS NOT NULL;


CREATE SCHEMA evttrig
        CREATE TABLE one (col_a SERIAL PRIMARY KEY, col_b text DEFAULT 'forty two')
        CREATE INDEX one_idx ON one (col_b)
        CREATE TABLE two (col_c INTEGER CHECK (col_c > 0) REFERENCES one DEFAULT 42);

CREATE SCHEMA test_ns_schema_1
       CREATE UNIQUE INDEX abc_a_idx ON abc (a)

       CREATE VIEW abc_view AS
              SELECT a+1 AS a, b+1 AS b FROM abc

       CREATE TABLE abc (
              a serial,
              b int UNIQUE
       )
       CREATE UNIQUE INDEX abc_a_idx2 ON abc (b);


CREATE TABLE IF NOT EXISTS hello
(
  foo char(20) NOT NULL UNIQUE,

  -- A comment
  bar char(25)
);


CREATE TABLE stock
(
    id character varying(6) NOT NULL DEFAULT lpad(cast(nextval('stock_id_seq'::regclass) as character varying(6)), 6, '0'),
    part_number text NOT NULL,
    quantity integer NOT NULL
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

