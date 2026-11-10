-- Policy commands and predicates align; column names retain their case.
create policy read_events on public.events for select to app_user using (extension = 'notice' and public.can_read_event(event_topic()));
create policy account_write on public.accounts for update to app_user using (owner_id = app.user_id()) with check (owner_id = app.user_id() and name <> '');
create policy account_insert on public.accounts for insert to app_user with check (owner_id = app.user_id());
create policy account_read on public.accounts using (exists(select 1 from public.members where user_id = app.user_id() and account_id = accounts.id));
alter policy account_read on public.accounts using (extension = 'notice');
select 1;
create extension if not exists pgcrypto;
