--
-- Hot Standby tests
--
-- hs_primary_setup.sql
--
DROP TABLE IF EXISTS hs1;

CREATE TABLE hs1 (
    col1 integer PRIMARY KEY
);

INSERT INTO hs1
    VALUES (1);

DROP TABLE IF EXISTS hs2;

CREATE TABLE hs2 (
    col1 integer PRIMARY KEY
);

INSERT INTO hs2
    VALUES (12);

INSERT INTO hs2
    VALUES (13);

DROP TABLE IF EXISTS hs3;

CREATE TABLE hs3 (
    col1 integer PRIMARY KEY
);

INSERT INTO hs3
    VALUES (113);

INSERT INTO hs3
    VALUES (114);

INSERT INTO hs3
    VALUES (115);

DROP SEQUENCE IF EXISTS hsseq;

CREATE SEQUENCE hsseq;

SELECT
    pg_switch_wal ();

