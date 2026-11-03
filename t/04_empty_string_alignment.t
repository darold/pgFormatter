use strict;
use warnings;

use Test::More;
use lib 'lib';
use pgFormatter::Beautify;

my $query = <<'SQL';
CREATE TABLE audit_check (
    id integer,
    description text,
    CHECK (description <> '')
);
CREATE TABLE audit_after (
    id integer,
    description text
);
SQL

my $formatter = pgFormatter::Beautify->new(
    query          => $query,
    vertical_align => 1,
);
$formatter->beautify();
my $result = $formatter->content();

like(
    $result,
    qr/    id          integer,\n    description text,/,
    'aligns columns in a table with an empty-string CHECK expression'
);
like(
    $result,
    qr/CREATE TABLE audit_after \(\n    id          integer,\n    description text/,
    'aligns the following table independently'
);
like( $result, qr/CHECK \(description <> ''\)/, 'preserves the empty string' );

done_testing();
