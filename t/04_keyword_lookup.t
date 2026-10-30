use strict;
use warnings;

use Test::More;
use lib 'lib';
use pgFormatter::Beautify;

# Keywords are looked up in a hash built from the keyword list: a keyword added
# after a first call to beautify() must still be recognized.
my $formatter = pgFormatter::Beautify->new( uc_keywords => 2 );

$formatter->query("select myword from t;\n");
$formatter->beautify();
like( $formatter->content(), qr/\bmyword\b/, 'an unknown word is left as it is' );

$formatter->add_keywords('MYWORD');
$formatter->query("select myword from t;\n");
$formatter->beautify();
like( $formatter->content(), qr/\bMYWORD\b/, 'a keyword added after a first run is recognized' );

done_testing();
