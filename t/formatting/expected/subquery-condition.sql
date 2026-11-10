-- A scalar subquery and nested function call must not consume an IF frame.
CREATE FUNCTION compare_items(
  p_input jsonb
)
  RETURNS uuid
  LANGUAGE plpgsql
  AS $$
DECLARE
  result_id uuid;
BEGIN
  IF (
    SELECT
      count(
        DISTINCT item ->> 'id'
      )
    FROM
      jsonb_array_elements(
        p_input -> 'items'
      ) item
  ) <> jsonb_array_length(
    p_input -> 'items'
  ) THEN
    RAISE EXCEPTION 'invalid input' USING errcode = '22023';
  END IF;
  INSERT INTO demo.items(
    id,
    name
  )
  VALUES (
    gen_random_uuid(),
    'sample'
  )
  RETURNING
    id
  INTO
    result_id;
  RETURN result_id;
END;
$$;
