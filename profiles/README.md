# Formatting profiles

`readable.conf` combines two-space indentation, uppercase keywords, lowercase
types, expanded complex function calls, aligned closing delimiters, and a
100-character SQL code width. Overlong literals explicitly cast to `json` or
`jsonb` become multiline JSON; other literal values remain unchanged.

```sh
./pg_format --config profiles/readable.conf input.sql > formatted.sql
```

The profile is optional. Each setting can be overridden on the command line.
The formatting regression tests use the same profile.
