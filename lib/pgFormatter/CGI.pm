package pgFormatter::CGI;

use strict;
use warnings;
use warnings qw( FATAL );
use Encode qw( decode );

=head1 NAME

pgFormatter::CGI - Implementation of CGI-BIN script to format SQL queries.

=head1 VERSION

Version 5.2

=cut

# Version of pgFormatter
our $VERSION = '5.2';

use pgFormatter::Beautify;
use File::Basename;
use CGI;

=head1 SYNOPSIS

This module is called by pg_format program, when it detects it is run in CGI
environment. In such case all control over flow is passed to this module by
calling:

    my $program = pgFormatter::CGI->new();
    $program->run()

=head1 FUNCTIONS

=head2 new

Object constructor, calls L<set_config> method to set default values for
various parameters.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->set_config();
    return $self;
}

=head2 run

Wraps all work related to generating html page.

It calls set of functions to get CGI object, receive parameters from
request, sanitize them, beautify query (if provided) and print ghtml.

=cut

sub run {
    my $self = shift;
    $self->get_cgi();
    $self->get_params();
    $self->sanitize_params();
    $self->print_headers();
    $self->beautify_query();
    $self->print_body();
    $self->print_footer();
    return;
}

=head2 get_cgi

Creates CGI object, and sets POST size limit

=cut

sub get_cgi {
    my $self = shift;
    $self->{ 'cgi' } = CGI->new();
    $CGI::POST_MAX = $self->{ 'maxlength' };
    return;
}

=head2

Sets config for the page and beautifier. URLs, names of auxiliary files,
configuration for pgFormatter::Beautify module.

=cut

sub set_config {
    my $self = shift;

    $self->{ 'program_name' } = 'pgFormatter';
    $self->{ 'program_name' } =~ s/\.[^\.]+$//;
    $self->{ 'config' }       = 'pg_format.conf';

    # Maximum code size that can be formatted
    $self->{ 'maxlength' }    = 100000;

    # Set default settings
    $self->{ 'outfile' }      = '';
    $self->{ 'outdir' }       = '';
    $self->{ 'help' }         = '';
    $self->{ 'version' }      = '';
    $self->{ 'debug' }        = 0;
    $self->{ 'content' }      = '';
    $self->{ 'original_content' }      = '';
    $self->{ 'show_example' } = 0;
    $self->{ 'project_url' }  = 'https://github.com/darold/pgFormatter';
    $self->{ 'service_url' }  = '';
    $self->{ 'download_url' } = 'https://github.com/darold/pgFormatter/releases';

    if (-f $self->{ 'config' })
    {
	open(my $cfh, '<', $self->{ 'config' }) or die "ERROR: can not read file $self->{ 'config' }\n";
	while (my $line = <$cfh>)
	{
	    chomp($line);
	    next if ($line !~ /^[a-z]/);
	    if ($line =~ /^([^\s=]+)\s*=\s*([^\s]+)/)
	    {
		my $key = lc($1);
		my $val = $2;
		$key =~ s/-/_/g;
		$key = 'uc_keyword'  if ($key eq 'keyword_case');
		$key = 'uc_function' if ($key eq 'function_case');
		$key = 'uc_type'     if ($key eq 'type_case');
		if ($key eq 'comma' || $key eq 'format') {
		    $self->{$key} = lc($val);
		} else {
		    $self->{$key} = $val;
	        }
	    }
	}
    }

    $self->{ 'spaces' }       //= 4;
    $self->{ 'nocomment' }    //= 0;
    $self->{ 'nogrouping' }   //= 0;
    $self->{ 'uc_keyword' }   //= 2;
    $self->{ 'uc_function' }  //= 0;
    $self->{ 'uc_type' }      //= 1;
    $self->{ 'anonymize' }    //= 0;
    $self->{ 'separator' }    //= '';
    $self->{ 'comma' }        //= 'end';
    $self->{ 'format' }       //= 'html';
    $self->{ 'comma_break' }  //= 0;
    $self->{ 'format_type' }  //= 0;
    $self->{ 'wrap_after' }   //= 0;
    $self->{ 'numbering' }    //= 0;
    $self->{ 'redshift' }     //= 0;
    $self->{ 'colorize' }     //= 1;
    $self->{ 'keep_newline' } //= 0;
    $self->{ 'extra_function' }//= '';

    if ($self->{ 'tabs' })
    {
        $self->{ 'spaces' } = 1;
        $self->{ 'space' }  = "\t";
    }

    if (!grep(/^$self->{ 'comma' }$/i, 'end', 'start'))
    {
        print STDERR "FATAL: unknow value for comma: $self->{ 'comma' }\n";
        exit 0;
    }

    if (!grep(/^$self->{ 'format' }$/i, 'text', 'html'))
    {
        print STDERR "FATAL: unknow output format: $self->{ 'format' }\n";
        exit 0;
    }

    if ( $self->{ 'extra_function' } && !-e $self->{ 'extra_function' }) {
        print STDERR "FATAL: file for extra function list does not exists: $self->{ 'extra_function' }\n";
        exit 0;
    }

    # Filename to load tracker and ad to be included respectively in the
    # HTML head and the bottom of the HTML page.
    $self->{ 'bottom_ad_file' }  = 'bottom_ad_file.txt';
    $self->{ 'head_track_file' } = 'head_track_file.txt';
    # CSS file to load if exists to override default style
    $self->{ 'css_file' }        = 'custom_css_file.css';

    return;
}

=head2

Loads, and returns, default CSS from __DATA__.

=cut

sub default_styles {
    my $shift;
    local $/;
    my $style = <DATA>;
    return $style;
}

=head2

Gets values of parameters, and possibly uploaded file from CGI object to
structures in $self.

=cut

sub get_params {
    my $self = shift;

    return unless $self->{ 'cgi' }->param;

    # shortcut
    my $cgi = $self->{ 'cgi' };

    for my $param_name ( qw( colorize spaces uc_keyword uc_function uc_type content nocomment nogrouping show_example anonymize separator comma comma_break format_type wrap_after original_content numbering redshifti keep_newline) ) {
        $self->{ $param_name } = $cgi->param( $param_name ) if defined $cgi->param( $param_name );
    }

    my $filename = $cgi->param( 'filetoload' );
    return unless $filename;

    my $type = $cgi->uploadInfo( $filename )->{ 'Content-Type' };
    if ( $type eq 'text/plain' || $type eq 'text/x-sql' || $type eq 'application/sql' || $type eq 'application/octet-stream') {
        local $/ = undef;
        my $fh = $cgi->upload( 'filetoload' );
	my $tmpfilename = $cgi->tmpFileName( $fh );
	if (!-T $tmpfilename) {
		$self->{ 'colorize' }   = 0;
		$self->{ 'uc_keyword' } = 0;
		$self->{ 'uc_function' }= 0;
		$self->{ 'uc_type' }    = 0;
		$self->{ 'content' }    = "FATAL: Only text files are supported! Found content-type: $type";
	} else {
		binmode $fh;
		$self->{ 'content' } = <$fh>; 
	}
    }
    else {
        $self->{ 'colorize' }   = 0;
        $self->{ 'uc_keyword' } = 0;
	$self->{ 'uc_function' }= 0;
	$self->{ 'uc_type' }    = 0;
        $self->{ 'content' }    = "FATAL: Only text files are supported! Found content-type: $type";
    }

    return;
}

=head2 sanitize_params

Overrides parameter values if given values were not within acceptable ranges.

=cut

sub sanitize_params {
    my $self = shift;
    $self->{ 'colorize' }     = 1 if $self->{ 'colorize' } !~ /^(0|1)$/;
    $self->{ 'spaces' }       = 4 if $self->{ 'spaces' } !~ /^\d{1,2}$/;
    $self->{ 'uc_keyword' }   = 2 if $self->{ 'uc_keyword' } && ( $self->{ 'uc_keyword' } !~ /^(0|1|2|3)$/ );
    $self->{ 'uc_function' }  = 0 if $self->{ 'uc_function' } && ( $self->{ 'uc_function' } !~ /^(0|1|2|3)$/ );
    $self->{ 'uc_type' }      = 1 if $self->{ 'uc_type' } && ( $self->{ 'uc_type' } !~ /^(0|1|2|3)$/ );
    $self->{ 'nocomment' }    = 0 if $self->{ 'nocomment' } !~ /^(0|1)$/;
    $self->{ 'nogrouping' }   = 0 if $self->{ 'nogrouping' } !~ /^(0|1)$/;
    $self->{ 'show_example' } = 0 if $self->{ 'show_example' } !~ /^(0|1)$/;
    $self->{ 'separator' }    = '' if ($self->{ 'separator' } eq "'" or length($self->{ 'separator' }) > 6);
    $self->{ 'comma' }        = 'end' if ($self->{ 'comma' } ne 'start');
    $self->{ 'comma_break' }  = 0 if ($self->{ 'comma_break' } !~ /^(0|1)$/);
    $self->{ 'format_type' }  = 0 if ($self->{ 'format_type' } !~ /^(0|1)$/);
    $self->{ 'wrap_after' }   = 0 if ($self->{ 'wrap_after' } !~ /^\d{1,2}$/);
    $self->{ 'numbering' }    = 0 if ($self->{ 'numbering' } !~ /^\d{1,2}$/);
    $self->{ 'redshift' }     = 0 if $self->{ 'redshift' } !~ /^(0|1)$/;
    $self->{ 'keep_newline' }   = 0 if $self->{ 'keep_newline' } !~ /^(0|1)$/;

    if ( $self->{ 'show_example' } ) {
        $self->{ 'content' } = q{
SELECT DISTINCT (current_database())::information_schema.sql_identifier AS view_catalog, (nv.nspname)::information_schema.sql_identifier AS view_schema, (v.relname)::information_schema.sql_identifier AS view_name, (current_database())::information_schema.sql_identifier AS table_catalog, (nt.nspname)::information_schema.sql_identifier AS table_schema, (t.relname)::information_schema.sql_identifier AS table_name FROM pg_namespace nv, pg_class v, pg_depend dv, pg_depend dt, pg_class t, pg_namespace nt WHERE ((((((((((((((nv.oid = v.relnamespace) AND (v.relkind = 'v'::"char")) AND (v.oid = dv.refobjid)) AND (dv.refclassid = ('pg_class'::regclass)::oid)) AND (dv.classid = ('pg_rewrite'::regclass)::oid)) AND (dv.deptype = 'i'::"char")) AND (dv.objid = dt.objid)) AND (dv.refobjid <> dt.refobjid)) AND (dt.classid = ('pg_rewrite'::regclass)::oid)) AND (dt.refclassid = ('pg_class'::regclass)::oid)) AND (dt.refobjid = t.oid)) AND (t.relnamespace = nt.oid)) AND (t.relkind = ANY (ARRAY['r'::"char", 'v'::"char"]))) AND pg_has_role(t.relowner, 'USAGE'::text)) ORDER BY (current_database())::information_schema.sql_identifier, (nv.nspname)::information_schema.sql_identifier, (v.relname)::information_schema.sql_identifier, (current_database())::information_schema.sql_identifier, (nt.nspname)::information_schema.sql_identifier, (t.relname)::information_schema.sql_identifier;
        };
	$self->{ 'original_content' } = $self->{ 'content' };
    }

    if (!$self->{ 'original_content' })
    {
	    $self->{ 'original_content' } = $self->{ 'content' };
    }
    else {
	    $self->{ 'content' } = $self->{ 'original_content' };
    }

    $self->{ 'content' } = substr( $self->{ 'content' }, 0, $self->{ 'maxlength' } );
    return;
}

=head2 beautify_query

Runs beautification on provided query, and stores new version in $self->{'content'}

=cut

sub beautify_query {
    my $self = shift;
    return if $self->{ 'show_example' };
    return unless $self->{ 'content' };
    my %args;
    $args{ 'no_comments' }  = 1 if $self->{ 'nocomment' };
    $args{ 'spaces' }       = $self->{ 'spaces' };
    $args{ 'uc_keywords' }  = $self->{ 'uc_keyword' };
    $args{ 'uc_functions' } = $self->{ 'uc_function' };
    $args{ 'uc_types' }     = $self->{ 'uc_type' };
    $args{ 'separator' }    = $self->{ 'separator' };
    $args{ 'comma' }        = $self->{ 'comma' };
    $args{ 'format' }       = $self->{ 'format' };
    $args{ 'colorize' }     = $self->{ 'colorize' };
    $args{ 'comma_break' }  = $self->{ 'comma_break' };
    $args{ 'format_type' }  = 1 if ($self->{ 'format_type' });
    $args{ 'wrap_after' }   = $self->{ 'wrap_after' };
    $args{ 'no_grouping' }  = 1 if $self->{ 'nogrouping' };
    $args{ 'numbering' }    = 1 if $self->{ 'numbering' };
    $args{ 'redshift' }     = 1 if $self->{ 'redshift' };
    $args{ 'keep_newline' } = 1 if $self->{ 'keep_newline' };

    $self->{ 'content' } = &remove_extra_parenthesis($self->{ 'content' } ) if ($self->{ 'content' } );

    my $beautifier = pgFormatter::Beautify->new( %args );
    if ($self->{ 'extra_function' } && -e $self->{ 'extra_function' })
    {
	    if (open(my $fh, '<', $self->{ 'extra_function' }))
	    {
		    my @fcts = ();
		    while (my $l = <$fh>) {
			    chomp($l);
			    push(@fcts, split(/^[\s,;]+$/, $l));
		    }
		    $beautifier->add_functions(@fcts);
		    close($fh);
	    } else {
		    warn("WARNING: can not read file $self->{ 'extra_function' }\n");
	    }
    }
    $beautifier->query( $self->{ 'content' } );
    $beautifier->anonymize() if $self->{ 'anonymize' };
    $beautifier->beautify();

    $self->{ 'content' } = $beautifier->content();

    return;
}

sub remove_extra_parenthesis {
    my $str = shift;

    while ($str =~ s/\(\s*\(([^\(\)]+)\)\s*\)/($1)/gs) {};
    while ($str =~ s/\(\s*\(([^\(\)]+)\)\s*AND\s*\(([^\(\)]+)\)\s*\)/($1 AND $2)/igs) {};
    while ($str =~ s/\(\s*\(\s*\(([^\(\)]+\)[^\(\)]+\([^\(\)]+)\)\s*\)\s*\)/(($1))/gs) {};

    return $str;
}

=head2

Outputs body of the page.

=cut

sub print_body {
    my $self = shift;

    my $chk_nocomment   = $self->{ 'nocomment' } ? 'checked="checked" ' : '';
    my $chk_colorize    = $self->{ 'colorize' }  ? 'checked="checked" ' : '';
    my $chk_anonymize   = $self->{ 'anonymize' } ? 'checked="checked" ' : '';
    my $chk_comma       = $self->{ 'comma' } eq 'start' ? 'checked="checked" ' : '';
    my $chk_comma_break = $self->{ 'comma_break' } ? 'checked="checked" ' : '';
    my $chk_format_type = $self->{ 'format_type' } ? 'checked="checked" ' : '';
    my $chk_nogrouping  = $self->{ 'nogrouping' } ? 'checked="checked" ' : '';
    my $chk_numbering   = $self->{ 'numbering' } ? 'checked="checked" ' : '';
    my $chk_redshift    = $self->{ 'redshift' } ? 'checked="checked" ' : '';
    my $chk_keepnewline = $self->{ 'keep_newline' } ? 'checked="checked" ' : '';

    my %kw_toggle = ( 0 => '', 1 => '', 2 => '', 3 => '' );
    $kw_toggle{ $self->{ 'uc_keyword' } } = ' selected="selected"';

    my %fct_toggle = ( 0 => '', 1 => '', 2 => '', 3 => '' );
    $fct_toggle{ $self->{ 'uc_function' } } = ' selected="selected"';

    my %typ_toggle = ( 0 => '', 1 => '', 2 => '', 3 => '' );
    $typ_toggle{ $self->{ 'uc_type' } } = ' selected="selected"';

    my $service_url = $self->{ 'service_url' } || $self->{ 'cgi' }->url;

    print <<_END_OF_HTML_;
<form method="post" action="" enctype="multipart/form-data">
 <table width="100%"><tr><td align="center" valign="top">
 <div id="options">
    <fieldset><legend id="general"><strong> General </strong></legend>
      <div id="general_content" class="content">
      <input type="checkbox" id="id_highlight" name="colorize" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_colorize/>
      <label for="id_highlight">Enable syntax highlighting</label>
      <br />
      <input type="checkbox" id="id_remove_comments" name="nocomment" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_nocomment/>
      <label for="id_remove_comments">Remove comments</label>
      <br />
      <input type="checkbox" id="id_anonymize" name="anonymize" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_anonymize/>
      <label for="id_anonymize">Anonymize values in queries</label>
      <br />
      <input type="checkbox" id="id_comma" name="comma" value="start" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_comma/>
      <label for="id_comma">Comma at beginning</label>
      <br />
      <input type="checkbox" id="id_comma_break" name="comma_break" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_comma_break/>
      <label for="id_comma_break">New-line after comma (insert)</label>
      <br />
      <input type="checkbox" id="id_keep_newline" name="keep_newline" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_keepnewline/>
      <label for="id_keep_newline">Keep empty lines</label>
      <br />
      <input type="checkbox" id="id_format_type" name="format_type" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_format_type/>
      <label for="id_format_type">Alternate formatting</label>
      <br />
      <input type="checkbox" id="id_no_grouping" name="nogrouping" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_nogrouping/>
      <label for="id_no_grouping">No transaction grouping</label>
      <br />
      <input type="checkbox" id="id_numbering" name="numbering" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_numbering/>
      <label for="id_numbering">Statement numbering</label>
      <br />
      <input type="checkbox" id="id_redshift" name="redshift" value="1" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" $chk_redshift/>
      <label for="id_redshift">Redshift keywords</label>
      </div>
    </fieldset>
      <br />
    <fieldset><legend id="kwcase">
    <strong> Keywords & functions</strong></legend>
      <div>
      Keywords: <select name="uc_keyword" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();">
            <option value="0"$kw_toggle{0}>Unchanged</option>
            <option value="1"$kw_toggle{1} >Lower case</option>
            <option value="2"$kw_toggle{2} >Upper case</option>
            <option value="3"$kw_toggle{3} >Capitalize</option>
      </select>
    <br />
      Functions: <select name="uc_function" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();">
            <option value="0"$fct_toggle{0}>Unchanged</option>
            <option value="1"$fct_toggle{1} >Lower case</option>
            <option value="2"$fct_toggle{2} >Upper case</option>
            <option value="3"$fct_toggle{3} >Capitalize</option>
      </select>
    <br />
      Datatypes: <select name="uc_type" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();">
            <option value="0"$typ_toggle{0}>Unchanged</option>
            <option value="1"$typ_toggle{1} >Lower case</option>
            <option value="2"$typ_toggle{2} >Upper case</option>
            <option value="3"$typ_toggle{3} >Capitalize</option>
      </select>
    </div>
    </fieldset>
      <br />
    <fieldset><legend id="indent"><strong> Indentation </strong>
    </legend>
      <div id="indent_content" class="content">
        Indentation: <input name="spaces" value="$self->{ 'spaces' }" maxlength="2" type="text" id="spaces" size="2" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" /> spaces
      <br />
      Wrap after:&nbsp;&nbsp;<input name="wrap_after" value="$self->{ 'wrap_after' }" maxlength="2" type="text" id="wrap_after" size="2" onchange="document.forms[0].original_content.value != ''; document.forms[0].submit();" /> cols
      </div>
    </fieldset>
    <p align="center">
    <input type="button" value="Clear" onclick="document.forms[0].original_content.value = ''; document.forms[0].submit();" title="Clear content in code area"/>
    &nbsp;&nbsp;
    <input type="button" value="Reset" onclick="document.location.href='$service_url'; return true;" title="Reset all options to default"/>
    &nbsp;&nbsp;
    <input type="button" value="Load example" onclick="document.forms[0].show_example.value=1; document.forms[0].submit();" title="Load an example to see what pgFormatter is a able to do"/>
    <input type="hidden" name="show_example" value="0" />
    </p>
    <input type="hidden" name="load_from_file" value="0" />
    <p align="center">
    <span style="position: relative">
        <span style="position:absolute; top:0; left:0; width:150px; filter:alpha(opacity=0); opacity:0.0; overflow:hidden">
        <input type="file" name="filetoload" onchange="document.forms[0].code_upload.value=this.value" style="height:28px;width:150px;cursor:hand;">
        </span>
        <input type="text" name="code_upload" style="width: 150px">
    <input type="button" value="Upload file" onclick="if (document.forms[0].filetoload.value != '') { document.forms[0].load_from_file.value=1; document.forms[0].submit(); } return false;"/>
    </span>
    </p>
    <p align="center">
    <input id="format_code" type="button" style="background-color: #ff7400;" value="&nbsp;Format my code&nbsp;" onclick="document.forms[0].submit();"/>
  </div>
  </td><td valign="top" align="left">
  <table><tr><td>
_END_OF_HTML_

    if ( ( $self->{ 'show_example' } ) || ( !$self->{ 'content' } ) )
    {
        $self->{ 'content' } = 'Enter your SQL code here...' unless $self->{ 'content' };
        print
qq{<textarea name="content" id="sqlcontent" onfocus="if (done == 0) this.value=''; done = 1; set_bg_color('sqlcontent', '#f5f3de');" onblur="set_bg_color('sqlcontent', 'white');" onchange="maxlength_textarea(this, $self->{ 'maxlength' })">};
        print "$self->{ 'content' }</textarea>";
    }
    else
    {
        print qq{<div class="sql" id="sql"><pre>$self->{ 'content' }</pre></div>};
	print qq{
	</td></tr>
	<tr><td align="center"><div class="sql">
    <input id="copycode" type="button" style="background-color: #ff7400" value="&nbsp;Copy to clipboard&nbsp;" onclick="if (!navigator.clipboard) {return false;} var copied=document.getElementById('sql').innerText;navigator.clipboard.writeText(copied); return false;"/>
        <p></p>
};
    }
    print
qq{<textarea name="original_content" id="originalcontent" style="display: none;">$self->{ 'original_content' }</textarea>};

    print qq{
    </td></tr>
    <tr><td>
    <div class="footer"> Service provided by <a href="$self->{ 'download_url' }" target="_new">$self->{ 'program_name' } $VERSION</a>. Development code available on <a href="$self->{ 'project_url' }" target="_new">GitHub.com</a> </div>
    </td></tr>
};

    # Add external file with html code at bottom of the page
    # used to display ads or anything else below the text area
    my $ad_content = $self->_load_optional_file( $self->{ 'bottom_ad_file' } );
    $ad_content ||= '<br/>';

    print qq{
    <tr><td>$ad_content</td></tr>
    </table>
    </td></tr></table> </form>
};

    return;
}

=head2 print_footer

Outputs footer of the page

=cut

sub print_footer {
    my $self = shift;

    print qq{<p>&nbsp;</p>};
    print " </div> </body> </html>\n";
    return;
}

=head2 _load_optional_file

Helper function to try to load file. If it succeeds, it returns file
content, it not, it returns empty string (instead of dying).

=cut

sub _load_optional_file {
    my $self     = shift;
    my $filename = shift;

    return '' unless -f $filename;
    return '' if -z $filename;

    open my $in, '<', $filename or return '';
    local $/ = undef;
    my $content = <$in>;
    close $in;
    return $content;
}

=head2 print_headers

Outputs page headers - both HTTP level headers, and HTML.

=cut

sub print_headers {
    my $self = shift;
    print $self->{ 'cgi' }->header(-charset => 'utf-8');

    my $date = localtime( time );

    # Add external file content into the HTML header, used to add tracker
    # information or anything else between the <head></head> tags.
    my $track_content = $self->_load_optional_file( $self->{ 'head_track_file' } );
    my $style_content = $self->_load_optional_file( $self->{ 'css_file' } );
    $style_content = $self->default_styles if '' eq $style_content;

    print <<_END_OF_HTML_HEADER_;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$self->{ 'program_name' }</title>
<meta NAME="robots" CONTENT="noindex,nofollow">
<meta HTTP-EQUIV="Expires" CONTENT="$date">
<meta HTTP-EQUIV="Generator" CONTENT="$self->{ 'program_name'} v$VERSION">
<meta HTTP-EQUIV="Date" CONTENT="$date">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link rel="shortcut icon" href="icon_pgformatter.ico" />
<meta name="description" content="Free online sql formatting tool, beautify sql code instantly for PostgreSQL, SQL-92, SQL-99, SQL-2003, SQL-2008 and SQL-2011" />
<meta name="keywords" content="sql formatter,sql beautifier,format sql,formatting sql" />
$track_content
<style type="text/css">
$style_content
.logopart {
font-size:32px;
font-weight:bold;
font-color:#ff7400;
font-family: Lucida Sans, Arial, Helvetica, sans-serif;
overflow: hidden;
padding-left: 100px;
}
.logo {
float: left;
margin-left: -100px;
}
</style>
<script type="text/javascript">
<!--
var done = 0;
function set_bg_color(id, color) {
document.getElementById(id).style.background=color;
}
function clear_content(id, msg) {
document.getElementById(id).value=msg;
}
function maxlength_textarea(objtextarea,maxlength) {
if (objtextarea.value.length > maxlength) {
    objtextarea.value = objtextarea.value.substring(0, maxlength);
    alert('Hum, with no limit I means up to '+maxlength+' characters!\\nThat should be enough, no ? Content has been truncated.');
}
}
//-->
</script>
</head>
<body>
<div id="content">
<table>
<tr><td width="330">
<div class="logopart">
<a href="$self->{ 'service_url' }"><img class="logo" src="logo_pgformatter.png"/></a><p>pgFormatter</p>
</div>
</td><td width="1000">
Free Online version of $self->{ 'program_name' } a PostgreSQL SQL syntax beautifier (no line limit here up to $self->{ 'maxlength' } characters).  This SQL formatter/beautifier supports keywords from SQL-92, SQL-99, SQL-2003, SQL-2008, SQL-2011 and PostgreSQL specifics keywords.  May work with any other databases too.
</td>
</tr>
</table>
_END_OF_HTML_HEADER_
    return;
}

=head1 DATA

__DATA__ section (at the end of this file) is used to store default CSS
Style, so that it will not "pollute" Perl code, and will not need to be
indented.

=head1 AUTHOR

pgFormatter is an original work from Gilles Darold

=head1 BUGS

Please report any bugs or feature requests to: https://github.com/darold/pgFormatter/issues

=head1 COPYRIGHT

Copyright 2012-2021 Gilles Darold. All rights reserved.

=head1 LICENSE

pgFormatter is free software distributed under the PostgreSQL Licence.

A modified version of the SQL::Beautify Perl Module is embedded in pgFormatter
with copyright (C) 2009 by Jonas Kramer and is published under the terms of
the Artistic License 2.0.

=cut

__DATA__

body {
background-color:#262626;
margin-top:0px;
font-family: Lucida Sans, Arial, Helvetica, sans-serif;
font-size: 18px;
color: #888888;
height: 100% !important;
background-position:top center;
background-attachment:fixed;
}

a {
text-decoration: none;
color: #000000;
}

a:hover {
text-decoration:underline;
color: #000000;
}
h1 {
font-family: Lucida Sans, sans-serif;
font-size: 38px;
color:#ff7400;
font-weight: bold;
padding:5px;
margin:3px 3px 3px 3px;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}
textarea#sqlcontent {
width: 1000px;
height: 400px;
border: 3px solid #cccccc;
padding: 5px;
font-family: Tahoma, sans-serif;
font-size: 14px;
background-position: bottom right;
background-repeat: no-repeat;
background: #f5f3de;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}
div#sql {
width: 1000px;
height: 400px;
border: 3px solid #cccccc;
padding: 5px;
overflow: auto;
font-family:monospace;
font-size: 14px;
float: left;
text-align: left;
background-position: bottom right;
background-repeat: no-repeat;
background: #f5f3de;
white-space: pre;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}
.sql .kw1 {color: #993333; font-weight: bold;}
.sql .kw1_u {color: #993333; font-weight: bold; text-transform: uppercase;}
.sql .kw1_l {color: #993333; font-weight: bold; text-transform: lowercase;}
.sql .kw1_c {color: #993333; font-weight: bold; text-transform: capitalize;}
.sql .kw2 {color: #993333; font-style: italic;}
.sql .kw2_u {color: #993333; font-style: italic; text-transform: uppercase;}
.sql .kw2_l {color: #993333; font-style: italic; text-transform: lowercase;}
.sql .kw2_c {color: #993333; font-style: italic; text-transform: capitalize;}
.sql .kw3 {color: #993333;}
.sql .kw3_u {color: #993333; text-transform: uppercase;}
.sql .kw3_l {color: #993333; text-transform: lowercase;}
.sql .kw3_c {color: #993333; text-transform: capitalize;}
.sql .br0 {color: #66cc66;}
.sql .br1 {color: #3b3ba2;}
.sql .sy0 {color: #000000;}
.sql .st0 {color: #ff0000;}
.sql .nu0 {color: #cc66cc;}
div.footer { width: 1020px; font: 14px Helvetica, Arial, sans-serif;clear: both; height:40px; color: #000000; padding: 13px 0px 0 0; margin-left: auto; margin-right: auto; text-align: center; background-color: #ff7400; }
div.footer a strong { color: #eeeeee; font-weight: bold;}
div.footer a, #footer a:visited { color: #eeeeee; }
div.footer a:hover { color: #eeeeee; }
div.smaller { font: 11px Helvetica, Arial, sans-serif;clear: both; color: #000000; padding:13px 0px 0 0;margin-left: auto; margin-right: auto; text-align: center; background-color: #ff7400; }

#options {
width: 250px;
height: 400px;
margin:3px 3px 3px 3px;
padding:2 2px;
font-size: 14px;
float: left;
text-align: left;
color: #2e3436;
border-radius:6px;
}

#options fieldset {
border: 1px solid #dddddd;
margin:3px 3px 3px 3px;
background: #ff7400;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}

#options fieldset legend {
border: 1px solid #dddddd;
margin-bottom: .6em;
background: #ff7400;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}
#options input, select, button {
border: 1px solid #dddddd;
background: #f5f3de;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
}
#format_code {
border: 1px solid #dddddd;
background: #f5f3de;
padding: 5px;
margin: 5px;
border-radius:6px;
-moz-border-radius:10px;
-webkit-border-radius:10px;
box-shadow:3px 3px 6px 2px #A9A9A9;
-moz-box-shadow:3px 3px 6px 2px #A9A9A9;
-webkit-box-shadow:3px 3px 6px #A9A9A9;
font-weight: normal;
font-size: 16px;
}
