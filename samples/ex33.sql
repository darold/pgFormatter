SELECT CASE WHEN my_col IS NOT NULL THEN 'Y' ELSE 'N' END AS my_new_col, CASE WHEN TRIM(my_other_col) = 'confirmed' THEN 'Y' ELSE 'N' END AS new_col FROM my_table;

select distinct on (a, b) a, b, c from d order by a, b, c;

select distinct a, b, b, c from d order by a, b, c;
