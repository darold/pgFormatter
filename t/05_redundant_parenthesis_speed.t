use strict;
use warnings;
use Test::More;
use lib 'lib';
use pgFormatter::Beautify;

sub format_sql
{
	my $beautifier = pgFormatter::Beautify->new();
	$beautifier->query(shift);
	$beautifier->beautify();
	return $beautifier->content();
}

# The indentation of these statements keeps growing, because of the psql
# variable in the function. The time spent on the redundant parentheses must
# not explode with the length of the runs of whitespace (more than 15 seconds with
# 15 statements of each kind before this was fixed, 20 took more than a minute).
my $sql = "CREATE FUNCTION f()\n    AS :'r', 'h'\n    RETURNS text\n"
	. "ALTER FOREIGN TABLE IF EXISTS t ALTER COLUMN c TYPE char(10);\n" x 15
	. "SELECT * FROM t ORDER BY 1, 2;\n" x 15
	. "SELECT f((SELECT 1));\n";
my $start = time();
format_sql($sql);
cmp_ok( time() - $start, '<', 5, 'long runs of whitespace do not make the formatting explode' );

# What the redundant parentheses loop does must stay the same.
unlike( format_sql("SELECT ((a)) FROM t;\n"),            qr/\(\(/,       'collapsed in the select list' );
like( format_sql("SELECT count((a)) FROM t;\n"),         qr/count\(a\)/, 'collapsed in a function call' );
like( format_sql("SELECT * FROM t WHERE ((a = 1));\n"),  qr/\(a = 1\)/,  'collapsed in a WHERE clause' );
like( format_sql("SELECT a FROM f(((SELECT 1)));\n"),    qr/\(\(/,       'kept around a scalar subquery' );

done_testing();
