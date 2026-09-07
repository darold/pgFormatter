SELECT
    A.COL,
    B.NAME,
    count(*) AS TOTAL,
    MYSCHEMA.MYTABLE.ID
FROM
    MYSCHEMA.MYTABLE A
    JOIN OTHER_TBL B ON A.ID = B.REF_ID
WHERE
    A.STATUS = 1
    AND B."MixedCol" > 0;

SELECT
    T."weird.name",
    SCHEMA."My.Tbl".PLAINCOL,
    VAL::integer
FROM
    PUBLIC.USERS T;

CREATE TABLE APP.ORDERS (
    ID integer,
    CUSTOMER_ID integer,
    ORDER_DATE timestamp
);

