insert into videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
on conflict (sha, idx)
    do update set
        sha = excluded.sha, idx = excluded.idx, title = excluded.title, codec = excluded.codec, mime_codec = excluded.mime_codec, width = excluded.width, height = excluded.height, is_default = excluded.is_default, bitrate = excluded.bitrate;

insert into videos (sha, idx, title, codec, mime_codec, width, height, is_default, bitrate)
    values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
on conflict (sha, idx)
    do update set
         (a, b, c) = (excluded.a, excluded.b, excluded.c);

INSERT INTO insertconflicttest
    VALUES (0, 'Crowberry')
ON CONFLICT (KEY, fruit)
    DO UPDATE SET
        fruit = excluded.fruit
    WHERE
        EXISTS ( SELECT 1 FROM insertconflicttest ii WHERE ii.key = excluded.key);

insert into upsert values(1, 'val') on conflict (key) do update set val = 'seen with subselect ' || (select f1 from int4_tbl where f1 != 0 limit 1)::text;
