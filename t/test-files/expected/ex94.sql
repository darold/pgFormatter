-- Issue #434: delimited identifiers containing "" or ' must not desynchronize
-- quoting for the statements after them
SELECT
    c
FROM
    t AS """";

SELECT
    "a"
FROM
    t;

SELECT
    c
FROM
    t
WHERE
    "'" = 'x';

SELECT
    "a"
FROM
    t;

SELECT
    "it's"."x""y",
    s."t'x",
    "a""b" AS """"
FROM
    "o'k"."t""t" AS "z'z"
WHERE
    "'" = 'x'
    AND c = 'say "a''b" and "c''d"';

SELECT
    "f'n" (1),
    "a"
FROM
    t;

-- comment with "it's" and """"
/* block "it's" """" */
SELECT
    "a"
FROM
    t;

COMMENT ON COLUMN "t'x"."c""c" IS 'it''s';

SELECT
    E'it\'s "a' AS "x'y",
    date'2020-01-01' AS """d""",
    "a"
FROM
    t;

CREATE FUNCTION "f'x" ()
    RETURNS int
    LANGUAGE plpgsql
    AS $$
DECLARE
    "v'v" int := 1;
BEGIN
    SELECT
        "a""b"
    INTO
        "v'v"
    FROM
        t AS """"
    WHERE
        "'" = 'x';
    RETURN "v'v";
END
$$;

SELECT
    "a"
FROM
    t;

