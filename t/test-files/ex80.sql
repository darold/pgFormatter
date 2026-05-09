CREATE SCHEMA IF NOT EXISTS TEST;

-- Formats as expected
CREATE TABLE TEST.T1 ( C1 VARCHAR( 10 ) CHECK( C1 > 1 ) );

-- Extra space before type and CHECK closing paren's
DO $$
BEGIN
  CREATE TABLE TEST.T2 ( C1 VARCHAR( 10 ) CHECK( C1 > 1 ) );
  CREATE TEMPORARY TABLE TEST.T2 ( C1 VARCHAR( 10 ) CHECK( C1 > 1 ) );
END $$;
