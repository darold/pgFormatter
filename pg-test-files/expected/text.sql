--
-- TEXT
--

SELECT
    text 'this is a text string' = text 'this is a text string' AS true;

SELECT
    text 'this is a text string' = text 'this is a text strin' AS false;

CREATE TABLE TEXT_TBL (
    f1 text
);

INSERT INTO TEXT_TBL
    VALUES ('doh!');

INSERT INTO TEXT_TBL
    VALUES ('hi de ho neighbor');

SELECT
    '' AS two,
    *
FROM
    TEXT_TBL;

-- As of 8.3 we have removed most implicit casts to text, so that for example
-- this no longer works:

SELECT
    length(42);

-- But as a special exception for usability's sake, we still allow implicit
-- casting to text in concatenations, so long as the other input is text or
-- an unknown literal.  So these work:

SELECT
    'four: '::text || 2 + 2;

SELECT
    'four: ' || 2 + 2;

-- but not this:
SELECT
    3 || 4.0;


/*
 * various string functions
 */
SELECT
    concat('one');

SELECT
    concat(1, 2, 3, 'hello', TRUE, FALSE, to_date('20100309', 'YYYYMMDD'));

SELECT
    concat_ws('#', 'one');

SELECT
    concat_ws('#', 1, 2, 3, 'hello', TRUE, FALSE, to_date('20100309', 'YYYYMMDD'));

SELECT
    concat_ws(',', 10, 20, NULL, 30);

SELECT
    concat_ws('', 10, 20, NULL, 30);

SELECT
    concat_ws(NULL, 10, 20, NULL, 30) IS NULL;

SELECT
    reverse('abcde');

SELECT
    i,
    LEFT ('ahoj',
        i),
    RIGHT ('ahoj',
        i)
FROM
    generate_series(- 5, 5) t (i)
ORDER BY
    i;

SELECT
    quote_literal('');

SELECT
    quote_literal('abc''');

SELECT
    quote_literal(e '\\');
 -- check variadic labeled argument
 select concat(variadic array[1,2,3]);
 select concat_ws(', ', variadic array[1,2,3]);
 select concat_ws(', ', variadic NULL::int[]);
 select concat(variadic NULL::int[]) is NULL;
 select concat(variadic ' '::int[]) = '';
 --should fail
 select concat_ws(', ', variadic 10);
 
 /*
  * format
  */
 select format(NULL);
 select format(' Hello ');
 select format(' Hello % s ', ' World ');
 select format(' Hello % % ');
 select format(' Hello % % % % ');
 -- should fail
 select format(' Hello % s % s ', ' World ');
 select format(' Hello % s ');
 select format(' Hello % x ', 20);
 -- check literal and sql identifiers
 select format(' INSERT INTO % I
            VALUES (% L, % L) ', ' mytab ', 10, ' Hello ');
 select format(' % s % s % s ',' Hello ', NULL,' World ');
 select format(' INSERT INTO % I
                VALUES (% L, % L) ', ' mytab ', 10, NULL);
 select format(' INSERT INTO % I
                    VALUES (% L, % L) ', ' mytab ', NULL, ' Hello ');
 -- should fail, sql identifier cannot be NULL
 select format(' INSERT INTO % I
                        VALUES (% L, % L) ', NULL, 10, ' Hello ');
 -- check positional placeholders
 select format(' % 1$s % 3$s ', 1, 2, 3);
 select format(' % 1$s % 12$s ', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
 -- should fail
 select format(' % 1$s % 4$s ', 1, 2, 3);
 select format(' % 1$s % 13$s ', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
 select format(' % 0$s ', ' Hello ');
 select format(' % * 0$s ', ' Hello ');
 select format(' % 1$ ', 1);
 select format(' % 1$1 ', 1);
 -- check mix of positional and ordered placeholders
 select format(' Hello % s % 1$s % s ', ' World ', ' Hello again ');
 select format(' Hello % s % s, % 2$s % 2$s ', ' World ', ' Hello again ');
 -- check variadic labeled arguments
 select format(' % s, % s ', variadic array[' Hello ',' World ']);
 select format(' % s, % s ', variadic array[1, 2]);
 select format(' % s, % s ', variadic array[true, false]);
 select format(' % s, % s ', variadic array[true, false]::text[]);
 -- check variadic with positional placeholders
 select format(' % 2$s, % 1$s ', variadic array[' FIRST ', ' second ']);
 select format(' % 2$s, % 1$s ', variadic array[1, 2]);
 -- variadic argument can be array type NULL, but should not be referenced
 select format(' Hello ', variadic NULL::int[]);
 -- variadic argument allows simulating more than FUNC_MAX_ARGS parameters
 select format(string_agg(' % s ',', '), variadic array_agg(i))
 from generate_series(1,200) g(i);
 -- check field widths and left, right alignment
 select format(' >> % 10s << ', ' Hello ');
 select format(' >> % 10s << ', NULL);
 select format(' >> % 10s << ', '');
 select format(' >> % - 10s << ', '');
 select format(' >> % - 10s << ', ' Hello ');
 select format(' >> % - 10s << ', NULL);
 select format(' >> % 1$10s << ', ' Hello ');
 select format(' >> % 1$ - 10I << ', ' Hello ');
 select format(' >> % 2$ * 1$L << ', 10, ' Hello ');
 select format(' >> % 2$ * 1$L << ', 10, NULL);
 select format(' >> % 2$ * 1$L << ', -10, NULL);
 select format(' >> % * s << ', 10, ' Hello ');
 select format(' >> % * 1$s << ', 10, ' Hello ');
 select format(' >> % - s << ', ' Hello ');
 select format(' >> % 10L << ', NULL);
 select format(' >> % 2$ * 1$L << ', NULL, ' Hello ');
 select format(' >> % 2$ * 1$L << ', 0, ' Hello);

