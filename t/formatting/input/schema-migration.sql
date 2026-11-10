-- Transactional DDL, parenthesized query loops, and trigger definitions.
begin;

-- Multi-relation locking.
lock table app.users,
public.workspace_accounts,
public.workspace_account_users in share row exclusive mode;

create table public.demo_accounts(
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  created timestamptz not null default transaction_timestamp()
);

create table public.demo_account_users(
  user_id uuid not null references app.users(id) on delete cascade,
  account_id uuid not null references public.demo_accounts(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  primary key (user_id, account_id)
);

create unique index demo_account_users_owner_account on public.demo_account_users(account_id)
where
  role = 'owner';

create index demo_account_users_account on public.demo_account_users(account_id);

alter table public.demo_accounts enable row level security;

alter table public.demo_account_users enable row level security;

-- Relation privileges and row security.
revoke all on public.demo_accounts, public.demo_account_users from public, guest, app_user;

grant all on public.demo_accounts, public.demo_account_users to app_admin;

-- INSERT ... SELECT with a multiline column list.
insert into public.demo_accounts(
  id,
  name,
  created
)
select
  id,
  name,
  created
from
  public.workspace_accounts;

-- Query loop containing nested expressions and RETURNING INTO.
do $$
declare
  person record;
  account uuid;
begin
  for person in
  (
    select
      u.id,
      u.email,
      u.raw_user_meta_data
    from
      app.users u
    where
      not exists (
        select
          1
        from
          public.demo_account_users m
        where
          m.user_id = u.id
          and m.role = 'owner'
      )
  ) loop
      insert into public.demo_accounts(
        name
      )
      values (
        coalesce(
          nullif(
            btrim(
              person.raw_user_meta_data ->> 'full_name'
            ),
            ''
          ),
          person.email,
          'Personal account'
        )
      )
    returning
      id
    into
      account;

    insert into public.demo_account_users(
      user_id,
      account_id,
      role
    )
    values (
      person.id,
      account,
      'owner'
    );

  end loop;

end;

$$;

alter table public.demo_items
  drop constraint demo_items_account_id_fkey,
  add constraint demo_items_account_id_fkey foreign key (account_id)
  references public.demo_accounts(id);

alter table public.demo_preferences
  drop constraint demo_preferences_account_id_fkey,
  add constraint demo_preferences_account_id_fkey foreign key (account_id)
  references public.demo_accounts(id) on delete cascade;

-- Composite foreign key with an ON DELETE action.
alter table demo_private.item_grants
  drop constraint item_grants_user_id_account_id_fkey,
  add constraint item_grants_user_id_account_id_fkey foreign key (user_id, account_id)
  references public.demo_account_users(user_id, account_id) on delete cascade;

-- Trigger function declaration and trigger DDL.
create or replace function demo_private.trigger_create_demo_account()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
  as $$
declare
  account uuid;
begin
  insert into public.demo_accounts(
    name
  )
  values (
    coalesce(
      nullif(
        btrim(
          new.raw_user_meta_data ->> 'full_name'
        ),
        ''
      ),
      new.email,
      'Personal account'
    )
  )
returning
  id
into
  account;

  insert into public.demo_account_users(
    user_id,
    account_id,
    role
  )
  values (
    new.id,
    account,
    'owner'
  );

  return new;

end;

$$;

revoke all on function demo_private.trigger_create_demo_account() from public, guest, app_user, app_admin;

drop trigger if exists create_demo_account on app.users;

create trigger create_demo_account
  after insert on app.users for each row
  execute function demo_private.trigger_create_demo_account();

commit;
