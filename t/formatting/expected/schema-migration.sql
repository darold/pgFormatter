-- Transactional DDL, parenthesized query loops, and trigger definitions.
BEGIN;

-- Multi-relation locking.
LOCK TABLE app.users,
public.workspace_accounts,
public.workspace_account_users IN share ROW exclusive mode;

CREATE TABLE public.demo_accounts(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (btrim(name) <> ''),
  created timestamptz NOT NULL DEFAULT transaction_timestamp()
);

CREATE TABLE public.demo_account_users(
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES public.demo_accounts(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (ROLE IN ('owner', 'member')),
  PRIMARY KEY (user_id, account_id)
);

CREATE UNIQUE INDEX demo_account_users_owner_account ON public.demo_account_users(account_id)
WHERE
  ROLE = 'owner';

CREATE INDEX demo_account_users_account ON public.demo_account_users(account_id);

ALTER TABLE public.demo_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.demo_account_users ENABLE ROW LEVEL SECURITY;

-- Relation privileges and row security.
REVOKE ALL ON public.demo_accounts, public.demo_account_users FROM public, guest, app_user;

GRANT ALL ON public.demo_accounts, public.demo_account_users TO app_admin;

-- INSERT ... SELECT with a multiline column list.
INSERT INTO public.demo_accounts(
  id,
  name,
  created
)
SELECT
  id,
  name,
  created
FROM
  public.workspace_accounts;

-- Query loop containing nested expressions and RETURNING INTO.
DO $$
DECLARE
  person record;
  account uuid;
BEGIN
  FOR person IN
  (
    SELECT
      u.id,
      u.email,
      u.raw_user_meta_data
    FROM
      app.users u
    WHERE
      NOT EXISTS (
        SELECT
          1
        FROM
          public.demo_account_users m
        WHERE
          m.user_id = u.id
          AND m.role = 'owner'
      )
  ) LOOP
    INSERT INTO public.demo_accounts(
      name
    )
    VALUES (
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
    RETURNING
      id
    INTO
      account;

    INSERT INTO public.demo_account_users(
      user_id,
      account_id,
      role
    )
    VALUES (
      person.id,
      account,
      'owner'
    );

  END LOOP;

END;

$$;

ALTER TABLE public.demo_items
  DROP CONSTRAINT demo_items_account_id_fkey,
  ADD CONSTRAINT demo_items_account_id_fkey FOREIGN KEY (account_id)
  REFERENCES public.demo_accounts(id);

ALTER TABLE public.demo_preferences
  DROP CONSTRAINT demo_preferences_account_id_fkey,
  ADD CONSTRAINT demo_preferences_account_id_fkey FOREIGN KEY (account_id)
  REFERENCES public.demo_accounts(id) ON DELETE CASCADE;

-- Composite foreign key with an ON DELETE action.
ALTER TABLE demo_private.item_grants
  DROP CONSTRAINT item_grants_user_id_account_id_fkey,
  ADD CONSTRAINT item_grants_user_id_account_id_fkey FOREIGN KEY (user_id, account_id)
  REFERENCES public.demo_account_users(user_id, account_id) ON DELETE CASCADE;

-- Trigger function declaration and trigger DDL.
CREATE OR REPLACE FUNCTION demo_private.trigger_create_demo_account()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = ''
  AS $$
DECLARE
  account uuid;
BEGIN
  INSERT INTO public.demo_accounts(
    name
  )
  VALUES (
    coalesce(
      nullif(
        btrim(
          NEW.raw_user_meta_data ->> 'full_name'
        ),
        ''
      ),
      NEW.email,
      'Personal account'
    )
  )
  RETURNING
    id
  INTO
    account;

  INSERT INTO public.demo_account_users(
    user_id,
    account_id,
    role
  )
  VALUES (
    NEW.id,
    account,
    'owner'
  );

  RETURN new;

END;

$$;

REVOKE ALL ON FUNCTION demo_private.trigger_create_demo_account() FROM public, guest, app_user,
  app_admin;

DROP TRIGGER IF EXISTS create_demo_account ON app.users;

CREATE TRIGGER create_demo_account
  AFTER INSERT ON app.users FOR EACH ROW
  EXECUTE FUNCTION demo_private.trigger_create_demo_account();

COMMIT;
