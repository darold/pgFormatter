-- Composite foreign keys use a separate REFERENCES line in alternate layout.
ALTER TABLE public.child
  DROP CONSTRAINT old_parent,
  ADD CONSTRAINT parent FOREIGN KEY (account_id, user_id)
  REFERENCES public.parent(account_id, user_id) ON DELETE CASCADE,
  ADD COLUMN owner_id uuid REFERENCES public.owner(id),
  ADD CONSTRAINT secondary_parent FOREIGN KEY (other_id)
  REFERENCES public.parent(id);

-- A later statement and inline column references must not inherit FK state.
CREATE TABLE public.other_child(
  id uuid REFERENCES public.parent(id)
);

ALTER TABLE public.other_child
  ADD COLUMN owner_id uuid REFERENCES public.owner(id);
