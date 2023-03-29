SELECT
    jsonb '{"a": 12}' @? '$';

SELECT
    jsonb '{"a": 12}' @? '1';

SELECT
    jsonb '{"a": 12}' @? '$.a.b';

SELECT
    jsonb '{"a": 12}' @? '$.b';

SELECT
    jsonb '{"a": 12}' @? '$.a + 2';

SELECT
    jsonb '{"a": 12}' @? '$.b + 2';

SELECT
    jsonb '{"a": {"a": 12}}' @? '$.a.a';

SELECT
    jsonb '{"a": {"a": 12}}' @? '$.*.a';

SELECT
    jsonb '{"b": {"a": 12}}' @? '$.*.a';

SELECT
    jsonb '{"b": {"a": 12}}' @? '$.*.b';

SELECT
    jsonb '{"b": {"a": 12}}' @? 'strict $.*.b';

SELECT
    jsonb '{}' @? '$.*';

SELECT
    jsonb '{"a": 1}' @? '$.*';

SELECT
    jsonb '{"a": {"b": 1}}' @? 'lax $.**{1}';

SELECT
    jsonb '{"a": {"b": 1}}' @? 'lax $.**{2}';

SELECT
    jsonb '{"a": {"b": 1}}' @? 'lax $.**{3}';

SELECT
    jsonb '[]' @? '$[*]';

SELECT
    jsonb '[1]' @? '$[*]';

SELECT
    jsonb '[1]' @? '$[1]';

SELECT
    jsonb '[1]' @? 'strict $[1]';

SELECT
    jsonb_path_query('[1]', 'strict $[1]');

SELECT
    jsonb_path_query('[1]', 'strict $[1]', silent => TRUE);

SELECT
    jsonb '[1]' @? 'lax $[10000000000000000]';

SELECT
    jsonb '[1]' @? 'strict $[10000000000000000]';

SELECT
    jsonb_path_query('[1]', 'lax $[10000000000000000]');

SELECT
    jsonb_path_query('[1]', 'strict $[10000000000000000]');

SELECT
    jsonb '[1]' @? '$[0]';

SELECT
    jsonb '[1]' @? '$[0.3]';

SELECT
    jsonb '[1]' @? '$[0.5]';

SELECT
    jsonb '[1]' @? '$[0.9]';

SELECT
    jsonb '[1]' @? '$[1.2]';

SELECT
    jsonb '[1]' @? 'strict $[1.2]';

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,5]}' @? '$ ? (@.a[*] >  @.b[*])';

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,5]}' @? '$ ? (@.a[*] >= @.b[*])';

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,"5"]}' @? '$ ? (@.a[*] >= @.b[*])';

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,"5"]}' @? 'strict $ ? (@.a[*] >= @.b[*])';

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,null]}' @? '$ ? (@.a[*] >= @.b[*])';

SELECT
    jsonb '1' @? '$ ? ((@ == "1") is unknown)';

SELECT
    jsonb '1' @? '$ ? ((@ == 1) is unknown)';

SELECT
    jsonb '[{"a": 1}, {"a": 2}]' @? '$[0 to 1] ? (@.a > 1)';

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, 3]', 'lax $[*].a', silent => FALSE);

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, 3]', 'lax $[*].a', silent => TRUE);

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, 3]', 'strict $[*].a', silent => FALSE);

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, 3]', 'strict $[*].a', silent => TRUE);

SELECT
    jsonb_path_query('1', 'lax $.a');

SELECT
    jsonb_path_query('1', 'strict $.a');

SELECT
    jsonb_path_query('1', 'strict $.*');

SELECT
    jsonb_path_query('1', 'strict $.a', silent => TRUE);

SELECT
    jsonb_path_query('1', 'strict $.*', silent => TRUE);

SELECT
    jsonb_path_query('[]', 'lax $.a');

SELECT
    jsonb_path_query('[]', 'strict $.a');

SELECT
    jsonb_path_query('[]', 'strict $.a', silent => TRUE);

SELECT
    jsonb_path_query('{}', 'lax $.a');

SELECT
    jsonb_path_query('{}', 'strict $.a');

SELECT
    jsonb_path_query('{}', 'strict $.a', silent => TRUE);

SELECT
    jsonb_path_query('1', 'strict $[1]');

SELECT
    jsonb_path_query('1', 'strict $[*]');

SELECT
    jsonb_path_query('[]', 'strict $[1]');

SELECT
    jsonb_path_query('[]', 'strict $["a"]');

SELECT
    jsonb_path_query('1', 'strict $[1]', silent => TRUE);

SELECT
    jsonb_path_query('1', 'strict $[*]', silent => TRUE);

SELECT
    jsonb_path_query('[]', 'strict $[1]', silent => TRUE);

SELECT
    jsonb_path_query('[]', 'strict $["a"]', silent => TRUE);

SELECT
    jsonb_path_query('{"a": 12, "b": {"a": 13}}', '$.a');

SELECT
    jsonb_path_query('{"a": 12, "b": {"a": 13}}', '$.b');

SELECT
    jsonb_path_query('{"a": 12, "b": {"a": 13}}', '$.*');

SELECT
    jsonb_path_query('{"a": 12, "b": {"a": 13}}', 'lax $.*.a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[*].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[*].*');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[0].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[1].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[2].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[0,1].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[0 to 10].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}]', 'lax $[0 to 10 / 0].a');

SELECT
    jsonb_path_query('[12, {"a": 13}, {"b": 14}, "ccc", true]', '$[2.5 - 1 to $.size() - 2]');

SELECT
    jsonb_path_query('1', 'lax $[0]');

SELECT
    jsonb_path_query('1', 'lax $[*]');

SELECT
    jsonb_path_query('[1]', 'lax $[0]');

SELECT
    jsonb_path_query('[1]', 'lax $[*]');

SELECT
    jsonb_path_query('[1,2,3]', 'lax $[*]');

SELECT
    jsonb_path_query('[1,2,3]', 'strict $[*].a');

SELECT
    jsonb_path_query('[1,2,3]', 'strict $[*].a', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$[last]');

SELECT
    jsonb_path_query('[]', '$[last ? (exists(last))]');

SELECT
    jsonb_path_query('[]', 'strict $[last]');

SELECT
    jsonb_path_query('[]', 'strict $[last]', silent => TRUE);

SELECT
    jsonb_path_query('[1]', '$[last]');

SELECT
    jsonb_path_query('[1,2,3]', '$[last]');

SELECT
    jsonb_path_query('[1,2,3]', '$[last - 1]');

SELECT
    jsonb_path_query('[1,2,3]', '$[last ? (@.type() == "number")]');

SELECT
    jsonb_path_query('[1,2,3]', '$[last ? (@.type() == "string")]');

SELECT
    jsonb_path_query('[1,2,3]', '$[last ? (@.type() == "string")]', silent => TRUE);

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$ ? (@.a < $value)');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$ ? (@.a < $value)', '1');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$ ? (@.a < $value)', '[{"value" : 13}]');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$ ? (@.a < $value)', '{"value" : 13}');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$ ? (@.a < $value)', '{"value" : 8}');

SELECT
    *
FROM
    jsonb_path_query('{"a": 10}', '$.a ? (@ < $value)', '{"value" : 13}');

SELECT
    *
FROM
    jsonb_path_query('[10,11,12,13,14,15]', '$[*] ? (@ < $value)', '{"value" : 13}');

SELECT
    *
FROM
    jsonb_path_query('[10,11,12,13,14,15]', '$[0,1] ? (@ < $x.value)', '{"x": {"value" : 13}}');

SELECT
    *
FROM
    jsonb_path_query('[10,11,12,13,14,15]', '$[0 to 2] ? (@ < $value)', '{"value" : 15}');

SELECT
    *
FROM
    jsonb_path_query('[1,"1",2,"2",null]', '$[*] ? (@ == "1")');

SELECT
    *
FROM
    jsonb_path_query('[1,"1",2,"2",null]', '$[*] ? (@ == $value)', '{"value" : "1"}');

SELECT
    *
FROM
    jsonb_path_query('[1,"1",2,"2",null]', '$[*] ? (@ == $value)', '{"value" : null}');

SELECT
    *
FROM
    jsonb_path_query('[1, "2", null]', '$[*] ? (@ != null)');

SELECT
    *
FROM
    jsonb_path_query('[1, "2", null]', '$[*] ? (@ == null)');

SELECT
    *
FROM
    jsonb_path_query('{}', '$ ? (@ == @)');

SELECT
    *
FROM
    jsonb_path_query('[]', 'strict $ ? (@ == @)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{0}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{0 to last}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{1}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{1 to last}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{2}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{2 to last}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{3 to last}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{last}');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{0}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{1}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{0 to last}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{1 to last}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"b": 1}}', 'lax $.**{1 to 2}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{0}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{1}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{0 to last}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{1 to last}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{1 to 2}.b ? (@ > 0)');

SELECT
    jsonb_path_query('{"a": {"c": {"b": 1}}}', 'lax $.**{2 to 3}.b ? (@ > 0)');

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**{0}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**{1}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**{0 to last}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**{1 to last}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"b": 1}}' @? '$.**{1 to 2}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{0}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{1}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{0 to last}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{1 to last}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{1 to 2}.b ? ( @ > 0)';

SELECT
    jsonb '{"a": {"c": {"b": 1}}}' @? '$.**{2 to 3}.b ? ( @ > 0)';

SELECT
    jsonb_path_query('{"g": {"x": 2}}', '$.g ? (exists (@.x))');

SELECT
    jsonb_path_query('{"g": {"x": 2}}', '$.g ? (exists (@.y))');

SELECT
    jsonb_path_query('{"g": {"x": 2}}', '$.g ? (exists (@.x ? (@ >= 2) ))');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'lax $.g ? (exists (@.x))');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'lax $.g ? (exists (@.x + "3"))');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'lax $.g ? ((exists (@.x + "3")) is unknown)');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'strict $.g[*] ? (exists (@.x))');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'strict $.g[*] ? ((exists (@.x)) is unknown)');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'strict $.g ? (exists (@[*].x))');

SELECT
    jsonb_path_query('{"g": [{"x": 2}, {"y": 3}]}', 'strict $.g ? ((exists (@[*].x)) is unknown)');

--test ternary logic
SELECT
    x,
    y,
    jsonb_path_query('[true, false, null]', '$[*] ? (@ == true  &&  ($x == true && $y == true) ||
				 @ == false && !($x == true && $y == true) ||
				 @ == null  &&  ($x == true && $y == true) is unknown)', jsonb_build_object('x', x, 'y', y)) AS "x && y"
FROM (
    VALUES (jsonb 'true'),
        ('false'),
        ('"null"')) x (x),
    (
        VALUES (jsonb 'true'), ('false'), ('"null"')) y (y);

SELECT
    x,
    y,
    jsonb_path_query('[true, false, null]', '$[*] ? (@ == true  &&  ($x == true || $y == true) ||
				 @ == false && !($x == true || $y == true) ||
				 @ == null  &&  ($x == true || $y == true) is unknown)', jsonb_build_object('x', x, 'y', y)) AS "x || y"
FROM (
    VALUES (jsonb 'true'),
        ('false'),
        ('"null"')) x (x),
    (
        VALUES (jsonb 'true'), ('false'), ('"null"')) y (y);

SELECT
    jsonb '{"a": 1, "b":1}' @? '$ ? (@.a == @.b)';

SELECT
    jsonb '{"c": {"a": 1, "b":1}}' @? '$ ? (@.a == @.b)';

SELECT
    jsonb '{"c": {"a": 1, "b":1}}' @? '$.c ? (@.a == @.b)';

SELECT
    jsonb '{"c": {"a": 1, "b":1}}' @? '$.c ? ($.c.a == @.b)';

SELECT
    jsonb '{"c": {"a": 1, "b":1}}' @? '$.* ? (@.a == @.b)';

SELECT
    jsonb '{"a": 1, "b":1}' @? '$.** ? (@.a == @.b)';

SELECT
    jsonb '{"c": {"a": 1, "b":1}}' @? '$.** ? (@.a == @.b)';

SELECT
    jsonb_path_query('{"c": {"a": 2, "b":1}}', '$.** ? (@.a == 1 + 1)');

SELECT
    jsonb_path_query('{"c": {"a": 2, "b":1}}', '$.** ? (@.a == (1 + 1))');

SELECT
    jsonb_path_query('{"c": {"a": 2, "b":1}}', '$.** ? (@.a == @.b + 1)');

SELECT
    jsonb_path_query('{"c": {"a": 2, "b":1}}', '$.** ? (@.a == (@.b + 1))');

SELECT
    jsonb '{"c": {"a": -1, "b":1}}' @? '$.** ? (@.a == - 1)';

SELECT
    jsonb '{"c": {"a": -1, "b":1}}' @? '$.** ? (@.a == -1)';

SELECT
    jsonb '{"c": {"a": -1, "b":1}}' @? '$.** ? (@.a == -@.b)';

SELECT
    jsonb '{"c": {"a": -1, "b":1}}' @? '$.** ? (@.a == - @.b)';

SELECT
    jsonb '{"c": {"a": 0, "b":1}}' @? '$.** ? (@.a == 1 - @.b)';

SELECT
    jsonb '{"c": {"a": 2, "b":1}}' @? '$.** ? (@.a == 1 - - @.b)';

SELECT
    jsonb '{"c": {"a": 0, "b":1}}' @? '$.** ? (@.a == 1 - +@.b)';

SELECT
    jsonb '[1,2,3]' @? '$ ? (+@[*] > +2)';

SELECT
    jsonb '[1,2,3]' @? '$ ? (+@[*] > +3)';

SELECT
    jsonb '[1,2,3]' @? '$ ? (-@[*] < -2)';

SELECT
    jsonb '[1,2,3]' @? '$ ? (-@[*] < -3)';

SELECT
    jsonb '1' @? '$ ? ($ > 0)';

-- arithmetic errors
SELECT
    jsonb_path_query('[1,2,0,3]', '$[*] ? (2 / @ > 0)');

SELECT
    jsonb_path_query('[1,2,0,3]', '$[*] ? ((2 / @ > 0) is unknown)');

SELECT
    jsonb_path_query('0', '1 / $');

SELECT
    jsonb_path_query('0', '1 / $ + 2');

SELECT
    jsonb_path_query('0', '-(3 + 1 % $)');

SELECT
    jsonb_path_query('1', '$ + "2"');

SELECT
    jsonb_path_query('[1, 2]', '3 * $');

SELECT
    jsonb_path_query('"a"', '-$');

SELECT
    jsonb_path_query('[1,"2",3]', '+$');

SELECT
    jsonb_path_query('1', '$ + "2"', silent => TRUE);

SELECT
    jsonb_path_query('[1, 2]', '3 * $', silent => TRUE);

SELECT
    jsonb_path_query('"a"', '-$', silent => TRUE);

SELECT
    jsonb_path_query('[1,"2",3]', '+$', silent => TRUE);

SELECT
    jsonb '["1",2,0,3]' @? '-$[*]';

SELECT
    jsonb '[1,"2",0,3]' @? '-$[*]';

SELECT
    jsonb '["1",2,0,3]' @? 'strict -$[*]';

SELECT
    jsonb '[1,"2",0,3]' @? 'strict -$[*]';

-- unwrapping of operator arguments in lax mode
SELECT
    jsonb_path_query('{"a": [2]}', 'lax $.a * 3');

SELECT
    jsonb_path_query('{"a": [2]}', 'lax $.a + 3');

SELECT
    jsonb_path_query('{"a": [2, 3, 4]}', 'lax -$.a');

-- should fail
SELECT
    jsonb_path_query('{"a": [1, 2]}', 'lax $.a * 3');

SELECT
    jsonb_path_query('{"a": [1, 2]}', 'lax $.a * 3', silent => TRUE);

-- extension: boolean expressions
SELECT
    jsonb_path_query('2', '$ > 1');

SELECT
    jsonb_path_query('2', '$ <= 1');

SELECT
    jsonb_path_query('2', '$ == "2"');

SELECT
    jsonb '2' @? '$ == "2"';

SELECT
    jsonb '2' @@ '$ > 1';

SELECT
    jsonb '2' @@ '$ <= 1';

SELECT
    jsonb '2' @@ '$ == "2"';

SELECT
    jsonb '2' @@ '1';

SELECT
    jsonb '{}' @@ '$';

SELECT
    jsonb '[]' @@ '$';

SELECT
    jsonb '[1,2,3]' @@ '$[*]';

SELECT
    jsonb '[]' @@ '$[*]';

SELECT
    jsonb_path_match('[[1, true], [2, false]]', 'strict $[*] ? (@[0] > $x) [1]', '{"x": 1}');

SELECT
    jsonb_path_match('[[1, true], [2, false]]', 'strict $[*] ? (@[0] < $x) [1]', '{"x": 2}');

SELECT
    jsonb_path_match('[{"a": 1}, {"a": 2}, 3]', 'lax exists($[*].a)', silent => FALSE);

SELECT
    jsonb_path_match('[{"a": 1}, {"a": 2}, 3]', 'lax exists($[*].a)', silent => TRUE);

SELECT
    jsonb_path_match('[{"a": 1}, {"a": 2}, 3]', 'strict exists($[*].a)', silent => FALSE);

SELECT
    jsonb_path_match('[{"a": 1}, {"a": 2}, 3]', 'strict exists($[*].a)', silent => TRUE);

SELECT
    jsonb_path_query('[null,1,true,"a",[],{}]', '$.type()');

SELECT
    jsonb_path_query('[null,1,true,"a",[],{}]', 'lax $.type()');

SELECT
    jsonb_path_query('[null,1,true,"a",[],{}]', '$[*].type()');

SELECT
    jsonb_path_query('null', 'null.type()');

SELECT
    jsonb_path_query('null', 'true.type()');

SELECT
    jsonb_path_query('null', '(123).type()');

SELECT
    jsonb_path_query('null', '"123".type()');

SELECT
    jsonb_path_query('{"a": 2}', '($.a - 5).abs() + 10');

SELECT
    jsonb_path_query('{"a": 2.5}', '-($.a * $.a).floor() % 4.3');

SELECT
    jsonb_path_query('[1, 2, 3]', '($[*] > 2) ? (@ == true)');

SELECT
    jsonb_path_query('[1, 2, 3]', '($[*] > 3).type()');

SELECT
    jsonb_path_query('[1, 2, 3]', '($[*].a > 3).type()');

SELECT
    jsonb_path_query('[1, 2, 3]', 'strict ($[*].a > 3).type()');

SELECT
    jsonb_path_query('[1,null,true,"11",[],[1],[1,2,3],{},{"a":1,"b":2}]', 'strict $[*].size()');

SELECT
    jsonb_path_query('[1,null,true,"11",[],[1],[1,2,3],{},{"a":1,"b":2}]', 'strict $[*].size()', silent => TRUE);

SELECT
    jsonb_path_query('[1,null,true,"11",[],[1],[1,2,3],{},{"a":1,"b":2}]', 'lax $[*].size()');

SELECT
    jsonb_path_query('[0, 1, -2, -3.4, 5.6]', '$[*].abs()');

SELECT
    jsonb_path_query('[0, 1, -2, -3.4, 5.6]', '$[*].floor()');

SELECT
    jsonb_path_query('[0, 1, -2, -3.4, 5.6]', '$[*].ceiling()');

SELECT
    jsonb_path_query('[0, 1, -2, -3.4, 5.6]', '$[*].ceiling().abs()');

SELECT
    jsonb_path_query('[0, 1, -2, -3.4, 5.6]', '$[*].ceiling().abs().type()');

SELECT
    jsonb_path_query('[{},1]', '$[*].keyvalue()');

SELECT
    jsonb_path_query('[{},1]', '$[*].keyvalue()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.keyvalue()');

SELECT
    jsonb_path_query('{"a": 1, "b": [1, 2], "c": {"a": "bbb"}}', '$.keyvalue()');

SELECT
    jsonb_path_query('[{"a": 1, "b": [1, 2]}, {"c": {"a": "bbb"}}]', '$[*].keyvalue()');

SELECT
    jsonb_path_query('[{"a": 1, "b": [1, 2]}, {"c": {"a": "bbb"}}]', 'strict $.keyvalue()');

SELECT
    jsonb_path_query('[{"a": 1, "b": [1, 2]}, {"c": {"a": "bbb"}}]', 'lax $.keyvalue()');

SELECT
    jsonb_path_query('[{"a": 1, "b": [1, 2]}, {"c": {"a": "bbb"}}]', 'strict $.keyvalue().a');

SELECT
    jsonb '{"a": 1, "b": [1, 2]}' @? 'lax $.keyvalue()';

SELECT
    jsonb '{"a": 1, "b": [1, 2]}' @? 'lax $.keyvalue().key';

SELECT
    jsonb_path_query('null', '$.double()');

SELECT
    jsonb_path_query('true', '$.double()');

SELECT
    jsonb_path_query('null', '$.double()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.double()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.double()');

SELECT
    jsonb_path_query('[]', 'strict $.double()');

SELECT
    jsonb_path_query('{}', '$.double()');

SELECT
    jsonb_path_query('[]', 'strict $.double()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.double()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.double()');

SELECT
    jsonb_path_query('"1.23"', '$.double()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.double()');

SELECT
    jsonb_path_query('"nan"', '$.double()');

SELECT
    jsonb_path_query('"NaN"', '$.double()');

SELECT
    jsonb_path_query('"inf"', '$.double()');

SELECT
    jsonb_path_query('"-inf"', '$.double()');

SELECT
    jsonb_path_query('"inf"', '$.double()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.double()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.abs()');

SELECT
    jsonb_path_query('true', '$.floor()');

SELECT
    jsonb_path_query('"1.2"', '$.ceiling()');

SELECT
    jsonb_path_query('{}', '$.abs()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.floor()', silent => TRUE);

SELECT
    jsonb_path_query('"1.2"', '$.ceiling()', silent => TRUE);

SELECT
    jsonb_path_query('["", "a", "abc", "abcabc"]', '$[*] ? (@ starts with "abc")');

SELECT
    jsonb_path_query('["", "a", "abc", "abcabc"]', 'strict $ ? (@[*] starts with "abc")');

SELECT
    jsonb_path_query('["", "a", "abd", "abdabc"]', 'strict $ ? (@[*] starts with "abc")');

SELECT
    jsonb_path_query('["abc", "abcabc", null, 1]', 'strict $ ? (@[*] starts with "abc")');

SELECT
    jsonb_path_query('["abc", "abcabc", null, 1]', 'strict $ ? ((@[*] starts with "abc") is unknown)');

SELECT
    jsonb_path_query('[[null, 1, "abc", "abcabc"]]', 'lax $ ? (@[*] starts with "abc")');

SELECT
    jsonb_path_query('[[null, 1, "abd", "abdabc"]]', 'lax $ ? ((@[*] starts with "abc") is unknown)');

SELECT
    jsonb_path_query('[null, 1, "abd", "abdabc"]', 'lax $[*] ? ((@ starts with "abc") is unknown)');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "adc\nabc", "babc"]', 'lax $[*] ? (@ like_regex "^ab.*c")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "adc\nabc", "babc"]', 'lax $[*] ? (@ like_regex "^a  b.*  c " flag "ix")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "adc\nabc", "babc"]', 'lax $[*] ? (@ like_regex "^ab.*c" flag "m")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "adc\nabc", "babc"]', 'lax $[*] ? (@ like_regex "^ab.*c" flag "s")');

-- jsonpath operators
SELECT
    jsonb_path_query('[{"a": 1}, {"a": 2}]', '$[*]');

SELECT
    jsonb_path_query('[{"a": 1}, {"a": 2}]', '$[*] ? (@.a > 10)');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}, {}]', 'strict $[*].a');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}]', '$[*].a');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}]', '$[*].a ? (@ == 1)');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}]', '$[*].a ? (@ > 10)');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*].a ? (@ > $min && @ < $max)', vars => '{"min": 1, "max": 4}');

SELECT
    jsonb_path_query_array('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*].a ? (@ > $min && @ < $max)', vars => '{"min": 3, "max": 4}');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}, {}]', 'strict $[*].a');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}, {}]', 'strict $[*].a', silent => TRUE);

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}]', '$[*].a');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}]', '$[*].a ? (@ == 1)');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}]', '$[*].a ? (@ > 10)');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*].a ? (@ > $min && @ < $max)', vars => '{"min": 1, "max": 4}');

SELECT
    jsonb_path_query_first('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*].a ? (@ > $min && @ < $max)', vars => '{"min": 3, "max": 4}');

SELECT
    jsonb '[{"a": 1}, {"a": 2}]' @? '$[*].a ? (@ > 1)';

SELECT
    jsonb '[{"a": 1}, {"a": 2}]' @? '$[*] ? (@.a > 2)';

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}]', '$[*].a ? (@ > 1)');

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*] ? (@.a > $min && @.a < $max)', vars => '{"min": 1, "max": 4}');

SELECT
    jsonb_path_exists('[{"a": 1}, {"a": 2}, {"a": 3}, {"a": 5}]', '$[*] ? (@.a > $min && @.a < $max)', vars => '{"min": 3, "max": 4}');

SELECT
    jsonb_path_match('true', '$', silent => FALSE);

SELECT
    jsonb_path_match('false', '$', silent => FALSE);

SELECT
    jsonb_path_match('null', '$', silent => FALSE);

SELECT
    jsonb_path_match('1', '$', silent => TRUE);

SELECT
    jsonb_path_match('1', '$', silent => FALSE);

SELECT
    jsonb_path_match('"a"', '$', silent => FALSE);

SELECT
    jsonb_path_match('{}', '$', silent => FALSE);

SELECT
    jsonb_path_match('[true]', '$', silent => FALSE);

SELECT
    jsonb_path_match('{}', 'lax $.a', silent => FALSE);

SELECT
    jsonb_path_match('{}', 'strict $.a', silent => FALSE);

SELECT
    jsonb_path_match('{}', 'strict $.a', silent => TRUE);

SELECT
    jsonb_path_match('[true, true]', '$[*]', silent => FALSE);

SELECT
    jsonb '[{"a": 1}, {"a": 2}]' @@ '$[*].a > 1';

SELECT
    jsonb '[{"a": 1}, {"a": 2}]' @@ '$[*].a > 2';

SELECT
    jsonb_path_match('[{"a": 1}, {"a": 2}]', '$[*].a > 1');

