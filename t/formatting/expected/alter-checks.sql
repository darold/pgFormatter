BEGIN;

ALTER TABLE app.rules
  ADD COLUMN label text CHECK (
    label IS NULL
    OR btrim(label) <> ''
  ),
  ADD COLUMN document jsonb CHECK (
    document IS NULL
    OR (
      jsonb_typeof(document) = 'object'
      AND app.valid_document(document::json) IS TRUE
    )
  ),
  ADD COLUMN tags text[] CHECK (
    tags IS NULL
    OR cardinality(tags) > 0
  );

COMMENT ON TABLE app.rules IS 'These rules preserve commas, parentheses (), and literal spacing.';

ALTER TABLE app.samples
  ADD COLUMN amount integer CHECK (
    amount BETWEEN 1 AND 20
    OR amount IS NULL
  ),
  ADD COLUMN enabled boolean CHECK (enabled IS TRUE),
  ADD CONSTRAINT allowed_amount CHECK (
    amount IS NULL
    OR amount IN (1, 2, 3)
  ),
  ALTER COLUMN amount SET DEFAULT 1,
  DROP COLUMN obsolete;

ALTER TABLE app.samples
  ADD COLUMN revision integer DEFAULT 1;

ALTER TABLE app.samples
  ALTER COLUMN revision SET DEFAULT 2,
  ADD CONSTRAINT revision_allowed CHECK (
    revision IS NULL
    OR revision > 0
  ),
  ALTER COLUMN revision DROP DEFAULT;

COMMIT;
