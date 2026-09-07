INSERT INTO labo.peri_budgets
WITH bud AS -- CBT selection des soldes des budgets
(
    SELECT
        1 AS budg_tyap_direct
)
SELECT
    *
FROM
    bud;

INSERT INTO labo.planco_gl
WITH rs1 AS (
    SELECT
        1 AS gl_code
)
SELECT
    gl_code
FROM
    rs1;

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
    taux;

WITH cte AS (
    SELECT
        1 AS x
)
INSERT INTO labo.target
SELECT
    x
FROM
    cte;

