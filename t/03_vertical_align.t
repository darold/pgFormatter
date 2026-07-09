use strict;
use warnings;

use Test::More;
use lib 'lib';
use pgFormatter::Beautify;

my $beautifier = pgFormatter::Beautify->new();

is_deeply(
	$beautifier->_parse_create_table_column(
		'    id uuid primary key default gen_random_uuid(),'
	),
	{
		indent             => '    ',
		name               => 'id',
		declaration_tokens => [qw(uuid primary key)],
		remainder_tokens   => [ 'default', 'gen_random_uuid', '(', ')' ],
		comma              => ',',
	},
	'parses PRIMARY KEY and DEFAULT separately'
);

is_deeply(
	$beautifier->_parse_create_table_column(
		q{    payload jsonb not null default '{}'::jsonb,}
	),
	{
		indent             => '    ',
		name               => 'payload',
		declaration_tokens => ['jsonb'],
		remainder_tokens   => [ 'not', 'null', 'default', q{'{}'}, '::jsonb' ],
		comma              => ',',
	},
	'parses multiple column constraints'
);

is_deeply(
	$beautifier->_parse_create_table_column(
		'    amount numeric(10, 2),'
	),
	{
		indent             => '    ',
		name               => 'amount',
		declaration_tokens => [ 'numeric', '(', '10', ',', '2', ')' ],
		remainder_tokens   => [],
		comma              => ',',
	},
	'keeps type modifiers inside the declaration'
);

is_deeply(
	$beautifier->_parse_create_table_column(
		'    "quoted column" public.custom_type[] unique'
	),
	{
		indent             => '    ',
		name               => '"quoted column"',
		declaration_tokens =>
		  [ 'public.custom_type', '[', ']', 'unique' ],
		remainder_tokens => [],
		comma            => '',
	},
	'parses quoted names, qualified custom types, arrays, and UNIQUE'
);

is_deeply(
	$beautifier->_parse_create_table_column(
		'    owner_id uuid references app_user (id) on delete set null,'
	),
	{
		indent             => '    ',
		name               => 'owner_id',
		declaration_tokens => ['uuid'],
		remainder_tokens   =>
		  [ 'references', 'app_user', '(', 'id', ')', 'on', 'delete', 'set', 'null' ],
		comma => ',',
	},
	'parses a REFERENCES constraint'
);

for my $table_constraint (
	'constraint demo_pk primary key (id)',
	'primary key (id)',
	'foreign key (owner_id) references app_user (id)',
	'unique (correlation_key)',
	'check (id is not null)',
  )
{
	ok(
		!defined $beautifier->_parse_create_table_column($table_constraint),
		"skips table constraint: $table_constraint"
	);
}

ok(
	!defined $beautifier->_parse_create_table_column(
		"    score integer check (\n        score >= 0\n    )"
	),
	'skips multiline definitions in the first implementation'
);

ok(
	!defined $beautifier->_parse_create_table_column(
		'    username text -- explanatory comment'
	),
	'skips definitions containing comments in the first implementation'
);

done_testing();
