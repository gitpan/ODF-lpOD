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
#    Lpod is distributed in the hope that it will be useful,
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
our	$VERSION	        = '0.100';
use constant PACKAGE_DATE => '2010-06-25T14:17:07';
#-----------------------------------------------------------------------------
use Scalar::Util;
use Encode;
use Carp;
use base 'Exporter';
our @EXPORT     = qw
        (
        lpod_common lpod

        odf_get_document
        odf_new_document_from_template odf_new_document_from_type

        odf_get_container
        odf_new_container_from_template odf_new_container_from_type

        odf_get_xmlpart

        odf_create_element odf_create_paragraph odf_create_heading
        odf_create_section
        odf_create_table odf_create_column odf_create_row odf_create_cell
        odf_create_field

        odf_document odf_container
        odf_xmlpart odf_content odf_styles odf_meta odf_settings odf_manifest
        
        odf_element odf_text_element odf_bibliography_mark
        odf_paragraph odf_heading odf_draw_page odf_section
        odf_list odf_table odf_column odf_row odf_cell odf_field
        odf_table_element

        TRUE FALSE PRETTY
        is_true is_false is_odf_datatype odf_boolean process_options
        
        META CONTENT STYLES SETTINGS MANIFEST MIMETYPE

        text_segment TEXT_SEGMENT
        
        input_conversion output_conversion search_string
        get_local_encoding set_local_encoding
        is_numeric iso_date numeric_date check_odf_value odf_value
        alert fatal_error not_implemented
        
        PRETTY_PRINT EMPTY_TAGS
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
        odf_table               => 'ODF::lpOD::Table',
        odf_table_element       => 'ODF::lpOD::TableElement',
        odf_column              => 'ODF::lpOD::Column',
        odf_row                 => 'ODF::lpOD::Row',
        odf_cell                => 'ODF::lpOD::Cell',
        odf_draw_page           => 'ODF::lpOD::DrawPage',
        odf_section             => 'ODF::lpOD::Section',
        odf_bibliography_mark   => 'ODF::lpOD::BibliographyMark'
        };
        
#--- lpOD common tools and parameters ----------------------------------------

use constant
        {
        lpod_common             => 'ODF::lpOD::Common',
        lpod                    => 'ODF::lpOD::Common'
        };

#--- ODF data types ----------------------------------------------------------

our @DATA_TYPES = qw(string float currency percentage date time boolean);

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

our %ODF_TEMPLATE           =
        (
        'text'          => 'text.odt',
        'spreadsheet'   => 'spreadsheet.ods',
        'presentation'  => 'presentation.odp',
        'drawing'       => 'drawing.odg'
        #TBC
        );

our $LOCAL_ENCODING     = 'utf8';       # application local text encoding

our $LINE_BREAK         = "\n";
our $TAB_STOP           = "\t";

our $INSTALLATION_PATH  = undef;        # lpOD library installation path

our $LPOD_MARK          = '#lpod:mark'; # lpOD session bookmark tag
our $LPOD_ID            = '#lpod:id';   # lpOD XML ID attribute
our $LPOD_PART          = '#lpod:part'; # lpOD link from element to xmlpart

#=== common function aliases =================================================

BEGIN   {
        *odf_get_document                       =
                *ODF::lpOD::Document::get_from_uri;
        *odf_new_document_from_template         =
                *ODF::lpOD::Document::create_from_template;
        *odf_new_document_from_type            =
                *ODF::lpOD::Document::create;

        *odf_get_container                      =
                *ODF::lpOD::Container::get_from_uri;
        *odf_new_container_from_template        =
                *ODF::lpOD::Container::create_from_template;
        *odf_new_container_from_type            =
                *ODF::lpOD::Container::create;
        
        *odf_get_xmlpart        = *ODF::lpOD::XMLPart::get;
        
        *odf_create_element     = *ODF::lpOD::Element::create;
        *odf_create_paragraph   = *ODF::lpOD::Paragraph::create;
        *odf_create_heading     = *ODF::lpOD::Heading::create;
        *odf_create_field       = *ODF::lpOD::Field::create;
        *odf_create_table       = *ODF::lpOD::Table::create;
        *odf_create_column      = *ODF::lpOD::Column::create;
        *odf_create_row         = *ODF::lpOD::Row::create;
        *odf_create_cell        = *ODF::lpOD::Cell::create;
        *odf_create_section     = *ODF::lpOD::Section::create;

        *is_numeric             = *Scalar::Util::looks_like_number;
        *odf_value              = *check_odf_value;

        *fatal_error            = *Carp::confess;
        }

#=== exported utilities ======================================================

our     $DEBUG          = FALSE;

sub     alert
        {
        return $DEBUG ? Carp::cluck(@_) : say for @_;
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
        my $param       = shift // "";                          #/
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
        my $type        = shift;

        given ($type)
                {
                when (undef)
                        {
                        $type = 'string'; $value //= "";        #/
                        }
                when ('string')
                        {
                        $value //= "";                          #/
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        $value //= 0;                           #/
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
                when ('time')
                        {
                        # check not implemented
                        }
                default
                        {
                        $value  = undef;
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

#-----------------------------------------------------------------------------

our     $ENCODER        = Encode::find_encoding($LOCAL_ENCODING);

sub     get_local_encoding
        {
        return $LOCAL_ENCODING;
        }

sub     set_local_encoding
        {
        my $new_encoding = shift // "";                                 #/
        $new_encoding = shift if ($new_encoding eq lpod);
        my $enc = Encode::find_encoding($new_encoding);
        unless ($enc)
                {
                alert("Unsupported encoding");
                return FALSE;
                }
        $ENCODER = $enc;
        $LOCAL_ENCODING = $new_encoding;
        return $LOCAL_ENCODING;
        }

sub     input_conversion
        {
        my $text        = shift;
        unless ($ENCODER)
                {
                alert "Unsupported encoding";
                return $text;
                }
        return (defined $text) ? $ENCODER->decode($text)  : undef;
        }

sub     output_conversion
        {
        my $text        = shift;
        
        unless ($ENCODER)
                {
                alert "Unsupported encoding";
                return $text;
                }
        return $text unless $LOCAL_ENCODING;
        return (defined $text) ? $ENCODER->encode($text) : undef;
        }

#--- ISO-9601 / internal date conversion -------------------------------------

sub	iso_date
	{
	my $time = shift // time();                             #/
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
        if (abs($start) >= $ln)
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

sub     installation_path
        {
        return $INSTALLATION_PATH;
        }

sub     template
        {
        my $type        = shift // "";                          #/
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

