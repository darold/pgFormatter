copy time
from 's3://mybucket/data/timerows.gz' 
iam_role 'arn:aws:iam::0123456789012:role/MyRedshiftRole'
gzip
delimiter '|';


SELECT a.b AS "B", a.c AS "C" FROM a WHERE d IN (
        SELECT e FROM ( SELECT f FF FROM h HH) i
        UNION ALL
        SELECT j FROM l LL WHERE h.o IS NULL)
ORDER BY
    DECODE(p, 'a', SYSDATE, 'b', SYSDATE, 'c', SYSDATE, d), NVL(q, 1) ASC, CASE WHEN r = 0 AND s != 'N' THEN a.y ELSE a.z END ASC;

