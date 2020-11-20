-- encoding-sensitive tests for json and jsonb
-- first json
-- basic unicode input
SELECT
    '"\u"'::json;

-- ERROR, incomplete escape
SELECT
    '"\u00"'::json;

-- ERROR, incomplete escape
SELECT
    '"\u000g"'::json;

-- ERROR, g is not a hex digit
SELECT
    '"\u0000"'::json;

-- OK, legal escape
SELECT
    '"\uaBcD"'::json;

-- OK, uppercase and lower case both OK
-- handling of unicode surrogate pairs
SELECT
    json '{ "a":  "\ud83d\ude04\ud83d\udc36" }' -> 'a' AS correct_in_utf8;

SELECT
    json '{ "a":  "\ud83d\ud83d" }' -> 'a';

-- 2 high surrogates in a row
SELECT
    json '{ "a":  "\ude04\ud83d" }' -> 'a';

-- surrogates in wrong order
SELECT
    json '{ "a":  "\ud83dX" }' -> 'a';

-- orphan high surrogate
SELECT
    json '{ "a":  "\ude04X" }' -> 'a';

-- orphan low surrogate
--handling of simple unicode escapes
SELECT
    json '{ "a":  "the Copyright \u00a9 sign" }' AS correct_in_utf8;

SELECT
    json '{ "a":  "dollar \u0024 character" }' AS correct_everywhere;

SELECT
    json '{ "a":  "dollar \\u0024 character" }' AS not_an_escape;

SELECT
    json '{ "a":  "null \u0000 escape" }' AS not_unescaped;

SELECT
    json '{ "a":  "null \\u0000 escape" }' AS not_an_escape;

SELECT
    json '{ "a":  "the Copyright \u00a9 sign" }' ->> 'a' AS correct_in_utf8;

SELECT
    json '{ "a":  "dollar \u0024 character" }' ->> 'a' AS correct_everywhere;

SELECT
    json '{ "a":  "dollar \\u0024 character" }' ->> 'a' AS not_an_escape;

SELECT
    json '{ "a":  "null \u0000 escape" }' ->> 'a' AS fails;

SELECT
    json '{ "a":  "null \\u0000 escape" }' ->> 'a' AS not_an_escape;

-- then jsonb
-- basic unicode input
SELECT
    '"\u"'::jsonb;

-- ERROR, incomplete escape
SELECT
    '"\u00"'::jsonb;

-- ERROR, incomplete escape
SELECT
    '"\u000g"'::jsonb;

-- ERROR, g is not a hex digit
SELECT
    '"\u0045"'::jsonb;

-- OK, legal escape
SELECT
    '"\u0000"'::jsonb;

-- ERROR, we don't support U+0000
-- use octet_length here so we don't get an odd unicode char in the
-- output
SELECT
    octet_length('"\uaBcD"'::jsonb::text);

-- OK, uppercase and lower case both OK
-- handling of unicode surrogate pairs
SELECT
    octet_length((jsonb '{ "a":  "\ud83d\ude04\ud83d\udc36" }' -> 'a')::text) AS correct_in_utf8;

SELECT
    jsonb '{ "a":  "\ud83d\ud83d" }' -> 'a';

-- 2 high surrogates in a row
SELECT
    jsonb '{ "a":  "\ude04\ud83d" }' -> 'a';

-- surrogates in wrong order
SELECT
    jsonb '{ "a":  "\ud83dX" }' -> 'a';

-- orphan high surrogate
SELECT
    jsonb '{ "a":  "\ude04X" }' -> 'a';

-- orphan low surrogate
-- handling of simple unicode escapes
SELECT
    jsonb '{ "a":  "the Copyright \u00a9 sign" }' AS correct_in_utf8;

SELECT
    jsonb '{ "a":  "dollar \u0024 character" }' AS correct_everywhere;

SELECT
    jsonb '{ "a":  "dollar \\u0024 character" }' AS not_an_escape;

SELECT
    jsonb '{ "a":  "null \u0000 escape" }' AS fails;

SELECT
    jsonb '{ "a":  "null \\u0000 escape" }' AS not_an_escape;

SELECT
    jsonb '{ "a":  "the Copyright \u00a9 sign" }' ->> 'a' AS correct_in_utf8;

SELECT
    jsonb '{ "a":  "dollar \u0024 character" }' ->> 'a' AS correct_everywhere;

SELECT
    jsonb '{ "a":  "dollar \\u0024 character" }' ->> 'a' AS not_an_escape;

SELECT
    jsonb '{ "a":  "null \u0000 escape" }' ->> 'a' AS fails;

SELECT
    jsonb '{ "a":  "null \\u0000 escape" }' ->> 'a' AS not_an_escape;

