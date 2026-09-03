CREATE TABLE example (
    id         serial PRIMARY KEY,                                -- some comment
    name       varchar(100)             NOT NULL,                 -- another comment
    email      varchar(100)             NOT NULL,                 -- third comment
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP -- last comment
);
