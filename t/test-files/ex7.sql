-- From 9.4 JSON page - examples
SELECT '[{"a":"foo"},{"b":"bar"},{"c":"baz"}]'::json -> 2;
SELECT '{"a": {"b":"foo"}}'::json -> 'a';
SELECT '[1,2,3]'::json ->> 2;
SELECT '{"a":1,"b":2}'::json ->> 'b';
SELECT '{"a": {"b":{"c": "foo"}}}'::json #> '{a,b}';
SELECT '{"a":[1,2,3],"b":[4,5,6]}'::json #>> '{a,2}';
-- From 9.4 JSON page - jsonb examples
SELECT '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;
SELECT '{"b":2}'::jsonb <@ '{"a":1, "b":2}'::jsonb;
SELECT '{"a":1, "b":2}'::jsonb ? 'b';
SELECT '{"a":1, "b":2, "c":3}'::jsonb ?| ARRAY [ 'b', 'c' ];
SELECT '{"a":1, "b":2, "c":3}'::jsonb ?| ARRAY [ 'b', 'c' ];
SELECT '["a", "b"]'::jsonb ?& ARRAY [ 'a', 'b' ];
SELECT '{"a": {"b":{"c": "foo"}}}'::json#>'{a,b}', '{"a":[1,2,3],"b":[4,5,6]}'::json#>>'{a,2}';
