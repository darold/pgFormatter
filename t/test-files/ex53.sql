INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (KEY, fruit)
    DO UPDATE
SET
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
    tbl2 ON CONFLICT ON CONSTRAINT pk$tbl1 DO
    UPDATE
        SET
            asgen = excluded.asgen, long_rev = excluded.long_rev, short_rev = excluded.short_rev;

    UPDATE toto SET
            asgen = excluded.asgen, long_rev = excluded.long_rev, short_rev = excluded.short_rev;

CREATE TABLE FKTABLE ( ftest1 int REFERENCES PKTABLE MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE, ftest2 int );
CREATE TABLE FKTABLE ( ftest1 int DEFAULT -1, ftest2 int DEFAULT -2, ftest3 int, CONSTRAINT constrname2 FOREIGN KEY(ftest1, ftest2)
                       REFERENCES PKTABLE MATCH FULL ON DELETE SET DEFAULT ON UPDATE SET DEFAULT);

ALTER TABLE fk_partitioned_fk ADD FOREIGN KEY (a, b)
  REFERENCES fk_notpartitioned_pk MATCH SIMPLE
  ON DELETE SET NULL ON UPDATE SET NULL;


CREATE TABLE persons OF nothing;
CREATE TABLE IF NOT EXISTS persons OF nothing;
SELECT * FROM nothing;

SET client_encoding TO 'UTF8';

UPDATE weather SET temp_lo = temp_lo+1, temp_hi = temp_lo+15, prcp = DEFAULT
  WHERE city = 'San Francisco' AND date = '2003-07-03' RETURNING temp_lo,temp_hi,prcp;

INSERT INTO tbl1
SELECT
    column1,
    coilumn2,
    column3
FROM
    tbl2 ON CONFLICT ON CONSTRAINT pk$tbl1 DO
    UPDATE
        SET
            asgen = excluded.asgen, long_rev = excluded.long_rev, short_rev = excluded.short_rev;

explain (costs off) insert into insertconflicttest values(0, 'Crowberry') on conflict (fruit, key, fruit, key) do nothing;
explain (costs off) insert into insertconflicttest values(0, 'Crowberry') on conflict (lower(fruit), key, lower(fruit), key) do nothing;
explain (costs off) insert into insertconflicttest values(0, 'Crowberry') on conflict (key, fruit) do update set fruit = excluded.fruit
  where exists (select 1 from insertconflicttest ii where ii.key = excluded.key);

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

create function tg_hub_a() returns trigger as '
declare
    hname       text;
    dummy       integer;
begin
    if tg_op = ''INSERT'' then
        dummy := tg_hub_adjustslots(new.name, 0, new.nslots);
        return new;
    end if;
    if tg_op = ''UPDATE'' then
        if new.name != old.name then
            update HSlot set hubname = new.name where hubname = old.name;
        end if;
        dummy := tg_hub_adjustslots(new.name, old.nslots, new.nslots);
        return new;
    end if;
    if tg_op = ''DELETE'' then
        dummy := tg_hub_adjustslots(old.name, old.nslots, 0);
        return old;
    end if;
end;
' language plpgsql;

EXPLAIN (
    COSTS OFF
) create TABLE parallel_write AS
EXECUTE prep_stmt;

CREATE FUNCTION tg_hub_adjustslots (hname bpchar, oldnslots integer, newnslots integer)
    RETURNS integer
    AS '
 begin
     if newnslots = oldnslots then
         return 0;
     end if;
     if newnslots < oldnslots then
         delete from HSlot where hubname = hname and slotno > newnslots;
        return 0;
     end if;
     for i in oldnslots + 1 .. newnslots loop
         insert into HSlot (slotname, hubname, slotno, slotlink)
                values (''HS.dummy'', hname, i, '''');
     end loop;
     return 0;
 end
 '
    LANGUAGE plpgsql;

create function tg_backlink_a() returns trigger as '
declare
    dummy       integer;
begin
    if tg_op = ''INSERT'' then
        if new.backlink != '''' then
            dummy := tg_backlink_set(new.backlink, new.slotname);
        end if;
        return new;
    end if;
    if tg_op = ''UPDATE'' then
        if new.backlink != old.backlink then
            if old.backlink != '''' then
                dummy := tg_backlink_unset(old.backlink, old.slotname);
            end if;
            if new.backlink != '''' then
                dummy := tg_backlink_set(new.backlink, new.slotname);
            end if;
        else
            if new.slotname != old.slotname and new.backlink != '''' then
                dummy := tg_slotlink_set(new.backlink, new.slotname);
            end if;
        end if;
        return new;
    end if;
    if tg_op = ''DELETE'' then
        if old.backlink != '''' then
            dummy := tg_backlink_unset(old.backlink, old.slotname);
        end if;
        return old;
    end if;
end;
' language plpgsql;

CREATE VIEW v AS
  WITH a AS (
    SELECT
      *
    FROM
      aa
  );

-- original snippet
\set user `echo $PGRST_DB_USER`
\set passwd `echo $PGRST_DB_PWD`
CREATE ROLE :user WITH LOGIN noinherit PASSWORD :'passwd';

select -11,  -10 * -1.3, -1.3 * 10, (1+2) - -9, ARRAY[- 15, -14, -13], fnsum(-12+34);
