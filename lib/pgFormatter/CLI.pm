package pgFormatter::CLI;

use strict;
use warnings;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use warnings qw( FATAL );
use utf8;
use open qw( :std );
use Encode qw( decode );

=head1 NAME

pgFormatter::CLI - Implementation of command line program to format SQL queries.

=head1 VERSION

Version 3.3

=cut

# Version of pgFormatter
our $VERSION = '3.3';

use autodie;
use pgFormatter::Beautify;
use Getopt::Long qw(:config no_ignore_case bundling);
use File::Basename;

=head1 SYNOPSIS

This module is called by pg_format program, when it detects it is not being
run in CGI environment. In such case all control over flow is passed to this
module by calling:

    my $program = pgFormatter::CLI->new();
    $program->run()

=head1 FUNCTIONS

=head2 new

Object constructor, nothing fancy in here.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 run

Wraps all work related to pg_format CLI program. This includes calling
methods to read command line parameters, validate them, read query, beautify
it, and output.

=cut

sub run {
    my $self = shift;
    $self->get_command_line_args();
    $self->validate_args();
    $self->logmsg( 'DEBUG', 'Starting to parse SQL file: %s', $self->{ 'cfg' }->{ 'input' } );
    $self->load_sql();
    $self->logmsg( 'DEBUG', 'Beautifying' );
    $self->beautify();
    if ($self->{'wrap_limit'}) {
	    $self->logmsg( 'DEBUG', 'Wrap query' );
	    $self->wrap_lines();
    }
    $self->logmsg( 'DEBUG', 'Writing output' );
    $self->save_output();
    return;
}

=head2 beautify

Actually formats loaded query using pgFormatter::Beautify library. If
necessary runs anonymization.

=cut

sub beautify {
    my $self = shift;
    my %args;
    $args{ 'no_comments' }  = 1 if $self->{ 'cfg' }->{ 'nocomment' };
    $args{ 'spaces' }       = $self->{ 'cfg' }->{ 'spaces' };
    $args{ 'uc_keywords' }  = $self->{ 'cfg' }->{ 'keyword-case' };
    $args{ 'uc_functions' } = $self->{ 'cfg' }->{ 'function-case' };
    $args{ 'placeholder' }  = $self->{ 'cfg' }->{ 'placeholder' };
    $args{ 'separator' }    = $self->{ 'cfg' }->{ 'separator' };
    $args{ 'comma' }        = $self->{ 'cfg' }->{ 'comma' };
    $args{ 'comma_break' }  = $self->{ 'cfg' }->{ 'comma-break' };
    $args{ 'format' }       = $self->{ 'cfg' }->{ 'format' };
    $args{ 'maxlength' }    = $self->{ 'cfg' }->{ 'maxlength' };
    $args{ 'format_type' }  = $self->{ 'cfg' }->{ 'format-type' };
    $args{ 'wrap_limit' }   = $self->{ 'cfg' }->{ 'wrap-limit' };
    $args{ 'wrap_after' }   = $self->{ 'cfg' }->{ 'wrap-after' };

    if ($self->{ 'query' } && ($args{ 'maxlength' } && length($self->{ 'query' }) > $args{ 'maxlength' })) {
        $self->{ 'query' } = substr($self->{ 'query' }, 0, $args{ 'maxlength' })
    }

    my $beautifier = pgFormatter::Beautify->new( %args );
    $beautifier->query( $self->{ 'query' } );
    $beautifier->anonymize() if $self->{ 'cfg' }->{ 'anonymize' };
    $beautifier->beautify();
    if ($self->{ 'cfg' }->{ 'wrap-limit' }) {
	    $self->logmsg( 'DEBUG', 'Wrap query' );
	    $beautifier->wrap_lines();
    }

    $self->{ 'ready' } = $beautifier->content();

    return;
}

=head2 save_output

Saves beautified query to whatever is output filehandle

=cut

sub save_output {
    my $self = shift;
    my $fh   = delete $self->{ 'output' };
    print $fh $self->{ 'ready' };
    close $fh;
    return;
}

=head2 logmsg

Display message following the log level

=cut

sub logmsg {
    my $self = shift;
    my ( $level, $str, @args ) = @_;

    return if ( !$self->{ 'cfg' }->{ 'debug' } && ( $level eq 'DEBUG' ) );

    printf STDERR "%s: $str\n", $level, @args;
    return;
}

=head2 show_help_and_die

As name suggests - shows help page, with optional error message, and ends
program.

=cut

sub show_help_and_die {
    my $self = shift;
    my ( $status, $format, @args ) = @_;

    if ( $format ) {
        $format =~ s/\s*$//;
        printf STDERR "Error: $format\n\n", @args;
    }

    my $program_name = basename( $0 );
    my $help         = qq{
Usage: $program_name [options] file.sql

    PostgreSQL SQL queries and PL/PGSQL code beautifier.

Arguments:

    file.sql can be a file or use - to read query from stdin.

    Returning the SQL formatted to stdout or into a file specified with
    the -o | --output option.

Options:

    -a | --anonymize      : obscure all literals in queries, useful to hide
                            confidential data before formatting.
    -b | --comma-start    : in a parameters list, start with the comma (see -e)
    -B | --comma-break    : in insert statement, add a newline after each comma
    -d | --debug          : enable debug mode. Disabled by default.
    -e | --comma-end      : in a parameters list, end with the comma (default)
    -f | --function-case N: Change the case of the reserved keyword. Default is
                            unchanged: 0. Values: 0=>unchanged, 1=>lowercase,
                            2=>uppercase, 3=>capitalize.
    -F | --format STR     : output format: text or html. Default: text.
    -h | --help           : show this message and exit.
    -m | --maxlength SIZE : maximum length of a query, it will be cutted above
                            the given size. Default: no truncate.
    -n | --nocomment      : remove any comment from SQL code.
    -o | --output file    : define the filename for the output. Default: stdout.
    -p | --placeholder re : set regex to find code that must not be changed.
    -s | --spaces size    : change space indent, default 4 spaces.
    -S | --separator STR  : dynamic code separator, default to single quote.
    -t | --format-type    : try another formatting type for some statements.
    -u | --keyword-case N : Change the case of the reserved keyword. Default is
                            uppercase: 2. Values: 0=>unchanged, 1=>lowercase,
                            2=>uppercase, 3=>capitalize.
    -v | --version        : show pg_format version and exit.
    -w | --wrap-limit N   : wrap queries at a certain length.
    -W | --wrap-after N   : number of column after which lists must be wrapped.
                            Default: puts every item on its own line.

Examples:

    cat samples/ex1.sql | $0 -
    $0 -n samples/ex1.sql
    $0 -f 2 -n -o result.sql samples/ex1.sql
};

    if ( $status ) {
        print STDERR $help;
    }
    else {
        print $help;
    }

    exit $status;
}

=head2 load_sql

Loads SQL from input file or stdin.

=cut

sub load_sql {
    my $self = shift;
    local $/ = undef;
    my $fh = delete $self->{ 'input' };
    $self->{ 'query' } = <$fh>;
    close $fh;
    return;
}

=head2 get_command_line_args

Parses command line options into $self->{'cfg'}.

=cut

sub get_command_line_args {
    my $self = shift;
    my %cfg;
    my @options = (
        'anonymize|a!',
        'comma-start|b!',
        'comma-break|B!',
        'comma-end|e!',
        'debug|d!',
	'format|F=s',
        'function-case|f=i',
        'help|h!',
        'maxlength|m=i',
        'nocomment|n!',
        'output|o=s',
        'placeholder|p=s',
        'separator|S=s',
        'spaces|s=i',
        'format-type|t!',
        'keyword-case|u=i',
        'version|v!',
        'wrap-limit|w=i',
        'wrap-after|W=i',
    );

    $self->show_help_and_die( 1 ) unless GetOptions( \%cfg, @options );

    $self->show_help_and_die( 0 ) if $cfg{ 'help' };

    if ( $cfg{ 'version' } ) {
        printf '%s version %s%s', basename( $0 ), $VERSION, "\n";
        exit 0;
    }

    $cfg{ 'spaces' }        //= 4;
    $cfg{ 'output' }        //= '-';
    $cfg{ 'function-case' } //= 0;
    $cfg{ 'keyword-case' }  //= 2;
    $cfg{ 'comma' }           = 'end';
    $cfg{ 'format' }        //= 'text';
    $cfg{ 'comma-break' }   //= 0;
    $cfg{ 'maxlength' }     //= 0;
    $cfg{ 'format-type' }   //= 0;
    $cfg{ 'wrap-limit' }    //= 0;
    $cfg{ 'wrap-after' }    //= 0;

    if (!grep(/^$cfg{ 'format' }$/i, 'text', 'html')) {
        printf 'FATAL: unknow output format: %s%s', $cfg{ 'format' } , "\n";
        exit 0;
    }

    $cfg{ 'input' } = $ARGV[ 0 ] // '-';
    $self->{ 'cfg' } = \%cfg;
    return;
}

=head2 validate_args

Validates that options parsed from command line have sensible values, opens
input and output files.

=cut

sub validate_args {
    my $self = shift;

    $self->show_help_and_die( 2, 'function-case can be only one of: 0, 1, 2, or 3.' ) unless $self->{ 'cfg' }->{ 'function-case' } =~ m{\A[0123]\z};
    $self->show_help_and_die( 2, 'keyword-case can be only one of: 0, 1, 2, or 3.' )  unless $self->{ 'cfg' }->{ 'keyword-case' } =~ m{\A[0123]\z};

    # Thanks to "autodie" I don't have to check if open() worked.
    if ( $self->{ 'cfg' }->{ 'input' } eq '-' ) {
        $self->{ 'input' } = \*STDIN;
    }
    else {
        open my $fh, '<', $self->{ 'cfg' }->{ 'input' };
        $self->{ 'input' } = $fh;
    }

    if ( $self->{ 'cfg' }->{ 'output' } eq '-' ) {
        $self->logmsg( 'DEBUG', 'Formatted SQL queries will be written to stdout' );
        $self->{ 'output' } = \*STDOUT;
    }
    else {
        $self->logmsg( 'DEBUG', 'Formatted SQL queries will be written to %s', $self->{ 'cfg' }->{ 'output' } );
        open my $fh, '>', $self->{ 'cfg' }->{ 'output' };
        $self->{ 'output' } = $fh;
    }

    if ($self->{ 'cfg' }->{ 'comma-end' }) {
        $self->{ 'cfg' }->{ 'comma' } = 'end';
    }
    elsif ($self->{ 'cfg' }->{ 'comma-start' }) {
        $self->{ 'cfg' }->{ 'comma' } = 'start';
    }

    return;
}

=head1 AUTHOR

pgFormatter is an original work from Gilles Darold

=head1 BUGS

Please report any bugs or feature requests to: https://github.com/darold/pgFormatter/issues

=head1 COPYRIGHT

Copyright 2012-2019 Gilles Darold. All rights reserved.

=head1 LICENSE

pgFormatter is free software distributed under the PostgreSQL Licence.

A modified version of the SQL::Beautify Perl Module is embedded in pgFormatter
with copyright (C) 2009 by Jonas Kramer and is published under the terms of
the Artistic License 2.0.

=cut

1;
