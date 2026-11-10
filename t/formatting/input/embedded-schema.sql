-- Dollar-quoted JSON with negative numbers, nullable arrays, and nested objects.
INSERT INTO demo_private.schemas (kind, name, definition)
    VALUES ('validation', 'record', $schema${
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid"
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 300
    },
    "note": {
      "type": [
        "string",
        "null"
      ],
      "maxLength": 16000
    },
    "x_coord": {
      "type": [
        "number",
        "null"
      ],
      "minimum": -90,
      "maximum": 90
    },
    "y_coord": {
      "type": [
        "number",
        "null"
      ],
      "minimum": -180,
      "maximum": 180
    }
  },
  "required": [
    "id",
    "name",
    "note",
    "x_coord",
    "y_coord"
  ]
}$schema$::jsonb);
