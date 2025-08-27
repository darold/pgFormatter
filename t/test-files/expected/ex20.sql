SELECT
    group_concat(k.column_name ORDER BY k.ordinal_position) AS column_names,
    t.table_name AS table_name,
    t.table_schema AS table_schema,
    t.constraint_name AS constraint_name
FROM
    information_schema.table_constraints t
    LEFT JOIN information_schema.key_column_usage k USING (constraint_name, table_schema, table_name)
WHERE
    t.constraint_type = 'PRIMARY KEY'
GROUP BY
    t.table_schema,
    t.table_name;

