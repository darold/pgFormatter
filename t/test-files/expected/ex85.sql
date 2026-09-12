SELECT
    'a'
    'b' AS lit
FROM
    t;

SELECT
    concat('CLOTURE AVGLI PROP LOCATAIRE ', l.imme_no, ' AU '
        '2024-12-31') AS libelle
FROM
    locataires l;

SELECT
    'one'
    'two'
    'three' AS parts
FROM
    t;

SELECT
    *
FROM
    t
WHERE
    t.code = 'pre'
    'fix';

