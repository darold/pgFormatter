SELECT attributes->'key' FROM json_test;

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
