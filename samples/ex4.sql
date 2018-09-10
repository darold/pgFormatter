SELECT 1, 2, 10, 'depesz', 'hubert', 'depesz', 'hubert depesz', '1 2 3 4';

SELECT tbl_lots.id, to_char ( tbl_lots.dt_crea, 'DD/MM/YYYY HH24:MI:SS' ) AS date_crea FROM tbl_lots WHERE tbl_lots.dt_crea > current_timestamp - interval '1 day' AND  tbl_lots.dt_crea > current_timestamp - (dayrett || ' days')::interval AND tbl_lots.type = 'SECRET';

SELECT extract( year from school_day ) AS year;

SELECT substring( firstname from 1 for 10 ) AS sname;

select * from (select 1 i) a INNER JOIN (select 1 i) b ON (a.i=b.i) inner join (select 1 i) ON (c.i=a.i) where a.i=1 ;
