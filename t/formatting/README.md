# Formatting regression fixtures

Run `prove -lv t/08_formatting.t` from the repository root. The tests use
`profiles/readable.conf` and invoke the real CLI; `PG_FORMAT` can select another
executable. Fixtures are parser/formatter inputs and are never executed.

Each fixture is named for the syntax it exercises:

| Fixture | Coverage |
| --- | --- |
| `alter-checks.sql` | Sibling ALTER actions, nested CHECK predicates, and BETWEEN bounds |
| `subquery-condition.sql` | Procedural frame restoration after scalar subqueries |
| `returning-clauses.sql` | Nested writes with `RETURNING INTO` |
| `schema-migration.sql` | DDL, partial indexes, query loops, triggers, and privileges |
| `case-statements.sql` | Procedural CASE, SELECT INTO, and a default exception |
| `conditional-updates.sql` | Nested conditionals, cast expressions, CASE assignments, and exception lists |
| `foreign-keys.sql` | Composite keys and clause state across statements |
| `policies.sql` | Policy commands, predicates, subqueries, and identifier casing |
| `nested-functions.sql` | Compact simple calls and expanded complex arguments |
| `dollar-literals.sql` | Quoting boundaries inside executable bodies and comments |
| `embedded-schema.sql` | Dollar-quoted JSON, nullable arrays, and negative numbers |
| `json-schema.sql` | Cast JSON conversion, long scalar values, and cast spacing |
| `line-width.sql` | Boolean continuations, compact argument lists, and comments |

Expected files lock down reviewed layout. All inputs also check idempotence,
non-JSON literal bytes, cast JSON values, comment text/order, and independently
lexed SQL tokens, including executable dollar bodies. The preservation lexer
covers these fixtures; it is not a complete PostgreSQL semantic proof.
