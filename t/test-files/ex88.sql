-- A scalar sub-SELECT used as a row of a VALUES list keeps both pairs of
-- parentheses after another row: the outer pair is the row constructor.
SELECT * FROM (VALUES (1), ((SELECT 2))) AS t (i);
SELECT * FROM (VALUES (1), (2), ((SELECT 3))) AS t (i);
SELECT * FROM (VALUES ((SELECT 1)), ((SELECT 2))) AS t (i);
SELECT * FROM (VALUES (1, 'a'), ((SELECT 2), 'b')) AS t (i, j);

-- A redundant pair is still removed.
SELECT * FROM (VALUES (1), ((2))) AS t (i);
