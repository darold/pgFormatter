use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Temp qw(tempfile);
use IPC::Open3;
use Symbol qw(gensym);

my $pg_format = $ENV{PG_FORMAT} // './pg_format';
my $config = 'profiles/readable.conf';
sub read_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "$path: $!";
  local $/;
  return <$fh>;
}
sub format_sql {
  my ($sql, @options) = @_;
  my ($fh, $path) = tempfile(UNLINK => 1);
  print $fh $sql;
  close $fh;
  my $error = gensym;
  my $pid = open3(undef, my $out, $error, $pg_format, '--config', $config, @options, $path);
  local $/;
  my $result = <$out>;
  my $stderr = <$error>;
  waitpid($pid, 0);
  die "Formatter failed: $stderr" if $?;
  return $result;
}
# Compare actual string tokens, including escaped E-strings, rather than
# matching quotes across comments or executable dollar bodies.
sub literals {
  my ($sql) = @_;
  return [grep {
    /^(?:[Ee])?'/ || /^(\$(?:[A-Za-z_]\w*)?\$).*?\1$/s || /^JSON-VALUE:/
  } @{preservation_tokens($sql)}];
}
# A small independent lexer for this corpus. Whitespace between tokens and
# keyword case may change; operators, identifiers, comments, literals and token
# order may not. Recurse into executable dollar bodies, keeping data opaque.
sub sql_tokens {
  my ($sql) = @_;
  my @tokens;
  pos($sql) = 0;
  while (pos($sql) < length($sql)) {
    next if $sql =~ /\G\s+/gc;
    if ($sql =~ /\G(--[^\n]*|\/\*.*?\*\/)/gcs) {
      push @tokens, $1;
    }
    elsif ($sql =~ /\G([Ee]'(?:[^'\\]|\\.|'')*'|'(?:[^']|'')*'|"(?:[^"]|"")*")/gcs) {
      push @tokens, $1;
    }
    elsif ($sql =~ /\G(\$(?:[A-Za-z_]\w*)?\$)/gc) {
      my $delimiter = $1;
      my $start = pos($sql);
      my $end = index($sql, $delimiter, $start);
      die "Unclosed dollar quote in fixture" if $end < 0;
      my $body = substr($sql, $start, $end - $start);
      my @code = grep { !m{^(?:--|/\*)} } @tokens;
      my $prefix = join(' ', @code);
      if ($prefix =~ /(?:\bas|\bdo(?: language \w+)?)$/) {
        push @tokens, $delimiter, @{sql_tokens($body)}, $delimiter;
      }
      else {
        push @tokens, $delimiter . $body . $delimiter;
      }
      pos($sql) = $end + length($delimiter);
    }
    elsif ($sql =~ /\G([A-Za-z_][A-Za-z_0-9\$]*)/gc) {
      push @tokens, lc($1);
    }
    elsif ($sql =~ /\G((?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?|[~!@#%\^&|`?+*\/<>=:\-]+|.)/gcs) {
      push @tokens, $1;
    }
    else {
      die "Cannot tokenize fixture at " . pos($sql);
    }
  }
  return \@tokens;
}
# Only explicitly cast builtin JSON data may change representation. Compare
# decoded JSON values there, while all other SQL literals remain byte exact.
sub preservation_tokens {
  my ($sql) = @_;
  my @tokens = @{sql_tokens($sql)};
  for my $i (0 .. $#tokens - 2) {
    next unless $tokens[$i + 1] eq '::';
    my $type = $i + 2;
    $type += 2 if $tokens[$type] eq 'pg_catalog' && ($tokens[$type + 1] // '') eq '.';
    next unless ($tokens[$type] // '') =~ /^jsonb?$/ && ($tokens[$type + 1] // '') ne '[';
    my $json;
    if ($tokens[$i] =~ /^'(.*)'$/s) { $json = $1; $json =~ s/''/'/g; }
    elsif ($tokens[$i] =~ /^(\$(?:[A-Za-z_]\w*)?\$)(.*?)\1$/s) { $json = $2; }
    next if !defined $json;
    my $parser = JSON::PP->new->allow_nonref->allow_bignum->canonical;
    my $normalized = eval { $parser->encode($parser->decode($json)) };
    $tokens[$i] = 'JSON-VALUE:' . $normalized if defined $normalized && !$@;
  }
  return \@tokens;
}

# Guard against turning the preservation check into whitespace stripping.
isnt(join('|', @{sql_tokens("select 'a b';")}),
     join('|', @{sql_tokens("select 'ab';")}), 'lexer retains literal whitespace');
isnt(join('|', @{sql_tokens('select a <= b;')}),
     join('|', @{sql_tokens('select a < = b;')}), 'lexer retains operator boundaries');

subtest 'complex function layout can be disabled explicitly' => sub {
  my $source = "select coalesce(nullif(name, ''), 'fallback');";
  my $expanded = format_sql($source);
  my $compact = format_sql($source, '--no-multiline-functions');
  like($expanded, qr/coalesce\(\n/, 'configuration enables complex call layout');
  like($compact, qr/coalesce\(nullif\(name, ''\), 'fallback'\)/, 'CLI overrides configuration');
  is_deeply(sql_tokens($expanded), sql_tokens($compact), 'both layouts keep the same SQL tokens');
};

for my $path (sort glob 't/formatting/input/*.sql') {
  subtest $path => sub {
    my $source = read_file($path);
    my $formatted = format_sql($source);
    (my $expected = $path) =~ s{/input/}{/expected/};
    is($formatted, read_file($expected), 'focused regression output') if -f $expected;
    is(format_sql($formatted), $formatted, 'second pass makes no changes');
    is_deeply(literals($formatted), literals($source), 'literal values preserved; JSON representation may change');
    my $before_tokens = preservation_tokens($source);
    my $after_tokens = preservation_tokens($formatted);
    my @before_code = grep { !m{^(?:--|/\*)} } @$before_tokens;
    my @after_code = grep { !m{^(?:--|/\*)} } @$after_tokens;
    is_deeply(\@after_code, \@before_code, 'SQL tokens and executable body tokens preserved');
    my @comments;
    for my $tokens ($before_tokens, $after_tokens) {
      my @text = grep { m{^(?:--|/\*)} } @$tokens;
      s{^(?:--|/\*)\s*|\s*\*/$}{}g for @text;
      push @comments, join(' ', map { split /\s+/ } @text);
    }
    is($comments[1], $comments[0], 'comment text and order preserved when wrapping');
    if ($path =~ /line-width/) {
      my $number = 0;
      for my $line (split /\n/, $formatted) {
        $number++;
        next if $line =~ /(?:'This literal|E'An escaped|\$message\$)/;
        cmp_ok(length($line), '<=', 100, "code line $number respects width");
      }
      like($formatted, qr/IF NOT found\n    OR r\.updated/, 'long IF uses aligned predicates');
      like($formatted, qr/\n  THEN\n/, 'THEN aligns with IF');
    }
    if ($path =~ /dollar-literals/) {
      ok(index($formatted, '$$line one' . "\n" . 'line two$$') >= 0, 'untagged multiline literal preserved');
      like($formatted, qr/begin\n\s+perform/i, 'DO body remains formatable');
    }

  };
}
done_testing();
