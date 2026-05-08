MERGE INTO wines w
USING new_wine_list s
ON s.winename = w.winename
WHEN NOT MATCHED BY TARGET THEN
  INSERT VALUES(s.winename, s.stock)
WHEN MATCHED AND w.stock != s.stock THEN
  UPDATE SET stock = s.stock
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

MERGE INTO rw_view14  AS t
  USING (VALUES (2, 'Merged row 2'), (3, 'Merged row 3')) AS v(a,b) ON t.a = v.a
  WHEN MATCHED THEN UPDATE SET b = v.b
  WHEN NOT MATCHED THEN INSERT (a,b) VALUES (v.a, v.b);

INSERT INTO notes(payload)
VALUES (
  '{
    "message": "User''s code is ''1x''"
  }'
);

SELECT '["a", {"b":1}]'::jsonb #- '{1,b}';

with result as (insert into brtrigpartcon values (1, 'hi there') returning 1)
  insert into inserttest3 (f3) select * from result;

CREATE POLICY "transport_company_employees_delete_as_company_admin_policy" ON "transport_company_employees" AS PERMISSIVE
    FOR DELETE TO "authenticated"
    USING (EXISTS (
        SELECT
            1
        FROM
            "transport_company_employees" AS admin_membership
        WHERE
            "admin_membership"."employee_profile_id" = app.current_profile_id () AND "admin_membership"."role" = 'admin' AND "admin_membership"."transport_company_id" = "transport_company_employees"."transport_company_id"));
