DELIMITER $$
-- We change the delimiter: it is now $$ instead of ;
CREATE PROCEDURE TEST ()
BEGIN
    SELECT
        "Hello World";

END;
$$
-- This is the delimiter that marks the end of the procedure definition.
DELIMITER ;

DROP SCHEMA IF EXISTS TEST_ISSUE_191;

CREATE SCHEMA TEST_ISSUE_191;

USE TEST_ISSUE_191;

CREATE TABLE TEST (
    A int
);

INSERT INTO TEST
    VALUES (1);

DELIMITER //
CREATE PROCEDURE PROCEDURE_TEST ()
BEGIN
    SELECT
        *
    FROM
        TEST;

END;
//
DELIMITER ;

CALL PROCEDURE_TEST ();

DELIMITER $$
CREATE PROCEDURE PROCEDURE_TEST ()
BEGIN
    SELECT
        *
    FROM
        TEST;

END;
$$
DELIMITER ;

CALL PROCEDURE_TEST ();

