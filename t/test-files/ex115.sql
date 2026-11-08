select 1 /* a /* b */ c */ + 2;
/* top /* nested */ end */
select '/* not */', $$ /* x /* y */ $$, 3;
SELECT /* one
/* two */
*/ 'x' AS y;
