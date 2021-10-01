SELECT
    col::"text"
FROM
    tab;

ALTER TABLE tab
    ALTER COLUMN col TYPE "schema"."dataType"
    USING col::text::"schema"."dataType";

