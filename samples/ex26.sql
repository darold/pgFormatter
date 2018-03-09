PREPARE demo AS 
INSERT INTO demo VALUES (1, 2, 3, 4);

PREPARE demo AS 
SELECT * FROM demo WHERE id IN (1, 2, 3, 4);

PREPARE demo AS 
UPDATE demo SET lbl = 'unknown' WHERE id IN (1, 2, 3, 4);

PREPARE demo AS 
DELETE FROM demo WHERE id IN (1, 2, 3, 4);

