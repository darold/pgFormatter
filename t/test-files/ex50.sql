-- function to wait for counters to advance
create function wait_for_stats() returns void as $$
declare
  start_time timestamptz := clock_timestamp();
  updated1 bool;
  updated2 bool;
  updated3 bool;
  updated4 bool;
begin
  -- we don't want to wait forever; loop will exit after 30 seconds
  for i in 1 .. 300 loop

    -- With parallel query, the seqscan and indexscan on tenk2 might be done
    -- in parallel worker processes, which will send their stats counters
    -- asynchronously to what our own session does.  So we must check for
    -- those counts to be registered separately from the update counts.

    -- check to see if seqscan has been sensed
    SELECT (st.seq_scan >= pr.seq_scan + 1) INTO updated1
      FROM pg_stat_user_tables AS st, pg_class AS cl, prevstats AS pr
     WHERE st.relname='tenk2' AND cl.relname='tenk2';

    -- check to see if indexscan has been sensed
    SELECT (st.idx_scan >= pr.idx_scan + 1) INTO updated2
      FROM pg_stat_user_tables AS st, pg_class AS cl, prevstats AS pr
     WHERE st.relname='tenk2' AND cl.relname='tenk2';

    -- check to see if all updates have been sensed
    SELECT (n_tup_ins > 0) INTO updated3
      FROM pg_stat_user_tables WHERE relname='trunc_stats_test4';

    -- We must also check explicitly that pg_stat_get_snapshot_timestamp has
    -- advanced, because that comes from the global stats file which might
    -- be older than the per-DB stats file we got the other values from.
    SELECT (pr.snap_ts < pg_stat_get_snapshot_timestamp()) INTO updated4
      FROM prevstats AS pr;

    exit when updated1 and updated2 and updated3 and updated4;

    -- wait a little
    perform pg_sleep_for('100 milliseconds');

    -- reset stats snapshot so we can test again
    perform pg_stat_clear_snapshot();

  end loop;

  -- report time waited in postmaster log (where it won't change test output)
  raise log 'wait_for_stats delayed % seconds',
    extract(epoch from clock_timestamp() - start_time);
end
$$ language plpgsql;

-- test ordered-set aggs using built-in support functions
create aggregate my_percentile_disc(float8 ORDER BY anyelement) (
  stype = internal,
  sfunc = ordered_set_transition,
  finalfunc = percentile_disc_final,
  finalfunc_extra = true,
  finalfunc_modify = read_write
);

create aggregate my_rank(VARIADIC "any" ORDER BY VARIADIC "any") (
  stype = internal,
  sfunc = ordered_set_transition_multi,
  finalfunc = rank_final,
  finalfunc_extra = true,
  hypothetical
);

