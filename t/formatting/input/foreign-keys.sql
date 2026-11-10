-- Composite foreign keys use a separate REFERENCES line in alternate layout.
alter table public.child
  drop constraint old_parent,
  add constraint parent foreign key (account_id, user_id) references public.parent(account_id, user_id) on delete cascade,
  add column owner_id uuid references public.owner(id),
  add constraint secondary_parent foreign key (other_id) references public.parent(id);
-- A later statement and inline column references must not inherit FK state.
create table public.other_child(id uuid references public.parent(id));
alter table public.other_child add column owner_id uuid references public.owner(id);
