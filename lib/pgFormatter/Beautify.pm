package pgFormatter::Beautify;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.14;    # It was released in 2011, so I guess we can assume anything should have it by now.
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Encode qw( decode );

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

# Without this, usage of /(?<!STYLES)/i will break
use re '/aa';

# PostgreSQL functions that use a FROM clause
our @have_from_clause = qw( extract overlay substring trim );

=head1 NAME

pgFormatter::Beautify - Library for pretty-printing SQL queries

=head1 VERSION

Version 1.6

=cut

# Version of pgFormatter
our $VERSION = '1.6';

# Inclusion of code from Perl package SQL::Beautify
# Copyright (C) 2009 by Jonas Kramer
# Published under the terms of the Artistic License 2.0.

=head1 SYNOPSIS

This module can be used to reformat given SQL query, optionally anonymizing parameters.

Output can be either plain text, or it can be HTML with appropriate styles so that it can be displayed on a web page.

Example usage:

    my $beautifier = pgFormatter::Beautify->new();
    $beautifier->query( 'select a,b,c from d where e = f' );

    $beautifier->beautify();
    my $nice_txt = $beautifier->content();

    $beautifier->html_highlight_code();
    my $nice_html = $beautifier->content();

    $beautifier->anonymize();
    $beautifier->html_highlight_code();
    my $nice_anonymized_html = $beautifier->content();

=head1 FUNCTIONS

=head2 new

Generic constructur - creates object, sets defaults, and reads config from given hash with options.

Takes options as hash. Following options are recognized:

=over

=item * break - String that is used for linebreaks. Default is "\n".

=item * functions - list (arrayref) of strings that are function names

=item * keywords - list (arrayref) of strings that are keywords

=item * no_comments - if set to true comments will be removed from query

=item * placeholder - use the specified regex to find code that must not be changed in the query.

=item * query - query to beautify

=item * rules - hash of rules - uses rule semantics from SQL::Beautify

=item * space - character(s) to be used as space for indentation

=item * spaces - how many spaces to use for indentation

=item * uc_functions - what to do with function names:

=over

=item 0 - do not change

=item 1 - change to lower case

=item 2 - change to upper case

=item 3 - change to Capitalized

=back

=item * uc_keywords - what to do with keywords - meaning of value like with uc_functions

=item * wrap - wraps given keywords in pre- and post- markup. Specific docs in SQL::Beautify

=back

For defaults, please check function L<set_defaults>.

=cut

sub new {
    my $class   = shift;
    my %options = @_;

    my $self = bless {}, $class;
    $self->set_defaults();

    for my $key ( qw( query spaces space break wrap keywords functions rules uc_keywords uc_functions no_comments placeholder ) ) {
        $self->{ $key } = $options{ $key } if defined $options{ $key };
    }

    # Make sure "break" is sensible
    $self->{ 'break' } = ' ' if $self->{ 'spaces' } == 0;

    # Initialize internal stuff.
    $self->{ '_level' } = 0;

    # Array to store placeholders values
    @{ $self->{ 'placeholder_values' } } = ();

    return $self;
}

=head2 query

Accessor to query string. Both reads:

    $object->query()

, and writes

    $object->query( $something )

=cut

sub query {
    my $self      = shift;
    my $new_value = shift;

    $self->{ 'query' } = $new_value if defined $new_value;

    # Store values of code that must not be changed following the given placeholder
    if ($self->{ 'placeholder' }) {
        my $i = 0;
        while ( $self->{ 'query' } =~ s/($self->{ 'placeholder' })/PLACEHOLDER${i}PLACEHOLDER/) {
            push(@{ $self->{ 'placeholder_values' } }, $1);
            $i++;
       }
    }

    return $self->{ 'query' };
}

=head2 content

Accessor to content of results.

This can be either plain text (after $object->beautify()), or html, if client code called $object->html_highlight_code()

=cut

sub content {
    my $self      = shift;
    my $new_value = shift;

    $self->{ 'content' } = $new_value if defined $new_value;

    # Replace placeholders by their original values
    if ($self->{ 'placeholder' }) {
	$self->{ 'content' } =~ s/PLACEHOLDER(\d+)PLACEHOLDER/$self->{ 'placeholder_values' }[$1]/igs;
    }

    return $self->{ 'content' };
}

=head2 html_highlight_code

Makes result (in $object->content()) html with styles set for highlighting.

Internally it calls L<beautify()> method, and then reformats output to HTML form.

=cut

sub html_highlight_code {
    my $self = shift;

    $self->beautify();

    my $code = $self->content();

    my $i      = 0;
    my @qqcode = ();
    while ( $code =~ s/("[^\"]*")/QQCODEY${i}A/s ) {
        push( @qqcode, $1 );
        $i++;
    }

    $i = 0;
    my @qcode = ();
    while ( $code =~ s/('.*?(?<!\\)')/QCODEY${i}B/s ) {
        push( @qcode, $1 );
        $i++;
    }

    while ( my ( $k, $v ) = each %{ $self->{ 'dict' }->{ 'symbols' } } ) {
        $code =~ s/$k/\$\$STYLESY0A\$\$$v\$\$STYLESY0B\$\$/gs;
    }

    for my $k ( sort { length( $b ) <=> length( $a ) } @{ $self->{ 'dict' }->{ 'sql_keywords' } } ) {
        if ( $self->{ 'uc_keywords' } == 1 ) {
            $code =~ s/(?<!STYLESY0B\$\$)\b$k\b/<span class="kw1_l">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_keywords' } == 2 ) {
            $code =~ s/(?<!STYLESY0B\$\$)\b$k\b/<span class="kw1_u">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_keywords' } == 3 ) {
            $code =~ s/(?<!STYLESY0B\$\$)\b$k\b/<span class="kw1_c">\L$k\E<\/span>/igs;
        }
        else {
            $code =~ s/(?<!STYLESY0B\$\$)\b$k\b/<span class="kw1">$k<\/span>/igs;
        }
    }

    for my $k ( sort { length( $b ) <=> length( $a ) } @{ $self->{ 'dict' }->{ 'pg_functions' } } ) {
        if ( $self->{ 'uc_functions' } == 1 ) {
            $code =~ s/(?<!:)\b$k\b/<span class="kw2_l">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_functions' } == 2 ) {
            $code =~ s/(?<!:)\b$k\b/<span class="kw2_u">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_functions' } == 3 ) {
            $code =~ s/(?<!:)\b$k\b/<span class="kw2_c">\L$k\E<\/span>/igs;
        }
        else {
            $code =~ s/(?<!:)\b$k\b/<span class="kw2">$k<\/span>/igs;
        }
    }

    for my $k ( sort { length( $b ) <=> length( $a ) } @{ $self->{ 'dict' }->{ 'copy_keywords' } } ) {
        if ( $self->{ 'uc_keywords' } == 1 ) {
            $code =~ s/\b$k\b/<span class="kw3_l">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_keywords' } == 2 ) {
            $code =~ s/\b$k\b/<span class="kw3_u">$k<\/span>/igs;
        }
        elsif ( $self->{ 'uc_keywords' } == 3 ) {
            $code =~ s/\b$k\b/<span class="kw3_c">\L$k\E<\/span>/igs;
        }
        else {
            $code =~ s/\b$k\b/<span class="kw3">$k<\/span>/igs;
        }
    }

    for my $k ( sort { length( $b ) <=> length( $a ) } @{ $self->{ 'dict' }->{ 'brackets' } } ) {
        $code =~ s/(\Q$k\E)/<span class="br0">$1<\/span>/igs;
    }

    $code =~ s/\$\$STYLESY0A\$\$([^\$]+)\$\$STYLESY0B\$\$/<span class="sy0">$1<\/span>/gs;

    $code =~ s/\b(\d+)\b/<span class="nu0">$1<\/span>/igs;

    for ( my $x = 0 ; $x <= $#qcode ; $x++ ) {
        $code =~ s/QCODEY${x}B/$qcode[$x]/s;
    }

    for ( my $x = 0 ; $x <= $#qqcode ; $x++ ) {
        $code =~ s/QQCODEY${x}A/$qqcode[$x]/s;
    }

    $code =~ s/('.*?(?<!\\)')/<span class="st0">$1<\/span>/gs;
    $code =~ s/(`[^`]*`)/<span class="st0">$1<\/span>/gs;

    $self->content( $code );

    return;
}

=head2 tokenize_sql

Splits input SQL into tokens

Code lifted from SQL::Beautify

=cut

sub tokenize_sql {
    my $self  = shift;
    my $query = $self->query();

    my $re = qr{
	(
		(?:--)[\ \t\S]*      # single line comments
		|
		(?:\-\|\-) # range operator "is adjacent to"
		|
		(?:\->>|\->|\#>>|\#>|\?\&|\?)  # Json Operators
		|
		(?:\#<=|\#>=|\#<>|\#<|\#=) # compares tinterval and reltime
		|
		(?:>>=|<<=) # inet operators
		|
		(?:!!|\@\@\@) # deprecated factorial and full text search  operators
		|
		(?:\|\|\/|\|\/) # square root and cube root
		|
		(?:\@\-\@|\@\@|\#\#|<\->|<<\||\|>>|\&<\||\&<|\|\&>|\&>|<\^|>\^|\?\#|\#|\?<\||\?\-\||\?\-|\?\|\||\?\||\@>|<\@|\~=)
				 # Geometric Operators
		|
		(?:~<=~|~>=~|~>~|~<~) # string comparison for pattern matching operator families
		|
		(?:!~~|!~~\*|~~\*|~~) # LIKE operators
		|
		(?:!~\*|!~|~\*) # regular expression operators
		|
		(?:\*=|\*<>|\*<=|\*>=|\*<|\*>) # composite type comparison operators
		|
		(?:<>|<=>|>=|<=|==|!=|=|!|<<|>>|<|>|\|\||\||&&|&|-|\+|\*(?!/)|/(?!\*)|\%|~|\^|\?) # operators and tests
		|
		[\[\]\(\),;.]            # punctuation (parenthesis, comma)
		|
		E\'\'(?!\')              # empty single escaped quoted string
		|
		\'\'(?!\')              # empty single quoted string
		|
		\"\"(?!\"")             # empty double quoted string
		|
		"(?>(?:(?>[^"\\]+)|""|\\.)*)+" # anything inside double quotes, ungreedy
		|
		`(?>(?:(?>[^`\\]+)|``|\\.)*)+` # anything inside backticks quotes, ungreedy
		|
		E'(?>(?:(?>[^'\\]+)|''|\\.)*)+' # anything escaped inside single quotes, ungreedy.
		|
		'(?>(?:(?>[^'\\]+)|''|\\.)*)+' # anything inside single quotes, ungreedy.
		|
		/\*[\ \t\r\n\S]*?\*/      # C style comments
		|
		(?:[\w:@]+(?:\.(?:\w+|\*)?)*) # words, standard named placeholders, db.table.*, db.*
		|
		(?:\$\w+\$)
		|
		(?: \$_\$ | \$\d+ | \${1,2} | \$\w+\$ ) # dollar expressions - eg $_$ $3 $$ $BODY$
		|
		\n                      # newline
		|
		[\t\ ]+                 # any kind of white spaces
	)
    }smx;

    my @query = ();
    @query = grep { /\S/ } $query =~ m{$re}smxg;

    $self->{ '_tokens' } = \@query;
}

=head2 beautify

Beautify SQL.

After calling this function, $object->content() will contain nicely indented result.

Code lifted from SQL::Beautify

=cut

sub beautify {
    my $self = shift;

    $self->content( '' );
    $self->{ '_level_stack' } = [];
    $self->{ '_new_line' }    = 1;

    my $last;
    $self->tokenize_sql();

    while ( defined( my $token = $self->_token ) ) {
        my $rule = $self->_get_rule( $token );

        # Allow custom rules to override defaults.
        if ( $rule ) {
            $self->_process_rule( $rule, $token );
        }

        elsif ( $token eq '(' ) {
            $self->_add_token( $token );
            if ( ($self->_next_token ne ')') && ($self->_next_token ne '*') ) {
		$self->{ '_has_from' } = 1 if (grep(/^\Q$last\E$/i, @have_from_clause));
                push @{ $self->{ '_level_stack' } }, $self->{ '_level' };
                $self->_over unless $last and uc( $last ) eq 'WHERE';

            }
        }

        elsif ( $token eq ')' ) {
	    $self->{ '_has_from' } = 0;
	    if ( ($last ne '(') && ($last ne '*') )  {
		$self->{ '_level' } = pop( @{ $self->{ '_level_stack' } } ) || 0;
	    }
            $self->_add_token( $token );
	    my $next_tok = quotemeta($self->_next_token);
            $self->_new_line
                if ($self->_next_token
                and $self->_next_token !~ /^AS$/i
                and $self->_next_token ne ')'
                and $self->_next_token !~ /::/
                and $self->_next_token ne ';'
                and $self->_next_token ne ','
		and !exists $SYMBOLS{$next_tok} );
        }

        elsif ( $token eq ',' ) {
            $self->_add_token( $token );
            $self->_new_line if ($self->_next_token !~ /^'/ && !$self->{ '_is_in_where' });
        }

        elsif ( $token eq ';' ) {
	    $self->{ '_has_from' } = 0;
	    $self->{ '_is_in_where' } = 0;
            $self->_add_token( $token );
            $self->{ 'break' } = "\n" unless ( $self->{ 'spaces' } != 0 );
            $self->_new_line;

            # End of statement; remove all indentation.
            @{ $self->{ '_level_stack' } } = ();
            $self->{ '_level' } = 0;
            $self->{ 'break' } = ' ' unless ( $self->{ 'spaces' } != 0 );
        }

        elsif ( $token =~ /^(?:SELECT|FROM|WHERE|HAVING|BEGIN|SET)$/i ) {

	    if (($token =~ /^FROM$/i) && $self->{ '_has_from' } ) {
		$self->{ '_has_from' } = 0;
                $self->_new_line;
	        $self->_add_token( $token );
                $self->_new_line;
	    }
	    else
	    {
		# if we're not in a sub-select, make sure these always are
		# at the far left (col 1)
		$self->_back if ( $last and $last ne '(' and $last ne 'FOR' );

		$self->_new_line;
		$self->_add_token( $token );
		$self->_new_line if ( ( ( $token ne 'SET' ) || $last ) and $self->_next_token and $self->_next_token ne '(' and $self->_next_token ne ';' );
		$self->_over;
	    }
	    if ($token =~ /^WHERE$/i) {
		$self->{ '_is_in_where' } = 1;
	    } else {
		$self->{ '_is_in_where' } = 0;
	    }

        }

        elsif ( $token =~ /^(?:GROUP|ORDER|LIMIT)$/i ) {
            $self->_back;
            $self->_new_line;
            $self->_add_token( $token );
	    $self->{ '_is_in_where' } = 0;
        }

        elsif ( $token =~ /^(?:BY)$/i ) {
            $self->_add_token( $token );
            $self->_new_line;
            $self->_over;
        }

        elsif ( $token =~ /^(?:CASE)$/i ) {
            $self->_add_token( $token );
            $self->_over;
        }

        elsif ( $token =~ /^(?:WHEN)$/i ) {
            $self->_new_line;
            $self->_add_token( $token );
        }

        elsif ( $token =~ /^(?:ELSE)$/i ) {
            $self->_new_line;
            $self->_add_token( $token );
        }

        elsif ( $token =~ /^(?:END)$/i ) {
            $self->_back;
            $self->_new_line;
            $self->_add_token( $token );
        }

        elsif ( $token =~ /^(?:UNION|INTERSECT|EXCEPT)$/i ) {
            $self->_back unless $last and $last eq '(';
            $self->_new_line;
            $self->_add_token( $token );
            $self->_new_line if ( $self->_next_token and $self->_next_token ne '(' );
            $self->_over;
        }

        elsif ( $token =~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS|NATURAL)$/i ) {
            $self->_back unless $last and $last eq ')';

            if ( $token =~ /(?:LEFT|RIGHT|CROSS|NATURAL)$/i ) {
                $self->_new_line;
                $self->_over if ( $self->{ '_level' } == 0 );
            }
            if ( ($token =~ /(?:INNER|OUTER)$/i) && ($last !~ /(?:LEFT|RIGHT|CROSS|NATURAL)$/i) ) {
                $self->_new_line;
                $self->_over if ($self->{_level} == 0);
            } 
            $self->_add_token( $token );
        }

        elsif ( $token =~ /^(?:JOIN)$/i ) {
            if ( !$last or $last !~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS|NATURAL)$/i ) {
                $self->_new_line;
            }
            $self->_add_token( $token );
            if ( $last && $last =~ /^(?:INNER|OUTER)$/i ) {
                $self->_over;
            }
        }

        elsif ( $token =~ /^(?:AND|OR)$/i ) {
            if ( !$last or ( $last !~ /^(?:CREATE)$/i ) ) {
                $self->_new_line;
            }
            $self->_add_token( $token );
        }

        elsif ( $token =~ /^--/ ) {
            if ( !$self->{ 'no_comments' } ) {
                $self->_add_token( $token );
                $self->{ 'break' } = "\n" unless ( $self->{ 'spaces' } != 0 );
                $self->_new_line;
                $self->{ 'break' } = ' ' unless ( $self->{ 'spaces' } != 0 );
            }
        }

        elsif ( $token =~ /^\/\*.*\*\/$/s ) {
            if ( !$self->{ 'no_comments' } ) {
                $token =~ s/\n[\s\t]+\*/\n\*/gs;
                $self->_new_line;
                $self->_add_token( $token );
                $self->{ 'break' } = "\n" unless ( $self->{ 'spaces' } != 0 );
                $self->_new_line;
                $self->{ 'break' } = " " unless ( $self->{ 'spaces' } != 0 );
            }
        }

        elsif ($token =~ /^(?:USING)$/i) {
            $self->_new_line;
            $self->_add_token($token);
        }

        else {
            $self->_add_token( $token, $last );
        }

        $last = $token;
    }

    $self->_new_line;

    return;
}

=head2 _add_token

Add a token to the beautified string.

Code lifted from SQL::Beautify

=cut

sub _add_token {
    my ( $self, $token, $last_token ) = @_;

    if ( $self->{ 'wrap' } ) {
        my $wrap;
        if ( $self->_is_keyword( $token ) ) {
            $wrap = $self->{ 'wrap' }->{ 'keywords' };
        }
        elsif ( $self->_is_constant( $token ) ) {
            $wrap = $self->{ 'wrap' }->{ 'constants' };
        }

        if ( $wrap ) {
            $token = $wrap->[ 0 ] . $token . $wrap->[ 1 ];
        }
    }

    my $last_is_dot = defined( $last_token ) && $last_token eq '.';

    if ( !$self->_is_punctuation( $token ) and !$last_is_dot ) {
        my $sp = $self->_indent;
	if ( (!defined($last_token) || $last_token ne '(') && ($token ne ')') && ($token !~ /^::/) ) {
		$self->{ 'content' } .= $sp if (!defined($last_token) || $last_token ne '::');
	}
        $token =~ s/\n/\n$sp/gs;
    }

    # uppercase keywords
    if ( $self->{ 'uc_keywords' } && $self->_is_keyword( $token ) ) {
        $token = lc( $token )            if ( $self->{ 'uc_keywords' } == 1 );
        $token = uc( $token )            if ( $self->{ 'uc_keywords' } == 2 );
        $token = ucfirst( lc( $token ) ) if ( $self->{ 'uc_keywords' } == 3 );
    }

    # uppercase functions
    if ( $self->{ 'uc_functions' } && ( my $fct = $self->_is_function( $token ) ) ) {
        $token =~ s/$fct/\L$fct\E/i if ( $self->{ 'uc_functions' } == 1 );
        $token =~ s/$fct/\U$fct\E/i if ( $self->{ 'uc_functions' } == 2 );
        $fct = ucfirst( lc( $fct ) );
        $token =~ s/$fct/$fct/i if ( $self->{ 'uc_functions' } == 3 );
    }

    $self->{ 'content' } .= $token;
    $self->{ 'content' } =~ s/\(\s+\(/\(\(/gs;

    # This can't be the beginning of a new line anymore.
    $self->{ '_new_line' } = 0;
}

=head2 _over

Increase the indentation level.

Code lifted from SQL::Beautify

=cut

sub _over {
    my ( $self ) = @_;

    ++$self->{ '_level' };
}

=head2 _back

Decrease the indentation level.

Code lifted from SQL::Beautify

=cut

sub _back {
    my ( $self ) = @_;

    --$self->{ '_level' } if ( $self->{ '_level' } > 0 );
}

=head2 _indent

Return a string of spaces according to the current indentation level and the
spaces setting for indenting.

Code lifted from SQL::Beautify

=cut

sub _indent {
    my ( $self ) = @_;

    if ( $self->{ '_new_line' } ) {
        return $self->{ 'space' } x ( $self->{ 'spaces' } * $self->{ '_level' } );
    }
    else {
        return $self->{ 'space' };
    }
}

=head2 _new_line

Add a line break, but make sure there are no empty lines.

Code lifted from SQL::Beautify

=cut

sub _new_line {
    my ( $self ) = @_;

    $self->{ 'content' } .= $self->{ 'break' } unless ( $self->{ '_new_line' } );
    $self->{ '_new_line' } = 1;
}

=head2 _next_token

Have a look at the token that's coming up next.

Code lifted from SQL::Beautify

=cut

sub _next_token {
    my ( $self ) = @_;

    return @{ $self->{ '_tokens' } } ? $self->{ '_tokens' }->[ 0 ] : undef;
}

=head2 _token

Get the next token, removing it from the list of remaining tokens.

Code lifted from SQL::Beautify

=cut

sub _token {
    my ( $self ) = @_;

    return shift @{ $self->{ '_tokens' } };
}

=head2 _is_keyword

Check if a token is a known SQL keyword.

Code lifted from SQL::Beautify

=cut

sub _is_keyword {
    my ( $self, $token ) = @_;

    return ~~ grep { $_ eq uc( $token ) } @{ $self->{ 'keywords' } };
}

=head2 _is_function

Check if a token is a known SQL function.

Code lifted from SQL::Beautify

=cut

sub _is_function {
    my ( $self, $token ) = @_;

    my @ret = grep( $token =~ /\b[\.]*$_$/i, @{ $self->{ 'functions' } } );

    return $ret[ 0 ];
}

=head2 add_keywords

Add new keywords to highlight.

Code lifted from SQL::Beautify

=cut

sub add_keywords {
    my $self = shift;

    for my $keyword ( @_ ) {
        push @{ $self->{ 'keywords' } }, ref( $keyword ) ? @{ $keyword } : $keyword;
    }
}

=head2 add_functions

Add new functions to highlight.

Code lifted from SQL::Beautify

=cut

sub add_functions {
    my $self = shift;

    for my $function ( @_ ) {
        push @{ $self->{ 'functions' } }, ref( $function ) ? @{ $function } : $function;
    }
}

=head2 add_rule

Add new rules.

Code lifted from SQL::Beautify

=cut

sub add_rule {
    my ( $self, $format, $token ) = @_;

    my $rules = $self->{ 'rules' }  ||= {};
    my $group = $rules->{ $format } ||= [];

    push @{ $group }, ref( $token ) ? @{ $token } : $token;
}

=head2 _get_rule

Find custom rule for a token.

Code lifted from SQL::Beautify

=cut

sub _get_rule {
    my ( $self, $token ) = @_;

    values %{ $self->{ 'rules' } };    # Reset iterator.

    while ( my ( $rule, $list ) = each %{ $self->{ 'rules' } } ) {
        return $rule if ( grep { uc( $token ) eq uc( $_ ) } @$list );
    }

    return;
}

=head2 _process_rule

Applies defined rule.

Code lifted from SQL::Beautify

=cut

sub _process_rule {
    my ( $self, $rule, $token ) = @_;

    my $format = {
        break => sub { $self->_new_line },
        over  => sub { $self->_over },
        back  => sub { $self->_back },
        token => sub { $self->_add_token( $token ) },
        push  => sub { push @{ $self->{ '_level_stack' } }, $self->{ '_level' } },
        pop   => sub { $self->{ '_level' } = pop( @{ $self->{ '_level_stack' } } ) || 0 },
        reset => sub { $self->{ '_level' } = 0; @{ $self->{ '_level_stack' } } = (); },
    };

    for ( split /-/, lc $rule ) {
        &{ $format->{ $_ } } if ( $format->{ $_ } );
    }
}

=head2 _is_constant

Check if a token is a constant.

Code lifted from SQL::Beautify

=cut

sub _is_constant {
    my ( $self, $token ) = @_;

    return ( $token =~ /^\d+$/ or $token =~ /^(['"`]).*\1$/ );
}

=head2 _is_punctuation

Check if a token is punctuation.

Code lifted from SQL::Beautify

=cut

sub _is_punctuation {
    my ( $self, $token ) = @_;
    return ( $token =~ /^[,;.]$/ );
}

=head2 _generate_anonymized_string

Simply generate a random string, thanks to Perlmonks.

Returns original in certain cases which don't require anonymization, like
timestamps, or intervals.

=cut

sub _generate_anonymized_string {
    my $self = shift;
    my ( $before, $original, $after ) = @_;

    # Prevent dates from being anonymized
    return $original if $original =~ m{\A\d\d\d\d[/:-]\d\d[/:-]\d\d\z};
    return $original if $original =~ m{\A\d\d[/:-]\d\d[/:-]\d\d\d\d\z};

    # Prevent dates format like DD/MM/YYYY HH24:MI:SS from being anonymized
    return $original if $original =~ m{
        \A
        (?:FM|FX|TM)?
        (?:
            HH | HH12 | HH24
            | MI
            | SS
            | MS
            | US
            | SSSS
            | AM | A\.M\. | am | a\.m\.
            | PM | P\.M\. | pm | p\.m\.
            | Y,YYY | YYYY | YYY | YY | Y
            | IYYY | IYY | IY | I
            | BC | B\.C\. | bc | b\.c\.
            | AD | A\.D\. | ad | a\.d\.
            | MONTH | Month | month | MON | Mon | mon | MM
            | DAY | Day | day | DY | Dy | dy | DDD | DD | D
            | W | WW | IW
            | CC
            | J
            | Q
            | RM | rm
            | TZ | tz
            | [\s/:-]
        )+
        (?:TH|th|SP)?
        \z
    };

    # Prevent interval from being anonymized

    return $original if ($before && ($before =~ /interval/i));
    return $original if ($after && ($after =~ /^\)*::interval/i));

    # Shortcut
    my $cache = $self->{ '_anonymization_cache' };

    # Range of characters to use in anonymized strings
    my @chars = ( 'A' .. 'Z', 0 .. 9, 'a' .. 'z', '-', '_', '.' );

    unless ( $cache->{ $original } ) {

        # Actual anonymized version generation
        $cache->{ $original } = join( '', map { $chars[ rand @chars ] } 1 .. 10 );
    }

    return $cache->{ $original };
}

=head2 anonymize

Anonymize litteral in SQL queries by replacing parameters with fake values

=cut

sub anonymize {
    my $self  = shift;
    my $query = $self->query;

    return if ( !$query );

    # Variable to hold anonymized versions, so we can provide the same value
    # for the same input, within single query.
    $self->{ '_anonymization_cache' } = {};

    # Remove comments
    $query =~ s/\/\*(.*?)\*\///gs;

    # Clean query
    $query =~ s/\\'//gs;
    $query =~ s/('')+/\$EMPTYSTRING\$/gs;

    # Anonymize each values
    $query =~ s{
        ([^\s\']+[\s\(]*)       # before
        '([^']*)'               # original
        ([\)]*::\w+)?           # after
    }{$1 . "'" . $self->_generate_anonymized_string($1, $2, $3) . "'" . ($3||'')}xeg;

    $query =~ s/\$EMPTYSTRING\$/''/gs;

    $self->query( $query );
}

=head2 set_defaults

Sets defaults for newly created objects.

Currently defined defaults:

=over

=item spaces => 4

=item space => ' '

=item break => "\n"

=item uc_keywords => 0

=item uc_functions => 0

=item no_comments => 0

=item placeholder => ''

=back

=cut

sub set_defaults {
    my $self = shift;
    $self->set_dicts();

    # Set some defaults.
    $self->{ 'query' }        = '';
    $self->{ 'spaces' }       = 4;
    $self->{ 'space' }        = ' ';
    $self->{ 'break' }        = "\n";
    $self->{ 'wrap' }         = {};
    $self->{ 'rules' }        = {};
    $self->{ 'uc_keywords' }  = 0;
    $self->{ 'uc_functions' } = 0;
    $self->{ 'no_comments' }  = 0;
    $self->{ 'placeholder' }  = '';
    $self->{ 'keywords' }     = $self->{ 'dict' }->{ 'pg_keywords' };
    $self->{ 'functions' }    = $self->{ 'dict' }->{ 'pg_functions' };
    return;
}

=head2 set_dicts

Sets various dictionaries (lists of keywords, functions, symbols, and the like)

This was moved to separate function, so it can be put at the very end of module
so it will be easier to read the rest of the code.

=cut

sub set_dicts {
    my $self = shift;

    # First load it all as "my" variables, to make it simpler to modify/map/grep/add
    # Afterwards, when everything is ready, put it in $self->{'dict'}->{...}

    my @pg_keywords = map { uc } qw(
        ALL ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC AUTHORIZATION BERNOULLI BINARY BOTH BY CASE
        CAST CHECK COLLATE COLLATION COLUMN CONCURRENTLY CONFLICT CONSTRAINT CREATE CROSS CUBE
        CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER
        DEFAULT DEFERRABLE DESC DISTINCT DO ELSE END EXCEPT FALSE FETCH FOR FOREIGN FREEZE FROM
        FULL GRANT GROUP GROUPING HAVING ILIKE IN INITIALLY INNER INTERSECT INTO IS ISNULL JOIN LEADING
        LEFT LIKE LIMIT LOCALTIME LOCALTIMESTAMP LOCKED LOGGED NATURAL NOT NOTNULL NULL ON ONLY OPEN OR
        ORDER OUTER OVER OVERLAPS PLACING POLICY PRIMARY REFERENCES REPLACE RETURNING RETURNS RIGHT ROLLUP SELECT SESSION_USER
        SETS SKIP SIMILAR SOME SYMMETRIC TABLE TABLESAMPLE THEN TO TRAILING TRUE UNION UNIQUE USER USING VARIADIC
        VERBOSE WHEN WHERE WINDOW WITH
        );
 
    my @sql_keywords = map { uc } qw(
        ALTER ADD AUTO_INCREMENT BETWEEN BY BOOLEAN BEGIN CHANGE COLUMNS COMMIT COALESCE CLUSTER
        COPY DATABASES DATABASE DATA DELAYED DESCRIBE DELETE DROP ENCLOSED ESCAPED EXISTS EXPLAIN
        FIELDS FIELD FLUSH FUNCTION GREATEST IGNORE INDEX INFILE INSERT IDENTIFIED IF INHERIT
        KEYS KILL KEY LINES LOAD LOCAL LOCK LOW_PRIORITY LANGUAGE LEAST LOGIN MODIFY
        NULLIF NOSUPERUSER NOCREATEDB NOCREATEROLE OPTIMIZE OPTION OPTIONALLY OUTFILE OWNER PROCEDURE
        PROCEDURAL READ REGEXP RENAME RETURN REVOKE RLIKE ROLE ROLLBACK SHOW SONAME STATUS
        STRAIGHT_JOIN SET SEQUENCE TABLES TEMINATED TRUNCATE TEMPORARY TRIGGER TRUSTED UNLOCK
        USE UPDATE UNSIGNED VALUES VARIABLES VIEW VACUUM WRITE ZEROFILL XOR
        ABORT ABSOLUTE ACCESS ACTION ADMIN AFTER AGGREGATE ALSO ALWAYS ASSERTION ASSIGNMENT AT ATTRIBUTE
        BACKWARD BEFORE BIGINT CACHE CALLED CASCADE CASCADED CATALOG CHAIN CHARACTER CHARACTERISTICS
        CHECKPOINT CLOSE COMMENT COMMENTS COMMITTED CONFIGURATION CONNECTION CONSTRAINTS CONTENT
        CONTINUE CONVERSION COST CSV CURRENT CURSOR CYCLE DAY DEALLOCATE DEC DECIMAL DECLARE DEFAULTS
        DEFERRED DEFINER DELIMITER DELIMITERS DICTIONARY DISABLE DISCARD DOCUMENT DOMAIN DOUBLE EACH
        ENABLE ENCODING ENCRYPTED ENUM ESCAPE EXCLUDE EXCLUDING EXCLUSIVE EXECUTE EXTENSION EXTERNAL
        FIRST FLOAT FOLLOWING FORCE FORWARD FUNCTIONS GLOBAL GRANTED HANDLER HEADER HOLD
        HOUR IDENTITY IMMEDIATE IMMUTABLE IMPLICIT INCLUDING INCREMENT INDEXES INHERITS INLINE INOUT INPUT
        INSENSITIVE INSTEAD INT INTEGER INVOKER ISOLATION LABEL LARGE LAST LC_COLLATE LC_CTYPE
        LEAKPROOF LEVEL LISTEN LOCATION LOOP MAPPING MATCH MAXVALUE MINUTE MINVALUE MODE MONTH MOVE NAMES
        NATIONAL NCHAR NEXT NO NONE NOTHING NOTIFY NOWAIT NULLS OBJECT OF OFF OIDS OPERATOR OPTIONS
        OUT OWNED PARSER PARTIAL PARTITION PASSING PASSWORD PLANS PRECEDING PRECISION PREPARE
        PREPARED PRESERVE PRIOR PRIVILEGES QUOTE RANGE REAL REASSIGN RECHECK RECURSIVE REF REINDEX RELATIVE
        RELEASE REPEATABLE REPLICA RESET RESTART RESTRICT RETURNS ROW ROWS RULE SAVEPOINT SCHEMA SCROLL SEARCH
        SECOND SECURITY SEQUENCES SERIALIZABLE SERVER SESSION SETOF SHARE SIMPLE SMALLINT SNAPSHOT STABLE
        STANDALONE START STATEMENT STATISTICS STORAGE STRICT SYSID SYSTEM TABLESPACE TEMP
        TEMPLATE TRANSACTION TREAT TYPE TYPES UNBOUNDED UNCOMMITTED UNENCRYPTED
        UNKNOWN UNLISTEN UNLOGGED UNTIL VALID VALIDATE VALIDATOR VALUE VARYING VOLATILE
        WHITESPACE WITHOUT WORK WRAPPER XMLATTRIBUTES XMLCONCAT XMLELEMENT XMLEXISTS XMLFOREST XMLPARSE
        XMLPI XMLROOT XMLSERIALIZE YEAR YES ZONE
        );

    for my $k ( @pg_keywords ) {
        next if grep { $k eq $_ } @sql_keywords;
        push @sql_keywords, $k;
    }

    my @pg_functions = map { lc } qw(
        ascii age bit_length btrim char_length character_length convert chr current_date current_time current_timestamp count
        decode date_part date_trunc encode extract get_byte get_bit initcap isfinite interval justify_hours justify_days
        lower length lpad ltrim localtime localtimestamp md5 now octet_length overlay position pg_client_encoding
        quote_ident quote_literal repeat replace rpad rtrim substring split_part strpos substr set_byte set_bit
        trim to_ascii to_hex translate to_char to_date to_timestamp to_number timeofday upper
        abbrev abs abstime abstimeeq abstimege abstimegt abstimein abstimele
        abstimelt abstimene abstimeout abstimerecv abstimesend aclcontains acldefault
        aclexplode aclinsert aclitemeq aclitemin aclitemout aclremove acos
        any_in any_out anyarray_in anyarray_out anyarray_recv anyarray_send anyelement_in
        anyelement_out anyenum_in anyenum_out anynonarray_in anynonarray_out anyrange_in anyrange_out
        anytextcat area areajoinsel areasel armor array_agg array_agg_finalfn
        array_agg_transfn array_append array_cat array_dims array_eq array_fill array_ge
        array_gt array_in array_larger array_le array_length array_lower array_lt
        array_ndims array_ne array_out array_prepend array_recv array_send array_smaller
        array_to_json array_to_string array_typanalyze array_upper arraycontained arraycontains arraycontjoinsel
        arraycontsel arrayoverlap ascii_to_mic ascii_to_utf8 asin atan atan2
        avg big5_to_euc_tw big5_to_mic big5_to_utf8 bit bit_and bit_in
        bit_or bit_out bit_recv bit_send bitand bitcat bitcmp
        biteq bitge bitgt bitle bitlt bitne bitnot
        bitor bitshiftleft bitshiftright bittypmodin bittypmodout bitxor bool
        bool_and bool_or booland_statefunc booleq boolge boolgt boolin
        boolle boollt boolne boolor_statefunc boolout boolrecv boolsend
        box box_above box_above_eq box_add box_below box_below_eq box_center
        box_contain box_contain_pt box_contained box_distance box_div box_eq box_ge
        box_gt box_in box_intersect box_le box_left box_lt box_mul
        box_out box_overabove box_overbelow box_overlap box_overleft box_overright box_recv
        box_right box_same box_send box_sub bpchar bpchar_larger bpchar_pattern_ge
        bpchar_pattern_gt bpchar_pattern_le bpchar_pattern_lt bpchar_smaller bpcharcmp bpchareq bpcharge
        bpchargt bpchariclike bpcharicnlike bpcharicregexeq bpcharicregexne bpcharin bpcharle
        bpcharlike bpcharlt bpcharne bpcharnlike bpcharout bpcharrecv bpcharregexeq
        bpcharregexne bpcharsend bpchartypmodin bpchartypmodout broadcast btabstimecmp btarraycmp
        btbeginscan btboolcmp btbpchar_pattern_cmp btbuild btbuildempty btbulkdelete btcanreturn
        btcharcmp btcostestimate btendscan btfloat48cmp btfloat4cmp btfloat4sortsupport btfloat84cmp
        btfloat8cmp btfloat8sortsupport btgetbitmap btgettuple btinsert btint24cmp btint28cmp
        btint2cmp btint2sortsupport btint42cmp btint48cmp btint4cmp btint4sortsupport btint82cmp
        btint84cmp btint8cmp btint8sortsupport btmarkpos btnamecmp btnamesortsupport btoidcmp
        btoidsortsupport btoidvectorcmp btoptions btrecordcmp btreltimecmp btrescan btrestrpos
        bttext_pattern_cmp bttextcmp bttidcmp bttintervalcmp btvacuumcleanup bytea_string_agg_finalfn bytea_string_agg_transfn
        byteacat byteacmp byteaeq byteage byteagt byteain byteale
        bytealike bytealt byteane byteanlike byteaout bytearecv byteasend
        cash_cmp cash_div_cash cash_div_flt4 cash_div_flt8 cash_div_int2 cash_div_int4 cash_eq
        cash_ge cash_gt cash_in cash_le cash_lt cash_mi cash_mul_flt4
        cash_mul_flt8 cash_mul_int2 cash_mul_int4 cash_ne cash_out cash_pl cash_recv
        cash_send cash_words cashlarger cashsmaller cbrt ceil ceiling
        center char chareq charge chargt charin charle
        charlt charne charout charrecv charsend cideq cidin
        cidout cidr cidr_in cidr_out cidr_recv cidr_send cidrecv
        cidsend circle circle_above circle_add_pt circle_below circle_center circle_contain
        circle_contain_pt circle_contained circle_distance circle_div_pt circle_eq circle_ge circle_gt
        circle_in circle_le circle_left circle_lt circle_mul_pt circle_ne circle_out
        circle_overabove circle_overbelow circle_overlap circle_overleft circle_overright circle_recv circle_right
        circle_same circle_send circle_sub_pt clock_timestamp close_lb close_ls close_lseg
        close_pb close_pl close_ps close_sb close_sl col_description concat
        concat_ws contjoinsel contsel convert_from convert_to corr cos
        cot covar_pop covar_samp crypt cstring_in cstring_out cstring_recv
        cstring_send cume_dist current_database current_query current_schema current_schemas current_setting
        current_user currtid currtid2 currval cursor_to_xml cursor_to_xmlschema database_to_xml
        database_to_xml_and_xmlschema database_to_xmlschema date date_cmp date_cmp_timestamp date_cmp_timestamptz date_eq
        date_eq_timestamp date_eq_timestamptz date_ge date_ge_timestamp date_ge_timestamptz date_gt date_gt_timestamp
        date_gt_timestamptz date_in date_larger date_le date_le_timestamp date_le_timestamptz date_lt
        date_lt_timestamp date_lt_timestamptz date_mi date_mi_interval date_mii date_ne date_ne_timestamp
        date_ne_timestamptz date_out date_pl_interval date_pli date_recv date_send date_smaller
        date_sortsupport daterange daterange_canonical daterange_subdiff datetime_pl datetimetz_pl dcbrt
        dearmor decrypt decrypt_iv degrees dense_rank dexp diagonal
        diameter digest dispell_init dispell_lexize dist_cpoly dist_lb dist_pb
        dist_pc dist_pl dist_ppath dist_ps dist_sb dist_sl div
        dlog1 dlog10 domain_in domain_recv dpow dround dsimple_init
        dsimple_lexize dsnowball_init dsnowball_lexize dsqrt dsynonym_init dsynonym_lexize dtrunc
        elem_contained_by_range encrypt encrypt_iv enum_cmp enum_eq enum_first enum_ge
        enum_gt enum_in enum_larger enum_last enum_le enum_lt enum_ne
        enum_out enum_range enum_recv enum_send enum_smaller eqjoinsel eqsel
        euc_cn_to_mic euc_cn_to_utf8 euc_jis_2004_to_shift_jis_2004 euc_jis_2004_to_utf8 euc_jp_to_mic euc_jp_to_sjis euc_jp_to_utf8
        euc_kr_to_mic euc_kr_to_utf8 euc_tw_to_big5 euc_tw_to_mic euc_tw_to_utf8 every exp
        factorial family fdw_handler_in fdw_handler_out first_value float4 float48div
        float48eq float48ge float48gt float48le float48lt float48mi float48mul
        float48ne float48pl float4_accum float4abs float4div float4eq float4ge
        float4gt float4in float4larger float4le float4lt float4mi float4mul
        float4ne float4out float4pl float4recv float4send float4smaller float4um
        float4up float8 float84div float84eq float84ge float84gt float84le
        float84lt float84mi float84mul float84ne float84pl float8_accum float8_avg
        float8_corr float8_covar_pop float8_covar_samp float8_regr_accum float8_regr_avgx float8_regr_avgy float8_regr_intercept
        float8_regr_r2 float8_regr_slope float8_regr_sxx float8_regr_sxy float8_regr_syy float8_stddev_pop float8_stddev_samp
        float8_var_pop float8_var_samp float8abs float8div float8eq float8ge float8gt
        float8in float8larger float8le float8lt float8mi float8mul float8ne
        float8out float8pl float8recv float8send float8smaller float8um float8up
        floor flt4_mul_cash flt8_mul_cash fmgr_c_validator fmgr_internal_validator fmgr_sql_validator format
        format_type gb18030_to_utf8 gbk_to_utf8 gen_random_bytes gen_salt generate_series generate_subscripts
        get_current_ts_config getdatabaseencoding getpgusername gin_cmp_prefix gin_cmp_tslexeme gin_extract_tsquery gin_extract_tsvector
        gin_tsquery_consistent ginarrayconsistent ginarrayextract ginbeginscan ginbuild ginbuildempty ginbulkdelete
        gincostestimate ginendscan gingetbitmap gininsert ginmarkpos ginoptions ginqueryarrayextract
        ginrescan ginrestrpos ginvacuumcleanup gist_box_compress gist_box_consistent gist_box_decompress gist_box_penalty
        gist_box_picksplit gist_box_same gist_box_union gist_circle_compress gist_circle_consistent gist_point_compress gist_point_consistent
        gist_point_distance gist_poly_compress gist_poly_consistent gistbeginscan gistbuild gistbuildempty gistbulkdelete
        gistcostestimate gistendscan gistgetbitmap gistgettuple gistinsert gistmarkpos gistoptions
        gistrescan gistrestrpos gistvacuumcleanup gtsquery_compress gtsquery_consistent gtsquery_decompress gtsquery_penalty
        gtsquery_picksplit gtsquery_same gtsquery_union gtsvector_compress gtsvector_consistent gtsvector_decompress gtsvector_penalty
        gtsvector_picksplit gtsvector_same gtsvector_union gtsvectorin gtsvectorout has_any_column_privilege has_column_privilege
        has_database_privilege has_foreign_data_wrapper_privilege has_function_privilege has_language_privilege has_schema_privilege
        has_sequence_privilege has_server_privilege has_table_privilege has_tablespace_privilege has_type_privilege hash_aclitem
        hash_array hash_numeric hash_range hashbeginscan hashbpchar hashbuild hashbuildempty hashbulkdelete hashchar hashcostestimate
        hashendscan hashenum hashfloat4 hashfloat8 hashgetbitmap hashgettuple hashinet
        hashinsert hashint2 hashint2vector hashint4 hashint8 hashmacaddr hashmarkpos
        hashname hashoid hashoidvector hashoptions hashrescan hashrestrpos hashtext
        hashvacuumcleanup hashvarlena height hmac host hostmask iclikejoinsel
        iclikesel icnlikejoinsel icnlikesel icregexeqjoinsel icregexeqsel icregexnejoinsel icregexnesel
        inet_client_addr inet_client_port inet_in inet_out inet_recv inet_send inet_server_addr
        inet_server_port inetand inetmi inetmi_int8 inetnot inetor inetpl
        int2 int24div int24eq int24ge int24gt int24le int24lt
        int24mi int24mul int24ne int24pl int28div int28eq int28ge
        int28gt int28le int28lt int28mi int28mul int28ne int28pl
        int2_accum int2_avg_accum int2_mul_cash int2_sum int2abs int2and int2div
        int2eq int2ge int2gt int2in int2larger int2le int2lt
        int2mi int2mod int2mul int2ne int2not int2or int2out
        int2pl int2recv int2send int2shl int2shr int2smaller int2um
        int2up int2vectoreq int2vectorin int2vectorout int2vectorrecv int2vectorsend int2xor
        int4 int42div int42eq int42ge int42gt int42le int42lt
        int42mi int42mul int42ne int42pl int48div int48eq int48ge
        int48gt int48le int48lt int48mi int48mul int48ne int48pl
        int4_accum int4_avg_accum int4_mul_cash int4_sum int4abs int4and int4div
        int4eq int4ge int4gt int4in int4inc int4larger int4le
        int4lt int4mi int4mod int4mul int4ne int4not int4or
        int4out int4pl int4range int4range_canonical int4range_subdiff int4recv int4send
        int4shl int4shr int4smaller int4um int4up int4xor int8
        int82div int82eq int82ge int82gt int82le int82lt int82mi
        int82mul int82ne int82pl int84div int84eq int84ge int84gt
        int84le int84lt int84mi int84mul int84ne int84pl int8_accum
        int8_avg int8_avg_accum int8_sum int8abs int8and int8div int8eq
        int8ge int8gt int8in int8inc int8inc_any int8inc_float8_float8 int8larger
        int8le int8lt int8mi int8mod int8mul int8ne int8not
        int8or int8out int8pl int8pl_inet int8range int8range_canonical int8range_subdiff
        int8recv int8send int8shl int8shr int8smaller int8um int8up
        int8xor integer_pl_date inter_lb inter_sb inter_sl internal_in internal_out
        interval_accum interval_avg interval_cmp interval_div interval_eq interval_ge interval_gt
        interval_hash interval_in interval_larger interval_le interval_lt interval_mi interval_mul
        interval_ne interval_out interval_pl interval_pl_date interval_pl_time interval_pl_timestamp interval_pl_timestamptz
        interval_pl_timetz interval_recv interval_send interval_smaller interval_transform interval_um intervaltypmodin
        intervaltypmodout intinterval isclosed isempty ishorizontal iso8859_1_to_utf8 iso8859_to_utf8
        iso_to_koi8r iso_to_mic iso_to_win1251 iso_to_win866 isopen isparallel isperp
        isvertical johab_to_utf8 json_array_elements jsonb_array_elements json_array_elements_text jsonb_array_elements_text
        json_array_length jsonb_array_length json_build_array json_build_object json_each jsonb_each json_each_text
        jsonb_each_text json_extract_path jsonb_extract_path json_extract_path_text jsonb_extract_path_text json_in json_object
        json_object_keys jsonb_object_keys json_out json_populate_record jsonb_populate_record json_populate_recordset jsonb_pretty
        jsonb_populate_recordset json_recv json_send jsonb_set json_typeof jsonb_typeof json_to_record jsonb_to_record json_to_recordset
        jsonb_to_recordset justify_interval koi8r_to_iso koi8r_to_mic koi8r_to_utf8 koi8r_to_win1251 koi8r_to_win866 koi8u_to_utf8
        lag language_handler_in language_handler_out last_value lastval latin1_to_mic latin2_to_mic latin2_to_win1250
        latin3_to_mic latin4_to_mic lead like_escape likejoinsel
        likesel line line_distance line_eq line_horizontal line_in line_interpt
        line_intersect line_out line_parallel line_perp line_recv line_send line_vertical
        ln lo_close lo_creat lo_create lo_export lo_import lo_lseek
        lo_open lo_tell lo_truncate lo_unlink log loread lower_inc
        lower_inf lowrite lseg lseg_center lseg_distance lseg_eq lseg_ge
        lseg_gt lseg_horizontal lseg_in lseg_interpt lseg_intersect lseg_le lseg_length
        lseg_lt lseg_ne lseg_out lseg_parallel lseg_perp lseg_recv lseg_send
        lseg_vertical macaddr_and macaddr_cmp macaddr_eq macaddr_ge macaddr_gt macaddr_in
        macaddr_le macaddr_lt macaddr_ne macaddr_not macaddr_or macaddr_out macaddr_recv
        macaddr_send makeaclitem masklen max mic_to_ascii mic_to_big5 mic_to_euc_cn
        mic_to_euc_jp mic_to_euc_kr mic_to_euc_tw mic_to_iso mic_to_koi8r mic_to_latin1 mic_to_latin2
        mic_to_latin3 mic_to_latin4 mic_to_sjis mic_to_win1250 mic_to_win1251 mic_to_win866 min
        mktinterval mod money mul_d_interval name nameeq namege
        namegt nameiclike nameicnlike nameicregexeq nameicregexne namein namele
        namelike namelt namene namenlike nameout namerecv nameregexeq
        nameregexne namesend neqjoinsel neqsel netmask network network_cmp
        network_eq network_ge network_gt network_le network_lt network_ne network_sub
        network_subeq network_sup network_supeq nextval nlikejoinsel nlikesel notlike
        npoints nth_value ntile numeric numeric_abs numeric_accum numeric_add
        numeric_avg numeric_avg_accum numeric_cmp numeric_div numeric_div_trunc numeric_eq numeric_exp
        numeric_fac numeric_ge numeric_gt numeric_in numeric_inc numeric_larger numeric_le
        numeric_ln numeric_log numeric_lt numeric_mod numeric_mul numeric_ne numeric_out
        numeric_power numeric_recv numeric_send numeric_smaller numeric_sqrt numeric_stddev_pop numeric_stddev_samp
        numeric_sub numeric_transform numeric_uminus numeric_uplus numeric_var_pop numeric_var_samp numerictypmodin
        numerictypmodout numnode numrange numrange_subdiff obj_description oid oideq
        oidge oidgt oidin oidlarger oidle oidlt oidne
        oidout oidrecv oidsend oidsmaller oidvectoreq oidvectorge oidvectorgt
        oidvectorin oidvectorle oidvectorlt oidvectorne oidvectorout oidvectorrecv oidvectorsend
        oidvectortypes on_pb on_pl on_ppath on_ps on_sb on_sl
        opaque_in opaque_out overlaps path path_add path_add_pt path_center
        path_contain_pt path_distance path_div_pt path_in path_inter path_length path_mul_pt
        path_n_eq path_n_ge path_n_gt path_n_le path_n_lt path_npoints path_out
        path_recv path_send path_sub_pt pclose percent_rank pg_advisory_lock pg_advisory_lock_shared
        pg_advisory_unlock pg_advisory_unlock_all pg_advisory_unlock_shared pg_advisory_xact_lock pg_advisory_xact_lock_shared
        pg_available_extension_versions pg_available_extensions pg_backend_pid pg_cancel_backend pg_char_to_encoding pg_collation_for
        pg_collation_is_visible pg_column_size pg_conf_load_time pg_conversion_is_visible pg_create_restore_point pg_current_xlog_insert_location
        pg_current_xlog_location pg_cursor pg_database_size pg_describe_object pg_encoding_max_length pg_encoding_to_char pg_export_snapshot
        pg_extension_config_dump pg_extension_update_paths pg_function_is_visible pg_get_constraintdef pg_get_expr pg_get_function_arguments
        pg_get_function_identity_arguments pg_get_function_result pg_get_functiondef pg_get_indexdef pg_get_keywords
        pg_get_ruledef pg_get_serial_sequence pg_get_triggerdef pg_get_userbyid pg_get_viewdef pg_has_role pg_indexes_size
        pg_is_in_recovery pg_is_other_temp_schema pg_is_xlog_replay_paused pg_last_xact_replay_timestamp pg_last_xlog_receive_location
        pg_last_xlog_replay_location pg_listening_channels pg_lock_status pg_ls_dir pg_my_temp_schema pg_node_tree_in pg_node_tree_out
        pg_node_tree_recv pg_node_tree_send pg_notify pg_opclass_is_visible pg_operator_is_visible pg_opfamily_is_visible pg_options_to_table
        pg_postmaster_start_time pg_prepared_statement pg_prepared_xact pg_read_binary_file pg_read_file pg_relation_filenode pg_relation_filepath
        pg_relation_size pg_reload_conf pg_rotate_logfile pg_sequence_parameters pg_show_all_settings pg_size_pretty pg_sleep pg_start_backup
        pg_stat_clear_snapshot pg_stat_file pg_stat_get_activity pg_stat_get_analyze_count pg_stat_get_autoanalyze_count pg_stat_get_autovacuum_count
        pg_stat_get_backend_activity pg_stat_get_backend_activity_start pg_stat_get_backend_client_addr pg_stat_get_backend_client_port
        pg_stat_get_backend_dbid pg_stat_get_backend_idset pg_stat_get_backend_pid pg_stat_get_backend_start pg_stat_get_backend_userid
        pg_stat_get_backend_waiting pg_stat_get_backend_xact_start pg_stat_get_bgwriter_buf_written_checkpoints pg_stat_get_bgwriter_buf_written_clean
        pg_stat_get_bgwriter_maxwritten_clean pg_stat_get_bgwriter_requested_checkpoints pg_stat_get_bgwriter_stat_reset_time
        pg_stat_get_bgwriter_timed_checkpoints pg_stat_get_blocks_fetched pg_stat_get_blocks_hit pg_stat_get_buf_alloc pg_stat_get_buf_fsync_backend
        pg_stat_get_buf_written_backend pg_stat_get_checkpoint_sync_time pg_stat_get_checkpoint_write_time pg_stat_get_db_blk_read_time
        pg_stat_get_db_blk_write_time pg_stat_get_db_blocks_fetched pg_stat_get_db_blocks_hit pg_stat_get_db_conflict_all pg_stat_get_db_conflict_bufferpin
        pg_stat_get_db_conflict_lock pg_stat_get_db_conflict_snapshot pg_stat_get_db_conflict_startup_deadlock pg_stat_get_db_conflict_tablespace
        pg_stat_get_db_deadlocks pg_stat_get_db_numbackends pg_stat_get_db_stat_reset_time pg_stat_get_db_temp_bytes pg_stat_get_db_temp_files
        pg_stat_get_db_tuples_deleted pg_stat_get_db_tuples_fetched pg_stat_get_db_tuples_inserted pg_stat_get_db_tuples_returned pg_stat_get_db_tuples_updated
        pg_stat_get_db_xact_commit pg_stat_get_db_xact_rollback pg_stat_get_dead_tuples pg_stat_get_function_calls pg_stat_get_function_self_time
        pg_stat_get_function_total_time pg_stat_get_last_analyze_time pg_stat_get_last_autoanalyze_time pg_stat_get_last_autovacuum_time
        pg_stat_get_last_vacuum_time pg_stat_get_live_tuples pg_stat_get_numscans pg_stat_get_tuples_deleted pg_stat_get_tuples_fetched
        pg_stat_get_tuples_hot_updated pg_stat_get_tuples_inserted pg_stat_get_tuples_returned pg_stat_get_tuples_updated pg_stat_get_vacuum_count
        pg_stat_get_wal_senders pg_stat_get_xact_blocks_fetched pg_stat_get_xact_blocks_hit pg_stat_get_xact_function_calls pg_stat_get_xact_function_self_time
        pg_stat_get_xact_function_total_time pg_stat_get_xact_numscans pg_stat_get_xact_tuples_deleted pg_stat_get_xact_tuples_fetched
        pg_stat_get_xact_tuples_hot_updated pg_stat_get_xact_tuples_inserted pg_stat_get_xact_tuples_returned pg_stat_get_xact_tuples_updated pg_stat_reset
        pg_stat_reset_shared pg_stat_reset_single_function_counters pg_stat_reset_single_table_counters pg_stop_backup pg_switch_xlog pg_table_is_visible
        pg_table_size pg_tablespace_databases pg_tablespace_location pg_tablespace_size pg_terminate_backend pg_timezone_abbrevs pg_timezone_names
        pg_total_relation_size pg_trigger_depth pg_try_advisory_lock pg_try_advisory_lock_shared pg_try_advisory_xact_lock pg_try_advisory_xact_lock_shared
        pg_ts_config_is_visible pg_ts_dict_is_visible pg_ts_parser_is_visible pg_ts_template_is_visible
        pg_type_is_visible pg_typeof pg_xact_commit_timestamp pg_last_committed_xact pg_xlog_location_diff pg_xlog_replay_pause pg_xlog_replay_resume pg_xlogfile_name pg_xlogfile_name_offset
        pgp_key_id pgp_pub_decrypt pgp_pub_decrypt_bytea pgp_pub_encrypt pgp_pub_encrypt_bytea pgp_sym_decrypt pgp_sym_decrypt_bytea
        pgp_sym_encrypt pgp_sym_encrypt_bytea pi plainto_tsquery plpgsql_call_handler plpgsql_inline_handler plpgsql_validator
        point point_above point_add point_below point_distance point_div point_eq
        point_horiz point_in point_left point_mul point_ne point_out point_recv
        point_right point_send point_sub point_vert poly_above poly_below poly_center
        poly_contain poly_contain_pt poly_contained poly_distance poly_in poly_left poly_npoints
        poly_out poly_overabove poly_overbelow poly_overlap poly_overleft poly_overright poly_recv
        poly_right poly_same poly_send polygon popen positionjoinsel positionsel
        postgresql_fdw_validator pow power prsd_end prsd_headline prsd_lextype prsd_nexttoken
        prsd_start pt_contained_circle pt_contained_poly query_to_xml query_to_xml_and_xmlschema query_to_xmlschema querytree
        quote_nullable radians radius random range_adjacent range_after range_before
        range_cmp range_contained_by range_contains range_contains_elem range_eq range_ge range_gist_compress
        range_gist_consistent range_gist_decompress range_gist_penalty range_gist_picksplit range_gist_same range_gist_union range_gt
        range_in range_intersect range_le range_lt range_minus range_ne range_out
        range_overlaps range_overleft range_overright range_recv range_send range_typanalyze range_union
        rank record_eq record_ge record_gt record_in record_le record_lt
        record_ne record_out record_recv record_send regclass regclassin regclassout
        regclassrecv regclasssend regconfigin regconfigout regconfigrecv regconfigsend regdictionaryin
        regdictionaryout regdictionaryrecv regdictionarysend regexeqjoinsel regexeqsel regexnejoinsel regexnesel
        regexp_matches regexp_replace regexp_split_to_array regexp_split_to_table regoperatorin regoperatorout regoperatorrecv
        regoperatorsend regoperin regoperout regoperrecv regopersend regprocedurein regprocedureout
        regprocedurerecv regproceduresend regprocin regprocout regprocrecv regprocsend regr_avgx
        regr_avgy regr_count regr_intercept regr_r2 regr_slope regr_sxx regr_sxy
        regr_syy regtypein regtypeout regtyperecv regtypesend reltime reltimeeq
        reltimege reltimegt reltimein reltimele reltimelt reltimene reltimeout
        reltimerecv reltimesend reverse round row_number row_to_json
        scalargtjoinsel scalargtsel scalarltjoinsel scalarltsel schema_to_xml schema_to_xml_and_xmlschema schema_to_xmlschema
        session_user set_config set_masklen setseed setval setweight shell_in
        shell_out shift_jis_2004_to_euc_jis_2004 shift_jis_2004_to_utf8 shobj_description sign similar_escape sin
        sjis_to_euc_jp sjis_to_mic sjis_to_utf8 slope smgreq smgrin smgrne
        smgrout spg_kd_choose spg_kd_config spg_kd_inner_consistent spg_kd_picksplit spg_quad_choose spg_quad_config
        spg_quad_inner_consistent spg_quad_leaf_consistent spg_quad_picksplit spg_text_choose spg_text_config spg_text_inner_consistent spg_text_leaf_consistent
        spg_text_picksplit spgbeginscan spgbuild spgbuildempty spgbulkdelete spgcanreturn spgcostestimate
        spgendscan spggetbitmap spggettuple spginsert spgmarkpos spgoptions spgrescan
        spgrestrpos spgvacuumcleanup sqrt statement_timestamp stddev stddev_pop stddev_samp
        string_agg string_agg_finalfn string_agg_transfn string_to_array strip sum table_to_xml
        table_to_xml_and_xmlschema table_to_xmlschema tan text text_ge text_gt text_larger
        text_le text_lt text_pattern_ge text_pattern_gt text_pattern_le text_pattern_lt text_smaller
        textanycat textcat texteq texticlike texticnlike texticregexeq texticregexne
        textin textlen textlike textne textnlike textout textrecv
        textregexeq textregexne textsend thesaurus_init thesaurus_lexize tideq tidge
        tidgt tidin tidlarger tidle tidlt tidne tidout
        tidrecv tidsend tidsmaller time time_cmp time_eq time_ge
        time_gt time_hash time_in time_larger time_le time_lt time_mi_interval
        time_mi_time time_ne time_out time_pl_interval time_recv time_send time_smaller
        time_transform timedate_pl timemi timenow timepl timestamp timestamp_cmp
        timestamp_cmp_date timestamp_cmp_timestamptz timestamp_eq timestamp_eq_date timestamp_eq_timestamptz timestamp_ge timestamp_ge_date
        timestamp_ge_timestamptz timestamp_gt timestamp_gt_date timestamp_gt_timestamptz timestamp_hash timestamp_in timestamp_larger
        timestamp_le timestamp_le_date timestamp_le_timestamptz timestamp_lt timestamp_lt_date timestamp_lt_timestamptz timestamp_mi
        timestamp_mi_interval timestamp_ne timestamp_ne_date timestamp_ne_timestamptz timestamp_out timestamp_pl_interval timestamp_recv
        timestamp_send timestamp_smaller timestamp_sortsupport timestamp_transform timestamptypmodin timestamptypmodout timestamptz
        timestamptz_cmp timestamptz_cmp_date timestamptz_cmp_timestamp timestamptz_eq timestamptz_eq_date timestamptz_eq_timestamp timestamptz_ge
        timestamptz_ge_date timestamptz_ge_timestamp timestamptz_gt timestamptz_gt_date timestamptz_gt_timestamp timestamptz_in timestamptz_larger
        timestamptz_le timestamptz_le_date timestamptz_le_timestamp timestamptz_lt timestamptz_lt_date timestamptz_lt_timestamp timestamptz_mi
        timestamptz_mi_interval timestamptz_ne timestamptz_ne_date timestamptz_ne_timestamp timestamptz_out timestamptz_pl_interval timestamptz_recv
        timestamptz_send timestamptz_smaller timestamptztypmodin timestamptztypmodout timetypmodin timetypmodout timetz
        timetz_cmp timetz_eq timetz_ge timetz_gt timetz_hash timetz_in timetz_larger
        timetz_le timetz_lt timetz_mi_interval timetz_ne timetz_out timetz_pl_interval timetz_recv
        timetz_send timetz_smaller timetzdate_pl timetztypmodin timetztypmodout timezone tinterval
        tintervalct tintervalend tintervaleq tintervalge tintervalgt tintervalin tintervalle
        tintervalleneq tintervallenge tintervallengt tintervallenle tintervallenlt tintervallenne tintervallt
        tintervalne tintervalout tintervalov tintervalrecv tintervalrel tintervalsame tintervalsend
        tintervalstart to_json to_tsquery to_tsvector transaction_timestamp trigger_out trunc ts_debug
        ts_headline ts_lexize ts_match_qv ts_match_tq ts_match_tt ts_match_vq ts_parse
        ts_rank ts_rank_cd ts_rewrite ts_stat ts_token_type ts_typanalyze tsmatchjoinsel
        tsmatchsel tsq_mcontained tsq_mcontains tsquery_and tsquery_cmp tsquery_eq tsquery_ge
        tsquery_gt tsquery_le tsquery_lt tsquery_ne tsquery_not tsquery_or tsqueryin
        tsqueryout tsqueryrecv tsquerysend tsrange tsrange_subdiff tstzrange tstzrange_subdiff
        tsvector_cmp tsvector_concat tsvector_eq tsvector_ge tsvector_gt tsvector_le tsvector_lt
        tsvector_ne tsvectorin tsvectorout tsvectorrecv tsvectorsend txid_current txid_current_snapshot
        txid_snapshot_in txid_snapshot_out txid_snapshot_recv txid_snapshot_send txid_snapshot_xip txid_snapshot_xmax txid_snapshot_xmin
        txid_visible_in_snapshot uhc_to_utf8 unknownin unknownout unknownrecv unknownsend unnest
        upper_inc upper_inf utf8_to_ascii utf8_to_big5 utf8_to_euc_cn utf8_to_euc_jis_2004 utf8_to_euc_jp
        utf8_to_euc_kr utf8_to_euc_tw utf8_to_gb18030 utf8_to_gbk utf8_to_iso8859 utf8_to_iso8859_1 utf8_to_johab
        utf8_to_koi8r utf8_to_koi8u utf8_to_shift_jis_2004 utf8_to_sjis utf8_to_uhc utf8_to_win uuid_cmp
        uuid_eq uuid_ge uuid_gt uuid_hash uuid_in uuid_le uuid_lt
        uuid_ne uuid_out uuid_recv uuid_send var_pop var_samp varbit
        varbit_in varbit_out varbit_recv varbit_send varbit_transform varbitcmp varbiteq
        varbitge varbitgt varbitle varbitlt varbitne varbittypmodin varbittypmodout
        varchar varchar_transform varcharin varcharout varcharrecv varcharsend varchartypmodin
        varchartypmodout variance version void_in void_out void_recv void_send
        width width_bucket win1250_to_latin2 win1250_to_mic win1251_to_iso win1251_to_koi8r win1251_to_mic
        win1251_to_win866 win866_to_iso win866_to_koi8r win866_to_mic win866_to_win1251 win_to_utf8 xideq
        xideqint4 xidin xidout xidrecv xidsend xml xml_in
        xml_is_well_formed xml_is_well_formed_content xml_is_well_formed_document xml_out xml_recv xml_send xmlagg
        );

    my @copy_keywords = ( 'STDIN', 'STDOUT' );

    my %symbols = (
        '='  => '=', '<'  => '&lt;', '>'  => '&gt;', '\|' => '|', ',' => ',', '\.' => '.', '\+' => '+', '\-' => '-',
        '\*' => '*', '\/' => '/',    '!=' => '!=', '\%' => '%'
    );

    my @brackets = ( '(', ')' );

    # All setting and modification of dicts is done, can set them now to $self->{'dict'}->{...}
    $self->{ 'dict' }->{ 'pg_keywords' }   = \@pg_keywords;
    $self->{ 'dict' }->{ 'sql_keywords' }  = \@sql_keywords;
    $self->{ 'dict' }->{ 'pg_functions' }  = \@pg_functions;
    $self->{ 'dict' }->{ 'copy_keywords' } = \@copy_keywords;
    $self->{ 'dict' }->{ 'symbols' }       = \%symbols;
    $self->{ 'dict' }->{ 'brackets' }      = \@brackets;
    return;
}

=head1 AUTHOR

pgFormatter is an original work from Gilles Darold

=head1 BUGS

Please report any bugs or feature requests to: https://github.com/darold/pgFormatter/issues

=head1 COPYRIGHT

Copyright 2012-2017 Gilles Darold. All rights reserved.

=head1 LICENSE

pgFormatter is free software distributed under the PostgreSQL Licence.

A modified version of the SQL::Beautify Perl Module is embedded in pgFormatter
with copyright (C) 2009 by Jonas Kramer and is published under the terms of
the Artistic License 2.0.

=cut

1;
