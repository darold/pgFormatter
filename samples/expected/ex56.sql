CREATE VIEW ticket. "view_ticket_inquiry" AS
SELECT
    i.*,
    (
        SELECT
            max(tl.creation_time)
        FROM
            wf.transition_log tl
        WHERE
            tl.workflow_id = i.id
            AND tl.dst_station_id = 25346145527
            /* this is a comment */) AS last_answered
FROM
    ticket.inquiry i;

CREATE FUNCTION state_update (id int4, new int4)
    RETURNS int4
    AS $$
BEGIN
    INSERT INTO state (id, state, WHEN)
        VALUES (id, new, CURRENT_TIMESTAMP);
    INSERT INTO state (id, state, WHEN)
        VALUES (id, new, CURRENT_TIMESTAMP)
    ON CONFLICT (id) -- ### this line should not be dedented
        DO UPDATE SET
            state = excluded.state, WHEN = excluded.when;
    RETURN 1;
END;
$$
LANGUAGE plpgsql;

CREATE PROCEDURE insert_data (a integer, b integer)
LANGUAGE SQL
AS $$
    INSERT INTO tbl
        VALUES (a);
    INSERT INTO foo AS bar DEFAULT
        VALUES
        RETURNING
            foo.*;
    INSERT INTO tbl
        VALUES (b)
    RETURNING
        b;
$$;

INSERT INTO foo AS bar DEFAULT
    VALUES
    RETURNING
        foo.*;

