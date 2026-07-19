use strict;
use warnings;

use Test::More;
use lib 'lib';
use pgFormatter::Beautify;

sub format_sql {
	my ($query) = @_;
	my $formatter = pgFormatter::Beautify->new(
		query          => $query,
		vertical_align => 1,
		uc_keywords    => 1,
		uc_types       => 1,
		uc_functions   => 1,
		no_extra_line  => 1,
	);

	$formatter->beautify();
	return $formatter->content();
}

my $input = <<'SQL';
create table example (
    id uuid primary key default gen_random_uuid(),
    name varchar(100) not null, -- a comment
    owner_id uuid references app_user (id),
    created_at timestamptz not null default now(),
    constraint example_name_unique unique (name)
);
SQL

my $expected = <<'SQL';
create table example (
    id         uuid primary key          default gen_random_uuid (),
    name       varchar(100)     not null,                            -- a comment
    owner_id   uuid             references app_user (id),
    created_at timestamptz      not null default now(),
    constraint example_name_unique unique (name)
);
SQL

is(
	format_sql($input),
	$expected,
	'aligns columns, defaults, references, and comments'
);

my $unsupported = <<'SQL';
CREATE TABLE measurements (
    id uuid primary key,
    score integer check (
        score >= 0
        and score <= 100
    ),
    descriptive_name text
);

CREATE TABLE copied AS
SELECT id FROM measurements;
SQL

my $beautifier = pgFormatter::Beautify->new();
my $result = $beautifier->_align_create_table_columns($unsupported);

like(
	$result,
	qr/score integer check \(\n        score >= 0\n        and score <= 100\n    \),/,
	'preserves multiline definitions'
);

like(
	$result,
	qr/CREATE TABLE copied AS\nSELECT id FROM measurements;/,
	'skips CREATE TABLE AS'
);

my $aligned = format_sql($input);
is(
	$beautifier->_align_create_table_columns($aligned),
	$aligned,
	'is idempotent'
);

done_testing();
