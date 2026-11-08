--jsonpath io
SELECT
    ''::jsonpath;

SELECT
    '$'::jsonpath;

SELECT
    'strict $'::jsonpath;

SELECT
    'lax $'::jsonpath;

SELECT
    '$.a'::jsonpath;

SELECT
    '$.a.v'::jsonpath;

SELECT
    '$.a.*'::jsonpath;

SELECT
    '$.*[*]'::jsonpath;

SELECT
    '$.a[*]'::jsonpath;

SELECT
    '$.a[*][*]'::jsonpath;

SELECT
    '$[*]'::jsonpath;

SELECT
    '$[0]'::jsonpath;

SELECT
    '$[*][0]'::jsonpath;

SELECT
    '$[*].a'::jsonpath;

SELECT
    '$[*][0].a.b'::jsonpath;

SELECT
    '$.a.**.b'::jsonpath;

SELECT
    '$.a.**{2}.b'::jsonpath;

SELECT
    '$.a.**{2 to 2}.b'::jsonpath;

SELECT
    '$.a.**{2 to 5}.b'::jsonpath;

SELECT
    '$.a.**{0 to 5}.b'::jsonpath;

SELECT
    '$.a.**{5 to last}.b'::jsonpath;

SELECT
    '$.a.**{last}.b'::jsonpath;

SELECT
    '$.a.**{last to 5}.b'::jsonpath;

SELECT
    '$+1'::jsonpath;

SELECT
    '$-1'::jsonpath;

SELECT
    '$--+1'::jsonpath;

SELECT
    '$.a/+-1'::jsonpath;

SELECT
    '1 * 2 + 4 % -3 != false'::jsonpath;

SELECT
    '"\b\f\r\n\t\v\"\'' \\ "'::jsonpath;

SELECT
    '"\x50\u0067\u{53}\u{051}\u{00004C}"'::jsonpath;

SELECT
    '$.foo\x50\u0067\u{53}\u{051}\u{00004C}\t\"bar'::jsonpath;

SELECT
    '"\z"'::jsonpath;

-- unrecognized escape is just the literal char
SELECT
    '$.g ? ($.a == 1)'::jsonpath;

SELECT
    '$.g ? (@ == 1)'::jsonpath;

SELECT
    '$.g ? (@.a == 1)'::jsonpath;

SELECT
    '$.g ? (@.a == 1 || @.a == 4)'::jsonpath;

SELECT
    '$.g ? (@.a == 1 && @.a == 4)'::jsonpath;

SELECT
    '$.g ? (@.a == 1 || @.a == 4 && @.b == 7)'::jsonpath;

SELECT
    '$.g ? (@.a == 1 || !(@.a == 4) && @.b == 7)'::jsonpath;

SELECT
    '$.g ? (@.a == 1 || !(@.x >= 123 || @.a == 4) && @.b == 7)'::jsonpath;

SELECT
    '$.g ? (@.x >= @[*]?(@.a > "abc"))'::jsonpath;

SELECT
    '$.g ? ((@.x >= 123 || @.a == 4) is unknown)'::jsonpath;

SELECT
    '$.g ? (exists (@.x))'::jsonpath;

SELECT
    '$.g ? (exists (@.x ? (@ == 14)))'::jsonpath;

SELECT
    '$.g ? ((@.x >= 123 || @.a == 4) && exists (@.x ? (@ == 14)))'::jsonpath;

SELECT
    '$.g ? (+@.x >= +-(+@.a + 2))'::jsonpath;

SELECT
    '$a'::jsonpath;

SELECT
    '$a.b'::jsonpath;

SELECT
    '$a[*]'::jsonpath;

SELECT
    '$.g ? (@.zip == $zip)'::jsonpath;

SELECT
    '$.a[1,2, 3 to 16]'::jsonpath;

SELECT
    '$.a[$a + 1, ($b[*]) to -($[0] * 2)]'::jsonpath;

SELECT
    '$.a[$.a.size() - 3]'::jsonpath;

SELECT
    'last'::jsonpath;

SELECT
    '"last"'::jsonpath;

SELECT
    '$.last'::jsonpath;

SELECT
    '$ ? (last > 0)'::jsonpath;

SELECT
    '$[last]'::jsonpath;

SELECT
    '$[$[0] ? (last > 0)]'::jsonpath;

SELECT
    'null.type()'::jsonpath;

SELECT
    '1.type()'::jsonpath;

SELECT
    '(1).type()'::jsonpath;

SELECT
    '1.2.type()'::jsonpath;

SELECT
    '"aaa".type()'::jsonpath;

SELECT
    'true.type()'::jsonpath;

SELECT
    '$.double().floor().ceiling().abs()'::jsonpath;

SELECT
    '$.keyvalue().key'::jsonpath;

SELECT
    '$.datetime()'::jsonpath;

SELECT
    '$.datetime("datetime template")'::jsonpath;

SELECT
    '$.bigint().integer().number().decimal()'::jsonpath;

SELECT
    '$.boolean()'::jsonpath;

SELECT
    '$.date()'::jsonpath;

SELECT
    '$.decimal(4,2)'::jsonpath;

SELECT
    '$.string()'::jsonpath;

SELECT
    '$.replace("hello","bye")'::jsonpath;

SELECT
    '$.lower()'::jsonpath;

SELECT
    '$.upper()'::jsonpath;

SELECT
    '$.lower().upper().lower().replace("hello","bye")'::jsonpath;

SELECT
    '$.ltrim()'::jsonpath;

SELECT
    '$.ltrim("xyz")'::jsonpath;

SELECT
    '$.rtrim()'::jsonpath;

SELECT
    '$.rtrim("xyz")'::jsonpath;

SELECT
    '$.btrim()'::jsonpath;

SELECT
    '$.btrim("xyz")'::jsonpath;

SELECT
    '$.initcap()'::jsonpath;

SELECT
    '$.split_part("~@~", 2)'::jsonpath;

-- Parse errors
SELECT
    '$.replace("hello")'::jsonpath;

SELECT
    '$.replace()'::jsonpath;

SELECT
    '$.replace("hello","bye","extra")'::jsonpath;

SELECT
    '$.split_part("~@~")'::jsonpath;

SELECT
    '$.split_part()'::jsonpath;

SELECT
    '$.split_part("~@~", "hi")'::jsonpath;

SELECT
    '$.split_part("~@~", 2, "extra")'::jsonpath;

SELECT
    '$.lower("hi")'::jsonpath;

SELECT
    '$.upper("hi")'::jsonpath;

SELECT
    '$.initcap("hi")'::jsonpath;

SELECT
    '$.ltrim(42)'::jsonpath;

SELECT
    '$.ltrim("x", "y")'::jsonpath;

SELECT
    '$.rtrim(42)'::jsonpath;

SELECT
    '$.rtrim("x", "y")'::jsonpath;

SELECT
    '$.trim(42)'::jsonpath;

SELECT
    '$.trim("x", "y")'::jsonpath;

-- Verify method keywords work as object key names
SELECT
    '$.lower'::jsonpath;

SELECT
    '$.upper'::jsonpath;

SELECT
    '$.initcap'::jsonpath;

SELECT
    '$.replace'::jsonpath;

SELECT
    '$.split_part'::jsonpath;

SELECT
    '$.ltrim'::jsonpath;

SELECT
    '$.rtrim'::jsonpath;

SELECT
    '$.btrim'::jsonpath;

SELECT
    '$.time()'::jsonpath;

SELECT
    '$.time(6)'::jsonpath;

SELECT
    '$.time_tz()'::jsonpath;

SELECT
    '$.time_tz(4)'::jsonpath;

SELECT
    '$.timestamp()'::jsonpath;

SELECT
    '$.timestamp(2)'::jsonpath;

SELECT
    '$.timestamp_tz()'::jsonpath;

SELECT
    '$.timestamp_tz(0)'::jsonpath;

SELECT
    '$ ? (@ starts with "abc")'::jsonpath;

SELECT
    '$ ? (@ starts with $var)'::jsonpath;

SELECT
    '$ ? (@ like_regex "(invalid pattern")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "i")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "is")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "isim")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "xsms")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "q")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "iq")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "smixq")'::jsonpath;

SELECT
    '$ ? (@ like_regex "pattern" flag "a")'::jsonpath;

SELECT
    '$ < 1'::jsonpath;

SELECT
    '($ < 1) || $.a.b <= $x'::jsonpath;

SELECT
    '@ + 1'::jsonpath;

SELECT
    '($).a.b'::jsonpath;

SELECT
    '($.a.b).c.d'::jsonpath;

SELECT
    '($.a.b + -$.x.y).c.d'::jsonpath;

SELECT
    '(-+$.a.b).c.d'::jsonpath;

SELECT
    '1 + ($.a.b + 2).c.d'::jsonpath;

SELECT
    '1 + ($.a.b > 2).c.d'::jsonpath;

SELECT
    '($)'::jsonpath;

SELECT
    '(($))'::jsonpath;

SELECT
    '((($ + 1)).a + ((2)).b ? ((((@ > 1)) || (exists(@.c)))))'::jsonpath;

SELECT
    '$ ? (@.a < 1)'::jsonpath;

SELECT
    '$ ? (@.a < -1)'::jsonpath;

SELECT
    '$ ? (@.a < +1)'::jsonpath;

SELECT
    '$ ? (@.a < .1)'::jsonpath;

SELECT
    '$ ? (@.a < -.1)'::jsonpath;

SELECT
    '$ ? (@.a < +.1)'::jsonpath;

SELECT
    '$ ? (@.a < 0.1)'::jsonpath;

SELECT
    '$ ? (@.a < -0.1)'::jsonpath;

SELECT
    '$ ? (@.a < +0.1)'::jsonpath;

SELECT
    '$ ? (@.a < 10.1)'::jsonpath;

SELECT
    '$ ? (@.a < -10.1)'::jsonpath;

SELECT
    '$ ? (@.a < +10.1)'::jsonpath;

SELECT
    '$ ? (@.a < 1e1)'::jsonpath;

SELECT
    '$ ? (@.a < -1e1)'::jsonpath;

SELECT
    '$ ? (@.a < +1e1)'::jsonpath;

SELECT
    '$ ? (@.a < .1e1)'::jsonpath;

SELECT
    '$ ? (@.a < -.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < +.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < 0.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < -0.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < +0.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < 10.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < -10.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < +10.1e1)'::jsonpath;

SELECT
    '$ ? (@.a < 1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < -1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < +1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < .1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < -.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < +.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < 0.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < -0.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < +0.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < 10.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < -10.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < +10.1e-1)'::jsonpath;

SELECT
    '$ ? (@.a < 1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < -1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < +1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < .1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < -.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < +.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < 0.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < -0.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < +0.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < 10.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < -10.1e+1)'::jsonpath;

SELECT
    '$ ? (@.a < +10.1e+1)'::jsonpath;

-- numeric literals
SELECT
    '0'::jsonpath;

SELECT
    '00'::jsonpath;

SELECT
    '0755'::jsonpath;

SELECT
    '0.0'::jsonpath;

SELECT
    '0.000'::jsonpath;

SELECT
    '0.000e1'::jsonpath;

SELECT
    '0.000e2'::jsonpath;

SELECT
    '0.000e3'::jsonpath;

SELECT
    '0.0010'::jsonpath;

SELECT
    '0.0010e-1'::jsonpath;

SELECT
    '0.0010e+1'::jsonpath;

SELECT
    '0.0010e+2'::jsonpath;

SELECT
    '.001'::jsonpath;

SELECT
    '.001e1'::jsonpath;

SELECT
    '1.'::jsonpath;

SELECT
    '1.e1'::jsonpath;

SELECT
    '1a'::jsonpath;

SELECT
    '1e'::jsonpath;

SELECT
    '1.e'::jsonpath;

SELECT
    '1.2a'::jsonpath;

SELECT
    '1.2e'::jsonpath;

SELECT
    '1.2.e'::jsonpath;

SELECT
    '(1.2).e'::jsonpath;

SELECT
    '1e3'::jsonpath;

SELECT
    '1.e3'::jsonpath;

SELECT
    '1.e3.e'::jsonpath;

SELECT
    '1.e3.e4'::jsonpath;

SELECT
    '1.2e3'::jsonpath;

SELECT
    '1.2e3a'::jsonpath;

SELECT
    '1.2.e3'::jsonpath;

SELECT
    '(1.2).e3'::jsonpath;

SELECT
    '1..e'::jsonpath;

SELECT
    '1..e3'::jsonpath;

SELECT
    '(1.).e'::jsonpath;

SELECT
    '(1.).e3'::jsonpath;

SELECT
    '1?(2>3)'::jsonpath;

-- nondecimal
SELECT
    '0b100101'::jsonpath;

SELECT
    '0o273'::jsonpath;

SELECT
    '0x42F'::jsonpath;

-- error cases
SELECT
    '0b'::jsonpath;

SELECT
    '1b'::jsonpath;

SELECT
    '0b0x'::jsonpath;

SELECT
    '0o'::jsonpath;

SELECT
    '1o'::jsonpath;

SELECT
    '0o0x'::jsonpath;

SELECT
    '0x'::jsonpath;

SELECT
    '1x'::jsonpath;

SELECT
    '0x0y'::jsonpath;

-- underscores
SELECT
    '1_000_000'::jsonpath;

SELECT
    '1_2_3'::jsonpath;

SELECT
    '0x1EEE_FFFF'::jsonpath;

SELECT
    '0o2_73'::jsonpath;

SELECT
    '0b10_0101'::jsonpath;

SELECT
    '1_000.000_005'::jsonpath;

SELECT
    '1_000.'::jsonpath;

SELECT
    '.000_005'::jsonpath;

SELECT
    '1_000.5e0_1'::jsonpath;

-- error cases
SELECT
    '_100'::jsonpath;

SELECT
    '100_'::jsonpath;

SELECT
    '100__000'::jsonpath;

SELECT
    '_1_000.5'::jsonpath;

SELECT
    '1_000_.5'::jsonpath;

SELECT
    '1_000._5'::jsonpath;

SELECT
    '1_000.5_'::jsonpath;

SELECT
    '1_000.5e_1'::jsonpath;

-- underscore after prefix not allowed in JavaScript (but allowed in SQL)
SELECT
    '0b_10_0101'::jsonpath;

SELECT
    '0o_273'::jsonpath;

SELECT
    '0x_42F'::jsonpath;

-- test non-error-throwing API
SELECT
    str AS jsonpath,
    pg_input_is_valid (str, 'jsonpath') AS ok,
    errinfo.sql_error_code,
    errinfo.message,
    errinfo.detail,
    errinfo.hint
FROM
    unnest(ARRAY['$ ? (@ like_regex "pattern" flag "smixq")'::text, '$ ? (@ like_regex "pattern" flag "a")', '@ + 1', '00', '1a']) str,
    LATERAL pg_input_error_info (str, 'jsonpath') AS errinfo;

