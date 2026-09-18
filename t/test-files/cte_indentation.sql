WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;

DO $$
BEGIN
WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;
END
$$;

DO $$
BEGIN
IF TRUE THEN
WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;
ELSE
PERFORM 0;
END IF;
END
$$;

INSERT INTO results (id)
WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;

DO $$
BEGIN
INSERT INTO results (id)
WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;
END
$$;

DO $$
BEGIN
IF TRUE THEN
INSERT INTO results (id)
WITH first_cte AS (SELECT 1 AS id), second_cte AS (SELECT id FROM first_cte), third_cte AS (SELECT id FROM second_cte) SELECT id FROM third_cte;
ELSE
PERFORM 0;
END IF;
END
$$;
