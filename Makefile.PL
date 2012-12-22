use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;

my @ALLOWED_ARGS = ('INSTALLDIRS','DESTDIR');

# Parse command line arguments and store them as environment variables
while ($_ = shift) {
	my ($k,$v) = split(/=/, $_, 2);
	if (grep(/^$k$/, @ALLOWED_ARGS)) {
		$ENV{$k} = $v;
	}
}
$ENV{DESTDIR} =~ s/\/$//;

# Default install path
my $DESTDIR = $ENV{DESTDIR} || '';
my $INSTALLDIRS = $ENV{INSTALLDIRS} || 'site';

WriteMakefile(
	'DISTNAME'	=> 'pgformatter',
	'NAME'		=> 'pgFormatter',
	'VERSION_FROM'	=> 'pg_format',
	'dist'  => {
			'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
			'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'
		   },
	'AUTHOR'       => 'Gilles Darold (gilles@darold.net)',
	'ABSTRACT'     => 'pgFormatter - PostgreSQL SQL and PL/PGSQL syntaxe beautifier',
	'EXE_FILES'    => [ qw(pg_format) ],
	'MAN1PODS'     => { 'doc/pg_format.pod' => 'blib/man1/pg_format.1' },
	'DESTDIR'      => $DESTDIR,
	'INSTALLDIRS'  => $INSTALLDIRS,
	'clean'	       => {},
	'META_MERGE'   => {
		resources  => {
			homepage => 'http://sqlformat.darold.net/',
			repository  => {
				type => 'git',
				git => 'git@github.com:darold/pgformatter.git',
				web => 'https://github.com/darold/pgformatter',
			},
		},
        }
);

