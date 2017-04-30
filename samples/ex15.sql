SELECT
    user_id,
    view_homepage,
    view_homepage_time,
    enter_credit_card,
    enter_credit_card_time
FROM ( -- Get the first time each user viewed the homepage.
    SELECT
        user_id,
        1 AS view_homepage,
        min (time) AS view_homepage_time
    FROM
        event
    WHERE
        data ->> 'type' = 'view_homepage'
    GROUP BY
        user_id)
    e1
    LEFT JOIN LATERAL ( -- For each row, get the first time the user_id did the enter_credit_card
        -- event, if one exists within two weeks of view_homepage_time.
    SELECT
        1 AS enter_credit_card,
        time AS enter_credit_card_time
    FROM
        event
    WHERE
        user_id = e1.user_id
        AND data ->> 'type' = 'enter_credit_card'
        AND time BETWEEN view_homepage_time
        AND (view_homepage_time + 1000 * 60 * 60 * 24 * 14)
    ORDER BY
        time
    LIMIT 1)
    e2 ON TRUE;
