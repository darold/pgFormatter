-- Geometric operators starting with ? must not be split
SELECT
    l1.s,
    l2.s
FROM
    LSEG_TBL l1,
    LSEG_TBL l2
WHERE
    l1.s ?# l2.s
    AND l1.s ?|| l2.s
    AND l1.s ?-| l2.s;

SELECT
    s
FROM
    LINE_TBL
WHERE
    ?- s
    AND ?| s
    AND p ?- point '(0,0)';

SELECT
    j ? 'a',
    j ?| ARRAY['a'],
    j ?& ARRAY['a'],
    j @? '$.a'
FROM
    t;

