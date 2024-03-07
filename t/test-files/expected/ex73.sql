CREATE OR REPLACE FUNCTION loader_os (OUT o_rc integer, OUT o_err character varying, IN i_acctoken character varying, IN i_os text)
    RETURNS record
    AS $$
-- Description1
-- Description2
DECLARE
    v_os bigint;
    v_id bigint;
BEGIN
    SELECT
        * INTO o_rc,
        o_err
    FROM
        loader_add i_acctoken;
    -- Description3
    IF o_rc != 0 THEN
        o_err = '(): ' || o_err;
    END IF;
    SELECT
        ost_id INTO STRICT v_os
    FROM
        os_form
    WHERE
        UPPER(ost_form) = UPPER(i_os);
    SELECT
        os_id INTO v_id
    FROM
        os_get (v_os);
    UPDATE
        mbile
    SET
        os_id = 1
    WHERE
        id = v_id;
    UPDATE
        mbsim
    SET
        reg_id = 2
    WHERE
        id = v_id;
END
$$
LANGUAGE plpgsql;

