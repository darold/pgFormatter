CREATE SCHEMA testxmlschema;

CREATE TABLE testxmlschema.test1 (
    a int,
    b text
);

INSERT INTO testxmlschema.test1
VALUES
    (1, 'one'),
    (2, 'two'),
    (-1, NULL);

CREATE DOMAIN testxmldomain AS varchar;

CREATE TABLE testxmlschema.test2 (
    z int,
    y varchar(500),
    x char(6),
    w numeric(9, 2),
    v smallint,
    u bigint,
    t real,
    s time,
    r timestamp,
    q date,
    p xml,
    o testxmldomain,
    n bool,
    m bytea,
    aaa text
);

ALTER TABLE testxmlschema.test2
    DROP COLUMN aaa;

INSERT INTO testxmlschema.test2
    VALUES (55, 'abc', 'def', 98.6, 2, 999, 0, '21:07', '2009-06-08 21:07:30', '2009-06-08', NULL, 'ABC', TRUE, 'XYZ');

SELECT
    table_to_xml('testxmlschema.test1', FALSE, FALSE, '');

SELECT
    table_to_xml('testxmlschema.test1', TRUE, FALSE, 'foo');

SELECT
    table_to_xml('testxmlschema.test1', FALSE, TRUE, '');

SELECT
    table_to_xml('testxmlschema.test1', TRUE, TRUE, '');

SELECT
    table_to_xml('testxmlschema.test2', FALSE, FALSE, '');

SELECT
    table_to_xmlschema('testxmlschema.test1', FALSE, FALSE, '');

SELECT
    table_to_xmlschema('testxmlschema.test1', TRUE, FALSE, '');

SELECT
    table_to_xmlschema('testxmlschema.test1', FALSE, TRUE, 'foo');

SELECT
    table_to_xmlschema('testxmlschema.test1', TRUE, TRUE, '');

SELECT
    table_to_xmlschema('testxmlschema.test2', FALSE, FALSE, '');

SELECT
    table_to_xml_and_xmlschema('testxmlschema.test1', FALSE, FALSE, '');

SELECT
    table_to_xml_and_xmlschema('testxmlschema.test1', TRUE, FALSE, '');

SELECT
    table_to_xml_and_xmlschema('testxmlschema.test1', FALSE, TRUE, '');

SELECT
    table_to_xml_and_xmlschema('testxmlschema.test1', TRUE, TRUE, 'foo');

SELECT
    query_to_xml('SELECT * FROM testxmlschema.test1', FALSE, FALSE, '');

SELECT
    query_to_xmlschema('SELECT * FROM testxmlschema.test1', FALSE, FALSE, '');

SELECT
    query_to_xml_and_xmlschema('SELECT * FROM testxmlschema.test1', TRUE, TRUE, '');

DECLARE xc CURSOR WITH HOLD FOR
    SELECT
        *
    FROM
        testxmlschema.test1
    ORDER BY
        1,
        2;

SELECT
    cursor_to_xml('xc'::refcursor, 5, FALSE, TRUE, '');

SELECT
    cursor_to_xmlschema('xc'::refcursor, FALSE, TRUE, '');

MOVE BACKWARD ALL IN xc;

SELECT
    cursor_to_xml('xc'::refcursor, 5, TRUE, FALSE, '');

SELECT
    cursor_to_xmlschema('xc'::refcursor, TRUE, FALSE, '');

SELECT
    schema_to_xml('testxmlschema', FALSE, TRUE, '');

SELECT
    schema_to_xml('testxmlschema', TRUE, FALSE, '');

SELECT
    schema_to_xmlschema('testxmlschema', FALSE, TRUE, '');

SELECT
    schema_to_xmlschema('testxmlschema', TRUE, FALSE, '');

SELECT
    schema_to_xml_and_xmlschema('testxmlschema', TRUE, TRUE, 'foo');

-- test that domains are transformed like their base types
CREATE DOMAIN testboolxmldomain AS bool;

CREATE DOMAIN testdatexmldomain AS date;

CREATE TABLE testxmlschema.test3 AS
SELECT
    TRUE c1,
    TRUE::testboolxmldomain c2,
    '2013-02-21'::date c3,
    '2013-02-21'::testdatexmldomain c4;

SELECT
    xmlforest(c1, c2, c3, c4)
FROM
    testxmlschema.test3;

SELECT
    table_to_xml('testxmlschema.test3', TRUE, TRUE, '');

