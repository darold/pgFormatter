-- Simple calls stay compact; complex expressions expand structurally.
select gen_random_uuid(), btrim(name), coalesce(nullif(btrim(person.meta ->> 'full_name'), ''), person.email, 'Personal account') from people person;
select coalesce(array[1, 2], array[3, 4]), custom.wrap(custom.read(meta -> 'value'), fallback) from people;
