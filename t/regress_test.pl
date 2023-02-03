#!/usr/bin/perl
use strict;

use File::Temp qw/ tempfile /;

my @files = `find t/test-files/ -maxdepth 1 -name '*.sql' | sort`;
chomp(@files);
my $pg_format = $ENV{PG_FORMAT} // './pg_format'; # set to 'pg_format' to test installed binary in /usr/bin
my $exit = 0;

foreach my $f (@files)
{
	next if ( $#ARGV >= 0 and lc($ARGV[0]) ne 'update' and !grep(m#^$f$#, @ARGV) );
	print "Running test on file $f...\n";
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
	if ($f =~ m#/ex61.sql$#)
	{
		my ($fh, $tmpfile) = tempfile('tmp_pgformatXXXX', SUFFIX => '.lst', TMPDIR => 1, O_TEMPORARY => 1, UNLINK => 1 );
		print $fh "fct1\nMyFunction\n";
		close($fh);
		$opt = "--extra-function $tmpfile " if ($f =~ m#/ex61.sql$#);
	}
	my $cmd = "./pg_format $opt -u 2 $f >/tmp/output.sql";
	`$cmd`;
	$f =~ s/test-files\//test-files\/expected\//;
	my @diff = ();
	if (lc($ARGV[0]) eq 'update') {
		`cp -f /tmp/output.sql $f` if ($f !~ m#/ex67.sql$#);
		unlink("/tmp/output.sql");
		next;
	} elsif ($f =~ m#/ex67.sql$#) {
		@diff = `grep "confirmed|hello|'Y'|'N'" /tmp/output.sql`;
	} else { 
		@diff = `diff -u /tmp/output.sql $f | grep "^[+-]" | grep -v "^[+-]\t\$" | grep -v "^[+-][+-][+-]"`;
	}
	if ($#diff < 0) {
		print "\ttest ok.\n";
	} else {
		print "\ttest failed!!!\n";
		print @diff;
		$exit = 1;
	}
	unlink("/tmp/output.sql");
}

@files = `find t/pg-test-files/sql/ -maxdepth 1 -name '*.sql' | sort`;
chomp(@files);

foreach my $f (@files)
{
	next if ( $#ARGV >= 0 and lc($ARGV[0]) ne 'update' and !grep(m#^$f$#, @ARGV) );
	print "Running test on file $f...\n";
	my $opt = '';
	$opt .= ' -t' if (grep(/^-t/, @ARGV));
	my $cmd = "./pg_format $opt -u 2 $f >/tmp/output.sql";
	`$cmd`;
	$f =~ s/\/sql\//\/expected\//;
	if (lc($ARGV[0]) eq 'update') {
		`cp -f /tmp/output.sql $f`;
	} else { 
		my @diff = `diff -u /tmp/output.sql $f | grep "^[+-]" | grep -v "^[+-]\$" | grep -v "^[+-]\t\$" | grep -v "^[+-][+-][+-]"`;
		if ($#diff < 0) {
			print "\ttest ok.\n";
		} else {
			print "\ttest failed!!!\n";
			print @diff;
			$exit = 1;
		}
	}
	unlink("/tmp/output.sql");
}

exit $exit;
