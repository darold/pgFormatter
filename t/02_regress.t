use Test::Simple tests => 58;

my $ret = `perl -I. -wc pg_format 2>&1`;

my @files = `find t/test-files/ -maxdepth 1 -name '*.sql' | sort`;
chomp(@files);
my $pg_format = $ENV{PG_FORMAT} // './pg_format'; # set to 'pg_format' to test installed binary in /usr/bin
my $exit = 0;

foreach my $f (@files)
{
	next if ( $#ARGV >= 0 and lc($ARGV[0]) ne 'update' and !grep(m#^$f$#, @ARGV) );
	my $opt = '';
	$opt = "-S '\$f\$'" if ($f =~ m#/ex19.sql$#);
	$opt = "-W 4" if ($f =~ m#/ex46.sql$#);
	$opt = "--comma-break -U 2" if ($f =~ m#/ex57.sql$#);
	#$opt .= ' -t' if (grep(/^-t/, @ARGV) or $f =~ /float4\.sql/);
	$opt .= ' -t' if (grep(/^-t/, @ARGV));
	$opt = "-T -n " if ($f =~ m#/ex51.sql$#);
	my $cmd = "./pg_format $opt -u 2 $f >/tmp/output.sql";
	`$cmd`;
	$f =~ s/test-files\//test-files\/expected\//;
	if (lc($ARGV[0]) eq 'update') {
		`cp -f /tmp/output.sql $f`;
	} else { 
		my @diff = `diff -u /tmp/output.sql $f | grep "^[+-]" | grep -v "^[+-]\t\$" | grep -v "^[+-][+-][+-]"`;
		ok( $#diff < 0, "Test file $f");
	}
	unlink("/tmp/output.sql");
}

