-- Input in a single byte encoding (Latin-1 / Windows-1252)
SELECT
    'café',
    upper('äöü') AS "résultat"
FROM
    t
WHERE
    c = 'ß€';

