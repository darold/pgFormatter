-- Explicitly cast JSON with a long regex, escaped string, and required fields.
INSERT INTO demo.schemas(
  kind,
  definition
)
VALUES (
  'record',
  $json$
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "format": "uuid",
        "pattern": "^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$"
      },
      "label": {
        "type": "string",
        "maxLength": 1024,
        "pattern": "\\S",
        "description": "A descriptive label supplied by the caller."
      }
    },
    "required": [
      "id",
      "label"
    ],
    "additionalProperties": false
  }
  $json$::jsonb
);

-- Every pretty JSON line can fit after conversion; the adjacent cast stays stable.
INSERT INTO fixture(
  schema,
  updated
)
VALUES (
  $json$
  {
    "type": "object",
    "properties": {
      "first": {
        "type": "string"
      },
      "second": {
        "type": "string"
      },
      "third": {
        "type": "string"
      }
    },
    "required": [
      "first",
      "second",
      "third"
    ],
    "additionalProperties": false
  }
  $json$::jsonb,
  now()
);
