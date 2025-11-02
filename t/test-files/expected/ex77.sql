CREATE POLICY "My policy" ON mytable
    FOR SELECT TO myrole
        USING (_is_org_member ((
            SELECT
                n.org_id
            FROM
                networks n
            WHERE
                network_id = n.id LIMIT 1)));

SELECT
    1.2e-7::double precision;

SELECT
    1.2e+7::double precision;

SELECT
    12e+7::double precision;

