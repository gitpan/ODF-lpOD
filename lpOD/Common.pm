# Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#
# Author: Jean-Marie Gouarné <jean-marie.gouarne@arsaperta.com>
#
# This file is part of lpOD (see: http://lpod-project.org).
# Lpod is free software; you can redistribute it and/or modify it under
# the terms of either:
#
# a) the GNU General Public License as published by the Free Software
#    Foundation, either version 3 of the License, or (at your option)
#    any later version.
#    lpOD is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with lpOD.  If not, see <http://www.gnu.org/licenses/>.
#
# b) the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
#-----------------------------------------------------------------------------
use     5.010_000;
use     strict;
#-----------------------------------------------------------------------------
#       Common lpOD/Perl parameters and utility functions
#-----------------------------------------------------------------------------
package ODF::lpOD::Common;
our	$VERSION	        = '1.002';
use constant PACKAGE_DATE       => '2011-01-10T19:33:39';
#-----------------------------------------------------------------------------
use Scalar::Util;
use Encode;
use base 'Exporter';
our @EXPORT     = qw
        (
        lpod_common lpod

        odf_get_document odf_new_document
        odf_new_document_from_template odf_new_document_from_type

        odf_get_container odf_new_container
        odf_new_container_from_template odf_new_container_from_type

        odf_get_xmlpart

        odf_create_element odf_create_paragraph odf_create_heading
        odf_create_section odf_create_draw_page
        odf_create_shape
        odf_create_area odf_create_rectangle odf_create_ellipse
        odf_create_vector odf_create_line odf_create_connector
        odf_create_frame odf_create_text_frame odf_create_image_frame
        odf_create_image
        odf_create_list
        odf_create_table odf_create_column odf_create_row odf_create_cell
        odf_create_column_group odf_create_row_group
        odf_create_field odf_create_simple_variable odf_create_user_variable
        odf_create_note odf_create_annotation
        odf_create_style odf_create_font_declaration
        odf_create_toc

        odf_document odf_container
        odf_xmlpart odf_content odf_styles odf_meta odf_settings odf_manifest
        
        odf_element
        odf_text_element
        odf_bibliography_mark odf_note odf_annotation odf_changed_region
        odf_paragraph odf_heading odf_draw_page odf_image odf_shape odf_frame
        odf_area odf_rectangle odf_ellipse odf_vector odf_line odf_connector
        odf_field odf_variable odf_simple_variable odf_user_variable
        odf_text_field odf_classify_text_field
        odf_list odf_table odf_column odf_row odf_cell
        odf_matrix odf_column_group odf_row_group odf_table_element
        odf_section odf_toc
        odf_file_entry

        odf_style
        odf_text_style odf_paragraph_style
        odf_list_style odf_list_level_style odf_outline_style
        odf_table_style odf_column_style odf_row_style odf_cell_style
        odf_number_style
        odf_master_page odf_page_end_style odf_drawing_page_style
        odf_page_layout odf_presentation_page_layout
        odf_graphic_style
        odf_font_declaration

        TRUE FALSE PRETTY
        is_true is_false defined_false
        is_odf_datatype odf_boolean process_options
        alpha_to_num translate_coordinates translate_range
        
        xelt xtwig
        
        META CONTENT STYLES SETTINGS MANIFEST MIMETYPE

        text_segment TEXT_SEGMENT
        
        input_conversion output_conversion search_string
        color_code color_name load_color_map unload_color_map
        is_numeric iso_date numeric_date check_odf_value odf_value
        file_parse file_type image_size input_2d_value
        alert not_implemented
        
        PRETTY_PRINT EMPTY_TAGS
        
        FIRST_CHILD LAST_CHILD NEXT_SIBLING PREV_SIBLING WITHIN
        );

#=== package name aliases ====================================================
#--- ODF package & parts -----------------------------------------------------

use constant
        {
        odf_document            => 'ODF::lpOD::Document',
        odf_container           => 'ODF::lpOD::Container',
        odf_xmlpart             => 'ODF::lpOD::XMLPart',
        odf_content             => 'ODF::lpOD::Content',
        odf_styles              => 'ODF::lpOD::Styles',
        odf_meta                => 'ODF::lpOD::Meta',
        odf_settings            => 'ODF::lpOD::Settings',
        odf_manifest            => 'ODF::lpOD::Manifest'        
        };

#--- ODF element -------------------------------------------------------------

use constant
        {
        odf_element             => 'ODF::lpOD::Element',
        odf_text_element        => 'ODF::lpOD::TextElement',
        odf_paragraph           => 'ODF::lpOD::Paragraph',
        odf_heading             => 'ODF::lpOD::Heading',
        odf_list                => 'ODF::lpOD::List',
        odf_field               => 'ODF::lpOD::Field',
        odf_variable            => 'ODF::lpOD::Variable',
        odf_simple_variable     => 'ODF::lpOD::SimpleVariable',
        odf_user_variable       => 'ODF::lpOD::UserVariable',
        odf_text_field          => 'ODF::lpOD::TextField',
        odf_table               => 'ODF::lpOD::Table',
        odf_table_element       => 'ODF::lpOD::TableElement',
        odf_matrix              => 'ODF::lpOD::Matrix',
        odf_column_group        => 'ODF::lpOD::ColumnGroup',
        odf_row_group           => 'ODF::lpOD::RowGroup',
        odf_column              => 'ODF::lpOD::Column',
        odf_row                 => 'ODF::lpOD::Row',
        odf_cell                => 'ODF::lpOD::Cell',
        odf_draw_page           => 'ODF::lpOD::DrawPage',
        odf_shape               => 'ODF::lpOD::Shape',
        odf_area                => 'ODF::lpOD::Area',
        odf_rectangle           => 'ODF::lpOD::Rectangle',
        odf_ellipse             => 'ODF::lpOD::Ellipse',
        odf_vector              => 'ODF::lpOD::Vector',
        odf_line                => 'ODF::lpOD::Line',
        odf_connector           => 'ODF::lpOD::Connector',
        odf_frame               => 'ODF::lpOD::Frame',
        odf_image               => 'ODF::lpOD::Image',
        odf_section             => 'ODF::lpOD::Section',
        odf_bibliography_mark   => 'ODF::lpOD::BibliographyMark',
        odf_note                => 'ODF::lpOD::Note',
        odf_annotation          => 'ODF::lpOD::Annotation',
        odf_changed_region      => 'ODF::lpOD::ChangedRegion',
        odf_font_declaration    => 'ODF::lpOD::FontDeclaration',
        odf_style               => 'ODF::lpOD::Style',
        odf_text_style          => 'ODF::lpOD::TextStyle',
        odf_paragraph_style     => 'ODF::lpOD::ParagraphStyle',
        odf_list_style          => 'ODF::lpOD::ListStyle',
        odf_list_level_style    => 'ODF::lpOD::ListLevelStyle',
        odf_outline_style       => 'ODF::lpOD::OutlineStyle',
        odf_table_style         => 'ODF::lpOD::TableStyle',
        odf_column_style        => 'ODF::lpOD::ColumnStyle',
        odf_row_style           => 'ODF::lpOD::RowStyle',
        odf_cell_style          => 'ODF::lpOD::CellStyle',
        odf_number_style        => 'ODF::lpOD::NumberStyle',
        odf_master_page         => 'ODF::lpOD::MasterPage',
        odf_page_layout         => 'ODF::lpOD::PageLayout',
        odf_presentation_page_layout
                                => 'ODF::lpOD::PresentationPageLayout',
        odf_graphic_style       => 'ODF::lpOD::GraphicStyle',
        odf_page_end_style      => 'ODF::lpOD::PageEndStyle',
        odf_drawing_page_style  => 'ODF::lpOD::DrawingPageStyle',
        odf_file_entry          => 'ODF::lpOD::FileEntry',
        odf_toc                 => 'ODF::lpOD::TOC'
        };

#--- basic API shortcuts -----------------------------------------------------

use constant
        {
        xelt                    => 'XML::Twig::Elt',
        xtwig                   => 'XML::Twig'
        };

#--- lpOD common tools and parameters ----------------------------------------

use constant
        {
        lpod_common             => 'ODF::lpOD::Common',
        lpod                    => 'ODF::lpOD::Common'
        };

#--- ODF data types ----------------------------------------------------------

our @DATA_TYPES = qw(string float currency percentage date time boolean);

#--- default string comparison function --------------------------------------

our $COMPARE = sub { shift cmp shift };

#=== common parameters =======================================================

use constant                            # common constants
        {
        TRUE            => 1,
        FALSE           => 0,
        };
        
use constant                            # ODF package parts
        {
        META            => 'meta.xml',
        CONTENT         => 'content.xml',
        STYLES          => 'styles.xml',
        SETTINGS        => 'settings.xml',
        MANIFEST        => 'META-INF/manifest.xml',
        MIMETYPE        => 'mimetype'
        };

use constant
        {
        TEXT_SEGMENT    => '#PCDATA',
        text_segment    => '#PCDATA'
        };

use constant                            # XML::Twig specific
        {
        PRETTY_PRINT    => 'indented',
        EMPTY_TAGS      => 'normal'
        };

use constant                            # element insert positions
        {
        FIRST_CHILD     => 'FIRST_CHILD',
        LAST_CHILD      => 'LAST_CHILD',
        NEXT_SIBLING    => 'NEXT_SIBLING',
        PREV_SIBLING    => 'PREV_SIBLING',
        WITHIN          => 'WITHIN'
        };

our %ODF_TEMPLATE           =
        (
        'text'          => 'text.odt',
        'spreadsheet'   => 'spreadsheet.ods',
        'presentation'  => 'presentation.odp',
        'drawing'       => 'drawing.odg'
        );

our $LINE_BREAK         = "\n";
our $TAB_STOP           = "\t";

our $INSTALLATION_PATH  = undef;        # lpOD library installation path

our $LPOD_MARK          = '#lpod:mark'; # lpOD session bookmark tag
our $LPOD_ID            = '#lpod:id';   # lpOD XML ID attribute
our $LPOD_PART          = '#lpod:part'; # lpOD link from element to xmlpart

#=== common function aliases =================================================

BEGIN   {
        *odf_get_document       = *ODF::lpOD::Document::get_from_uri;
        *odf_new_document_from_template
                                = *ODF::lpOD::Document::create_from_template;
        *odf_new_document_from_type
                                = *ODF::lpOD::Document::_create;
        *odf_new_document       = *ODF::lpOD::Document::_create;
        *odf_get_container      = *ODF::lpOD::Container::get_from_uri;
        *odf_new_container_from_template
                                = *ODF::lpOD::Container::create_from_template;
        *odf_new_container      = *ODF::lpOD::Container::create;
        *odf_new_container_from_type
                                = *ODF::lpOD::Container::create;
        *odf_get_xmlpart        = *ODF::lpOD::XMLPart::get;
        
        *odf_create_element     = *ODF::lpOD::Element::_create;
        *odf_create_paragraph   = *ODF::lpOD::Paragraph::_create;
        *odf_create_heading     = *ODF::lpOD::Heading::_create;
        *odf_create_field       = *ODF::lpOD::Field::_create;
        *odf_create_simple_variable
                                = *ODF::lpOD::SimpleVariable::_create;
        *odf_create_user_variable
                                = *ODF::lpOD::UserVariable::_create;
        *odf_create_table       = *ODF::lpOD::Table::_create;
        *odf_create_row_group   = *ODF::lpOD::RowGroup::_create;
        *odf_create_column_group
                                = *ODF::lpOD::ColumnGroup::_create;
        *odf_create_column      = *ODF::lpOD::Column::_create;
        *odf_create_row         = *ODF::lpOD::Row::_create;
        *odf_create_cell        = *ODF::lpOD::Cell::_create;
        *odf_create_section     = *ODF::lpOD::Section::_create;
        *odf_create_list        = *ODF::lpOD::List::_create;
        *odf_create_draw_page   = *ODF::lpOD::DrawPage::_create;
        *odf_create_shape       = *ODF::lpOD::Shape::_create;
        *odf_create_area        = *ODF::lpOD::Area::_create;
        *odf_create_rectangle   = *ODF::lpOD::Rectangle::_create;
        *odf_create_ellipse     = *ODF::lpOD::Ellipse::_create;
        *odf_create_vector      = *ODF::lpOD::Vector::_create;
        *odf_create_line        = *ODF::lpOD::Line::_create;
        *odf_create_connector   = *ODF::lpOD::Connector::_create;
        *odf_create_frame       = *ODF::lpOD::Frame::_create;
        *odf_create_image       = *ODF::lpOD::Image::_create;
        *odf_create_text_frame  = *ODF::lpOD::Frame::_create_text;
        *odf_create_image_frame = *ODF::lpOD::Frame::_create_image;
        *odf_create_note        = *ODF::lpOD::Note::_create;
        *odf_create_annotation  = *ODF::lpOD::Annotation::_create;
        *odf_create_font_declaration
                                = *ODF::lpOD::FontDeclaration::_create;
        *odf_create_style       = *ODF::lpOD::Style::_create;
        *odf_classify_text_field
                                = *ODF::lpOD::TextField::classify;
        *odf_create_toc         = *ODF::lpOD::TOC::_create;

        *is_numeric             = *Scalar::Util::looks_like_number;
        *odf_value              = *check_odf_value;
        
        #initializations

        }

#=== exported utilities ======================================================

our     $DEBUG          = FALSE;
        
sub     alert
        {
        if ($DEBUG)
                {
                require Carp;
                return Carp::cluck(@_);
                }
        say for @_;
        }

sub     info
        {
        return wantarray ?
                (
                name    => "ODF::lpOD",
                version => $ODF::lpOD::VERSION,
                date    => ODF::lpOD->PACKAGE_DATE,
                path    => lpod->installation_path
                )
                :
                "ODF::lpOD $ODF::lpOD::VERSION" .
                " " . ODF::lpOD->PACKAGE_DATE   .
                " " . lpod->installation_path;
        }

sub     debug
        {
        my $param       = shift // "";
        $param          = shift if $param eq lpod;
        given ($param)
                {
                when (undef)            {}
                when (TRUE || FALSE)    { $DEBUG = $_; }
                default                 { alert "Wrong argument"; }
                }
        return $DEBUG;
        }

sub     is_true
        {
        my $arg = shift;
        return FALSE unless defined $arg;
        given (lc $arg)
                {
                when (["", "false", "off", "no"])
                        {
                        return FALSE;
                        }
                when ('true')
                        {
                        return TRUE;
                        }
                when (0)
                        {
                        return FALSE;
                        }
                default
                        {
                        return TRUE;
                        }
                }
        }

sub     is_false
        {
        return is_true(shift) ? FALSE : TRUE;
        }

sub	defined_false
	{
	my $arg	= shift;
	return FALSE unless defined $arg;
        return is_false($arg) ? TRUE : FALSE;
	}

sub     odf_boolean
        {
        my $value       = shift;
        return undef unless defined $value;
        return is_true($value) ? 'true' : 'false';
        }

sub     is_odf_datatype
        {
        my $type        = shift         or return undef;
        return $type ~~ @DATA_TYPES ? TRUE : FALSE;
        }

sub     check_odf_value
        {
        my $value       = shift;
        return undef unless defined $value;
        my $type        = shift;
        given ($type)
                {
                when (['float', 'currency', 'percentage'])
                        {
                        $value = undef unless is_numeric($value);
                        }
                when ('boolean')
                        {
                        if (is_true($value))
                                {
                                $value = 'true'; 
                                }
                        else
                                {
                                $value = 'false';
                                }
                        }
                when ('date')
                        {
                        if (is_numeric($value))
                                {
                                $value = iso_date($value);
                                }
                        else
                                {
                                my $num = numeric_date($value);
                                $value = defined $num ?
                                                iso_date($num) : undef;
                                }
                        }
                }
        return $value;
        }

sub     process_options
        {
        my %in  = (@_);
        my %out = ();
        foreach my $ink (keys %in)
                {
                my $outk = $ink;
                $outk =~ s/[ -]/_/g;
                $out{$outk} = $in{$ink}; 
                }
        return %out;
        }

sub     alpha_to_num
        {
        my $arg = shift         or return 0;
        $arg = shift if ref($arg) || $arg eq __PACKAGE__;
        my $alpha = uc $arg;
        unless ($alpha =~ /^[A-Z]*$/)
                {
                return $arg if $alpha =~ /^[0-9\-]*$/;
                alert "Wrong alpha value $arg";
                return undef;
                }
        my @asplit = split('', $alpha);
        my $num = 0;
        foreach my $p (@asplit)
                {
		$num *= 26;
		$num += ((ord($p) - ord('A')) + 1);
                }
        $num--;
        return $num;
        }

sub	translate_coordinates   # adapted from OpenOffice::OODoc (Genicorp)
	{
	my $arg	= shift // return undef;
        my $ra = ref $arg;
        if ($ra)
                {
                if ($ra eq 'ARRAY')     { return @$arg }
                else                    { shift }
                }
        elsif ($arg eq __PACKAGE__)
                {
                shift
                }
	return ($arg, @_) unless defined $arg;
	my $coord = uc $arg;
	return ($arg, @_) unless $coord =~ /[A-Z]/;

	$coord	=~ s/\s*//g;
	$coord	=~ /(^[A-Z]*)(\d*)/;
	my $c	= $1;
	my $r	= $2;
	return ($arg, @_) unless $c;
        my $colnum = alpha_to_num($c);
        if (defined $r and $r gt "")
                {
                $r--;
                return ($r, $colnum, @_);
                }
        else
                {
                return ($colnum, @_);
                }
	}

sub     translate_range
        {
        my $arg = shift // return undef;
        $arg = shift if ref($arg) || $arg eq __PACKAGE__;
        return ($arg, @_) unless (defined $arg && $arg =~ /:/);
        my $range = uc $arg;
        $range =~ s/\s*//g;
        my ($start, $end) = split(':', $range);
        my @r = ();
	push @r, translate_coordinates($_) for ($start, $end);
        return @r;
        }

#--- external character set conversion utilities -----------------------------

our $INPUT_CHARSET      = 'utf8';
our $OUTPUT_CHARSET     = 'utf8';
our $INPUT_ENCODER      = Encode::find_encoding($INPUT_CHARSET);
our $OUTPUT_ENCODER     = Encode::find_encoding($OUTPUT_CHARSET);

sub	get_input_charset       { $INPUT_CHARSET  }

sub     get_output_charset      { $OUTPUT_CHARSET }

sub     set_input_charset
        {
        my $charset = shift // "";
        $charset = shift if ($charset eq lpod);
        my $enc = Encode::find_encoding($charset);
        unless ($enc)
                {
                alert("Unsupported $charset input character set");
                return FALSE;
                }
        $INPUT_ENCODER = $enc;
        $INPUT_CHARSET = $charset;
        return $INPUT_CHARSET;
        }

sub     set_output_charset
        {
        my $charset = shift // "";
        $charset = shift if ($charset eq lpod);
        my $enc = Encode::find_encoding($charset);
        unless ($enc)
                {
                alert("Unsupported output character set");
                return FALSE;
                }
        $OUTPUT_ENCODER = $enc;
        $OUTPUT_CHARSET = $charset;
        return $OUTPUT_CHARSET;
        }

sub     input_conversion
        {
        my $text        = shift;
        return $text unless $INPUT_CHARSET;
        
        unless ($INPUT_ENCODER)
                {
                alert "Unsupported input character conversion";
                return $text;
                }
        return (defined $text) ? $INPUT_ENCODER->decode($text)  : undef;
        }

sub     output_conversion
        {
        my $text        = shift;
        return $text unless $OUTPUT_CHARSET;

        unless ($OUTPUT_ENCODER)
                {
                alert "Unsupported output character conversion";
                return $text;
                }
        
        return (defined $text) ? $OUTPUT_ENCODER->encode($text) : undef;
        }

#--- ISO-9601 / internal date conversion -------------------------------------

sub	iso_date
	{
	my $time = shift // time();
	my @t = localtime($time);
	return sprintf
			(
			"%04d-%02d-%02dT%02d:%02d:%02d",
			$t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]
			);
	}

sub	numeric_date                            # in progress
	{
	require Time::Local;

	my $iso_date = shift    or return undef;
	$iso_date .= 'T00:00:00'unless ($iso_date =~ /T/);
	$iso_date =~ /(\d*)-(\d*)-(\d*)T(\d*):(\d*):(\d*)/;
	my $sec = $6 || 0; my $min = $5 || 0; my $hrs = $4 || 0;
	my $day = $3 || 1; my $mon = $2 || 1; my $year = $1 || 0;
	return Time::Local::timelocal($sec,$min,$hrs,$day,$mon-1,$year); 
	}

#-----------------------------------------------------------------------------

sub     search_string
        {
        my $content     = shift;
        my $expr        = shift;
        return undef unless defined $expr;
        my %opt         =
                (
                replace         => undef,
                offset          => undef,
                range           => undef,
                @_
                );
        my $start       = $opt{offset};
        my $ln = length($content);
        if ((defined $start) and (abs($start) >= $ln))
                {
                alert "[$start $ln] out of range";
                return undef;
                }
        my $range       = $opt{range};
        if (defined $start)
                {
                $start = $start + $ln if $start < 0;
                $content = defined $range ?
                                substr($content, $start, $range)        :
                                substr($content, $start);
                }
        unless (defined $opt{replace})
                {
                if ($content =~ /$expr/)
                        {
                        my $start_pos = length($`);
                        $start_pos += $start if defined $start;
                        my $end_pos = $start_pos + length($&);
                        my $match = $&;
                        return wantarray ?
                                ($start_pos, $end_pos, $match)  :
                                $start_pos;
                        }
                else
                        {
                        return wantarray ? (undef) : undef;
                        }
                }
        else
                {
                my $rep = $opt{replace};
                my $count = ($content =~ s/$expr/$rep/g);
                if (wantarray)
                        {
                        return ($content, $count);
                        }
                else
                        {
                        return $count ? $content : undef;
                        }
                }
        }

#-----------------------------------------------------------------------------

sub     file_type
        {
        return undef unless eval('require File::Type');
        my $f   = shift;
        return undef    unless (-r $f && -f $f);
        return File::Type->new->mime_type($f);
        }

sub     file_parse
        {
        require File::Basename;
        return File::Basename::fileparse(shift, '\.*');
        }

sub     image_size
        {
        return undef unless eval('require Image::Size');
        my $f           = shift;
        return undef    unless (-r $f && -f $f);
        my ($w, $h) = Image::Size::imgsize($f);
        return undef    unless defined $w;
        $w .= 'pt'; $h .= 'pt';
        return [$w, $h];
        }

sub	input_2d_value
	{
        my $arg         = shift or return undef;
        my $u           = shift // 'cm';
	my ($x, $y);
        if (ref $arg)
                {
                $x = $arg->[0]; $y = $arg->[1];
                }
        elsif ($arg)
                {
                if ($arg =~ /,/)
		        {
		        $arg =~ s/\s*//g;
		        ($x, $y) = split(',', $arg);
		        }
		else
		        {
		        $x = $arg; $y = shift;
		        }
		}
	$x ||= ('0' . $u); $y ||= ('0' . $u);
	$x .= $u unless $x =~ /[a-zA-Z]$/;
	$y .= $u unless $y =~ /[a-zA-Z]$/;
        return wantarray ? ($x, $y) : [$x, $y];
	}        

#--- symbolic color names handling -------------------------------------------

our     %COLORCODE      = ();
our     %COLORNAME      = ();

sub	color_code
	{
	my $name        = shift         or return undef;
        if ($name && ($name =~ /^#/))   { return $name }
        return $COLORCODE{$name};
	}

sub     color_name
        {
        my $code        = shift         or return undef;
        return $COLORNAME{lc $code};
        }

sub	load_color_map
	{
	my $filename = shift || (installation_path() . '/data/rgb.txt');
	unless ( -e $filename && -r $filename )
		{
		warn "Color map file non existent or unreadable"
                                if $DEBUG;
		return FALSE;
		}
	my $r = open COLORS, "<", $filename;
	unless ($r)
		{
		alert "Error opening $filename"; return FALSE;
		}
	while (my $line = <COLORS>)
		{
		$line =~ s/^\s*//; $line =~ s/\s*$//;
		next unless $line =~ /^[0-9]/;
		$line =~ /(\d*)\s*(\d*)\s*(\d*)\s*(.*)/;
		my $name = $4;
		$COLORCODE{$name} = sprintf("#%02x%02x%02x", $1, $2, $3)
                                                if $name;
		}
	close COLORS;
        %COLORNAME = reverse %COLORCODE;
	return TRUE;
	}

sub	unload_color_map
	{
	my $self	= shift;
	%COLORCODE      = ();
        %COLORNAME      = ();
        return TRUE;
	}

#-----------------------------------------------------------------------------

sub     installation_path       { $INSTALLATION_PATH }

sub     template
        {
        my $type        = shift // "";
        $type = shift if $type eq lpod;
        
        my $filename = $ODF_TEMPLATE{$type};
        unless ($filename)
                {
                alert("Unsupported type");
                return FALSE;
                }
        my $fullpath = installation_path() . '/templates/' . $filename;
        unless (-r -f -e $fullpath)
                {
                alert("Template not available");
                return FALSE;
                }
        return $fullpath;
        }

#--- session ID generator ----------------------------------------------------

our $LPOD_ID_PATTERN    = 'lpOD_%09x';
sub     new_id
        {
        state $count    = 0;
        return sprintf($LPOD_ID_PATTERN, ++$count);        
        }

#-----------------------------------------------------------------------------

sub     not_implemented
        {
        alert("NOT IMPLEMENTED");
        return FALSE;
        }

#=============================================================================
1;

