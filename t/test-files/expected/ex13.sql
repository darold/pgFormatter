WITH RECURSIVE employee_recursive (
    distance,
    employee_name,
    manager_name
) AS (
    SELECT
        1,
        employee_name,
        manager_name
    FROM
        employee
    WHERE
        manager_name = 'Mary'
    UNION ALL
    SELECT
        er.distance + 1,
        e.employee_name,
        e.manager_name
    FROM
        employee_recursive er,
        employee e
    WHERE
        er.employee_name = e.manager_name
)
SELECT
    distance,
    employee_name
FROM
    employee_recursive;

WITH RECURSIVE t (
    nombre
) AS (
    VALUES (2)
    UNION ALL
    SELECT
        2 * nombre
    FROM
        t
    WHERE
        2 * nombre < 100
)
SELECT
    nombre
FROM
    t;

CREATE FUNCTION tg_phone_bu ()
    RETURNS TRIGGER
    AS $$
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
$$
LANGUAGE plpgsql;

