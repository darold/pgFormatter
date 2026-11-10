#!/usr/bin/env perl
use strict;
use warnings;
use Archive::Tar;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IO::Compress::Gzip qw(gzip $GzipError);
use JSON::PP;
use Cwd qw(abs_path);

my $root = abs_path("$FindBin::Bin/..");
my $output = File::Spec->rel2abs(shift(@ARGV) // "$root/dist");
my $tag = shift @ARGV;
die "Usage: build-release.pl [output-directory [release-tag]]\n" if @ARGV;
sub capture {
    open my $fh, '-|', @_ or die "Cannot run $_[0]: $!";
    local $/;
    my $value = <$fh>;
    close $fh or die "Command failed: $_[0]\n";
    $value =~ s/\s+\z//;
    return $value;
}
my $version = capture($^X, "$root/pg_format", '--version');
$version =~ s/^pg_format version // or die "Unexpected formatter version\n";
die "Invalid fork version\n" unless $version =~ /^\d+\.\d+\.\d+-samshull\.\d+$/;
die "Tag must be v$version\n" if defined($tag) && $tag ne "v$version";
my $revision = capture('git', '-C', $root, 'rev-parse', 'HEAD');
my $epoch = capture('git', '-C', $root, 'show', '-s', '--format=%ct', 'HEAD');
if (defined $tag) {
    die "Release tag does not identify HEAD\n"
        unless capture('git', '-C', $root, 'rev-parse', "$tag^{commit}") eq $revision;
    die "Release requires a clean checkout\n"
        if length capture('git', '-C', $root, 'status', '--porcelain', '--untracked-files=normal');
}
my $name = "pgFormatter-$version";
my $tar = Archive::Tar->new;
my %files = (
    'bin/pg_format' => 'pg_format',
    'LICENSE' => 'LICENSE', 'README' => 'README',
    'profiles/readable.conf' => 'profiles/readable.conf',
);
for my $module (glob "$root/lib/pgFormatter/*.pm") {
    (my $relative = $module) =~ s/^\Q$root\E\///;
    $files{"bin/$relative"} = $relative;
}
for my $destination (sort keys %files) {
    open my $fh, '<:raw', "$root/$files{$destination}" or die "$files{$destination}: $!";
    local $/;
    $tar->add_data("$name/$destination", <$fh>, {
        mode => $destination eq 'bin/pg_format' ? 0755 : 0644,
        mtime => $epoch, uid => 0, gid => 0, uname => '', gname => '',
    });
}
my $metadata = JSON::PP->new->canonical->pretty->encode({
    format => 1, version => $version, revision => $revision,
    runtime => 'Perl 5.22 or newer (CLI uses core modules only)',
});
$tar->add_data("$name/release.json", $metadata, {
    mode => 0644, mtime => $epoch, uid => 0, gid => 0, uname => '', gname => '',
});
my $contents = $tar->write;
my $compressed;
gzip \$contents => \$compressed, Time => 0, Minimal => 1 or die "gzip: $GzipError\n";
make_path($output);
my $archive = "$name.tar.gz";
open my $fh, '>:raw', "$output/$archive" or die "$output/$archive: $!";
print {$fh} $compressed;
close $fh or die $!;
open my $checksums, '>', "$output/SHA256SUMS" or die $!;
print {$checksums} sha256_hex($compressed), "  $archive\n";
close $checksums or die $!;
print "$output/$archive\n";
