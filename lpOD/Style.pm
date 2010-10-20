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
our $VERSION    = '0.102';
use constant PACKAGE_DATE => '2010-10-20T17:19:05';
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
                },
        list            =>
                {
                tag             => 'text:list-style',
                name            => 'style:name',
                class           => odf_list_style
                },
        outline         =>
                {
                tag             => 'text:outline-style',
                name            => undef,
                class           => odf_outline_style
                }
        );

#-----------------------------------------------------------------------------

sub     required_tag
        {
        my $self	= shift;
        my $family      = $self->get_family()   or return undef;
        return $STYLE_DEF{$family}->{tag};
        }

sub     set_name
        {
        my $self        = shift;
        my $name        = shift;
        return undef unless defined $name;
        return $self->set_tag($name) if (caller() eq 'XML::Twig::Elt');
        my $family = $self->get_family;
        my $attr;
        if ($family)
            {
            my $desc = $STYLE_DEF{$family};
            $attr = $desc->{'name'} if $desc;
            }
        return $attr ?
            $self->set_attribute($attr => $name)    :
            $self->SUPER::set_name($name);
        }

sub     get_name
        {
        my $self	= shift;
        return $self->get_attribute('style:name');
        }

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
                unless (($f eq $family) || ($style->convert($family)))
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
        $style->set_name($opt{name}) if $opt{name};
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
our $VERSION    = '0.102';
use constant PACKAGE_DATE => '2010-10-19T14:17:41';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR =
    (
    line_spacing                    => 'style:line-spacing',
    line_height_at_least            => 'style:line-height-at-least',
    font_independent_line_spacing   => 'style:font-independent-line-spacing',
    together                        => 'fo:keep-together',
    auto_text_indent                => 'style:auto-text-indent',
    shadow                          => 'style:shadow'
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
package ODF::lpOD::ListStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-10-20T17:55:47';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub get_family  { 'list' }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self        = shift;
        my %opt         = @_;
        $self->set_attribute('style:display-name' => $opt{display_name});
        return $self;
        }

sub     level_style_tag
        {
        my $self	= shift;
        my $type        = shift;
        unless ($type)
                {
                alert "Missing item mark type"; return FALSE;
                }
        return ('text:list-level-style-' . $type);
        }

sub     convert
        {
        my $self	= shift;
        my $family      = shift;
        return FALSE unless ($family && ($family eq 'outline'));
        $self->set_name(undef);
        $self->set_tag($STYLE_DEF{outline}->{tag});
        foreach my $ls ($self->get_children(qr'level-style'))
                {
                $ls->set_tag($self->level_style_tag);
                }
        return $self;        
        }

#-----------------------------------------------------------------------------

sub     get_level_style
        {
        my $self	= shift;
        my $level       = shift;
        return $self->get_xpath('.//*[@text:level="' . $level . '"]', 0);
        }

sub	set_level_style
        {
        my $self	= shift;
        my $level       = shift;
        unless (defined $level && $level > 0)
                {
                alert "Missing or wrong level"; return FALSE;
                }
        my %opt = process_options(@_);
        my $e;
        if (defined $opt{clone})
                {
                $e = $opt{clone}->copy;
                my $old = $self->get_level_style($level);
                $old && $old->delete;
                $e->set_attribute(level => $level);
                return $self->append_element($e);
                }
        my $type = $opt{type} || 'number';
        my $tag = $self->level_style_tag($type) or return FALSE;
        $e = odf_create_element($self->level_style_tag($type));
        given ($type)
                {
                when ('number')
                        {
                        $e->set_attributes
                                (
                                'style:num-format'      => $opt{format},
                                'style:num-prefix'      => $opt{prefix},
                                'style:num-suffix'      => $opt{suffix},
                                'start value'           => $opt{start_value},
                                'display levels'        => $opt{display_levels}
                                );
                        }
                when ('bullet')
                        {
                        $e->set_attribute('bullet char' => $opt{character});
                        }
                when ('image')
                        {
                        $e->set_url($opt{url} // $opt{uri});
                        }
                default
                        {
                        $e->delete; undef $e;
                        alert "Unknown item mark type"; return FALSE;
                        }
                }
        $e->set_attribute(level => $level);
        $e->set_style($opt{style});
        my $old = $self->get_level_style($level); $old && $old->delete;
        return $self->append_element($e);
        }

#=============================================================================
package ODF::lpOD::OutlineStyle;
use base 'ODF::lpOD::ListStyle';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-10-20T17:54:51';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub get_family          { 'outline' }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self        = shift;
        return $self;
        }

sub     level_style_tag { 'text:outline-level-style' }

sub     convert
        {
        my $self	= shift;
        my $family      = shift;
        return FALSE unless ($family && ($family eq 'list'));
        $self->set_tag($STYLE_DEF{list}->{tag});
        foreach my $ls ($self->get_children(qr'level-style'))
                {
                $ls->set_tag($self->level_style_tag('number'));
                }
        return $self;
        }

#-----------------------------------------------------------------------------

sub     set_level_style
        {
        my $self	= shift;
        my $level       = shift;
        my %opt         = @_;
        $opt{type}      = 'number';
        return $self->SUPER::set_level_style($level, %opt);
        }

#=============================================================================
1;
