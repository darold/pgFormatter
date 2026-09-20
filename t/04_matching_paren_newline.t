use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use lib 'lib';
use pgFormatter::Beautify;

sub format_sql {
    my ($query, %options) = @_;
    my $formatter = pgFormatter::Beautify->new(
        no_extra_line => 1, separator => "'", %options
    );
    $formatter->query($query);
    $formatter->beautify();
    return $formatter->content();
}

my $insert = 'INSERT INTO widgets (id, label) SELECT 1, 2;';
my $baseline = format_sql($insert, comma_break => 1);
like($baseline, qr/    label\)/, 'default retains closing parenthesis beside last column');
is(format_sql($insert, comma_break => 1, matching_paren_newline => 0),
    $baseline, 'explicit false preserves default output');
my $expanded = format_sql($insert, comma_break => 1, matching_paren_newline => 1);
like($expanded, qr/INSERT INTO widgets \(\n    id,\n    label\n\)/,
    'expanded INSERT columns close at the opening line indentation');
is(format_sql($insert, matching_paren_newline => 1), format_sql($insert),
    'inline opening content does not trigger a closing newline');

my $nested = <<'SQL';
SELECT id FROM widgets WHERE id IN (
  SELECT widget_id FROM archive WHERE label IN (
    SELECT "odd)name" FROM labels WHERE label = 'literal (
)' /* ignored ) ( */
  )
);
SQL
my $formatted = format_sql($nested, matching_paren_newline => 1);
like($formatted, qr/\n            \)\n    \);/, 'nested pairs close independently');
like($formatted, qr/"odd\)name"/, 'quoted identifier does not affect the parenthesis stack');
like($formatted, qr/'literal \(\n\)'/, 'multiline literal remains unchanged');
like($formatted, qr{/\* ignored \) \( \*/}, 'comment parentheses remain unchanged');

my $block = <<'SQL';
DO $$ BEGIN
IF (SELECT count(*) FROM widgets) = 0 THEN
EXECUTE $sql$SELECT '(' AS "odd)name", ')';$sql$;
ELSE PERFORM 2;
END IF;
END $$;
SQL
$formatted = format_sql($block, matching_paren_newline => 1);
like($formatted, qr/\n    \) = 0 THEN\n        EXECUTE/, 'condition closing line preserves THEN and body indentation');
my $dynamic = q{$sql$SELECT '(' AS "odd)name", ')';$sql$};
like($formatted, qr/\Q$dynamic\E/, 'dollar-quoted dynamic SQL remains unchanged');

for my $options (
    { spaces => 2 }, { spaces => 1, space => "\t" },
    { wrap_after => 2 }, { compact_clause_body => 1 }
) {
    my $first = format_sql($nested, matching_paren_newline => 1, %$options);
    is(format_sql($first, matching_paren_newline => 1, %$options), $first,
        'stable when combined with ' . join(', ', sort keys %$options));
}
my $tabs = format_sql($block, matching_paren_newline => 1, spaces => 1, space => "\t");
like($tabs, qr/\n\t\) = 0 THEN/, 'closing line uses tabs when configured');

my ($fh, $file) = tempfile(UNLINK => 1);
print $fh $insert;
close $fh;
my $cli = $ENV{PG_FORMAT} // './pg_format';
my $output = `$cli -X -L -B --matching-paren-newline $file`;
is($?, 0, 'CLI accepts the option');
is($output, $expanded, 'CLI option reaches the formatter');
$output = `$cli -X -L -B --no-matching-paren-newline $file`;
is($?, 0, 'CLI accepts the negated option');
is($output, $baseline, 'negated CLI option restores default output');

done_testing();
