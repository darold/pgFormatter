--
-- RULES
-- From Jan's original setup_ruletest.sql and run_ruletest.sql
-- - thomas 1998-09-13
--
--
-- Tables and rules for the view test
--
CREATE TABLE rtest_t1 (
    a int4,
    b int4
);

CREATE TABLE rtest_t2 (
    a int4,
    b int4
);

CREATE TABLE rtest_t3 (
    a int4,
    b int4
);

CREATE VIEW rtest_v1 AS
SELECT
    *
FROM
    rtest_t1;

CREATE RULE rtest_v1_ins AS ON INSERT TO rtest_v1
    DO INSTEAD
    INSERT INTO rtest_t1 VALUES (NEW.a, NEW.b);

CREATE RULE rtest_v1_upd AS ON UPDATE
    TO rtest_v1
        DO INSTEAD
        UPDATE
            rtest_t1 SET
            a = NEW.a,
            b = NEW.b WHERE
            a = OLD.a;

CREATE RULE rtest_v1_del AS ON DELETE TO rtest_v1
    DO INSTEAD
    DELETE FROM rtest_t1
    WHERE a = OLD.a;

-- Test comments
COMMENT ON RULE rtest_v1_bad ON rtest_v1 IS 'bad rule';

COMMENT ON RULE rtest_v1_del ON rtest_v1 IS 'delete rule';

COMMENT ON RULE rtest_v1_del ON rtest_v1 IS NULL;

--
-- Tables and rules for the constraint update/delete test
--
-- Note:
-- 	Now that we have multiple action rule support, we check
-- 	both possible syntaxes to define them (The last action
--  can but must not have a semicolon at the end).
--
CREATE TABLE rtest_system (
    sysname text,
    sysdesc text
);

CREATE TABLE rtest_interface (
    sysname text,
    ifname text
);

CREATE TABLE rtest_person (
    pname text,
    pdesc text
);

CREATE TABLE rtest_admin (
    pname text,
    sysname text
);

CREATE RULE rtest_sys_upd AS ON UPDATE
    TO rtest_system
        DO ALSO
        ( UPDATE
                rtest_interface SET
                sysname = NEW.sysname WHERE
                sysname = OLD.sysname;

UPDATE
    rtest_admin
SET
    sysname = new.sysname
WHERE
    sysname = old.sysname);

CREATE RULE rtest_sys_del AS ON DELETE TO rtest_system
    DO ALSO
    ( DELETE FROM rtest_interface
        WHERE sysname = OLD.sysname;

DELETE FROM rtest_admin
WHERE sysname = old.sysname;

);

CREATE RULE rtest_pers_upd AS ON UPDATE
    TO rtest_person
        DO ALSO
        UPDATE
            rtest_admin SET
            pname = NEW.pname WHERE
            pname = OLD.pname;

CREATE RULE rtest_pers_del AS ON DELETE TO rtest_person
    DO ALSO
    DELETE FROM rtest_admin
    WHERE pname = OLD.pname;

--
-- Tables and rules for the logging test
--
CREATE TABLE rtest_emp (
    ename char(20),
    salary money
);

CREATE TABLE rtest_emplog (
    ename char(20),
    who name,
    action char(10),
    newsal money,
    oldsal money
);

CREATE TABLE rtest_empmass (
    ename char(20),
    salary money
);

CREATE RULE rtest_emp_ins AS ON INSERT TO rtest_emp DO INSERT INTO rtest_emplog VALUES (NEW.ename, CURRENT_USER, 'hired', NEW.salary, '0.00');

CREATE RULE rtest_emp_upd AS ON UPDATE
    TO rtest_emp WHERE
    NEW.salary != OLD.salary DO INSERT INTO rtest_emplog VALUES (NEW.ename, CURRENT_USER, 'honored', NEW.salary, OLD.salary);

CREATE RULE rtest_emp_del AS ON DELETE TO rtest_emp DO INSERT INTO rtest_emplog VALUES (OLD.ename, CURRENT_USER, 'fired', '0.00', OLD.salary);

--
-- Tables and rules for the multiple cascaded qualified instead
-- rule test
--
CREATE TABLE rtest_t4 (
    a int4,
    b text
);

CREATE TABLE rtest_t5 (
    a int4,
    b text
);

CREATE TABLE rtest_t6 (
    a int4,
    b text
);

CREATE TABLE rtest_t7 (
    a int4,
    b text
);

CREATE TABLE rtest_t8 (
    a int4,
    b text
);

CREATE TABLE rtest_t9 (
    a int4,
    b text
);

CREATE RULE rtest_t4_ins1 AS ON INSERT TO rtest_t4 WHERE
    NEW.a >= 10
    AND NEW.a < 20
        DO INSTEAD
        INSERT INTO rtest_t5 VALUES (NEW.a, NEW.b);

CREATE RULE rtest_t4_ins2 AS ON INSERT TO rtest_t4 WHERE
    NEW.a >= 20
    AND NEW.a < 30 DO INSERT INTO rtest_t6 VALUES (NEW.a, NEW.b);

CREATE RULE rtest_t5_ins AS ON INSERT TO rtest_t5 WHERE
    NEW.a > 15 DO INSERT INTO rtest_t7 VALUES (NEW.a, NEW.b);

CREATE RULE rtest_t6_ins AS ON INSERT TO rtest_t6 WHERE
    NEW.a > 25
        DO INSTEAD
        INSERT INTO rtest_t8 VALUES (NEW.a, NEW.b);

--
-- Tables and rules for the rule fire order test
--
-- As of PG 7.3, the rules should fire in order by name, regardless
-- of INSTEAD attributes or creation order.
--
CREATE TABLE rtest_order1 (
    a int4
);

CREATE TABLE rtest_order2 (
    a int4,
    b int4,
    c text
);

CREATE SEQUENCE rtest_seq;

CREATE RULE rtest_order_r3 AS ON INSERT TO rtest_order1
    DO INSTEAD
    INSERT INTO rtest_order2 VALUES (NEW.a, nextval('rtest_seq'), 'rule 3 - this should run 3rd');

CREATE RULE rtest_order_r4 AS ON INSERT TO rtest_order1 WHERE
    a < 100
        DO INSTEAD
        INSERT INTO rtest_order2 VALUES (NEW.a, nextval('rtest_seq'), 'rule 4 - this should run 4th');

CREATE RULE rtest_order_r2 AS ON INSERT TO rtest_order1 DO INSERT INTO rtest_order2 VALUES (NEW.a, nextval('rtest_seq'), 'rule 2 - this should run 2nd');

CREATE RULE rtest_order_r1 AS ON INSERT TO rtest_order1
    DO INSTEAD
    INSERT INTO rtest_order2 VALUES (NEW.a, nextval('rtest_seq'), 'rule 1 - this should run 1st');

--
-- Tables and rules for the instead nothing test
--
CREATE TABLE rtest_nothn1 (
    a int4,
    b text
);

CREATE TABLE rtest_nothn2 (
    a int4,
    b text
);

CREATE TABLE rtest_nothn3 (
    a int4,
    b text
);

CREATE TABLE rtest_nothn4 (
    a int4,
    b text
);

CREATE RULE rtest_nothn_r1 AS ON INSERT TO rtest_nothn1 WHERE
    NEW.a >= 10
    AND NEW.a < 20
        DO INSTEAD
        NOTHING;

CREATE RULE rtest_nothn_r2 AS ON INSERT TO rtest_nothn1 WHERE
    NEW.a >= 30
    AND NEW.a < 40
        DO INSTEAD
        NOTHING;

CREATE RULE rtest_nothn_r3 AS ON INSERT TO rtest_nothn2 WHERE
    NEW.a >= 100
        DO INSTEAD
        INSERT INTO rtest_nothn3 VALUES (NEW.a, NEW.b);

CREATE RULE rtest_nothn_r4 AS ON INSERT TO rtest_nothn2
    DO INSTEAD
    NOTHING;

--
-- Tests on a view that is select * of a table
-- and has insert/update/delete instead rules to
-- behave close like the real table.
--
--
-- We need test date later
--
INSERT INTO rtest_t2
    VALUES (1, 21);

INSERT INTO rtest_t2
    VALUES (2, 22);

INSERT INTO rtest_t2
    VALUES (3, 23);

INSERT INTO rtest_t3
    VALUES (1, 31);

INSERT INTO rtest_t3
    VALUES (2, 32);

INSERT INTO rtest_t3
    VALUES (3, 33);

INSERT INTO rtest_t3
    VALUES (4, 34);

INSERT INTO rtest_t3
    VALUES (5, 35);

-- insert values
INSERT INTO rtest_v1
    VALUES (1, 11);

INSERT INTO rtest_v1
    VALUES (2, 12);

SELECT
    *
FROM
    rtest_v1;

-- delete with constant expression
DELETE FROM rtest_v1
WHERE a = 1;

SELECT
    *
FROM
    rtest_v1;

INSERT INTO rtest_v1
    VALUES (1, 11);

DELETE FROM rtest_v1
WHERE b = 12;

SELECT
    *
FROM
    rtest_v1;

INSERT INTO rtest_v1
    VALUES (2, 12);

INSERT INTO rtest_v1
    VALUES (2, 13);

SELECT
    *
FROM
    rtest_v1;

* * Remember the DELETE rule ON rtest_v1: It says * *
    DO INSTEAD
    DELETE FROM rtest_t1
    WHERE a = old.a * * So this time BOTH ROWS WITH a = 2 must get deleted \p
        \r
        DELETE FROM rtest_v1
        WHERE b = 12;

SELECT
    *
FROM
    rtest_v1;

DELETE FROM rtest_v1;

-- insert select
INSERT INTO rtest_v1
SELECT
    *
FROM
    rtest_t2;

SELECT
    *
FROM
    rtest_v1;

DELETE FROM rtest_v1;

-- same with swapped targetlist
INSERT INTO rtest_v1 (b, a)
SELECT
    b,
    a
FROM
    rtest_t2;

SELECT
    *
FROM
    rtest_v1;

-- now with only one target attribute
INSERT INTO rtest_v1 (a)
SELECT
    a
FROM
    rtest_t3;

SELECT
    *
FROM
    rtest_v1;

SELECT
    *
FROM
    rtest_v1
WHERE
    b ISNULL;

-- let attribute a differ (must be done on rtest_t1 - see above)
UPDATE
    rtest_t1
SET
    a = a + 10
WHERE
    b ISNULL;

DELETE FROM rtest_v1
WHERE b ISNULL;

SELECT
    *
FROM
    rtest_v1;

-- now updates with constant expression
UPDATE
    rtest_v1
SET
    b = 42
WHERE
    a = 2;

SELECT
    *
FROM
    rtest_v1;

UPDATE
    rtest_v1
SET
    b = 99
WHERE
    b = 42;

SELECT
    *
FROM
    rtest_v1;

UPDATE
    rtest_v1
SET
    b = 88
WHERE
    b < 50;

SELECT
    *
FROM
    rtest_v1;

DELETE FROM rtest_v1;

INSERT INTO rtest_v1
SELECT
    rtest_t2.a,
    rtest_t3.b
FROM
    rtest_t2,
    rtest_t3
WHERE
    rtest_t2.a = rtest_t3.a;

SELECT
    *
FROM
    rtest_v1;

-- updates in a mergejoin
UPDATE
    rtest_v1
SET
    b = rtest_t2.b
FROM
    rtest_t2
WHERE
    rtest_v1.a = rtest_t2.a;

SELECT
    *
FROM
    rtest_v1;

INSERT INTO rtest_v1
SELECT
    *
FROM
    rtest_t3;

SELECT
    *
FROM
    rtest_v1;

UPDATE
    rtest_t1
SET
    a = a + 10
WHERE
    b > 30;

SELECT
    *
FROM
    rtest_v1;

UPDATE
    rtest_v1
SET
    a = rtest_t3.a + 20
FROM
    rtest_t3
WHERE
    rtest_v1.b = rtest_t3.b;

SELECT
    *
FROM
    rtest_v1;

--
-- Test for constraint updates/deletes
--
INSERT INTO rtest_system
    VALUES ('orion', 'Linux Jan Wieck');

INSERT INTO rtest_system
    VALUES ('notjw', 'WinNT Jan Wieck (notebook)');

INSERT INTO rtest_system
    VALUES ('neptun', 'Fileserver');

INSERT INTO rtest_interface
    VALUES ('orion', 'eth0');

INSERT INTO rtest_interface
    VALUES ('orion', 'eth1');

INSERT INTO rtest_interface
    VALUES ('notjw', 'eth0');

INSERT INTO rtest_interface
    VALUES ('neptun', 'eth0');

INSERT INTO rtest_person
    VALUES ('jw', 'Jan Wieck');

INSERT INTO rtest_person
    VALUES ('bm', 'Bruce Momjian');

INSERT INTO rtest_admin
    VALUES ('jw', 'orion');

INSERT INTO rtest_admin
    VALUES ('jw', 'notjw');

INSERT INTO rtest_admin
    VALUES ('bm', 'neptun');

UPDATE
    rtest_system
SET
    sysname = 'pluto'
WHERE
    sysname = 'neptun';

SELECT
    *
FROM
    rtest_interface;

SELECT
    *
FROM
    rtest_admin;

UPDATE
    rtest_person
SET
    pname = 'jwieck'
WHERE
    pdesc = 'Jan Wieck';

-- Note: use ORDER BY here to ensure consistent output across all systems.
-- The above UPDATE affects two rows with equal keys, so they could be
-- updated in either order depending on the whim of the local qsort().
SELECT
    *
FROM
    rtest_admin
ORDER BY
    pname,
    sysname;

DELETE FROM rtest_system
WHERE sysname = 'orion';

SELECT
    *
FROM
    rtest_interface;

SELECT
    *
FROM
    rtest_admin;

--
-- Rule qualification test
--
INSERT INTO rtest_emp
    VALUES ('wiecc', '5000.00');

INSERT INTO rtest_emp
    VALUES ('gates', '80000.00');

UPDATE
    rtest_emp
SET
    ename = 'wiecx'
WHERE
    ename = 'wiecc';

UPDATE
    rtest_emp
SET
    ename = 'wieck',
    salary = '6000.00'
WHERE
    ename = 'wiecx';

UPDATE
    rtest_emp
SET
    salary = '7000.00'
WHERE
    ename = 'wieck';

DELETE FROM rtest_emp
WHERE ename = 'gates';

SELECT
    ename,
    who = CURRENT_USER AS "matches user",
    action,
    newsal,
    oldsal
FROM
    rtest_emplog
ORDER BY
    ename,
    action,
    newsal;

INSERT INTO rtest_empmass
    VALUES ('meyer', '4000.00');

INSERT INTO rtest_empmass
    VALUES ('maier', '5000.00');

INSERT INTO rtest_empmass
    VALUES ('mayr', '6000.00');

INSERT INTO rtest_emp
SELECT
    *
FROM
    rtest_empmass;

SELECT
    ename,
    who = CURRENT_USER AS "matches user",
    action,
    newsal,
    oldsal
FROM
    rtest_emplog
ORDER BY
    ename,
    action,
    newsal;

UPDATE
    rtest_empmass
SET
    salary = salary + '1000.00';

UPDATE
    rtest_emp
SET
    salary = rtest_empmass.salary
FROM
    rtest_empmass
WHERE
    rtest_emp.ename = rtest_empmass.ename;

SELECT
    ename,
    who = CURRENT_USER AS "matches user",
    action,
    newsal,
    oldsal
FROM
    rtest_emplog
ORDER BY
    ename,
    action,
    newsal;

DELETE FROM rtest_emp USING rtest_empmass
WHERE rtest_emp.ename = rtest_empmass.ename;

SELECT
    ename,
    who = CURRENT_USER AS "matches user",
    action,
    newsal,
    oldsal
FROM
    rtest_emplog
ORDER BY
    ename,
    action,
    newsal;

--
-- Multiple cascaded qualified instead rule test
--
INSERT INTO rtest_t4
    VALUES (1, 'Record should go to rtest_t4');

INSERT INTO rtest_t4
    VALUES (2, 'Record should go to rtest_t4');

INSERT INTO rtest_t4
    VALUES (10, 'Record should go to rtest_t5');

INSERT INTO rtest_t4
    VALUES (15, 'Record should go to rtest_t5');

INSERT INTO rtest_t4
    VALUES (19, 'Record should go to rtest_t5 and t7');

INSERT INTO rtest_t4
    VALUES (20, 'Record should go to rtest_t4 and t6');

INSERT INTO rtest_t4
    VALUES (26, 'Record should go to rtest_t4 and t8');

INSERT INTO rtest_t4
    VALUES (28, 'Record should go to rtest_t4 and t8');

INSERT INTO rtest_t4
    VALUES (30, 'Record should go to rtest_t4');

INSERT INTO rtest_t4
    VALUES (40, 'Record should go to rtest_t4');

SELECT
    *
FROM
    rtest_t4;

SELECT
    *
FROM
    rtest_t5;

SELECT
    *
FROM
    rtest_t6;

SELECT
    *
FROM
    rtest_t7;

SELECT
    *
FROM
    rtest_t8;

DELETE FROM rtest_t4;

DELETE FROM rtest_t5;

DELETE FROM rtest_t6;

DELETE FROM rtest_t7;

DELETE FROM rtest_t8;

INSERT INTO rtest_t9
    VALUES (1, 'Record should go to rtest_t4');

INSERT INTO rtest_t9
    VALUES (2, 'Record should go to rtest_t4');

INSERT INTO rtest_t9
    VALUES (10, 'Record should go to rtest_t5');

INSERT INTO rtest_t9
    VALUES (15, 'Record should go to rtest_t5');

INSERT INTO rtest_t9
    VALUES (19, 'Record should go to rtest_t5 and t7');

INSERT INTO rtest_t9
    VALUES (20, 'Record should go to rtest_t4 and t6');

INSERT INTO rtest_t9
    VALUES (26, 'Record should go to rtest_t4 and t8');

INSERT INTO rtest_t9
    VALUES (28, 'Record should go to rtest_t4 and t8');

INSERT INTO rtest_t9
    VALUES (30, 'Record should go to rtest_t4');

INSERT INTO rtest_t9
    VALUES (40, 'Record should go to rtest_t4');

INSERT INTO rtest_t4
SELECT
    *
FROM
    rtest_t9
WHERE
    a < 20;

SELECT
    *
FROM
    rtest_t4;

SELECT
    *
FROM
    rtest_t5;

SELECT
    *
FROM
    rtest_t6;

SELECT
    *
FROM
    rtest_t7;

SELECT
    *
FROM
    rtest_t8;

INSERT INTO rtest_t4
SELECT
    *
FROM
    rtest_t9
WHERE
    b ~ 'and t8';

SELECT
    *
FROM
    rtest_t4;

SELECT
    *
FROM
    rtest_t5;

SELECT
    *
FROM
    rtest_t6;

SELECT
    *
FROM
    rtest_t7;

SELECT
    *
FROM
    rtest_t8;

INSERT INTO rtest_t4
SELECT
    a + 1,
    b
FROM
    rtest_t9
WHERE
    a IN (20, 30, 40);

SELECT
    *
FROM
    rtest_t4;

SELECT
    *
FROM
    rtest_t5;

SELECT
    *
FROM
    rtest_t6;

SELECT
    *
FROM
    rtest_t7;

SELECT
    *
FROM
    rtest_t8;

--
-- Check that the ordering of rules fired is correct
--
INSERT INTO rtest_order1
    VALUES (1);

SELECT
    *
FROM
    rtest_order2;

--
-- Check if instead nothing w/without qualification works
--
INSERT INTO rtest_nothn1
    VALUES (1, 'want this');

INSERT INTO rtest_nothn1
    VALUES (2, 'want this');

INSERT INTO rtest_nothn1
    VALUES (10, 'don''t want this');

INSERT INTO rtest_nothn1
    VALUES (19, 'don''t want this');

INSERT INTO rtest_nothn1
    VALUES (20, 'want this');

INSERT INTO rtest_nothn1
    VALUES (29, 'want this');

INSERT INTO rtest_nothn1
    VALUES (30, 'don''t want this');

INSERT INTO rtest_nothn1
    VALUES (39, 'don''t want this');

INSERT INTO rtest_nothn1
    VALUES (40, 'want this');

INSERT INTO rtest_nothn1
    VALUES (50, 'want this');

INSERT INTO rtest_nothn1
    VALUES (60, 'want this');

SELECT
    *
FROM
    rtest_nothn1;

INSERT INTO rtest_nothn2
    VALUES (10, 'too small');

INSERT INTO rtest_nothn2
    VALUES (50, 'too small');

INSERT INTO rtest_nothn2
    VALUES (100, 'OK');

INSERT INTO rtest_nothn2
    VALUES (200, 'OK');

SELECT
    *
FROM
    rtest_nothn2;

SELECT
    *
FROM
    rtest_nothn3;

DELETE FROM rtest_nothn1;

DELETE FROM rtest_nothn2;

DELETE FROM rtest_nothn3;

INSERT INTO rtest_nothn4
    VALUES (1, 'want this');

INSERT INTO rtest_nothn4
    VALUES (2, 'want this');

INSERT INTO rtest_nothn4
    VALUES (10, 'don''t want this');

INSERT INTO rtest_nothn4
    VALUES (19, 'don''t want this');

INSERT INTO rtest_nothn4
    VALUES (20, 'want this');

INSERT INTO rtest_nothn4
    VALUES (29, 'want this');

INSERT INTO rtest_nothn4
    VALUES (30, 'don''t want this');

INSERT INTO rtest_nothn4
    VALUES (39, 'don''t want this');

INSERT INTO rtest_nothn4
    VALUES (40, 'want this');

INSERT INTO rtest_nothn4
    VALUES (50, 'want this');

INSERT INTO rtest_nothn4
    VALUES (60, 'want this');

INSERT INTO rtest_nothn1
SELECT
    *
FROM
    rtest_nothn4;

SELECT
    *
FROM
    rtest_nothn1;

DELETE FROM rtest_nothn4;

INSERT INTO rtest_nothn4
    VALUES (10, 'too small');

INSERT INTO rtest_nothn4
    VALUES (50, 'too small');

INSERT INTO rtest_nothn4
    VALUES (100, 'OK');

INSERT INTO rtest_nothn4
    VALUES (200, 'OK');

INSERT INTO rtest_nothn2
SELECT
    *
FROM
    rtest_nothn4;

SELECT
    *
FROM
    rtest_nothn2;

SELECT
    *
FROM
    rtest_nothn3;

CREATE TABLE rtest_view1 (
    a int4,
    b text,
    v bool
);

CREATE TABLE rtest_view2 (
    a int4
);

CREATE TABLE rtest_view3 (
    a int4,
    b text
);

CREATE TABLE rtest_view4 (
    a int4,
    b text,
    c int4
);

CREATE VIEW rtest_vview1 AS
SELECT
    a,
    b
FROM
    rtest_view1 X
WHERE
    0 < (
        SELECT
            count(*)
        FROM
            rtest_view2 Y
        WHERE
            Y.a = X.a);

CREATE VIEW rtest_vview2 AS
SELECT
    a,
    b
FROM
    rtest_view1
WHERE
    v;

CREATE VIEW rtest_vview3 AS
SELECT
    a,
    b
FROM
    rtest_vview2 X
WHERE
    0 < (
        SELECT
            count(*)
        FROM
            rtest_view2 Y
        WHERE
            Y.a = X.a);

CREATE VIEW rtest_vview4 AS
SELECT
    X.a,
    X.b,
    count(Y.a) AS refcount
FROM
    rtest_view1 X,
    rtest_view2 Y
WHERE
    X.a = Y.a
GROUP BY
    X.a,
    X.b;

CREATE FUNCTION rtest_viewfunc1 (int4)
    RETURNS int4
    AS '
    SELECT
        count(*)::int4
    FROM
        rtest_view2
    WHERE
        a = $1;
'
LANGUAGE sql;

CREATE VIEW rtest_vview5 AS
SELECT
    a,
    b,
    rtest_viewfunc1 (a) AS refcount
FROM
    rtest_view1;

INSERT INTO rtest_view1
    VALUES (1, 'item 1', 't');

INSERT INTO rtest_view1
    VALUES (2, 'item 2', 't');

INSERT INTO rtest_view1
    VALUES (3, 'item 3', 't');

INSERT INTO rtest_view1
    VALUES (4, 'item 4', 'f');

INSERT INTO rtest_view1
    VALUES (5, 'item 5', 't');

INSERT INTO rtest_view1
    VALUES (6, 'item 6', 'f');

INSERT INTO rtest_view1
    VALUES (7, 'item 7', 't');

INSERT INTO rtest_view1
    VALUES (8, 'item 8', 't');

INSERT INTO rtest_view2
    VALUES (2);

INSERT INTO rtest_view2
    VALUES (2);

INSERT INTO rtest_view2
    VALUES (4);

INSERT INTO rtest_view2
    VALUES (5);

INSERT INTO rtest_view2
    VALUES (7);

INSERT INTO rtest_view2
    VALUES (7);

INSERT INTO rtest_view2
    VALUES (7);

INSERT INTO rtest_view2
    VALUES (7);

SELECT
    *
FROM
    rtest_vview1;

SELECT
    *
FROM
    rtest_vview2;

SELECT
    *
FROM
    rtest_vview3;

SELECT
    *
FROM
    rtest_vview4
ORDER BY
    a,
    b;

SELECT
    *
FROM
    rtest_vview5;

INSERT INTO rtest_view3
SELECT
    *
FROM
    rtest_vview1
WHERE
    a < 7;

SELECT
    *
FROM
    rtest_view3;

DELETE FROM rtest_view3;

INSERT INTO rtest_view3
SELECT
    *
FROM
    rtest_vview2
WHERE
    a != 5
    AND b !~ '2';

SELECT
    *
FROM
    rtest_view3;

DELETE FROM rtest_view3;

INSERT INTO rtest_view3
SELECT
    *
FROM
    rtest_vview3;

SELECT
    *
FROM
    rtest_view3;

DELETE FROM rtest_view3;

INSERT INTO rtest_view4
SELECT
    *
FROM
    rtest_vview4
WHERE
    3 > refcount;

SELECT
    *
FROM
    rtest_view4
ORDER BY
    a,
    b;

DELETE FROM rtest_view4;

INSERT INTO rtest_view4
SELECT
    *
FROM
    rtest_vview5
WHERE
    a > 2
    AND refcount = 0;

SELECT
    *
FROM
    rtest_view4;

DELETE FROM rtest_view4;

--
-- Test for computations in views
--
CREATE TABLE rtest_comp (
    part text,
    unit char(4),
    size float
);

CREATE TABLE rtest_unitfact (
    unit char(4),
    factor float
);

CREATE VIEW rtest_vcomp AS
SELECT
    X.part,
    (X.size * Y.factor) AS size_in_cm
FROM
    rtest_comp X,
    rtest_unitfact Y
WHERE
    X.unit = Y.unit;

INSERT INTO rtest_unitfact
    VALUES ('m', 100.0);

INSERT INTO rtest_unitfact
    VALUES ('cm', 1.0);

INSERT INTO rtest_unitfact
    VALUES ('inch', 2.54);

INSERT INTO rtest_comp
    VALUES ('p1', 'm', 5.0);

INSERT INTO rtest_comp
    VALUES ('p2', 'm', 3.0);

INSERT INTO rtest_comp
    VALUES ('p3', 'cm', 5.0);

INSERT INTO rtest_comp
    VALUES ('p4', 'cm', 15.0);

INSERT INTO rtest_comp
    VALUES ('p5', 'inch', 7.0);

INSERT INTO rtest_comp
    VALUES ('p6', 'inch', 4.4);

SELECT
    *
FROM
    rtest_vcomp
ORDER BY
    part;

SELECT
    *
FROM
    rtest_vcomp
WHERE
    size_in_cm > 10.0
ORDER BY
    size_in_cm USING >;

--
-- In addition run the (slightly modified) queries from the
-- programmers manual section on the rule system.
--
CREATE TABLE shoe_data (
    shoename char(10), -- primary key
    sh_avail integer, -- available # of pairs
    slcolor char(10), -- preferred shoelace color
    slminlen float, -- minimum shoelace length
    slmaxlen float, -- maximum shoelace length
    slunit char(8) -- length unit
);

CREATE TABLE shoelace_data (
    sl_name char(10), -- primary key
    sl_avail integer, -- available # of pairs
    sl_color char(10), -- shoelace color
    sl_len float, -- shoelace length
    sl_unit char(8) -- length unit
);

CREATE TABLE unit (
    un_name char(8), -- the primary key
    un_fact float -- factor to transform to cm
);

CREATE VIEW shoe AS
SELECT
    sh.shoename,
    sh.sh_avail,
    sh.slcolor,
    sh.slminlen,
    sh.slminlen * un.un_fact AS slminlen_cm,
    sh.slmaxlen,
    sh.slmaxlen * un.un_fact AS slmaxlen_cm,
    sh.slunit
FROM
    shoe_data sh,
    unit un
WHERE
    sh.slunit = un.un_name;

CREATE VIEW shoelace AS
SELECT
    s.sl_name,
    s.sl_avail,
    s.sl_color,
    s.sl_len,
    s.sl_unit,
    s.sl_len * u.un_fact AS sl_len_cm
FROM
    shoelace_data s,
    unit u
WHERE
    s.sl_unit = u.un_name;

CREATE VIEW shoe_ready AS
SELECT
    rsh.shoename,
    rsh.sh_avail,
    rsl.sl_name,
    rsl.sl_avail,
    int4smaller(rsh.sh_avail, rsl.sl_avail) AS total_avail
FROM
    shoe rsh,
    shoelace rsl
WHERE
    rsl.sl_color = rsh.slcolor
    AND rsl.sl_len_cm >= rsh.slminlen_cm
    AND rsl.sl_len_cm <= rsh.slmaxlen_cm;

INSERT INTO unit
    VALUES ('cm', 1.0);

INSERT INTO unit
    VALUES ('m', 100.0);

INSERT INTO unit
    VALUES ('inch', 2.54);

INSERT INTO shoe_data
    VALUES ('sh1', 2, 'black', 70.0, 90.0, 'cm');

INSERT INTO shoe_data
    VALUES ('sh2', 0, 'black', 30.0, 40.0, 'inch');

INSERT INTO shoe_data
    VALUES ('sh3', 4, 'brown', 50.0, 65.0, 'cm');

INSERT INTO shoe_data
    VALUES ('sh4', 3, 'brown', 40.0, 50.0, 'inch');

INSERT INTO shoelace_data
    VALUES ('sl1', 5, 'black', 80.0, 'cm');

INSERT INTO shoelace_data
    VALUES ('sl2', 6, 'black', 100.0, 'cm');

INSERT INTO shoelace_data
    VALUES ('sl3', 0, 'black', 35.0, 'inch');

INSERT INTO shoelace_data
    VALUES ('sl4', 8, 'black', 40.0, 'inch');

INSERT INTO shoelace_data
    VALUES ('sl5', 4, 'brown', 1.0, 'm');

INSERT INTO shoelace_data
    VALUES ('sl6', 0, 'brown', 0.9, 'm');

INSERT INTO shoelace_data
    VALUES ('sl7', 7, 'brown', 60, 'cm');

INSERT INTO shoelace_data
    VALUES ('sl8', 1, 'brown', 40, 'inch');

-- SELECTs in doc
SELECT
    *
FROM
    shoelace
ORDER BY
    sl_name;

SELECT
    *
FROM
    shoe_ready
WHERE
    total_avail >= 2
ORDER BY
    1;

CREATE TABLE shoelace_log (
    sl_name char(10), -- shoelace changed
    sl_avail integer, -- new available value
    log_who name, -- who did it
    log_when timestamp -- when
);

-- Want "log_who" to be CURRENT_USER,
-- but that is non-portable for the regression test
-- - thomas 1999-02-21
CREATE RULE log_shoelace AS ON UPDATE
    TO shoelace_data WHERE
    NEW.sl_avail != OLD.sl_avail DO INSERT INTO shoelace_log VALUES (NEW.sl_name, NEW.sl_avail, 'Al Bundy', 'epoch');

UPDATE
    shoelace_data
SET
    sl_avail = 6
WHERE
    sl_name = 'sl7';

SELECT
    *
FROM
    shoelace_log;

CREATE RULE shoelace_ins AS ON INSERT TO shoelace
    DO INSTEAD
    INSERT INTO shoelace_data VALUES (NEW.sl_name, NEW.sl_avail, NEW.sl_color, NEW.sl_len, NEW.sl_unit);

CREATE RULE shoelace_upd AS ON UPDATE
    TO shoelace
        DO INSTEAD
        UPDATE
            shoelace_data SET
            sl_name = NEW.sl_name,
            sl_avail = NEW.sl_avail,
            sl_color = NEW.sl_color,
            sl_len = NEW.sl_len,
            sl_unit = NEW.sl_unit WHERE
            sl_name = OLD.sl_name;

CREATE RULE shoelace_del AS ON DELETE TO shoelace
    DO INSTEAD
    DELETE FROM shoelace_data
    WHERE sl_name = OLD.sl_name;

CREATE TABLE shoelace_arrive (
    arr_name char(10),
    arr_quant integer
);

CREATE TABLE shoelace_ok (
    ok_name char(10),
    ok_quant integer
);

CREATE RULE shoelace_ok_ins AS ON INSERT TO shoelace_ok
    DO INSTEAD
    UPDATE
        shoelace SET
        sl_avail = sl_avail + NEW.ok_quant WHERE
        sl_name = NEW.ok_name;

INSERT INTO shoelace_arrive
    VALUES ('sl3', 10);

INSERT INTO shoelace_arrive
    VALUES ('sl6', 20);

INSERT INTO shoelace_arrive
    VALUES ('sl8', 20);

SELECT
    *
FROM
    shoelace
ORDER BY
    sl_name;

INSERT INTO shoelace_ok
SELECT
    *
FROM
    shoelace_arrive;

SELECT
    *
FROM
    shoelace
ORDER BY
    sl_name;

SELECT
    *
FROM
    shoelace_log
ORDER BY
    sl_name;

CREATE VIEW shoelace_obsolete AS
SELECT
    *
FROM
    shoelace
WHERE
    NOT EXISTS (
        SELECT
            shoename
        FROM
            shoe
        WHERE
            slcolor = sl_color);

CREATE VIEW shoelace_candelete AS
SELECT
    *
FROM
    shoelace_obsolete
WHERE
    sl_avail = 0;

INSERT INTO shoelace
    VALUES ('sl9', 0, 'pink', 35.0, 'inch', 0.0);

INSERT INTO shoelace
    VALUES ('sl10', 1000, 'magenta', 40.0, 'inch', 0.0);

-- Unsupported (even though a similar updatable view construct is)
INSERT INTO shoelace
    VALUES ('sl10', 1000, 'magenta', 40.0, 'inch', 0.0)
ON CONFLICT
    DO NOTHING;

SELECT
    *
FROM
    shoelace_obsolete
ORDER BY
    sl_len_cm;

SELECT
    *
FROM
    shoelace_candelete;

DELETE FROM shoelace
WHERE EXISTS (
        SELECT
            *
        FROM
            shoelace_candelete
        WHERE
            sl_name = shoelace.sl_name);

SELECT
    *
FROM
    shoelace
ORDER BY
    sl_name;

SELECT
    *
FROM
    shoe
ORDER BY
    shoename;

SELECT
    count(*)
FROM
    shoe;

--
-- Simple test of qualified ON INSERT ... this did not work in 7.0 ...
--
CREATE TABLE rules_foo (
    f1 int
);

CREATE TABLE rules_foo2 (
    f1 int
);

CREATE RULE rules_foorule AS ON INSERT TO rules_foo WHERE
    f1 < 100
        DO INSTEAD
        NOTHING;

INSERT INTO rules_foo
    VALUES (1);

INSERT INTO rules_foo
    VALUES (1001);

SELECT
    *
FROM
    rules_foo;

DROP RULE rules_foorule ON rules_foo;

-- this should fail because f1 is not exposed for unqualified reference:
CREATE RULE rules_foorule AS ON INSERT TO rules_foo WHERE
    f1 < 100
        DO INSTEAD
        INSERT INTO rules_foo2 VALUES (f1);

-- this is the correct way:
CREATE RULE rules_foorule AS ON INSERT TO rules_foo WHERE
    f1 < 100
        DO INSTEAD
        INSERT INTO rules_foo2 VALUES (NEW.f1);

INSERT INTO rules_foo
    VALUES (2);

INSERT INTO rules_foo
    VALUES (100);

SELECT
    *
FROM
    rules_foo;

SELECT
    *
FROM
    rules_foo2;

DROP RULE rules_foorule ON rules_foo;

DROP TABLE rules_foo;

DROP TABLE rules_foo2;

--
-- Test rules containing INSERT ... SELECT, which is a very ugly special
-- case as of 7.1.  Example is based on bug report from Joel Burton.
--
CREATE TABLE pparent (
    pid int,
    txt text
);

INSERT INTO pparent
    VALUES (1, 'parent1');

INSERT INTO pparent
    VALUES (2, 'parent2');

CREATE TABLE cchild (
    pid int,
    descrip text
);

INSERT INTO cchild
    VALUES (1, 'descrip1');

CREATE VIEW vview AS
SELECT
    pparent.pid,
    txt,
    descrip
FROM
    pparent
    LEFT JOIN cchild USING (pid);

CREATE RULE rrule AS ON UPDATE
    TO vview
        DO INSTEAD
        (INSERT INTO cchild (pid, descrip)
            SELECT
                OLD.pid,
                NEW.descrip WHERE
                OLD.descrip ISNULL;

UPDATE
    cchild
SET
    descrip = new.descrip
WHERE
    cchild.pid = old.pid;

);

SELECT
    *
FROM
    vview;

UPDATE
    vview
SET
    descrip = 'test1'
WHERE
    pid = 1;

SELECT
    *
FROM
    vview;

UPDATE
    vview
SET
    descrip = 'test2'
WHERE
    pid = 2;

SELECT
    *
FROM
    vview;

UPDATE
    vview
SET
    descrip = 'test3'
WHERE
    pid = 3;

SELECT
    *
FROM
    vview;

SELECT
    *
FROM
    cchild;

DROP RULE rrule ON vview;

DROP VIEW vview;

DROP TABLE pparent;

DROP TABLE cchild;

--
-- Check that ruleutils are working
--
-- temporarily disable fancy output, so view changes create less diff noise
a \t
SELECT
    viewname,
    definition
FROM
    pg_views
WHERE
    schemaname IN ('pg_catalog', 'public')
ORDER BY
    viewname;

SELECT
    tablename,
    rulename,
    definition
FROM
    pg_rules
WHERE
    schemaname IN ('pg_catalog', 'public')
ORDER BY
    tablename,
    rulename;

-- restore normal output mode
a \t
--
-- CREATE OR REPLACE RULE
--
CREATE TABLE ruletest_tbl (
    a int,
    b int
);

CREATE TABLE ruletest_tbl2 (
    a int,
    b int
);

CREATE OR REPLACE RULE myrule AS ON INSERT TO ruletest_tbl
    DO INSTEAD
    INSERT INTO ruletest_tbl2
        VALUES (
            10, 10
);

INSERT INTO ruletest_tbl
    VALUES (99, 99);

CREATE OR REPLACE RULE myrule AS ON INSERT TO ruletest_tbl
    DO INSTEAD
    INSERT INTO ruletest_tbl2
        VALUES (
            1000, 1000
);

INSERT INTO ruletest_tbl
    VALUES (99, 99);

SELECT
    *
FROM
    ruletest_tbl2;

-- Check that rewrite rules splitting one INSERT into multiple
-- conditional statements does not disable FK checking.
CREATE TABLE rule_and_refint_t1 (
    id1a integer,
    id1b integer,
    PRIMARY KEY (id1a, id1b)
);

CREATE TABLE rule_and_refint_t2 (
    id2a integer,
    id2c integer,
    PRIMARY KEY (id2a, id2c)
);

CREATE TABLE rule_and_refint_t3 (
    id3a integer,
    id3b integer,
    id3c integer,
    data text,
    PRIMARY KEY (id3a, id3b, id3c),
    FOREIGN KEY (id3a, id3b) REFERENCES rule_and_refint_t1 (id1a, id1b),
    FOREIGN KEY (id3a, id3c) REFERENCES rule_and_refint_t2 (id2a, id2c)
);

INSERT INTO rule_and_refint_t1
    VALUES (1, 11);

INSERT INTO rule_and_refint_t1
    VALUES (1, 12);

INSERT INTO rule_and_refint_t1
    VALUES (2, 21);

INSERT INTO rule_and_refint_t1
    VALUES (2, 22);

INSERT INTO rule_and_refint_t2
    VALUES (1, 11);

INSERT INTO rule_and_refint_t2
    VALUES (1, 12);

INSERT INTO rule_and_refint_t2
    VALUES (2, 21);

INSERT INTO rule_and_refint_t2
    VALUES (2, 22);

INSERT INTO rule_and_refint_t3
    VALUES (1, 11, 11, 'row1');

INSERT INTO rule_and_refint_t3
    VALUES (1, 11, 12, 'row2');

INSERT INTO rule_and_refint_t3
    VALUES (1, 12, 11, 'row3');

INSERT INTO rule_and_refint_t3
    VALUES (1, 12, 12, 'row4');

INSERT INTO rule_and_refint_t3
    VALUES (1, 11, 13, 'row5');

INSERT INTO rule_and_refint_t3
    VALUES (1, 13, 11, 'row6');

-- Ordinary table
INSERT INTO rule_and_refint_t3
    VALUES (1, 13, 11, 'row6')
ON CONFLICT
    DO NOTHING;

-- rule not fired, so fk violation
INSERT INTO rule_and_refint_t3
    VALUES (1, 13, 11, 'row6')
ON CONFLICT (id3a, id3b, id3c)
    DO UPDATE SET
        id3b = excluded.id3b;

-- rule fired, so unsupported
INSERT INTO shoelace
    VALUES ('sl9', 0, 'pink', 35.0, 'inch', 0.0)
ON CONFLICT (sl_name)
    DO UPDATE SET
        sl_avail = excluded.sl_avail;

CREATE RULE rule_and_refint_t3_ins AS ON INSERT TO rule_and_refint_t3 WHERE (EXISTS (
        SELECT
            1 FROM
            rule_and_refint_t3 WHERE (((rule_and_refint_t3.id3a = NEW.id3a)
                AND (rule_and_refint_t3.id3b = NEW.id3b))
            AND (rule_and_refint_t3.id3c = NEW.id3c))))
    DO INSTEAD
    UPDATE
        rule_and_refint_t3 SET
        data = NEW.data WHERE (((rule_and_refint_t3.id3a = NEW.id3a)
            AND (rule_and_refint_t3.id3b = NEW.id3b))
        AND (rule_and_refint_t3.id3c = NEW.id3c));

INSERT INTO rule_and_refint_t3
    VALUES (1, 11, 13, 'row7');

INSERT INTO rule_and_refint_t3
    VALUES (1, 13, 11, 'row8');

--
-- disallow dropping a view's rule (bug #5072)
--
CREATE VIEW rules_fooview AS
SELECT
    'rules_foo'::text;

DROP RULE "_RETURN" ON rules_fooview;

DROP VIEW rules_fooview;

--
-- test conversion of table to view (needed to load some pg_dump files)
--
CREATE TABLE rules_fooview (
    x int,
    y text
);

SELECT
    xmin,
    *
FROM
    rules_fooview;

CREATE RULE "_RETURN" AS ON
SELECT
    TO rules_fooview
        DO INSTEAD
        SELECT
            1 AS x,
            'aaa'::text AS y;

SELECT
    *
FROM
    rules_fooview;

SELECT
    xmin,
    *
FROM
    rules_fooview;

-- fail, views don't have such a column
SELECT
    reltoastrelid,
    relkind,
    relfrozenxid
FROM
    pg_class
WHERE
    oid = 'rules_fooview'::regclass;

DROP VIEW rules_fooview;

-- trying to convert a partitioned table to view is not allowed
CREATE TABLE rules_fooview (
    x int,
    y text
)
PARTITION BY LIST (x);

CREATE RULE "_RETURN" AS ON
SELECT
    TO rules_fooview
        DO INSTEAD
        SELECT
            1 AS x,
            'aaa'::text AS y;

-- nor can one convert a partition to view
CREATE TABLE rules_fooview_part PARTITION OF rules_fooview
FOR VALUES IN (1);

CREATE RULE "_RETURN" AS ON
SELECT
    TO rules_fooview_part
        DO INSTEAD
        SELECT
            1 AS x,
            'aaa'::text AS y;

--
-- check for planner problems with complex inherited UPDATES
--
CREATE TABLE id (
    id serial PRIMARY KEY,
    name text
);

-- currently, must respecify PKEY for each inherited subtable
CREATE TABLE test_1 (
    id integer PRIMARY KEY
)
INHERITS (
    id
);

CREATE TABLE test_2 (
    id integer PRIMARY KEY
)
INHERITS (
    id
);

CREATE TABLE test_3 (
    id integer PRIMARY KEY
)
INHERITS (
    id
);

INSERT INTO test_1 (name)
    VALUES ('Test 1');

INSERT INTO test_1 (name)
    VALUES ('Test 2');

INSERT INTO test_2 (name)
    VALUES ('Test 3');

INSERT INTO test_2 (name)
    VALUES ('Test 4');

INSERT INTO test_3 (name)
    VALUES ('Test 5');

INSERT INTO test_3 (name)
    VALUES ('Test 6');

CREATE VIEW id_ordered AS
SELECT
    *
FROM
    id
ORDER BY
    id;

CREATE RULE update_id_ordered AS ON UPDATE
    TO id_ordered
        DO INSTEAD
        UPDATE
            id SET
            name = NEW.name WHERE
            id = OLD.id;

SELECT
    *
FROM
    id_ordered;

UPDATE
    id_ordered
SET
    name = 'update 2'
WHERE
    id = 2;

UPDATE
    id_ordered
SET
    name = 'update 4'
WHERE
    id = 4;

UPDATE
    id_ordered
SET
    name = 'update 5'
WHERE
    id = 5;

SELECT
    *
FROM
    id_ordered;

DROP TABLE id CASCADE;

--
-- check corner case where an entirely-dummy subplan is created by
-- constraint exclusion
--
CREATE temp TABLE t1 (
    a integer PRIMARY KEY
);

CREATE temp TABLE t1_1 (
    CHECK (a >= 0 AND a < 10)
)
INHERITS (
    t1
);

CREATE temp TABLE t1_2 (
    CHECK (a >= 10 AND a < 20)
)
INHERITS (
    t1
);

CREATE RULE t1_ins_1 AS ON INSERT TO t1 WHERE
    NEW.a >= 0
    AND NEW.a < 10
        DO INSTEAD
        INSERT INTO t1_1 VALUES (NEW.a);

CREATE RULE t1_ins_2 AS ON INSERT TO t1 WHERE
    NEW.a >= 10
    AND NEW.a < 20
        DO INSTEAD
        INSERT INTO t1_2 VALUES (NEW.a);

CREATE RULE t1_upd_1 AS ON UPDATE
    TO t1 WHERE
    OLD.a >= 0
    AND OLD.a < 10
        DO INSTEAD
        UPDATE
            t1_1 SET
            a = NEW.a WHERE
            a = OLD.a;

CREATE RULE t1_upd_2 AS ON UPDATE
    TO t1 WHERE
    OLD.a >= 10
    AND OLD.a < 20
        DO INSTEAD
        UPDATE
            t1_2 SET
            a = NEW.a WHERE
            a = OLD.a;

SET constraint_exclusion = ON;

INSERT INTO t1
SELECT
    *
FROM
    generate_series(5, 19, 1) g;

UPDATE
    t1
SET
    a = 4
WHERE
    a = 5;

SELECT
    *
FROM
    ONLY t1;

SELECT
    *
FROM
    ONLY t1_1;

SELECT
    *
FROM
    ONLY t1_2;

RESET constraint_exclusion;

-- test various flavors of pg_get_viewdef()
SELECT
    pg_get_viewdef('shoe'::regclass) AS unpretty;

SELECT
    pg_get_viewdef('shoe'::regclass, TRUE) AS pretty;

SELECT
    pg_get_viewdef('shoe'::regclass, 0) AS prettier;

--
-- check multi-row VALUES in rules
--
CREATE TABLE rules_src (
    f1 int,
    f2 int
);

CREATE TABLE rules_log (
    f1 int,
    f2 int,
    tag text
);

INSERT INTO rules_src
VALUES
    (1, 2),
    (11, 12);

CREATE RULE r1 AS ON UPDATE
    TO rules_src
        DO ALSO
        INSERT INTO rules_log VALUES
            (OLD.*, 'old'),
            (NEW.*, 'new');

UPDATE
    rules_src
SET
    f2 = f2 + 1;

UPDATE
    rules_src
SET
    f2 = f2 * 10;

SELECT
    *
FROM
    rules_src;

SELECT
    *
FROM
    rules_log;

CREATE RULE r2 AS ON UPDATE
    TO rules_src
        DO ALSO
    VALUES (OLD.*,
        'old'),
    (NEW.*,
        'new');

UPDATE
    rules_src
SET
    f2 = f2 / 10;

SELECT
    *
FROM
    rules_src;

SELECT
    *
FROM
    rules_log;

CREATE RULE r3 AS ON DELETE TO rules_src DO NOTIFY rules_src_deletion;

\d+ rules_src
--
-- Ensure an aliased target relation for insert is correctly deparsed.
--
CREATE RULE r4 AS ON INSERT TO rules_src
    DO INSTEAD
    INSERT INTO rules_log AS trgt
    SELECT
        NEW.* RETURNING
        trgt.f1,
        trgt.f2;

CREATE RULE r5 AS ON UPDATE
    TO rules_src
        DO INSTEAD
        UPDATE
            rules_log AS trgt SET
            tag = 'updated' WHERE
            trgt.f1 = NEW.f1;

\d+ rules_src
--
-- check alter rename rule
--
CREATE TABLE rule_t1 (
    a int
);

CREATE VIEW rule_v1 AS
SELECT
    *
FROM
    rule_t1;

CREATE RULE InsertRule AS ON INSERT TO rule_v1
    DO INSTEAD
    INSERT INTO rule_t1 VALUES (NEW.a);

ALTER RULE InsertRule ON rule_v1 RENAME TO NewInsertRule;

INSERT INTO rule_v1
    VALUES (1);

SELECT
    *
FROM
    rule_v1;

\d+ rule_v1
--
-- error conditions for alter rename rule
--
ALTER RULE InsertRule ON rule_v1 RENAME TO NewInsertRule;

-- doesn't exist
ALTER RULE NewInsertRule ON rule_v1 RENAME TO "_RETURN";

-- already exists
ALTER RULE "_RETURN" ON rule_v1 RENAME TO abc;

-- ON SELECT rule cannot be renamed
DROP VIEW rule_v1;

DROP TABLE rule_t1;

--
-- check display of VALUES in view definitions
--
CREATE VIEW rule_v1 AS
VALUES (1,
    2);

\d+ rule_v1
DROP VIEW rule_v1;

CREATE VIEW rule_v1 (x) AS
VALUES (1,
    2);

\d+ rule_v1
DROP VIEW rule_v1;

CREATE VIEW rule_v1 (x) AS
SELECT
    *
FROM (
    VALUES (1, 2)) v;

\d+ rule_v1
DROP VIEW rule_v1;

CREATE VIEW rule_v1 (x) AS
SELECT
    *
FROM (
    VALUES (1, 2)) v (q, w);

\d+ rule_v1
DROP VIEW rule_v1;

--
-- Check DO INSTEAD rules with ON CONFLICT
--
CREATE TABLE hats (
    hat_name char(10) PRIMARY KEY,
    hat_color char(10) -- hat color
);

CREATE TABLE hat_data (
    hat_name char(10),
    hat_color char(10) -- hat color
);

CREATE UNIQUE INDEX hat_data_unique_idx ON hat_data (hat_name COLLATE "C" bpchar_pattern_ops);

-- DO NOTHING with ON CONFLICT
CREATE RULE hat_nosert AS ON INSERT TO hats
    DO INSTEAD
    INSERT INTO hat_data VALUES (NEW.hat_name, NEW.hat_color)
ON CONFLICT (hat_name COLLATE "C" bpchar_pattern_ops)
WHERE
    hat_color = 'green'
        DO NOTHING RETURNING
        *;

SELECT
    definition
FROM
    pg_rules
WHERE
    tablename = 'hats'
ORDER BY
    rulename;

-- Works (projects row)
INSERT INTO hats
    VALUES ('h7', 'black')
RETURNING
    *;

-- Works (does nothing)
INSERT INTO hats
    VALUES ('h7', 'black')
RETURNING
    *;

SELECT
    tablename,
    rulename,
    definition
FROM
    pg_rules
WHERE
    tablename = 'hats';

DROP RULE hat_nosert ON hats;

-- DO NOTHING without ON CONFLICT
CREATE RULE hat_nosert_all AS ON INSERT TO hats
    DO INSTEAD
    INSERT INTO hat_data VALUES (NEW.hat_name, NEW.hat_color)
ON CONFLICT
    DO NOTHING RETURNING
    *;

SELECT
    definition
FROM
    pg_rules
WHERE
    tablename = 'hats'
ORDER BY
    rulename;

DROP RULE hat_nosert_all ON hats;

-- Works (does nothing)
INSERT INTO hats
    VALUES ('h7', 'black')
RETURNING
    *;

-- DO UPDATE with a WHERE clause
CREATE RULE hat_upsert AS ON INSERT TO hats
    DO INSTEAD
    INSERT INTO hat_data VALUES (NEW.hat_name, NEW.hat_color)
ON CONFLICT (hat_name)
    DO UPDATE SET
        hat_name = hat_data.hat_name,
        hat_color = excluded.hat_color WHERE
        excluded.hat_color <> 'forbidden'
        AND hat_data.* != excluded.* RETURNING
        *;

SELECT
    definition
FROM
    pg_rules
WHERE
    tablename = 'hats'
ORDER BY
    rulename;

-- Works (does upsert)
INSERT INTO hats
    VALUES ('h8', 'black')
RETURNING
    *;

SELECT
    *
FROM
    hat_data
WHERE
    hat_name = 'h8';

INSERT INTO hats
    VALUES ('h8', 'white')
RETURNING
    *;

SELECT
    *
FROM
    hat_data
WHERE
    hat_name = 'h8';

INSERT INTO hats
    VALUES ('h8', 'forbidden')
RETURNING
    *;

SELECT
    *
FROM
    hat_data
WHERE
    hat_name = 'h8';

SELECT
    tablename,
    rulename,
    definition
FROM
    pg_rules
WHERE
    tablename = 'hats';

-- ensure explain works for on insert conflict rules
EXPLAIN (
    COSTS OFF
) INSERT INTO hats
    VALUES ('h8', 'forbidden')
RETURNING
    *;

-- ensure upserting into a rule, with a CTE (different offsets!) works
WITH data (
    hat_name,
    hat_color
) AS MATERIALIZED (
    VALUES (
            'h8', 'green'
),
        (
            'h9', 'blue'
),
        (
            'h7', 'forbidden'
))
INSERT INTO hats
SELECT
    *
FROM
    data
RETURNING
    *;

EXPLAIN (
    COSTS OFF
) WITH data (hat_name,
    hat_color) AS MATERIALIZED (
    VALUES ('h8', 'green'),
        ('h9', 'blue'),
        ('h7', 'forbidden'))
INSERT INTO hats
SELECT
    *
FROM
    data
RETURNING
    *;

SELECT
    *
FROM
    hat_data
WHERE
    hat_name IN ('h8', 'h9', 'h7')
ORDER BY
    hat_name;

DROP RULE hat_upsert ON hats;

DROP TABLE hats;

DROP TABLE hat_data;

-- test for pg_get_functiondef properly regurgitating SET parameters
-- Note that the function is kept around to stress pg_dump.
CREATE FUNCTION func_with_set_params ()
    RETURNS integer
    AS '
    SELECT
        1;
'
LANGUAGE SQL
SET search_path TO PG_CATALOG SET extra_float_digits TO 2 SET work_mem TO '4MB' SET datestyle TO iso, mdy SET local_preload_libraries TO "Mixed/Case", 'c:/''a"/path', '', '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789' IMMUTABLE STRICT;

SELECT
    pg_get_functiondef('func_with_set_params()'::regprocedure);

-- tests for pg_get_*def with invalid objects
SELECT
    pg_get_constraintdef(0);

SELECT
    pg_get_functiondef(0);

SELECT
    pg_get_indexdef(0);

SELECT
    pg_get_ruledef(0);

SELECT
    pg_get_statisticsobjdef (0);

SELECT
    pg_get_triggerdef(0);

SELECT
    pg_get_viewdef(0);

SELECT
    pg_get_function_arguments(0);

SELECT
    pg_get_function_identity_arguments(0);

SELECT
    pg_get_function_result(0);

SELECT
    pg_get_function_arg_default (0, 0);

SELECT
    pg_get_function_arg_default ('pg_class'::regclass, 0);

SELECT
    pg_get_partkeydef (0);

-- test rename for a rule defined on a partitioned table
CREATE TABLE rules_parted_table (
    a int
)
PARTITION BY LIST (a);

CREATE TABLE rules_parted_table_1 PARTITION OF rules_parted_table
FOR VALUES IN (1);

CREATE RULE rules_parted_table_insert AS ON INSERT TO rules_parted_table
    DO INSTEAD
    INSERT INTO rules_parted_table_1 VALUES (NEW.*);

ALTER RULE rules_parted_table_insert ON rules_parted_table RENAME TO rules_parted_table_insert_redirect;

DROP TABLE rules_parted_table;

--
-- Test enabling/disabling
--
CREATE TABLE ruletest1 (
    a int
);

CREATE TABLE ruletest2 (
    b int
);

CREATE RULE rule1 AS ON INSERT TO ruletest1
    DO INSTEAD
    INSERT INTO ruletest2 VALUES (NEW.*);

INSERT INTO ruletest1
    VALUES (1);

ALTER TABLE ruletest1 DISABLE RULE rule1;

INSERT INTO ruletest1
    VALUES (2);

ALTER TABLE ruletest1 ENABLE RULE rule1;

SET session_replication_role = REPLICA;

INSERT INTO ruletest1
    VALUES (3);

ALTER TABLE ruletest1 ENABLE REPLICA RULE rule1;

INSERT INTO ruletest1
    VALUES (4);

RESET session_replication_role;

INSERT INTO ruletest1
    VALUES (5);

SELECT
    *
FROM
    ruletest1;

SELECT
    *
FROM
    ruletest2;

DROP TABLE ruletest1;

DROP TABLE ruletest2;

