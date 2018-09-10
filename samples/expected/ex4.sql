SELECT
    1,
    2,
    10,
    'depesz',
    'hubert',
    'depesz',
    'hubert depesz',
    '1 2 3 4';

SELECT
    tbl_lots.id,
    to_char(tbl_lots.dt_crea, 'DD/MM/YYYY HH24:MI:SS') AS date_crea
FROM
    tbl_lots
WHERE
    tbl_lots.dt_crea > CURRENT_TIMESTAMP - interval '1 day'
    AND tbl_lots.dt_crea > CURRENT_TIMESTAMP - (dayrett || ' days')::interval
    AND tbl_lots.type = 'SECRET';

SELECT
    extract(year FROM school_day) AS year;

SELECT
    substring(firstname FROM 1 FOR 10) AS sname;

SELECT
    *
FROM (
    SELECT
        1 i) a
    INNER JOIN (
        SELECT
            1 i) b ON (a.i = b.i)
    INNER JOIN (
        SELECT
            1 i) ON (c.i = a.i)
WHERE
    a.i = 1;

