INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (KEY, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                insertconflicttest ii
            WHERE
                ii.key = excluded.key);

INSERT INTO tbl1
SELECT
    column1,
    coilumn2,
    column3
FROM
    tbl2
ON CONFLICT ON CONSTRAINT pk$tbl1
    DO UPDATE SET
        asgen = excluded.asgen,
        long_rev = excluded.long_rev,
        short_rev = excluded.short_rev;

UPDATE
    toto
SET
    asgen = excluded.asgen,
    long_rev = excluded.long_rev,
    short_rev = excluded.short_rev;

CREATE TABLE FKTABLE (
    ftest1 int REFERENCES PKTABLE MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
    ftest2 int
);

CREATE TABLE FKTABLE (
    ftest1 int DEFAULT -1,
    ftest2 int DEFAULT -2,
    ftest3 int,
    CONSTRAINT constrname2 FOREIGN KEY (ftest1, ftest2) REFERENCES PKTABLE MATCH FULL ON DELETE SET DEFAULT ON UPDATE SET DEFAULT
);

ALTER TABLE fk_partitioned_fk
    ADD FOREIGN KEY (a, b) REFERENCES fk_notpartitioned_pk MATCH SIMPLE ON DELETE SET NULL ON UPDATE SET NULL;

CREATE TABLE persons OF nothing;

CREATE TABLE IF NOT EXISTS persons OF nothing;

SELECT
    *
FROM
    NOTHING;

SET client_encoding TO 'UTF8';

UPDATE
    weather
SET
    temp_lo = temp_lo + 1,
    temp_hi = temp_lo + 15,
    prcp = DEFAULT
WHERE
    city = 'San Francisco'
    AND date = '2003-07-03'
RETURNING
    temp_lo,
    temp_hi,
    prcp;

INSERT INTO tbl1
SELECT
    column1,
    coilumn2,
    column3
FROM
    tbl2
ON CONFLICT ON CONSTRAINT pk$tbl1
    DO UPDATE SET
        asgen = excluded.asgen,
        long_rev = excluded.long_rev,
        short_rev = excluded.short_rev;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (fruit, key, fruit, key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (lower(fruit), key, lower(fruit), key)
    DO NOTHING;

EXPLAIN (
    COSTS OFF
) INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (key, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                insertconflicttest ii
            WHERE
                ii.key = excluded.key);

PREPARE demo AS
INSERT INTO demo
    VALUES (1, 2, 3, 4);

PREPARE demo AS
UPDATE
    demo
SET
    lbl = 'unknown'
WHERE
    id IN (1, 2, 3, 4);

BEGIN;
LOCK hs1 IN SHARE UPDATE EXCLUSIVE MODE;
COMMIT;

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

EXPLAIN (
    COSTS OFF
) CREATE TABLE parallel_write AS
EXECUTE prep_stmt;

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

CREATE VIEW v AS
WITH a AS (
    SELECT
        *
    FROM
        aa);

-- original snippet
\set user `echo $PGRST_DB_USER`
\set passwd `echo $PGRST_DB_PWD`
CREATE ROLE :user WITH LOGIN noinherit PASSWORD :'passwd';

SELECT
    -11,
    -10 * -1.3,
    -1.3 * 10, (1 + 2) - -9,
    ARRAY[-15, -14, -13],
    fnsum (-12 + 34);

