-- Tests for multirange data types.
--
-- test input parser
--
-- negative tests; should fail
SELECT
    ''::textmultirange;

SELECT
    '{,}'::textmultirange;

SELECT
    '{(,)}.'::textmultirange;

SELECT
    '{[a,c),}'::textmultirange;

SELECT
    '{,[a,c)}'::textmultirange;

SELECT
    '{-[a,z)}'::textmultirange;

SELECT
    '{[a,z) - }'::textmultirange;

SELECT
    '{(",a)}'::textmultirange;

SELECT
    '{(,,a)}'::textmultirange;

SELECT
    '{(),a)}'::textmultirange;

SELECT
    '{(a,))}'::textmultirange;

SELECT
    '{(],a)}'::textmultirange;

SELECT
    '{(a,])}'::textmultirange;

SELECT
    '{[z,a]}'::textmultirange;

-- should succeed
SELECT
    '{}'::textmultirange;

SELECT
    '  {}  '::textmultirange;

SELECT
    ' { empty, empty }  '::textmultirange;

SELECT
    ' {( " a " " a ", " z " " z " )  }'::textmultirange;

SELECT
    textrange ('\\\\', repeat('a', 200))::textmultirange;

SELECT
    '{(,z)}'::textmultirange;

SELECT
    '{(a,)}'::textmultirange;

SELECT
    '{[,z]}'::textmultirange;

SELECT
    '{[a,]}'::textmultirange;

SELECT
    '{(,)}'::textmultirange;

SELECT
    '{[ , ]}'::textmultirange;

SELECT
    '{["",""]}'::textmultirange;

SELECT
    '{[",",","]}'::textmultirange;

SELECT
    '{["\\","\\"]}'::textmultirange;

SELECT
    '{["""","\""]}'::textmultirange;

SELECT
    '{(\\,a)}'::textmultirange;

SELECT
    '{((,z)}'::textmultirange;

SELECT
    '{([,z)}'::textmultirange;

SELECT
    '{(!,()}'::textmultirange;

SELECT
    '{(!,[)}'::textmultirange;

SELECT
    '{[a,a]}'::textmultirange;

SELECT
    '{[a,a],[a,b]}'::textmultirange;

SELECT
    '{[a,b), [b,e]}'::textmultirange;

SELECT
    '{[a,d), [b,f]}'::textmultirange;

SELECT
    '{[a,a],[b,b]}'::textmultirange;

-- without canonicalization, we can't join these:
SELECT
    '{[a,a], [b,b]}'::textmultirange;

-- with canonicalization, we can join these:
SELECT
    '{[1,2], [3,4]}'::int4multirange;

SELECT
    '{[a,a], [b,b], [c,c]}'::textmultirange;

SELECT
    '{[a,d], [b,e]}'::textmultirange;

SELECT
    '{[a,d), [d,e)}'::textmultirange;

-- these are allowed but normalize to empty:
SELECT
    '{[a,a)}'::textmultirange;

SELECT
    '{(a,a]}'::textmultirange;

SELECT
    '{(a,a)}'::textmultirange;

-- Also try it with non-error-throwing API
SELECT
    pg_input_is_valid ('{[1,2], [4,5]}', 'int4multirange');

SELECT
    pg_input_is_valid ('{[1,2], [4,5]', 'int4multirange');

SELECT
    *
FROM
    pg_input_error_info ('{[1,2], [4,5]', 'int4multirange');

SELECT
    pg_input_is_valid ('{[1,2], [4,zed]}', 'int4multirange');

SELECT
    *
FROM
    pg_input_error_info ('{[1,2], [4,zed]}', 'int4multirange');

--
-- test the constructor
---
SELECT
    textmultirange ();

SELECT
    textmultirange (textrange ('a', 'c'));

SELECT
    textmultirange (textrange ('a', 'c'), textrange ('f', 'g'));

SELECT
    textmultirange (textrange ('\\\\', repeat('a', 200)), textrange ('c', 'd'));

--
-- test casts, both a built-in range type and a user-defined one:
--
SELECT
    'empty'::int4range::int4multirange;

SELECT
    int4range(1, 3)::int4multirange;

SELECT
    int4range(1, NULL)::int4multirange;

SELECT
    int4range(NULL, NULL)::int4multirange;

SELECT
    'empty'::textrange::textmultirange;

SELECT
    textrange ('a', 'c')::textmultirange;

SELECT
    textrange ('a', NULL)::textmultirange;

SELECT
    textrange (NULL, NULL)::textmultirange;

--
-- test unnest(multirange) function
--
SELECT
    unnest(int4multirange (int4range('5', '6'), int4range('1', '2')));

SELECT
    unnest(textmultirange (textrange ('a', 'b'), textrange ('d', 'e')));

SELECT
    unnest(textmultirange (textrange ('\\\\', repeat('a', 200)), textrange ('c', 'd')));

--
-- create some test data and test the operators
--
CREATE TABLE nummultirange_test (
    nmr NUMMULTIRANGE
);

CREATE INDEX nummultirange_test_btree ON nummultirange_test (nmr);

INSERT INTO nummultirange_test
    VALUES ('{}');

INSERT INTO nummultirange_test
    VALUES ('{[,)}');

INSERT INTO nummultirange_test
    VALUES ('{[3,]}');

INSERT INTO nummultirange_test
    VALUES ('{[,), [3,]}');

INSERT INTO nummultirange_test
    VALUES ('{[, 5)}');

INSERT INTO nummultirange_test
    VALUES (nummultirange ());

INSERT INTO nummultirange_test
    VALUES (nummultirange (VARIADIC '{}'::numrange[]));

INSERT INTO nummultirange_test
    VALUES (nummultirange (numrange(1.1, 2.2)));

INSERT INTO nummultirange_test
    VALUES ('{empty}');

INSERT INTO nummultirange_test
    VALUES (nummultirange (numrange(1.7, 1.7, '[]'), numrange(1.7, 1.9)));

INSERT INTO nummultirange_test
    VALUES (nummultirange (numrange(1.7, 1.7, '[]'), numrange(1.9, 2.1)));

SELECT
    nmr,
    isempty(nmr),
    lower(nmr),
    upper(nmr)
FROM
    nummultirange_test
ORDER BY
    nmr;

SELECT
    nmr,
    lower_inc(nmr),
    lower_inf(nmr),
    upper_inc(nmr),
    upper_inf(nmr)
FROM
    nummultirange_test
ORDER BY
    nmr;

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr = '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr = '{(,5)}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr = '{[3,)}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr = '{[1.7,1.7]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr = '{[1.7,1.7],[1.9,2.1)}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr < '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr < '{[-1000.0, -1000.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr < '{[0.0, 1.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr < '{[1000.0, 1001.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr <= '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr <= '{[3,)}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr >= '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr >= '{[3,)}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr > '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr > '{[-1000.0, -1000.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr > '{[0.0, 1.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr > '{[1000.0, 1001.0]}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr <> '{}';

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr <> '{(,5)}';

SELECT
    nummultirange (numrange(2.0, 1.0));

SELECT
    nummultirange (numrange(5.0, 6.0), numrange(1.0, 2.0));

ANALYZE nummultirange_test;

-- overlaps
SELECT
    *
FROM
    nummultirange_test
WHERE
    range_overlaps_multirange (numrange(4.0, 4.2), nmr);

SELECT
    *
FROM
    nummultirange_test
WHERE
    numrange(4.0, 4.2) && nmr;

SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_overlaps_range (nmr, numrange(4.0, 4.2));

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr && numrange(4.0, 4.2);

SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_overlaps_multirange (nmr, nummultirange (numrange(4.0, 4.2), numrange(6.0, 7.0)));

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr && nummultirange (numrange(4.0, 4.2), numrange(6.0, 7.0));

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr && nummultirange (numrange(6.0, 7.0));

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr && nummultirange (numrange(6.0, 7.0), numrange(8.0, 9.0));

-- mr contains x
SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_contains_elem (nmr, 4.0);

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr @> 4.0;

SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_contains_range (nmr, numrange(4.0, 4.2));

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr @> numrange(4.0, 4.2);

SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_contains_multirange (nmr, '{[4.0,4.2), [6.0, 8.0)}');

SELECT
    *
FROM
    nummultirange_test
WHERE
    nmr @> '{[4.0,4.2), [6.0, 8.0)}'::nummultirange;

-- x is contained by mr
SELECT
    *
FROM
    nummultirange_test
WHERE
    elem_contained_by_multirange (4.0, nmr);

SELECT
    *
FROM
    nummultirange_test
WHERE
    4.0 <@ nmr;

SELECT
    *
FROM
    nummultirange_test
WHERE
    range_contained_by_multirange (numrange(4.0, 4.2), nmr);

SELECT
    *
FROM
    nummultirange_test
WHERE
    numrange(4.0, 4.2) <@ nmr;

SELECT
    *
FROM
    nummultirange_test
WHERE
    multirange_contained_by_multirange ('{[4.0,4.2), [6.0, 8.0)}', nmr);

SELECT
    *
FROM
    nummultirange_test
WHERE
    '{[4.0,4.2), [6.0, 8.0)}'::nummultirange <@ nmr;

-- overlaps
SELECT
    'empty'::numrange && nummultirange ();

SELECT
    'empty'::numrange && nummultirange (numrange(1, 2));

SELECT
    nummultirange () && 'empty'::numrange;

SELECT
    nummultirange (numrange(1, 2)) && 'empty'::numrange;

SELECT
    nummultirange () && nummultirange ();

SELECT
    nummultirange () && nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) && nummultirange ();

SELECT
    nummultirange (numrange(3, 4)) && nummultirange (numrange(1, 2), numrange(7, 8));

SELECT
    nummultirange (numrange(1, 2), numrange(7, 8)) && nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(3, 4)) && nummultirange (numrange(1, 2), numrange(3.5, 8));

SELECT
    nummultirange (numrange(1, 2), numrange(3.5, 8)) && numrange(3, 4);

SELECT
    nummultirange (numrange(1, 2), numrange(3.5, 8)) && nummultirange (numrange(3, 4));

SELECT
    '{(10,20),(30,40),(50,60)}'::nummultirange && '(42,92)'::numrange;

-- contains
SELECT
    nummultirange () @> nummultirange ();

SELECT
    nummultirange () @> 'empty'::numrange;

SELECT
    nummultirange (numrange(NULL, NULL)) @> numrange(1, 2);

SELECT
    nummultirange (numrange(NULL, NULL)) @> numrange(NULL, 2);

SELECT
    nummultirange (numrange(NULL, NULL)) @> numrange(2, NULL);

SELECT
    nummultirange (numrange(NULL, 5)) @> numrange(NULL, 3);

SELECT
    nummultirange (numrange(NULL, 5)) @> numrange(NULL, 8);

SELECT
    nummultirange (numrange(5, NULL)) @> numrange(8, NULL);

SELECT
    nummultirange (numrange(5, NULL)) @> numrange(3, NULL);

SELECT
    nummultirange (numrange(1, 5)) @> numrange(8, 9);

SELECT
    nummultirange (numrange(1, 5)) @> numrange(3, 9);

SELECT
    nummultirange (numrange(1, 5)) @> numrange(1, 4);

SELECT
    nummultirange (numrange(1, 5)) @> numrange(1, 5);

SELECT
    nummultirange (numrange(-4, -2), numrange(1, 5)) @> numrange(1, 5);

SELECT
    nummultirange (numrange(1, 5), numrange(8, 9)) @> numrange(1, 5);

SELECT
    nummultirange (numrange(1, 5), numrange(8, 9)) @> numrange(6, 7);

SELECT
    nummultirange (numrange(1, 5), numrange(6, 9)) @> numrange(6, 7);

SELECT
    '{[1,5)}'::nummultirange @> '{[1,5)}';

SELECT
    '{[-4,-2), [1,5)}'::nummultirange @> '{[1,5)}';

SELECT
    '{[1,5), [8,9)}'::nummultirange @> '{[1,5)}';

SELECT
    '{[1,5), [8,9)}'::nummultirange @> '{[6,7)}';

SELECT
    '{[1,5), [6,9)}'::nummultirange @> '{[6,7)}';

SELECT
    '{(10,20),(30,40),(50,60)}'::nummultirange @> '(52,56)'::numrange;

SELECT
    numrange(NULL, NULL) @> nummultirange (numrange(1, 2));

SELECT
    numrange(NULL, NULL) @> nummultirange (numrange(NULL, 2));

SELECT
    numrange(NULL, NULL) @> nummultirange (numrange(2, NULL));

SELECT
    numrange(NULL, 5) @> nummultirange (numrange(NULL, 3));

SELECT
    numrange(NULL, 5) @> nummultirange (numrange(NULL, 8));

SELECT
    numrange(5, NULL) @> nummultirange (numrange(8, NULL));

SELECT
    numrange(5, NULL) @> nummultirange (numrange(3, NULL));

SELECT
    numrange(1, 5) @> nummultirange (numrange(8, 9));

SELECT
    numrange(1, 5) @> nummultirange (numrange(3, 9));

SELECT
    numrange(1, 5) @> nummultirange (numrange(1, 4));

SELECT
    numrange(1, 5) @> nummultirange (numrange(1, 5));

SELECT
    numrange(1, 9) @> nummultirange (numrange(-4, -2), numrange(1, 5));

SELECT
    numrange(1, 9) @> nummultirange (numrange(1, 5), numrange(8, 9));

SELECT
    numrange(1, 9) @> nummultirange (numrange(1, 5), numrange(6, 9));

SELECT
    numrange(1, 9) @> nummultirange (numrange(1, 5), numrange(6, 10));

SELECT
    '{[1,9)}' @> '{[1,5)}'::nummultirange;

SELECT
    '{[1,9)}' @> '{[-4,-2), [1,5)}'::nummultirange;

SELECT
    '{[1,9)}' @> '{[1,5), [8,9)}'::nummultirange;

SELECT
    '{[1,9)}' @> '{[1,5), [6,9)}'::nummultirange;

SELECT
    '{[1,9)}' @> '{[1,5), [6,10)}'::nummultirange;

-- is contained by
SELECT
    nummultirange () <@ nummultirange ();

SELECT
    'empty'::numrange <@ nummultirange ();

SELECT
    numrange(1, 2) <@ nummultirange (numrange(NULL, NULL));

SELECT
    numrange(NULL, 2) <@ nummultirange (numrange(NULL, NULL));

SELECT
    numrange(2, NULL) <@ nummultirange (numrange(NULL, NULL));

SELECT
    numrange(NULL, 3) <@ nummultirange (numrange(NULL, 5));

SELECT
    numrange(NULL, 8) <@ nummultirange (numrange(NULL, 5));

SELECT
    numrange(8, NULL) <@ nummultirange (numrange(5, NULL));

SELECT
    numrange(3, NULL) <@ nummultirange (numrange(5, NULL));

SELECT
    numrange(8, 9) <@ nummultirange (numrange(1, 5));

SELECT
    numrange(3, 9) <@ nummultirange (numrange(1, 5));

SELECT
    numrange(1, 4) <@ nummultirange (numrange(1, 5));

SELECT
    numrange(1, 5) <@ nummultirange (numrange(1, 5));

SELECT
    numrange(1, 5) <@ nummultirange (numrange(-4, -2), numrange(1, 5));

SELECT
    numrange(1, 5) <@ nummultirange (numrange(1, 5), numrange(8, 9));

SELECT
    numrange(6, 7) <@ nummultirange (numrange(1, 5), numrange(8, 9));

SELECT
    numrange(6, 7) <@ nummultirange (numrange(1, 5), numrange(6, 9));

SELECT
    '{[1,5)}' <@ '{[1,5)}'::nummultirange;

SELECT
    '{[1,5)}' <@ '{[-4,-2), [1,5)}'::nummultirange;

SELECT
    '{[1,5)}' <@ '{[1,5), [8,9)}'::nummultirange;

SELECT
    '{[6,7)}' <@ '{[1,5), [8,9)}'::nummultirange;

SELECT
    '{[6,7)}' <@ '{[1,5), [6,9)}'::nummultirange;

SELECT
    nummultirange (numrange(1, 2)) <@ numrange(NULL, NULL);

SELECT
    nummultirange (numrange(NULL, 2)) <@ numrange(NULL, NULL);

SELECT
    nummultirange (numrange(2, NULL)) <@ numrange(NULL, NULL);

SELECT
    nummultirange (numrange(NULL, 3)) <@ numrange(NULL, 5);

SELECT
    nummultirange (numrange(NULL, 8)) <@ numrange(NULL, 5);

SELECT
    nummultirange (numrange(8, NULL)) <@ numrange(5, NULL);

SELECT
    nummultirange (numrange(3, NULL)) <@ numrange(5, NULL);

SELECT
    nummultirange (numrange(8, 9)) <@ numrange(1, 5);

SELECT
    nummultirange (numrange(3, 9)) <@ numrange(1, 5);

SELECT
    nummultirange (numrange(1, 4)) <@ numrange(1, 5);

SELECT
    nummultirange (numrange(1, 5)) <@ numrange(1, 5);

SELECT
    nummultirange (numrange(-4, -2), numrange(1, 5)) <@ numrange(1, 9);

SELECT
    nummultirange (numrange(1, 5), numrange(8, 9)) <@ numrange(1, 9);

SELECT
    nummultirange (numrange(1, 5), numrange(6, 9)) <@ numrange(1, 9);

SELECT
    nummultirange (numrange(1, 5), numrange(6, 10)) <@ numrange(1, 9);

SELECT
    '{[1,5)}'::nummultirange <@ '{[1,9)}';

SELECT
    '{[-4,-2), [1,5)}'::nummultirange <@ '{[1,9)}';

SELECT
    '{[1,5), [8,9)}'::nummultirange <@ '{[1,9)}';

SELECT
    '{[1,5), [6,9)}'::nummultirange <@ '{[1,9)}';

SELECT
    '{[1,5), [6,10)}'::nummultirange <@ '{[1,9)}';

-- overleft
SELECT
    'empty'::numrange &< nummultirange ();

SELECT
    'empty'::numrange &< nummultirange (numrange(1, 2));

SELECT
    nummultirange () &< 'empty'::numrange;

SELECT
    nummultirange (numrange(1, 2)) &< 'empty'::numrange;

SELECT
    nummultirange () &< nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) &< nummultirange ();

SELECT
    nummultirange () &< nummultirange (numrange(1, 2));

SELECT
    numrange(6, 7) &< nummultirange (numrange(3, 4));

SELECT
    numrange(1, 2) &< nummultirange (numrange(3, 4));

SELECT
    numrange(1, 4) &< nummultirange (numrange(3, 4));

SELECT
    numrange(1, 6) &< nummultirange (numrange(3, 4));

SELECT
    numrange(3.5, 6) &< nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(6, 7)) &< numrange(3, 4);

SELECT
    nummultirange (numrange(1, 2)) &< numrange(3, 4);

SELECT
    nummultirange (numrange(1, 4)) &< numrange(3, 4);

SELECT
    nummultirange (numrange(1, 6)) &< numrange(3, 4);

SELECT
    nummultirange (numrange(3.5, 6)) &< numrange(3, 4);

SELECT
    nummultirange (numrange(6, 7)) &< nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2)) &< nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 4)) &< nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 6)) &< nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(3.5, 6)) &< nummultirange (numrange(3, 4));

-- overright
SELECT
    nummultirange () &> 'empty'::numrange;

SELECT
    nummultirange (numrange(1, 2)) &> 'empty'::numrange;

SELECT
    'empty'::numrange &> nummultirange ();

SELECT
    'empty'::numrange &> nummultirange (numrange(1, 2));

SELECT
    nummultirange () &> nummultirange ();

SELECT
    nummultirange () &> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) &> nummultirange ();

SELECT
    nummultirange (numrange(3, 4)) &> numrange(6, 7);

SELECT
    nummultirange (numrange(3, 4)) &> numrange(1, 2);

SELECT
    nummultirange (numrange(3, 4)) &> numrange(1, 4);

SELECT
    nummultirange (numrange(3, 4)) &> numrange(1, 6);

SELECT
    nummultirange (numrange(3, 4)) &> numrange(3.5, 6);

SELECT
    numrange(3, 4) &> nummultirange (numrange(6, 7));

SELECT
    numrange(3, 4) &> nummultirange (numrange(1, 2));

SELECT
    numrange(3, 4) &> nummultirange (numrange(1, 4));

SELECT
    numrange(3, 4) &> nummultirange (numrange(1, 6));

SELECT
    numrange(3, 4) &> nummultirange (numrange(3.5, 6));

SELECT
    nummultirange (numrange(3, 4)) &> nummultirange (numrange(6, 7));

SELECT
    nummultirange (numrange(3, 4)) &> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(3, 4)) &> nummultirange (numrange(1, 4));

SELECT
    nummultirange (numrange(3, 4)) &> nummultirange (numrange(1, 6));

SELECT
    nummultirange (numrange(3, 4)) &> nummultirange (numrange(3.5, 6));

-- meets
SELECT
    'empty'::numrange -|- nummultirange ();

SELECT
    'empty'::numrange -|- nummultirange (numrange(1, 2));

SELECT
    nummultirange () -|- 'empty'::numrange;

SELECT
    nummultirange (numrange(1, 2)) -|- 'empty'::numrange;

SELECT
    nummultirange () -|- nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) -|- nummultirange ();

SELECT
    nummultirange () -|- nummultirange (numrange(1, 2));

SELECT
    numrange(1, 2) -|- nummultirange (numrange(2, 4));

SELECT
    numrange(1, 2) -|- nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2)) -|- numrange(2, 4);

SELECT
    nummultirange (numrange(1, 2)) -|- numrange(3, 4);

SELECT
    nummultirange (numrange(1, 2)) -|- nummultirange (numrange(2, 4));

SELECT
    nummultirange (numrange(1, 2)) -|- nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(5, 6)) -|- nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(5, 6)) -|- nummultirange (numrange(6, 7));

SELECT
    nummultirange (numrange(1, 2), numrange(5, 6)) -|- nummultirange (numrange(8, 9));

SELECT
    nummultirange (numrange(1, 2)) -|- nummultirange (numrange(2, 4), numrange(6, 7));

-- strictly left
SELECT
    'empty'::numrange << nummultirange ();

SELECT
    numrange(1, 2) << nummultirange ();

SELECT
    numrange(1, 2) << nummultirange (numrange(3, 4));

SELECT
    numrange(1, 2) << nummultirange (numrange(0, 4));

SELECT
    numrange(1, 2) << nummultirange (numrange(0, 4), numrange(7, 8));

SELECT
    nummultirange () << 'empty'::numrange;

SELECT
    nummultirange () << numrange(1, 2);

SELECT
    nummultirange (numrange(3, 4)) << numrange(3, 6);

SELECT
    nummultirange (numrange(0, 2)) << numrange(3, 6);

SELECT
    nummultirange (numrange(0, 2), numrange(7, 8)) << numrange(3, 6);

SELECT
    nummultirange (numrange(-4, -2), numrange(0, 2)) << numrange(3, 6);

SELECT
    nummultirange () << nummultirange ();

SELECT
    nummultirange () << nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) << nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) << nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) << nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2)) << nummultirange (numrange(3, 4), numrange(7, 8));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) << nummultirange (numrange(3, 4), numrange(7, 8));

-- strictly right
SELECT
    nummultirange () >> 'empty'::numrange;

SELECT
    nummultirange () >> numrange(1, 2);

SELECT
    nummultirange (numrange(3, 4)) >> numrange(1, 2);

SELECT
    nummultirange (numrange(0, 4)) >> numrange(1, 2);

SELECT
    nummultirange (numrange(0, 4), numrange(7, 8)) >> numrange(1, 2);

SELECT
    'empty'::numrange >> nummultirange ();

SELECT
    numrange(1, 2) >> nummultirange ();

SELECT
    numrange(3, 6) >> nummultirange (numrange(3, 4));

SELECT
    numrange(3, 6) >> nummultirange (numrange(0, 2));

SELECT
    numrange(3, 6) >> nummultirange (numrange(0, 2), numrange(7, 8));

SELECT
    numrange(3, 6) >> nummultirange (numrange(-4, -2), numrange(0, 2));

SELECT
    nummultirange () >> nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) >> nummultirange ();

SELECT
    nummultirange () >> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) >> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(3, 4)) >> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(3, 4), numrange(7, 8)) >> nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(3, 4), numrange(7, 8)) >> nummultirange (numrange(1, 2), numrange(4, 5));

-- union
SELECT
    nummultirange () + nummultirange ();

SELECT
    nummultirange () + nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) + nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) + nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) + nummultirange (numrange(2, 4));

SELECT
    nummultirange (numrange(1, 2)) + nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) + nummultirange (numrange(2, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) + nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) + nummultirange (numrange(0, 9));

-- merge
SELECT
    range_merge(nummultirange ());

SELECT
    range_merge(nummultirange (numrange(1, 2)));

SELECT
    range_merge(nummultirange (numrange(1, 2), numrange(7, 8)));

-- minus
SELECT
    nummultirange () - nummultirange ();

SELECT
    nummultirange () - nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) - nummultirange ();

SELECT
    nummultirange (numrange(1, 2), numrange(3, 4)) - nummultirange ();

SELECT
    nummultirange (numrange(1, 2)) - nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) - nummultirange (numrange(2, 4));

SELECT
    nummultirange (numrange(1, 2)) - nummultirange (numrange(3, 4));

SELECT
    nummultirange (numrange(1, 4)) - nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 4)) - nummultirange (numrange(2, 3));

SELECT
    nummultirange (numrange(1, 4)) - nummultirange (numrange(0, 8));

SELECT
    nummultirange (numrange(1, 4)) - nummultirange (numrange(0, 2));

SELECT
    nummultirange (numrange(1, 8)) - nummultirange (numrange(0, 2), numrange(3, 4));

SELECT
    nummultirange (numrange(1, 8)) - nummultirange (numrange(2, 3), numrange(5, NULL));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(-2, 0));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(2, 4));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(3, 5));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(0, 9));

SELECT
    nummultirange (numrange(1, 3), numrange(4, 5)) - nummultirange (numrange(2, 9));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(8, 9));

SELECT
    nummultirange (numrange(1, 2), numrange(4, 5)) - nummultirange (numrange(-2, 0), numrange(8, 9));

-- multirange_minus_multi
SELECT
    multirange_minus_multi (nummultirange (), nummultirange ());

SELECT
    multirange_minus_multi (nummultirange (), nummultirange (numrange(1, 2)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2)), nummultirange ());

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(3, 4)), nummultirange ());

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2)), nummultirange (numrange(1, 2)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2)), nummultirange (numrange(2, 4)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2)), nummultirange (numrange(3, 4)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 4)), nummultirange (numrange(1, 2)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 4)), nummultirange (numrange(2, 3)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 4)), nummultirange (numrange(0, 8)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 4)), nummultirange (numrange(0, 2)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 8)), nummultirange (numrange(0, 2), numrange(3, 4)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 8)), nummultirange (numrange(2, 3), numrange(5, NULL)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(-2, 0)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(2, 4)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(3, 5)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(0, 9)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 3), numrange(4, 5)), nummultirange (numrange(2, 9)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(8, 9)));

SELECT
    multirange_minus_multi (nummultirange (numrange(1, 2), numrange(4, 5)), nummultirange (numrange(-2, 0), numrange(8, 9)));

-- intersection
SELECT
    nummultirange () * nummultirange ();

SELECT
    nummultirange () * nummultirange (numrange(1, 2));

SELECT
    nummultirange (numrange(1, 2)) * nummultirange ();

SELECT
    '{[1,3)}'::nummultirange * '{[1,5)}'::nummultirange;

SELECT
    '{[1,3)}'::nummultirange * '{[0,5)}'::nummultirange;

SELECT
    '{[1,3)}'::nummultirange * '{[0,2)}'::nummultirange;

SELECT
    '{[1,3)}'::nummultirange * '{[2,5)}'::nummultirange;

SELECT
    '{[1,4)}'::nummultirange * '{[2,3)}'::nummultirange;

SELECT
    '{[1,4)}'::nummultirange * '{[0,2), [3,5)}'::nummultirange;

SELECT
    '{[1,4), [7,10)}'::nummultirange * '{[0,8), [9,12)}'::nummultirange;

SELECT
    '{[1,4), [7,10)}'::nummultirange * '{[9,12)}'::nummultirange;

SELECT
    '{[1,4), [7,10)}'::nummultirange * '{[-5,-4), [5,6), [9,12)}'::nummultirange;

SELECT
    '{[1,4), [7,10)}'::nummultirange * '{[0,2), [3,8), [9,12)}'::nummultirange;

SELECT
    '{[1,4), [7,10)}'::nummultirange * '{[0,2), [3,8), [9,12)}'::nummultirange;

-- test GiST index
CREATE TABLE test_multirange_gist (
    mr int4multirange
);

INSERT INTO test_multirange_gist
SELECT
    int4multirange (int4range(g, g + 10), int4range(g + 20, g + 30), int4range(g + 40, g + 50))
FROM
    generate_series(1, 2000) g;

INSERT INTO test_multirange_gist
SELECT
    '{}'::int4multirange
FROM
    generate_series(1, 500) g;

INSERT INTO test_multirange_gist
SELECT
    int4multirange (int4range(g, g + 10000))
FROM
    generate_series(1, 1000) g;

INSERT INTO test_multirange_gist
SELECT
    int4multirange (int4range(NULL, g * 10, '(]'), int4range(g * 10, g * 20, '(]'))
FROM
    generate_series(1, 100) g;

INSERT INTO test_multirange_gist
SELECT
    int4multirange (int4range(g * 10, g * 20, '(]'), int4range(g * 20, NULL, '(]'))
FROM
    generate_series(1, 100) g;

CREATE INDEX test_mulrirange_gist_idx ON test_multirange_gist USING gist (mr);

-- test statistics and selectivity estimation as well
--
-- We don't check the accuracy of selectivity estimation, but at least check
-- it doesn't fall.
ANALYZE test_multirange_gist;

-- first, verify non-indexed results
SET enable_seqscan = t;

SET enable_indexscan = f;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr = '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr = int4multirange (int4range(10, 20), int4range(30, 40), int4range(50, 60));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> 10;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && int4range(10, 20);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> int4multirange (int4range(10, 20), int4range(30, 40));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && '{(10,20),(30,40),(50,60)}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ '{(10,30),(40,60),(70,90)}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- int4multirange (int4range(100, 200), int4range(400, 500));

-- now check same queries using index
SET enable_seqscan = f;

SET enable_indexscan = t;

SET enable_bitmapscan = f;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr = '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> 'empty'::int4range;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr = int4multirange (int4range(10, 20), int4range(30, 40), int4range(50, 60));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> 10;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> int4range(10, 20);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && int4range(10, 20);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ int4range(10, 50);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- int4range(100, 500);

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> '{}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr @> int4multirange (int4range(10, 20), int4range(30, 40));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr && '{(10,20),(30,40),(50,60)}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr <@ '{(10,30),(40,60),(70,90)}'::int4multirange;

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr << int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr >> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &< int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr &> int4multirange (int4range(100, 200), int4range(400, 500));

SELECT
    count(*)
FROM
    test_multirange_gist
WHERE
    mr -|- int4multirange (int4range(100, 200), int4range(400, 500));

DROP TABLE test_multirange_gist;

--
-- range_agg function
--
CREATE TABLE reservations (
    room_id integer NOT NULL,
    booked_during daterange
);

INSERT INTO reservations
VALUES
    -- 1: has a meets and a gap
    (1, daterange('2018-07-01', '2018-07-07')),
    (1, daterange('2018-07-07', '2018-07-14')),
    (1, daterange('2018-07-20', '2018-07-22')),
    -- 2: just a single row
    (2, daterange('2018-07-01', '2018-07-03')),
    -- 3: one null range
    (3, NULL),
    -- 4: two null ranges
    (4, NULL),
    (4, NULL),
    -- 5: a null range and a non-null range
    (5, NULL),
    (5, daterange('2018-07-01', '2018-07-03')),
    -- 6: has overlap
    (6, daterange('2018-07-01', '2018-07-07')),
    (6, daterange('2018-07-05', '2018-07-10')),
    -- 7: two ranges that meet: no gap or overlap
    (7, daterange('2018-07-01', '2018-07-07')),
    (7, daterange('2018-07-07', '2018-07-14')),
    -- 8: an empty range
    (8, 'empty'::daterange);

SELECT
    room_id,
    range_agg (booked_during)
FROM
    reservations
GROUP BY
    room_id
ORDER BY
    room_id;

-- range_agg on a custom range type too
SELECT
    range_agg (r)
FROM (
    VALUES ('[a,c]'::textrange),
        ('[b,b]'::textrange),
        ('[c,f]'::textrange),
        ('[g,h)'::textrange),
        ('[h,j)'::textrange)) t (r);

-- range_agg with multirange inputs
SELECT
    range_agg (nmr)
FROM
    nummultirange_test;

SELECT
    range_agg (nmr)
FROM
    nummultirange_test
WHERE
    FALSE;

SELECT
    range_agg (NULL::nummultirange)
FROM
    nummultirange_test;

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{}'::nummultirange),
        ('{}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{[1,2]}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{[1,2], [5,6]}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{[1,2], [2,3]}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{[1,2]}'::nummultirange),
        ('{[5,6]}'::nummultirange)) t (nmr);

SELECT
    range_agg (nmr)
FROM (
    VALUES ('{[1,2]}'::nummultirange),
        ('{[2,3]}'::nummultirange)) t (nmr);

--
-- range_intersect_agg function
--
SELECT
    range_intersect_agg (nmr)
FROM
    nummultirange_test;

SELECT
    range_intersect_agg (nmr)
FROM
    nummultirange_test
WHERE
    FALSE;

SELECT
    range_intersect_agg (NULL::nummultirange)
FROM
    nummultirange_test;

SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{[1,3]}'::nummultirange),
        ('{[6,12]}'::nummultirange)) t (nmr);

SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{[1,6]}'::nummultirange),
        ('{[3,12]}'::nummultirange)) t (nmr);

SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{[1,6], [10,12]}'::nummultirange),
        ('{[4,14]}'::nummultirange)) t (nmr);

-- test with just one input:
SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{}'::nummultirange)) t (nmr);

SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{[1,2]}'::nummultirange)) t (nmr);

SELECT
    range_intersect_agg (nmr)
FROM (
    VALUES ('{[1,6], [10,12]}'::nummultirange)) t (nmr);

SELECT
    range_intersect_agg (nmr)
FROM
    nummultirange_test
WHERE
    nmr @> 4.0;

CREATE TABLE nummultirange_test2 (
    nmr nummultirange
);

CREATE INDEX nummultirange_test2_hash_idx ON nummultirange_test2 USING HASH (nmr);

INSERT INTO nummultirange_test2
    VALUES ('{[, 5)}');

INSERT INTO nummultirange_test2
    VALUES (nummultirange (numrange(1.1, 2.2)));

INSERT INTO nummultirange_test2
    VALUES (nummultirange (numrange(1.1, 2.2)));

INSERT INTO nummultirange_test2
    VALUES (nummultirange (numrange(1.1, 2.2, '()')));

INSERT INTO nummultirange_test2
    VALUES ('{}');

SELECT
    *
FROM
    nummultirange_test2
WHERE
    nmr = '{}';

SELECT
    *
FROM
    nummultirange_test2
WHERE
    nmr = nummultirange (numrange(1.1, 2.2));

SELECT
    *
FROM
    nummultirange_test2
WHERE
    nmr = nummultirange (numrange(1.1, 2.3));

SET enable_nestloop = t;

SET enable_hashjoin = f;

SET enable_mergejoin = f;

SELECT
    *
FROM
    nummultirange_test
    NATURAL JOIN nummultirange_test2
ORDER BY
    nmr;

SET enable_nestloop = f;

SET enable_hashjoin = t;

SET enable_mergejoin = f;

SELECT
    *
FROM
    nummultirange_test
    NATURAL JOIN nummultirange_test2
ORDER BY
    nmr;

SET enable_nestloop = f;

SET enable_hashjoin = f;

SET enable_mergejoin = t;

SELECT
    *
FROM
    nummultirange_test
    NATURAL JOIN nummultirange_test2
ORDER BY
    nmr;

SET enable_nestloop TO DEFAULT;

SET enable_hashjoin TO DEFAULT;

SET enable_mergejoin TO DEFAULT;

DROP TABLE nummultirange_test2;

--
-- Test user-defined multirange of floats
--
SELECT
    '{[123.001, 5.e9)}'::float8multirange @> 888.882::float8;

CREATE TABLE float8multirange_test (
    f8mr float8multirange,
    i int
);

INSERT INTO float8multirange_test
    VALUES (float8multirange (float8range (-100.00007, '1.111113e9')), 42);

SELECT
    *
FROM
    float8multirange_test;

DROP TABLE float8multirange_test;

--
-- Test multirange types over domains
--
CREATE DOMAIN mydomain AS int4;

CREATE TYPE mydomainrange AS RANGE (
    subtype = mydomain
);

SELECT
    '{[4,50)}'::mydomainmultirange @> 7::mydomain;

DROP DOMAIN mydomain CASCADE;

--
-- Test domains over multirange types
--
CREATE DOMAIN restrictedmultirange AS int4multirange CHECK (upper(value) < 10);

SELECT
    '{[4,5)}'::restrictedmultirange @> 7;

SELECT
    '{[4,50)}'::restrictedmultirange @> 7;

-- should fail
DROP DOMAIN restrictedmultirange;

---
-- Check automatic naming of multiranges
---
CREATE TYPE intr AS RANGE (
    subtype = int
);

SELECT
    intr_multirange (intr (1, 10));

DROP TYPE intr;

CREATE TYPE intmultirange AS (
    x int,
    y int
);

CREATE TYPE intrange AS RANGE (
    subtype = int
);

-- should fail
DROP TYPE intmultirange;

CREATE TYPE intr_multirange AS (
    x int,
    y int
);

CREATE TYPE intr AS RANGE (
    subtype = int
);

-- should fail
DROP TYPE intr_multirange;

--
-- Test multiple multirange types over the same subtype and manual naming of
-- the multirange type.
--
-- should fail
CREATE TYPE textrange1 AS RANGE (
    subtype = text,
    multirange_type_name = int,
    COLLATION = "C"
);

-- should pass
CREATE TYPE textrange1 AS RANGE (
    subtype = text,
    multirange_type_name = multirange_of_text,
    COLLATION = "C"
);

-- should pass, because existing _textrange1 is automatically renamed
CREATE TYPE textrange2 AS RANGE (
    subtype = text,
    multirange_type_name = _textrange1,
    COLLATION = "C"
);

SELECT
    multirange_of_text (textrange2 ('a', 'Z'));

-- should fail
SELECT
    multirange_of_text (textrange1 ('a', 'Z')) @> 'b'::text;

SELECT
    unnest(multirange_of_text (textrange1 ('a', 'b'), textrange1 ('d', 'e')));

SELECT
    _textrange1 (textrange2 ('a', 'z')) @> 'b'::text;

DROP TYPE textrange1;

DROP TYPE textrange2;

--
-- Multiranges don't have their own ownership or permissions.
--
CREATE TYPE textrange1 AS RANGE (
    subtype = text,
    multirange_type_name = multitextrange1,
    COLLATION = "C"
);

CREATE ROLE regress_multirange_owner;

ALTER TYPE multitextrange1 OWNER TO regress_multirange_owner;

-- fail
ALTER TYPE textrange1 OWNER TO regress_multirange_owner;

SET ROLE regress_multirange_owner;

REVOKE usage ON type multitextrange1 FROM public;

-- fail
REVOKE usage ON type textrange1 FROM public;

\dT+ *textrange1*
CREATE temp TABLE test1 (
    f1 multitextrange1[]
);

REVOKE usage ON type textrange1 FROM regress_multirange_owner;

CREATE temp TABLE test2 (
    f1 multitextrange1[]
);

-- fail
DROP TABLE test1;

DROP TYPE textrange1;

RESET ROLE;

DROP ROLE regress_multirange_owner;

--
-- CREATE TYPE checks for CREATE on multirange schema
--
CREATE ROLE regress_mr;

CREATE SCHEMA mr_sch;

SET ROLE regress_mr;

CREATE TYPE mytype AS RANGE (
    subtype = int4,
    multirange_type_name = mr_sch.mr_type
);

RESET ROLE;

GRANT CREATE ON SCHEMA mr_sch TO regress_mr;

SET ROLE regress_mr;

CREATE TYPE mytype AS RANGE (
    subtype = int4,
    multirange_type_name = mr_sch.mr_type
);

RESET ROLE;

DROP TYPE mytype;

DROP SCHEMA mr_sch;

DROP ROLE regress_mr;

--
-- Test polymorphic type system
--
CREATE FUNCTION anyarray_anymultirange_func (a anyarray, r anymultirange)
    RETURNS anyelement
    AS '
    SELECT
        $1[1] + lower($2);
'
LANGUAGE sql;

SELECT
    anyarray_anymultirange_func (ARRAY[1, 2], int4multirange (int4range(10, 20)));

-- should fail
SELECT
    anyarray_anymultirange_func (ARRAY[1, 2], nummultirange (numrange(10, 20)));

DROP FUNCTION anyarray_anymultirange_func (anyarray, anymultirange);

-- should fail
CREATE FUNCTION bogus_func (anyelement)
    RETURNS anymultirange
    AS '
    SELECT
        int4multirange (int4range(1, 10));
'
LANGUAGE sql;

-- should fail
CREATE FUNCTION bogus_func (int)
    RETURNS anymultirange
    AS '
    SELECT
        int4multirange (int4range(1, 10));
'
LANGUAGE sql;

CREATE FUNCTION range_add_bounds (anymultirange)
    RETURNS anyelement
    AS '
    SELECT
        lower($1) + upper($1);
'
LANGUAGE sql;

SELECT
    range_add_bounds (int4multirange (int4range(1, 17)));

SELECT
    range_add_bounds (nummultirange (numrange(1.0001, 123.123)));

CREATE FUNCTION multirangetypes_sql (q anymultirange, b anyarray, out c anyelement)
AS $$
    SELECT
        upper($1) + $2[1]
$$
LANGUAGE sql;

SELECT
    multirangetypes_sql (int4multirange (int4range(1, 10)), ARRAY[2, 20]);

SELECT
    multirangetypes_sql (nummultirange (numrange(1, 10)), ARRAY[2, 20]);

-- match failure
CREATE FUNCTION anycompatiblearray_anycompatiblemultirange_func (a anycompatiblearray, mr anycompatiblemultirange)
    RETURNS anycompatible
    AS '
    SELECT
        $1[1] + lower($2);
'
LANGUAGE sql;

SELECT
    anycompatiblearray_anycompatiblemultirange_func (ARRAY[1, 2], multirange (int4range(10, 20)));

SELECT
    anycompatiblearray_anycompatiblemultirange_func (ARRAY[1, 2], multirange (numrange(10, 20)));

-- should fail
SELECT
    anycompatiblearray_anycompatiblemultirange_func (ARRAY[1.1, 2], multirange (int4range(10, 20)));

DROP FUNCTION anycompatiblearray_anycompatiblemultirange_func (anycompatiblearray, anycompatiblemultirange);

CREATE FUNCTION anycompatiblerange_anycompatiblemultirange_func (r anycompatiblerange, mr anycompatiblemultirange)
    RETURNS anycompatible
    AS '
    SELECT
        lower($1) + lower($2);
'
LANGUAGE sql;

SELECT
    anycompatiblerange_anycompatiblemultirange_func (int4range(1, 2), multirange (int4range(10, 20)));

-- should fail
SELECT
    anycompatiblerange_anycompatiblemultirange_func (numrange(1, 2), multirange (int4range(10, 20)));

DROP FUNCTION anycompatiblerange_anycompatiblemultirange_func (anycompatiblerange, anycompatiblemultirange);

-- should fail
CREATE FUNCTION bogus_func (anycompatible)
    RETURNS anycompatiblerange
    AS '
    SELECT
        int4range(1, 10);
'
LANGUAGE sql;

--
-- Arrays of multiranges
--
SELECT
    ARRAY[nummultirange (numrange(1.1, 1.2)), nummultirange (numrange(12.3, 155.5))];

CREATE TABLE i8mr_array (
    f1 int,
    f2 int8multirange[]
);

INSERT INTO i8mr_array
    VALUES (42, ARRAY[int8multirange (int8range(1, 10)), int8multirange (int8range(2, 20))]);

SELECT
    *
FROM
    i8mr_array;

DROP TABLE i8mr_array;

--
-- Multiranges of arrays
--
SELECT
    arraymultirange (arrayrange (ARRAY[1, 2], ARRAY[2, 1]));

SELECT
    arraymultirange (arrayrange (ARRAY[2, 1], ARRAY[1, 2]));

-- fail
SELECT
    ARRAY[1, 1] <@ arraymultirange (arrayrange (ARRAY[1, 2], ARRAY[2, 1]));

SELECT
    ARRAY[1, 3] <@ arraymultirange (arrayrange (ARRAY[1, 2], ARRAY[2, 1]));

--
-- Ranges of composites
--
CREATE TYPE two_ints AS (
    a int,
    b int
);

CREATE TYPE two_ints_range AS RANGE (
    subtype = two_ints
);

-- with debug_parallel_query on, this exercises tqueue.c's range remapping
SELECT
    *,
    row_to_json(upper(t)) AS u
FROM (
    VALUES (two_ints_multirange (two_ints_range (ROW (1, 2), ROW (3, 4)))),
        (two_ints_multirange (two_ints_range (ROW (5, 6), ROW (7, 8))))) v (t);

-- this must be rejected to avoid self-inclusion issues:
ALTER TYPE two_ints
    ADD attribute c two_ints_multirange;

DROP TYPE two_ints CASCADE;

--
-- Check behavior when subtype lacks a hash function
--
SET enable_groupagg = OFF;

-- try to make it pick a hash setop implementation
SELECT
    '{(01,10)}'::varbitmultirange
EXCEPT
SELECT
    '{(10,11)}'::varbitmultirange;

RESET enable_groupagg;

--
-- OUT/INOUT/TABLE functions
--
-- infer anymultirange from anymultirange
CREATE FUNCTION mr_outparam_succeed (i anymultirange, out r anymultirange, out t text)
AS $$
    SELECT
        $1,
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_outparam_succeed (int4multirange (int4range(1, 2)));

-- infer anyarray from anymultirange
CREATE FUNCTION mr_outparam_succeed2 (i anymultirange, out r anyarray, out t text)
AS $$
    SELECT
        ARRAY[upper($1)],
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_outparam_succeed2 (int4multirange (int4range(1, 2)));

-- infer anyrange from anymultirange
CREATE FUNCTION mr_outparam_succeed3 (i anymultirange, out r anyrange, out t text)
AS $$
    SELECT
        range_merge($1),
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_outparam_succeed3 (int4multirange (int4range(1, 2)));

-- infer anymultirange from anyrange
CREATE FUNCTION mr_outparam_succeed4 (i anyrange, out r anymultirange, out t text)
AS $$
    SELECT
        multirange ($1),
        'foo'::text
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_outparam_succeed4 (int4range(1, 2));

-- infer anyelement from anymultirange
CREATE FUNCTION mr_inoutparam_succeed (out i anyelement, INOUT r anymultirange)
AS $$
    SELECT
        upper($1),
        $1
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_inoutparam_succeed (int4multirange (int4range(1, 2)));

-- infer anyelement+anymultirange from anyelement+anymultirange
CREATE FUNCTION mr_table_succeed (i anyelement, r anymultirange)
    RETURNS TABLE (
        i anyelement,
        r anymultirange
    )
    AS $$
    SELECT
        $1,
        $2
$$
LANGUAGE sql;

SELECT
    *
FROM
    mr_table_succeed (123, int4multirange (int4range(1, 11)));

-- use anymultirange in plpgsql
CREATE FUNCTION mr_polymorphic (i anyrange)
    RETURNS anymultirange
    AS $$
BEGIN
    RETURN multirange ($1);
END;
$$
LANGUAGE plpgsql;

SELECT
    mr_polymorphic (int4range(1, 4));

-- should fail
CREATE FUNCTION mr_outparam_fail (i anyelement, out r anymultirange, out t text)
AS $$
    SELECT
        '[1,10]',
        'foo'
$$
LANGUAGE sql;

--should fail
CREATE FUNCTION mr_inoutparam_fail (INOUT i anyelement, out r anymultirange)
AS $$
    SELECT
        $1,
        '[1,10]'
$$
LANGUAGE sql;

--should fail
CREATE FUNCTION mr_table_fail (i anyelement)
    RETURNS TABLE (
        i anyelement,
        r anymultirange
    )
    AS $$
    SELECT
        $1,
        '[1,10]'
$$
LANGUAGE sql;

--
-- Check that numeric overflow during analyze does not make it fail
--
CREATE TABLE multirange_analyze_test (
    r nummultirange
);

INSERT INTO multirange_analyze_test
    VALUES ('{[1e1000, 2e1000], [-9e131071, 9e131071]}'::nummultirange);

ANALYZE multirange_analyze_test;

DROP TABLE multirange_analyze_test;

