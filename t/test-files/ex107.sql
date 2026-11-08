-- comment AA


-- comment BB
-- comment CC

drop table if exists accounts;

-- comment DD
/* header */


/* second
 * block
 */

-- atlas:import users.sql

CREATE TABLE t (
    a int, -- col a

    -- before b
    b text
);

SELECT a, -- first

    -- second column
    b
FROM t

-- before where
WHERE a = 1;
CREATE FUNCTION f() RETURNS int AS $$
BEGIN
    -- step 1

    RETURN 1;

    -- end
END;
$$ LANGUAGE plpgsql;
SELECT 1; -- trailing

SELECT 2;
-- last
