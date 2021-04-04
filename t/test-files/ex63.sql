SELECT 1 + coalesce(( SELECT sum(amount) FROM transfers WHERE id IS NOT NULL), 0);

SELECT id, jsonb_build_object('subs', ( SELECT json_agg(q.col) AS data FROM q WHERE q.id = t.pid)) AS data FROM t;

SELECT ( SELECT max(( SELECT i.unique2 FROM tenk1 i WHERE i.unique1 = o.unique1))) FROM tenk1 o;

DELETE FROM xx1 USING ( SELECT * FROM int4_tbl WHERE f1 = xx1.x1) ss;

DELETE FROM xx1 USING LATERAL ( SELECT * FROM int4_tbl WHERE f1 = x1) ss; 

INSERT INTO shipped_view (ordnum, partnum, value) VALUES (0, 1, ( SELECT COST FROM parts WHERE partnum = '1'));

SELECT lead(ten, ( SELECT two FROM tenk1 WHERE s.unique2 = unique2)) OVER (PARTITION BY four ORDER BY ten) FROM tenk1 s WHERE unique2 < 10;

SELECT empno, depname, salary, bonus, depadj, MIN(bonus) OVER (ORDER BY empno), MAX(depadj) OVER () FROM(
	SELECT *,
		CASE WHEN enroll_date < '2008-01-01' THEN 2008 - extract(YEAR FROM enroll_date) END * 500 AS bonus,
		CASE WHEN
			AVG(salary) OVER (PARTITION BY depname) < salary
		THEN 200 END AS depadj FROM empsalary
)s;

