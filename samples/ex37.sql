CREATE POLICY can_select_object ON object
  FOR SELECT
  USING (
    can_do_the_thing(get_current_user(), owner_id)
  );

CREATE POLICY can_insert_object ON object
  FOR INSERT
  WITH CHECK (
    can_do_the_thing(get_current_user(), owner_id)
  );

CREATE POLICY can_update_object ON object
  FOR UPDATE
  USING (
    can_do_the_thing(get_current_user(), owner_id)
  );

CREATE POLICY can_delete_object ON object
  FOR DELETE
  USING (
    can_do_the_thing(get_current_user(), owner_id)
  );

