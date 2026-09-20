INSERT INTO widgets (
    id,
    label
)
SELECT
    1,
    2;

SELECT
    id
FROM
    widgets
WHERE
    id IN (
        SELECT
            widget_id
        FROM
            archive
    );

DO $$
BEGIN
    IF (
        SELECT
            count(*)
        FROM
            widgets
    ) = 0 THEN
        PERFORM
            1;
    ELSE
        PERFORM
            2;
    END IF;
END
$$;

