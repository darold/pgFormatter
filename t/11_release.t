use strict;
use warnings;
use Test::More;
use Archive::Tar;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Path qw(make_path);
use JSON::PP;
use IPC::Open3;
use Symbol qw(gensym);

sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/;
    return <$fh>;
}
sub run {
    my $error = gensym;
    my $pid = open3(undef, my $out, $error, @_);
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$error> // '';
    waitpid($pid, 0);
    return ($?, $stdout, $stderr);
}
my $temporary = tempdir(CLEANUP => 1);
my ($status, $path, $error) = run($^X, 'scripts/build-release.pl', "$temporary/output with spaces");
is($status, 0, 'package builds into a path containing spaces') or diag($error);
chomp $path;
ok(-f $path, 'archive exists');
my $checksum = read_file("$temporary/output with spaces/SHA256SUMS");
like($checksum, qr/^\Q@{[sha256_hex(read_file($path))]}\E  pgFormatter-/, 'published checksum matches archive');
my (undef, $second) = run($^X, 'scripts/build-release.pl', "$temporary/second");
chomp $second;
is(read_file($path), read_file($second), 'archive is reproducible for the same source revision');
my $tar = Archive::Tar->new($path, 1);
my @members = $tar->get_files;
my ($metadata_file) = grep { $_->full_path =~ /\/release\.json$/ } @members;
my $metadata = decode_json($metadata_file->get_content);
like($metadata->{version}, qr/^\d+\.\d+\.\d+-samshull\.\d+$/, 'fork version in metadata');
like($metadata->{revision}, qr/^[a-f0-9]{40}$/, 'full source revision in metadata');
for my $pair (
    ['bin/pg_format', 'pg_format'],
    ['bin/lib/pgFormatter/Beautify.pm', 'lib/pgFormatter/Beautify.pm'],
    ['bin/lib/pgFormatter/CLI.pm', 'lib/pgFormatter/CLI.pm'],
    ['bin/lib/pgFormatter/CGI.pm', 'lib/pgFormatter/CGI.pm'],
    ['LICENSE', 'LICENSE'], ['profiles/readable.conf', 'profiles/readable.conf'],
) {
    my ($file) = grep { $_->full_path eq "pgFormatter-$metadata->{version}/$pair->[0]" } @members;
    ok($file, "$pair->[0] is packaged");
    is($file->get_content, read_file($pair->[1]), "$pair->[0] retains original bytes") if $file;
}
($status, undef, $error) = run($^X, 'scripts/build-release.pl', "$temporary/invalid", 'v0.0.0-samshull.0');
ok($status, 'mismatched release tag is rejected');
like($error, qr/Tag must be/, 'tag failure explains expected version');
open my $bad, '>>:raw', $path or die $!;
print {$bad} 'corrupt'; close $bad;
($status, undef, $error) = run($^X, 'scripts/test-release.pl', $path);
ok($status, 'corrupt download is rejected before execution');
like($error, qr/checksum mismatch/, 'checksum error is explicit');
# Integrity alone does not make an archive safe to extract.
my $unsafe = Archive::Tar->new;
$unsafe->add_data('../escape', 'untrusted');
$unsafe->write($path, 1);
open my $sum, '>', "$temporary/output with spaces/SHA256SUMS" or die $!;
(my $filename = $path) =~ s{.*/}{};
print {$sum} sha256_hex(read_file($path)), "  $filename\n";
close $sum;
($status, undef, $error) = run($^X, 'scripts/test-release.pl', $path);
ok($status, 'unsafe archive is rejected even with a matching checksum');
like($error, qr/Unsafe archive member/, 'unsafe path is reported before extraction');

# Exercise publication guards in a disposable repository, without tagging this checkout.
my $repository = "$temporary/repository";
for my $file (qw(scripts/build-release.pl pg_format LICENSE README .gitignore
    profiles/readable.conf lib/pgFormatter/CLI.pm lib/pgFormatter/Beautify.pm lib/pgFormatter/CGI.pm)) {
    (my $parent = "$repository/$file") =~ s{/[^/]+$}{};
    make_path($parent);
    copy($file, "$repository/$file") or die $!;
}
my @git = ('git', '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false', '-C', $repository);
run(@git, 'init', '--quiet');
run(@git, 'add', '.');
($status, undef, $error) = run(@git, '-c', 'user.name=Release test', '-c', 'user.email=release@example.test',
    'commit', '--quiet', '-m', 'Fixture');
is($status, 0, 'disposable release repository committed') or diag($error);
my $tag = "v$metadata->{version}";
run(@git, 'tag', $tag);
($status, undef, $error) = run($^X, "$repository/scripts/build-release.pl", "$repository/dist", $tag);
is($status, 0, 'clean checkout with matching tag can produce release assets') or diag($error);
open my $dirty, '>>', "$repository/README" or die $!;
print {$dirty} "changed\n"; close $dirty;
($status, undef, $error) = run($^X, "$repository/scripts/build-release.pl", "$repository/dist", $tag);
ok($status, 'dirty tagged source is rejected');
like($error, qr/clean checkout/, 'dirty source cannot claim the tagged revision');
run(@git, 'checkout', '--', 'README');
run(@git, '-c', 'user.name=Release test', '-c', 'user.email=release@example.test',
    'commit', '--quiet', '--allow-empty', '-m', 'New revision');
($status, undef, $error) = run($^X, "$repository/scripts/build-release.pl", "$repository/dist", $tag);
ok($status, 'tag pointing at another commit is rejected');
like($error, qr/tag does not identify HEAD/, 'release revision mismatch is explicit');
done_testing;
