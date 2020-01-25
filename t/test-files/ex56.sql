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
            /* this is a comment */
) AS last_answered
FROM
    ticket.inquiry i;

CREATE FUNCTION state_update (id int4, new int4) RETURNS int4
    AS $$
BEGIN
    INSERT INTO state (id, state, when)
    VALUES (id, new, CURRENT_TIMESTAMP);
    INSERT INTO state (id, state, when)
    VALUES (id, new, CURRENT_TIMESTAMP)
ON CONFLICT (id) -- ### this line should not be dedented
    DO UPDATE SET
        state = excluded.state, when = excluded.when;
    RETURN 1;
END;
$$
LANGUAGE plpgsql;
CREATE PROCEDURE insert_data (a integer, b integer)
LANGUAGE SQL
AS $$
    INSERT INTO tbl VALUES (a);
INSERT INTO foo AS bar DEFAULT VALUES RETURNING foo.*;
    INSERT INTO tbl VALUES (b) RETURNING b;
$$;

INSERT INTO foo AS bar DEFAULT
    VALUES
    RETURNING
        foo.*;

CREATE TYPE foo AS enum (
    'busy',
    'help'
);

CREATE TYPE IF NOT EXISTS foo AS enum ( 'busy',
    'help'
);

CREATE TABLE IF NOT EXISTS foo (
    id bigint PRIMARY KEY,
    /*
     This text will receive an extra level of indentation
     every time pg_format is executed
     */
    bar text NOT NULL
    /* this is the end*/
);

CREATE INDEX onek_unique1 ON onek
    USING btree (unique1 int4_ops);

CREATE INDEX IF NOT EXISTS onek_unique1 ON onek
    USING btree (unique1 int4_ops);

CREATE STATISTICS ab1_a_b_stats ON a, b FROM ab1;

CREATE STATISTICS IF NOT EXISTS ab1_a_b_stats ON a, b FROM ab1;

