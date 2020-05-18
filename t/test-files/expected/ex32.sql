CREATE TABLE projects (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4 (),
    name citext NOT NULL CHECK (name ~* '^[a-z0-9_-]{3,255}$'),
    owner_id uuid NOT NULL,
    UNIQUE (owner_id, name),
    PRIMARY KEY (id, name)
);

CREATE TABLE projects (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4 (),
    name citext NOT NULL CHECK (name ~* '^[a-z0-9_-]{3,255}$'),
    owner_id uuid NOT NULL,
    UNIQUE name,
    PRIMARY KEY id
);

CREATE TABLE sample (
    fkey integer REFERENCES other (id) ON UPDATE CASCADE ON DELETE CASCADE,
    other integer,
    columns integer
);

