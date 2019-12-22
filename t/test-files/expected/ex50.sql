-- function to wait for counters to advance
CREATE FUNCTION wait_for_stats ()
    RETURNS void
    AS $$
DECLARE
    start_time timestamptz := clock_timestamp();
    updated1 bool;
    updated2 bool;
    updated3 bool;
    updated4 bool;
BEGIN
    -- we don't want to wait forever; loop will exit after 30 seconds
    FOR i IN 1..300 LOOP
        -- With parallel query, the seqscan and indexscan on tenk2 might be done
        -- in parallel worker processes, which will send their stats counters
        -- asynchronously to what our own session does.  So we must check for
        -- those counts to be registered separately from the update counts.
        -- check to see if seqscan has been sensed
        SELECT
            (st.seq_scan >= pr.seq_scan + 1) INTO updated1
        FROM
            pg_stat_user_tables AS st,
            pg_class AS cl,
            prevstats AS pr
        WHERE
            st.relname = 'tenk2'
            AND cl.relname = 'tenk2';
        -- check to see if indexscan has been sensed
        SELECT
            (st.idx_scan >= pr.idx_scan + 1) INTO updated2
        FROM
            pg_stat_user_tables AS st,
            pg_class AS cl,
            prevstats AS pr
        WHERE
            st.relname = 'tenk2'
            AND cl.relname = 'tenk2';
        -- check to see if all updates have been sensed
        SELECT
            (n_tup_ins > 0) INTO updated3
        FROM
            pg_stat_user_tables
        WHERE
            relname = 'trunc_stats_test4';
        -- We must also check explicitly that pg_stat_get_snapshot_timestamp has
        -- advanced, because that comes from the global stats file which might
        -- be older than the per-DB stats file we got the other values from.
        SELECT
            (pr.snap_ts < pg_stat_get_snapshot_timestamp ()) INTO updated4
        FROM
            prevstats AS pr;
        exit
        WHEN updated1
            AND updated2
            AND updated3
            AND updated4;
        -- wait a little
        PERFORM
            pg_sleep_for ('100 milliseconds');
        -- reset stats snapshot so we can test again
        PERFORM
            pg_stat_clear_snapshot();
    END LOOP;
    -- report time waited in postmaster log (where it won't change test output)
    RAISE log 'wait_for_stats delayed % seconds', extract(epoch FROM clock_timestamp() - start_time);
END
$$
LANGUAGE plpgsql;

-- test ordered-set aggs using built-in support functions
CREATE AGGREGATE my_percentile_disc (float8 ORDER BY anyelement) (
    STYPE = internal,
    SFUNC = ordered_set_transition,
    FINALFUNC = percentile_disc_final,
    FINALFUNC_EXTRA = TRUE,
    FINALFUNC_MODIFY = READ_WRITE
);

CREATE AGGREGATE my_rank (VARIADIC "any" ORDER BY VARIADIC "any") (
    STYPE = internal,
    SFUNC = ordered_set_transition_multi,
    FINALFUNC = rank_final,
    FINALFUNC_EXTRA = TRUE,
    hypothetical
);

