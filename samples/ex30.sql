CREATE OR REPLACE FUNCTION plpython_demo()
RETURNS void
AS $$
	from this import s, d

	for char in s:
		print(d.get(char, char), end="")

	print()
$$
LANGUAGE 'plpython3u';

CREATE TABLE IF NOT EXISTS foo (
        id bigint PRIMARY KEY,
	/*
	This text will receive an extra level of indentation
	every time pg_format is executed
	*/
        bar text NOT NULL
	/* this is the end*/
);

COMMENT ON TABLE xx.yy IS 'Line 1
- Line 2
- Line 3';

CREATE TABLE IF NOT EXISTS foo (
        /*******************************************************
        * This text will receive an extra level of indentation *
        * every time pg_format is executed                     *
        ********************************************************/
        id bigint PRIMARY KEY,
        /*
        This text will receive an extra level of indentation
        every time pg_format is executed
        */
        bar text NOT NULL
        /* this is the end*/
);


