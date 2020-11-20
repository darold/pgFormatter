--
-- expression evaluated tests that don't fit into a more specific file
--
--
-- Tests for SQLVAlueFunction
--
-- current_date  (always matches because of transactional behaviour)
SELECT
    date(now())::text = CURRENT_DATE::text;

-- current_time / localtime
SELECT
    now()::timetz::text = CURRENT_TIME::text;

SELECT
    now()::time::text = LOCALTIME::text;

-- current_timestamp / localtimestamp (always matches because of transactional behaviour)
SELECT
    CURRENT_TIMESTAMP = NOW();

-- precision
SELECT
    length(CURRENT_TIMESTAMP::text) >= length(current_timestamp(0)::text);

-- localtimestamp
SELECT
    now()::timestamp::text = LOCALTIMESTAMP::text;

-- current_role/user/user is tested in rolnames.sql
-- current database / catalog
SELECT
    current_catalog = current_database();

-- current_schema
SELECT
    current_schema;

SET search_path = 'notme';

SELECT
    current_schema;

SET search_path = 'pg_catalog';

SELECT
    current_schema;

RESET search_path;

