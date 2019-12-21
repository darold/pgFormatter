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

