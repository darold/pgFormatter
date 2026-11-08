SELECT
    '\' AS d1,
    '' AS d2;

-- it's a comment
SELECT
    'foo\bar\041baz\',
    E'a\'b',
    'x';

SELECT
    'foox' LIKE 'foo\' COLLATE ignore_accents;

SELECT
    'tricky' AS U&"\" UESCAPE '!';

SELECT
    U&'wrong: \061';

