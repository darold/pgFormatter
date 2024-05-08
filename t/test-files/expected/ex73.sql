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

SELECT
    ligne.numligne,
    ligne.numero,
    ligne.date_mouvement,
    ligne.libelle,
    ligne.debit,
    ligne.credit,
    releve.releve_uuid,
    releve.date_fin,
    compte.compte_uuid,
    compte.numcompte,
    devise.devise_uuid,
    devise.code,
    CASE WHEN ligne.typemvt IS NULL THEN
    (
        SELECT
            typemvt_uuid
        FROM
            typemvt
        WHERE
            upper(typemvt.code) = 'PRELEVEMENT')
    ELSE
        (
            SELECT
                typemvt_uuid
            FROM
                typemvt
            WHERE
                upper(typemvt.code) = upper(ligne.typemvt))
    END,
    ligne.ligne_uuid,
    analytique.analytique_uuid
FROM
    ligne
    INNER JOIN releve ON (releve.releve_uuid = ligne.releve_uuid)
    INNER JOIN compte ON (compte.compte_uuid = releve.compte_uuid),
    devise,
    analytique
WHERE
    ligne_uuid = :ligne_uuid
    AND devise.defaut = 'O'
    AND upper(analytique.groupe) = 'DIVERS';

CREATE OR REPLACE FUNCTION loader_os (OUT o_rc integer, OUT o_err character varying, IN i_acctoken character varying, IN i_os text)
    RETURNS record
    AS $$
DECLARE
    v_os bigint;
    v_id bigint;
BEGIN ATOMIC
    SELECT
        * INTO o_rc,
        o_err
    FROM
        loader_add i_acctoken;
END
$$
LANGUAGE plpgsql;
