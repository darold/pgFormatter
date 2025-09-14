--
-- PLPGSQL
--
-- Scenario:
--
--     A building with a modern TP cable installation where any
--     of the wall connectors can be used to plug in phones,
--     ethernet interfaces or local office hubs. The backside
--     of the wall connectors is wired to one of several patch-
--     fields in the building.
--
--     In the patchfields, there are hubs and all the slots
--     representing the wall connectors. In addition there are
--     slots that can represent a phone line from the central
--     phone system.
--
--     Triggers ensure consistency of the patching information.
--
--     Functions are used to build up powerful views that let
--     you look behind the wall when looking at a patchfield
--     or into a room.
--
CREATE TABLE Room (
    roomno char(8),
    comment text
);

CREATE UNIQUE INDEX Room_rno ON Room USING btree (roomno bpchar_ops);

CREATE TABLE WSlot (
    slotname char(20),
    roomno char(8),
    slotlink char(20),
    backlink char(20)
);

CREATE UNIQUE INDEX WSlot_name ON WSlot USING btree (slotname bpchar_ops);

CREATE TABLE PField (
    name text,
    comment text
);

CREATE UNIQUE INDEX PField_name ON PField USING btree (name text_ops);

CREATE TABLE PSlot (
    slotname char(20),
    pfname text,
    slotlink char(20),
    backlink char(20)
);

CREATE UNIQUE INDEX PSlot_name ON PSlot USING btree (slotname bpchar_ops);

CREATE TABLE PLine (
    slotname char(20),
    phonenumber char(20),
    comment text,
    backlink char(20)
);

CREATE UNIQUE INDEX PLine_name ON PLine USING btree (slotname bpchar_ops);

CREATE TABLE Hub (
    name char(14),
    comment text,
    nslots integer
);

CREATE UNIQUE INDEX Hub_name ON Hub USING btree (name bpchar_ops);

CREATE TABLE HSlot (
    slotname char(20),
    hubname char(14),
    slotno integer,
    slotlink char(20)
);

CREATE UNIQUE INDEX HSlot_name ON HSlot USING btree (slotname bpchar_ops);

CREATE INDEX HSlot_hubname ON HSlot USING btree (hubname bpchar_ops);

CREATE TABLE SYSTEM (
    name text,
    comment text
);

CREATE UNIQUE INDEX System_name ON SYSTEM USING btree (name text_ops);

CREATE TABLE IFace (
    slotname char(20),
    sysname text,
    ifname text,
    slotlink char(20)
);

CREATE UNIQUE INDEX IFace_name ON IFace USING btree (slotname bpchar_ops);

CREATE TABLE PHone (
    slotname char(20),
    comment text,
    slotlink char(20)
);

CREATE UNIQUE INDEX PHone_name ON PHone USING btree (slotname bpchar_ops);

-- ************************************************************
-- *
-- * Trigger procedures and functions for the patchfield
-- * test of PL/pgSQL
-- *
-- ************************************************************
-- ************************************************************
-- * AFTER UPDATE on Room
-- *	- If room no changes let wall slots follow
-- ************************************************************
CREATE FUNCTION tg_room_au ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.roomno != OLD.roomno THEN
        UPDATE
            WSlot
        SET
            roomno = NEW.roomno
        WHERE
            roomno = OLD.roomno;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_room_au
    AFTER UPDATE ON Room FOR EACH ROW
    EXECUTE PROCEDURE tg_room_au ();

-- ************************************************************
-- * AFTER DELETE on Room
-- *	- delete wall slots in this room
-- ************************************************************
CREATE FUNCTION tg_room_ad ()
    RETURNS TRIGGER
    AS '
BEGIN
    DELETE FROM WSlot
    WHERE roomno = OLD.roomno;
    RETURN old;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_room_ad
    AFTER DELETE ON Room FOR EACH ROW
    EXECUTE PROCEDURE tg_room_ad ();

-- ************************************************************
-- * BEFORE INSERT or UPDATE on WSlot
-- *	- Check that room exists
-- ************************************************************
CREATE FUNCTION tg_wslot_biu ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF count(*) = 0
    FROM
        Room
    WHERE
        roomno = NEW.roomno THEN
        RAISE EXCEPTION 'Room % does not exist', NEW.roomno;
    END IF;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER tg_wslot_biu
    BEFORE INSERT OR UPDATE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_wslot_biu ();

-- ************************************************************
-- * AFTER UPDATE on PField
-- *	- Let PSlots of this field follow
-- ************************************************************
CREATE FUNCTION tg_pfield_au ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.name != OLD.name THEN
        UPDATE
            PSlot
        SET
            pfname = NEW.name
        WHERE
            pfname = OLD.name;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_pfield_au
    AFTER UPDATE ON PField FOR EACH ROW
    EXECUTE PROCEDURE tg_pfield_au ();

-- ************************************************************
-- * AFTER DELETE on PField
-- *	- Remove all slots of this patchfield
-- ************************************************************
CREATE FUNCTION tg_pfield_ad ()
    RETURNS TRIGGER
    AS '
BEGIN
    DELETE FROM PSlot
    WHERE pfname = OLD.name;
    RETURN old;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_pfield_ad
    AFTER DELETE ON PField FOR EACH ROW
    EXECUTE PROCEDURE tg_pfield_ad ();

-- ************************************************************
-- * BEFORE INSERT or UPDATE on PSlot
-- *	- Ensure that our patchfield does exist
-- ************************************************************
CREATE FUNCTION tg_pslot_biu ()
    RETURNS TRIGGER
    AS $proc$
DECLARE
    pfrec record;
    ps alias FOR new;
BEGIN
    SELECT
        INTO pfrec *
    FROM
        PField
    WHERE
        name = ps.pfname;
    IF NOT found THEN
        RAISE EXCEPTION $$ Patchfield "%" does NOT exist$$, ps.pfname;
    END IF;
    RETURN ps;
END;
$proc$
LANGUAGE plpgsql;

CREATE TRIGGER tg_pslot_biu
    BEFORE INSERT OR UPDATE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_pslot_biu ();

-- ************************************************************
-- * AFTER UPDATE on System
-- *	- If system name changes let interfaces follow
-- ************************************************************
CREATE FUNCTION tg_system_au ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.name != OLD.name THEN
        UPDATE
            IFace
        SET
            sysname = NEW.name
        WHERE
            sysname = OLD.name;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_system_au
    AFTER UPDATE ON SYSTEM FOR EACH ROW
    EXECUTE PROCEDURE tg_system_au ();

-- ************************************************************
-- * BEFORE INSERT or UPDATE on IFace
-- *	- set the slotname to IF.sysname.ifname
-- ************************************************************
CREATE FUNCTION tg_iface_biu ()
    RETURNS TRIGGER
    AS $$
DECLARE
    sname text;
    sysrec record;
BEGIN
    SELECT
        INTO sysrec *
    FROM
        SYSTEM
    WHERE
        name = NEW.sysname;
    IF NOT found THEN
        RAISE EXCEPTION $q$system "%" does not exist$q$, NEW.sysname;
    END IF;
    sname := 'IF.' || NEW.sysname;
    sname := sname || '.';
    sname := sname || NEW.ifname;
    IF length(sname) > 20 THEN
        RAISE EXCEPTION 'IFace slotname "%" too long (20 char max)', sname;
    END IF;
    NEW.slotname := sname;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER tg_iface_biu
    BEFORE INSERT OR UPDATE ON IFace FOR EACH ROW
    EXECUTE PROCEDURE tg_iface_biu ();

-- ************************************************************
-- * AFTER INSERT or UPDATE or DELETE on Hub
-- *	- insert/delete/rename slots as required
-- ************************************************************
CREATE FUNCTION tg_hub_a ()
    RETURNS TRIGGER
    AS '
DECLARE
    hname text;
    dummy integer;
BEGIN
    IF tg_op = ''INSERT'' THEN
        dummy := tg_hub_adjustslots (NEW.name, 0, NEW.nslots);
        RETURN new;
    END IF;
    IF tg_op = ''UPDATE'' THEN
        IF NEW.name != OLD.name THEN
            UPDATE
                HSlot
            SET
                hubname = NEW.name
            WHERE
                hubname = OLD.name;
        END IF;
        dummy := tg_hub_adjustslots (NEW.name, OLD.nslots, NEW.nslots);
        RETURN new;
    END IF;
    IF tg_op = ''DELETE'' THEN
        dummy := tg_hub_adjustslots (OLD.name, OLD.nslots, 0);
        RETURN old;
    END IF;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_hub_a
    AFTER INSERT OR UPDATE OR DELETE ON Hub FOR EACH ROW
    EXECUTE PROCEDURE tg_hub_a ();

-- ************************************************************
-- * Support function to add/remove slots of Hub
-- ************************************************************
CREATE FUNCTION tg_hub_adjustslots (hname bpchar, oldnslots integer, newnslots integer)
    RETURNS integer
    AS '
BEGIN
    IF newnslots = oldnslots THEN
        RETURN 0;
    END IF;
    IF newnslots < oldnslots THEN
        DELETE FROM HSlot
        WHERE hubname = hname
            AND slotno > newnslots;
        RETURN 0;
    END IF;
    FOR i IN oldnslots + 1..newnslots LOOP
        INSERT INTO HSlot (slotname, hubname, slotno, slotlink)
            VALUES (''HS.dummy'', hname, i, '''');
    END LOOP;
    RETURN 0;
END
'
LANGUAGE plpgsql;

-- Test comments
COMMENT ON FUNCTION tg_hub_adjustslots_wrong (bpchar, integer, integer) IS 'function with args';

COMMENT ON FUNCTION tg_hub_adjustslots (bpchar, integer, integer) IS 'function with args';

COMMENT ON FUNCTION tg_hub_adjustslots (bpchar, integer, integer) IS NULL;

-- ************************************************************
-- * BEFORE INSERT or UPDATE on HSlot
-- *	- prevent from manual manipulation
-- *	- set the slotname to HS.hubname.slotno
-- ************************************************************
CREATE FUNCTION tg_hslot_biu ()
    RETURNS TRIGGER
    AS '
DECLARE
    sname text;
    xname HSlot.slotname%TYPE;
    hubrec record;
BEGIN
    SELECT
        INTO hubrec *
    FROM
        Hub
    WHERE
        name = NEW.hubname;
    IF NOT found THEN
        RAISE EXCEPTION ''no manual manipulation of HSlot'';
    END IF;
    IF NEW.slotno < 1 OR NEW.slotno > hubrec.nslots THEN
        RAISE EXCEPTION ''no manual manipulation of HSlot'';
    END IF;
    IF tg_op = ''UPDATE'' AND NEW.hubname != OLD.hubname THEN
        IF count(*) > 0
        FROM
            Hub
        WHERE
            name = OLD.hubname THEN
            RAISE EXCEPTION ''no manual manipulation of HSlot'';
        END IF;
    END IF;
    sname := ''HS.'' || trim(NEW.hubname);
    sname := sname || ''.'';
    sname := sname || NEW.slotno::text;
    IF length(sname) > 20 THEN
        RAISE EXCEPTION ''HSlot slotname "%" too long (20 char max)'', sname;
    END IF;
    NEW.slotname := sname;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_hslot_biu
    BEFORE INSERT OR UPDATE ON HSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_hslot_biu ();

-- ************************************************************
-- * BEFORE DELETE on HSlot
-- *	- prevent from manual manipulation
-- ************************************************************
CREATE FUNCTION tg_hslot_bd ()
    RETURNS TRIGGER
    AS '
DECLARE
    hubrec record;
BEGIN
    SELECT
        INTO hubrec *
    FROM
        Hub
    WHERE
        name = OLD.hubname;
    IF NOT found THEN
        RETURN old;
    END IF;
    IF OLD.slotno > hubrec.nslots THEN
        RETURN old;
    END IF;
    RAISE EXCEPTION ''no manual manipulation of HSlot'';
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_hslot_bd
    BEFORE DELETE ON HSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_hslot_bd ();

-- ************************************************************
-- * BEFORE INSERT on all slots
-- *	- Check name prefix
-- ************************************************************
CREATE FUNCTION tg_chkslotname ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF substr(NEW.slotname, 1, 2) != tg_argv[0] THEN
        RAISE EXCEPTION ''slotname must begin with %'', tg_argv[0];
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_chkslotname
    BEFORE INSERT ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotname ('PS');

CREATE TRIGGER tg_chkslotname
    BEFORE INSERT ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotname ('WS');

CREATE TRIGGER tg_chkslotname
    BEFORE INSERT ON PLine FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotname ('PL');

CREATE TRIGGER tg_chkslotname
    BEFORE INSERT ON IFace FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotname ('IF');

CREATE TRIGGER tg_chkslotname
    BEFORE INSERT ON PHone FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotname ('PH');

-- ************************************************************
-- * BEFORE INSERT or UPDATE on all slots with slotlink
-- *	- Set slotlink to empty string if NULL value given
-- ************************************************************
CREATE FUNCTION tg_chkslotlink ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotlink ISNULL THEN
        NEW.slotlink := '''';
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_chkslotlink
    BEFORE INSERT OR UPDATE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotlink ();

CREATE TRIGGER tg_chkslotlink
    BEFORE INSERT OR UPDATE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotlink ();

CREATE TRIGGER tg_chkslotlink
    BEFORE INSERT OR UPDATE ON IFace FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotlink ();

CREATE TRIGGER tg_chkslotlink
    BEFORE INSERT OR UPDATE ON HSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotlink ();

CREATE TRIGGER tg_chkslotlink
    BEFORE INSERT OR UPDATE ON PHone FOR EACH ROW
    EXECUTE PROCEDURE tg_chkslotlink ();

-- ************************************************************
-- * BEFORE INSERT or UPDATE on all slots with backlink
-- *	- Set backlink to empty string if NULL value given
-- ************************************************************
CREATE FUNCTION tg_chkbacklink ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.backlink ISNULL THEN
        NEW.backlink := '''';
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_chkbacklink
    BEFORE INSERT OR UPDATE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkbacklink ();

CREATE TRIGGER tg_chkbacklink
    BEFORE INSERT OR UPDATE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_chkbacklink ();

CREATE TRIGGER tg_chkbacklink
    BEFORE INSERT OR UPDATE ON PLine FOR EACH ROW
    EXECUTE PROCEDURE tg_chkbacklink ();

-- ************************************************************
-- * BEFORE UPDATE on PSlot
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_pslot_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname THEN
        DELETE FROM PSlot
        WHERE slotname = OLD.slotname;
        INSERT INTO PSlot (slotname, pfname, slotlink, backlink)
            VALUES (NEW.slotname, NEW.pfname, NEW.slotlink, NEW.backlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_pslot_bu
    BEFORE UPDATE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_pslot_bu ();

-- ************************************************************
-- * BEFORE UPDATE on WSlot
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_wslot_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname THEN
        DELETE FROM WSlot
        WHERE slotname = OLD.slotname;
        INSERT INTO WSlot (slotname, roomno, slotlink, backlink)
            VALUES (NEW.slotname, NEW.roomno, NEW.slotlink, NEW.backlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_wslot_bu
    BEFORE UPDATE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_Wslot_bu ();

-- ************************************************************
-- * BEFORE UPDATE on PLine
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_pline_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname THEN
        DELETE FROM PLine
        WHERE slotname = OLD.slotname;
        INSERT INTO PLine (slotname, phonenumber, comment, backlink)
            VALUES (NEW.slotname, NEW.phonenumber, NEW.comment, NEW.backlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_pline_bu
    BEFORE UPDATE ON PLine FOR EACH ROW
    EXECUTE PROCEDURE tg_pline_bu ();

-- ************************************************************
-- * BEFORE UPDATE on IFace
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_iface_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname THEN
        DELETE FROM IFace
        WHERE slotname = OLD.slotname;
        INSERT INTO IFace (slotname, sysname, ifname, slotlink)
            VALUES (NEW.slotname, NEW.sysname, NEW.ifname, NEW.slotlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_iface_bu
    BEFORE UPDATE ON IFace FOR EACH ROW
    EXECUTE PROCEDURE tg_iface_bu ();

-- ************************************************************
-- * BEFORE UPDATE on HSlot
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_hslot_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname OR NEW.hubname != OLD.hubname THEN
        DELETE FROM HSlot
        WHERE slotname = OLD.slotname;
        INSERT INTO HSlot (slotname, hubname, slotno, slotlink)
            VALUES (NEW.slotname, NEW.hubname, NEW.slotno, NEW.slotlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_hslot_bu
    BEFORE UPDATE ON HSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_hslot_bu ();

-- ************************************************************
-- * BEFORE UPDATE on PHone
-- *	- do delete/insert instead of update if name changes
-- ************************************************************
CREATE FUNCTION tg_phone_bu ()
    RETURNS TRIGGER
    AS '
BEGIN
    IF NEW.slotname != OLD.slotname THEN
        DELETE FROM PHone
        WHERE slotname = OLD.slotname;
        INSERT INTO PHone (slotname, comment, slotlink)
            VALUES (NEW.slotname, NEW.comment, NEW.slotlink);
        RETURN NULL;
    END IF;
    RETURN new;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_phone_bu
    BEFORE UPDATE ON PHone FOR EACH ROW
    EXECUTE PROCEDURE tg_phone_bu ();

-- ************************************************************
-- * AFTER INSERT or UPDATE or DELETE on slot with backlink
-- *	- Ensure that the opponent correctly points back to us
-- ************************************************************
CREATE FUNCTION tg_backlink_a ()
    RETURNS TRIGGER
    AS '
DECLARE
    dummy integer;
BEGIN
    IF tg_op = ''INSERT'' THEN
        IF NEW.backlink != '''' THEN
            dummy := tg_backlink_set (NEW.backlink, NEW.slotname);
        END IF;
        RETURN new;
    END IF;
    IF tg_op = ''UPDATE'' THEN
        IF NEW.backlink != OLD.backlink THEN
            IF OLD.backlink != '''' THEN
                dummy := tg_backlink_unset (OLD.backlink, OLD.slotname);
            END IF;
            IF NEW.backlink != '''' THEN
                dummy := tg_backlink_set (NEW.backlink, NEW.slotname);
            END IF;
        ELSE
            IF NEW.slotname != OLD.slotname AND NEW.backlink != '''' THEN
                dummy := tg_slotlink_set (NEW.backlink, NEW.slotname);
            END IF;
        END IF;
        RETURN new;
    END IF;
    IF tg_op = ''DELETE'' THEN
        IF OLD.backlink != '''' THEN
            dummy := tg_backlink_unset (OLD.backlink, OLD.slotname);
        END IF;
        RETURN old;
    END IF;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_backlink_a
    AFTER INSERT OR UPDATE OR DELETE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_backlink_a ('PS');

CREATE TRIGGER tg_backlink_a
    AFTER INSERT OR UPDATE OR DELETE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_backlink_a ('WS');

CREATE TRIGGER tg_backlink_a
    AFTER INSERT OR UPDATE OR DELETE ON PLine FOR EACH ROW
    EXECUTE PROCEDURE tg_backlink_a ('PL');

-- ************************************************************
-- * Support function to set the opponents backlink field
-- * if it does not already point to the requested slot
-- ************************************************************
CREATE FUNCTION tg_backlink_set (myname bpchar, blname bpchar)
    RETURNS integer
    AS '
DECLARE
    mytype char(2);
    link char(4);
    rec record;
BEGIN
    mytype := substr(myname, 1, 2);
    link := mytype || substr(blname, 1, 2);
    IF link = ''PLPL'' THEN
        RAISE EXCEPTION ''backlink between two phone lines does not make sense'';
    END IF;
    IF link IN (''PLWS'', ''WSPL'') THEN
        RAISE EXCEPTION ''direct link of phone line to wall slot not permitted'';
    END IF;
    IF mytype = ''PS'' THEN
        SELECT
            INTO rec *
        FROM
            PSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.backlink != blname THEN
            UPDATE
                PSlot
            SET
                backlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''WS'' THEN
        SELECT
            INTO rec *
        FROM
            WSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.backlink != blname THEN
            UPDATE
                WSlot
            SET
                backlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''PL'' THEN
        SELECT
            INTO rec *
        FROM
            PLine
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.backlink != blname THEN
            UPDATE
                PLine
            SET
                backlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    RAISE EXCEPTION ''illegal backlink beginning with %'', mytype;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * Support function to clear out the backlink field if
-- * it still points to specific slot
-- ************************************************************
CREATE FUNCTION tg_backlink_unset (bpchar, bpchar)
    RETURNS integer
    AS '
DECLARE
    myname alias FOR $1;
    blname alias FOR $2;
    mytype char(2);
    rec record;
BEGIN
    mytype := substr(myname, 1, 2);
    IF mytype = ''PS'' THEN
        SELECT
            INTO rec *
        FROM
            PSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.backlink = blname THEN
            UPDATE
                PSlot
            SET
                backlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''WS'' THEN
        SELECT
            INTO rec *
        FROM
            WSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.backlink = blname THEN
            UPDATE
                WSlot
            SET
                backlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''PL'' THEN
        SELECT
            INTO rec *
        FROM
            PLine
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.backlink = blname THEN
            UPDATE
                PLine
            SET
                backlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
END
'
LANGUAGE plpgsql;

-- ************************************************************
-- * AFTER INSERT or UPDATE or DELETE on slot with slotlink
-- *	- Ensure that the opponent correctly points back to us
-- ************************************************************
CREATE FUNCTION tg_slotlink_a ()
    RETURNS TRIGGER
    AS '
DECLARE
    dummy integer;
BEGIN
    IF tg_op = ''INSERT'' THEN
        IF NEW.slotlink != '''' THEN
            dummy := tg_slotlink_set (NEW.slotlink, NEW.slotname);
        END IF;
        RETURN new;
    END IF;
    IF tg_op = ''UPDATE'' THEN
        IF NEW.slotlink != OLD.slotlink THEN
            IF OLD.slotlink != '''' THEN
                dummy := tg_slotlink_unset (OLD.slotlink, OLD.slotname);
            END IF;
            IF NEW.slotlink != '''' THEN
                dummy := tg_slotlink_set (NEW.slotlink, NEW.slotname);
            END IF;
        ELSE
            IF NEW.slotname != OLD.slotname AND NEW.slotlink != '''' THEN
                dummy := tg_slotlink_set (NEW.slotlink, NEW.slotname);
            END IF;
        END IF;
        RETURN new;
    END IF;
    IF tg_op = ''DELETE'' THEN
        IF OLD.slotlink != '''' THEN
            dummy := tg_slotlink_unset (OLD.slotlink, OLD.slotname);
        END IF;
        RETURN old;
    END IF;
END;
'
LANGUAGE plpgsql;

CREATE TRIGGER tg_slotlink_a
    AFTER INSERT OR UPDATE OR DELETE ON PSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_slotlink_a ('PS');

CREATE TRIGGER tg_slotlink_a
    AFTER INSERT OR UPDATE OR DELETE ON WSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_slotlink_a ('WS');

CREATE TRIGGER tg_slotlink_a
    AFTER INSERT OR UPDATE OR DELETE ON IFace FOR EACH ROW
    EXECUTE PROCEDURE tg_slotlink_a ('IF');

CREATE TRIGGER tg_slotlink_a
    AFTER INSERT OR UPDATE OR DELETE ON HSlot FOR EACH ROW
    EXECUTE PROCEDURE tg_slotlink_a ('HS');

CREATE TRIGGER tg_slotlink_a
    AFTER INSERT OR UPDATE OR DELETE ON PHone FOR EACH ROW
    EXECUTE PROCEDURE tg_slotlink_a ('PH');

-- ************************************************************
-- * Support function to set the opponents slotlink field
-- * if it does not already point to the requested slot
-- ************************************************************
CREATE FUNCTION tg_slotlink_set (bpchar, bpchar)
    RETURNS integer
    AS '
DECLARE
    myname alias FOR $1;
    blname alias FOR $2;
    mytype char(2);
    link char(4);
    rec record;
BEGIN
    mytype := substr(myname, 1, 2);
    link := mytype || substr(blname, 1, 2);
    IF link = ''PHPH'' THEN
        RAISE EXCEPTION ''slotlink between two phones does not make sense'';
    END IF;
    IF link IN (''PHHS'', ''HSPH'') THEN
        RAISE EXCEPTION ''link of phone to hub does not make sense'';
    END IF;
    IF link IN (''PHIF'', ''IFPH'') THEN
        RAISE EXCEPTION ''link of phone to hub does not make sense'';
    END IF;
    IF link IN (''PSWS'', ''WSPS'') THEN
        RAISE EXCEPTION ''slotlink from patchslot to wallslot not permitted'';
    END IF;
    IF mytype = ''PS'' THEN
        SELECT
            INTO rec *
        FROM
            PSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.slotlink != blname THEN
            UPDATE
                PSlot
            SET
                slotlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''WS'' THEN
        SELECT
            INTO rec *
        FROM
            WSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.slotlink != blname THEN
            UPDATE
                WSlot
            SET
                slotlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''IF'' THEN
        SELECT
            INTO rec *
        FROM
            IFace
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.slotlink != blname THEN
            UPDATE
                IFace
            SET
                slotlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''HS'' THEN
        SELECT
            INTO rec *
        FROM
            HSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.slotlink != blname THEN
            UPDATE
                HSlot
            SET
                slotlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''PH'' THEN
        SELECT
            INTO rec *
        FROM
            PHone
        WHERE
            slotname = myname;
        IF NOT found THEN
            RAISE EXCEPTION ''% does not exist'', myname;
        END IF;
        IF rec.slotlink != blname THEN
            UPDATE
                PHone
            SET
                slotlink = blname
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    RAISE EXCEPTION ''illegal slotlink beginning with %'', mytype;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * Support function to clear out the slotlink field if
-- * it still points to specific slot
-- ************************************************************
CREATE FUNCTION tg_slotlink_unset (bpchar, bpchar)
    RETURNS integer
    AS '
DECLARE
    myname alias FOR $1;
    blname alias FOR $2;
    mytype char(2);
    rec record;
BEGIN
    mytype := substr(myname, 1, 2);
    IF mytype = ''PS'' THEN
        SELECT
            INTO rec *
        FROM
            PSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.slotlink = blname THEN
            UPDATE
                PSlot
            SET
                slotlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''WS'' THEN
        SELECT
            INTO rec *
        FROM
            WSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.slotlink = blname THEN
            UPDATE
                WSlot
            SET
                slotlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''IF'' THEN
        SELECT
            INTO rec *
        FROM
            IFace
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.slotlink = blname THEN
            UPDATE
                IFace
            SET
                slotlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''HS'' THEN
        SELECT
            INTO rec *
        FROM
            HSlot
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.slotlink = blname THEN
            UPDATE
                HSlot
            SET
                slotlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
    IF mytype = ''PH'' THEN
        SELECT
            INTO rec *
        FROM
            PHone
        WHERE
            slotname = myname;
        IF NOT found THEN
            RETURN 0;
        END IF;
        IF rec.slotlink = blname THEN
            UPDATE
                PHone
            SET
                slotlink = ''''
            WHERE
                slotname = myname;
        END IF;
        RETURN 0;
    END IF;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * Describe the backside of a patchfield slot
-- ************************************************************
CREATE FUNCTION pslot_backlink_view (bpchar)
    RETURNS text
    AS '
    <<
    OUTER >>
DECLARE
    rec record;
    bltype char(2);
    retval text;
BEGIN
    SELECT
        INTO rec *
    FROM
        PSlot
    WHERE
        slotname = $1;
        IF NOT found THEN
            RETURN '''';
        END IF;
        IF rec.backlink = '''' THEN
            RETURN ''-'';
        END IF;
        bltype := substr(rec.backlink, 1, 2);
        IF bltype = ''PL'' THEN
            DECLARE rec record;
            BEGIN
                SELECT
                    INTO rec *
                FROM
                    PLine
                WHERE
                    slotname = "outer".rec.backlink;
                    retval := ''Phone line '' || trim(rec.phonenumber);
                    IF rec.comment != '''' THEN
                        retval := retval || '' ('';
                        retval := retval || rec.comment;
                        retval := retval || '')'';
                    END IF;
                    RETURN retval;
            END;
        END IF;
        IF bltype = ''WS'' THEN
            SELECT
                INTO rec *
            FROM
                WSlot
            WHERE
                slotname = rec.backlink;
                retval := trim(rec.slotname) || '' in room '';
                retval := retval || trim(rec.roomno);
                retval := retval || '' -> '';
                RETURN retval || wslot_slotlink_view (rec.slotname);
        END IF;
        RETURN rec.backlink;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * Describe the front of a patchfield slot
-- ************************************************************
CREATE FUNCTION pslot_slotlink_view (bpchar)
    RETURNS text
    AS '
DECLARE
    psrec record;
    sltype char(2);
    retval text;
BEGIN
    SELECT
        INTO psrec *
    FROM
        PSlot
    WHERE
        slotname = $1;
    IF NOT found THEN
        RETURN '''';
    END IF;
    IF psrec.slotlink = '''' THEN
        RETURN ''-'';
    END IF;
    sltype := substr(psrec.slotlink, 1, 2);
    IF sltype = ''PS'' THEN
        retval := trim(psrec.slotlink) || '' -> '';
        RETURN retval || pslot_backlink_view (psrec.slotlink);
    END IF;
    IF sltype = ''HS'' THEN
        retval := comment
    FROM
        Hub H,
        HSlot HS
    WHERE
        HS.slotname = psrec.slotlink
            AND H.name = HS.hubname;
        retval := retval || '' slot '';
        retval := retval || slotno::text
    FROM
        HSlot
    WHERE
        slotname = psrec.slotlink;
        RETURN retval;
    END IF;
    RETURN psrec.slotlink;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * Describe the front of a wall connector slot
-- ************************************************************
CREATE FUNCTION wslot_slotlink_view (bpchar)
    RETURNS text
    AS '
DECLARE
    rec record;
    sltype char(2);
    retval text;
BEGIN
    SELECT
        INTO rec *
    FROM
        WSlot
    WHERE
        slotname = $1;
    IF NOT found THEN
        RETURN '''';
    END IF;
    IF rec.slotlink = '''' THEN
        RETURN ''-'';
    END IF;
    sltype := substr(rec.slotlink, 1, 2);
    IF sltype = ''PH'' THEN
        SELECT
            INTO rec *
        FROM
            PHone
        WHERE
            slotname = rec.slotlink;
        retval := ''Phone '' || trim(rec.slotname);
        IF rec.comment != '''' THEN
            retval := retval || '' ('';
            retval := retval || rec.comment;
            retval := retval || '')'';
        END IF;
        RETURN retval;
    END IF;
    IF sltype = ''IF'' THEN
        DECLARE syrow System%RowType;
        ifrow IFace%ROWTYPE;
        BEGIN
            SELECT
                INTO ifrow *
            FROM
                IFace
            WHERE
                slotname = rec.slotlink;
            SELECT
                INTO syrow *
            FROM
                SYSTEM
            WHERE
                name = ifrow.sysname;
            retval := syrow.name || '' IF '';
            retval := retval || ifrow.ifname;
            IF syrow.comment != '''' THEN
                retval := retval || '' ('';
                retval := retval || syrow.comment;
                retval := retval || '')'';
            END IF;
            RETURN retval;
        END;
    END IF;
    RETURN rec.slotlink;
END;
'
LANGUAGE plpgsql;

-- ************************************************************
-- * View of a patchfield describing backside and patches
-- ************************************************************
CREATE VIEW Pfield_v1 AS
SELECT
    PF.pfname,
    PF.slotname,
    pslot_backlink_view (PF.slotname) AS backside,
    pslot_slotlink_view (PF.slotname) AS patch
FROM
    PSlot PF;

--
-- First we build the house - so we create the rooms
--
INSERT INTO Room
    VALUES ('001', 'Entrance');

INSERT INTO Room
    VALUES ('002', 'Office');

INSERT INTO Room
    VALUES ('003', 'Office');

INSERT INTO Room
    VALUES ('004', 'Technical');

INSERT INTO Room
    VALUES ('101', 'Office');

INSERT INTO Room
    VALUES ('102', 'Conference');

INSERT INTO Room
    VALUES ('103', 'Restroom');

INSERT INTO Room
    VALUES ('104', 'Technical');

INSERT INTO Room
    VALUES ('105', 'Office');

INSERT INTO Room
    VALUES ('106', 'Office');

--
-- Second we install the wall connectors
--
INSERT INTO WSlot
    VALUES ('WS.001.1a', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.001.1b', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.001.2a', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.001.2b', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.001.3a', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.001.3b', '001', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.1a', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.1b', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.2a', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.2b', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.3a', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.002.3b', '002', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.1a', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.1b', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.2a', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.2b', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.3a', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.003.3b', '003', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.1a', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.1b', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.2a', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.2b', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.3a', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.101.3b', '101', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.1a', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.1b', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.2a', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.2b', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.3a', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.102.3b', '102', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.1a', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.1b', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.2a', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.2b', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.3a', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.105.3b', '105', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.1a', '106', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.1b', '106', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.2a', '106', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.2b', '106', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.3a', '106', '', '');

INSERT INTO WSlot
    VALUES ('WS.106.3b', '106', '', '');

--
-- Now create the patch fields and their slots
--
INSERT INTO PField
    VALUES ('PF0_1', 'Wallslots basement');

--
-- The cables for these will be made later, so they are unconnected for now
--
INSERT INTO PSlot
    VALUES ('PS.base.a1', 'PF0_1', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.a2', 'PF0_1', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.a3', 'PF0_1', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.a4', 'PF0_1', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.a5', 'PF0_1', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.a6', 'PF0_1', '', '');

--
-- These are already wired to the wall connectors
--
INSERT INTO PSlot
    VALUES ('PS.base.b1', 'PF0_1', '', 'WS.002.1a');

INSERT INTO PSlot
    VALUES ('PS.base.b2', 'PF0_1', '', 'WS.002.1b');

INSERT INTO PSlot
    VALUES ('PS.base.b3', 'PF0_1', '', 'WS.002.2a');

INSERT INTO PSlot
    VALUES ('PS.base.b4', 'PF0_1', '', 'WS.002.2b');

INSERT INTO PSlot
    VALUES ('PS.base.b5', 'PF0_1', '', 'WS.002.3a');

INSERT INTO PSlot
    VALUES ('PS.base.b6', 'PF0_1', '', 'WS.002.3b');

INSERT INTO PSlot
    VALUES ('PS.base.c1', 'PF0_1', '', 'WS.003.1a');

INSERT INTO PSlot
    VALUES ('PS.base.c2', 'PF0_1', '', 'WS.003.1b');

INSERT INTO PSlot
    VALUES ('PS.base.c3', 'PF0_1', '', 'WS.003.2a');

INSERT INTO PSlot
    VALUES ('PS.base.c4', 'PF0_1', '', 'WS.003.2b');

INSERT INTO PSlot
    VALUES ('PS.base.c5', 'PF0_1', '', 'WS.003.3a');

INSERT INTO PSlot
    VALUES ('PS.base.c6', 'PF0_1', '', 'WS.003.3b');

--
-- This patchfield will be renamed later into PF0_2 - so its
-- slots references in pfname should follow
--
INSERT INTO PField
    VALUES ('PF0_X', 'Phonelines basement');

INSERT INTO PSlot
    VALUES ('PS.base.ta1', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.ta2', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.ta3', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.ta4', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.ta5', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.ta6', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb1', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb2', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb3', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb4', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb5', 'PF0_X', '', '');

INSERT INTO PSlot
    VALUES ('PS.base.tb6', 'PF0_X', '', '');

INSERT INTO PField
    VALUES ('PF1_1', 'Wallslots first floor');

INSERT INTO PSlot
    VALUES ('PS.first.a1', 'PF1_1', '', 'WS.101.1a');

INSERT INTO PSlot
    VALUES ('PS.first.a2', 'PF1_1', '', 'WS.101.1b');

INSERT INTO PSlot
    VALUES ('PS.first.a3', 'PF1_1', '', 'WS.101.2a');

INSERT INTO PSlot
    VALUES ('PS.first.a4', 'PF1_1', '', 'WS.101.2b');

INSERT INTO PSlot
    VALUES ('PS.first.a5', 'PF1_1', '', 'WS.101.3a');

INSERT INTO PSlot
    VALUES ('PS.first.a6', 'PF1_1', '', 'WS.101.3b');

INSERT INTO PSlot
    VALUES ('PS.first.b1', 'PF1_1', '', 'WS.102.1a');

INSERT INTO PSlot
    VALUES ('PS.first.b2', 'PF1_1', '', 'WS.102.1b');

INSERT INTO PSlot
    VALUES ('PS.first.b3', 'PF1_1', '', 'WS.102.2a');

INSERT INTO PSlot
    VALUES ('PS.first.b4', 'PF1_1', '', 'WS.102.2b');

INSERT INTO PSlot
    VALUES ('PS.first.b5', 'PF1_1', '', 'WS.102.3a');

INSERT INTO PSlot
    VALUES ('PS.first.b6', 'PF1_1', '', 'WS.102.3b');

INSERT INTO PSlot
    VALUES ('PS.first.c1', 'PF1_1', '', 'WS.105.1a');

INSERT INTO PSlot
    VALUES ('PS.first.c2', 'PF1_1', '', 'WS.105.1b');

INSERT INTO PSlot
    VALUES ('PS.first.c3', 'PF1_1', '', 'WS.105.2a');

INSERT INTO PSlot
    VALUES ('PS.first.c4', 'PF1_1', '', 'WS.105.2b');

INSERT INTO PSlot
    VALUES ('PS.first.c5', 'PF1_1', '', 'WS.105.3a');

INSERT INTO PSlot
    VALUES ('PS.first.c6', 'PF1_1', '', 'WS.105.3b');

INSERT INTO PSlot
    VALUES ('PS.first.d1', 'PF1_1', '', 'WS.106.1a');

INSERT INTO PSlot
    VALUES ('PS.first.d2', 'PF1_1', '', 'WS.106.1b');

INSERT INTO PSlot
    VALUES ('PS.first.d3', 'PF1_1', '', 'WS.106.2a');

INSERT INTO PSlot
    VALUES ('PS.first.d4', 'PF1_1', '', 'WS.106.2b');

INSERT INTO PSlot
    VALUES ('PS.first.d5', 'PF1_1', '', 'WS.106.3a');

INSERT INTO PSlot
    VALUES ('PS.first.d6', 'PF1_1', '', 'WS.106.3b');

--
-- Now we wire the wall connectors 1a-2a in room 001 to the
-- patchfield. In the second update we make an error, and
-- correct it after
--
UPDATE
    PSlot
SET
    backlink = 'WS.001.1a'
WHERE
    slotname = 'PS.base.a1';

UPDATE
    PSlot
SET
    backlink = 'WS.001.1b'
WHERE
    slotname = 'PS.base.a3';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

UPDATE
    PSlot
SET
    backlink = 'WS.001.2a'
WHERE
    slotname = 'PS.base.a3';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

UPDATE
    PSlot
SET
    backlink = 'WS.001.1b'
WHERE
    slotname = 'PS.base.a2';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

--
-- Same procedure for 2b-3b but this time updating the WSlot instead
-- of the PSlot. Due to the triggers the result is the same:
-- WSlot and corresponding PSlot point to each other.
--
UPDATE
    WSlot
SET
    backlink = 'PS.base.a4'
WHERE
    slotname = 'WS.001.2b';

UPDATE
    WSlot
SET
    backlink = 'PS.base.a6'
WHERE
    slotname = 'WS.001.3a';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

UPDATE
    WSlot
SET
    backlink = 'PS.base.a6'
WHERE
    slotname = 'WS.001.3b';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

UPDATE
    WSlot
SET
    backlink = 'PS.base.a5'
WHERE
    slotname = 'WS.001.3a';

SELECT
    *
FROM
    WSlot
WHERE
    roomno = '001'
ORDER BY
    slotname;

SELECT
    *
FROM
    PSlot
WHERE
    slotname ~ 'PS.base.a'
ORDER BY
    slotname;

INSERT INTO PField
    VALUES ('PF1_2', 'Phonelines first floor');

INSERT INTO PSlot
    VALUES ('PS.first.ta1', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.ta2', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.ta3', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.ta4', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.ta5', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.ta6', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb1', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb2', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb3', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb4', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb5', 'PF1_2', '', '');

INSERT INTO PSlot
    VALUES ('PS.first.tb6', 'PF1_2', '', '');

--
-- Fix the wrong name for patchfield PF0_2
--
UPDATE
    PField
SET
    name = 'PF0_2'
WHERE
    name = 'PF0_X';

SELECT
    *
FROM
    PSlot
ORDER BY
    slotname;

SELECT
    *
FROM
    WSlot
ORDER BY
    slotname;

--
-- Install the central phone system and create the phone numbers.
-- They are wired on insert to the patchfields. Again the
-- triggers automatically tell the PSlots to update their
-- backlink field.
--
INSERT INTO PLine
    VALUES ('PL.001', '-0', 'Central call', 'PS.base.ta1');

INSERT INTO PLine
    VALUES ('PL.002', '-101', '', 'PS.base.ta2');

INSERT INTO PLine
    VALUES ('PL.003', '-102', '', 'PS.base.ta3');

INSERT INTO PLine
    VALUES ('PL.004', '-103', '', 'PS.base.ta5');

INSERT INTO PLine
    VALUES ('PL.005', '-104', '', 'PS.base.ta6');

INSERT INTO PLine
    VALUES ('PL.006', '-106', '', 'PS.base.tb2');

INSERT INTO PLine
    VALUES ('PL.007', '-108', '', 'PS.base.tb3');

INSERT INTO PLine
    VALUES ('PL.008', '-109', '', 'PS.base.tb4');

INSERT INTO PLine
    VALUES ('PL.009', '-121', '', 'PS.base.tb5');

INSERT INTO PLine
    VALUES ('PL.010', '-122', '', 'PS.base.tb6');

INSERT INTO PLine
    VALUES ('PL.015', '-134', '', 'PS.first.ta1');

INSERT INTO PLine
    VALUES ('PL.016', '-137', '', 'PS.first.ta3');

INSERT INTO PLine
    VALUES ('PL.017', '-139', '', 'PS.first.ta4');

INSERT INTO PLine
    VALUES ('PL.018', '-362', '', 'PS.first.tb1');

INSERT INTO PLine
    VALUES ('PL.019', '-363', '', 'PS.first.tb2');

INSERT INTO PLine
    VALUES ('PL.020', '-364', '', 'PS.first.tb3');

INSERT INTO PLine
    VALUES ('PL.021', '-365', '', 'PS.first.tb5');

INSERT INTO PLine
    VALUES ('PL.022', '-367', '', 'PS.first.tb6');

INSERT INTO PLine
    VALUES ('PL.028', '-501', 'Fax entrance', 'PS.base.ta2');

INSERT INTO PLine
    VALUES ('PL.029', '-502', 'Fax first floor', 'PS.first.ta1');

--
-- Buy some phones, plug them into the wall and patch the
-- phone lines to the corresponding patchfield slots.
--
INSERT INTO PHone
    VALUES ('PH.hc001', 'Hicom standard', 'WS.001.1a');

UPDATE
    PSlot
SET
    slotlink = 'PS.base.ta1'
WHERE
    slotname = 'PS.base.a1';

INSERT INTO PHone
    VALUES ('PH.hc002', 'Hicom standard', 'WS.002.1a');

UPDATE
    PSlot
SET
    slotlink = 'PS.base.ta5'
WHERE
    slotname = 'PS.base.b1';

INSERT INTO PHone
    VALUES ('PH.hc003', 'Hicom standard', 'WS.002.2a');

UPDATE
    PSlot
SET
    slotlink = 'PS.base.tb2'
WHERE
    slotname = 'PS.base.b3';

INSERT INTO PHone
    VALUES ('PH.fax001', 'Canon fax', 'WS.001.2a');

UPDATE
    PSlot
SET
    slotlink = 'PS.base.ta2'
WHERE
    slotname = 'PS.base.a3';

--
-- Install a hub at one of the patchfields, plug a computers
-- ethernet interface into the wall and patch it to the hub.
--
INSERT INTO Hub
    VALUES ('base.hub1', 'Patchfield PF0_1 hub', 16);

INSERT INTO SYSTEM
    VALUES ('orion', 'PC');

INSERT INTO IFace
    VALUES ('IF', 'orion', 'eth0', 'WS.002.1b');

UPDATE
    PSlot
SET
    slotlink = 'HS.base.hub1.1'
WHERE
    slotname = 'PS.base.b2';

--
-- Now we take a look at the patchfield
--
SELECT
    *
FROM
    PField_v1
WHERE
    pfname = 'PF0_1'
ORDER BY
    slotname;

SELECT
    *
FROM
    PField_v1
WHERE
    pfname = 'PF0_2'
ORDER BY
    slotname;

--
-- Finally we want errors
--
INSERT INTO PField
    VALUES ('PF1_1', 'should fail due to unique index');

UPDATE
    PSlot
SET
    backlink = 'WS.not.there'
WHERE
    slotname = 'PS.base.a1';

UPDATE
    PSlot
SET
    backlink = 'XX.illegal'
WHERE
    slotname = 'PS.base.a1';

UPDATE
    PSlot
SET
    slotlink = 'PS.not.there'
WHERE
    slotname = 'PS.base.a1';

UPDATE
    PSlot
SET
    slotlink = 'XX.illegal'
WHERE
    slotname = 'PS.base.a1';

INSERT INTO HSlot
    VALUES ('HS', 'base.hub1', 1, '');

INSERT INTO HSlot
    VALUES ('HS', 'base.hub1', 20, '');

DELETE FROM HSlot;

INSERT INTO IFace
    VALUES ('IF', 'notthere', 'eth0', '');

INSERT INTO IFace
    VALUES ('IF', 'orion', 'ethernet_interface_name_too_long', '');

--
-- The following tests are unrelated to the scenario outlined above;
-- they merely exercise specific parts of PL/pgSQL
--
--
-- Test recursion, per bug report 7-Sep-01
--
CREATE FUNCTION recursion_test (int, int)
    RETURNS text
    AS '
DECLARE
    rslt text;
BEGIN
    IF $1 <= 0 THEN
        rslt = CAST($2 AS text);
    ELSE
        rslt = CAST($1 AS text) || '','' || recursion_test ($1 - 1, $2);
    END IF;
    RETURN rslt;
END;
'
LANGUAGE plpgsql;

SELECT
    recursion_test (4, 3);

--
-- Test the FOUND magic variable
--
CREATE TABLE found_test_tbl (
    a int
);

CREATE FUNCTION test_found ()
    RETURNS boolean
    AS '
DECLARE
BEGIN
    INSERT INTO found_test_tbl
        VALUES (1);
    IF FOUND THEN
        INSERT INTO found_test_tbl
            VALUES (2);
    END IF;
    UPDATE
        found_test_tbl
    SET
        a = 100
    WHERE
        a = 1;
    IF FOUND THEN
        INSERT INTO found_test_tbl
            VALUES (3);
    END IF;
    DELETE FROM found_test_tbl
    WHERE a = 9999;
    -- matches no rows
    IF NOT FOUND THEN
        INSERT INTO found_test_tbl
            VALUES (4);
    END IF;
    FOR i IN 1..10 LOOP
        -- no need to do anything
    END LOOP;
    IF FOUND THEN
        INSERT INTO found_test_tbl
            VALUES (5);
    END IF;
    -- never executes the loop
    FOR i IN 2..1 LOOP
        -- no need to do anything
    END LOOP;
    IF NOT FOUND THEN
        INSERT INTO found_test_tbl
            VALUES (6);
    END IF;
    RETURN TRUE;
END;
'
LANGUAGE plpgsql;

SELECT
    test_found ();

SELECT
    *
FROM
    found_test_tbl;

--
-- Test set-returning functions for PL/pgSQL
--
CREATE FUNCTION test_table_func_rec ()
    RETURNS SETOF found_test_tbl
    AS '
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
    SELECT
        *
    FROM
        found_test_tbl LOOP
            RETURN NEXT rec;
        END LOOP;
    RETURN;
END;
'
LANGUAGE plpgsql;

SELECT
    *
FROM
    test_table_func_rec ();

CREATE FUNCTION test_table_func_row ()
    RETURNS SETOF found_test_tbl
    AS '
DECLARE
    ROW found_test_tbl%ROWTYPE;
BEGIN
    FOR ROW IN
    SELECT
        *
    FROM
        found_test_tbl LOOP
            RETURN NEXT ROW;
        END LOOP;
    RETURN;
END;
'
LANGUAGE plpgsql;

SELECT
    *
FROM
    test_table_func_row ();

CREATE FUNCTION test_ret_set_scalar (int, int)
    RETURNS SETOF int
    AS '
DECLARE
    i int;
BEGIN
    FOR i IN $1..$2 LOOP
        RETURN NEXT i + 1;
    END LOOP;
    RETURN;
END;
'
LANGUAGE plpgsql;

SELECT
    *
FROM
    test_ret_set_scalar (1, 10);

CREATE FUNCTION test_ret_set_rec_dyn (int)
    RETURNS SETOF record
    AS '
DECLARE
    retval RECORD;
BEGIN
    IF $1 > 10 THEN
        SELECT
            INTO retval 5,
            10,
            15;
        RETURN NEXT retval;
        RETURN NEXT retval;
    ELSE
        SELECT
            INTO retval 50,
            5::numeric,
            ''xxx''::text;
        RETURN NEXT retval;
        RETURN NEXT retval;
    END IF;
    RETURN;
END;
'
LANGUAGE plpgsql;

SELECT
    *
FROM
    test_ret_set_rec_dyn (1500)
    AS (a int, b int, c int);

SELECT
    *
FROM
    test_ret_set_rec_dyn (5)
    AS (a int, b numeric, c text);

CREATE FUNCTION test_ret_rec_dyn (int)
    RETURNS record
    AS '
DECLARE
    retval RECORD;
BEGIN
    IF $1 > 10 THEN
        SELECT
            INTO retval 5,
            10,
            15;
        RETURN retval;
    ELSE
        SELECT
            INTO retval 50,
            5::numeric,
            ''xxx''::text;
        RETURN retval;
    END IF;
END;
'
LANGUAGE plpgsql;

SELECT
    *
FROM
    test_ret_rec_dyn (1500)
    AS (a int, b int, c int);

SELECT
    *
FROM
    test_ret_rec_dyn (5)
    AS (a int, b numeric, c text);

--
-- Test handling of OUT parameters, including polymorphic cases.
-- Note that RETURN is optional with OUT params; we try both ways.
--
-- wrong way to do it:
CREATE FUNCTION f1 (IN i int, out j int)
    RETURNS int
    AS $$
BEGIN
    RETURN i + 1;
END
$$
LANGUAGE plpgsql;

CREATE FUNCTION f1 (IN i int, out j int)
AS $$
BEGIN
    j := i + 1;
    RETURN;
END
$$
LANGUAGE plpgsql;

SELECT
    f1 (42);

SELECT
    *
FROM
    f1 (42);

CREATE OR REPLACE FUNCTION f1 (INOUT i int)
AS $$
BEGIN
    i := i + 1;
END
$$
LANGUAGE plpgsql;

SELECT
    f1 (42);

SELECT
    *
FROM
    f1 (42);

DROP FUNCTION f1 (int);

CREATE FUNCTION f1 (IN i int, out j int)
    RETURNS SETOF int
    AS $$
BEGIN
    j := i + 1;
    RETURN NEXT;
    j := i + 2;
    RETURN NEXT;
    RETURN;
END
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    f1 (42);

DROP FUNCTION f1 (int);

CREATE FUNCTION f1 (IN i int, out j int, out k text)
AS $$
BEGIN
    j := i;
    j := j + 1;
    k := 'foo';
END
$$
LANGUAGE plpgsql;

SELECT
    f1 (42);

SELECT
    *
FROM
    f1 (42);

DROP FUNCTION f1 (int);

CREATE FUNCTION f1 (IN i int, out j int, out k text)
    RETURNS SETOF record
    AS $$
BEGIN
    j := i + 1;
    k := 'foo';
    RETURN NEXT;
    j := j + 1;
    k := 'foot';
    RETURN NEXT;
END
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    f1 (42);

DROP FUNCTION f1 (int);

CREATE FUNCTION duplic (IN i anyelement, out j anyelement, out k anyarray)
AS $$
BEGIN
    j := i;
    k := ARRAY[j, j];
    RETURN;
END
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    duplic (42);

SELECT
    *
FROM
    duplic ('foo'::text);

DROP FUNCTION duplic (anyelement);

--
-- test PERFORM
--
CREATE TABLE perform_test (
    a int,
    b int
);

CREATE FUNCTION perform_simple_func (int)
    RETURNS boolean
    AS '
BEGIN
    IF $1 < 20 THEN
        INSERT INTO perform_test
            VALUES ($1, $1 + 10);
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
'
LANGUAGE plpgsql;

CREATE FUNCTION perform_test_func ()
    RETURNS void
    AS '
BEGIN
    IF FOUND THEN
        INSERT INTO perform_test
            VALUES (100, 100);
    END IF;
    PERFORM
        perform_simple_func (5);
    IF FOUND THEN
        INSERT INTO perform_test
            VALUES (100, 100);
    END IF;
    PERFORM
        perform_simple_func (50);
    IF FOUND THEN
        INSERT INTO perform_test
            VALUES (100, 100);
    END IF;
    RETURN;
END;
'
LANGUAGE plpgsql;

SELECT
    perform_test_func ();

SELECT
    *
FROM
    perform_test;

DROP TABLE perform_test;

--
-- Test proper snapshot handling in simple expressions
--
CREATE temp TABLE users (
    login text,
    id serial
);

CREATE FUNCTION sp_id_user (a_login text)
    RETURNS int
    AS $$
DECLARE
    x int;
BEGIN
    SELECT
        INTO x id
    FROM
        users
    WHERE
        login = a_login;
    IF found THEN
        RETURN x;
    END IF;
    RETURN 0;
END
$$
LANGUAGE plpgsql
STABLE;

INSERT INTO users
    VALUES ('user1');

SELECT
    sp_id_user ('user1');

SELECT
    sp_id_user ('userx');

CREATE FUNCTION sp_add_user (a_login text)
    RETURNS int
    AS $$
DECLARE
    my_id_user int;
BEGIN
    my_id_user = sp_id_user (a_login);
    IF my_id_user > 0 THEN
        RETURN -1;
        -- error code for existing user
    END IF;
    INSERT INTO users (login)
        VALUES (a_login);
    my_id_user = sp_id_user (a_login);
    IF my_id_user = 0 THEN
        RETURN -2;
        -- error code for insertion failure
    END IF;
    RETURN my_id_user;
END
$$
LANGUAGE plpgsql;

SELECT
    sp_add_user ('user1');

SELECT
    sp_add_user ('user2');

SELECT
    sp_add_user ('user2');

SELECT
    sp_add_user ('user3');

SELECT
    sp_add_user ('user3');

DROP FUNCTION sp_add_user (text);

DROP FUNCTION sp_id_user (text);

--
-- tests for refcursors
--
CREATE TABLE rc_test (
    a int,
    b int
);

CREATE FUNCTION return_unnamed_refcursor ()
    RETURNS refcursor
    AS $$
DECLARE
    rc refcursor;
BEGIN
    OPEN rc FOR
        SELECT
            a
        FROM
            rc_test;
    RETURN rc;
END
$$
LANGUAGE plpgsql;

CREATE FUNCTION use_refcursor (rc refcursor)
    RETURNS int
    AS $$
DECLARE
    rc refcursor;
    x record;
BEGIN
    rc := return_unnamed_refcursor ();
    FETCH NEXT FROM rc INTO x;
    RETURN x.a;
END
$$
LANGUAGE plpgsql;

SELECT
    use_refcursor (return_unnamed_refcursor ());

CREATE FUNCTION return_refcursor (rc refcursor)
    RETURNS refcursor
    AS $$
BEGIN
    OPEN rc FOR
        SELECT
            a
        FROM
            rc_test;
    RETURN rc;
END
$$
LANGUAGE plpgsql;

CREATE FUNCTION refcursor_test1 (refcursor)
    RETURNS refcursor
    AS $$
BEGIN
    PERFORM
        return_refcursor ($1);
    RETURN $1;
END
$$
LANGUAGE plpgsql;

BEGIN;
SELECT
    refcursor_test1 ('test1');
FETCH NEXT IN test1;
SELECT
    refcursor_test1 ('test2');
FETCH ALL FROM test2;
COMMIT;

-- should fail
FETCH NEXT
FROM
    test1;

CREATE FUNCTION refcursor_test2 (int, int)
    RETURNS boolean
    AS $$
DECLARE
    c1 CURSOR (param1 int,
        param2 int)
    FOR
        SELECT
            *
        FROM
            rc_test
        WHERE
            a > param1
            AND b > param2;
    nonsense record;
BEGIN
    OPEN c1 ($1,
        $2);
    FETCH c1 INTO nonsense;
    CLOSE c1;
    IF found THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$
LANGUAGE plpgsql;

SELECT
    refcursor_test2 (20000, 20000) AS "Should be false",
    refcursor_test2 (20, 20) AS "Should be true";

--
-- tests for cursors with named parameter arguments
--
CREATE FUNCTION namedparmcursor_test1 (int, int)
    RETURNS boolean
    AS $$
DECLARE
    c1 CURSOR (param1 int,
        param12 int)
    FOR
        SELECT
            *
        FROM
            rc_test
        WHERE
            a > param1
            AND b > param12;
    nonsense record;
BEGIN
    OPEN c1 (param12 := $2,
        param1 := $1);
    FETCH c1 INTO nonsense;
    CLOSE c1;
    IF found THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$
LANGUAGE plpgsql;

SELECT
    namedparmcursor_test1 (20000, 20000) AS "Should be false",
    namedparmcursor_test1 (20, 20) AS "Should be true";

-- mixing named and positional argument notations
CREATE FUNCTION namedparmcursor_test2 (int, int)
    RETURNS boolean
    AS $$
DECLARE
    c1 CURSOR (param1 int,
        param2 int)
    FOR
        SELECT
            *
        FROM
            rc_test
        WHERE
            a > param1
            AND b > param2;
    nonsense record;
BEGIN
    OPEN c1 (param1 := $1,
        $2);
    FETCH c1 INTO nonsense;
    CLOSE c1;
    IF found THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$
LANGUAGE plpgsql;

SELECT
    namedparmcursor_test2 (20, 20);

-- mixing named and positional: param2 is given twice, once in named notation
-- and second time in positional notation. Should throw an error at parse time
CREATE FUNCTION namedparmcursor_test3 ()
    RETURNS void
    AS $$
DECLARE
    c1 CURSOR (param1 int,
        param2 int)
    FOR
        SELECT
            *
        FROM
            rc_test
        WHERE
            a > param1
            AND b > param2;
BEGIN
    OPEN c1 (param2 := 20,
        21);
END
$$
LANGUAGE plpgsql;

-- mixing named and positional: same as previous test, but param1 is duplicated
CREATE FUNCTION namedparmcursor_test4 ()
    RETURNS void
    AS $$
DECLARE
    c1 CURSOR (param1 int,
        param2 int)
    FOR
        SELECT
            *
        FROM
            rc_test
        WHERE
            a > param1
            AND b > param2;
BEGIN
    OPEN c1 (20,
        param1 := 21);
END
$$
LANGUAGE plpgsql;

-- duplicate named parameter, should throw an error at parse time
CREATE FUNCTION namedparmcursor_test5 ()
    RETURNS void
    AS $$
DECLARE
    c1 CURSOR (p1 int,
        p2 int)
    FOR
        SELECT
            *
        FROM
            tenk1
        WHERE
            thousand = p1
            AND tenthous = p2;
BEGIN
    OPEN c1 (p2 := 77,
        p2 := 42);
END
$$
LANGUAGE plpgsql;

-- not enough parameters, should throw an error at parse time
CREATE FUNCTION namedparmcursor_test6 ()
    RETURNS void
    AS $$
DECLARE
    c1 CURSOR (p1 int,
        p2 int)
    FOR
        SELECT
            *
        FROM
            tenk1
        WHERE
            thousand = p1
            AND tenthous = p2;
BEGIN
    OPEN c1 (p2 := 77);
END
$$
LANGUAGE plpgsql;

-- division by zero runtime error, the context given in the error message
-- should be sensible
CREATE FUNCTION namedparmcursor_test7 ()
    RETURNS void
    AS $$
DECLARE
    c1 CURSOR (p1 int,
        p2 int)
    FOR
        SELECT
            *
        FROM
            tenk1
        WHERE
            thousand = p1
            AND tenthous = p2;
BEGIN
    OPEN c1 (p2 := 77,
        p1 := 42 / 0);
END
$$
LANGUAGE plpgsql;

SELECT
    namedparmcursor_test7 ();

-- check that line comments work correctly within the argument list (there
-- is some special handling of this case in the code: the newline after the
-- comment must be preserved when the argument-evaluating query is
-- constructed, otherwise the comment effectively comments out the next
-- argument, too)
CREATE FUNCTION namedparmcursor_test8 ()
    RETURNS int4
    AS $$
DECLARE
    c1 CURSOR (p1 int,
        p2 int)
    FOR
        SELECT
            count(*)
        FROM
            tenk1
        WHERE
            thousand = p1
            AND tenthous = p2;
    n int4;
BEGIN
    OPEN c1 (77, -- test
        42);
    FETCH c1 INTO n;
    RETURN n;
END
$$
LANGUAGE plpgsql;

SELECT
    namedparmcursor_test8 ();

-- cursor parameter name can match plpgsql variable or unreserved keyword
CREATE FUNCTION namedparmcursor_test9 (p1 int)
    RETURNS int4
    AS $$
DECLARE
    c1 CURSOR (p1 int,
        p2 int,
        debug int)
    FOR
        SELECT
            count(*)
        FROM
            tenk1
        WHERE
            thousand = p1
            AND tenthous = p2
            AND four = debug;
    p2 int4 := 1006;
    n int4;
BEGIN
    OPEN c1 (p1 := p1,
        p2 := p2,
        debug := 2);
    FETCH c1 INTO n;
    RETURN n;
END
$$
LANGUAGE plpgsql;

SELECT
    namedparmcursor_test9 (6);

--
-- tests for "raise" processing
--
CREATE FUNCTION raise_test1 (int)
    RETURNS int
    AS $$
BEGIN
    RAISE NOTICE 'This message has too many parameters!', $1;
    RETURN $1;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION raise_test2 (int)
    RETURNS int
    AS $$
BEGIN
    RAISE NOTICE 'This message has too few parameters: %, %, %', $1, $1;
    RETURN $1;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION raise_test3 (int)
    RETURNS int
    AS $$
BEGIN
    RAISE NOTICE 'This message has no parameters (despite having %% signs in it)!';
    RETURN $1;
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test3 (1);

-- Test re-RAISE inside a nested exception block.  This case is allowed
-- by Oracle's PL/SQL but was handled differently by PG before 9.1.
CREATE FUNCTION reraise_test ()
    RETURNS void
    AS $$
BEGIN
    BEGIN
        RAISE syntax_error;
    EXCEPTION
        WHEN syntax_error THEN
            BEGIN
                RAISE NOTICE 'exception % thrown in inner block, reraising', sqlerrm;
                RAISE;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'RIGHT - exception % caught in inner block', sqlerrm;
            END;
    END;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'WRONG - exception % caught in outer block', sqlerrm;
END;

$$
LANGUAGE plpgsql;

SELECT
    reraise_test ();

--
-- reject function definitions that contain malformed SQL queries at
-- compile-time, where possible
--
CREATE FUNCTION bad_sql1 ()
    RETURNS int
    AS $$
DECLARE
    a int;
BEGIN
    a := 5;
    Johnny Yuma;
    a := 10;
    RETURN a;
END
$$
LANGUAGE plpgsql;

CREATE FUNCTION bad_sql2 ()
    RETURNS int
    AS $$
DECLARE
    r record;
BEGIN
    FOR r IN
    SELECT
        I fought the law,
        the law won LOOP
            RAISE NOTICE 'in loop';
        END LOOP;
    RETURN 5;
END;
$$
LANGUAGE plpgsql;

-- a RETURN expression is mandatory, except for void-returning
-- functions, where it is not allowed
CREATE FUNCTION missing_return_expr ()
    RETURNS int
    AS $$
BEGIN
    RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION void_return_expr ()
    RETURNS void
    AS $$
BEGIN
    RETURN 5;
END;
$$
LANGUAGE plpgsql;

-- VOID functions are allowed to omit RETURN
CREATE FUNCTION void_return_expr ()
    RETURNS void
    AS $$
BEGIN
    PERFORM
        2 + 2;
END;
$$
LANGUAGE plpgsql;

SELECT
    void_return_expr ();

-- but ordinary functions are not
CREATE FUNCTION missing_return_expr ()
    RETURNS int
    AS $$
BEGIN
    PERFORM
        2 + 2;
END;
$$
LANGUAGE plpgsql;

SELECT
    missing_return_expr ();

DROP FUNCTION void_return_expr ();

DROP FUNCTION missing_return_expr ();

--
-- EXECUTE ... INTO test
--
CREATE TABLE eifoo (
    i integer,
    y integer
);

CREATE TYPE eitype AS (
    i integer,
    y integer
);

CREATE OR REPLACE FUNCTION execute_into_test (varchar)
    RETURNS record
    AS $$
DECLARE
    _r record;
    _rt eifoo%rowtype;
    _v eitype;
    i int;
    j int;
    k int;
BEGIN
    EXECUTE 'insert into ' || $1 || ' values(10,15)';
    EXECUTE 'select (row).* from (select row(10,1)::eifoo) s' INTO _r;
    RAISE NOTICE '% %', _r.i, _r.y;
    EXECUTE 'select * from ' || $1 || ' limit 1' INTO _rt;
    RAISE NOTICE '% %', _rt.i, _rt.y;
    EXECUTE 'select *, 20 from ' || $1 || ' limit 1' INTO i,
    j,
    k;
    RAISE NOTICE '% % %', i, j, k;
    EXECUTE 'select 1,2' INTO _v;
    RETURN _v;
END;
$$
LANGUAGE plpgsql;

SELECT
    execute_into_test ('eifoo');

DROP TABLE eifoo CASCADE;

DROP TYPE eitype CASCADE;

--
-- SQLSTATE and SQLERRM test
--
CREATE FUNCTION excpt_test1 ()
    RETURNS void
    AS $$
BEGIN
    RAISE NOTICE '% %', sqlstate, sqlerrm;
END;
$$
LANGUAGE plpgsql;

-- should fail: SQLSTATE and SQLERRM are only in defined EXCEPTION
-- blocks
SELECT
    excpt_test1 ();

CREATE FUNCTION excpt_test2 ()
    RETURNS void
    AS $$
BEGIN
    BEGIN
        BEGIN
            RAISE NOTICE '% %', sqlstate, sqlerrm;
        END;
    END;
END;
$$
LANGUAGE plpgsql;

-- should fail
SELECT
    excpt_test2 ();

CREATE FUNCTION excpt_test3 ()
    RETURNS void
    AS $$
BEGIN
    BEGIN
        RAISE EXCEPTION 'user exception';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'caught exception % %', sqlstate, sqlerrm;
            BEGIN
                RAISE NOTICE '% %', sqlstate, sqlerrm;
                PERFORM
                    10 / 0;
            EXCEPTION
                WHEN substring_error THEN
                    -- this exception handler shouldn't be invoked
                    RAISE NOTICE 'unexpected exception: % %', sqlstate, sqlerrm;
                WHEN division_by_zero THEN
                    RAISE NOTICE 'caught exception % %', sqlstate, sqlerrm;
            END;
            RAISE NOTICE '% %', sqlstate, sqlerrm;
    END;
END;

$$
LANGUAGE plpgsql;

SELECT
    excpt_test3 ();

CREATE FUNCTION excpt_test4 ()
    RETURNS text
    AS $$
BEGIN
    BEGIN
        PERFORM
            1 / 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END;
END;

$$
LANGUAGE plpgsql;

SELECT
    excpt_test4 ();

DROP FUNCTION excpt_test1 ();

DROP FUNCTION excpt_test2 ();

DROP FUNCTION excpt_test3 ();

DROP FUNCTION excpt_test4 ();

-- parameters of raise stmt can be expressions
CREATE FUNCTION raise_exprs ()
    RETURNS void
    AS $$
DECLARE
    a integer[] = '{10,20,30}';
    c varchar = 'xyz';
    i integer;
BEGIN
    i := 2;
    RAISE NOTICE '%; %; %; %; %; %', a, a[i], c, (
        SELECT
            c || 'abc'),
    ROW (10,
        'aaa',
        NULL,
        30),
    NULL;
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_exprs ();

DROP FUNCTION raise_exprs ();

-- regression test: verify that multiple uses of same plpgsql datum within
-- a SQL command all get mapped to the same $n parameter.  The return value
-- of the SELECT is not important, we only care that it doesn't fail with
-- a complaint about an ungrouped column reference.
CREATE FUNCTION multi_datum_use (p1 int)
    RETURNS bool
    AS $$
DECLARE
    x int;
    y int;
BEGIN
    SELECT
        INTO x,
        y unique1 / p1,
        unique1 / $1
    FROM
        tenk1
    GROUP BY
        unique1 / p1;
    RETURN x = y;
END
$$
LANGUAGE plpgsql;

SELECT
    multi_datum_use (42);

--
-- Test STRICT limiter in both planned and EXECUTE invocations.
-- Note that a data-modifying query is quasi strict (disallow multi rows)
-- by default in the planned case, but not in EXECUTE.
--
CREATE temp TABLE foo (
    f1 int,
    f2 int
);

INSERT INTO foo
VALUES
    (1, 2),
    (3, 4);

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should work
    INSERT INTO foo
        VALUES (5, 6)
    RETURNING
        * INTO x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should fail due to implicit strict
    INSERT INTO foo
    VALUES
        (7, 8),
        (9, 10)
    RETURNING
        * INTO x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should work
    EXECUTE 'insert into foo values(5,6) returning *' INTO x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- this should work since EXECUTE isn't as picky
    EXECUTE 'insert into foo values(7,8),(9,10) returning *' INTO x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

SELECT
    *
FROM
    foo;

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should work
    SELECT
        *
    FROM
        foo
    WHERE
        f1 = 3 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should fail, no rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 = 0 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should fail, too many rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 > 3 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should work
    EXECUTE 'select * from foo where f1 = 3' INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should fail, no rows
    EXECUTE 'select * from foo where f1 = 0' INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- should fail, too many rows
    EXECUTE 'select * from foo where f1 > 3' INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

DROP FUNCTION stricttest ();

-- test printing parameters after failure due to STRICT
SET plpgsql.print_strict_params TO TRUE;

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
    p1 int := 2;
    p3 text := 'foo';
BEGIN
    -- no rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 = p1
        AND f1::text = p3 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
    p1 int := 2;
    p3 text := 'foo';
BEGIN
    -- too many rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 > p1
        OR f1::text = p3 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- too many rows, no params
    SELECT
        *
    FROM
        foo
    WHERE
        f1 > 3 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- no rows
    EXECUTE 'select * from foo where f1 = $1 or f1::text = $2'
    USING 0, 'foo' INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- too many rows
    EXECUTE 'select * from foo where f1 > $1'
    USING 1 INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
DECLARE
    x record;
BEGIN
    -- too many rows, no parameters
    EXECUTE 'select * from foo where f1 > 3' INTO STRICT x;
    RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
    -- override the global
    # print_strict_params OFF
DECLARE
    x record;
    p1 int := 2;
    p3 text := 'foo';
BEGIN
    -- too many rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 > p1
        OR f1::text = p3 INTO STRICT x;
        RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

RESET plpgsql.print_strict_params;

CREATE OR REPLACE FUNCTION stricttest ()
    RETURNS void
    AS $$
    -- override the global
    # print_strict_params ON
DECLARE
    x record;
    p1 int := 2;
    p3 text := 'foo';
BEGIN
    -- too many rows
    SELECT
        *
    FROM
        foo
    WHERE
        f1 > p1
        OR f1::text = p3 INTO STRICT x;
        RAISE NOTICE 'x.f1 = %, x.f2 = %', x.f1, x.f2;
END
$$
LANGUAGE plpgsql;

SELECT
    stricttest ();

-- test warnings and errors
SET plpgsql.extra_warnings TO 'all';

SET plpgsql.extra_warnings TO 'none';

SET plpgsql.extra_errors TO 'all';

SET plpgsql.extra_errors TO 'none';

-- test warnings when shadowing a variable
SET plpgsql.extra_warnings TO 'shadowed_variables';

-- simple shadowing of input and output parameters
CREATE OR REPLACE FUNCTION shadowtest (in1 int)
    RETURNS TABLE (
        out1 int
    )
    AS $$
DECLARE
    in1 int;
    out1 int;
BEGIN
END
$$
LANGUAGE plpgsql;

SELECT
    shadowtest (1);

SET plpgsql.extra_warnings TO 'shadowed_variables';

SELECT
    shadowtest (1);

CREATE OR REPLACE FUNCTION shadowtest (in1 int)
    RETURNS TABLE (
        out1 int
    )
    AS $$
DECLARE
    in1 int;
    out1 int;
BEGIN
END
$$
LANGUAGE plpgsql;

SELECT
    shadowtest (1);

DROP FUNCTION shadowtest (int);

-- shadowing in a second DECLARE block
CREATE OR REPLACE FUNCTION shadowtest ()
    RETURNS void
    AS $$
DECLARE
    f1 int;
BEGIN
    DECLARE f1 int;
    BEGIN
    END;
END
$$
LANGUAGE plpgsql;

DROP FUNCTION shadowtest ();

-- several levels of shadowing
CREATE OR REPLACE FUNCTION shadowtest (in1 int)
    RETURNS void
    AS $$
DECLARE
    in1 int;
BEGIN
    DECLARE in1 int;
    BEGIN
    END;
END
$$
LANGUAGE plpgsql;

DROP FUNCTION shadowtest (int);

-- shadowing in cursor definitions
CREATE OR REPLACE FUNCTION shadowtest ()
    RETURNS void
    AS $$
DECLARE
    f1 int;
    c1 CURSOR (f1 int)
    FOR
        SELECT
            1;
BEGIN
END
$$
LANGUAGE plpgsql;

DROP FUNCTION shadowtest ();

-- test errors when shadowing a variable
SET plpgsql.extra_errors TO 'shadowed_variables';

CREATE OR REPLACE FUNCTION shadowtest (f1 int)
    RETURNS boolean
    AS $$
DECLARE
    f1 int;
BEGIN
    RETURN 1;
END
$$
LANGUAGE plpgsql;

SELECT
    shadowtest (1);

RESET plpgsql.extra_errors;

RESET plpgsql.extra_warnings;

CREATE OR REPLACE FUNCTION shadowtest (f1 int)
    RETURNS boolean
    AS $$
DECLARE
    f1 int;
BEGIN
    RETURN 1;
END
$$
LANGUAGE plpgsql;

SELECT
    shadowtest (1);

-- runtime extra checks
SET plpgsql.extra_warnings TO 'too_many_rows';

DO $$
DECLARE
    x int;
BEGIN
    SELECT
        v
    FROM
        generate_series(1, 2) g (v) INTO x;
END;
$$;

SET plpgsql.extra_errors TO 'too_many_rows';

DO $$
DECLARE
    x int;
BEGIN
    SELECT
        v
    FROM
        generate_series(1, 2) g (v) INTO x;
END;
$$;

RESET plpgsql.extra_errors;

RESET plpgsql.extra_warnings;

SET plpgsql.extra_warnings TO 'strict_multi_assignment';

DO $$
DECLARE
    x int;
    y int;
BEGIN
    SELECT
        1 INTO x,
        y;
    SELECT
        1,
        2 INTO x,
        y;
    SELECT
        1,
        2,
        3 INTO x,
        y;
END
$$;

SET plpgsql.extra_errors TO 'strict_multi_assignment';

DO $$
DECLARE
    x int;
    y int;
BEGIN
    SELECT
        1 INTO x,
        y;
    SELECT
        1,
        2 INTO x,
        y;
    SELECT
        1,
        2,
        3 INTO x,
        y;
END
$$;

CREATE TABLE test_01 (
    a int,
    b int,
    c int
);

ALTER TABLE test_01
    DROP COLUMN a;

-- the check is active only when source table is not empty
INSERT INTO test_01
    VALUES (10, 20);

DO $$
DECLARE
    x int;
    y int;
BEGIN
    SELECT
        *
    FROM
        test_01 INTO x,
        y;
    -- should be ok
    RAISE NOTICE 'ok';
    SELECT
        *
    FROM
        test_01 INTO x;
    -- should to fail
END;
$$;

DO $$
DECLARE
    t test_01;
BEGIN
    SELECT
        1,
        2 INTO t;
    -- should be ok
    RAISE NOTICE 'ok';
    SELECT
        1,
        2,
        3 INTO t;
    -- should fail;
END;
$$;

DO $$
DECLARE
    t test_01;
BEGIN
    SELECT
        1 INTO t;
    -- should fail;
END;
$$;

DROP TABLE test_01;

RESET plpgsql.extra_errors;

RESET plpgsql.extra_warnings;

-- test scrollable cursor support
CREATE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c SCROLL CURSOR FOR
        SELECT
            f1
        FROM
            int4_tbl;
    x integer;
BEGIN
    OPEN c;
    FETCH LAST FROM c INTO x;
    while found LOOP
        RETURN NEXT x;
        FETCH prior FROM c INTO x;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c NO SCROLL CURSOR FOR
        SELECT
            f1
        FROM
            int4_tbl;
    x integer;
BEGIN
    OPEN c;
    FETCH LAST FROM c INTO x;
    while found LOOP
        RETURN NEXT x;
        FETCH prior FROM c INTO x;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

-- fails because of NO SCROLL specification
CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c refcursor;
    x integer;
BEGIN
    OPEN c SCROLL FOR
        SELECT
            f1
        FROM
            int4_tbl;
    FETCH LAST FROM c INTO x;
    while found LOOP
        RETURN NEXT x;
        FETCH prior FROM c INTO x;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c refcursor;
    x integer;
BEGIN
    OPEN c SCROLL FOR EXECUTE 'select f1 from int4_tbl';
    FETCH LAST FROM c INTO x;
    while found LOOP
        RETURN NEXT x;
        FETCH relative - 2 FROM c INTO x;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c refcursor;
    x integer;
BEGIN
    OPEN c SCROLL FOR EXECUTE 'select f1 from int4_tbl';
    FETCH LAST FROM c INTO x;
    while found LOOP
        RETURN NEXT x;
        MOVE BACKWARD 2
    FROM
        c;
        FETCH relative - 1 FROM c INTO x;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c CURSOR FOR
        SELECT
            *
        FROM
            generate_series(1, 10);
    x integer;
BEGIN
    OPEN c;
    LOOP
        MOVE relative 2 IN c;
        IF NOT found THEN
            exit;
        END IF;
        FETCH NEXT FROM c INTO x;
        IF found THEN
            RETURN NEXT x;
        END IF;
    END LOOP;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

CREATE OR REPLACE FUNCTION sc_test ()
    RETURNS SETOF integer
    AS $$
DECLARE
    c CURSOR FOR
        SELECT
            *
        FROM
            generate_series(1, 10);
    x integer;
BEGIN
    OPEN c;
    MOVE FORWARD ALL IN c;
    FETCH BACKWARD FROM c INTO x;
    IF found THEN
        RETURN NEXT x;
    END IF;
    CLOSE c;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    sc_test ();

DROP FUNCTION sc_test ();

-- test qualified variable names
CREATE FUNCTION pl_qual_names (param1 int)
    RETURNS void
    AS $$
    << outerblock >>
DECLARE
    param1 int := 1;
BEGIN
    << innerblock >> DECLARE param1 int := 2;
    BEGIN
        RAISE NOTICE 'param1 = %', param1;
        RAISE NOTICE 'pl_qual_names.param1 = %', pl_qual_names.param1;
        RAISE NOTICE 'outerblock.param1 = %', outerblock.param1;
        RAISE NOTICE 'innerblock.param1 = %', innerblock.param1;
    END;
END;
$$
LANGUAGE plpgsql;

SELECT
    pl_qual_names (42);

DROP FUNCTION pl_qual_names (int);

-- tests for RETURN QUERY
CREATE FUNCTION ret_query1 (out int, out int)
    RETURNS SETOF record
    AS $$
BEGIN
    $1 := - 1;
    $2 := - 2;
    RETURN NEXT;
    RETURN query
    SELECT
        x + 1,
        x * 10
    FROM
        generate_series(0, 10) s (x);
    RETURN NEXT;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    ret_query1 ();

CREATE TYPE record_type AS (
    x text,
    y int,
    z boolean
);

CREATE OR REPLACE FUNCTION ret_query2 (lim int)
    RETURNS SETOF record_type
    AS $$
BEGIN
    RETURN query
    SELECT
        md5(s.x::text),
        s.x,
        s.x > 0
    FROM
        generate_series(-8, lim) s (x)
WHERE
    s.x % 2 = 0;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    ret_query2 (8);

-- test EXECUTE USING
CREATE FUNCTION exc_using (int, text)
    RETURNS int
    AS $$
DECLARE
    i int;
BEGIN
    FOR i IN EXECUTE 'select * from generate_series(1,$1)'
    USING $1 + 1 LOOP
        RAISE NOTICE '%', i;
    END LOOP;
    EXECUTE 'select $2 + $2*3 + length($1)' INTO i
    USING $2, $1;
    RETURN i;
END
$$
LANGUAGE plpgsql;

SELECT
    exc_using (5, 'foobar');

DROP FUNCTION exc_using (int, text);

CREATE OR REPLACE FUNCTION exc_using (int)
    RETURNS void
    AS $$
DECLARE
    c refcursor;
    i int;
BEGIN
    OPEN c FOR EXECUTE 'select * from generate_series(1,$1)'
    USING $1 + 1;
    LOOP
        FETCH c INTO i;
        exit
        WHEN NOT found;
        RAISE NOTICE '%', i;
    END LOOP;
    CLOSE c;
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT
    exc_using (5);

DROP FUNCTION exc_using (int);

-- test FOR-over-cursor
CREATE OR REPLACE FUNCTION forc01 ()
    RETURNS void
    AS $$
DECLARE
    c CURSOR (r1 integer,
        r2 integer)
    FOR
        SELECT
            *
        FROM
            generate_series(r1, r2) i;
    c2 CURSOR FOR
        SELECT
            *
        FROM
            generate_series(41, 43) i;
BEGIN
    FOR r IN c (5,
        7)
        LOOP
            RAISE NOTICE '% from %', r.i, c;
        END LOOP;
    -- again, to test if cursor was closed properly
    FOR r IN c (9,
        10)
        LOOP
            RAISE NOTICE '% from %', r.i, c;
        END LOOP;
    -- and test a parameterless cursor
    FOR r IN c2 LOOP
        RAISE NOTICE '% from %', r.i, c2;
    END LOOP;
    -- and try it with a hand-assigned name
    RAISE NOTICE 'after loop, c2 = %', c2;
    c2 := 'special_name';
    FOR r IN c2 LOOP
        RAISE NOTICE '% from %', r.i, c2;
    END LOOP;
    RAISE NOTICE 'after loop, c2 = %', c2;
    -- and try it with a generated name
    -- (which we can't show in the output because it's variable)
    c2 := NULL;
    FOR r IN c2 LOOP
        RAISE NOTICE '%', r.i;
    END LOOP;
    RAISE NOTICE 'after loop, c2 = %', c2;
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT
    forc01 ();

-- try updating the cursor's current row
CREATE temp TABLE forc_test AS
SELECT
    n AS i,
    n AS j
FROM
    generate_series(1, 10) n;

CREATE OR REPLACE FUNCTION forc01 ()
    RETURNS void
    AS $$
DECLARE
    c CURSOR FOR
        SELECT
            *
        FROM
            forc_test;
BEGIN
    FOR r IN c LOOP
        RAISE NOTICE '%, %', r.i, r.j;
        UPDATE
            forc_test
        SET
            i = i * 100,
            j = r.j * 2
        WHERE
            CURRENT OF c;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT
    forc01 ();

SELECT
    *
FROM
    forc_test;

-- same, with a cursor whose portal name doesn't match variable name
CREATE OR REPLACE FUNCTION forc01 ()
    RETURNS void
    AS $$
DECLARE
    c refcursor := 'fooled_ya';
    r record;
BEGIN
    OPEN c FOR
        SELECT
            *
        FROM
            forc_test;
    LOOP
        FETCH c INTO r;
        exit
        WHEN NOT found;
        RAISE NOTICE '%, %', r.i, r.j;
        UPDATE
            forc_test
        SET
            i = i * 100,
            j = r.j * 2
        WHERE
            CURRENT OF c;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT
    forc01 ();

SELECT
    *
FROM
    forc_test;

DROP FUNCTION forc01 ();

-- fail because cursor has no query bound to it
CREATE OR REPLACE FUNCTION forc_bad ()
    RETURNS void
    AS $$
DECLARE
    c refcursor;
BEGIN
    FOR r IN c LOOP
        RAISE NOTICE '%', r.i;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- test RETURN QUERY EXECUTE
CREATE OR REPLACE FUNCTION return_dquery ()
    RETURNS SETOF int
    AS $$
BEGIN
    RETURN query EXECUTE 'select * from (values(10),(20)) f';
    RETURN query EXECUTE 'select * from (values($1),($2)) f'
    USING 40, 50;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    return_dquery ();

DROP FUNCTION return_dquery ();

-- test RETURN QUERY with dropped columns
CREATE TABLE tabwithcols (
    a int,
    b int,
    c int,
    d int
);

INSERT INTO tabwithcols
VALUES
    (10, 20, 30, 40),
    (50, 60, 70, 80);

CREATE OR REPLACE FUNCTION returnqueryf ()
    RETURNS SETOF tabwithcols
    AS $$
BEGIN
    RETURN query
    SELECT
        *
    FROM
        tabwithcols;
    RETURN query EXECUTE 'select * from tabwithcols';
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    returnqueryf ();

ALTER TABLE tabwithcols
    DROP COLUMN b;

SELECT
    *
FROM
    returnqueryf ();

ALTER TABLE tabwithcols
    DROP COLUMN d;

SELECT
    *
FROM
    returnqueryf ();

ALTER TABLE tabwithcols
    ADD COLUMN d int;

SELECT
    *
FROM
    returnqueryf ();

DROP FUNCTION returnqueryf ();

DROP TABLE tabwithcols;

--
-- Tests for composite-type results
--
CREATE TYPE compostype AS (
    x int,
    y varchar
);

-- test: use of variable of composite type in return statement
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
DECLARE
    v compostype;
BEGIN
    v := (1,
        'hello');
    RETURN v;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- test: use of variable of record type in return statement
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
DECLARE
    v record;
BEGIN
    v := (1,
        'hello'::varchar);
    RETURN v;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- test: use of row expr in return statement
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
BEGIN
    RETURN (1,
        'hello'::varchar);
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- this does not work currently (no implicit casting)
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
BEGIN
    RETURN (1,
        'hello');
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- ... but this does
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
BEGIN
    RETURN (1,
        'hello')::compostype;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

DROP FUNCTION compos ();

-- test: return a row expr as record.
CREATE OR REPLACE FUNCTION composrec ()
    RETURNS record
    AS $$
DECLARE
    v record;
BEGIN
    v := (1,
        'hello');
    RETURN v;
END;
$$
LANGUAGE plpgsql;

SELECT
    composrec ();

-- test: return row expr in return statement.
CREATE OR REPLACE FUNCTION composrec ()
    RETURNS record
    AS $$
BEGIN
    RETURN (1,
        'hello');
END;
$$
LANGUAGE plpgsql;

SELECT
    composrec ();

DROP FUNCTION composrec ();

-- test: row expr in RETURN NEXT statement.
CREATE OR REPLACE FUNCTION compos ()
    RETURNS SETOF compostype
    AS $$
BEGIN
    FOR i IN 1..3 LOOP
        RETURN NEXT (1,
            'hello'::varchar);
    END LOOP;
    RETURN NEXT NULL::compostype;
    RETURN NEXT (2,
        'goodbye')::compostype;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    compos ();

DROP FUNCTION compos ();

-- test: use invalid expr in return statement.
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
BEGIN
    RETURN 1 + 1;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- RETURN variable is a different code path ...
CREATE OR REPLACE FUNCTION compos ()
    RETURNS compostype
    AS $$
DECLARE
    x int := 42;
BEGIN
    RETURN x;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    compos ();

DROP FUNCTION compos ();

-- test: invalid use of composite variable in scalar-returning function
CREATE OR REPLACE FUNCTION compos ()
    RETURNS int
    AS $$
DECLARE
    v compostype;
BEGIN
    v := (1,
        'hello');
    RETURN v;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

-- test: invalid use of composite expression in scalar-returning function
CREATE OR REPLACE FUNCTION compos ()
    RETURNS int
    AS $$
BEGIN
    RETURN (1,
        'hello')::compostype;
END;
$$
LANGUAGE plpgsql;

SELECT
    compos ();

DROP FUNCTION compos ();

DROP TYPE compostype;

--
-- Tests for 8.4's new RAISE features
--
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE NOTICE '% % %', 1, 2, 3
    USING errcode = '55001', detail = 'some detail info', hint = 'some hint';
    RAISE '% % %', 1, 2, 3
    USING errcode = 'division_by_zero', detail = 'some detail info';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- Since we can't actually see the thrown SQLSTATE in default psql output,
-- test it like this; this also tests re-RAISE
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE 'check me'
    USING errcode = 'division_by_zero', detail = 'some detail info';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'SQLSTATE: % SQLERRM: %', sqlstate, sqlerrm;
        RAISE;
END;

$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE 'check me'
    USING errcode = '1234F', detail = 'some detail info';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'SQLSTATE: % SQLERRM: %', sqlstate, sqlerrm;
        RAISE;
END;

$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- SQLSTATE specification in WHEN
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE 'check me'
    USING errcode = '1234F', detail = 'some detail info';
EXCEPTION
    WHEN sqlstate '1234F' THEN
        RAISE NOTICE 'SQLSTATE: % SQLERRM: %', sqlstate, sqlerrm;
        RAISE;
END;

$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE division_by_zero
    USING detail = 'some detail info';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'SQLSTATE: % SQLERRM: %', sqlstate, sqlerrm;
        RAISE;
END;

$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE division_by_zero;
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE sqlstate '1234F';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE division_by_zero
    USING message = 'custom' || ' message';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE
    USING message = 'custom' || ' message', errcode = '22012';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- conflict on message
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE NOTICE 'some message'
    USING message = 'custom' || ' message', errcode = '22012';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- conflict on errcode
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE division_by_zero
    USING message = 'custom' || ' message', errcode = '22012';
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- nothing to re-RAISE
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE;
END;
$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

-- test access to exception data
CREATE FUNCTION zero_divide ()
    RETURNS int
    AS $$
DECLARE
    v int := 0;
BEGIN
    RETURN 10 / v;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    RAISE EXCEPTION 'custom exception'
        USING detail = 'some detail of custom exception', hint = 'some hint related to custom exception';
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION stacked_diagnostics_test ()
    RETURNS void
    AS $$
DECLARE
    _sqlstate text;
    _message text;
    _context text;
BEGIN
    PERFORM
        zero_divide ();
EXCEPTION
    WHEN OTHERS THEN
        get stacked diagnostics _sqlstate = returned_sqlstate,
        _message = message_text,
        _context = pg_exception_context;
        RAISE NOTICE 'sqlstate: %, message: %, context: [%]', _sqlstate, _message, replace(_context, E'\n', ' <- ');
END;

$$
LANGUAGE plpgsql;

SELECT
    stacked_diagnostics_test ();

CREATE OR REPLACE FUNCTION stacked_diagnostics_test ()
    RETURNS void
    AS $$
DECLARE
    _detail text;
    _hint text;
    _message text;
BEGIN
    PERFORM
        raise_test ();
EXCEPTION
    WHEN OTHERS THEN
        get stacked diagnostics _message = message_text,
        _detail = pg_exception_detail,
        _hint = pg_exception_hint;
        RAISE NOTICE 'message: %, detail: %, hint: %', _message, _detail, _hint;
END;

$$
LANGUAGE plpgsql;

SELECT
    stacked_diagnostics_test ();

-- fail, cannot use stacked diagnostics statement outside handler
CREATE OR REPLACE FUNCTION stacked_diagnostics_test ()
    RETURNS void
    AS $$
DECLARE
    _detail text;
    _hint text;
    _message text;
BEGIN
    get stacked diagnostics _message = message_text,
    _detail = pg_exception_detail,
    _hint = pg_exception_hint;
    RAISE NOTICE 'message: %, detail: %, hint: %', _message, _detail, _hint;
END;
$$
LANGUAGE plpgsql;

SELECT
    stacked_diagnostics_test ();

DROP FUNCTION zero_divide ();

DROP FUNCTION stacked_diagnostics_test ();

-- check cases where implicit SQLSTATE variable could be confused with
-- SQLSTATE as a keyword, cf bug #5524
CREATE OR REPLACE FUNCTION raise_test ()
    RETURNS void
    AS $$
BEGIN
    PERFORM
        1 / 0;
EXCEPTION
    WHEN sqlstate '22012' THEN
        RAISE NOTICE USING message = sqlstate;
        RAISE sqlstate '22012' USING message = 'substitute message';
END;

$$
LANGUAGE plpgsql;

SELECT
    raise_test ();

DROP FUNCTION raise_test ();

-- test passing column_name, constraint_name, datatype_name, table_name
-- and schema_name error fields
CREATE OR REPLACE FUNCTION stacked_diagnostics_test ()
    RETURNS void
    AS $$
DECLARE
    _column_name text;
    _constraint_name text;
    _datatype_name text;
    _table_name text;
    _schema_name text;
BEGIN
    RAISE EXCEPTION
        USING COLUMN = '>>some column name<<', CONSTRAINT = '>>some constraint name<<', datatype = '>>some datatype name<<', TABLE = '>>some table name<<', schema = '>>some schema name<<';
EXCEPTION
    WHEN OTHERS THEN
        get stacked diagnostics _column_name = column_name,
        _constraint_name = constraint_name,
        _datatype_name = pg_datatype_name,
        _table_name = table_name,
        _schema_name = schema_name;
        RAISE NOTICE 'column %, constraint %, type %, table %, schema %', _column_name, _constraint_name, _datatype_name, _table_name, _schema_name;
END;

$$
LANGUAGE plpgsql;

SELECT
    stacked_diagnostics_test ();

DROP FUNCTION stacked_diagnostics_test ();

-- test variadic functions
CREATE OR REPLACE FUNCTION vari (VARIADIC int[])
    RETURNS void
    AS $$
BEGIN
    FOR i IN array_lower($1, 1)..array_upper($1, 1)
    LOOP
        RAISE NOTICE '%', $1[i];
    END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT
    vari (1, 2, 3, 4, 5);

SELECT
    vari (3, 4, 5);

SELECT
    vari (VARIADIC ARRAY[5, 6, 7]);

DROP FUNCTION vari (int[]);

-- coercion test
CREATE OR REPLACE FUNCTION pleast (VARIADIC numeric[])
    RETURNS numeric
    AS $$
DECLARE
    aux numeric = $1[array_lower($1, 1)];
BEGIN
    FOR i IN array_lower($1, 1) + 1..array_upper($1, 1)
    LOOP
        IF $1[i] < aux THEN
            aux := $1[i];
        END IF;
    END LOOP;
    RETURN aux;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

SELECT
    pleast (10, 1, 2, 3, -16);

SELECT
    pleast (10.2, 2.2, -1.1);

SELECT
    pleast (10.2, 10, -20);

SELECT
    pleast (10, 20, -1.0);

-- in case of conflict, non-variadic version is preferred
CREATE OR REPLACE FUNCTION pleast (numeric)
    RETURNS numeric
    AS $$
BEGIN
    RAISE NOTICE 'non-variadic function called';
    RETURN $1;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

SELECT
    pleast (10);

DROP FUNCTION pleast (numeric[]);

DROP FUNCTION pleast (numeric);

-- test table functions
CREATE FUNCTION tftest (int)
    RETURNS TABLE (
        a int,
        b int
    )
    AS $$
BEGIN
    RETURN query
    SELECT
        $1,
        $1 + i
    FROM
        generate_series(1, 5) g (i);
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

SELECT
    *
FROM
    tftest (10);

CREATE OR REPLACE FUNCTION tftest (a1 int)
    RETURNS TABLE (
        a int,
        b int
    )
    AS $$
BEGIN
    a := a1;
    b := a1 + 1;
    RETURN NEXT;
    a := a1 * 10;
    b := a1 * 10 + 1;
    RETURN NEXT;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

SELECT
    *
FROM
    tftest (10);

DROP FUNCTION tftest (int);

CREATE OR REPLACE FUNCTION rttest ()
    RETURNS SETOF int
    AS $$
DECLARE
    rc int;
    rca int[];
BEGIN
    RETURN query
VALUES (10),
(20);
    get diagnostics rc = row_count;
    RAISE NOTICE '% %', found, rc;
    RETURN query
    SELECT
        *
    FROM (
        VALUES (10),
            (20)) f (a)
WHERE
    FALSE;
    get diagnostics rc = row_count;
    RAISE NOTICE '% %', found, rc;
    RETURN query EXECUTE 'values(10),(20)';
    -- just for fun, let's use array elements as targets
    get diagnostics rca[1] = row_count;
    RAISE NOTICE '% %', found, rca[1];
    RETURN query EXECUTE 'select * from (values(10),(20)) f(a) where false';
    get diagnostics rca[2] = row_count;
    RAISE NOTICE '% %', found, rca[2];
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    rttest ();

DROP FUNCTION rttest ();

-- Test for proper cleanup at subtransaction exit.  This example
-- exposed a bug in PG 8.2.
CREATE FUNCTION leaker_1 (fail bool)
    RETURNS integer
    AS $$
DECLARE
    v_var integer;
BEGIN
    BEGIN
        v_var := (leaker_2 (fail)).error_code;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;
    RETURN 1;
END;

$$
LANGUAGE plpgsql;

CREATE FUNCTION leaker_2 (fail bool, OUT error_code integer, OUT new_id integer)
    RETURNS RECORD
    AS $$
BEGIN
    IF fail THEN
        RAISE EXCEPTION 'fail ...';
    END IF;
    error_code := 1;
    new_id := 1;
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    leaker_1 (FALSE);

SELECT
    *
FROM
    leaker_1 (TRUE);

DROP FUNCTION leaker_1 (bool);

DROP FUNCTION leaker_2 (bool);

-- Test for appropriate cleanup of non-simple expression evaluations
-- (bug in all versions prior to August 2010)
CREATE FUNCTION nonsimple_expr_test ()
    RETURNS text[]
    AS $$
DECLARE
    arr text[];
    lr text;
    i integer;
BEGIN
    arr := ARRAY[ARRAY['foo', 'bar'], ARRAY['baz', 'quux']];
    lr := 'fool';
    i := 1;
    -- use sub-SELECTs to make expressions non-simple
    arr[(
        SELECT
            i)][(
        SELECT
            i + 1)] := (
        SELECT
            lr);
    RETURN arr;
END;
$$
LANGUAGE plpgsql;

SELECT
    nonsimple_expr_test ();

DROP FUNCTION nonsimple_expr_test ();

CREATE FUNCTION nonsimple_expr_test ()
    RETURNS integer
    AS $$
DECLARE
    i integer NOT NULL := 0;
BEGIN
    BEGIN
        i := (
            SELECT
                NULL::integer);
        -- should throw error
    EXCEPTION
        WHEN OTHERS THEN
            i := (
                SELECT
                    1::integer);
    END;
    RETURN i;
END;

$$
LANGUAGE plpgsql;

SELECT
    nonsimple_expr_test ();

DROP FUNCTION nonsimple_expr_test ();

--
-- Test cases involving recursion and error recovery in simple expressions
-- (bugs in all versions before October 2010).  The problems are most
-- easily exposed by mutual recursion between plpgsql and sql functions.
--
CREATE FUNCTION recurse (float8)
    RETURNS float8
    AS $$
BEGIN
    IF ($1 > 0) THEN
        RETURN sql_recurse ($1 - 1);
    ELSE
        RETURN $1;
    END IF;
END;
$$
LANGUAGE plpgsql;

-- "limit" is to prevent this from being inlined
CREATE FUNCTION sql_recurse (float8)
    RETURNS float8
    AS $$
    SELECT
        recurse ($1)
    LIMIT 1;
$$
LANGUAGE sql;

SELECT
    recurse (10);

CREATE FUNCTION error1 (text)
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        relname::text
    FROM
        pg_class c
    WHERE
        c.oid = $1::regclass
$$;

CREATE FUNCTION error2 (p_name_table text)
    RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN error1 (p_name_table);
END
$$;

BEGIN;
CREATE TABLE public.stuffs (
    stuff text
);
SAVEPOINT a;
SELECT
    error2 ('nonexistent.stuffs');
ROLLBACK TO a;

SELECT
    error2 ('public.stuffs');

ROLLBACK;

DROP FUNCTION error2 (p_name_table text);

DROP FUNCTION error1 (text);

-- Test for proper handling of cast-expression caching
CREATE FUNCTION sql_to_date (integer)
    RETURNS date
    AS $$
    SELECT
        $1::text::date
$$
LANGUAGE sql
IMMUTABLE STRICT;

CREATE CAST (integer AS date) WITH FUNCTION sql_to_date (integer) AS assignment;

CREATE FUNCTION cast_invoker (integer)
    RETURNS date
    AS $$
BEGIN
    RETURN $1;
END
$$
LANGUAGE plpgsql;

SELECT
    cast_invoker (20150717);

SELECT
    cast_invoker (20150718);

-- second call crashed in pre-release 9.5
BEGIN;
SELECT
    cast_invoker (20150717);
SELECT
    cast_invoker (20150718);
SAVEPOINT s1;
SELECT
    cast_invoker (20150718);
SELECT
    cast_invoker (-1);
-- fails
ROLLBACK TO SAVEPOINT s1;

SELECT
    cast_invoker (20150719);

SELECT
    cast_invoker (20150720);

COMMIT;

DROP FUNCTION cast_invoker (integer);

DROP FUNCTION sql_to_date (integer) CASCADE;

-- Test handling of cast cache inside DO blocks
-- (to check the original crash case, this must be a cast not previously
-- used in this session)
BEGIN;
DO $$
DECLARE
    x text[];
BEGIN
    x := '{1.23, 4.56}'::numeric[];
END
$$;
DO $$
DECLARE
    x text[];
BEGIN
    x := '{1.23, 4.56}'::numeric[];
END
$$;
END;
-- Test for consistent reporting of error context
CREATE FUNCTION fail ()
    RETURNS int
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 1 / 0;
END
$$;
SELECT
    fail ();
SELECT
    fail ();
DROP FUNCTION fail ();
-- Test handling of string literals.
SET standard_conforming_strings = OFF;
CREATE OR REPLACE FUNCTION strtest ()
    RETURNS text
    AS $$
BEGIN
    RAISE NOTICE 'foo\\bar\041baz';
    RETURN 'foo\\bar\041baz';
END
$$
LANGUAGE plpgsql;
SELECT
    strtest ();
CREATE OR REPLACE FUNCTION strtest ()
    RETURNS text
    AS $$
BEGIN
    RAISE NOTICE E'foo\\bar\041baz';
    RETURN E'foo\\bar\041baz';
END
$$
LANGUAGE plpgsql;
SELECT
    strtest ();
SET standard_conforming_strings = ON;
CREATE OR REPLACE FUNCTION strtest ()
    RETURNS text
    AS $$
BEGIN
    RAISE NOTICE 'foo\\bar\041baz\';
  return ' foo\\bar 041baz\';
END
$$
LANGUAGE plpgsql;
SELECT
    strtest ();
CREATE OR REPLACE FUNCTION strtest ()
    RETURNS text
    AS $$
BEGIN
    RAISE NOTICE E'foo\\bar\041baz';
    RETURN E'foo\\bar\041baz';
END
$$
LANGUAGE plpgsql;
SELECT
    strtest ();
DROP FUNCTION strtest ();
-- Test anonymous code blocks.
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
    SELECT
        rtrim(roomno) AS roomno,
        comment
    FROM
        Room
    ORDER BY
        roomno LOOP
            RAISE NOTICE '%, %', r.roomno, r.comment;
        END LOOP;
END
$$;
-- these are to check syntax error reporting
DO
LANGUAGE plpgsql
$$
BEGIN
    RETURN 1;
END $$;
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
    SELECT
        rtrim(roomno) AS roomno,
        foo
    FROM
        Room
    ORDER BY
        roomno LOOP
            RAISE NOTICE '%, %', r.roomno, r.comment;
        END LOOP;
END
$$;
-- Check handling of errors thrown from/into anonymous code blocks.
DO $outer$
BEGIN
    FOR i IN 1..10 LOOP
        BEGIN
            EXECUTE $ex$
      do $$
      declare x int = 0;
      begin
        x := 1 / x;
      end;
      $$;
    $ex$;
        EXCEPTION
            WHEN division_by_zero THEN
                RAISE NOTICE 'caught division by zero';
        END;
    END LOOP;
END;
$outer$;
-- Check variable scoping -- a var is not available in its own or prior
-- default expressions.
CREATE FUNCTION scope_test ()
    RETURNS int
    AS $$
DECLARE
    x int := 42;
BEGIN
    DECLARE y int := x + 1;
    x int := x + 2;
    BEGIN
        RETURN x * 100 + y;
    END;
END;
$$
LANGUAGE plpgsql;
SELECT
    scope_test ();
DROP FUNCTION scope_test ();
-- Check handling of conflicts between plpgsql vars and table columns.
SET plpgsql.variable_conflict = error;
CREATE FUNCTION conflict_test ()
    RETURNS SETOF int8_tbl
    AS $$
DECLARE
    r record;
    q1 bigint := 42;
BEGIN
    FOR r IN
    SELECT
        q1,
        q2
    FROM
        int8_tbl LOOP
            RETURN NEXT r;
        END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    *
FROM
    conflict_test ();
CREATE OR REPLACE FUNCTION conflict_test ()
    RETURNS SETOF int8_tbl
    AS $$
    # variable_conflict use_variable
DECLARE
    r record;
    q1 bigint := 42;
BEGIN
    FOR r IN
    SELECT
        q1,
        q2
    FROM
        int8_tbl LOOP
            RETURN NEXT r;
        END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    *
FROM
    conflict_test ();
CREATE OR REPLACE FUNCTION conflict_test ()
    RETURNS SETOF int8_tbl
    AS $$
    # variable_conflict use_column
DECLARE
    r record;
    q1 bigint := 42;
BEGIN
    FOR r IN
    SELECT
        q1,
        q2
    FROM
        int8_tbl LOOP
            RETURN NEXT r;
        END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    *
FROM
    conflict_test ();
DROP FUNCTION conflict_test ();
-- Check that an unreserved keyword can be used as a variable name
CREATE FUNCTION unreserved_test ()
    RETURNS int
    AS $$
DECLARE
    FORWARD int := 21;
BEGIN
    FORWARD := FORWARD * 2;
    RETURN FORWARD;
END
$$
LANGUAGE plpgsql;
SELECT
    unreserved_test ();
CREATE OR REPLACE FUNCTION unreserved_test ()
    RETURNS int
    AS $$
DECLARE
    RETURN int := 42;
BEGIN
    RETURN := RETURN +1;
    RETURN RETURN;
END
$$
LANGUAGE plpgsql;
SELECT
    unreserved_test ();
CREATE OR REPLACE FUNCTION unreserved_test ()
    RETURNS int
    AS $$
DECLARE
    comment int := 21;
BEGIN
    comment := comment * 2;
    COMMENT ON FUNCTION unreserved_test () IS 'this is a test';
    RETURN comment;
END
$$
LANGUAGE plpgsql;
SELECT
    unreserved_test ();
SELECT
    obj_description('unreserved_test()'::regprocedure, 'pg_proc');
DROP FUNCTION unreserved_test ();
--
-- Test FOREACH over arrays
--
CREATE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x int;
BEGIN
    foreach x IN ARRAY $1 LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    foreach_test (ARRAY[1, 2, 3, 4]);
SELECT
    foreach_test (ARRAY[[1, 2],[3, 4]]);
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x int;
BEGIN
    foreach x slice 1 IN ARRAY $1 LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
-- should fail
SELECT
    foreach_test (ARRAY[1, 2, 3, 4]);
SELECT
    foreach_test (ARRAY[[1, 2],[3, 4]]);
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x int[];
BEGIN
    foreach x slice 1 IN ARRAY $1 LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    foreach_test (ARRAY[1, 2, 3, 4]);
SELECT
    foreach_test (ARRAY[[1, 2],[3, 4]]);
-- higher level of slicing
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x int[];
BEGIN
    foreach x slice 2 IN ARRAY $1 LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
-- should fail
SELECT
    foreach_test (ARRAY[1, 2, 3, 4]);
-- ok
SELECT
    foreach_test (ARRAY[[1, 2],[3, 4]]);
SELECT
    foreach_test (ARRAY[[[1, 2]],[[3, 4]]]);
CREATE TYPE xy_tuple AS (
    x int,
    y int
);
-- iteration over array of records
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    r record;
BEGIN
    foreach r IN ARRAY $1 LOOP
        RAISE NOTICE '%', r;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    foreach_test (ARRAY[(10, 20), (40, 69), (35, 78)]::xy_tuple[]);
SELECT
    foreach_test (ARRAY[[(10, 20), (40, 69)],[(35, 78), (88, 76)]]::xy_tuple[]);
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x int;
    y int;
BEGIN
    foreach x,
    y IN ARRAY $1 LOOP
        RAISE NOTICE 'x = %, y = %', x, y;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    foreach_test (ARRAY[(10, 20), (40, 69), (35, 78)]::xy_tuple[]);
SELECT
    foreach_test (ARRAY[[(10, 20), (40, 69)],[(35, 78), (88, 76)]]::xy_tuple[]);
-- slicing over array of composite types
CREATE OR REPLACE FUNCTION foreach_test (anyarray)
    RETURNS void
    AS $$
DECLARE
    x xy_tuple[];
BEGIN
    foreach x slice 1 IN ARRAY $1 LOOP
        RAISE NOTICE '%', x;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
SELECT
    foreach_test (ARRAY[(10, 20), (40, 69), (35, 78)]::xy_tuple[]);
SELECT
    foreach_test (ARRAY[[(10, 20), (40, 69)],[(35, 78), (88, 76)]]::xy_tuple[]);
DROP FUNCTION foreach_test (anyarray);
DROP TYPE xy_tuple;
--
-- Assorted tests for array subscript assignment
--
CREATE temp TABLE rtype (
    id int,
    ar text[]
);
CREATE FUNCTION arrayassign1 ()
    RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    r record;
BEGIN
    r := ROW (12,
        '{foo,bar,baz}')::rtype;
    r.ar[2] := 'replace';
    RETURN r.ar;
END
$$;
SELECT
    arrayassign1 ();
SELECT
    arrayassign1 ();
-- try again to exercise internal caching
CREATE DOMAIN orderedarray AS int[2] CONSTRAINT sorted CHECK (value[1] < value[2]);
SELECT
    '{1,2}'::orderedarray;
SELECT
    '{2,1}'::orderedarray;
-- fail
CREATE FUNCTION testoa (x1 int, x2 int, x3 int)
    RETURNS orderedarray
    LANGUAGE plpgsql
    AS $$
DECLARE
    res orderedarray;
BEGIN
    res := ARRAY[x1, x2];
    res[2] := x3;
    RETURN res;
END
$$;
SELECT
    testoa (1, 2, 3);
SELECT
    testoa (1, 2, 3);
-- try again to exercise internal caching
SELECT
    testoa (2, 1, 3);
-- fail at initial assign
SELECT
    testoa (1, 2, 1);
-- fail at update
DROP FUNCTION arrayassign1 ();
DROP FUNCTION testoa (x1 int, x2 int, x3 int);
--
-- Test handling of expanded arrays
--
CREATE FUNCTION returns_rw_array (int)
    RETURNS int[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    r int[];
BEGIN
    r := ARRAY[$1, $1];
    RETURN r;
END;
$$ STABLE;
CREATE FUNCTION consumes_rw_array (int[])
    RETURNS int
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN $1[1];
END;
$$ STABLE;
SELECT
    consumes_rw_array (returns_rw_array (42));
-- bug #14174
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    i,
    a
FROM (
    SELECT
        returns_rw_array (1) AS a OFFSET 0) ss,
    LATERAL consumes_rw_array (a) i;
SELECT
    i,
    a
FROM (
    SELECT
        returns_rw_array (1) AS a OFFSET 0) ss,
    LATERAL consumes_rw_array (a) i;
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    consumes_rw_array (a),
    a
FROM
    returns_rw_array (1) a;
SELECT
    consumes_rw_array (a),
    a
FROM
    returns_rw_array (1) a;
EXPLAIN (
    VERBOSE,
    COSTS OFF
)
SELECT
    consumes_rw_array (a),
    a
FROM (
    VALUES (returns_rw_array (1)),
        (returns_rw_array (2))) v (a);
SELECT
    consumes_rw_array (a),
    a
FROM (
    VALUES (returns_rw_array (1)),
        (returns_rw_array (2))) v (a);
DO $$
DECLARE
    a int[] := ARRAY[1, 2];
BEGIN
    a := a || 3;
    RAISE NOTICE 'a = %', a;
END
$$;
--
-- Test access to call stack
--
CREATE FUNCTION inner_func (int)
    RETURNS int
    AS $$
DECLARE
    _context text;
BEGIN
    get diagnostics _context = pg_context;
    RAISE NOTICE '***%***', _context;
    -- lets do it again, just for fun..
    get diagnostics _context = pg_context;
    RAISE NOTICE '***%***', _context;
    RAISE NOTICE 'lets make sure we didnt break anything';
    RETURN 2 * $1;
    END;
$$
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION outer_func (int)
    RETURNS int
    AS $$
DECLARE
    myresult int;
BEGIN
    RAISE NOTICE 'calling down into inner_func()';
    myresult := inner_func ($1);
    RAISE NOTICE 'inner_func() done';
    RETURN myresult;
END;
$$
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION outer_outer_func (int)
    RETURNS int
    AS $$
DECLARE
    myresult int;
BEGIN
    RAISE NOTICE 'calling down into outer_func()';
    myresult := outer_func ($1);
    RAISE NOTICE 'outer_func() done';
    RETURN myresult;
END;
$$
LANGUAGE plpgsql;
SELECT
    outer_outer_func (10);
-- repeated call should to work
SELECT
    outer_outer_func (20);
DROP FUNCTION outer_outer_func (int);
DROP FUNCTION outer_func (int);
DROP FUNCTION inner_func (int);
-- access to call stack from exception
CREATE FUNCTION inner_func (int)
    RETURNS int
    AS $$
DECLARE
    _context text;
    sx int := 5;
BEGIN
    BEGIN
        PERFORM
            sx / 0;
    EXCEPTION
        WHEN division_by_zero THEN
            get diagnostics _context = pg_context;
            RAISE NOTICE '***%***', _context;
    END;
    -- lets do it again, just for fun..
    get diagnostics _context = pg_context;
    RAISE NOTICE '***%***', _context;
    RAISE NOTICE 'lets make sure we didnt break anything';
    RETURN 2 * $1;
END;
$$
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION outer_func (int)
    RETURNS int
    AS $$
DECLARE
    myresult int;
BEGIN
    RAISE NOTICE 'calling down into inner_func()';
    myresult := inner_func ($1);
    RAISE NOTICE 'inner_func() done';
    RETURN myresult;
END;
$$
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION outer_outer_func (int)
    RETURNS int
    AS $$
DECLARE
    myresult int;
BEGIN
    RAISE NOTICE 'calling down into outer_func()';
    myresult := outer_func ($1);
    RAISE NOTICE 'outer_func() done';
    RETURN myresult;
END;
$$
LANGUAGE plpgsql;
SELECT
    outer_outer_func (10);
-- repeated call should to work
SELECT
    outer_outer_func (20);
DROP FUNCTION outer_outer_func (int);
DROP FUNCTION outer_func (int);
DROP FUNCTION inner_func (int);
--
-- Test ASSERT
--
DO $$
BEGIN
    assert 1 = 1;
    -- should succeed
END;
$$;
DO $$
BEGIN
    assert 1 = 0;
    -- should fail
END;
$$;
DO $$
BEGIN
    assert NULL;
    -- should fail
END;
$$;
-- check controlling GUC
SET plpgsql.check_asserts = OFF;
DO $$
BEGIN
    assert 1 = 0;
    -- won't be tested
END;
$$;
RESET plpgsql.check_asserts;
-- test custom message
DO $$
DECLARE
    var text := 'some value';
BEGIN
    assert 1 = 0,
    format('assertion failed, var = "%s"', var);
END;
$$;
-- ensure assertions are not trapped by 'others'
DO $$
BEGIN
    assert 1 = 0,
    'unhandled assertion';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
        -- do nothing
END;
$$;
-- Test use of plpgsql in a domain check constraint (cf. bug #14414)
CREATE FUNCTION plpgsql_domain_check (val int)
    RETURNS boolean
    AS $$
BEGIN
    RETURN val > 0;
END
$$
LANGUAGE plpgsql
IMMUTABLE;
CREATE DOMAIN plpgsql_domain AS integer CHECK (plpgsql_domain_check (value));
DO $$
DECLARE
    v_test plpgsql_domain;
BEGIN
    v_test := 1;
END;
$$;
DO $$
DECLARE
    v_test plpgsql_domain := 1;
BEGIN
    v_test := 0;
    -- fail
END;
$$;
-- Test handling of expanded array passed to a domain constraint (bug #14472)
CREATE FUNCTION plpgsql_arr_domain_check (val int[])
    RETURNS boolean
    AS $$
BEGIN
    RETURN val[1] > 0;
END
$$
LANGUAGE plpgsql
IMMUTABLE;
CREATE DOMAIN plpgsql_arr_domain AS int[] CHECK (plpgsql_arr_domain_check (value));
DO $$
DECLARE
    v_test plpgsql_arr_domain;
BEGIN
    v_test := ARRAY[1];
    v_test := v_test || 2;
END;
$$;
DO $$
DECLARE
    v_test plpgsql_arr_domain := ARRAY[1];
BEGIN
    v_test := 0 || v_test;
    -- fail
END;
$$;
--
-- test usage of transition tables in AFTER triggers
--
CREATE TABLE transition_table_base (
    id int PRIMARY KEY,
    val text
);
CREATE FUNCTION transition_table_base_ins_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    t text;
    l text;
BEGIN
    t = '';
    FOR l IN EXECUTE $q$
             EXPLAIN (TIMING off, COSTS off, VERBOSE on)
             SELECT * FROM newtable
           $q$ LOOP
        t = t || l || E'\n';
    END LOOP;
    RAISE INFO '%', t;
    RETURN new;
END;
$$;
CREATE TRIGGER transition_table_base_ins_trig
    AFTER INSERT ON transition_table_base REFERENCING OLD TABLE AS oldtable NEW TABLE AS newtable
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_base_ins_func ();
CREATE TRIGGER transition_table_base_ins_trig
    AFTER INSERT ON transition_table_base REFERENCING NEW TABLE AS newtable
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_base_ins_func ();
INSERT INTO transition_table_base
VALUES
    (1, 'One'),
    (2, 'Two');
INSERT INTO transition_table_base
VALUES
    (3, 'Three'),
    (4, 'Four');
CREATE OR REPLACE FUNCTION transition_table_base_upd_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    t text;
    l text;
BEGIN
    t = '';
    FOR l IN EXECUTE $q$
             EXPLAIN (TIMING off, COSTS off, VERBOSE on)
             SELECT * FROM oldtable ot FULL JOIN newtable nt USING (id)
           $q$ LOOP
        t = t || l || E'\n';
    END LOOP;
    RAISE INFO '%', t;
    RETURN new;
END;
$$;
CREATE TRIGGER transition_table_base_upd_trig
    AFTER UPDATE ON transition_table_base REFERENCING OLD TABLE AS oldtable NEW TABLE AS newtable
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_base_upd_func ();
UPDATE
    transition_table_base
SET
    val = '*' || val || '*'
WHERE
    id BETWEEN 2 AND 3;
CREATE TABLE transition_table_level1 (
    level1_no serial NOT NULL,
    level1_node_name varchar(255),
    PRIMARY KEY (level1_no)) WITHOUT OIDS;
CREATE TABLE transition_table_level2 (
    level2_no serial NOT NULL,
    parent_no int NOT NULL,
    level1_node_name varchar(255),
    PRIMARY KEY (level2_no)) WITHOUT OIDS;
CREATE TABLE transition_table_status (
    level int NOT NULL,
    node_no int NOT NULL,
    status int,
    PRIMARY KEY (level, node_no)) WITHOUT OIDS;
CREATE FUNCTION transition_table_level1_ri_parent_del_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    n bigint;
BEGIN
    PERFORM
    FROM
        p
        JOIN transition_table_level2 c ON c.parent_no = p.level1_no;
    IF FOUND THEN
        RAISE EXCEPTION 'RI error';
    END IF;
    RETURN NULL;
END;
$$;
CREATE TRIGGER transition_table_level1_ri_parent_del_trigger
    AFTER DELETE ON transition_table_level1 REFERENCING OLD TABLE AS p
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_level1_ri_parent_del_func ();
CREATE FUNCTION transition_table_level1_ri_parent_upd_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    x int;
BEGIN
    WITH p AS (
        SELECT
            level1_no,
            sum(delta) cnt
        FROM (
            SELECT
                level1_no,
                1 AS delta
            FROM
                i
            UNION ALL
            SELECT
                level1_no,
                -1 AS delta
            FROM
                d) w
        GROUP BY
            level1_no
        HAVING
            sum(delta) < 0
)
SELECT
    level1_no
FROM
    p
    JOIN transition_table_level2 c ON c.parent_no = p.level1_no INTO x;
    IF FOUND THEN
        RAISE EXCEPTION 'RI error';
    END IF;
    RETURN NULL;
END;
$$;
CREATE TRIGGER transition_table_level1_ri_parent_upd_trigger
    AFTER UPDATE ON transition_table_level1 REFERENCING OLD TABLE AS d NEW TABLE AS i
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_level1_ri_parent_upd_func ();
CREATE FUNCTION transition_table_level2_ri_child_insupd_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM
    FROM
        i
        LEFT JOIN transition_table_level1 p ON p.level1_no IS NOT NULL
            AND p.level1_no = i.parent_no
    WHERE
        p.level1_no IS NULL;
    IF FOUND THEN
        RAISE EXCEPTION 'RI error';
    END IF;
    RETURN NULL;
END;
$$;
CREATE TRIGGER transition_table_level2_ri_child_ins_trigger
    AFTER INSERT ON transition_table_level2 REFERENCING NEW TABLE AS i
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_level2_ri_child_insupd_func ();
CREATE TRIGGER transition_table_level2_ri_child_upd_trigger
    AFTER UPDATE ON transition_table_level2 REFERENCING NEW TABLE AS i
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_level2_ri_child_insupd_func ();
-- create initial test data
INSERT INTO transition_table_level1 (level1_no)
SELECT
    generate_series(1, 200);
ANALYZE transition_table_level1;
INSERT INTO transition_table_level2 (level2_no, parent_no)
SELECT
    level2_no,
    level2_no / 50 + 1 AS parent_no
FROM
    generate_series(1, 9999) level2_no;
ANALYZE transition_table_level2;
INSERT INTO transition_table_status (level, node_no, status)
SELECT
    1,
    level1_no,
    0
FROM
    transition_table_level1;
INSERT INTO transition_table_status (level, node_no, status)
SELECT
    2,
    level2_no,
    0
FROM
    transition_table_level2;
ANALYZE transition_table_status;
INSERT INTO transition_table_level1 (level1_no)
SELECT
    generate_series(201, 1000);
ANALYZE transition_table_level1;
-- behave reasonably if someone tries to modify a transition table
CREATE FUNCTION transition_table_level2_bad_usage_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO dx
        VALUES (1000000, 1000000, 'x');
    RETURN NULL;
END;
$$;
CREATE TRIGGER transition_table_level2_bad_usage_trigger
    AFTER DELETE ON transition_table_level2 REFERENCING OLD TABLE AS dx
    FOR EACH STATEMENT
    EXECUTE PROCEDURE transition_table_level2_bad_usage_func ();
DELETE FROM transition_table_level2
WHERE level2_no BETWEEN 301 AND 305;
DROP TRIGGER transition_table_level2_bad_usage_trigger ON transition_table_level2;
-- attempt modifications which would break RI (should all fail)
DELETE FROM transition_table_level1
WHERE level1_no = 25;
UPDATE
    transition_table_level1
SET
    level1_no = -1
WHERE
    level1_no = 30;
INSERT INTO transition_table_level2 (level2_no, parent_no)
    VALUES (10000, 10000);
UPDATE
    transition_table_level2
SET
    parent_no = 2000
WHERE
    level2_no = 40;
-- attempt modifications which would not break RI (should all succeed)
DELETE FROM transition_table_level1
WHERE level1_no BETWEEN 201 AND 1000;
DELETE FROM transition_table_level1
WHERE level1_no BETWEEN 100000000 AND 100000010;
SELECT
    count(*)
FROM
    transition_table_level1;
DELETE FROM transition_table_level2
WHERE level2_no BETWEEN 211 AND 220;
SELECT
    count(*)
FROM
    transition_table_level2;
CREATE TABLE alter_table_under_transition_tables (
    id int PRIMARY KEY,
    name text
);
CREATE FUNCTION alter_table_under_transition_tables_upd_func ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE WARNING 'old table = %, new table = %', (
        SELECT
            string_agg(id || '=' || name, ',')
        FROM
            d),
    (
        SELECT
            string_agg(id || '=' || name, ',')
        FROM
            i);
    RAISE NOTICE 'one = %', (
        SELECT
            1
        FROM
            alter_table_under_transition_tables
        LIMIT 1);
    RETURN NULL;
END;
$$;
-- should fail, TRUNCATE is not compatible with transition tables
CREATE TRIGGER alter_table_under_transition_tables_upd_trigger
    AFTER TRUNCATE OR UPDATE ON alter_table_under_transition_tables REFERENCING OLD TABLE AS d NEW TABLE AS i
    FOR EACH STATEMENT
    EXECUTE PROCEDURE alter_table_under_transition_tables_upd_func ();
-- should work
CREATE TRIGGER alter_table_under_transition_tables_upd_trigger
    AFTER UPDATE ON alter_table_under_transition_tables REFERENCING OLD TABLE AS d NEW TABLE AS i
    FOR EACH STATEMENT
    EXECUTE PROCEDURE alter_table_under_transition_tables_upd_func ();
INSERT INTO alter_table_under_transition_tables
VALUES
    (1, '1'),
    (2, '2'),
    (3, '3');
UPDATE
    alter_table_under_transition_tables
SET
    name = name || name;
-- now change 'name' to an integer to see what happens...
ALTER TABLE alter_table_under_transition_tables
    ALTER COLUMN name TYPE int
    USING name::integer;
UPDATE
    alter_table_under_transition_tables
SET
    name = (name::text || name::text)::integer;
-- now drop column 'name'
ALTER TABLE alter_table_under_transition_tables
    DROP COLUMN name;
UPDATE
    alter_table_under_transition_tables
SET
    id = id;
--
-- Test multiple reference to a transition table
--
CREATE TABLE multi_test (
    i int
);
INSERT INTO multi_test
    VALUES (1);
CREATE OR REPLACE FUNCTION multi_test_trig ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'count = %', (
        SELECT
            COUNT(*)
        FROM
            new_test);
    RAISE NOTICE 'count union = %', (
        SELECT
            COUNT(*)
        FROM (
            SELECT
                *
            FROM
                new_test
            UNION ALL
            SELECT
                *
            FROM
                new_test) ss);
    RETURN NULL;
END
$$;
CREATE TRIGGER my_trigger
    AFTER UPDATE ON multi_test REFERENCING NEW TABLE AS new_test OLD TABLE AS old_test
    FOR EACH STATEMENT
    EXECUTE PROCEDURE multi_test_trig ();
UPDATE
    multi_test
SET
    i = i;
DROP TABLE multi_test;
DROP FUNCTION multi_test_trig ();
--
-- Check type parsing and record fetching from partitioned tables
--
CREATE TABLE partitioned_table (
    a int,
    b text
)
PARTITION BY LIST (a);
CREATE TABLE pt_part1 PARTITION OF partitioned_table
FOR VALUES IN (1);
CREATE TABLE pt_part2 PARTITION OF partitioned_table
FOR VALUES IN (2);
INSERT INTO partitioned_table
    VALUES (1, 'Row 1');
INSERT INTO partitioned_table
    VALUES (2, 'Row 2');
CREATE OR REPLACE FUNCTION get_from_partitioned_table (partitioned_table.a%type)
    RETURNS partitioned_table
    AS $$
DECLARE
    a_val partitioned_table.a%TYPE;
    result partitioned_table%ROWTYPE;
BEGIN
    a_val := $1;
    SELECT
        * INTO result
    FROM
        partitioned_table
    WHERE
        a = a_val;
    RETURN result;
    END;
$$
LANGUAGE plpgsql;
SELECT
    *
FROM
    get_from_partitioned_table (1) AS t;
CREATE OR REPLACE FUNCTION list_partitioned_table ()
    RETURNS SETOF partitioned_table.a%TYPE
    AS $$
DECLARE
    ROW partitioned_table%ROWTYPE;
    a_val partitioned_table.a%TYPE;
BEGIN
    FOR ROW IN
    SELECT
        *
    FROM
        partitioned_table
    ORDER BY
        a LOOP
            a_val := row.a;
            RETURN NEXT a_val;
        END LOOP;
    RETURN;
END;
$$
LANGUAGE plpgsql;
SELECT
    *
FROM
    list_partitioned_table () AS t;
--
-- Check argument name is used instead of $n in error message
--
CREATE FUNCTION fx (x WSlot)
    RETURNS void
    AS $$
BEGIN
    GET DIAGNOSTICS x = ROW_COUNT;
    RETURN;
END;
$$
LANGUAGE plpgsql;
