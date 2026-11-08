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
    jsonb_path_query(
        '[true, false, null]',
        '$[*] ? (@ == true  &&  ($x == true && $y == true) ||
				 @ == false && !($x == true && $y == true) ||
				 @ == null  &&  ($x == true && $y == true) is unknown)',
        jsonb_build_object(
            'x', x,
            'y', y
        )
    ) AS "x && y"
FROM (
    VALUES (jsonb 'true'),
        ('false'),
        ('"null"')) x (x),
    (
        VALUES (jsonb 'true'), ('false'), ('"null"')) y (y);

SELECT
    x,
    y,
    jsonb_path_query(
        '[true, false, null]',
        '$[*] ? (@ == true  &&  ($x == true || $y == true) ||
				 @ == false && !($x == true || $y == true) ||
				 @ == null  &&  ($x == true || $y == true) is unknown)',
        jsonb_build_object(
            'x', x,
            'y', y
        )
    ) AS "x || y"
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

-- any key on arrays with and without unwrapping.
SELECT
    jsonb_path_query('{"a": [1,2,3], "b": [3,4,5]}', '$.*');

SELECT
    jsonb_path_query('[1,2,3]', '$.*');

SELECT
    jsonb_path_query('[1,2,3,{"b": [3,4,5]}]', 'lax $.*');

SELECT
    jsonb_path_query('[1,2,3,{"b": [3,4,5]}]', 'strict $.*');

SELECT
    jsonb_path_query('[1,2,3,{"b": [3,4,5]}]', 'strict $.*', NULL, TRUE);

SELECT
    jsonb '{"a": [1,2,3], "b": [3,4,5]}' @? '$.*';

SELECT
    jsonb '[1,2,3]' @? '$.*';

SELECT
    jsonb '[1,2,3,{"b": [3,4,5]}]' @? 'lax $.*';

SELECT
    jsonb '[1,2,3,{"b": [3,4,5]}]' @? 'strict $.*';

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
    jsonb_path_query('1e1000', '$.double()');

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
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "babc", "adc\nabc", "ab\nadc"]', 'lax $[*] ? (@ like_regex "^ab.*c")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "babc", "adc\nabc", "ab\nadc"]', 'lax $[*] ? (@ like_regex "^ab.*c" flag "i")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "babc", "adc\nabc", "ab\nadc"]', 'lax $[*] ? (@ like_regex "^ab.*c" flag "m")');

SELECT
    jsonb_path_query('[null, 1, "abc", "abd", "aBdC", "abdacb", "babc", "adc\nabc", "ab\nadc"]', 'lax $[*] ? (@ like_regex "^ab.*c" flag "s")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "a\\b" flag "q")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "a\\b" flag "")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "^a\\b$" flag "q")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "^a\\B$" flag "q")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "^a\\B$" flag "iq")');

SELECT
    jsonb_path_query('[null, 1, "a\b", "a\\b", "^a\\b$"]', 'lax $[*] ? (@ like_regex "^a\\b$" flag "")');

SELECT
    jsonb_path_query('null', '$.datetime()');

SELECT
    jsonb_path_query('true', '$.datetime()');

SELECT
    jsonb_path_query('1', '$.datetime()');

SELECT
    jsonb_path_query('[]', '$.datetime()');

SELECT
    jsonb_path_query('[]', 'strict $.datetime()');

SELECT
    jsonb_path_query('{}', '$.datetime()');

SELECT
    jsonb_path_query('"bogus"', '$.datetime()');

SELECT
    jsonb_path_query('"12:34"', '$.datetime("aaa")');

SELECT
    jsonb_path_query('"aaaa"', '$.datetime("HH24")');

SELECT
    jsonb '"10-03-2017"' @? '$.datetime("dd-mm-yyyy")';

SELECT
    jsonb_path_query('"10-03-2017"', '$.datetime("dd-mm-yyyy")');

SELECT
    jsonb_path_query('"10-03-2017"', '$.datetime("dd-mm-yyyy").type()');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy")');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy").type()');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '       $.datetime("dd-mm-yyyy HH24:MI").type()');

SELECT
    jsonb_path_query('"10-03-2017 12:34 +05:20"', '$.datetime("dd-mm-yyyy HH24:MI TZH:TZM").type()');

SELECT
    jsonb_path_query('"12:34:56"', '$.datetime("HH24:MI:SS").type()');

SELECT
    jsonb_path_query('"12:34:56 +05:20"', '$.datetime("HH24:MI:SS TZH:TZM").type()');

SELECT
    jsonb_path_query('"10-03-2017T12:34:56"', '$.datetime("dd-mm-yyyy\"T\"HH24:MI:SS")');

SELECT
    jsonb_path_query('"10-03-2017t12:34:56"', '$.datetime("dd-mm-yyyy\"T\"HH24:MI:SS")');

SELECT
    jsonb_path_query('"10-03-2017 12:34:56"', '$.datetime("dd-mm-yyyy\"T\"HH24:MI:SS")');

-- Test .bigint()
SELECT
    jsonb_path_query('null', '$.bigint()');

SELECT
    jsonb_path_query('true', '$.bigint()');

SELECT
    jsonb_path_query('null', '$.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.bigint()');

SELECT
    jsonb_path_query('[]', 'strict $.bigint()');

SELECT
    jsonb_path_query('{}', '$.bigint()');

SELECT
    jsonb_path_query('[]', 'strict $.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('"1.23"', '$.bigint()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.bigint()');

SELECT
    jsonb_path_query('1e1000', '$.bigint()');

SELECT
    jsonb_path_query('"nan"', '$.bigint()');

SELECT
    jsonb_path_query('"NaN"', '$.bigint()');

SELECT
    jsonb_path_query('"inf"', '$.bigint()');

SELECT
    jsonb_path_query('"-inf"', '$.bigint()');

SELECT
    jsonb_path_query('"inf"', '$.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.bigint()', silent => TRUE);

SELECT
    jsonb_path_query('123', '$.bigint()');

SELECT
    jsonb_path_query('"123"', '$.bigint()');

SELECT
    jsonb_path_query('1.23', '$.bigint()');

SELECT
    jsonb_path_query('1.83', '$.bigint()');

SELECT
    jsonb_path_query('1234567890123', '$.bigint()');

SELECT
    jsonb_path_query('"1234567890123"', '$.bigint()');

SELECT
    jsonb_path_query('12345678901234567890', '$.bigint()');

SELECT
    jsonb_path_query('"12345678901234567890"', '$.bigint()');

SELECT
    jsonb_path_query('"+123"', '$.bigint()');

SELECT
    jsonb_path_query('-123', '$.bigint()');

SELECT
    jsonb_path_query('"-123"', '$.bigint()');

SELECT
    jsonb_path_query('123', '$.bigint() * 2');

-- Test .boolean()
SELECT
    jsonb_path_query('null', '$.boolean()');

SELECT
    jsonb_path_query('null', '$.boolean()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.boolean()');

SELECT
    jsonb_path_query('[]', 'strict $.boolean()');

SELECT
    jsonb_path_query('{}', '$.boolean()');

SELECT
    jsonb_path_query('[]', 'strict $.boolean()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.boolean()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.boolean()');

SELECT
    jsonb_path_query('"1.23"', '$.boolean()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.boolean()');

SELECT
    jsonb_path_query('1e1000', '$.boolean()');

SELECT
    jsonb_path_query('"nan"', '$.boolean()');

SELECT
    jsonb_path_query('"NaN"', '$.boolean()');

SELECT
    jsonb_path_query('"inf"', '$.boolean()');

SELECT
    jsonb_path_query('"-inf"', '$.boolean()');

SELECT
    jsonb_path_query('"inf"', '$.boolean()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.boolean()', silent => TRUE);

SELECT
    jsonb_path_query('"100"', '$.boolean()');

SELECT
    jsonb_path_query('true', '$.boolean()');

SELECT
    jsonb_path_query('false', '$.boolean()');

SELECT
    jsonb_path_query('1', '$.boolean()');

SELECT
    jsonb_path_query('0', '$.boolean()');

SELECT
    jsonb_path_query('-1', '$.boolean()');

SELECT
    jsonb_path_query('100', '$.boolean()');

SELECT
    jsonb_path_query('"1"', '$.boolean()');

SELECT
    jsonb_path_query('"0"', '$.boolean()');

SELECT
    jsonb_path_query('"true"', '$.boolean()');

SELECT
    jsonb_path_query('"false"', '$.boolean()');

SELECT
    jsonb_path_query('"TRUE"', '$.boolean()');

SELECT
    jsonb_path_query('"FALSE"', '$.boolean()');

SELECT
    jsonb_path_query('"yes"', '$.boolean()');

SELECT
    jsonb_path_query('"NO"', '$.boolean()');

SELECT
    jsonb_path_query('"T"', '$.boolean()');

SELECT
    jsonb_path_query('"f"', '$.boolean()');

SELECT
    jsonb_path_query('"y"', '$.boolean()');

SELECT
    jsonb_path_query('"N"', '$.boolean()');

SELECT
    jsonb_path_query('true', '$.boolean().type()');

SELECT
    jsonb_path_query('123', '$.boolean().type()');

SELECT
    jsonb_path_query('"Yes"', '$.boolean().type()');

SELECT
    jsonb_path_query_array('[1, "yes", false]', '$[*].boolean()');

-- Test .date()
SELECT
    jsonb_path_query('null', '$.date()');

SELECT
    jsonb_path_query('true', '$.date()');

SELECT
    jsonb_path_query('1', '$.date()');

SELECT
    jsonb_path_query('[]', '$.date()');

SELECT
    jsonb_path_query('[]', 'strict $.date()');

SELECT
    jsonb_path_query('{}', '$.date()');

SELECT
    jsonb_path_query('"bogus"', '$.date()');

SELECT
    jsonb '"2023-08-15"' @? '$.date()';

SELECT
    jsonb_path_query('"2023-08-15"', '$.date()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.date().type()');

SELECT
    jsonb_path_query('"12:34:56"', '$.date()');

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.date()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.date()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.date()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.date()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15"', '$.date(2)');

-- Test .decimal()
SELECT
    jsonb_path_query('null', '$.decimal()');

SELECT
    jsonb_path_query('true', '$.decimal()');

SELECT
    jsonb_path_query('null', '$.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.decimal()');

SELECT
    jsonb_path_query('[]', 'strict $.decimal()');

SELECT
    jsonb_path_query('{}', '$.decimal()');

SELECT
    jsonb_path_query('[]', 'strict $.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.decimal()');

SELECT
    jsonb_path_query('"1.23"', '$.decimal()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.decimal()');

SELECT
    jsonb_path_query('1e1000', '$.decimal()');

SELECT
    jsonb_path_query('"nan"', '$.decimal()');

SELECT
    jsonb_path_query('"NaN"', '$.decimal()');

SELECT
    jsonb_path_query('"inf"', '$.decimal()');

SELECT
    jsonb_path_query('"-inf"', '$.decimal()');

SELECT
    jsonb_path_query('"inf"', '$.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.decimal()', silent => TRUE);

SELECT
    jsonb_path_query('123', '$.decimal()');

SELECT
    jsonb_path_query('"123"', '$.decimal()');

SELECT
    jsonb_path_query('12345678901234567890', '$.decimal()');

SELECT
    jsonb_path_query('"12345678901234567890"', '$.decimal()');

SELECT
    jsonb_path_query('"+12.3"', '$.decimal()');

SELECT
    jsonb_path_query('-12.3', '$.decimal()');

SELECT
    jsonb_path_query('"-12.3"', '$.decimal()');

SELECT
    jsonb_path_query('12.3', '$.decimal() * 2');

SELECT
    jsonb_path_query('12345.678', '$.decimal(6, 1)');

SELECT
    jsonb_path_query('12345.678', '$.decimal(6, 2)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(6, 2)');

SELECT
    jsonb_path_query('12345.678', '$.decimal(4, 6)');

SELECT
    jsonb_path_query('12345.678', '$.decimal(0, 6)');

SELECT
    jsonb_path_query('12345.678', '$.decimal(1001, 6)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(+6, +2)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(+6, -2)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(-6, +2)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(6, -1001)');

SELECT
    jsonb_path_query('1234.5678', '$.decimal(6, 1001)');

SELECT
    jsonb_path_query('-1234.5678', '$.decimal(+6, -2)');

SELECT
    jsonb_path_query('0.0123456', '$.decimal(1,2)');

SELECT
    jsonb_path_query('0.0012345', '$.decimal(2,4)');

SELECT
    jsonb_path_query('-0.00123456', '$.decimal(2,-4)');

SELECT
    jsonb_path_query('12.3', '$.decimal(12345678901,1)');

SELECT
    jsonb_path_query('12.3', '$.decimal(1,12345678901)');

-- An out-of-range precision or scale does not fail in silent mode.
SELECT
    jsonb_path_query('12345.678', '$.decimal(0, 6)', silent => TRUE);

SELECT
    jsonb_path_query('12345.678', '$.decimal(1001, 6)', silent => TRUE);

SELECT
    jsonb_path_query('1234.5678', '$.decimal(-6, +2)', silent => TRUE);

SELECT
    jsonb_path_query('1234.5678', '$.decimal(6, -1001)', silent => TRUE);

SELECT
    jsonb_path_query('1234.5678', '$.decimal(6, 1001)', silent => TRUE);

SELECT
    '1234.5678'::jsonb @? '$.decimal(0)';

-- Test .integer()
SELECT
    jsonb_path_query('null', '$.integer()');

SELECT
    jsonb_path_query('true', '$.integer()');

SELECT
    jsonb_path_query('null', '$.integer()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.integer()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.integer()');

SELECT
    jsonb_path_query('[]', 'strict $.integer()');

SELECT
    jsonb_path_query('{}', '$.integer()');

SELECT
    jsonb_path_query('[]', 'strict $.integer()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.integer()', silent => TRUE);

SELECT
    jsonb_path_query('"1.23"', '$.integer()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.integer()');

SELECT
    jsonb_path_query('1e1000', '$.integer()');

SELECT
    jsonb_path_query('"nan"', '$.integer()');

SELECT
    jsonb_path_query('"NaN"', '$.integer()');

SELECT
    jsonb_path_query('"inf"', '$.integer()');

SELECT
    jsonb_path_query('"-inf"', '$.integer()');

SELECT
    jsonb_path_query('"inf"', '$.integer()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.integer()', silent => TRUE);

SELECT
    jsonb_path_query('123', '$.integer()');

SELECT
    jsonb_path_query('"123"', '$.integer()');

SELECT
    jsonb_path_query('1.23', '$.integer()');

SELECT
    jsonb_path_query('1.83', '$.integer()');

SELECT
    jsonb_path_query('12345678901', '$.integer()');

SELECT
    jsonb_path_query('"12345678901"', '$.integer()');

SELECT
    jsonb_path_query('"+123"', '$.integer()');

SELECT
    jsonb_path_query('-123', '$.integer()');

SELECT
    jsonb_path_query('"-123"', '$.integer()');

SELECT
    jsonb_path_query('123', '$.integer() * 2');

-- Test .number()
SELECT
    jsonb_path_query('null', '$.number()');

SELECT
    jsonb_path_query('true', '$.number()');

SELECT
    jsonb_path_query('null', '$.number()', silent => TRUE);

SELECT
    jsonb_path_query('true', '$.number()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.number()');

SELECT
    jsonb_path_query('[]', 'strict $.number()');

SELECT
    jsonb_path_query('{}', '$.number()');

SELECT
    jsonb_path_query('[]', 'strict $.number()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.number()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.number()');

SELECT
    jsonb_path_query('"1.23"', '$.number()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.number()');

SELECT
    jsonb_path_query('1e1000', '$.number()');

SELECT
    jsonb_path_query('"nan"', '$.number()');

SELECT
    jsonb_path_query('"NaN"', '$.number()');

SELECT
    jsonb_path_query('"inf"', '$.number()');

SELECT
    jsonb_path_query('"-inf"', '$.number()');

SELECT
    jsonb_path_query('"inf"', '$.number()', silent => TRUE);

SELECT
    jsonb_path_query('"-inf"', '$.number()', silent => TRUE);

SELECT
    jsonb_path_query('123', '$.number()');

SELECT
    jsonb_path_query('"123"', '$.number()');

SELECT
    jsonb_path_query('12345678901234567890', '$.number()');

SELECT
    jsonb_path_query('"12345678901234567890"', '$.number()');

SELECT
    jsonb_path_query('"+12.3"', '$.number()');

SELECT
    jsonb_path_query('-12.3', '$.number()');

SELECT
    jsonb_path_query('"-12.3"', '$.number()');

SELECT
    jsonb_path_query('12.3', '$.number() * 2');

-- Test .string()
SELECT
    jsonb_path_query('null', '$.string()');

SELECT
    jsonb_path_query('null', '$.string()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.string()');

SELECT
    jsonb_path_query('[]', 'strict $.string()');

SELECT
    jsonb_path_query('{}', '$.string()');

SELECT
    jsonb_path_query('[]', 'strict $.string()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.string()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.string()');

SELECT
    jsonb_path_query('"1.23"', '$.string()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.string()');

SELECT
    jsonb_path_query('1234', '$.string()');

SELECT
    jsonb_path_query('true', '$.string()');

SELECT
    jsonb_path_query('1234', '$.string().type()');

SELECT
    jsonb_path_query('[2, true]', '$.string()');

SELECT
    jsonb_path_query_array('[1.23, "yes", false]', '$[*].string()');

SELECT
    jsonb_path_query_array('[1.23, "yes", false]', '$[*].string().type()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +5:30"', '$.timestamp().string()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +5:30"', '$.timestamp().string()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp_tz().string()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56"', '$.timestamp_tz().string()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +5:30"', '$.timestamp_tz().string()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp().string()');

SELECT
    jsonb_path_query('"12:34:56 +5:30"', '$.time_tz().string()');

-- this timetz usage will absorb the UTC offset of the current timezone setting
BEGIN;
SET local timezone = 'UTC-10';
SELECT
    jsonb_path_query_tz ('"12:34:56"', '$.time_tz().string()');
ROLLBACK;

SELECT
    jsonb_path_query('"12:34:56"', '$.time().string()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.date().string()');

-- .string() does not react to timezone or datestyle
BEGIN;
SET local timezone = 'UTC';
SET local datestyle = 'German';
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +5:30"', '$.timestamp_tz().string()');
SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp().string()');
ROLLBACK;

-- test .ltrim()
SELECT
    jsonb_path_query('"   hello   "', '$.ltrim(" ")');

SELECT
    jsonb_path_query('"   hello   "', '$.ltrim()');

SELECT
    jsonb_path_query('"zzzytest"', '$.ltrim("xyz")');

SELECT
    jsonb_path_query('null', '$.ltrim()');

SELECT
    jsonb_path_query('null', '$.ltrim()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.ltrim()');

SELECT
    jsonb_path_query('[]', 'strict $.ltrim()');

SELECT
    jsonb_path_query('{}', '$.ltrim()');

SELECT
    jsonb_path_query('[]', 'strict $.ltrim()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.ltrim()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.ltrim()');

SELECT
    jsonb_path_query('"1.23"', '$.ltrim()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.ltrim()');

SELECT
    jsonb_path_query('1234', '$.ltrim()');

SELECT
    jsonb_path_query('true', '$.ltrim()');

SELECT
    jsonb_path_query('1234', '$.ltrim().type()');

SELECT
    jsonb_path_query('[2, true]', '$.ltrim()');

SELECT
    jsonb_path_query_array('["  maybe  ", "  yes", "  no"]', '$[*].ltrim()');

SELECT
    jsonb_path_query_array('["  maybe  ", "  yes", "  no"]', '$[*].ltrim().type()');

-- test .rtrim()
SELECT
    jsonb_path_query('"   hello   "', '$.rtrim(" ")');

SELECT
    jsonb_path_query('"testxxzx"', '$.rtrim("xyz")');

SELECT
    jsonb_path_query('"   hello   "', '$.rtrim()');

-- test .btrim()
SELECT
    jsonb_path_query('"   hello   "', '$.btrim(" ")');

SELECT
    jsonb_path_query('"xyxtrimyyx"', '$.btrim("xyz")');

SELECT
    jsonb_path_query('"   hello   "', '$.btrim()');

-- test .lower()
SELECT
    jsonb_path_query('null', '$.lower()');

SELECT
    jsonb_path_query('null', '$.lower()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.lower()');

SELECT
    jsonb_path_query('[]', 'strict $.lower()');

SELECT
    jsonb_path_query('{}', '$.lower()');

SELECT
    jsonb_path_query('[]', 'strict $.lower()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.lower()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.lower()');

SELECT
    jsonb_path_query('"1.23"', '$.lower()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.lower()');

SELECT
    jsonb_path_query('1234', '$.lower()');

SELECT
    jsonb_path_query('true', '$.lower()');

SELECT
    jsonb_path_query('1234', '$.lower().type()');

SELECT
    jsonb_path_query('[2, true]', '$.lower()');

SELECT
    jsonb_path_query_array('["maybe", "yes", "no"]', '$[*].lower()');

SELECT
    jsonb_path_query_array('["maybe", "yes", "no"]', '$[*].lower().type()');

-- test .upper()
SELECT
    jsonb_path_query('null', '$.upper()');

SELECT
    jsonb_path_query('null', '$.upper()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.upper()');

SELECT
    jsonb_path_query('[]', 'strict $.upper()');

SELECT
    jsonb_path_query('{}', '$.upper()');

SELECT
    jsonb_path_query('[]', 'strict $.upper()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.upper()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.upper()');

SELECT
    jsonb_path_query('"1.23"', '$.upper()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.upper()');

SELECT
    jsonb_path_query('1234', '$.upper()');

SELECT
    jsonb_path_query('true', '$.upper()');

SELECT
    jsonb_path_query('1234', '$.upper().type()');

SELECT
    jsonb_path_query('[2, true]', '$.upper()');

SELECT
    jsonb_path_query_array('["maybe", "yes", "no"]', '$[*].upper()');

SELECT
    jsonb_path_query_array('["maybe", "yes", "no"]', '$[*].upper().type()');

-- test .initcap()
SELECT
    jsonb_path_query('null', '$.initcap()');

SELECT
    jsonb_path_query('null', '$.initcap()', silent => TRUE);

SELECT
    jsonb_path_query('[]', '$.initcap()');

SELECT
    jsonb_path_query('[]', 'strict $.initcap()');

SELECT
    jsonb_path_query('{}', '$.initcap()');

SELECT
    jsonb_path_query('[]', 'strict $.initcap()', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.initcap()', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.initcap()');

SELECT
    jsonb_path_query('"1.23"', '$.initcap()');

SELECT
    jsonb_path_query('"1.23aaa"', '$.initcap()');

SELECT
    jsonb_path_query('1234', '$.initcap()');

SELECT
    jsonb_path_query('true', '$.initcap()');

SELECT
    jsonb_path_query('1234', '$.initcap().type()');

SELECT
    jsonb_path_query('[2, true]', '$.initcap()');

SELECT
    jsonb_path_query('["maybe yes", "probably no"]', '$.initcap()');

-- Test .replace()
SELECT
    jsonb_path_query('null', '$.replace("x", "bye")');

SELECT
    jsonb_path_query('null', '$.replace("x", "bye")', silent => TRUE);

SELECT
    jsonb_path_query('["x", "y", "z"]', '$.replace("x", "bye")');

SELECT
    jsonb_path_query('{}', '$.replace("x", "bye")');

SELECT
    jsonb_path_query('[]', 'strict $.replace("x", "bye")', silent => TRUE);

SELECT
    jsonb_path_query('{}', '$.replace("x", "bye")', silent => TRUE);

SELECT
    jsonb_path_query('1.23', '$.replace("x", "bye")');

SELECT
    jsonb_path_query('"hello world"', '$.replace("hello","bye")');

SELECT
    jsonb_path_query('"hello world"', '$.replace("hello","bye") starts with "bye"');

-- Test .split_part()
SELECT
    jsonb_path_query('"abc~@~def~@~ghi"', '$.split_part("~@~", 2)');

SELECT
    jsonb_path_query('"abc,def,ghi,jkl"', '$.split_part(",", -2)');

SELECT
    jsonb_path_query('"a,b"', '$.split_part(",", 0)');

SELECT
    jsonb_path_query('"a,b"', '$.split_part(",", 0)', silent => TRUE);

SELECT
    jsonb_path_query('"a,b"', '$.split_part(",", 2147483648)');

SELECT
    jsonb_path_query('"a,b"', '$.split_part(",", 2147483648)', silent => TRUE);

-- Test string methods play nicely together
SELECT
    jsonb_path_query('"hello world"', '$.replace("hello","bye").upper()');

SELECT
    jsonb_path_query('"hElLo WorlD"', '$.lower().upper().lower().replace("hello","bye")');

SELECT
    jsonb_path_query('"hElLo WorlD"', '$.upper().lower().upper().replace("HELLO", "BYE")');

SELECT
    jsonb_path_query('"hElLo WorlD"', '$.lower().upper().lower().replace("hello","bye") starts with "bye"');

SELECT
    jsonb_path_query('"   hElLo WorlD "', '$.btrim().lower().upper().lower().replace("hello","bye") starts with "bye"');

-- Test .time()
SELECT
    jsonb_path_query('null', '$.time()');

SELECT
    jsonb_path_query('true', '$.time()');

SELECT
    jsonb_path_query('1', '$.time()');

SELECT
    jsonb_path_query('[]', '$.time()');

SELECT
    jsonb_path_query('[]', 'strict $.time()');

SELECT
    jsonb_path_query('{}', '$.time()');

SELECT
    jsonb_path_query('"bogus"', '$.time()');

SELECT
    jsonb '"12:34:56"' @? '$.time()';

SELECT
    jsonb_path_query('"12:34:56"', '$.time()');

SELECT
    jsonb_path_query('"12:34:56"', '$.time().type()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.time()');

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.time()');

SELECT
    jsonb_path_query_tz ('"12:34:56 +05:30"', '$.time()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.time()');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(-1)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(2.0)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(12345678901)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(0)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(2)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(5)');

SELECT
    jsonb_path_query('"12:34:56.789"', '$.time(10)');

SELECT
    jsonb_path_query('"12:34:56.789012"', '$.time(8)');

-- Test .time_tz()
SELECT
    jsonb_path_query('null', '$.time_tz()');

SELECT
    jsonb_path_query('true', '$.time_tz()');

SELECT
    jsonb_path_query('1', '$.time_tz()');

SELECT
    jsonb_path_query('[]', '$.time_tz()');

SELECT
    jsonb_path_query('[]', 'strict $.time_tz()');

SELECT
    jsonb_path_query('{}', '$.time_tz()');

SELECT
    jsonb_path_query('"bogus"', '$.time_tz()');

SELECT
    jsonb '"12:34:56 +05:30"' @? '$.time_tz()';

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.time_tz()');

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.time_tz().type()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.time_tz()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.time_tz()');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(-1)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(2.0)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(12345678901)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(0)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(2)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(5)');

SELECT
    jsonb_path_query('"12:34:56.789 +05:30"', '$.time_tz(10)');

SELECT
    jsonb_path_query('"12:34:56.789012 +05:30"', '$.time_tz(8)');

-- Test .timestamp()
SELECT
    jsonb_path_query('null', '$.timestamp()');

SELECT
    jsonb_path_query('true', '$.timestamp()');

SELECT
    jsonb_path_query('1', '$.timestamp()');

SELECT
    jsonb_path_query('[]', '$.timestamp()');

SELECT
    jsonb_path_query('[]', 'strict $.timestamp()');

SELECT
    jsonb_path_query('{}', '$.timestamp()');

SELECT
    jsonb_path_query('"bogus"', '$.timestamp()');

SELECT
    jsonb '"2023-08-15 12:34:56"' @? '$.timestamp()';

SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp().type()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.timestamp()');

SELECT
    jsonb_path_query('"12:34:56"', '$.timestamp()');

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.timestamp()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(-1)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(2.0)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(12345678901)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(0)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(2)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(5)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789"', '$.timestamp(10)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789012"', '$.timestamp(8)');

-- Test .timestamp_tz()
SELECT
    jsonb_path_query('null', '$.timestamp_tz()');

SELECT
    jsonb_path_query('true', '$.timestamp_tz()');

SELECT
    jsonb_path_query('1', '$.timestamp_tz()');

SELECT
    jsonb_path_query('[]', '$.timestamp_tz()');

SELECT
    jsonb_path_query('[]', 'strict $.timestamp_tz()');

SELECT
    jsonb_path_query('{}', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"bogus"', '$.timestamp_tz()');

SELECT
    jsonb '"2023-08-15 12:34:56 +05:30"' @? '$.timestamp_tz()';

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp_tz().type()');

SELECT
    jsonb_path_query('"2023-08-15"', '$.timestamp_tz()');

SELECT
    jsonb_path_query_tz ('"2023-08-15"', '$.timestamp_tz()');

-- should work
SELECT
    jsonb_path_query('"12:34:56"', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"12:34:56 +05:30"', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(-1)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(2.0)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(12345678901)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(0)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(2)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(5)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789 +05:30"', '$.timestamp_tz(10)');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56.789012 +05:30"', '$.timestamp_tz(8)');

SET time zone '+00';

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.time()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time_tz()');

SELECT
    jsonb_path_query('"12:34:56"', '$.time_tz()');

SELECT
    jsonb_path_query_tz ('"12:34:56"', '$.time_tz()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp_tz()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56"', '$.timestamp_tz()');

-- should work
SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy HH24:MI")');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 +05"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 -05"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 +05:20"', '$.datetime("dd-mm-yyyy HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 -05:20"', '$.datetime("dd-mm-yyyy HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"12:34"', '$.datetime("HH24:MI")');

SELECT
    jsonb_path_query('"12:34"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 +05"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 -05"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 +05:20"', '$.datetime("HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"12:34 -05:20"', '$.datetime("HH24:MI TZH:TZM")');

SET time zone '+10';

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.time()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time_tz()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56"', '$.timestamp_tz()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56"', '$.timestamp_tz()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy HH24:MI")');

SELECT
    jsonb_path_query('"10-03-2017 12:34"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 +05"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 -05"', '$.datetime("dd-mm-yyyy HH24:MI TZH")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 +05:20"', '$.datetime("dd-mm-yyyy HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"10-03-2017 12:34 -05:20"', '$.datetime("dd-mm-yyyy HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"12:34"', '$.datetime("HH24:MI")');

SELECT
    jsonb_path_query('"12:34"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 +05"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 -05"', '$.datetime("HH24:MI TZH")');

SELECT
    jsonb_path_query('"12:34 +05:20"', '$.datetime("HH24:MI TZH:TZM")');

SELECT
    jsonb_path_query('"12:34 -05:20"', '$.datetime("HH24:MI TZH:TZM")');

SET time zone DEFAULT;

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.time()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.time_tz()');

SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

SELECT
    jsonb_path_query_tz ('"2023-08-15 12:34:56 +05:30"', '$.timestamp()');

-- should work
SELECT
    jsonb_path_query('"2023-08-15 12:34:56 +05:30"', '$.timestamp_tz()');

SELECT
    jsonb_path_query('"2017-03-10"', '$.datetime().type()');

SELECT
    jsonb_path_query('"2017-03-10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56"', '$.datetime().type()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56+3"', '$.datetime().type()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56+3"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56+3:10"', '$.datetime().type()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10T12:34:56+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10t12:34:56+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10 12:34:56.789+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10T12:34:56.789+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10t12:34:56.789+3:10"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10T12:34:56.789EST"', '$.datetime()');

SELECT
    jsonb_path_query('"2017-03-10T12:34:56.789Z"', '$.datetime()');

SELECT
    jsonb_path_query('"12:34:56"', '$.datetime().type()');

SELECT
    jsonb_path_query('"12:34:56"', '$.datetime()');

SELECT
    jsonb_path_query('"12:34:56+3"', '$.datetime().type()');

SELECT
    jsonb_path_query('"12:34:56+3"', '$.datetime()');

SELECT
    jsonb_path_query('"12:34:56+3:10"', '$.datetime().type()');

SELECT
    jsonb_path_query('"12:34:56+3:10"', '$.datetime()');

SET time zone '+00';

-- date comparison
SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ == "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ >= "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ <  "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ == "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ >= "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "12:34:56", "01:02:03+04", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ <  "10.03.2017".datetime("dd.mm.yyyy"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ == "2017-03-10".date())');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ >= "2017-03-10".date())');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].datetime() ? (@ <  "2017-03-10".date())');

SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ == "2017-03-10".date())');

SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ >= "2017-03-10".date())');

SELECT
    jsonb_path_query('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ <  "2017-03-10".date())');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ == "2017-03-10".date())');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ >= "2017-03-10".date())');

SELECT
    jsonb_path_query_tz ('["2017-03-10", "2017-03-11", "2017-03-09", "2017-03-10 00:00:00", "2017-03-10 12:34:56", "2017-03-10 01:02:03+04", "2017-03-10 03:00:00+03"]', '$[*].date() ? (@ <  "2017-03-10".date())');

-- time comparison
SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ == "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ >= "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ <  "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ == "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ >= "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ <  "12:35".datetime("HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ == "12:35:00".time())');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ >= "12:35:00".time())');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].datetime() ? (@ <  "12:35:00".time())');

SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ == "12:35:00".time())');

SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ >= "12:35:00".time())');

SELECT
    jsonb_path_query('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ <  "12:35:00".time())');

SELECT
    jsonb_path_query('["12:34:00.123", "12:35:00.123", "12:36:00.1123", "12:35:00.1123+00", "12:35:00.123+01", "13:35:00.123+01", "2017-03-10 12:35:00.1", "2017-03-10 12:35:00.123+01"]', '$[*].time(2) ? (@ >= "12:35:00.123".time(2))');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ == "12:35:00".time())');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ >= "12:35:00".time())');

SELECT
    jsonb_path_query_tz ('["12:34:00", "12:35:00", "12:36:00", "12:35:00+00", "12:35:00+01", "13:35:00+01", "2017-03-10 12:35:00", "2017-03-10 12:35:00+01"]', '$[*].time() ? (@ <  "12:35:00".time())');

SELECT
    jsonb_path_query_tz ('["12:34:00.123", "12:35:00.123", "12:36:00.1123", "12:35:00.1123+00", "12:35:00.123+01", "13:35:00.123+01", "2017-03-10 12:35:00.1", "2017-03-10 12:35:00.123+01"]', '$[*].time(2) ? (@ >= "12:35:00.123".time(2))');

-- timetz comparison
SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ == "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ >= "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ <  "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ == "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ >= "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10", "2017-03-10 12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ <  "12:35 +1".datetime("HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ == "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ >= "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].datetime() ? (@ <  "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ == "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ >= "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ <  "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query('["12:34:00.123+01", "12:35:00.123+01", "12:36:00.1123+01", "12:35:00.1123+02", "12:35:00.123-02", "10:35:00.123", "11:35:00.1", "12:35:00.123", "2017-03-10 12:35:00.123 +1"]', '$[*].time_tz(2) ? (@ >= "12:35:00.123 +1".time_tz(2))');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ == "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ >= "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query_tz ('["12:34:00+01", "12:35:00+01", "12:36:00+01", "12:35:00+02", "12:35:00-02", "10:35:00", "11:35:00", "12:35:00", "2017-03-10 12:35:00 +1"]', '$[*].time_tz() ? (@ <  "12:35:00 +1".time_tz())');

SELECT
    jsonb_path_query_tz ('["12:34:00.123+01", "12:35:00.123+01", "12:36:00.1123+01", "12:35:00.1123+02", "12:35:00.123-02", "10:35:00.123", "11:35:00.1", "12:35:00.123", "2017-03-10 12:35:00.123 +1"]', '$[*].time_tz(2) ? (@ >= "12:35:00.123 +1".time_tz(2))');

-- timestamp comparison
SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ == "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ >= "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ < "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ == "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ >= "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ < "10.03.2017 12:35".datetime("dd.mm.yyyy HH24:MI"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ == "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ >= "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ < "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ == "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ >= "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ < "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00.123", "2017-03-10 12:35:00.123", "2017-03-10 12:36:00.1123", "2017-03-10 12:35:00.1123+01", "2017-03-10 13:35:00.123+01", "2017-03-10 12:35:00.1-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp(2) ? (@ >= "2017-03-10 12:35:00.123".timestamp(2))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ == "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ >= "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00", "2017-03-10 12:35:00", "2017-03-10 12:36:00", "2017-03-10 12:35:00+01", "2017-03-10 13:35:00+01", "2017-03-10 12:35:00-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp() ? (@ < "2017-03-10 12:35:00".timestamp())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00.123", "2017-03-10 12:35:00.123", "2017-03-10 12:36:00.1123", "2017-03-10 12:35:00.1123+01", "2017-03-10 13:35:00.123+01", "2017-03-10 12:35:00.1-01", "2017-03-10", "2017-03-11"]', '$[*].timestamp(2) ? (@ >= "2017-03-10 12:35:00.123".timestamp(2))');

-- timestamptz comparison
SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ == "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ >= "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ < "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ == "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ >= "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11", "12:34:56", "12:34:56+01"]', '$[*].datetime() ? (@ < "10.03.2017 12:35 +1".datetime("dd.mm.yyyy HH24:MI TZH"))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ == "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ >= "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].datetime() ? (@ < "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ == "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ >= "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ < "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query('["2017-03-10 12:34:00.123+01", "2017-03-10 12:35:00.123+01", "2017-03-10 12:36:00.1123+01", "2017-03-10 12:35:00.1123+02", "2017-03-10 12:35:00.123-02", "2017-03-10 10:35:00.123", "2017-03-10 11:35:00.1", "2017-03-10 12:35:00.123", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz(2) ? (@ >= "2017-03-10 12:35:00.123 +1".timestamp_tz(2))');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ == "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ >= "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00+01", "2017-03-10 12:35:00+01", "2017-03-10 12:36:00+01", "2017-03-10 12:35:00+02", "2017-03-10 12:35:00-02", "2017-03-10 10:35:00", "2017-03-10 11:35:00", "2017-03-10 12:35:00", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz() ? (@ < "2017-03-10 12:35:00 +1".timestamp_tz())');

SELECT
    jsonb_path_query_tz ('["2017-03-10 12:34:00.123+01", "2017-03-10 12:35:00.123+01", "2017-03-10 12:36:00.1123+01", "2017-03-10 12:35:00.1123+02", "2017-03-10 12:35:00.123-02", "2017-03-10 10:35:00.123", "2017-03-10 11:35:00.1", "2017-03-10 12:35:00.123", "2017-03-10", "2017-03-11"]', '$[*].timestamp_tz(2) ? (@ >= "2017-03-10 12:35:00.123 +1".timestamp_tz(2))');

-- overflow during comparison
SELECT
    jsonb_path_query('"1000000-01-01"', '$.datetime() > "2020-01-01 12:00:00".datetime()'::jsonpath);

SET time zone DEFAULT;

-- jsonpath operators
SELECT
    jsonb_path_query('[{"a": 1}, {"a": 2}]', '$[*]');

SELECT
    jsonb_path_query('[{"a": 1}, {"a": 2}]', '$[*] ? (@.a > 10)');

SELECT
    jsonb_path_query('[{"a": 1}]', '$undefined_var');

SELECT
    jsonb_path_query('[{"a": 1}]', 'false');

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
    jsonb_path_query_first('[{"a": 1}]', '$undefined_var');

SELECT
    jsonb_path_query_first('[{"a": 1}]', 'false');

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
    jsonb_path_exists('[{"a": 1}]', '$undefined_var');

SELECT
    jsonb_path_exists('[{"a": 1}]', 'false');

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

SELECT
    jsonb_path_match('[{"a": 1}]', '$undefined_var');

SELECT
    jsonb_path_match('[{"a": 1}]', 'false');

-- test string comparison (Unicode codepoint collation)
WITH str (
    j,
    num
) AS (
    SELECT
        jsonb_build_object(
            's', s
        ),
        num
    FROM
        unnest('{"", "a", "ab", "abc", "abcd", "b", "A", "AB", "ABC", "ABc", "ABcD", "B"}'::text[])
        WITH ORDINALITY AS a (s, num)
)
SELECT
    s1.j,
    s2.j,
    jsonb_path_query_first(s1.j, '$.s < $s', vars => s2.j) lt,
    jsonb_path_query_first(s1.j, '$.s <= $s', vars => s2.j) le,
    jsonb_path_query_first(s1.j, '$.s == $s', vars => s2.j) eq,
    jsonb_path_query_first(s1.j, '$.s >= $s', vars => s2.j) ge,
    jsonb_path_query_first(s1.j, '$.s > $s', vars => s2.j) gt
FROM
    str s1,
    str s2
ORDER BY
    s1.num,
    s2.num;

