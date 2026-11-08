SELECT
    @#@ 24,
    @@##@@ 24,
    5 ###### 6,
    t ^@ 'Worth',
    a === 1,
    b <<< 5,
    a <= b,
    a <> b,
    j ->> 'k',
    a = -1,
    x @> y,
    2 * -3,
    @ f.f1;

COMMENT ON OPERATOR ###### (int4,
    NONE) IS 'x';

CREATE OPERATOR schema_op1.#*# (
    RIGHTARG = int8,
    PROCEDURE = factorial
);

CREATE OPERATOR ri_cast.>>> (
    LEFTARG = int4[],
    RIGHTARG = int4[],
    FUNCTION = ri_i4a_gt
);

DROP OPERATOR IF EXISTS no_such_schema.+ (int, int);

