-- Subquery in the arguments of a function opened on the line where another subquery ends
SELECT
    sum(amount)
FROM
    payments + /* keep this comment to avoid crash */ (
        SELECT
            sum(amount)
        FROM payments
        WHERE
            owner_id IN (
                SELECT
                    id
                FROM invoices)) + coalesce((
                    SELECT
                        sum(amount)
                    FROM payments
                    WHERE
                        type IN ('xxx')), 0);

SELECT
    a + (
        SELECT
            max(x)
        FROM
            u
        WHERE
            y IN (
                SELECT
                    id
                FROM
                    i)) + coalesce((
                        SELECT
                            sum(z)
                        FROM v
                        WHERE
                            k IN ('x')), 0) AS total,
    b
FROM
    t
WHERE
    c = 1
    AND d IN (
        SELECT
            e
        FROM
            w)
ORDER BY
    b;

SELECT
    coalesce((
        SELECT
            sum(amount)
        FROM payments
        WHERE
            kind IN ('xxx')), 0);

