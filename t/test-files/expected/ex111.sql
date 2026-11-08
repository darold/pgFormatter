SELECT r.last_name
     , (SELECT MAX(YEAR (championship_date))
          FROM champions AS c
         WHERE c.last_name = r.last_name
           AND c.confirmed = 'Y') AS last_championship_year
  FROM riders AS r
       INNER JOIN bikes AS b ON r.bike_vin_num = b.vin_num
           AND b.engines > 2
 WHERE r.last_name IN (SELECT c.last_name
                         FROM champions AS c
                        WHERE YEAR (championship_date) > '2008'
                          AND c.confirmed = 'Y')
 GROUP BY r.last_name
HAVING count(*) > 1
 ORDER BY 1
 LIMIT 10;

UPDATE albums
   SET release_date = '1990-01-01 01:01:01.00000'
     , b = 2
 WHERE title = 'The New Danger';

INSERT INTO albums (title , release_date)
VALUES ('Charcoal Lane' , '1990-01-01')
     , ('The New Danger' , '2008-01-01');

DELETE FROM t
 WHERE a = 1
    OR b = 2;

  WITH x AS (
       SELECT a
            , b
         FROM t
        WHERE a IN (SELECT c
                      FROM u)
       )
SELECT x.a
     , x.b
  FROM x
 WHERE x.b > 1
 ORDER BY x.a;

