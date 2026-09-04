SELECT
    plan.id,
    plan.name,
    CASE WHEN plan.kind = 'S' THEN 'single'
    WHEN plan.kind = 'G' THEN 'group'
    ELSE
        'unknown'
    END AS kind_label
FROM plan
    LEFT JOIN agency ON agency.id = plan.agency_id
WHERE plan.kind IS NOT NULL
    OR plan.name IS NOT NULL
    AND (plan.amount > 100
        OR plan.amount < - 100)
    AND plan.kind IN ('S', 'G');

UPDATE
    plan
SET status = 'done',
    updated_at = NOW()
WHERE id = 42
RETURNING id,
    status;

