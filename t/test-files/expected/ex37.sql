CREATE POLICY can_select_object ON object
    FOR SELECT
        USING (can_do_the_thing (get_current_user (), owner_id));

CREATE POLICY can_insert_object ON object
    FOR INSERT
        WITH CHECK (can_do_the_thing (get_current_user (), owner_id));

CREATE POLICY can_update_object ON object
    FOR UPDATE
        USING (can_do_the_thing (get_current_user (), owner_id));

CREATE POLICY can_delete_object ON object
    FOR DELETE
        USING (can_do_the_thing (get_current_user (), owner_id));

CREATE POLICY fp_s ON information
    FOR SELECT
        USING (group_id <= (
            SELECT
                group_id
            FROM
                users
            WHERE
                user_name = CURRENT_USER));

CREATE POLICY fp_s ON information
    FOR SELECT
        USING (group_id <= 10);

CREATE POLICY p1 ON ec1
    USING (f1 < '5'::int8alias1);

CREATE POLICY fp_s ON information
    FOR SELECT
        WITH CHECK (group_id <= (
            SELECT
                group_id
            FROM
                users
            WHERE
                user_name = CURRENT_USER));

CREATE POLICY fp_s ON information
    FOR SELECT
        WITH CHECK (group_id <= 10);

CREATE POLICY p1 ON ec1
    WITH CHECK (f1 < '5'::int8alias1);

CREATE FUNCTION fonction_reference (refcursor)
    RETURNS refcursor
    AS $$
BEGIN
    OPEN $1 FOR
        SELECT
            col
        FROM
            test;
    RETURN $1;
END;
$$
LANGUAGE plpgsql;

CREATE PUBLICATION all_tables FOR ALL TABLES;

CREATE PUBLICATION insert_only FOR TABLE mydata WITH (publish = 'insert');

