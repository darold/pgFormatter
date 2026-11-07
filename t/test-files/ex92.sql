-- LOOP following a closing parenthesis must be at the same level as WHILE/FOR
create function f(p int, a int[]) returns void language plpgsql as $$
declare i int := 1; n int; r record;
begin
  while (i < 3) loop
    i := i + 1;
  end loop;
  while i < array_length(a, 1) loop
    i := i + 1;
  end loop;
  for j in 1..2 loop
    while not exists (select 1 from t where id = i) loop
      i := i + 1;
    end loop;
    while (i < 3) and (n > 0) loop
      i := i + 1;
    end loop;
  end loop;
  if p = 0 then
    raise notice 'z';
  elsif p > 1 then
    for r in select * from t where id in (1, 2) loop
      raise notice 'r';
    end loop;
  end if;
  for r in select * from a join b using (x, y) loop
    raise notice 'j';
  end loop;
  raise notice 'end';
end $$;
