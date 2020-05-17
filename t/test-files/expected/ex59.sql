DELIMITER $$ -- We change the delimiter: it is now $$ instead of ;
CREATE PROCEDURE TEST ()
BEGIN
    SELECT
        "Hello World";

END;

$$ -- This is the delimiter that marks the end of the procedure definition.
DELIMITER ;

