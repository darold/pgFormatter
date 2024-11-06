-- test placeholder: perl pg_format samples/ex9.sql -p '<<(?:.*)?>>'
SELECT * FROM projects WHERE projectnumber in <<internalprojects>> and username = <<loginname>>;


CREATE TEMPORARY TABLE tt_monthly_data AS
WITH a1 AS (
	SELECT * FROM test1
)
SELECT ROUND(AVG(t1)) avg_da, ROUND(AVG(t2)) FROM a1;

insert into videos(sha, idx, title, language, codec, mime_codec, width, height, is_default, bitrate)
values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
on conflict (sha, idx) do update set
	sha = excluded.sha,
	idx = excluded.idx,
	title = excluded.title,
	language = excluded.language,
	codec = excluded.codec,
	mime_codec = excluded.mime_codec,
	width = excluded.width,
	height = excluded.height,
	is_default = excluded.is_default,
	bitrate = excluded.bitrate;
