#!/usr/bin/env perl
use strict;
use warnings;
use Archive::Tar;
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use File::Find;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP;

my $initial = getcwd();
END { chdir $initial if defined $initial; }
my $archive = shift @ARGV;
die "Usage: test-release.pl path/to/pgFormatter-VERSION.tar.gz\n" if !defined($archive) || @ARGV;
$archive = abs_path($archive) or die "Archive not found\n";
my $name = basename($archive);
$name =~ /^pgFormatter-(\d+\.\d+\.\d+-samshull\.\d+)\.tar\.gz$/ or die "Invalid archive name\n";
my $version = $1;
my $prefix = "pgFormatter-$version";
sub read_file {
    open my $fh, '<:raw', $_[0] or die "$_[0]: $!";
    local $/;
    return <$fh>;
}
my $checksums = read_file(dirname($archive) . '/SHA256SUMS');
my @digests = $checksums =~ /^([a-f0-9]{64})  \Q$name\E$/mg;
die "Missing or duplicate archive checksum\n" unless @digests == 1;
die "Archive checksum mismatch\n" unless sha256_hex(read_file($archive)) eq $digests[0];
my $tar = Archive::Tar->new;
$tar->read($archive, 1) or die "Cannot read release archive\n";
my %members;
for my $file ($tar->get_files) {
    my $path = $file->full_path;
    die "Unsafe archive member: $path\n" unless $file->is_file
        && $path =~ m{^\Q$prefix\E/(?:bin/pg_format|bin/lib/pgFormatter/[A-Za-z]+\.pm|LICENSE|README|profiles/readable\.conf|release\.json)$};
    die "Duplicate archive member: $path\n" if $members{$path}++;
}
for my $required (qw(bin/pg_format bin/lib/pgFormatter/CLI.pm bin/lib/pgFormatter/Beautify.pm LICENSE README profiles/readable.conf release.json)) {
    die "Missing package file: $required\n" unless $members{"$prefix/$required"};
}
my $temporary = tempdir('pgformatter-release-XXXX', TMPDIR => 1, CLEANUP => 1);
# A path containing spaces also checks FindBin's portable module lookup.
my $unpacked = "$temporary/unpacked release";
make_path($unpacked);
chdir $unpacked or die $!;
$tar->extract or die "Cannot extract release archive\n";
my $package = "$unpacked/$prefix";
my $metadata = decode_json(read_file("$package/release.json"));
die "Invalid release metadata\n" unless $metadata->{format} == 1
    && $metadata->{version} eq $version && $metadata->{revision} =~ /^[a-f0-9]{40}$/;
die "Executable mode missing\n" unless -x "$package/bin/pg_format";
delete @ENV{qw(PERL5LIB PERLLIB PERL5OPT GATEWAY_INTERFACE)};
my $away = "$temporary/away";
make_path($away);
chdir $away or die $!;
symlink "$package/bin/pg_format", 'pg_format' or die $!;
open my $version_fh, '-|', './pg_format', '--version' or die $!;
my $actual = do { local $/; <$version_fh> };
close $version_fh or die "Packaged executable failed\n";
die "Version mismatch\n" unless $actual eq "pg_format version $version\n";
my $root = abs_path("$FindBin::Bin/..");
# Copy fixtures only. Every runtime module and profile comes from the archive.
for my $directory (qw(t doc)) {
    find({ no_chdir => 1, wanted => sub {
        my $source = $File::Find::name;
        (my $relative = $source) =~ s/^\Q$root\E\///;
        if (-d $source) { make_path($relative); }
        elsif (-f $source) { copy($source, $relative) or die "$source: $!"; }
    } }, "$root/$directory");
}
symlink "$package/bin/lib", 'lib' or die $!;
symlink "$package/profiles", 'profiles' or die $!;
local $ENV{PG_FORMAT} = './pg_format';
my @tests = sort grep { !/11_release\.t$/ } glob 't/*.t';
system('prove', '-l', @tests);
die "Packaged regression suite failed\n" if $?;
print "Verified $name: checksum, portable runtime, symlink lookup, and regression suite.\n";
