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
#=============================================================================
#       Structured containers : Sections, lists, draw pages, frames, shapes...
#-----------------------------------------------------------------------------
package ODF::lpOD::StructuredContainer;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.102';
use constant PACKAGE_DATE => '2010-11-11T20:00:13';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Section;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
use ODF::lpOD::Common;
#=============================================================================
#--- constructors ------------------------------------------------------------
sub     create
        {
        my $name        = shift;
        unless ($name)
                {
                alert "Missing section name";
                return FALSE;
                }

        my %opt =
                (
                style           => undef,
                url             => undef,
                display         => undef,
                condition       => undef,
                protected       => undef,
                key             => undef,
                @_
                );

        my $s = odf_element->new('text:section');
        if (defined $opt{url})
                {
                $s->set_source($opt{url});
                $opt{protected} = TRUE;
                }
        $s->set_attribute('protected', odf_boolean($opt{protected}));
        $s->set_attribute('name', $name);
        $s->set_attribute('style name', $opt{style});
        $s->set_attribute('protection key', $opt{key});
        $s->set_attribute('display', $opt{display});
        $s->set_attribute('condition', $opt{condition});
        
        return $s;
        }

#-----------------------------------------------------------------------------

sub     set_source
        {
        my $self        = shift;
        my $url         = shift;
        my %attr        = @_;
        
        my $source = $self->insert_element('section source');
        $source->set_attribute('xlink:href', $url);
        $source->set_attributes({%attr});
        return $source;
        }

sub     set_hyperlink
        {
        my $self        = shift;
        return $self->set_source(@_);
        }

#=============================================================================
package ODF::lpOD::List;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-06T13:08:17';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = process_options(@_);
        my $list = odf_element->new('text:list');
        $list->set_style($opt{style});
        $list->set_id($opt{id});
        return $list;
        }

#-----------------------------------------------------------------------------

sub     get_id
        {
        my $self        = shift;
        return $self->get_attribute('xml:id');
        }

sub     set_id
        {
        my $self        = shift;
        return $self->set_attribute('xml:id', shift);
        }

sub     get_item
        {
        my $self        = shift;
        my $p           = shift;
        if (is_numeric($p))
                {
                return $self->get_element('text:list-item', position => $p);
                }
        push @_, $p;
        return $self->get_element('text:list-item', @_);
        }

sub     get_item_list
        {
        my $self        = shift;
        return $self->get_element_list('text:list-item', @_);
        }

sub     add_item
        {
        my $self        = shift;
        my %opt         = process_options
                (
                number          => 1,
                @_
                );
        my $ref_elt     = $opt{after} || $opt{before};
        my $position    = undef;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                $ref_elt = $self->get_item($ref_elt) unless ref $ref_elt;
                unless  (
                        $ref_elt->is('text:list-item')
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong list item $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        my $text = $opt{text};
        my $style = $opt{style};
        my $start = $opt{start_value};
        delete @opt{qw(number before after text style start_value)};
        return undef unless $number && ($number > 0);
        my $elt;
        if ($ref_elt)
                {
                $elt = $ref_elt->clone;
                $elt->cut_children;
                }
        else
                {
                $elt = odf_element->new('text:list-item');
                }
        if (defined $text || defined $style)
                {
                my $p = odf_create_paragraph
                                (text => $text, style => $style);
                $p->paste_last_child($elt);
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        my @items = ();
        push @items, $elt;
        if ($number)
                {
                while ($number > 1)
                        {
                        my $cp = $elt->copy;
                        $cp->paste_after($elt);
                        push @items, $cp;
                        $number--;
                        }
                }
        $elt->set_attribute('start value', $start) if defined $start;
        return  @items;
        }

sub     set_header
        {
        my $self        = shift;
        my $h = $self->get_element('text:list-header');
        $h->delete if $h;
        $h = odf_element->new('text:list-header');
        $h->paste_first_child($self);
        while (@_)
                {
                my $c = shift;
                my $elt = ref $c ? $c : odf_create_paragraph(text => $c);
                $elt->paste_last_child($h);
                }
        return $h;
        }

#=============================================================================
package ODF::lpOD::DrawPage;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-06T13:24:20';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my $id          = shift;
        unless ($id)
                {
                alert "Missing draw page identifier"; return FALSE;
                }
        my %opt         = @_;
        my $dp = odf_element->new('draw:page');
        $dp->set_id($id);
        $dp->set_name($opt{'name'});
        $dp->set_style($opt{style});
        $dp->set_attribute('master page name' => $opt{master});
        $dp->set_attribute(
                'presentation:presentation-page-layout-name' => $opt{layout}
                );
        return $dp;
        }

sub     set_id
        {
        my $self        = shift;
        return $self->set_attribute('id' => shift);
        }

#=============================================================================
package ODF::lpOD::Shape;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.102';
use constant PACKAGE_DATE => '2010-11-13T20:50:09';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = process_options(@_);
        my $tag = $opt{tag}; $tag = 'draw:' . $tag unless $tag =~ /:/;
        my $f = odf_element->new($tag);
        $f->set_attribute('name' => $opt{name});
        $f->set_style($opt{style});
        $f->set_text_style($opt{text_style});
        $f->set_position($opt{position});
        if (defined $opt{page})
                {
                $f->set_anchor_page($opt{page});
                }
        else
                {
                $f->set_attribute('text:anchor-type' => $opt{anchor_type});
                }
        $f->set_title($opt{title});
        $f->set_description($opt{description});
        delete @opt
                {qw(
                        tag name style size position page
                        anchor_type title description
                )};
        foreach my $a (keys %opt)
                {
                $f->set_attribute($a => $opt{$a});
                }
        return $f;
        }

#-----------------------------------------------------------------------------

sub     input_2d
        {
        my $self        = shift;
        return input_2d_value(@_);
        }

sub     set_anchor_page
        {
        my $self        = shift;
        my $number      = shift;
        $self->set_attribute('text:anchor-page-number' => $number);
        $self->set_attribute('text:anchor-type' => 'page');
        return $number;
        }
        
sub     get_anchor_page
        {
        my $self        = shift;
        return $self->get_attribute('text:anchor-page-number');
        }

sub     set_title
        {
        my $self        = shift;
        my $t = $self->get_element('svg:title')
                //
                $self->append_element('svg:title');
        $t->set_text(shift);
        return $t;
        }

sub     get_title
        {
        my $self        = shift;
        my $t = $self->get_element('svg:title') or return undef;
        return $t->get_text;
        }

sub     set_description
        {
        my $self        = shift;
        my $t = $self->get_element('svg:desc')
                //
                $self->append_element('svg:desc');
        $t->set_text(shift);
        return $t;
        }

sub     get_description
        {
        my $self        = shift;
        my $t = $self->get_element('svg:desc') or return undef;
        return $t->get_text;        
        }

sub     set_text_style
        {
        my $self        = shift;
        return $self->set_attribute('text style name' => shift);
        }

sub     get_text_style
        {
        my $self        = shift;
        return $self->get_attribute('text style name');
        }

#=============================================================================
package ODF::lpOD::Area;
use base 'ODF::lpOD::Shape';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-11-13T20:46:34';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = @_;
        my $size        = $opt{size} // "1cm, 1cm";
        delete @opt {qw(start end size)};
        my $a = odf_create_shape(%opt);
        $a->set_size($size)     if $a;
        return $a;
        }

#=============================================================================
package ODF::lpOD::Rectangle;
use base 'ODF::lpOD::Area';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-27T16:46:12';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my $r = odf_create_area(tag => 'rect', @_);
        }

#=============================================================================
package ODF::lpOD::Ellipse;
use base 'ODF::lpOD::Area';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-27T16:46:29';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        return odf_create_area(tag => 'ellipse', @_);
        }

#=============================================================================
package ODF::lpOD::Vector;
use base 'ODF::lpOD::Shape';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-11-13T20:29:38';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = @_;
        my $start       = $opt{start};
        my $end         = $opt{end};
        delete @opt {qw(start end position size)};
        my $v = odf_create_shape(%opt);
        $v->set_start_position($start);
        $v->set_end_position($end);
        return $v;
        }

#-----------------------------------------------------------------------------

sub     set_start_position
        {
        my $self        = shift;
        my ($x, $y)     = input_2d_value(@_);
        $self->set_attribute('svg:x1' => $x);
        $self->set_attribute('svg:y1' => $y);
        return ($x, $y);
        }

sub     set_end_position
        {
        my $self        = shift;
        my ($x, $y)     = input_2d_value(@_);
        $self->set_attribute('svg:x2' => $x);
        $self->set_attribute('svg:y2' => $y);
        return ($x, $y);
        }

sub     get_position
        {
        my $self        = shift;
        my @p           =
                (
                $self->get_attribute('svg:x1'),
                $self->get_attribute('svg:y1'),
                $self->get_attribute('svg:x2'),
                $self->get_attribute('svg:y2')
                );
        return wantarray ? @p : [ @p ];
        }

sub     set_position
        {
        my $self        = shift;
        my $arg         = shift;
        my ($x1, $y1, $x2, $y2);
        if (ref $arg)
                {
                ($x1, $y1, $x2, $y2) = @{$arg};
                }
        else
                {
                ($x1, $y1, $x2, $y2) = ($arg, @_);
                }
        $self->set_attribute('svg:x1' => $x1);
        $self->set_attribute('svg:y1' => $y1);
        $self->set_attribute('svg:x2' => $x2);
        $self->set_attribute('svg:y2' => $y2);
        return wantarray ? ($x1, $y1, $x2, $y2) : [ ($x1, $y1, $x2, $y2) ];
        }

#=============================================================================
package ODF::lpOD::Line;
use base 'ODF::lpOD::Vector';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-27T17:17:10';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        return odf_create_vector(tag => 'line', @_);
        }

#=============================================================================
package ODF::lpOD::Connector;
use base 'ODF::lpOD::Vector';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-27T20:39:30';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = process_options(@_);
        my $cs = $opt{connected_shapes};
        my $gp = $opt{glue_points};
        my $type = $opt{type};
        delete @opt{qw(connected_shapes glue_points type)};
        my $connector = odf_create_vector(tag => 'connector', %opt);
        $connector->set_connected_shapes($cs);
        $connector->set_glue_points($gp);
        $connector->set_type($type);
        return $connector;
        }

#-----------------------------------------------------------------------------

sub     set_connected_shapes
        {
        my $self        = shift;
        my $arg         = shift;
        my $ra = ref $arg       or return undef;
        my ($start, $end);
        if ($ra eq 'ARRAY')
                {
                ($start, $end) = @$arg;
                }
        else
                {
                ($start, $end) = ($arg, @_);
                }
        $self->set_attribute('start shape' => $start);
        $self->set_attribute('end shape' => $end);
        return wantarray ? ($start, $end) : [ ($start, $end) ];
        }

sub     get_connected_shapes
        {
        my $self        = shift;
        my $start = $self->get_attribute('start shape');
        my $end = $self->get_attribute('end shape');
        return wantarray ? ($start, $end) : [ ($start, $end) ];
        }

sub     set_glue_points
        {
        my $self        = shift;
        my $arg         = shift;
        my ($sgp, $egp);
        if (ref $arg)
                {
                ($sgp, $egp) = @$arg;
                }
        else
                {
                ($sgp, $egp) = ($arg, @_);
                }
        $self->set_attribute('start glue point' => $sgp);
        $self->set_attribute('end glue point' => $egp);
        return wantarray ? ($sgp, $egp) : [ ($sgp, $egp) ];
        }

sub     get_glue_points
        {
        my $self        = shift;
        my $sgp = $self->get_attribute('start glue point');
        my $egp = $self->get_attribute('end glue point');
        return wantarray ? ($sgp, $egp) : [ ($sgp, $egp) ];
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift         or return undef;
        unless ($type ~~ [ 'standard', 'lines', 'line', 'curve' ])
                {
                alert "Not allowed connector type $type";
                return FALSE;
                }
        $self->set_attribute('type' => $type);
        return $type;
        }

sub     get_type
        {
        my $self        = shift;
        return $self->get_attribute('type');
        }

#=============================================================================
package ODF::lpOD::Frame;
use base 'ODF::lpOD::Area';
our $VERSION    = '0.103';
use constant PACKAGE_DATE => '2010-07-27T17:25:45';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        return odf_create_area(tag => 'frame', @_);
        }

sub     create_text
        {
        my $text        = shift;
        my $frame       = create(@_)    or return FALSE;
        $frame->set_text_box($text);
        return $frame;
        }

sub     create_image
        {
        my $link        = shift;
        my %opt         = @_;
        unless ($opt{size})
                {
                $opt{size} = image_size($link);
                }
        my $frame       = create(%opt)    or return FALSE;
        $frame->set_image($link);
        return $frame;
        }

#-----------------------------------------------------------------------------

sub     get_image
        {
        my $self        = shift;
        return $self->get_element('draw:image');
        }

sub     set_image
        {
        my $self        = shift;
        my $link        = shift;
        if (ref $link)
                {
                if ($link->is('draw:image'))
                        {
                        $link->paste_last_child($self);
                        return $link;
                        }
                else
                        {
                        alert "Non-valid image element";
                        return FALSE;
                        }
                } 
        unless ($link)
                {
                alert "Missing image URL"; return FALSE;
                }
        my %opt = @_;
        my $image =     $self->get_image()
                        //
                        $self->append_element('draw:image');
        if (is_true($opt{load}))
                {
                my $doc = $self->document;
                if ($doc && $doc->{container})
                        {
                        $link = $doc->add_file($link);
                        }
                }
        $image->set_attribute('xlink:href' => $link);
        foreach my $o (keys %opt)
                {
                my $att = ($o =~ /:/) ? $o : 'xlink:' . $o;
                $image->set_attribute($att => $opt{$o});
                }
        my ($w, $h) = $self->get_size;
        unless ($w || $h)
                {
                $self->set_size(image_size($link));
                }
        return $image;
        }

#-----------------------------------------------------------------------------

sub     get_text_box
        {
        my $self        = shift;
        return $self->get_element('draw:text-box');
        }

sub     set_text_box
        {
        my $self        = shift;
        my $t = $self->get_text_box()
                //
                $self->append_element('draw:text-box');
        my @list        = @_;
        foreach my $e (@list)
                {
                if (ref $e)
                        {
                        $e->paste_last_child($t);
                        }
                else
                        {
                        odf_create_paragraph(text => $e)
                                        ->paste_last_child($t);
                        }
                }
        return $t;
        }

#=============================================================================
package ODF::lpOD::Image;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-07-18T16:04:34';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt         = @_;
        my $image       = odf_create_element('draw:image');
        my $uri         = $opt{url} || $opt{uri};
        if ($uri)
                {
                $image->set_uri($uri);
                }
        elsif ($opt{content})
                {
                $image->set_content($opt{content});
                }
        else
                {
                alert "Missing image resource URI or content";
                return FALSE;
                }
        return $image;
        }

#-----------------------------------------------------------------------------

sub     set_uri
        {
        my $self        = shift;
        my $uri         = shift;
        $self->set_attribute('xlink:href' => $uri);
        my $bin = $self->first_child('office:binary-data');
        $bin->delete() if $bin;
        return $uri;
        }

sub     get_uri
        {
        my $self        = shift;
        return $self->get_attribute('xlink:href');
        }

sub     set_content
        {
        my $self        = shift;
        my $bin =       $self->first_child('office:binary-data');
        unless ($bin)
                {
                $bin = odf_create_element('office:binary-data');
                $bin->paste_last_child($self);
                }
        my $content = shift;
        $bin->_set_text($content);
        $self->del_attribute('xlink:href');
        return $content;                        
        }

sub     get_content
        {
        my $self        = shift;
        my $bin = $self->first_child('office:binary-data') or return undef;
        return $bin->text;
        }

#=============================================================================
1;
