-- Policy commands and predicates align; column names retain their case.
CREATE POLICY read_events ON public.events
  FOR SELECT TO app_user
  USING (
    extension = 'notice'
    AND public.can_read_event(
      event_topic()
    )
  );

CREATE POLICY account_write ON public.accounts
  FOR UPDATE TO app_user
  USING (
    owner_id = app.user_id()
  )
  WITH CHECK (
    owner_id = app.user_id()
    AND name <> ''
  );

CREATE POLICY account_insert ON public.accounts
  FOR INSERT TO app_user
  WITH CHECK (
    owner_id = app.user_id()
  );

CREATE POLICY account_read ON public.accounts
  USING (
    EXISTS (
      SELECT
        1
      FROM
        public.members
      WHERE
        user_id = app.user_id()
        AND account_id = accounts.id
    )
  );

ALTER POLICY account_read ON public.accounts
  USING (
    extension = 'notice'
  );

SELECT
  1;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
