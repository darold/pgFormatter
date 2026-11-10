use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
use pgFormatter::Beautify;

sub format_sql {
  my ($sql, %extra) = @_;
  my $formatter = pgFormatter::Beautify->new(
    spaces => 2, uc_keywords => 2, no_extra_line => 1,
    no_space_function => 1, redundant_parenthesis => 1,
    max_line_length => 100, multiline_json => 1, %extra,
  );
  $formatter->query($sql);
  $formatter->beautify();
  my $result = $formatter->content();
  is($formatter->content(), $result, 'reading content twice is stable');
  return $result;
}
sub sql_quote { my $s = shift; $s =~ s/'/''/g; return "'$s'"; }
sub payload {
  my ($sql) = @_;
  return $2 if $sql =~ /(\$json(?:_\d+)?\$)(.*?)\1/s;
  return;
}
my $raw = '{"b":9007199254740993,"a":1e+003,"b":-0.0,"pattern":"\\\\S","quote":"O\'Reilly","required":["id","label","value"]}';
my $source = 'select ' . sql_quote($raw) . ' ::jsonb;';
my $formatted = format_sql($source);
like($formatted, qr/\$json\$\n.*\n.*\$json\$::jsonb/s, 'long explicitly cast JSON becomes multiline dollar quoting');
like($formatted, qr/"b": 9007199254740993,\n.*"a": 1e\+003,\n.*"b": -0\.0/s, 'property order, duplicate keys and numeric spellings are retained');
like($formatted, qr/"pattern": "\\\\S"/, 'JSON escape spelling is retained');
like($formatted, qr/"quote": "O'Reilly"/, 'SQL doubled quotes are decoded before dollar quoting');
my $parser = JSON::PP->new->allow_nonref->allow_bignum;
is_deeply($parser->decode(payload($formatted)), $parser->decode($raw), 'JSON values are unchanged');
is(format_sql($formatted), $formatted, 'JSON formatting is idempotent');

my $long = '{"text":"' . ('x' x 120) . '"}';
for my $type ('json', 'jsonb', 'JSONB', 'pg_catalog.jsonb') {
  like(format_sql('select ' . sql_quote($long) . "::$type;"), qr/\$json\$/, "explicit $type cast qualifies");
}
my @unchanged = (
  ['short JSON', q{select '{"a":1}'::jsonb;}, q{'{"a":1}'}],
  ['uncast JSON', 'select ' . sql_quote($long) . ';', sql_quote($long)],
  ['text cast', 'select ' . sql_quote($long) . '::text;', sql_quote($long)],
  ['array cast', 'select ' . sql_quote($long) . '::jsonb[];', sql_quote($long)],
  ['similar type name', 'select ' . sql_quote($long) . '::jsonb_custom;', sql_quote($long)],
  ['invalid JSON', 'select ' . sql_quote('{"text":"' . ('x' x 120) . '",}') . '::jsonb;', sql_quote('{"text":"' . ('x' x 120) . '",}')],
  ['escape string', 'select E' . sql_quote($long) . '::jsonb;', 'E' . sql_quote($long)],
  ['Unicode string', 'select U&' . sql_quote($long) . '::jsonb;', 'U&' . sql_quote($long)],
);
for my $case (@unchanged) {
  my ($name, $sql, $literal) = @$case;
  my $result = format_sql($sql);
  ok(index($result, $literal) >= 0, "$name remains verbatim");
  unlike($result, qr/\$json(?:_\d+)?\$/, "$name does not get dollar quoting");
}
for my $options ({multiline_json => 0}, {max_line_length => 0}, {backslash_escape => 1}) {
  my $result = format_sql($source, %$options);
  ok(index($result, sql_quote($raw)) >= 0, 'disabled JSON formatting or disabled width preserves the literal');
}
like(format_sql(q{select '{"description":"a moderately sized value"}'::jsonb;}, max_line_length => 40), qr/\$json\$/, 'width is configurable');
my $adjacent = "select '  '\n" . sql_quote($long) . '::jsonb;';
my $adjacent_result = format_sql($adjacent);
unlike($adjacent_result, qr/\$json(?:_\d+)?\$/, 'adjacent SQL string segments are not converted independently');
ok(index($adjacent_result, sql_quote($long)) >= 0, 'adjacent JSON string segment stays verbatim');
my $colliding = '{"text":"' . ('x' x 100) . '$json$ $json_1$"}';
my $collision_result = format_sql('select ' . sql_quote($colliding) . '::jsonb;');
like($collision_result, qr/\$json_2\$/, 'new tag avoids delimiters inside JSON values');
is_deeply($parser->decode(payload($collision_result)), $parser->decode($colliding), 'colliding payload preserved');
my $body = 'create function example() returns jsonb language plpgsql as $json$ begin return ' . sql_quote($long) . '; end; $json$;';
# Add the explicit cast inside the function body, not to its definition.
$body =~ s/; end;/::jsonb; end;/;
my $body_result = format_sql($body);
like($body_result, qr/RETURN \$json_1\$/i, 'new JSON tag avoids its enclosing function body delimiter');
is(format_sql($body_result), $body_result, 'enclosing-tag collision is idempotent');
my $existing = 'select $schema$' . $long . '$schema$::jsonb;';
my $existing_result = format_sql($existing);
like($existing_result, qr/\$schema\$\n/, 'existing dollar tag is retained');
is(format_sql($existing_result), $existing_result, 'existing tagged JSON is idempotent');
my $protected_result = format_sql($source, placeholder => "'[^']*(?:''[^']*)*'\\s*::jsonb");
ok(index($protected_result, sql_quote($raw)) >= 0, 'configured placeholder prevents JSON conversion');
my $annotation = '-- @signature: sample_function(' . join(',', ('uuid') x 25) . ')';
my $preserved_comment = format_sql($annotation . "\nselect 1;", placeholder => '(?m:^-- @signature: [^\n]*$)');
ok(index($preserved_comment, $annotation) == 0, 'configured annotation remains a single line despite the width limit');
done_testing();
