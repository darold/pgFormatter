-- Issue #351: one key/value pair per line in json_build_object/jsonb_build_object
SELECT
    json_agg(
        json_build_object(
            'a', a.id,
            'b', b.id,
            'c', c.id
        )
    )
FROM
    a
    JOIN b ON a.id = b.id
    JOIN c ON c.id = b.id;

SELECT
    jsonb_build_object(
        'a', 1,
        'b', jsonb_build_object(
            'x', 1,
            'y', ARRAY[9, 8, 7]::int[]
        )
    ) AS j;

SELECT
    json_build_object(
        'n', (
            SELECT
                count(*)
            FROM a
            WHERE
                id > 0),
        'c', CASE WHEN x > 1 THEN
            'y'
        ELSE
            'z'
        END,
        'k', coalesce(y, 0)
    )
FROM
    t;

SELECT
    coalesce(
        json_agg(
            jsonb_build_object(
                'id', id,
                'n', name
            )
            ORDER BY id
        ) FILTER (WHERE id > 0),
        '[]'
    )
FROM
    t;

SELECT
    json_build_object(
        VARIADIC '{a,1,b,2}'::text[]
    ),
    json_build_object(),
    json_build_array(1, 2),
    json_agg(x)
FROM
    t;

CREATE FUNCTION f ()
    RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN json_build_object(
        'a', 1,
        'b', 2
    );
END
$$;

