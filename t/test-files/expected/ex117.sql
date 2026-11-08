SELECT
    v,
    b,
    (v || b) AS concat
FROM
    t;

SELECT
    testtext || testvarchar AS concat,
    concat,
    t.concat
FROM
    t;

SELECT
    a || b
FROM
    t;

CREATE FUNCTION r (t)
    RETURNS t
    AS $$
    SELECT
        $1
$$
LANGUAGE sql
IMMUTABLE;

SELECT
    $$a$$,
    $1;

