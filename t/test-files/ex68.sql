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
