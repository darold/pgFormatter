SELECT * FROM a, ONLY (c) JOIN b USING (id, id2) LEFT JOIN d USING (id) WHERE id > 10 AND id <= 20;
