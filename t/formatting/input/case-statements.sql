-- Procedural CASE branches with SELECT INTO and a default exception.
CREATE OR REPLACE FUNCTION demo_private.read_record (p_collection text, p_account uuid, p_id uuid)
    RETURNS jsonb
    LANGUAGE plpgsql
    STABLE
    SET search_path = ''
    AS $$
DECLARE
    result jsonb;
BEGIN
    CASE p_collection
    WHEN 'items' THEN
        SELECT
            demo_private.project (to_jsonb (r))
        INTO
            result
        FROM
            public.demo_items r
        WHERE
            r.account_id = p_account
            AND r.id = p_id;
    WHEN 'records' THEN
        SELECT
            demo_private.project (to_jsonb (r))
        INTO
            result
        FROM
            public.demo_records r
        WHERE
            r.account_id = p_account
            AND r.id = p_id;
    ELSE
        RAISE EXCEPTION 'Invalid collection'
        USING errcode = '22023';
    END CASE;
    RETURN result;
END;
$$;
