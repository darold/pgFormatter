SET client_encoding TO 'UTF8';

\set ON_ERROR_STOP ON
CREATE TABLE new_table_test (
    start_date timestamp NOT NULL,
    end_date timestamp NOT NULL,
    name varchar(40) NOT NULL CHECK (name <> ''),
    fk_organization_unit_id numeric(20),
    fk_product_id numeric(20),
    id numeric(20) NOT NULL PRIMARY KEY,
    migrated varchar(1)
);

COMMENT ON TABLE new_table_test IS E'Associação dos produtos as Unidades de Estrutura responsável';

COMMENT ON COLUMN new_table_test.end_date IS E'Data fim da associação da unidade. ';

COMMENT ON COLUMN new_table_test.migrated IS E'Indica se o registro foi migrado. Valores possíveis:  S - Sim, N - Não.';

CREATE INDEX ni_ansu_3 ON new_table_test (fk_product_id, start_date);

CREATE INDEX ni_ansu_2 ON new_table_test (fk_organization_unit_id ASC, fk_product_id DESC);

CREATE INDEX ni_ansu_1 ON new_table_test (fk_product_id ASC, start_date ASC);

ALTER TABLE new_table_test
    ADD CONSTRAINT ora2pg_ckey_fk_organization_unit_id CHECK (fk_organization_unit_id IS NOT NULL);

ALTER TABLE new_table_test
    ADD CONSTRAINT ck_ansu_fk_org_unit_id CHECK (fk_organization_unit_id IS NOT NULL AND fk_organization_unit_id > 1000);

ALTER TABLE new_table_test
    ADD CONSTRAINT fk_ansu_produ_id FOREIGN KEY (FK_PRODUCT_ID) REFERENCES PRODUCT (ID);

CREATE TABLE test_uuid (
    nom varchar(25),
    uid_col bytea NOT NULL DEFAULT uuid_generate_v4 ()
);

CREATE TABLE test_boolean (
    id bigint,
    is_deleted boolean,
    is_updated boolean
);

ALTER TABLE test_boolean
    ADD PRIMARY KEY (id, is_deleted, is_updated);

CREATE TABLE table_0 (
    ref_1 integer REFERENCES table_1 ON DELETE RESTRICT,
    ref_2 integer REFERENCES table_2 ON DELETE CASCADE,
    ref_3 integer REFERENCES table_3 ON DELETE SET NULL
);

COMMENT ON TABLE foo.bar IS $comment$
This is a nicely formatted comment line that spans
over multiple lines that should remain untouched

$comment$;

COMMENT ON TABLE foo2 IS 'Hello world';

-- Multi-line comment
COMMENT ON TABLE test IS E'foo\n'
    'bar\n'
    'bat';

