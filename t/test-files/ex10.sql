with a as (
  select x, y, z
    from twelve
    join nine
      on a = 2
     and b = a
), b as (
  select *
    from a
) select *
    from b;
