COPY time
FROM
    's3://mybucket/data/timerows.gz' iam_role 'arn:aws:iam::0123456789012:role/MyRedshiftRole' GZIP DELIMITER '|';

