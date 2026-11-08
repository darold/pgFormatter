--
-- encoding-sensitive tests for jsonpath
--
-- We provide expected-results files for UTF8 (jsonpath_encoding.out)
-- and for SQL_ASCII (jsonpath_encoding_1.out).  Skip otherwise.
SELECT
    getdatabaseencoding()
    NOT IN ('UTF8', 'SQL_ASCII') AS skip_test \gset

\if :skip_test
\quit
\endif
SELECT
    getdatabaseencoding();

-- just to label the results files
-- checks for double-quoted values
-- basic unicode input
SELECT
    '"\u"'::jsonpath;

-- ERROR, incomplete escape
SELECT
    '"\u00"'::jsonpath;

-- ERROR, incomplete escape
SELECT
    '"\u000g"'::jsonpath;

-- ERROR, g is not a hex digit
SELECT
    '"\u0000"'::jsonpath;

-- OK, legal escape
SELECT
    '"\uaBcD"'::jsonpath;

-- OK, uppercase and lower case both OK
-- handling of unicode surrogate pairs
SELECT
    '"\ud83d\ude04\ud83d\udc36"'::jsonpath AS correct_in_utf8;

SELECT
    '"\ud83d\ud83d"'::jsonpath;

-- 2 high surrogates in a row
SELECT
    '"\ude04\ud83d"'::jsonpath;

-- surrogates in wrong order
SELECT
    '"\ud83dX"'::jsonpath;

-- orphan high surrogate
SELECT
    '"\ude04X"'::jsonpath;

-- orphan low surrogate
--handling of simple unicode escapes
SELECT
    '"the Copyright \u00a9 sign"'::jsonpath AS correct_in_utf8;

SELECT
    '"dollar \u0024 character"'::jsonpath AS correct_everywhere;

SELECT
    '"dollar \\u0024 character"'::jsonpath AS not_an_escape;

SELECT
    '"null \u0000 escape"'::jsonpath AS not_unescaped;

SELECT
    '"null \\u0000 escape"'::jsonpath AS not_an_escape;

-- checks for quoted key names
-- basic unicode input
SELECT
    '$."\u"'::jsonpath;

-- ERROR, incomplete escape
SELECT
    '$."\u00"'::jsonpath;

-- ERROR, incomplete escape
SELECT
    '$."\u000g"'::jsonpath;

-- ERROR, g is not a hex digit
SELECT
    '$."\u0000"'::jsonpath;

-- OK, legal escape
SELECT
    '$."\uaBcD"'::jsonpath;

-- OK, uppercase and lower case both OK
-- handling of unicode surrogate pairs
SELECT
    '$."\ud83d\ude04\ud83d\udc36"'::jsonpath AS correct_in_utf8;

SELECT
    '$."\ud83d\ud83d"'::jsonpath;

-- 2 high surrogates in a row
SELECT
    '$."\ude04\ud83d"'::jsonpath;

-- surrogates in wrong order
SELECT
    '$."\ud83dX"'::jsonpath;

-- orphan high surrogate
SELECT
    '$."\ude04X"'::jsonpath;

-- orphan low surrogate
--handling of simple unicode escapes
SELECT
    '$."the Copyright \u00a9 sign"'::jsonpath AS correct_in_utf8;

SELECT
    '$."dollar \u0024 character"'::jsonpath AS correct_everywhere;

SELECT
    '$."dollar \\u0024 character"'::jsonpath AS not_an_escape;

SELECT
    '$."null \u0000 escape"'::jsonpath AS not_unescaped;

SELECT
    '$."null \\u0000 escape"'::jsonpath AS not_an_escape;

