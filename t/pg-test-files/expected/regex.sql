--
-- Regular expression tests
--
-- Don't want to have to double backslashes in regexes
SET standard_conforming_strings = ON;

-- Test simple quantified backrefs
SELECT
    'bbbbb' ~ '^([bc])\1*$' AS t;

SELECT
    'ccc' ~ '^([bc])\1*$' AS t;

SELECT
    'xxx' ~ '^([bc])\1*$' AS f;

SELECT
    'bbc' ~ '^([bc])\1*$' AS f;

SELECT
    'b' ~ '^([bc])\1*$' AS t;

-- Test quantified backref within a larger expression
SELECT
    'abc abc abc' ~ '^(\w+)( \1)+$' AS t;

SELECT
    'abc abd abc' ~ '^(\w+)( \1)+$' AS f;

SELECT
    'abc abc abd' ~ '^(\w+)( \1)+$' AS f;

SELECT
    'abc abc abc' ~ '^(.+)( \1)+$' AS t;

SELECT
    'abc abd abc' ~ '^(.+)( \1)+$' AS f;

SELECT
    'abc abc abd' ~ '^(.+)( \1)+$' AS f;

-- Test some cases that crashed in 9.2beta1 due to pmatch[] array overrun
SELECT
    substring('asd TO foo' FROM ' TO (([a-z0-9._]+|"([^"]+|"")+")+)');

SELECT
    substring('a' FROM '((a))+');

SELECT
    substring('a' FROM '((a)+)');

-- Test regexp_match()
SELECT
    regexp_match('abc', '');

SELECT
    regexp_match('abc', 'bc');

SELECT
    regexp_match('abc', 'd') IS NULL;

SELECT
    regexp_match('abc', '(B)(c)', 'i');

SELECT
    regexp_match('abc', 'Bd', 'ig');

-- error
-- Test lookahead constraints
SELECT
    regexp_matches('ab', 'a(?=b)b*');

SELECT
    regexp_matches('a', 'a(?=b)b*');

SELECT
    regexp_matches('abc', 'a(?=b)b*(?=c)c*');

SELECT
    regexp_matches('ab', 'a(?=b)b*(?=c)c*');

SELECT
    regexp_matches('ab', 'a(?!b)b*');

SELECT
    regexp_matches('a', 'a(?!b)b*');

SELECT
    regexp_matches('b', '(?=b)b');

SELECT
    regexp_matches('a', '(?=b)b');

-- Test lookbehind constraints
SELECT
    regexp_matches('abb', '(?<=a)b*');

SELECT
    regexp_matches('a', 'a(?<=a)b*');

SELECT
    regexp_matches('abc', 'a(?<=a)b*(?<=b)c*');

SELECT
    regexp_matches('ab', 'a(?<=a)b*(?<=b)c*');

SELECT
    regexp_matches('ab', 'a*(?<!a)b*');

SELECT
    regexp_matches('ab', 'a*(?<!a)b+');

SELECT
    regexp_matches('b', 'a*(?<!a)b+');

SELECT
    regexp_matches('a', 'a(?<!a)b*');

SELECT
    regexp_matches('b', '(?<=b)b');

SELECT
    regexp_matches('foobar', '(?<=f)b+');

SELECT
    regexp_matches('foobar', '(?<=foo)b+');

SELECT
    regexp_matches('foobar', '(?<=oo)b+');

-- Test optimization of single-chr-or-bracket-expression lookaround constraints
SELECT
    'xz' ~ 'x(?=[xy])';

SELECT
    'xy' ~ 'x(?=[xy])';

SELECT
    'xz' ~ 'x(?![xy])';

SELECT
    'xy' ~ 'x(?![xy])';

SELECT
    'x' ~ 'x(?![xy])';

SELECT
    'xyy' ~ '(?<=[xy])yy+';

SELECT
    'zyy' ~ '(?<=[xy])yy+';

SELECT
    'xyy' ~ '(?<![xy])yy+';

SELECT
    'zyy' ~ '(?<![xy])yy+';

-- Test conversion of regex patterns to indexable conditions
EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ 'abc';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^abc';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^abc$';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^abcd*e';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^abc+d';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^(abc)(def)';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^(abc)$';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^(abc)?d';

EXPLAIN (
    COSTS OFF
)
SELECT
    *
FROM
    pg_proc
WHERE
    proname ~ '^abcd(x|(?=\w\w)q)';

-- Test for infinite loop in pullback() (CVE-2007-4772)
SELECT
    'a' ~ '($|^)*';

-- These cases expose a bug in the original fix for CVE-2007-4772
SELECT
    'a' ~ '(^)+^';

SELECT
    'a' ~ '$($$)+';

-- More cases of infinite loop in pullback(), not fixed by CVE-2007-4772 fix
SELECT
    'a' ~ '($^)+';

SELECT
    'a' ~ '(^$)*';

SELECT
    'aa bb cc' ~ '(^(?!aa))+';

SELECT
    'aa x' ~ '(^(?!aa)(?!bb)(?!cc))+';

SELECT
    'bb x' ~ '(^(?!aa)(?!bb)(?!cc))+';

SELECT
    'cc x' ~ '(^(?!aa)(?!bb)(?!cc))+';

SELECT
    'dd x' ~ '(^(?!aa)(?!bb)(?!cc))+';

-- Test for infinite loop in fixempties() (Tcl bugs 3604074, 3606683)
SELECT
    'a' ~ '((((((a)*)*)*)*)*)*';

SELECT
    'a' ~ '((((((a+|)+|)+|)+|)+|)+|)';

-- These cases used to give too-many-states failures
SELECT
    'x' ~ 'abcd(\m)+xyz';

SELECT
    'a' ~ '^abcd*(((((^(a c(e?d)a+|)+|)+|)+|)+|a)+|)';

SELECT
    'x' ~ 'a^(^)bcd*xy(((((($a+|)+|)+|)+$|)+|)+|)^$';

SELECT
    'x' ~ 'xyz(\Y\Y)+';

SELECT
    'x' ~ 'x|(?:\M)+';

-- This generates O(N) states but O(N^2) arcs, so it causes problems
-- if arc count is not constrained
SELECT
    'x' ~ repeat('x*y*z*', 1000);

-- Test backref in combination with non-greedy quantifier
-- https://core.tcl.tk/tcl/tktview/6585b21ca8fa6f3678d442b97241fdd43dba2ec0
SELECT
    'Programmer' ~ '(\w).*?\1' AS t;

SELECT
    regexp_matches('Programmer', '(\w)(.*?\1)', 'g');

-- Test for proper matching of non-greedy iteration (bug #11478)
SELECT
    regexp_matches('foo/bar/baz', '^([^/]+?)(?:/([^/]+?))(?:/([^/]+?))?$', '');

-- Test for infinite loop in cfindloop with zero-length possible match
-- but no actual match (can only happen in the presence of backrefs)
SELECT
    'a' ~ '$()|^\1';

SELECT
    'a' ~ '.. ()|\1';

SELECT
    'a' ~ '()*\1';

SELECT
    'a' ~ '()+\1';

-- Error conditions
SELECT
    'xyz' ~ 'x(\w)(?=\1)';

-- no backrefs in LACONs
SELECT
    'xyz' ~ 'x(\w)(?=(\1))';

SELECT
    'a' ~ '\x7fffffff';

-- invalid chr code
