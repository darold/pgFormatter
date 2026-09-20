SELECT
    tyap0.tyap_code,
    appel.frap_tyap_code
FROM
    tyap
    LEFT OUTER JOIN ab_frap@link_serveur appel ON appel.frap_tyap_code = tyap.tyap_code
        AND appel.frap_imme_no = tyap.tyap_imme_no
    LEFT OUTER JOIN bud ON bud.budg_tyap_direct = tyap.tyap_direct
;

SELECT
    a.id
FROM
    a
    INNER JOIN b ON b.id = a.id
    CROSS JOIN c ON TRUE
    NATURAL JOIN d ON TRUE
    RIGHT JOIN e ON e.id = a.id
    FULL JOIN f ON f.id = a.id
;

SELECT
    x.v
FROM
    x
    JOIN y ON y.k = x.k
    LEFT JOIN z ON z.k = x.k
;

DO $$
BEGIN
    IF TRUE THEN
        CREATE TABLE t (
            id int DEFAULT abs(-1)
        );
        PERFORM
            1;
    ELSIF FALSE THEN
        CREATE TEMP TABLE t2 (
            id int
        );
    ELSE
        PERFORM
            2;
    END IF;
    PERFORM
        3;
END
$$
;

-- Procedural existence checks must open an indentation level, unlike DDL guards.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT
            1
        FROM
            widgets
        WHERE
            id = 1
            AND enabled) THEN
        IF EXISTS (
            SELECT
                1
            FROM
                other_widgets
            WHERE
                id = 1
                OR id = 2) AND TRUE THEN
            EXECUTE $sql$SELECT 1;$sql$;
        ELSE
            RAISE NOTICE 'missing';
        END IF;
    ELSE
        PERFORM
            2;
    END IF;
    PERFORM
        3;
END
$$
;

CREATE TABLE IF NOT EXISTS widgets (
    id integer,
    enabled boolean
)
;

DROP TABLE IF EXISTS widgets;

SELECT
    'a'
    'b' AS lit
FROM
    t
;

SELECT
    concat('CLOTURE AVGLI PROP LOCATAIRE ', l.imme_no, ' AU '
        '2024-12-31') AS libelle
FROM
    locataires l
;

SELECT
    'one'
    'two'
    'three' AS parts
FROM
    t
;

SELECT
    *
FROM
    t
WHERE
    t.code = 'pre'
    'fix'
;

INSERT INTO labo.peri_budgets
WITH bud AS -- CBT selection des soldes des budgets
(
    SELECT
        1 AS budg_tyap_direct
)
SELECT
    *
FROM
    bud
;

INSERT INTO labo.planco_gl
WITH rs1 AS (
    SELECT
        1 AS gl_code
)
SELECT
    gl_code
FROM
    rs1
;

INSERT INTO labo.lgba_taux (taux, periode)
WITH taux AS (
    SELECT
        0.05 AS taux,
        2024 AS periode
)
SELECT
    taux,
    periode
FROM
    taux
;

WITH cte AS (
    SELECT
        1 AS x
)
INSERT INTO labo.target
SELECT
    x
FROM
    cte
;

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

