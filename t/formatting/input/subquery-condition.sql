-- A scalar subquery and nested function call must not consume an IF frame.
create function compare_items(p_input jsonb) returns uuid language plpgsql as $$
declare
  result_id uuid;
begin
  if (
    select count(distinct item ->> 'id')
    from jsonb_array_elements(p_input -> 'items') item
  ) <> jsonb_array_length(p_input -> 'items') then raise exception 'invalid input' using errcode = '22023';
  end if;
  insert into demo.items (id, name) values (gen_random_uuid(), 'sample') returning id into result_id;
  return result_id;
end;
$$;
