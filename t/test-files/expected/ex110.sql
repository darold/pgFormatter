SELECT r.last_name,
       (SELECT MAX(YEAR (championship_date))
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
   SET release_date = '1990-01-01 01:01:01.00000',
       b = 2
 WHERE title = 'The New Danger';

INSERT INTO albums (title, release_date)
VALUES ('Charcoal Lane', '1990-01-01'),
       ('The New Danger', '2008-01-01');

DELETE FROM t
 WHERE a = 1
    OR b = 2;

  WITH cte AS (
       SELECT a,
              b
         FROM t
        WHERE a > 1
       ),
       c2 AS (
       SELECT *
         FROM u
       )
SELECT cte.a,
       CASE WHEN b = 1 THEN
           'one'
       WHEN b = 2
           AND a = 3 THEN
           'two'
       ELSE
           'other'
       END AS label,
       row_number() OVER (PARTITION BY a ORDER BY b)
  FROM cte
       JOIN c2 USING (a)
       LEFT JOIN v ON v.id = cte.a
 WHERE a BETWEEN 1 AND 10
   AND (b = 1
           OR b = 2)
 UNION ALL
SELECT 1,
       'x',
       2
  FROM dual
 ORDER BY 1;

INSERT INTO t (a, b)
SELECT x,
       y
  FROM s
 WHERE z = 1
RETURNING a,
          b;

UPDATE t
   SET a = s.a
  FROM s
 WHERE t.id = s.id
   AND s.flag
RETURNING t.*;

DELETE FROM t USING s
 WHERE t.id = s.id;

CREATE VIEW v AS
SELECT a,
       count(*)
  FROM t
 GROUP BY a
HAVING count(*) > 1;

CREATE TABLE ct AS
SELECT *
  FROM t
 WHERE a = 1;

CREATE FUNCTION f ()
    RETURNS int
    AS $$
DECLARE
    n int;
BEGIN
    SELECT count(*)
      INTO n
      FROM t
     WHERE a = 1;
    RETURN n;
END
$$
LANGUAGE plpgsql;

SELECT *
  FROM (SELECT a
          FROM t) AS s
 WHERE EXISTS (SELECT 1
                 FROM u
                WHERE u.a = s.a);

-- comment
SELECT a
       /* inline */
  FROM t;

-- trailing
SELECT a
  FROM t
 GROUP BY GROUPING SETS (((a,
                   b)));

SELECT ((a))
  FROM t
 WHERE ((b = 1));

