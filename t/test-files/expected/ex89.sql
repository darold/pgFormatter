-- Operator names are regex metacharacters and must be restored verbatim
CREATE OPERATOR ? (
    LEFTARG = hstore,
    RIGHTARG = text,
    PROCEDURE = exist
);

CREATE OPERATOR ?| (
    LEFTARG = hstore,
    RIGHTARG = text[],
    PROCEDURE = exists_any
);

CREATE OPERATOR <| (
    PROCEDURE = int8lt,
    LEFTARG = bigint,
    RIGHTARG = bigint
);

CREATE OPERATOR * (
    PROCEDURE = int8mul,
    LEFTARG = bigint,
    RIGHTARG = bigint
);

DROP OPERATOR <| (bigint, bigint);

