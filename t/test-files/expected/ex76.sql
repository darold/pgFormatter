INSERT INTO videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
ON CONFLICT (sha, idx)
    DO UPDATE SET
        sha = excluded.sha,
        idx = excluded.idx,
        title = excluded.title,
        codec = excluded.codec,
        mime_codec = excluded.mime_codec,
        width = excluded.width,
        height = excluded.height,
        is_default = excluded.is_default,
        bitrate = excluded.bitrate;

INSERT INTO videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
ON CONFLICT (sha, idx)
    DO UPDATE SET
        (a, b, c) = (excluded.a, excluded.b, excluded.c);

INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (KEY, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                insertconflicttest ii
            WHERE
                ii.key = excluded.key);

INSERT INTO upsert
    VALUES (1, 'val')
ON CONFLICT (key)
    DO UPDATE SET
        val = 'seen with subselect ' || (
            SELECT
                f1
            FROM
                int4_tbl
            WHERE
                f1 != 0
            LIMIT 1)::text;

