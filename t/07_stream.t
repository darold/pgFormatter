use strict;
use warnings;
use Test::More;
use IPC::Open2;
use IO::Handle;

# Interactive mode: when the first non empty line of the input is STARTSTREAM
# each block of SQL code ended by a ENDSTREAM line is formatted and written,
# followed by an ENDSTREAM line, without waiting for the end of the input.

my $pg_format = $ENV{PG_FORMAT} // './pg_format';

# Read the output of pg_format up to the next ENDSTREAM line, fail after a
# timeout instead of hanging if the output is not flushed.
sub read_block {
	my $fh  = shift;
	my $out = '';
	eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm(10);
		while ( my $l = <$fh> ) {
			last if ( $l eq "ENDSTREAM\n" );
			$out .= $l;
		}
		alarm(0);
	};
	return $@ ? "TIMEOUT: $out" : $out;
}

# Formatted output of a query in normal mode
sub batch {
	my ( $opt, $sql ) = @_;
	my $pid = open2( my $out, my $in, "$pg_format $opt -" );
	print $in $sql;
	close($in);
	local $/;
	my $res = <$out>;
	waitpid( $pid, 0 );
	return $res;
}

my @blocks = (
	"select a, b from t where c = 'x';\n",
	"-- a comment\n\nselect 1; select 2;\n",
	"create function f() returns int as \$\$ begin return 1; end \$\$ language plpgsql;\n",
);

my $opt = '-X -u 2 -s 2';
my $pid = open2( my $out, my $in, "$pg_format $opt -" );
$in->autoflush(1);
print $in "\nSTARTSTREAM\n";
foreach my $b (@blocks) {

	# The input is not closed: the block must be written as soon as
	# ENDSTREAM is read.
	print $in $b, "ENDSTREAM\n";
	is( read_block($out), batch( $opt, $b ),
		"block formatted before the end of the input: $b" );
}

# An empty block only gives the ENDSTREAM line
print $in "\nENDSTREAM\n";
is( read_block($out), '', 'empty block' );

# A block not ended by ENDSTREAM is formatted at the end of the input
print $in "update t set a = 1\n";
close($in);
is( read_block($out), batch( $opt, "update t set a = 1\n" ),
	'last block formatted at the end of the input' );
{
	local $/;
	my $rest = <$out>;
	is( $rest // '', '', 'nothing after the last block' );
}
waitpid( $pid, 0 );
is( $? >> 8, 0, 'exit code' );

# Each block is formatted independently: the statement numbering starts at 1
$pid = open2( $out, $in, "$pg_format -X -N -" );
$in->autoflush(1);
print $in "STARTSTREAM\nselect 1;\nselect 2;\nENDSTREAM\nselect 3;\nENDSTREAM\n";
like( read_block($out), qr/Statement # 1.*Statement # 2/s, 'numbering of the first block' );
like( read_block($out), qr/Statement # 1\n/, 'numbering restarts with the next block' );
close($in);
waitpid( $pid, 0 );

# Without STARTSTREAM as first non empty line nothing changes, the words
# are formatted as SQL code like before.
is( batch( '-X', "select 1;\nENDSTREAM\nSTARTSTREAM\n" ),
	"SELECT\n    1;\n\nENDSTREAM STARTSTREAM\n",
	'normal mode when the input does not start with STARTSTREAM' );

# The inplace option can not be used in interactive mode
my $tmp = "/tmp/pg_format_stream_$$.sql";
open( my $fh, '>', $tmp ) or die "$tmp: $!";
print $fh "STARTSTREAM\nselect 1;\nENDSTREAM\n";
close($fh);
my $ret = `$pg_format -X -i $tmp 2>&1`;
isnt( $? >> 8, 0, 'error with the inplace option' );
like( $ret, qr/can not use -i \| --inplace option with the STARTSTREAM/, 'error message' );
unlink($tmp);

done_testing();
