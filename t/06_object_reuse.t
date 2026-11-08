use strict;
use warnings;
use Test::More;

use lib 'lib';
use pgFormatter::Beautify;

# Formatting several queries with the same object must give the same result
# as formatting each query with a new object: the values hidden behind the
# placeholders of a query must not be used for the next one.
my @queries = (
	"create function a(cstring) returns x language internal as 'int4in';",
	"create function b(x) returns cstring language internal as 'int4out';",
	"select 'v1', 'v2' as \"Alias\", \"it's\" from t where c = 'x y';",
	"select 'w' as \"Other\" from u;",
	"select format(\$f\$ %I \$f\$, 'a'), x from t;",
	"select format(\$f\$ %L \$f\$, 'b'), y from t;",
	"COMMENT ON TABLE t IS 'first comment';",
	"COMMENT ON TABLE u IS 'second comment';",
	"do \$\$ begin execute 'select 1'; end \$\$;",
	"do \$\$ begin execute 'select 2'; end \$\$;",
);

my $reused = pgFormatter::Beautify->new();
foreach my $q (@queries) {
	my $new = pgFormatter::Beautify->new();
	$new->query($q);
	$new->beautify();
	my $expected = $new->content();

	$reused->query($q);
	$reused->beautify();
	is( $reused->content(), $expected, "same object: $q" );
}

done_testing();
