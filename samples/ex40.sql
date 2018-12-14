CREATE OR REPLACE FUNCTION myfunc()

RETURNS void
AS
$BODY$
BEGIN
set client_min_messages to warning;
DROP TABLE IF EXISTS tt_BIP;
DROP TABLE IF EXISTS tt_tmp;
set client_min_messages to notice;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

