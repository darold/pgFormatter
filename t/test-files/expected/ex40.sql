CREATE OR REPLACE FUNCTION myfunc ()
    RETURNS void
    AS $BODY$
BEGIN
    SET client_min_messages TO warning;
    DROP TABLE IF EXISTS tt_BIP;
    DROP TABLE IF EXISTS tt_tmp;
    SET client_min_messages TO notice;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;

