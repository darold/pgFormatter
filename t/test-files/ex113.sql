-- Input in a single byte encoding (Latin-1 / Windows-1252)
select 'café', upper('äöü') as "résultat" from t where c = 'ß€';
