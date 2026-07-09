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

is(
	$beautifier->_render_sql_tokens( [qw(uuid primary key)] ),
	'uuid primary key',
	'renders a simple declaration'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'numeric', '(', '10', ',', '2', ')' ]
	),
	'numeric(10, 2)',
	'renders a parameterized type'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'public.custom_type', '[', ']' ]
	),
	'public.custom_type[]',
	'renders an array type'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'default', 'gen_random_uuid', '(', ')' ]
	),
	'default gen_random_uuid()',
	'renders an extension function without a space before its parenthesis'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'references', 'app_user', '(', 'id', ')', 'on', 'delete', 'set', 'null' ]
	),
	'references app_user (id) on delete set null',
	'keeps a space before a referenced column list'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'not', 'null', 'default', q{'{}'}, '::jsonb' ]
	),
	q{not null default '{}'::jsonb},
	'renders a cast without surrounding spaces'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'check', '(', 'score', '>=', '0', ')' ]
	),
	'check (score >= 0)',
	'keeps a space after CHECK before a parenthesis'
);

is(
	$beautifier->_render_sql_tokens(
		[ 'generated', 'always', 'as', '(', 'lower', '(', 'name', ')', ')', 'stored' ]
	),
	'generated always as (lower(name)) stored',
	'renders nested generated-column expressions'
);

is(
	$beautifier->_render_sql_tokens([]),
	'',
	'renders an empty token list as an empty string'
);

is(
	$beautifier->_pad_right( 'id', 5 ),
	'id   ',
	'pads a value to the requested width'
);

is(
	$beautifier->_pad_right( 'identifier', 5 ),
	'identifier',
	'does not truncate a value wider than the requested width'
);

is_deeply(
	$beautifier->_align_create_table_column_group(
		[
			'    id uuid primary key default gen_random_uuid(),',
			'    parent_job_id uuid references queue_job (id) on delete set null,',
			'    type queue_job_type not null,',
			q{    status queue_job_status not null default 'queued',},
			'    created_at timestamptz not null default now()',
		]
	),
	[
		'    id            uuid primary key          default gen_random_uuid(),',
		'    parent_job_id uuid             references queue_job (id) on delete set null,',
		'    type          queue_job_type   not null,',
		q{    status        queue_job_status not null default 'queued',},
		'    created_at    timestamptz      not null default now()',
	],
	'aligns column names and the beginning of column constraints'
);

is_deeply(
	$beautifier->_align_create_table_column_group(
		[
			'    id uuid primary key,',
			'    constraint demo_pk primary key (id)',
			'    descriptive_name text',
		]
	),
	[
		'    id               uuid primary key,',
		'    constraint demo_pk primary key (id)',
		'    descriptive_name text',
	],
	'preserves unsupported table constraints while aligning column definitions'
);

is_deeply(
	$beautifier->_align_create_table_column_group(
		[
			'    first_value text default current_user,',
			'    second_value text not null default current_user,',
			'    third_value text references app_user (username)',
		]
	),
	[
		'    first_value  text          default current_user,',
		'    second_value text not null default current_user,',
		'    third_value  text references app_user (username)',
	],
	'aligns DEFAULT without moving unrelated constraints'
);

is_deeply(
	$beautifier->_align_create_table_column_group(
		[
			'    first_value text default current_user,',
			'    second_value text references app_user (username)',
		]
	),
	[
		'    first_value  text default current_user,',
		'    second_value text references app_user (username)',
	],
	'does not add padding when only one row contains DEFAULT'
);

my @single_column = ('    id uuid primary key');
my $single_result =
  $beautifier->_align_create_table_column_group(\@single_column);

is_deeply(
	$single_result,
	\@single_column,
	'leaves a single column unchanged'
);

isnt(
	$single_result,
	\@single_column,
	'returns a new array reference for a single column'
);

is_deeply(
	$beautifier->_align_create_table_column_group([]),
	[],
	'handles an empty group'
);

done_testing();
