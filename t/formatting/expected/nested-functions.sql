-- Simple calls stay compact; complex expressions expand structurally.
SELECT
  gen_random_uuid(),
  btrim(name),
  coalesce(
    nullif(
      btrim(
        person.meta ->> 'full_name'
      ),
      ''
    ),
    person.email,
    'Personal account'
  )
FROM
  people person;

SELECT
  coalesce(ARRAY[1, 2], ARRAY[3, 4]),
  custom.wrap(
    custom.read(
      meta -> 'value'
    ),
    fallback
  )
FROM
  people;
