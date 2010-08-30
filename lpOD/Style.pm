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
#	Style handling base package
#-----------------------------------------------------------------------------
package ODF::lpOD::Style;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-08-30T19:48:00';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %STYLE_DEF  =
        (
        text            =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_text_style
                },
        paragraph       =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_paragraph_style
                }
        );

#-----------------------------------------------------------------------------

sub     set_class
        {
        my $self        = shift;
        my $family      = shift || $self->get_family;
        return undef unless $family;
        my $desc        = $STYLE_DEF{$family}   or return undef;
        return bless $self, $desc->{class};
        }

sub     is_default
        {
        my $self        = shift;
        my $tag = $self->get_tag        or return undef;
        return $tag eq 'style:default-style' ? TRUE : FALSE;
        }

#-----------------------------------------------------------------------------

sub	create
	{
	my $family      = shift;
        my %opt         = process_options(@_);
	my $desc = $STYLE_DEF{$family};
	unless ($desc)
	        {
	        alert "Missing or not supported style family"; return FALSE;
	        }

        my $style;
        if ($opt{clone})
                {
                $style = $opt{clone}->clone;
                unless ($style)
                        {
                        alert "Style cloning error"; return undef;
                        }
                my $f = $style->get_family;
                unless ($f eq $family)
                        {
                        alert "Family mismatch";
                        $style->delete;
                        return undef;
                        }
                delete $opt{clone};
                }
        else
                {
                $style = odf_create_element($desc->{tag});
                }
	bless $style, $desc->{class};
        $style->initialize(%opt);
        return $style;
	}

#-----------------------------------------------------------------------------

sub     get_family
        {
        my $self        = shift;
        return $self->get_attribute('family');
        }

#-----------------------------------------------------------------------------

sub     set_properties_context
        {
        my $self        = shift;
        my $area        = shift || $self->get_family;
        my $pt = $self->ns_prefix() . ':' . $area . '-properties';
        return ($self->first_child($pt) || $self->insert_element($pt));
        }

#=============================================================================
package ODF::lpOD::TextStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-08-30T09:08:00';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR =
    (
    font                            => 'style:font-name',
    size                            => 'fo:font-size',
    weight                          => 'fo:font-weight',
    style                           => 'fo:font-style',
    color                           => 'fo:color',
    display                         => 'text:display'
    );

sub     initialize
        {
        my $self        = shift;
        my %opt         =
                (
                class           => 'text',
                @_
                );

        $self->set_attribute('family' => 'text');
        $self->set_attribute('name' => $opt{name});
        $self->set_attribute('display name' => $opt{display_name});
        $self->set_attribute('class' => $opt{class});
        $self->set_attribute('parent style name' => $opt{parent});
        delete @opt{qw(family name display_name class parent)};
        my $result = $self->set_properties(%opt);

        return $result ? $self : undef;
        }

#-----------------------------------------------------------------------------

sub     get_properties
        {
        my $self        = shift;

        my $p = $self->first_child('style:text-properties');
        return $p ? $p->get_attributes : undef;
        }

sub     set_properties
        {
        my $self        = shift;
        my %opt         = @_;
        delete $opt{area};
        my $pt = 'style:text-properties';
        my $pr = $self->first_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                $pr //= $self->insert_element($pt);
                foreach my $k (keys %opt)
                        {
                        if ($k eq 'display')
                                {
                                my $v;
                                given ($opt{$k})
                                        {
                                        when (TRUE)     { $v = 'true'; }
                                        when (FALSE)    { $v = 'none'; }
                                        default         { $v = $opt{$k}; }
                                        }
                                $pr->set_attribute('text:display' => $v);
                                }
                        else
                                {
                                my $att = $ATTR{$k} // $k;
                                $pr->set_attribute($att => $opt{$k});
                                }
                        }
                }
        return $self->get_properties();
        }

sub     set_background
        {
        my $self        = shift;
        my %opt         = @_;
        $self->set_properties('fo:background-color' => $opt{color});
        }

#=============================================================================
package ODF::lpOD::ParagraphStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-08-27T21:33:00';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR =
    (
    line_spacing                    => 'style:line-spacing',
    line_height_at_least            => 'style:line-height-at-least',
    font_independent_line_spacing   => 'style:font-independent-line-spacing',
    together                        => 'fo:keep-together',
    auto_text_indent                => 'style:auto-text-indent'
    );

sub     attribute_name
        {
        my $self        = shift;
        my $property    = shift // return undef;
        my $attribute   = undef;

        if ($property =~ /:/)
                {
                $attribute = $property;
                }
        else
                {
                if ($ATTR{$property})
                        {
                        $attribute = $ATTR{$property};
                        }
                else
                        {
                        $attribute = ($property =~ /^align|^indent/) ?
                                'text-' . $property : $property;
                        my $prefix = ($property =~ /^tab|register/) ?
                                'style' : 'fo';
                        $attribute = $prefix . ':' . $attribute;
                        }
                }
        return $attribute;
        }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self        = shift;
        my %opt         =
                (
                class           => 'text',
                @_
                );

        $self->set_attribute('family' => 'paragraph');
        $self->set_attribute('name' => $opt{name});
        $self->set_attribute('display name' => $opt{display_name});
        $self->set_attribute('class' => $opt{class});
        $self->set_attribute('parent style name' => $opt{parent});
        delete @opt{qw(family name class display_name parent)};
        my $result = $self->set_properties(area => 'paragraph', %opt);

        return $result ? $self : undef;
        }

#-----------------------------------------------------------------------------

sub     get_properties
        {
        my $self        = shift;
        my %opt         =
                (
                area            => 'paragraph',
                @_
                );
        my $p = $self->first_child('style:' . $opt{area} . '-properties');
        return $p ? $p->get_attributes : undef;
        }

sub     set_properties
        {
        my      $self   = shift;
        my      %opt    =
                (
                area            => 'paragraph',
                @_
                );
        my $area = $opt{area}; delete $opt{area};
        return $self->ODF::lpOD::TextStyle::set_properties(%opt)
                if $area eq 'text';
        my $pt = 'style:' . $area . '-properties';
        my $pr = $self->first_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                $pr //= $self->insert_element($pt);

                foreach my $k (keys %opt)
                        {
                        my $att = $self->attribute_name($k) // $k;
                        $pr->set_attribute($att => $opt{$k});
                        }
                }
        return $self->get_properties(area => $area);
        }

sub     set_background
        {
        my $self        = shift;
        my %opt         = @_;
        if (exists $opt{color})
                {
                $self->set_properties('fo:background-color' => $opt{color});
                }
        if (exists $opt{url})
                {
                my $pr = $self->set_properties_context;
                my $im = $pr->first_child('style:background-image');
                $im->delete() if $im;
                if (defined $opt{url})
                        {
                        $im //= $pr->insert_element('style:background-image');
                        $im->set_attribute('xlink:href' => $opt{url});
                        $im->set_attribute('style:repeat' => $opt{repeat});
                        $im->set_attribute('draw:opacity' => $opt{opacity});
                        $im->set_attribute('filter name' => $opt{filter});
                        }
                }
        }

#=============================================================================
1;
