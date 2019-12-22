/* Insert values for environment 1 */
INSERT INTO table
    VALUES (1, 2, '3');

/* Insert values for environment 2 */
/* Insert values for environment 3 */
INSERT INTO table
    VALUES (2, 17, 'hello');
-- New comment for a query
SELECT library.column1,
                        ---------------------    
                        -- This is a line  --     
                        -- comment in a    --     
                        -- SQL statement   --    
                        ---------------------     
                        library.column2, library.column3 -- inline comment     
FROM library;
