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
    '''\b\f\r\n\t\v\"\''\\'' '::jsonpath;

SELECT
    '"\x50\u0067\u{53}\u{051}\u{00004C}"'::jsonpath;

SELECT
    '''\x50\u0067\u{53}\u{051}\u{00004C}'''::jsonpath;

SELECT
    '$.foo\x50\u0067\u{53}\u{051}\u{00004C}\t\"bar'::jsonpath;

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

SELECT
    '0'::jsonpath;

SELECT
    '00'::jsonpath;

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
    '1e'::jsonpath;

SELECT
    '1.e'::jsonpath;

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

