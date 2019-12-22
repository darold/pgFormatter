ALTER TABLE boxes
    ADD CONSTRAINT my_constraint
    EXCLUDE USING gist (some_id WITH =, make_tsrange(created_at, expires_at) WITH &&);

CREATE TABLE circles (
    c circle,
    EXCLUDE USING gist (c WITH &&)
);

ALTER TABLE ONLY public.circles
    ADD CONSTRAINT circles_c_excl
    EXCLUDE USING gist (c WITH &&);

ALTER TABLE truck
    ADD EXCLUDE USING gist (id WITH =, system_period WITH &&);

