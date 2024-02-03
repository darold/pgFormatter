CREATE FUNCTION name ()
  RETURNS text
  LANGUAGE plpgsql
  SET search_path
FROM
  current
  AS $$
BEGIN
  RETURN 'text';
END;
$$;

