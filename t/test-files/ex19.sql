create or replace function toastcheck_writer(text) returns void language plpgsql as $ff$
  declare
    func text;
    funcname text;
    attrecord record;
    pkc    record;
    indent text;
    colrec record;
    pkcols text;
    pkformat text;
    detoast_funcname text;
    pk_col_ary text[];
  begin

  pkcols = '';
  pkformat = '';
  pk_col_ary = '{}';
  funcname = 'toastcheck__' || $1;

  FOR pkc IN EXECUTE $f$ SELECT attname
                           FROM pg_attribute JOIN
                                pg_class ON (oid = attrelid) JOIN
                                pg_index on (pg_class.oid = pg_index.indrelid and attnum = any (indkey))
                          WHERE pg_class.oid = '$f$ || $1 || $f$ '::regclass and indisprimary $f$
  LOOP
     IF pkcols = '' THEN
        pkcols = quote_ident(pkc.attname);
        pkformat = '%';
     ELSE
        pkcols = pkcols || ', ' || quote_ident(pkc.attname);
        pkformat = pkformat || ', %';
     END IF;
     pk_col_ary = array_append(pk_col_ary, quote_ident(pkc.attname));
  END LOOP;

  /*
   * This is the function header.  It's basically a constant string, with the
   * table name replaced a couple of times and the primary key columns replaced
   * once.  Make sure we don't fail if there's no primary key.
   */
  IF pkcols <> '' THEN
     pkcols = ', ' || pkcols;
     pkformat = ', PK=( ' || pkformat || ' )';
  END IF;
  func = $f$
    CREATE OR REPLACE FUNCTION $f$ || funcname || $f$() RETURNS void LANGUAGE plpgsql AS $$
     DECLARE
       rec record;
     BEGIN
     FOR rec IN SELECT ctid $f$ || pkcols || $f$ FROM $f$ || $1 || $f$ LOOP
        DECLARE
          f record;
          l int;
        BEGIN
          SELECT * INTO f FROM $f$ || $1 || $f$ WHERE ctid = rec.ctid;

          -- make sure each column is detoasted and reported separately
$f$;

   /* We now need one exception block per toastable column */
   indent = '          ';
   FOR attrecord in SELECT attname, atttypid
                 FROM pg_attribute JOIN pg_class on (oid=attrelid)
                 WHERE pg_class.oid = $1::regclass and attlen = -1
   LOOP
      func := func || indent || E'BEGIN\n';
      if attrecord.atttypid = 'numeric'::regtype then
         detoast_funcname = 'numeric_sign';
      else
         detoast_funcname = 'length';
      end if;
      func := func || indent || $f$  SELECT $f$ || detoast_funcname || $f$(f.$f$ ||
              quote_ident(attrecord.attname) || E') INTO l;\n';

     /* The interesting part here needs some replacement of the PK columns */
     func := func || indent || $f$EXCEPTION WHEN OTHERS THEN
	    RAISE NOTICE 'TID %$f$ || pkformat || $f$, column "$f$ || attrecord.attname || $f$": exception {{%}}',
			     rec.ctid, $f$;

     /* This iterates zero times if there are no PK columns */
     FOR colrec IN SELECT f.i[a] AS pknm
		  FROM (select pk_col_ary as i) as f,
		       generate_series(array_lower(pk_col_ary, 1), array_upper(pk_col_ary, 1)) as a
     LOOP
       func := func || $f$ rec.$f$ || colrec.pknm || $f$, $f$;
     END LOOP;

     func := func || E'sqlerrm;\n';
     func := func || indent || E'END;\n';
   
   END LOOP;

   /* And this is our constant footer */
   func := func || $f$ 
       END;
     END LOOP;
     END;
    $$;
  $f$;

  EXECUTE func;
  RAISE NOTICE $f$Successfully created function %()$f$, funcname;
  RETURN;
  END;
$ff$;

create or replace procedure public.copy_into_table_partition(
 --some parameters
)
language plpgsql
as $body$
declare
--some declaration
begin
	--code 
	--code 
	execute format(
        $i$ --dollar quote start
            insert into public."%2$s_%5$s"(%4$s)
            select %4$s from %3$s 
            where date_time >= %1$L and date_time < (timestamp %1$L + interval '1 month')
            order by date_time
        $i$/*dollar quote end*/, partition_day, _table_name, old_table_name, column_list_as_text, _table_suffix);
	GET DIAGNOSTICS num_copied = ROW_COUNT;
	raise notice 'Copied % rows to %', num_copied, format('public."%2$s_%1$s"', _table_suffix, _table_name);
end;
$body$;
