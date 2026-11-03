-- Geometric operators starting with ? must not be split
SELECT l1.s, l2.s FROM LSEG_TBL l1, LSEG_TBL l2 WHERE l1.s ?# l2.s AND l1.s ?|| l2.s AND l1.s ?-| l2.s;
SELECT s FROM LINE_TBL WHERE ?- s AND ?| s AND p ?- point '(0,0)';
SELECT j ? 'a', j ?| ARRAY['a'], j ?& ARRAY['a'], j @? '$.a' FROM t;
CREATE FUNCTION preserve_trigger_case() RETURNS tRiGgEr
LANGUAGE plpgsql AS $$
BEGIN
    RETURN NEW;
END;
$$;

CREATE trigger preserve_trigger_case
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION preserve_trigger_case();
-- A scalar sub-SELECT used as a row of a VALUES list keeps both pairs of
-- parentheses after another row: the outer pair is the row constructor.
SELECT * FROM (VALUES (1), ((SELECT 2))) AS t (i);
SELECT * FROM (VALUES (1), (2), ((SELECT 3))) AS t (i);
SELECT * FROM (VALUES ((SELECT 1)), ((SELECT 2))) AS t (i);
SELECT * FROM (VALUES (1, 'a'), ((SELECT 2), 'b')) AS t (i, j);

-- A redundant pair is still removed.
SELECT * FROM (VALUES (1), ((2))) AS t (i);
