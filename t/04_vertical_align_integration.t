use strict;
use warnings;

BEGIN {
	package JSON;

	sub import {
		my $caller = caller;
		no strict 'refs';
		*{"${caller}::decode_json"} = sub { die "decode_json is not used here" };
		*{"${caller}::encode_json"} = sub { die "encode_json is not used here" };
	}

	$INC{'JSON.pm'} = __FILE__;

	package CGI;

	sub import { }

	$INC{'CGI.pm'} = __FILE__;
}

use Test::More;
use File::Temp qw(tempfile);
use lib 'lib';
use pgFormatter::CGI;


my ( $config_fh, $config_path ) = tempfile();
print {$config_fh} <<'CONFIG';
vertical-align=1
keyword-case=1
type-case=1
function-case=1
no-extra-line=1
CONFIG
close($config_fh);

my ( $sql_fh, $sql_path ) = tempfile( SUFFIX => '.sql' );
print {$sql_fh} <<'SQL';
CREATE TABLE configured_example (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descriptive_name TEXT NOT NULL
);
SQL
close($sql_fh);

open my $formatter_output, '-|',
  $^X, '-Ilib', 'pg_format', '--config', $config_path, $sql_path
  or die "could not run pg_format: $!";

my $configured_output = do {
	local $/;
	<$formatter_output>;
};
close($formatter_output);

is( $?, 0, 'pg_format accepts vertical-align from a configuration file' );

is(
	$configured_output,
	<<'SQL',
create table configured_example (
    id               uuid primary key default gen_random_uuid (),
    descriptive_name text             not null
);
SQL
	'configuration-file vertical alignment reaches the formatter'
);

my $cgi_formatter = pgFormatter::CGI->new();

is(
	$cgi_formatter->{'vertical_align'},
	0,
	'CGI vertical alignment is disabled by default'
);

$cgi_formatter->{'content'} = <<'SQL';
CREATE TABLE example (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descriptive_name TEXT NOT NULL
);
SQL
$cgi_formatter->{'format'}         = 'text';
$cgi_formatter->{'colorize'}       = 0;
$cgi_formatter->{'vertical_align'} = 1;

$cgi_formatter->beautify_query();

is(
	$cgi_formatter->{'content'},
	<<'SQL',
CREATE TABLE example (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid (),
    descriptive_name text             NOT NULL
);

SQL
	'CGI forwards vertical alignment while preserving function spacing'
);

done_testing();
