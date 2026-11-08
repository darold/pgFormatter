SELECT 'a long literal with several words', E'escape\tstring', "Quoted Identifier With Spaces", a_very_long_identifier_name_that_does_not_fit_in_the_line, 123456789012345678901234567890 FROM t WHERE c = 'another long literal value';
/* strings between two C style comments */
SELECT a FROM t WHERE b IN ('one', ' two', 'three four five six seven', 'eight');
/* end */
SELECT 5 # 3 AS xor_of_two_values, # polygon '((0,0),(1,1),(2,0))' AS number_of_points;
\set a_long_psql_variable_name 'a long value that must stay on one line'
