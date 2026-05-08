MERGE INTO wines w
    USING new_wine_list s ON s.winename = w.winename
    WHEN NOT MATCHED BY TARGET THEN
        INSERT VALUES (s.winename, s.stock)
    WHEN MATCHED AND w.stock != s.stock THEN
        UPDATE SET stock = s.stock
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE;

MERGE INTO rw_view14 AS t
    USING ( VALUES (2, 'Merged row 2'), (3, 'Merged row 3')) AS v (a, b) ON t.a = v.a
    WHEN MATCHED THEN
        UPDATE SET b = v.b
    WHEN NOT MATCHED THEN
        INSERT (a, b) VALUES (v.a, v.b);

INSERT INTO notes (payload)
    VALUES ('{
    "message": "User''s code is ''1x''"
  }');

SELECT
    '["a", {"b":1}]'::jsonb #- '{1,b}';

WITH result AS (
INSERT INTO brtrigpartcon
        VALUES (1, 'hi there')
    RETURNING
        1)
    INSERT INTO inserttest3 (f3)
    SELECT
        *
    FROM
        result;

