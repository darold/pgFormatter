use Test::Simple tests => 74;
use File::Temp qw/ tempfile /;

my $pg_format = $ENV{PG_FORMAT} // './pg_format'; # set to the full path to 'pg_format' to test installed binary in /usr/bin

my $ret = `perl -I. -wc $pg_format 2>&1`;
ok( $? == 0, "$pg_format compiles OK" ) or exit $?;

my @files = `find t/test-files/ -maxdepth 1 -name '*.sql' | sort`;
chomp(@files);
my $exit = 0;

foreach my $f (@files)
{
	next if ( $#ARGV >= 0 and lc($ARGV[0]) ne 'update' and !grep(m#^$f$#, @ARGV) );
	my $opt = '';
	$opt = "-S '\$f\$'" if ($f =~ m#/ex19.sql$#);
	$opt = "-W 4" if ($f =~ m#/ex46.sql$#);
	$opt .= ' -t' if (grep(/^-t/, @ARGV));
	$opt = "-T -n " if ($f =~ m#/ex51.sql$#);
	$opt = "-k " if ($f =~ m#/ex64.sql$#);
	$opt = "-f 2 -u 2 -U 2 " if ($f =~ m#/ex60.sql$#);
	$opt = "--comma-break -U 2" if ($f =~ m#/ex57.sql$#);
	$opt = "--anonymize" if ($f =~ m#/ex67.sql$#);
	$opt = "--nocomment" if ($f =~ m#/ex68.sql$#);
	$opt = "--extra-keyword t/redshift.kw " if ($f =~ m#/ex69.sql$#);
	$opt = "-w 60 -C -p 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'" if ($f =~ m#/ex62.sql$#);
	$opt = "--keyword-case 2 --function-case 1 --comma-start --wrap-after 1 --wrap-limit 40 --tabs --spaces 4 " if ($f =~ m#/ex58.sql$#);
	$opt = "--no-space-function" if ($f =~ m#/ex70.sql$#);
	$opt = "--keyword-case 1 --type-case 1" if ($f =~ m#/ex71.sql$#);
	if ($f =~ m#/ex61.sql$#)
	{
		my ($fh, $tmpfile) = tempfile('tmp_pgformatXXXX', SUFFIX => '.lst', TMPDIR => 1, O_TEMPORARY => 1, UNLINK => 1 );
		print $fh "fct1\nMyFunction\n";
		close($fh);
		$opt = "--extra-function $tmpfile " if ($f =~ m#/ex61.sql$#);
	}
	my $cmd = "$pg_format $opt -u 2 -X $f >/tmp/output.sql";
	`$cmd`;
	$f =~ s/test-files\//test-files\/expected\//;
	if (lc($ARGV[0]) eq 'update') {
		`cp -f /tmp/output.sql $f`;
	} elsif ($f =~ m#/ex67.sql$#) {
		my @ret = `grep "confirmed|hello|'Y'|'N'" /tmp/output.sql`;
		ok( $#ret < 0, "Test anonymize");
	} else { 
		my @diff = `diff -u /tmp/output.sql $f | grep "^[+-]" | grep -v "^[+-]\t\$" | grep -v "^[+-][+-][+-]"`;
		ok( $#diff < 0, "Test file $f");
	}
	unlink("/tmp/output.sql");
}

