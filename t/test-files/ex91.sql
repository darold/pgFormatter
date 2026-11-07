-- Issue #437: USING clause inside a loop must not shift the following code
create function f(p int) returns void language plpgsql as $$
declare n int; s text; r record;
begin
  for i in 1..2 loop
    execute s into n using p;
  end loop;
  raise notice 'done';
  for i in 1..2 loop
    for j in 1..2 loop
      if p > 0 then
        execute s into n using p, i;
      else
        execute s using j;
      end if;
    end loop;
    case p when 1 then execute s using p; else raise notice 'x'; end case;
  end loop;
  for i in 1..2 loop
    delete from t using u where t.id = u.id;
  end loop;
  for i in 1..2 loop
    raise exception 'x' using hint = 'y';
  end loop;
  for i in 1..2 loop
    raise exception 'x' using errcode = 'P0001';
  end loop;
  for r in execute s using p loop
    raise notice 'r';
  end loop;
  raise notice 'end';
end $$;
