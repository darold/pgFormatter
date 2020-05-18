CREATE OR REPLACE FUNCTION toastcheck_writer (text)
    RETURNS void
    LANGUAGE plpgsql
    AS $ff$
DECLARE
    func text;
    funcname text;
    attrecord record;
    pkc record;
    indent text;
    colrec record;
    pkcols text;
    pkformat text;
    detoast_funcname text;
    pk_col_ary text[];
BEGIN
    pkcols = '';
    pkformat = '';
    pk_col_ary = '{}';
    funcname = 'toastcheck__' || $1;
    FOR pkc IN EXECUTE $f$ SELECT attname
                           FROM pg_attribute JOIN
                                pg_class ON (oid = attrelid) JOIN
                                pg_index on (pg_class.oid = pg_index.indrelid and attnum = any (indkey))
                          WHERE pg_class.oid = '$f$ || $1 || $f$ '::regclass and indisprimary $f$ LOOP
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
    FOR attrecord IN
    SELECT
        attname,
        atttypid
    FROM
        pg_attribute
        JOIN pg_class ON (oid = attrelid)
    WHERE
        pg_class.oid = $1::regclass
        AND attlen = - 1 LOOP
            func := func || indent || E'BEGIN\n';
            IF attrecord.atttypid = 'numeric'::regtype THEN
                detoast_funcname = 'numeric_sign';
            ELSE
                detoast_funcname = 'length';
            END IF;
            func := func || indent || $f$  SELECT $f$ || detoast_funcname || $f$(f.$f$ || quote_ident(attrecord.attname) || E') INTO l;\n';

            /* The interesting part here needs some replacement of the PK columns */
            func := func || indent || $f$EXCEPTION WHEN OTHERS THEN
	    RAISE NOTICE 'TID %$f$ || pkformat || $f$, column "$f$ || attrecord.attname || $f$": exception {{%}}',
			     rec.ctid, $f$;

            /* This iterates zero times if there are no PK columns */
            FOR colrec IN
            SELECT
                f.i[a] AS pknm
            FROM (
                SELECT
                    pk_col_ary AS i) AS f,
            generate_series(array_lower(pk_col_ary, 1), array_upper(pk_col_ary, 1)) AS a LOOP
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

