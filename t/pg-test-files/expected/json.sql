-- Strings.
SELECT
    '""'::json;

-- OK.
SELECT
    $$ ''$$::json;

-- ERROR, single quotes are not allowed
SELECT
    '"abc"'::json;

-- OK
SELECT
    '"abc'::json;

-- ERROR, quotes not closed
SELECT
    '"abc
def"'::json;

-- ERROR, unescaped newline in string constant
SELECT
    '"\n\"\\"'::json;

-- OK, legal escapes
SELECT
    '"\v"'::json;

-- ERROR, not a valid JSON escape
-- see json_encoding test for input with unicode escapes
-- Numbers.
SELECT
    '1'::json;

-- OK
SELECT
    '0'::json;

-- OK
SELECT
    '01'::json;

-- ERROR, not valid according to JSON spec
SELECT
    '0.1'::json;

-- OK
SELECT
    '9223372036854775808'::json;

-- OK, even though it's too large for int8
SELECT
    '1e100'::json;

-- OK
SELECT
    '1.3e100'::json;

-- OK
SELECT
    '1f2'::json;

-- ERROR
SELECT
    '0.x1'::json;

-- ERROR
SELECT
    '1.3ex100'::json;

-- ERROR
-- Arrays.
SELECT
    '[]'::json;

-- OK
SELECT
    '[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]'::json;

-- OK
SELECT
    '[1,2]'::json;

-- OK
SELECT
    '[1,2,]'::json;

-- ERROR, trailing comma
SELECT
    '[1,2'::json;

-- ERROR, no closing bracket
SELECT
    '[1,[2]'::json;

-- ERROR, no closing bracket
-- Objects.
SELECT
    '{}'::json;

-- OK
SELECT
    '{"abc"}'::json;

-- ERROR, no value
SELECT
    '{"abc":1}'::json;

-- OK
SELECT
    '{1:"abc"}'::json;

-- ERROR, keys must be strings
SELECT
    '{"abc",1}'::json;

-- ERROR, wrong separator
SELECT
    '{"abc"=1}'::json;

-- ERROR, totally wrong separator
SELECT
    '{"abc"::1}'::json;

-- ERROR, another wrong separator
SELECT
    '{"abc":1,"def":2,"ghi":[3,4],"hij":{"klm":5,"nop":[6]}}'::json;

-- OK
SELECT
    '{"abc":1:2}'::json;

-- ERROR, colon in wrong spot
SELECT
    '{"abc":1,3}'::json;

-- ERROR, no value
-- Recursion.
SET max_stack_depth = '100kB';

SELECT
    repeat('[', 10000)::json;

SELECT
    repeat('{"a":', 10000)::json;

RESET max_stack_depth;

-- Miscellaneous stuff.
SELECT
    'true'::json;

-- OK
SELECT
    'false'::json;

-- OK
SELECT
    'null'::json;

-- OK
SELECT
    ' true '::json;

-- OK, even with extra whitespace
SELECT
    'true false'::json;

-- ERROR, too many values
SELECT
    'true, false'::json;

-- ERROR, too many values
SELECT
    'truf'::json;

-- ERROR, not a keyword
SELECT
    'trues'::json;

-- ERROR, not a keyword
SELECT
    ''::json;

-- ERROR, no value
SELECT
    '    '::json;

-- ERROR, no value
--constructors
-- array_to_json
SELECT
    array_to_json(ARRAY (
            SELECT
                1 AS a));

SELECT
    array_to_json(array_agg(q), FALSE)
FROM (
    SELECT
        x AS b,
        x * 2 AS c
    FROM
        generate_series(1, 3) x) q;

SELECT
    array_to_json(array_agg(q), TRUE)
FROM (
    SELECT
        x AS b,
        x * 2 AS c
    FROM
        generate_series(1, 3) x) q;

SELECT
    array_to_json(array_agg(q), FALSE)
FROM (
    SELECT
        $$ a$$ || x AS b,
        y AS c,
        ARRAY[ROW (x.*, ARRAY[1, 2, 3]), ROW (y.*, ARRAY[4, 5, 6])] AS z
    FROM
        generate_series(1, 2) x,
        generate_series(4, 5) y) q;

SELECT
    array_to_json(array_agg(x), FALSE)
FROM
    generate_series(5, 10) x;

SELECT
    array_to_json('{{1,5},{99,100}}'::int[]);

-- row_to_json
SELECT
    row_to_json(ROW (1, 'foo'));

SELECT
    row_to_json(q)
FROM (
    SELECT
        $$ a$$ || x AS b,
        y AS c,
        ARRAY[ROW (x.*, ARRAY[1, 2, 3]), ROW (y.*, ARRAY[4, 5, 6])] AS z
    FROM
        generate_series(1, 2) x,
        generate_series(4, 5) y) q;

SELECT
    row_to_json(q, TRUE)
FROM (
    SELECT
        $$ a$$ || x AS b,
        y AS c,
        ARRAY[ROW (x.*, ARRAY[1, 2, 3]), ROW (y.*, ARRAY[4, 5, 6])] AS z
    FROM
        generate_series(1, 2) x,
        generate_series(4, 5) y) q;

CREATE TEMP TABLE ROWS AS
SELECT
    x,
    'txt' || x AS y
FROM
    generate_series(1, 3) AS x;

SELECT
    row_to_json(q, TRUE)
FROM
    ROWS q;

SELECT
    row_to_json(ROW ((
            SELECT
                array_agg(x) AS d FROM generate_series(5, 10) x)), FALSE);

-- anyarray column
SELECT
    to_json(histogram_bounds) histogram_bounds
FROM
    pg_stats
WHERE
    attname = 'tmplname'
    AND tablename = 'pg_pltemplate';

-- to_json, timestamps
SELECT
    to_json(timestamp '2014-05-28 12:22:35.614298');

BEGIN;
SET LOCAL TIME ZONE 10.5;
SELECT
    to_json(timestamptz '2014-05-28 12:22:35.614298-04');
SET LOCAL TIME ZONE - 8;
SELECT
    to_json(timestamptz '2014-05-28 12:22:35.614298-04');
COMMIT;

SELECT
    to_json(date '2014-05-28');

SELECT
    to_json(date 'Infinity');

SELECT
    to_json(date '-Infinity');

SELECT
    to_json(timestamp 'Infinity');

SELECT
    to_json(timestamp '-Infinity');

SELECT
    to_json(timestamptz 'Infinity');

SELECT
    to_json(timestamptz '-Infinity');

--json_agg
SELECT
    json_agg(q)
FROM (
    SELECT
        $$ a$$ || x AS b,
        y AS c,
        ARRAY[ROW (x.*, ARRAY[1, 2, 3]), ROW (y.*, ARRAY[4, 5, 6])] AS z
    FROM
        generate_series(1, 2) x,
        generate_series(4, 5) y) q;

SELECT
    json_agg(q ORDER BY x, y)
FROM
    ROWS q;

UPDATE
    ROWS
SET
    x = NULL
WHERE
    x = 1;

SELECT
    json_agg(q ORDER BY x NULLS FIRST, y)
FROM
    ROWS q;

-- non-numeric output
SELECT
    row_to_json(q)
FROM (
    SELECT
        'NaN'::float8 AS "float8field") q;

SELECT
    row_to_json(q)
FROM (
    SELECT
        'Infinity'::float8 AS "float8field") q;

SELECT
    row_to_json(q)
FROM (
    SELECT
        '-Infinity'::float8 AS "float8field") q;

-- json input
SELECT
    row_to_json(q)
FROM (
    SELECT
        '{"a":1,"b": [2,3,4,"d","e","f"],"c":{"p":1,"q":2}}'::json AS "jsonfield") q;

-- json extraction functions
CREATE TEMP TABLE test_json (
    json_type text,
    test_json json
);

INSERT INTO test_json
VALUES
    ('scalar', '"a scalar"'),
    ('array', '["zero", "one","two",null,"four","five", [1,2,3],{"f1":9}]'),
    ('object', '{"field1":"val1","field2":"val2","field3":null, "field4": 4, "field5": [1,2,3], "field6": {"f1":9}}');

SELECT
    test_json -> 'x'
FROM
    test_json
WHERE
    json_type = 'scalar';

SELECT
    test_json -> 'x'
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json -> 'x'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json -> 'field2'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json ->> 'field2'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json -> 2
FROM
    test_json
WHERE
    json_type = 'scalar';

SELECT
    test_json -> 2
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json -> - 1
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json -> 2
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json ->> 2
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json ->> 6
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json ->> 7
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    test_json ->> 'field4'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json ->> 'field5'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    test_json ->> 'field6'
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    json_object_keys(test_json)
FROM
    test_json
WHERE
    json_type = 'scalar';

SELECT
    json_object_keys(test_json)
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    json_object_keys(test_json)
FROM
    test_json
WHERE
    json_type = 'object';

-- test extending object_keys resultset - initial resultset size is 256
SELECT
    count(*)
FROM (
    SELECT
        json_object_keys(json_object(array_agg(g)))
    FROM (
        SELECT
            unnest(ARRAY['f' || n, n::text]) AS g
        FROM
            generate_series(1, 300) AS n) x) y;

-- nulls
SELECT
    (test_json -> 'field3') IS NULL AS expect_false
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    (test_json ->> 'field3') IS NULL AS expect_true
FROM
    test_json
WHERE
    json_type = 'object';

SELECT
    (test_json -> 3) IS NULL AS expect_false
FROM
    test_json
WHERE
    json_type = 'array';

SELECT
    (test_json ->> 3) IS NULL AS expect_true
FROM
    test_json
WHERE
    json_type = 'array';

-- corner cases
SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> NULL::text;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> NULL::int;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> 1;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> - 1;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> 'z';

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json -> '';

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json -> 1;

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json -> 3;

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json -> 'z';

SELECT
    '{"a": "c", "b": null}'::json -> 'b';

SELECT
    '"foo"'::json -> 1;

SELECT
    '"foo"'::json -> 'z';

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json ->> NULL::text;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json ->> NULL::int;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json ->> 1;

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json ->> 'z';

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json ->> '';

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json ->> 1;

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json ->> 3;

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json ->> 'z';

SELECT
    '{"a": "c", "b": null}'::json ->> 'b';

SELECT
    '"foo"'::json ->> 1;

SELECT
    '"foo"'::json ->> 'z';

-- array length
SELECT
    json_array_length('[1,2,3,{"f1":1,"f2":[5,6]},4]');

SELECT
    json_array_length('[]');

SELECT
    json_array_length('{"f1":1,"f2":[5,6]}');

SELECT
    json_array_length('4');

-- each
SELECT
    json_each('{"f1":[1,2,3],"f2":{"f3":1},"f4":null}');

SELECT
    *
FROM
    json_each('{"f1":[1,2,3],"f2":{"f3":1},"f4":null,"f5":99,"f6":"stringy"}') q;

SELECT
    json_each_text('{"f1":[1,2,3],"f2":{"f3":1},"f4":null,"f5":"null"}');

SELECT
    *
FROM
    json_each_text('{"f1":[1,2,3],"f2":{"f3":1},"f4":null,"f5":99,"f6":"stringy"}') q;

-- extract_path, extract_path_as_text
SELECT
    json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}', 'f4', 'f6');

SELECT
    json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}', 'f2');

SELECT
    json_extract_path('{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}', 'f2', 0::text);

SELECT
    json_extract_path('{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}', 'f2', 1::text);

SELECT
    json_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}', 'f4', 'f6');

SELECT
    json_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}', 'f2');

SELECT
    json_extract_path_text('{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}', 'f2', 0::text);

SELECT
    json_extract_path_text('{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}', 'f2', 1::text);

-- extract_path nulls
SELECT
    json_extract_path('{"f2":{"f3":1},"f4":{"f5":null,"f6":"stringy"}}', 'f4', 'f5') IS NULL AS expect_false;

SELECT
    json_extract_path_text('{"f2":{"f3":1},"f4":{"f5":null,"f6":"stringy"}}', 'f4', 'f5') IS NULL AS expect_true;

SELECT
    json_extract_path('{"f2":{"f3":1},"f4":[0,1,2,null]}', 'f4', '3') IS NULL AS expect_false;

SELECT
    json_extract_path_text('{"f2":{"f3":1},"f4":[0,1,2,null]}', 'f4', '3') IS NULL AS expect_true;

-- extract_path operators
SELECT
    '{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}'::json #> ARRAY['f4', 'f6'];

SELECT
    '{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}'::json #> ARRAY['f2'];

SELECT
    '{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}'::json #> ARRAY['f2', '0'];

SELECT
    '{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}'::json #> ARRAY['f2', '1'];

SELECT
    '{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}'::json #>> ARRAY['f4', 'f6'];

SELECT
    '{"f2":{"f3":1},"f4":{"f5":99,"f6":"stringy"}}'::json #>> ARRAY['f2'];

SELECT
    '{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}'::json #>> ARRAY['f2', '0'];

SELECT
    '{"f2":["f3",1],"f4":{"f5":99,"f6":"stringy"}}'::json #>> ARRAY['f2', '1'];

-- corner cases for same
SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> '{}';

SELECT
    '[1,2,3]'::json #> '{}';

SELECT
    '"foo"'::json #> '{}';

SELECT
    '42'::json #> '{}';

SELECT
    'null'::json #> '{}';

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', NULL];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', ''];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', 'b'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', 'b', 'c'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', 'b', 'c', 'd'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #> ARRAY['a', 'z', 'c'];

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json #> ARRAY['a', '1', 'b'];

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json #> ARRAY['a', 'z', 'b'];

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json #> ARRAY['1', 'b'];

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json #> ARRAY['z', 'b'];

SELECT
    '[{"b": "c"}, {"b": null}]'::json #> ARRAY['1', 'b'];

SELECT
    '"foo"'::json #> ARRAY['z'];

SELECT
    '42'::json #> ARRAY['f2'];

SELECT
    '42'::json #> ARRAY['0'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> '{}';

SELECT
    '[1,2,3]'::json #>> '{}';

SELECT
    '"foo"'::json #>> '{}';

SELECT
    '42'::json #>> '{}';

SELECT
    'null'::json #>> '{}';

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', NULL];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', ''];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', 'b'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', 'b', 'c'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', 'b', 'c', 'd'];

SELECT
    '{"a": {"b":{"c": "foo"}}}'::json #>> ARRAY['a', 'z', 'c'];

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json #>> ARRAY['a', '1', 'b'];

SELECT
    '{"a": [{"b": "c"}, {"b": "cc"}]}'::json #>> ARRAY['a', 'z', 'b'];

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json #>> ARRAY['1', 'b'];

SELECT
    '[{"b": "c"}, {"b": "cc"}]'::json #>> ARRAY['z', 'b'];

SELECT
    '[{"b": "c"}, {"b": null}]'::json #>> ARRAY['1', 'b'];

SELECT
    '"foo"'::json #>> ARRAY['z'];

SELECT
    '42'::json #>> ARRAY['f2'];

SELECT
    '42'::json #>> ARRAY['0'];

-- array_elements
SELECT
    json_array_elements('[1,true,[1,[2,3]],null,{"f1":1,"f2":[7,8,9]},false,"stringy"]');

SELECT
    *
FROM
    json_array_elements('[1,true,[1,[2,3]],null,{"f1":1,"f2":[7,8,9]},false,"stringy"]') q;

SELECT
    json_array_elements_text('[1,true,[1,[2,3]],null,{"f1":1,"f2":[7,8,9]},false,"stringy"]');

SELECT
    *
FROM
    json_array_elements_text('[1,true,[1,[2,3]],null,{"f1":1,"f2":[7,8,9]},false,"stringy"]') q;

-- populate_record
CREATE TYPE jpop AS (
    a text,
    b int,
    c timestamp
);

CREATE DOMAIN js_int_not_null AS int NOT NULL;

CREATE DOMAIN js_int_array_1d AS int[] CHECK (array_length(VALUE, 1) = 3);

CREATE DOMAIN js_int_array_2d AS int[][] CHECK (array_length(VALUE, 2) = 3);

CREATE TYPE j_unordered_pair AS (
    x int,
    y int
);

CREATE DOMAIN j_ordered_pair AS j_unordered_pair CHECK ((value).x <= (value).y);

CREATE TYPE jsrec AS (
    i int,
    ia _int4,
    ia1 int[],
    ia2 int[][],
    ia3 int[][][],
    ia1d js_int_array_1d,
    ia2d js_int_array_2d,
    t text,
    ta text[],
    c char(10),
    ca char(10)[],
    ts timestamp,
    js json,
    jsb jsonb,
    jsa json[],
    rec jpop,
    reca jpop[]
);

CREATE TYPE jsrec_i_not_null AS (
    i js_int_not_null
);

SELECT
    *
FROM
    json_populate_record(NULL::jpop, '{"a":"blurfl","x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(ROW ('x', 3, '2012-12-31 15:30:56')::jpop, '{"a":"blurfl","x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(NULL::jpop, '{"a":"blurfl","x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(ROW ('x', 3, '2012-12-31 15:30:56')::jpop, '{"a":"blurfl","x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(NULL::jpop, '{"a":[100,200,false],"x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(ROW ('x', 3, '2012-12-31 15:30:56')::jpop, '{"a":[100,200,false],"x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(ROW ('x', 3, '2012-12-31 15:30:56')::jpop, '{"c":[100,200,false],"x":43.2}') q;

SELECT
    *
FROM
    json_populate_record(ROW ('x', 3, '2012-12-31 15:30:56')::jpop, '{}') q;

SELECT
    i
FROM
    json_populate_record(NULL::jsrec_i_not_null, '{"x": 43.2}') q;

SELECT
    i
FROM
    json_populate_record(NULL::jsrec_i_not_null, '{"i": null}') q;

SELECT
    i
FROM
    json_populate_record(NULL::jsrec_i_not_null, '{"i": 12345}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": null}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": 123}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": [1, "2", null, 4]}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": [[1, 2], [3, 4]]}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": [[1], 2]}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": [[1], [2, 3]]}') q;

SELECT
    ia
FROM
    json_populate_record(NULL::jsrec, '{"ia": "{1,2,3}"}') q;

SELECT
    ia1
FROM
    json_populate_record(NULL::jsrec, '{"ia1": null}') q;

SELECT
    ia1
FROM
    json_populate_record(NULL::jsrec, '{"ia1": 123}') q;

SELECT
    ia1
FROM
    json_populate_record(NULL::jsrec, '{"ia1": [1, "2", null, 4]}') q;

SELECT
    ia1
FROM
    json_populate_record(NULL::jsrec, '{"ia1": [[1, 2, 3]]}') q;

SELECT
    ia1d
FROM
    json_populate_record(NULL::jsrec, '{"ia1d": null}') q;

SELECT
    ia1d
FROM
    json_populate_record(NULL::jsrec, '{"ia1d": 123}') q;

SELECT
    ia1d
FROM
    json_populate_record(NULL::jsrec, '{"ia1d": [1, "2", null, 4]}') q;

SELECT
    ia1d
FROM
    json_populate_record(NULL::jsrec, '{"ia1d": [1, "2", null]}') q;

SELECT
    ia2
FROM
    json_populate_record(NULL::jsrec, '{"ia2": [1, "2", null, 4]}') q;

SELECT
    ia2
FROM
    json_populate_record(NULL::jsrec, '{"ia2": [[1, 2], [null, 4]]}') q;

SELECT
    ia2
FROM
    json_populate_record(NULL::jsrec, '{"ia2": [[], []]}') q;

SELECT
    ia2
FROM
    json_populate_record(NULL::jsrec, '{"ia2": [[1, 2], [3]]}') q;

SELECT
    ia2
FROM
    json_populate_record(NULL::jsrec, '{"ia2": [[1, 2], 3, 4]}') q;

SELECT
    ia2d
FROM
    json_populate_record(NULL::jsrec, '{"ia2d": [[1, "2"], [null, 4]]}') q;

SELECT
    ia2d
FROM
    json_populate_record(NULL::jsrec, '{"ia2d": [[1, "2", 3], [null, 5, 6]]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [1, "2", null, 4]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [[1, 2], [null, 4]]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [ [[], []], [[], []], [[], []] ]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [ [[1, 2]], [[3, 4]] ]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [ [[1, 2], [3, 4]], [[5, 6], [7, 8]] ]}') q;

SELECT
    ia3
FROM
    json_populate_record(NULL::jsrec, '{"ia3": [ [[1, 2], [3, 4]], [[5, 6], [7, 8], [9, 10]] ]}') q;

SELECT
    ta
FROM
    json_populate_record(NULL::jsrec, '{"ta": null}') q;

SELECT
    ta
FROM
    json_populate_record(NULL::jsrec, '{"ta": 123}') q;

SELECT
    ta
FROM
    json_populate_record(NULL::jsrec, '{"ta": [1, "2", null, 4]}') q;

SELECT
    ta
FROM
    json_populate_record(NULL::jsrec, '{"ta": [[1, 2, 3], {"k": "v"}]}') q;

SELECT
    c
FROM
    json_populate_record(NULL::jsrec, '{"c": null}') q;

SELECT
    c
FROM
    json_populate_record(NULL::jsrec, '{"c": "aaa"}') q;

SELECT
    c
FROM
    json_populate_record(NULL::jsrec, '{"c": "aaaaaaaaaa"}') q;

SELECT
    c
FROM
    json_populate_record(NULL::jsrec, '{"c": "aaaaaaaaaaaaa"}') q;

SELECT
    ca
FROM
    json_populate_record(NULL::jsrec, '{"ca": null}') q;

SELECT
    ca
FROM
    json_populate_record(NULL::jsrec, '{"ca": 123}') q;

SELECT
    ca
FROM
    json_populate_record(NULL::jsrec, '{"ca": [1, "2", null, 4]}') q;

SELECT
    ca
FROM
    json_populate_record(NULL::jsrec, '{"ca": ["aaaaaaaaaaaaaaaa"]}') q;

SELECT
    ca
FROM
    json_populate_record(NULL::jsrec, '{"ca": [[1, 2, 3], {"k": "v"}]}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": null}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": true}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": 123.45}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": "123.45"}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": "abc"}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": [123, "123", null, {"key": "value"}]}') q;

SELECT
    js
FROM
    json_populate_record(NULL::jsrec, '{"js": {"a": "bbb", "b": null, "c": 123.45}}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": null}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": true}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": 123.45}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": "123.45"}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": "abc"}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": [123, "123", null, {"key": "value"}]}') q;

SELECT
    jsb
FROM
    json_populate_record(NULL::jsrec, '{"jsb": {"a": "bbb", "b": null, "c": 123.45}}') q;

SELECT
    jsa
FROM
    json_populate_record(NULL::jsrec, '{"jsa": null}') q;

SELECT
    jsa
FROM
    json_populate_record(NULL::jsrec, '{"jsa": 123}') q;

SELECT
    jsa
FROM
    json_populate_record(NULL::jsrec, '{"jsa": [1, "2", null, 4]}') q;

SELECT
    jsa
FROM
    json_populate_record(NULL::jsrec, '{"jsa": ["aaa", null, [1, 2, "3", {}], { "k" : "v" }]}') q;

SELECT
    rec
FROM
    json_populate_record(NULL::jsrec, '{"rec": 123}') q;

SELECT
    rec
FROM
    json_populate_record(NULL::jsrec, '{"rec": [1, 2]}') q;

SELECT
    rec
FROM
    json_populate_record(NULL::jsrec, '{"rec": {"a": "abc", "c": "01.02.2003", "x": 43.2}}') q;

SELECT
    rec
FROM
    json_populate_record(NULL::jsrec, '{"rec": "(abc,42,01.02.2003)"}') q;

SELECT
    reca
FROM
    json_populate_record(NULL::jsrec, '{"reca": 123}') q;

SELECT
    reca
FROM
    json_populate_record(NULL::jsrec, '{"reca": [1, 2]}') q;

SELECT
    reca
FROM
    json_populate_record(NULL::jsrec, '{"reca": [{"a": "abc", "b": 456}, null, {"c": "01.02.2003", "x": 43.2}]}') q;

SELECT
    reca
FROM
    json_populate_record(NULL::jsrec, '{"reca": ["(abc,42,01.02.2003)"]}') q;

SELECT
    reca
FROM
    json_populate_record(NULL::jsrec, '{"reca": "{\"(abc,42,01.02.2003)\"}"}') q;

SELECT
    rec
FROM
    json_populate_record(ROW (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ROW ('x', 3, '2012-12-31 15:30:56')::jpop, NULL)::jsrec, '{"rec": {"a": "abc", "c": "01.02.2003", "x": 43.2}}') q;

-- anonymous record type
SELECT
    json_populate_record(NULL::record, '{"x": 0, "y": 1}');

SELECT
    json_populate_record(ROW (1, 2), '{"f1": 0, "f2": 1}');

-- composite domain
SELECT
    json_populate_record(NULL::j_ordered_pair, '{"x": 0, "y": 1}');

SELECT
    json_populate_record(ROW (1, 2)::j_ordered_pair, '{"x": 0}');

SELECT
    json_populate_record(ROW (1, 2)::j_ordered_pair, '{"x": 1, "y": 0}');

-- populate_recordset
SELECT
    *
FROM
    json_populate_recordset(NULL::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(NULL::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"a":[100,200,300],"x":43.2},{"a":{"z":true},"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"c":[100,200,300],"x":43.2},{"a":{"z":true},"b":3,"c":"2012-01-20 10:42:53"}]') q;

CREATE TYPE jpop2 AS (
    a int,
    b json,
    c int,
    d int
);

SELECT
    *
FROM
    json_populate_recordset(NULL::jpop2, '[{"a":2,"c":3,"b":{"z":4},"d":6}]') q;

SELECT
    *
FROM
    json_populate_recordset(NULL::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"a":"blurfl","x":43.2},{"b":3,"c":"2012-01-20 10:42:53"}]') q;

SELECT
    *
FROM
    json_populate_recordset(ROW ('def', 99, NULL)::jpop, '[{"a":[100,200,300],"x":43.2},{"a":{"z":true},"b":3,"c":"2012-01-20 10:42:53"}]') q;

-- anonymous record type
SELECT
    json_populate_recordset(NULL::record, '[{"x": 0, "y": 1}]');

SELECT
    json_populate_recordset(ROW (1, 2), '[{"f1": 0, "f2": 1}]');

SELECT
    i,
    json_populate_recordset(ROW (i, 50), '[{"f1":"42"},{"f2":"43"}]')
FROM (
    VALUES (1),
        (2)) v (i);

-- empty array is a corner case
SELECT
    json_populate_recordset(NULL::record, '[]');

SELECT
    json_populate_recordset(ROW (1, 2), '[]');

SELECT
    *
FROM
    json_populate_recordset(NULL::jpop, '[]') q;

-- composite domain
SELECT
    json_populate_recordset(NULL::j_ordered_pair, '[{"x": 0, "y": 1}]');

SELECT
    json_populate_recordset(ROW (1, 2)::j_ordered_pair, '[{"x": 0}, {"y": 3}]');

SELECT
    json_populate_recordset(ROW (1, 2)::j_ordered_pair, '[{"x": 1, "y": 0}]');

-- negative cases where the wrong record type is supplied
SELECT
    *
FROM
    json_populate_recordset(ROW (0::int), '[{"a":"1","b":"2"},{"a":"3"}]') q (a text,
        b text);

SELECT
    *
FROM
    json_populate_recordset(ROW (0::int, 0::int), '[{"a":"1","b":"2"},{"a":"3"}]') q (a text,
        b text);

SELECT
    *
FROM
    json_populate_recordset(ROW (0::int, 0::int, 0::int), '[{"a":"1","b":"2"},{"a":"3"}]') q (a text,
        b text);

SELECT
    *
FROM
    json_populate_recordset(ROW (1000000000::int, 50::int), '[{"b":"2"},{"a":"3"}]') q (a text,
        b text);

-- test type info caching in json_populate_record()
CREATE TEMP TABLE jspoptest (
    js json
);

INSERT INTO jspoptest
SELECT
    '{
	"jsa": [1, "2", null, 4],
	"rec": {"a": "abc", "c": "01.02.2003", "x": 43.2},
	"reca": [{"a": "abc", "b": 456}, null, {"c": "01.02.2003", "x": 43.2}]
}'::json
FROM
    generate_series(1, 3);

SELECT
    (json_populate_record(NULL::jsrec, js)).*
FROM
    jspoptest;

DROP TYPE jsrec;

DROP TYPE jsrec_i_not_null;

DROP DOMAIN js_int_not_null;

DROP DOMAIN js_int_array_1d;

DROP DOMAIN js_int_array_2d;

DROP DOMAIN j_ordered_pair;

DROP TYPE j_unordered_pair;

--json_typeof() function
SELECT
    value,
    json_typeof(value)
FROM (
    VALUES (json '123.4'),
        (json '-1'),
        (json '"foo"'),
        (json 'true'),
        (json 'false'),
        (json 'null'),
        (json '[1, 2, 3]'),
        (json '[]'),
        (json '{"x":"foo", "y":123}'),
        (json '{}'),
        (NULL::json)) AS data (value);

-- json_build_array, json_build_object, json_object_agg
SELECT
    json_build_array('a', 1, 'b', 1.2, 'c', TRUE, 'd', NULL, 'e', json '{"x": 3, "y": [1,2,3]}');

SELECT
    json_build_array('a', NULL);

-- ok
SELECT
    json_build_array(VARIADIC NULL::text[]);

-- ok
SELECT
    json_build_array(VARIADIC '{}'::text[]);

-- ok
SELECT
    json_build_array(VARIADIC '{a,b,c}'::text[]);

-- ok
SELECT
    json_build_array(VARIADIC ARRAY['a', NULL]::text[]);

-- ok
SELECT
    json_build_array(VARIADIC '{1,2,3,4}'::text[]);

-- ok
SELECT
    json_build_array(VARIADIC '{1,2,3,4}'::int[]);

-- ok
SELECT
    json_build_array(VARIADIC '{{1,4},{2,5},{3,6}}'::int[][]);

-- ok
SELECT
    json_build_object('a', 1, 'b', 1.2, 'c', TRUE, 'd', NULL, 'e', json '{"x": 3, "y": [1,2,3]}');

SELECT
    json_build_object('a', json_build_object('b', FALSE, 'c', 99), 'd', json_build_object('e', ARRAY[9, 8, 7]::int[], 'f', (
                SELECT
                    row_to_json(r)
                FROM (
                    SELECT
                        relkind, oid::regclass AS name
                    FROM pg_class
                    WHERE
                        relname = 'pg_class') r)));

SELECT
    json_build_object('{a,b,c}'::text[]);

-- error
SELECT
    json_build_object('{a,b,c}'::text[], '{d,e,f}'::text[]);

-- error, key cannot be array
SELECT
    json_build_object('a', 'b', 'c');

-- error
SELECT
    json_build_object(NULL, 'a');

-- error, key cannot be NULL
SELECT
    json_build_object('a', NULL);

-- ok
SELECT
    json_build_object(VARIADIC NULL::text[]);

-- ok
SELECT
    json_build_object(VARIADIC '{}'::text[]);

-- ok
SELECT
    json_build_object(VARIADIC '{a,b,c}'::text[]);

-- error
SELECT
    json_build_object(VARIADIC ARRAY['a', NULL]::text[]);

-- ok
SELECT
    json_build_object(VARIADIC ARRAY[NULL, 'a']::text[]);

-- error, key cannot be NULL
SELECT
    json_build_object(VARIADIC '{1,2,3,4}'::text[]);

-- ok
SELECT
    json_build_object(VARIADIC '{1,2,3,4}'::int[]);

-- ok
SELECT
    json_build_object(VARIADIC '{{1,4},{2,5},{3,6}}'::int[][]);

-- ok
-- empty objects/arrays
SELECT
    json_build_array();

SELECT
    json_build_object();

-- make sure keys are quoted
SELECT
    json_build_object(1, 2);

-- keys must be scalar and not null
SELECT
    json_build_object(NULL, 2);

SELECT
    json_build_object(r, 2)
FROM (
    SELECT
        1 AS a,
        2 AS b) r;

SELECT
    json_build_object(json '{"a":1,"b":2}', 3);

SELECT
    json_build_object('{1,2,3}'::int[], 3);

CREATE TEMP TABLE foo (
    serial_num int,
    name text,
    type text
);

INSERT INTO foo
    VALUES (847001, 't15', 'GE1043');

INSERT INTO foo
    VALUES (847002, 't16', 'GE1043');

INSERT INTO foo
    VALUES (847003, 'sub-alpha', 'GESS90');

SELECT
    json_build_object('turbines', json_object_agg(serial_num, json_build_object('name', name, 'type', type)))
FROM
    foo;

SELECT
    json_object_agg(name, type)
FROM
    foo;

INSERT INTO foo
    VALUES (999999, NULL, 'bar');

SELECT
    json_object_agg(name, type)
FROM
    foo;

-- json_object
-- empty object, one dimension
SELECT
    json_object('{}');

-- empty object, two dimensions
SELECT
    json_object('{}', '{}');

-- one dimension
SELECT
    json_object('{a,1,b,2,3,NULL,"d e f","a b c"}');

-- same but with two dimensions
SELECT
    json_object('{{a,1},{b,2},{3,NULL},{"d e f","a b c"}}');

-- odd number error
SELECT
    json_object('{a,b,c}');

-- one column error
SELECT
    json_object('{{a},{b}}');

-- too many columns error
SELECT
    json_object('{{a,b,c},{b,c,d}}');

-- too many dimensions error
SELECT
    json_object('{{{a,b},{c,d}},{{b,c},{d,e}}}');

--two argument form of json_object
SELECT
    json_object('{a,b,c,"d e f"}', '{1,2,3,"a b c"}');

-- too many dimensions
SELECT
    json_object('{{a,1},{b,2},{3,NULL},{"d e f","a b c"}}', '{{a,1},{b,2},{3,NULL},{"d e f","a b c"}}');

-- mismatched dimensions
SELECT
    json_object('{a,b,c,"d e f",g}', '{1,2,3,"a b c"}');

SELECT
    json_object('{a,b,c,"d e f"}', '{1,2,3,"a b c",g}');

-- null key error
SELECT
    json_object('{a,b,NULL,"d e f"}', '{1,2,3,"a b c"}');

-- empty key is allowed
SELECT
    json_object('{a,b,"","d e f"}', '{1,2,3,"a b c"}');

-- json_to_record and json_to_recordset
SELECT
    *
FROM
    json_to_record('{"a":1,"b":"foo","c":"bar"}') AS x (a int,
        b text,
        d text);

SELECT
    *
FROM
    json_to_recordset('[{"a":1,"b":"foo","d":false},{"a":2,"b":"bar","c":true}]') AS x (a int,
        b text,
        c boolean);

SELECT
    *
FROM
    json_to_recordset('[{"a":1,"b":{"d":"foo"},"c":true},{"a":2,"c":false,"b":{"d":"bar"}}]') AS x (a int,
        b json,
        c boolean);

SELECT
    *,
    c IS NULL AS c_is_null
FROM
    json_to_record('{"a":1, "b":{"c":16, "d":2}, "x":8, "ca": ["1 2", 3], "ia": [[1,2],[3,4]], "r": {"a": "aaa", "b": 123}}'::json) AS t (a int,
        b json,
        c text,
        x int,
        ca char(5)[],
        ia int[][],
        r jpop);

SELECT
    *,
    c IS NULL AS c_is_null
FROM
    json_to_recordset('[{"a":1, "b":{"c":16, "d":2}, "x":8}]'::json) AS t (a int,
        b json,
        c text,
        x int);

SELECT
    *
FROM
    json_to_record('{"ia": null}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia": 123}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia": [1, "2", null, 4]}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia": [[1, 2], [3, 4]]}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia": [[1], 2]}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia": [[1], [2, 3]]}') AS x (ia _int4);

SELECT
    *
FROM
    json_to_record('{"ia2": [1, 2, 3]}') AS x (ia2 int[][]);

SELECT
    *
FROM
    json_to_record('{"ia2": [[1, 2], [3, 4]]}') AS x (ia2 int4[][]);

SELECT
    *
FROM
    json_to_record('{"ia2": [[[1], [2], [3]]]}') AS x (ia2 int4[][]);

-- json_strip_nulls
SELECT
    json_strip_nulls (NULL);

SELECT
    json_strip_nulls ('1');

SELECT
    json_strip_nulls ('"a string"');

SELECT
    json_strip_nulls ('null');

SELECT
    json_strip_nulls ('[1,2,null,3,4]');

SELECT
    json_strip_nulls ('{"a":1,"b":null,"c":[2,null,3],"d":{"e":4,"f":null}}');

SELECT
    json_strip_nulls ('[1,{"a":1,"b":null,"c":2},3]');

-- an empty object is not null and should not be stripped
SELECT
    json_strip_nulls ('{"a": {"b": null, "c": null}, "d": {} }');

-- json to tsvector
SELECT
    to_tsvector('{"a": "aaa bbb ddd ccc", "b": ["eee fff ggg"], "c": {"d": "hhh iii"}}'::json);

-- json to tsvector with config
SELECT
    to_tsvector('simple', '{"a": "aaa bbb ddd ccc", "b": ["eee fff ggg"], "c": {"d": "hhh iii"}}'::json);

-- json to tsvector with stop words
SELECT
    to_tsvector('english', '{"a": "aaa in bbb ddd ccc", "b": ["the eee fff ggg"], "c": {"d": "hhh. iii"}}'::json);

-- json to tsvector with numeric values
SELECT
    to_tsvector('english', '{"a": "aaa in bbb ddd ccc", "b": 123, "c": 456}'::json);

-- json_to_tsvector
SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"all"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"key"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"string"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"numeric"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"boolean"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '["string", "numeric"]');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"all"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"key"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"string"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"numeric"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '"boolean"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '["string", "numeric"]');

-- to_tsvector corner cases
SELECT
    to_tsvector('""'::json);

SELECT
    to_tsvector('{}'::json);

SELECT
    to_tsvector('[]'::json);

SELECT
    to_tsvector('null'::json);

-- json_to_tsvector corner cases
SELECT
    json_to_tsvector('""'::json, '"all"');

SELECT
    json_to_tsvector('{}'::json, '"all"');

SELECT
    json_to_tsvector('[]'::json, '"all"');

SELECT
    json_to_tsvector('null'::json, '"all"');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '""');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '{}');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '[]');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, 'null');

SELECT
    json_to_tsvector('english', '{"a": "aaa in bbb", "b": 123, "c": 456, "d": true, "f": false, "g": null}'::json, '["all", null]');

-- ts_headline for json
SELECT
    ts_headline('{"a": "aaa bbb", "b": {"c": "ccc ddd fff", "c1": "ccc1 ddd1"}, "d": ["ggg hhh", "iii jjj"]}'::json, tsquery('bbb & ddd & hhh'));

SELECT
    ts_headline('english', '{"a": "aaa bbb", "b": {"c": "ccc ddd fff"}, "d": ["ggg hhh", "iii jjj"]}'::json, tsquery('bbb & ddd & hhh'));

SELECT
    ts_headline('{"a": "aaa bbb", "b": {"c": "ccc ddd fff", "c1": "ccc1 ddd1"}, "d": ["ggg hhh", "iii jjj"]}'::json, tsquery('bbb & ddd & hhh'), 'StartSel = <, StopSel = >');

SELECT
    ts_headline('english', '{"a": "aaa bbb", "b": {"c": "ccc ddd fff", "c1": "ccc1 ddd1"}, "d": ["ggg hhh", "iii jjj"]}'::json, tsquery('bbb & ddd & hhh'), 'StartSel = <, StopSel = >');

-- corner cases for ts_headline with json
SELECT
    ts_headline('null'::json, tsquery('aaa & bbb'));

SELECT
    ts_headline('{}'::json, tsquery('aaa & bbb'));

SELECT
    ts_headline('[]'::json, tsquery('aaa & bbb'));

