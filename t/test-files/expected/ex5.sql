CREATE OR REPLACE FUNCTION inserta_esquema_pago_backup ()
    RETURNS TRIGGER
    AS $BODY$
BEGIN
    INSERT INTO educaciondistancia.esquema_pago_backup (curso, numpago, montopagar, estatus, usuario, fecha)
        VALUES (NEW.curso, NEW.numpago, NEW.montopagar, NEW.estatus, NEW.usuario, NEW.fecha);
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;

