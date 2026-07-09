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
		comment            => '',
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
		comment            => '',
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
		comment            => '',
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
		comment          => '',
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
		comma   => ',',
		comment => '',
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

is_deeply(
	$beautifier->_parse_create_table_column(
		'    username varchar(150) not null unique, -- explanatory comment'
	),
	{
		indent             => '    ',
		name               => 'username',
		declaration_tokens => [ 'varchar', '(', '150', ')' ],
		remainder_tokens   => [ 'not', 'null', 'unique' ],
		comma              => ',',
		comment            => '-- explanatory comment',
	},
	'parses a trailing comment separately from the column SQL'
);

ok(
	!defined $beautifier->_parse_create_table_column(
		'    username text /* explanation */ not null'
	),
	'skips comments embedded in the middle of a definition'
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
	'default gen_random_uuid ()',
	'preserves the default space before an unknown function parenthesis'
);

my $compact_function_renderer =
  pgFormatter::Beautify->new( no_space_function => 1 );

is(
	$compact_function_renderer->_render_sql_tokens(
		[ 'default', 'gen_random_uuid', '(', ')' ]
	),
	'default gen_random_uuid()',
	'removes the space before an unknown function when configured'
);

is(
	$beautifier->_render_sql_tokens( [ 'default', 'lower', '(', 'name', ')' ] ),
	'default lower(name)',
	'keeps PostgreSQL internal functions attached to their parenthesis'
);

is(
	$beautifier->_render_sql_tokens( [ 'my_type', '(', '10', ')' ] ),
	'my_type (10)',
	'preserves spacing for an unknown parameterized type'
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
		'    id            uuid primary key          default gen_random_uuid (),',
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
			'    id serial primary key, -- some comment',
			'    name varchar(100) not null, -- another comment',
			'    email varchar(100) not null, -- third comment',
			'    created_at timestamp with time zone default current_timestamp -- last comment',
		]
	),
	[
		'    id         serial primary key,                                -- some comment',
		'    name       varchar(100)             not null,                 -- another comment',
		'    email      varchar(100)             not null,                 -- third comment',
		'    created_at timestamp with time zone default current_timestamp -- last comment',
	],
	'aligns trailing comments after the complete column SQL'
);

is_deeply(
	$beautifier->_align_create_table_column_group(
		[
			'    id uuid primary key default gen_random_uuid(),',
			'    username varchar(150) not null unique, -- only comment',
			'    email varchar not null unique',
		]
	),
	[
		'    id       uuid primary key default gen_random_uuid (),',
		'    username varchar(150)     not null unique,            -- only comment',
		'    email    varchar          not null unique',
	],
	'aligns a lone trailing comment against the longest supported column'
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

sub format_sql {
	my ( $query, $vertical_align ) = @_;

	my $formatter = pgFormatter::Beautify->new(
		query             => $query,
		vertical_align    => $vertical_align,
		uc_keywords       => 1,
		uc_types          => 1,
		uc_functions      => 1,
		no_space_function => 1,
		no_extra_line     => 1,
	);

	$formatter->beautify();
	return $formatter->content();
}

my $create_table_sql = <<'SQL';
create table queue_job (
    id uuid primary key default gen_random_uuid(),
    parent_job_id uuid references queue_job (id) on delete set null,
    status queue_job_status not null default 'queued',
    created_at timestamptz not null default now()
);
SQL

is(
	format_sql( $create_table_sql, 1 ),
	<<'SQL',
create table queue_job(
    id            uuid primary key          default gen_random_uuid(),
    parent_job_id uuid             references queue_job (id) on delete set null,
    status        queue_job_status not null default 'queued',
    created_at    timestamptz      not null default now()
);
SQL
	'applies vertical alignment through the normal formatter output path'
);

my $commented_table_sql = <<'SQL';
create table example (
    id serial primary key, -- some comment
    name varchar(100) not null, -- another comment
    email varchar(100) not null, -- third comment
    created_at timestamp with time zone default current_timestamp -- last comment
);
SQL

is(
	format_sql( $commented_table_sql, 1 ),
	<<'SQL',
create table example(
    id         serial primary key,                                -- some comment
    name       varchar(100)             not null,                 -- another comment
    email      varchar(100)             not null,                 -- third comment
    created_at timestamp with time zone default current_timestamp -- last comment
);
SQL
	'aligns trailing comments through the normal formatter output path'
);

my $commented_aligned_once = format_sql( $commented_table_sql, 1 );
is(
	$beautifier->_align_create_table_columns($commented_aligned_once),
	$commented_aligned_once,
	'keeps aligned trailing comments stable when alignment runs again'
);

is(
	format_sql( $create_table_sql, 0 ),
	<<'SQL',
create table queue_job(
    id uuid primary key default gen_random_uuid(),
    parent_job_id uuid references queue_job(id) on delete set null,
    status queue_job_status not null default 'queued',
    created_at timestamptz not null default now()
);
SQL
	'leaves normal formatter output unchanged when vertical alignment is disabled'
);

sub format_sql_with_default_function_spacing {
	my ( $query, $vertical_align ) = @_;

	my $formatter = pgFormatter::Beautify->new(
		query          => $query,
		vertical_align => $vertical_align,
		uc_keywords    => 1,
		uc_types       => 1,
		uc_functions   => 1,
		no_extra_line  => 1,
	);

	$formatter->beautify();
	return $formatter->content();
}

my $default_spacing_disabled =
  format_sql_with_default_function_spacing( $create_table_sql, 0 );
my $default_spacing_enabled =
  format_sql_with_default_function_spacing( $create_table_sql, 1 );

like(
	$default_spacing_disabled,
	qr/default gen_random_uuid \(\)/,
	'normal formatting keeps a space before an unknown function parenthesis'
);

like(
	$default_spacing_enabled,
	qr/default gen_random_uuid \(\)/,
	'vertical alignment preserves unknown-function parenthesis spacing'
);

my $separate_parenthesis = <<'SQL';
create table demo
(
    id uuid primary key,
    descriptive_name text
);
SQL

is(
	$beautifier->_align_create_table_columns($separate_parenthesis),
	<<'SQL',
create table demo
(
    id               uuid primary key,
    descriptive_name text
);
SQL
	'detects a CREATE TABLE opening parenthesis on the following line'
);

my $nested_definition = <<'SQL';
CREATE TABLE measurements (
    id uuid primary key,
    score integer check (
        score >= 0
        and score <= 100
    ),
    descriptive_name text
);
SQL

is(
	$beautifier->_align_create_table_columns($nested_definition),
	<<'SQL',
CREATE TABLE measurements (
    id               uuid primary key,
    score integer check (
        score >= 0
        and score <= 100
    ),
    descriptive_name text
);
SQL
	'preserves multiline nested definitions while aligning other top-level columns'
);

my $create_table_as = <<'SQL';
CREATE TABLE completed_jobs AS
SELECT id, status
FROM queue_job;
SQL

is(
	$beautifier->_align_create_table_columns($create_table_as),
	$create_table_as,
	'skips CREATE TABLE AS statements'
);

my $multiple_tables = <<'SQL';
CREATE TABLE first_table (
    id uuid,
    descriptive_name text
);

CREATE TABLE second_table (
    key text,
    considerably_longer_value jsonb
);
SQL

is(
	$beautifier->_align_create_table_columns($multiple_tables),
	<<'SQL',
CREATE TABLE first_table (
    id               uuid,
    descriptive_name text
);

CREATE TABLE second_table (
    key                       text,
    considerably_longer_value jsonb
);
SQL
	'aligns multiple CREATE TABLE statements independently'
);

my $aligned_once =
  $beautifier->_align_create_table_columns($separate_parenthesis);
is(
	$beautifier->_align_create_table_columns($aligned_once),
	$aligned_once,
	'is idempotent when applied more than once'
);

is(
	$beautifier->_parenthesis_delta(
		q{    note text default 'not structural (parenthesis)' -- ignored )}
	),
	0,
	'ignores parentheses contained in strings and comments'
);

done_testing();
