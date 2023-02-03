SELECT
    app_public.hello(test);

DROP FUNCTION IF EXISTS app_public.hello(a text);

TRUNCATE
    table001,
    table002,
    table003,
    table004,
    table005,
    table006,
    table007,
    table008,
    table009,
    table010
RESTART IDENTITY
CASCADE;

TRUNCATE t1;

TRUNCATE t2 RESTART IDENTITY CASCADE;

