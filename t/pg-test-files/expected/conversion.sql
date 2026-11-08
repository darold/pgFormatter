--
-- create user defined conversion
--
-- directory paths and dlsuffix are passed to us in environment variables
\getenv libdir PG_LIBDIR

\getenv dlsuffix PG_DLSUFFIX

\set regresslib :libdir '/regress' :dlsuffix
CREATE FUNCTION test_enc_setup ()
    RETURNS void
    AS :'regresslib', 'test_enc_setup'
    LANGUAGE C
    STRICT;

SELECT
FROM
    test_enc_setup ();

CREATE FUNCTION test_enc_conversion (bytea, name, name, bool, validlen OUT int, result OUT bytea)
AS :'regresslib', 'test_enc_conversion'
    LANGUAGE C
    STRICT;

CREATE USER regress_conversion_user WITH NOCREATEDB NOCREATEROLE;

SET SESSION AUTHORIZATION regress_conversion_user;

CREATE CONVERSION myconv FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

--
-- cannot make same name conversion in same schema
--
CREATE CONVERSION myconv FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

--
-- create default conversion with qualified name
--
CREATE DEFAULT CONVERSION public.mydef FOR 'LATIN1' TO 'UTF8'
FROM
    iso8859_1_to_utf8;

--
-- cannot make default conversion with same schema/for_encoding/to_encoding
--
CREATE DEFAULT CONVERSION public.mydef2 FOR 'LATIN1' TO 'UTF8'
FROM
    iso8859_1_to_utf8;

-- test comments
COMMENT ON CONVERSION myconv_bad IS 'foo';

COMMENT ON CONVERSION myconv IS 'bar';

COMMENT ON CONVERSION myconv IS NULL;

--
-- drop user defined conversion
--
DROP CONVERSION myconv;

DROP CONVERSION mydef;

--
-- Note: the built-in conversions are exercised in opr_sanity.sql,
-- so there's no need to do that here.
--
--
-- return to the superuser
--
RESET SESSION AUTHORIZATION;

DROP USER regress_conversion_user;

--
-- Test built-in conversion functions.
--
-- Helper function to test a conversion. Uses the test_enc_conversion function
-- that was created in the create_function_0 test.
CREATE OR REPLACE FUNCTION test_conv (input IN bytea, src_encoding IN text, dst_encoding IN text, result OUT bytea, errorat OUT bytea, error OUT text)
LANGUAGE plpgsql
AS $$
DECLARE
    validlen int;
BEGIN
    -- First try to perform the conversion with noError = false. If that errors out,
    -- capture the error message, and try again with noError = true. The second call
    -- should succeed and return the position of the error, return that too.
    BEGIN
        SELECT
            *
        INTO
            validlen,
            result
        FROM
            test_enc_conversion (input, src_encoding, dst_encoding, FALSE);
        errorat = NULL;
        error := NULL;
    EXCEPTION
        WHEN OTHERS THEN
            error := sqlerrm;
            SELECT
                *
            INTO
                validlen,
                result
            FROM
                test_enc_conversion (input, src_encoding, dst_encoding, TRUE);
                errorat = substr(input, validlen + 1);
    END;
    RETURN;
END;

$$;

--
-- UTF-8
--
-- The description column must be unique.
CREATE TABLE utf8_verification_inputs (
    inbytes bytea,
    description text PRIMARY KEY
);

INSERT INTO utf8_verification_inputs
VALUES
    ('\x66006f', 'NUL byte'),
    ('\xaf', 'bare continuation'),
    ('\xc5', 'missing second byte in 2-byte char'),
    ('\xc080', 'smallest 2-byte overlong'),
    ('\xc1bf', 'largest 2-byte overlong'),
    ('\xc280', 'next 2-byte after overlongs'),
    ('\xdfbf', 'largest 2-byte'),
    ('\xe9af', 'missing third byte in 3-byte char'),
    ('\xe08080', 'smallest 3-byte overlong'),
    ('\xe09fbf', 'largest 3-byte overlong'),
    ('\xe0a080', 'next 3-byte after overlong'),
    ('\xed9fbf', 'last before surrogates'),
    ('\xeda080', 'smallest surrogate'),
    ('\xedbfbf', 'largest surrogate'),
    ('\xee8080', 'next after surrogates'),
    ('\xefbfbf', 'largest 3-byte'),
    ('\xf1afbf', 'missing fourth byte in 4-byte char'),
    ('\xf0808080', 'smallest 4-byte overlong'),
    ('\xf08fbfbf', 'largest 4-byte overlong'),
    ('\xf0908080', 'next 4-byte after overlong'),
    ('\xf48fbfbf', 'largest 4-byte'),
    ('\xf4908080', 'smallest too large'),
    ('\xfa9a9a8a8a', '5-byte');

-- Test UTF-8 verification slow path
SELECT
    description,
    (test_conv (inbytes, 'utf8', 'utf8')).*
FROM
    utf8_verification_inputs;

-- Test UTF-8 verification with ASCII padding appended to provide
-- coverage for algorithms that work on multiple bytes at a time.
-- The error message for a sequence starting with a 4-byte lead
-- will contain all 4 bytes if they are present, so various
-- expressions below add 3 ASCII bytes to the end to ensure
-- consistent error messages.
-- The number 64 below needs to be at least the value of STRIDE_LENGTH in wchar.c.
-- Test multibyte verification in fast path
WITH test_bytes AS (
    SELECT
        inbytes,
        description,
        (test_conv (inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        utf8_verification_inputs
),
test_padded AS (
    SELECT
        description,
        (test_conv (inbytes || repeat('.', 64)::bytea, 'utf8', 'utf8')).error
    FROM
        test_bytes
)
SELECT
    description,
    b.error AS orig_error,
    p.error AS error_after_padding
FROM
    test_padded p
    JOIN test_bytes b USING (description)
WHERE
    p.error IS DISTINCT FROM b.error
ORDER BY
    description;

-- Test ASCII verification in fast path where incomplete
-- UTF-8 sequences fall at the end of the preceding chunk.
WITH test_bytes AS (
    SELECT
        inbytes,
        description,
        (test_conv (inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        utf8_verification_inputs
),
test_padded AS (
    SELECT
        description,
        (test_conv (repeat('.', 64 - length(inbytes))::bytea || inbytes || repeat('.', 64)::bytea, 'utf8', 'utf8')).error
    FROM
        test_bytes
)
SELECT
    description,
    b.error AS orig_error,
    p.error AS error_after_padding
FROM
    test_padded p
    JOIN test_bytes b USING (description)
WHERE
    p.error IS DISTINCT FROM b.error
ORDER BY
    description;

-- Test cases where UTF-8 sequences within short text
-- come after the fast path returns.
WITH test_bytes AS (
    SELECT
        inbytes,
        description,
        (test_conv (inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        utf8_verification_inputs
),
test_padded AS (
    SELECT
        description,
        (test_conv (repeat('.', 64)::bytea || inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        test_bytes
)
SELECT
    description,
    b.error AS orig_error,
    p.error AS error_after_padding
FROM
    test_padded p
    JOIN test_bytes b USING (description)
WHERE
    p.error IS DISTINCT FROM b.error
ORDER BY
    description;

-- Test cases where incomplete UTF-8 sequences fall at the
-- end of the part checked by the fast path.
WITH test_bytes AS (
    SELECT
        inbytes,
        description,
        (test_conv (inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        utf8_verification_inputs
),
test_padded AS (
    SELECT
        description,
        (test_conv (repeat('.', 64 - length(inbytes))::bytea || inbytes || repeat('.', 3)::bytea, 'utf8', 'utf8')).error
    FROM
        test_bytes
)
SELECT
    description,
    b.error AS orig_error,
    p.error AS error_after_padding
FROM
    test_padded p
    JOIN test_bytes b USING (description)
WHERE
    p.error IS DISTINCT FROM b.error
ORDER BY
    description;

CREATE TABLE utf8_inputs (
    inbytes bytea,
    description text
);

INSERT INTO utf8_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\xc3a4c3b6', 'valid, extra latin chars'),
    ('\xd184d0bed0be', 'valid, cyrillic'),
    ('\x666f6fe8b1a1', 'valid, kanji/Chinese'),
    ('\xe382abe3829a', 'valid, two chars that combine to one in EUC_JIS_2004'),
    ('\xe382ab', 'only first half of combined char in EUC_JIS_2004'),
    ('\xe382abe382', 'incomplete combination when converted EUC_JIS_2004'),
    ('\xecbd94eb81bceba6ac', 'valid, Hangul, Korean'),
    ('\x666f6fefa8aa', 'valid, needs mapping function to convert to GB18030'),
    ('\x66e8b1ff6f6f', 'invalid byte sequence'),
    ('\x66006f', 'invalid, NUL byte'),
    ('\x666f6fe8b100', 'invalid, NUL byte'),
    ('\x666f6fe8b1', 'incomplete character at end');

-- Test UTF-8 verification
SELECT
    description,
    (test_conv (inbytes, 'utf8', 'utf8')).*
FROM
    utf8_inputs;

-- Test conversions from UTF-8
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'euc_jis_2004')).*
FROM
    utf8_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'latin1')).*
FROM
    utf8_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'latin2')).*
FROM
    utf8_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'latin5')).*
FROM
    utf8_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'koi8r')).*
FROM
    utf8_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'utf8', 'gb18030')).*
FROM
    utf8_inputs;

--
-- EUC_JIS_2004
--
CREATE TABLE euc_jis_2004_inputs (
    inbytes bytea,
    description text
);

INSERT INTO euc_jis_2004_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\x666f6fbedd', 'valid'),
    ('\xa5f7', 'valid, translates to two UTF-8 chars '),
    ('\xbeddbe', 'incomplete char '),
    ('\x666f6f00bedd', 'invalid, NUL byte'),
    ('\x666f6fbe00dd', 'invalid, NUL byte'),
    ('\x666f6fbedd00', 'invalid, NUL byte'),
    ('\xbe04', 'invalid byte sequence');

-- Test EUC_JIS_2004 verification
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'euc_jis_2004', 'euc_jis_2004')).*
FROM
    euc_jis_2004_inputs;

-- Test conversions from EUC_JIS_2004
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'euc_jis_2004', 'utf8')).*
FROM
    euc_jis_2004_inputs;

--
-- SHIFT-JIS-2004
--
CREATE TABLE shiftjis2004_inputs (
    inbytes bytea,
    description text
);

INSERT INTO shiftjis2004_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\x666f6f8fdb', 'valid'),
    ('\x666f6f81c0', 'valid, no translation to UTF-8'),
    ('\x666f6f82f5', 'valid, translates to two UTF-8 chars '),
    ('\x666f6f8fdb8f', 'incomplete char '),
    ('\x666f6f820a', 'incomplete char, followed by newline '),
    ('\x666f6f008fdb', 'invalid, NUL byte'),
    ('\x666f6f8f00db', 'invalid, NUL byte'),
    ('\x666f6f8fdb00', 'invalid, NUL byte');

-- Test SHIFT-JIS-2004 verification
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'shiftjis2004', 'shiftjis2004')).*
FROM
    shiftjis2004_inputs;

-- Test conversions from SHIFT-JIS-2004
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'shiftjis2004', 'utf8')).*
FROM
    shiftjis2004_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'shiftjis2004', 'euc_jis_2004')).*
FROM
    shiftjis2004_inputs;

--
-- GB18030
--
CREATE TABLE gb18030_inputs (
    inbytes bytea,
    description text
);

INSERT INTO gb18030_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\x666f6fcff3', 'valid'),
    ('\x666f6f8431a530', 'valid, no translation to UTF-8'),
    ('\x666f6f84309c38', 'valid, translates to UTF-8 by mapping function'),
    ('\xa6d9', 'valid, changed from version 2000 to 2022'),
    ('\x666f6f84309c', 'incomplete char '),
    ('\x666f6f84309c0a', 'incomplete char, followed by newline '),
    ('\x666f6f84', 'incomplete char at end'),
    ('\x666f6f84309c3800', 'invalid, NUL byte'),
    ('\x666f6f84309c0038', 'invalid, NUL byte');

-- Test GB18030 verification.  Round-trip through text so the backing of the
-- bytea values is palloc, not shared_buffers.  This lets Valgrind detect
-- reads past the end.
SELECT
    description,
    inbytes,
    (test_conv (inbytes::text::bytea, 'gb18030', 'gb18030')).*
FROM
    gb18030_inputs;

-- Test conversions from GB18030
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'gb18030', 'utf8')).*
FROM
    gb18030_inputs;

--
-- ISO-8859-5
--
CREATE TABLE iso8859_5_inputs (
    inbytes bytea,
    description text
);

INSERT INTO iso8859_5_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\xe4dede', 'valid'),
    ('\x00', 'invalid, NUL byte'),
    ('\xe400dede', 'invalid, NUL byte'),
    ('\xe4dede00', 'invalid, NUL byte');

-- Test ISO-8859-5 verification
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'iso8859-5', 'iso8859-5')).*
FROM
    iso8859_5_inputs;

-- Test conversions from ISO-8859-5
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'iso8859-5', 'utf8')).*
FROM
    iso8859_5_inputs;

SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'iso8859-5', 'koi8r')).*
FROM
    iso8859_5_inputs;

--
-- Big5
--
CREATE TABLE big5_inputs (
    inbytes bytea,
    description text
);

INSERT INTO big5_inputs
VALUES
    ('\x666f6f', 'valid, pure ASCII'),
    ('\x666f6fb648', 'valid'),
    ('\x666f6fa27f', 'valid, no translation to UTF-8'),
    ('\x666f6fb60048', 'invalid, NUL byte'),
    ('\x666f6fb64800', 'invalid, NUL byte');

-- Test Big5 verification
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'big5', 'big5')).*
FROM
    big5_inputs;

-- Test conversions from Big5
SELECT
    description,
    inbytes,
    (test_conv (inbytes, 'big5', 'utf8')).*
FROM
    big5_inputs;

