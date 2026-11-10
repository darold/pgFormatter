-- Conditional writes, parenthesized casts, CASE assignments, and exception lists.
CREATE FUNCTION public.update_record (p_action text, p_input jsonb)
    RETURNS jsonb
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = ''
    AS $$
DECLARE
    account uuid;
    target uuid;
    STORED public.demo_records;
    patch jsonb;
BEGIN
    account := (p_input ->> 'account_id')::uuid;
    target := (p_input ->> 'id')::uuid;
    PERFORM
        pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('record-write/' || account::text, 0));
    SELECT
        *
    INTO
        STORED
    FROM
        public.demo_records
    WHERE
        account_id = account
        AND id = target
    FOR UPDATE;
    IF p_action = 'insert' THEN
        IF stored.id IS NOT NULL THEN
            IF stored._deleted THEN
                RETURN jsonb_build_object('status', 'deleted');
            END IF;
            RETURN jsonb_build_object('status', 'mismatch', 'record', demo_private.project (to_jsonb (STORED)));
        END IF;
        INSERT INTO public.demo_records (id, account_id, name, note, x_coord, y_coord)
            VALUES (target, account, btrim(p_input ->> 'name'), p_input ->> 'note', (p_input ->> 'x_coord')::double precision, (p_input ->> 'y_coord')::double precision);
    ELSE
        IF stored.id IS NULL THEN
            RETURN jsonb_build_object('status', 'unavailable');
        END IF;
        IF stored._deleted THEN
            RETURN jsonb_build_object('status', 'deleted');
        END IF;
        IF stored.revision::text <> p_input ->> 'expected_revision' THEN
            RETURN jsonb_build_object('status', 'mismatch', 'record', demo_private.project (to_jsonb (STORED)));
        END IF;
        IF p_action = 'delete' THEN
            UPDATE
                public.demo_records
            SET
                _deleted = TRUE
            WHERE
                id = target
                AND account_id = account;
        ELSE
            patch := p_input -> 'patch';
            UPDATE
                public.demo_records p
            SET
                name = CASE WHEN patch ? 'name' THEN
                    btrim(patch ->> 'name')
                ELSE
                    p.name
                END,
                note = CASE WHEN patch ? 'note' THEN
                    patch ->> 'note'
                ELSE
                    p.note
                END,
                x_coord = CASE WHEN patch ? 'x_coord' THEN
                    (patch ->> 'x_coord')::double precision
                ELSE
                    p.x_coord
                END,
                y_coord = CASE WHEN patch ? 'y_coord' THEN
                    (patch ->> 'y_coord')::double precision
                ELSE
                    p.y_coord
                END
            WHERE
                id = target
                AND account_id = account;
        END IF;
    END IF;
    RETURN jsonb_build_object('status', 'accepted', 'records', jsonb_set(demo_private.empty_records (), '{records}', jsonb_build_array(demo_private.read_record ('records', account, target))));
EXCEPTION
    WHEN insufficient_privilege THEN
        RETURN jsonb_build_object('status', 'access_updated');
    WHEN check_violation
        OR invalid_text_representation
        OR numeric_value_out_of_range
        OR unique_violation THEN
        RETURN jsonb_build_object('status', 'rejected', 'code', 'invalid_input');
END;
$$;
