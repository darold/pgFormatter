my @files = `find samples/ -maxdepth 1 -name '*.sql' | sort`;
chomp(@files);

foreach my $f (@files) {
	print "Running test on file $f...\n";
	my $cmd = "./pg_format $f >/tmp/output.sql";
	`$cmd`;
	$f =~ s/\//\/expected\//;
	if (lc($ARGV[0]) eq 'update') {
		`cp -f /tmp/output.sql $f`;
	} else { 
		my @diff = `diff -u /tmp/output.sql $f | grep "^[+-]" | grep -v "^[+-]\$" | grep -v "^[+-]\t\$" | grep -v "^[+-][+-][+-]"`;
		if ($#diff < 0) {
			print "\ttest ok.\n";
		} else {
			print "\ttest failed!!!\n";
			print @diff;
		}
	}
	unlink("/tmp/output.sql");
}


