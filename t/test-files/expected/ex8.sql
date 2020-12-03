SELECT
    'hello',
    2 + 2,
    'o\'grady',
    0,
    '',
    count(*),
    'that\'s the position you\'re in now no matter where you select it';

SELECT
    1e-5,
    1e+5,
    10 + 20,
    colname + 12;

CREATE TABLE public.sample (
    a integer,
    b integer,
    c integer
);

CREATE TABLE "public".sample (
    a integer,
    b integer,
    c integer
);

CREATE TABLE public."sample" (
    a integer,
    b integer,
    c integer
);

CREATE TABLE "public"."sample" (
    a integer,
    b integer,
    c integer
);

CREATE TABLE collate_test_fail (
    a int,
    b text COLLATE "ja_JP.eucjp-x-icu"
);

