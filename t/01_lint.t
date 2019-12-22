use Test::Simple tests => 2;

my $ret = `perl -I. -wc pg_format 2>&1`;
ok( $? == 0, "PERL syntax check");

$ret = `podchecker doc/*.pod 2>&1`;
ok( $? == 0, "pod syntax check");

