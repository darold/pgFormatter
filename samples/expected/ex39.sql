ALTER TABLE boxes
    ADD CONSTRAINT my_constraint
    USING gist (some_id WITH =, make_tsrange (created_at, expires_at) WITH &&);

CREATE TABLE circles (
    c circle,
    USING gist (c WITH &&)
);

ALTER TABLE ONLY public.circles
    ADD CONSTRAINT circles_c_excl
    USING gist (c WITH &&);

