BEGIN;

CREATE FUNCTION basename (path text)
    RETURNS text
AS $$
    RETURN path.replace(/.* / /, '');
$$
LANGUAGE 'plv8' IMMUTABLE;

COMMIT;

UPDATE
    article a
SET
    title = 'x'
WHERE (a.perm & 8)::bool
