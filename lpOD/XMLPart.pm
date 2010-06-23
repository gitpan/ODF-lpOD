# Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#
# Authors: Jean-Marie Gouarné <jean-marie.gouarne@arsaperta.com>
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
use 5.010_000;
use strict;
#-----------------------------------------------------------------------------
#       Level 0 - Basic XML navigation module - XMLPart class
#-----------------------------------------------------------------------------
package ODF::lpOD::XMLPart;
our     $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-09T21:46:02';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use ODF::lpOD::Element;
#=============================================================================

BEGIN   {
        *get_container  = *container;
        *get_document   = *document;
        *root           = *get_root;
        }

our %CLASS      =
        (
        content         => odf_content,
        styles          => odf_styles,
        meta            => odf_meta,
        manifest        => odf_manifest,
        settings        => odf_settings
        );

#=== exported part ===========================================================

sub     get
        {
        my $container   = shift;
        unless (ref $container && $container->isa(odf_container))
                {
                alert "Missing or not valid container";
                return FALSE;
                }
        my $part_name   = shift;
        unless ($CLASS{$part_name})
                {
                alert "Missing or unknown document part";
                return FALSE;
                }
        return odf_xmlpart->new
                (
                part            => $part_name,
                container       => $container,
                @_
                );
        }

#=== private part ============================================================

our $COUNT              = 0;

#--- constructor and associated utilities ------------------------------------

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                container       => undef,
                part            => undef,
                load            => TRUE,
                elt_class       => odf_element,
                twig            => undef,
                context         => undef,
                @_
                };
        
        $self->{twig} //= XML::Twig->new        # twig init /
                                (
                                elt_class       => $self->{elt_class},
                                pretty_print    => $self->{pretty_print},
                                id              => $ODF::lpOD::Common::LPOD_ID
                                );
        $self->{twig}->set_output_encoding('UTF-8');

        bless $self, $CLASS{$self->{part}};
        if ($self->{load})
                {
                my $status = $self->load();
                unless (is_true($status))
                        {
                        alert("Part load failed");
                        return FALSE;
                        }
                }

        $COUNT++;
        return $self;
        }

sub     load
        {
        my $self        = shift;
        my $xml         = shift || $self->{container}->get_part($self->{part});

        unless (defined $xml)
                {
                alert("No content");
                return FALSE;
                }

        my $r = UNIVERSAL::isa($xml, 'IO::File') ?
                $self->{twig}->safe_parsefile($xml)     :
                $self->{twig}->safe_parse($xml);
        unless ($r)
                {
                alert "No valid XML content";
                return FALSE;
                }
        
        $self->{context} = $self->{twig}->root;
        $self->{context}->lpod_part($self);
        return TRUE;
        }

#--- destructor --------------------------------------------------------------

sub     DESTROY
        {
        my $self        = shift;
        $self->{context} &&
                $self->{context}->del_att($ODF::lpOD::Common::LPOD_PART);
        delete $self->{context};
        $self->{twig} && $self->{twig}->dispose;
        delete $self->{twig};
        delete $self->{container};
        delete $self->{part};
        $self = {};
        $COUNT--;
        }

#--- basic individual node selection -----------------------------------------

sub     find_node
        {
        my $self        = shift;
        my $tag         = shift;
        my $context     = shift || $self->{context};
        
        return $context->first_descendant($tag);
        }

#=== public part =============================================================
#--- general document management ---------------------------------------------

sub     get_root
        {
        my $self        = shift;
        return $self->{twig}->root;
        }

sub     get_body
        {
        my $self        = shift;
        my $root = $self->get_root;
        my $context = $root->get_xpath('//office:body', 0);
        return $context ?
                $context->first_child
                    (qr'office:(text|spreadsheet|presentation|drawing)')
                        :
                $root->first_child
                    (qr'office:(body|meta|master-styles|settings)');
        }

sub     container
        {
        my $self        = shift;
        return $self->{container};
        }

sub     document
        {
        my $self        = shift;
        return $self->{document};
        }

sub     serialize
        {
        my $self        = shift;
        my %opt         =
                (
                pretty          => FALSE,
                empty_tags      => EMPTY_TAGS,
                output          => undef,
                @_
                );
        $opt{pretty_print} = PRETTY_PRINT if is_true($opt{pretty});
        my $output = $opt{output};
        delete @opt{qw(pretty output)};
        return (defined $output) ?
                $self->{twig}->print($output, %opt)   :
                $self->{twig}->sprint(%opt);
        }

sub     store
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No associated container";
                return FALSE;
                }
        my %opt         = @_;
        my %storage     = ();
        if ($opt{storage})
                {
                %storage = %{$opt{storage}};
                delete $opt{storage};
                }
        return
                $self->{container}->set_part
                        (
                        $self->{part},
                        $self->serialize(%opt),
                        %storage
                        );
        }

#--- general element management ----------------------------------------------

sub     get_element_list
        {
        my ($self, $xpath) = @_;
        return $self->{context}->get_xpath($xpath);
        }

sub     get_element
        {
        my $self        = shift;
        my $xpath       = shift;
        my $offset      = shift || 0;
        return $self->{context}->get_xpath($xpath, $offset);
        }

sub     append_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->append_element(@_);
        }

sub     insert_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->insert_element(@_);
        }

sub     delete_element
        {
        my ($self, $element) = @_;
        return $element->delete;      
        }

#=============================================================================
package ODF::lpOD::Content;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-06T17:52:57';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Styles;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-06T17:52:57';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Meta;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-16T18:27:47';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %META =
        (
        creation_date           => 'meta:creation-date',
        creator                 => 'dc:creator',
        description             => 'dc:description',
        editing_cycles          => 'meta:editing-cycles',
        editing_duration        => 'meta:editing-duration',
        generator               => 'meta:generator',
        initial_creator         => 'meta:initial-creator',
        language                => 'dc:language',
        modification_date       => 'dc:date',
        printed_by              => 'meta:printed-by',
        print_date              => 'meta:print-date',
        subject                 => 'dc:subject',
        title                   => 'dc:title'
        );

#-----------------------------------------------------------------------------

sub     get_body
        {
        my $self        = shift;
        unless ($self->{body})
                {
                $self->{body} = $self->SUPER::get_element('//office:meta');
                }
        return $self->{body};
        }

sub     get_element
        {
        my $self        = shift;
        return $self->get_body->get_element(@_);
        }

sub     get_element_list
        {
        my $self        = shift;
        return $self->get_body->get_element_list(@_);        
        }

sub     append_element
        {
        my $self        = shift;
        return $self->get_body->append_element(@_);
        }

#-----------------------------------------------------------------------------

sub     get_statistics
        {
        my $self        = shift;
        my $stat        = $self->get_element('meta:document-statistic');
        return $stat ? $stat->get_attributes() : undef;
        }

sub     set_statistics
        {
        my $self        = shift;
        my $stat =      $self->get_element('meta:document-statistic') ||
                        $self->append_element('meta:document-statistic');
        return $stat->set_attributes(@_);
        }

#-----------------------------------------------------------------------------

sub     get_keyword_list
        {
        my $self        = shift;
        my $expr        = shift;
        return $self->get_element_list
                        ('meta:keyword', content => $expr);
        }

sub     get_keywords
        {
        my $self        = shift;
        my @kwl         = ();
        for ($self->get_keyword_list(@_))
                {
                push @kwl, $_->get_text;
                }
        return wantarray ? @kwl : join (', ', @kwl);
        }

sub     set_keyword
        {
        my $self        = shift;
        my $kw          = shift // return undef;                #/
        for ($self->get_keyword_list)
                {
                return FALSE if $_->get_text() eq $kw;
                }
        my $e = $self->append_element('meta:keyword');
        $e->set_text($kw);
        return $e;
        }

sub     set_keywords
        {
        my $self        = shift;
        my $input       = join(',', @_);
        foreach my $kw (split(',', $input))
                {
                $kw =~ s/^ *//; $kw =~ s/ *$//;
                $self->set_keyword($kw);
                }
        return $self->get_keywords;
        }

sub     check_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;

        return scalar $self->get_keyword_list($expr);
        }

sub     remove_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;
        my $count       = 0;
        for ($self->get_keyword_list($expr))
                {
                $_->delete; $count++;
                }
        return $count;
        }

#-----------------------------------------------------------------------------

sub     get_user_field
        {
        my $self        = shift;
        my $name        = shift         or return undef;
        my $e = ref $name ?
                        $name
                                :
                        $self->get_element
                                (
                                'meta:user-defined',
                                attribute       => 'name',
                                value           => $name
                                );
        return undef unless $e;
        return wantarray ?
                (
                        $e->get_text(),
                        $e->get_attribute('value type') || 'string'
                )
                :
                $e->get_text;
        }

sub     set_user_field
        {
        my $self        = shift;
        my $name        = shift;
        my $value       = shift;                          #/
        my $type        = shift || 'string';
        unless (is_odf_datatype($type))
                {
                alert "Wrong data type $type";
                return FALSE;
                }
        unless ($name)
                {
                alert "Missing user field name";
                return FALSE;
                }
        $value = check_odf_value($value, $type);
        my $e = $self->get_element
                        (
                        'meta:user-defined',
                        attribute       => 'name',
                        value           => $name
                        )
                        //
                $self->append_element('meta:user-defined');
        $e->set_attribute('name' => $name);
        $e->set_attribute('value type' => $type);
        $e->set_text($value);
        return wantarray ?
                ($e->get_text(), $e->get_attribute('value type'))
                        :
                $e->get_text;
        }

sub     get_user_fields
        {
        my $self        = shift;
        my @result      = ();
        foreach my $e ($self->get_element_list('meta:user-defined'))
                {
                my $f;
                $f->{name}      = $e->get_attribute('name');
                $f->{type}      = $e->get_attribute('value type') // 'string';
                $f->{value}     = $e->get_text() // "";
                push @result, $f;
                }
        return @result;
        }

#-----------------------------------------------------------------------------

our     $AUTOLOAD;
sub     AUTOLOAD
        {
        my $self        = shift;
        $AUTOLOAD       =~ /.*:(.*)/;
        my $method      = $1;
        $method =~ /^([gs]et)_(.*)/;
        my $action      = $1;
        my $object      = $META{$2};

        unless ($action && $object)
                {
                alert "Unsupported method";
                return undef;
                }

        my $e = $self->get_element($object);
        given ($action)
                {
                when (undef)
                        {
                        alert "Unsupported action";
                        }
                when ('get')
                        {
                        return $e ? $e->get_text() : undef;
                        }
                when ('set')
                        {
                        unless ($e)
                                {
                                my $body = $self->get_body;
                                $e = $body->append_element($object);
                                }
                        my $v = shift;
                        if ($object =~ /date$/)
                                {
                                $v = check_odf_value($v, 'date');
                                }
                        return $e->set_text($v);
                        }
                }
        return undef; 
        }

#=============================================================================
package ODF::lpOD::Settings;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-06T17:52:57';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Manifest;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-06T17:52:57';
use ODF::lpOD::Common;
#=============================================================================
1;
