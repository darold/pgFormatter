-- Nested INSERT, UPDATE, and DELETE with RETURNING INTO.
CREATE FUNCTION public.change_record(
  p_input jsonb
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = ''
  AS $$
DECLARE
  r public.demo_events;
BEGIN
  IF p_input ->> 'operation' = 'insert' THEN
    IF p_input ->> 'owner_id' IS NOT NULL THEN
      INSERT INTO public.demo_events(
        owner_id,
        labels
      )
      VALUES (
        p_input ->> 'owner_id',
        ARRAY(
          SELECT
            jsonb_array_elements_text(
              p_input -> 'labels'
            )
        )
      )
      RETURNING
        *
      INTO
        r;
    END IF;
    UPDATE
      public.demo_events
    SET
      updated = clock_timestamp()
    WHERE
      id = r.id
    RETURNING
      *
    INTO
      r;
  ELSIF p_input ->> 'operation' = 'delete' THEN
    DELETE FROM public.demo_events
    WHERE id = r.id
    RETURNING
      *
    INTO
      r;
  ELSE
    RETURN NULL;
  END IF;
  RETURN jsonb_build_object(
    'id', r.id,
    'labels', r.labels
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'invalid request' USING errcode = '22023';
END;

$$;
