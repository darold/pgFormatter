SELECT
    attributes -> 'key'
FROM
    json_test;

CREATE TABLE foobar (
    id integer NOT NULL,
    version integer NOT NULL,
    prev_id integer NOT NULL,
    prev_version integer NOT NULL,
    PRIMARY KEY (id, version),
    UNIQUE (prev_id, prev_version),
    FOREIGN KEY (prev_id, prev_version) REFERENCES foobar (id, version),
    FOREIGN KEY (id, version) REFERENCES barfoo (next_id, next_version)
);

CREATE TABLE accounts (
    password varchar(255),
    type varchar(255),
    passwords varchar(255),
    set double precision,
    exclude varchar(255),
    created date DEFAULT DATE '2026-01-01',
    CONSTRAINT DATE UNIQUE (passwords)
);

CREATE UNLOGGED TABLE accounts_unlogged (
    password varchar(255)
);

