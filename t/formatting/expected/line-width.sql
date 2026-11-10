-- Long validation conditions split at boolean boundaries, without changing literal values.
DO $$
BEGIN
  IF NOT found
    OR r.updated IS NOT NULL
    OR r.expires <= stamp
    OR r.owner_id IS DISTINCT FROM p_input ->> 'owner_id'
    OR r.resource IS DISTINCT FROM p_input ->> 'resource'
  THEN
    RETURN;
  END IF;
  IF length(message) > 5
    AND(ready OR permitted)
    AND owner_id IS NOT DISTINCT FROM requested_owner
    AND enabled
  THEN
    PERFORM
      send_message(message);
  END IF;
END;
$$;

SELECT
  'This literal is intentionally longer than one hundred characters and must stay exactly as written, including spaces and OR keywords.'::text;

SELECT
  E'An escaped quote: \' OR this text remains part of the literal and must never become code or be rewritten to satisfy a width constraint.'::text;

SELECT
  $message$This dollar-quoted literal is intentionally longer than one hundred characters and its whitespace must never be changed by the code wrapper.$message$;

-- This long comment is ordinary prose that should wrap cleanly at the configured column limit while
-- preserving every word and keeping every continuation inside a comment.
REVOKE ALL ON FUNCTION public.a_function_with_a_long_name(uuid, uuid, text, jsonb) FROM public,
  guest, app_user, app_admin;

-- Quoted-language legacy function bodies still need safe comma boundaries.
CREATE FUNCTION public.compact_arguments()
  RETURNS void
  LANGUAGE "plpgsql"
  AS $$
declare result jsonb;
begin
 result:=jsonb_build_object('operation_id',p_operation,'outcome',outcome,'data',to_jsonb(f),
   'error_code',null,'retryable',false);
end;
$$;

SELECT
  1;

-- A deliberately long trailing comment should move onto complete comment lines instead of making
-- the wrapped continuation into executable SQL text.
/* This is a deliberately long block comment whose prose must stay inside its delimiters while the
formatter adds whitespace between its words to keep the code width consistent. */
