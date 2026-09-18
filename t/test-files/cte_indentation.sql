INSERT INTO results (id)
WITH first_cte AS (SELECT 1 AS id),
second_cte AS (SELECT id FROM first_cte)
SELECT id FROM second_cte;

DO $$
BEGIN
IF TRUE THEN
INSERT INTO results (id)
WITH first_cte AS (SELECT 1 AS id),
second_cte AS (SELECT id FROM first_cte)
SELECT id FROM second_cte;
ELSE
PERFORM 0;
END IF;
END
$$;

DO $$
BEGIN
IF TRUE THEN
WITH first_cte AS (SELECT 1 AS id),
second_cte AS (SELECT id FROM first_cte)
SELECT id FROM second_cte;
ELSE
PERFORM 0;
END IF;
END
$$;
