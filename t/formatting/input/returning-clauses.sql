-- Nested INSERT, UPDATE, and DELETE with RETURNING INTO.
create function public.change_record(p_input jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.demo_events;
begin
  if p_input ->> 'operation' = 'insert' then
    if p_input ->> 'owner_id' is not null then
      insert into public.demo_events (owner_id, labels)
      values (p_input ->> 'owner_id', array(select jsonb_array_elements_text(p_input -> 'labels')))
      returning * into r;
    end if;
    update public.demo_events
    set updated = clock_timestamp()
    where id = r.id
    returning * into r;
  elsif p_input ->> 'operation' = 'delete' then
    delete from public.demo_events
    where id = r.id
    returning * into r;
  else
    return null;
  end if;
  return jsonb_build_object('id', r.id, 'labels', r.labels);
exception
  when unique_violation then
    raise exception 'invalid request' using errcode = '22023';
end;
$$;
