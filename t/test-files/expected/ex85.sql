SET search_path = public;

GRANT SELECT ON plan TO reader;

SELECT
    id,
    name
FROM
    plan
WHERE
    kind = 'S'
;

SELECT
    plan.id,
    plan.name
FROM
    plan
WHERE
    plan.kind IS NOT NULL
;

UPDATE
    plan
SET
    status = 'done'
WHERE
    id = 42
;

UPDATE
    plan
SET
    status = 'done'
WHERE
    id = 42
;

