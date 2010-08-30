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
use 5.010_000;
use strict;
#-----------------------------------------------------------------------------
#       Level 0 - Basic XML element handling - ODF Element class
#-----------------------------------------------------------------------------
package ODF::lpOD::Element;
our     $VERSION        = '0.106';
use constant PACKAGE_DATE => '2010-08-30T21:44:00';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use XML::Twig           3.32;
use ODF::lpOD::TextElement;
use ODF::lpOD::StructuredContainer;
use ODF::lpOD::Table;
use ODF::lpOD::Style;
use ODF::lpOD::Attributes;

use base 'XML::Twig::Elt';
#=== element classes =========================================================

our %CLASS    =
        (
        'text:p'                        => odf_paragraph,
        'text:h'                        => odf_heading,
        'text:span'                     => odf_text_element,
        'text:bibliography-mark'        => odf_bibliography_mark,
        'text:note'                     => odf_note,
        'office:annotation'             => odf_annotation,
        'text:changed-region'           => odf_changed_region,
        'text:section'                  => odf_section,
        'text:list'                     => odf_list,
        'table:table'                   => odf_table,
        'table:table-column-group'      => odf_column_group,
        'table:table-header-columns'    => odf_column_group,
        'table:table-row-group'         => odf_row_group,
        'table:table-header-rows'       => odf_row_group,
        'table:table-column'            => odf_column,
        'table:table-row'               => odf_row,
        'table:table-cell'              => odf_cell,
        'table:covered-table-cell'      => odf_cell,
        'draw:page'                     => odf_draw_page,
        'draw:rect'                     => odf_rectangle,
        'draw:ellipse'                  => odf_ellipse,
        'draw:line'                     => odf_line,
        'draw:connector'                => odf_connector,
        'draw:frame'                    => odf_frame,
        'draw:image'                    => odf_image,
        'manifest:file-entry'           => odf_file_entry,
        'style:style'                   => odf_style,
        'style:default-style'           => odf_style
        );

#=== aliases and initialization ==============================================

BEGIN
        {
        *get_tag                        = *XML::Twig::Elt::tag;
        *get_tagname                    = *XML::Twig::Elt::tag;
        *get_children                   = *XML::Twig::Elt::children;
        *get_descendants                = *XML::Twig::Elt::descendants;
        *get_parent                     = *XML::Twig::Elt::parent;
        *previous_sibling               = *XML::Twig::Elt::prev_sibling;
        *clone                          = *XML::Twig::Elt::copy;
        *ungroup                        = *XML::Twig::Elt::erase;
        *get_root                       = *XML::Twig::Elt::root;
        *is_element                     = *XML::Twig::Elt::is_elt;
        *is_text_segment                = *XML::Twig::Elt::is_text;
        *_set_text                      = *XML::Twig::Elt::set_text;
        *_get_text                      = *XML::Twig::Elt::text;
        *_set_tag                       = *XML::Twig::Elt::set_tag;
        *get_element_list               = *get_elements;
        *get_bookmark_list              = *get_bookmarks;
        *get_index_mark_list            = *get_index_marks;
        *get_bibliography_mark_list     = *get_bibliography_marks;
        *get_table_list                 = *get_tables;
        *get_table                      = *get_table_by_name;
        *get_part                       = *lpod_part;
        *get_document                   = *document;
        }

#=== exported constructor ====================================================

sub     create
        {
        my $data        = shift;
        my $element     = undef;
                                # remove leading and trailing spaces
        $data	=~ s/^\s+//;
	$data	=~ s/\s+$//;
	if ($data =~ /^<.*>$/)	# create element from XML string
	        {
	        $element = odf_element->parse($data, @_) or return undef;
                foreach my $e ($element->descendants_or_self)
                        {
                        my $tag = $e->tag;
                        bless $e, ($CLASS{$tag} || odf_element);
                        if ($e->isa(odf_style))
                                {
                                $e->set_class;
                                }
                        }
	        }
	else
	        {
	        $element = odf_element->new($data, @_);
	        }
	return $element;
        }

#=== common element methods ===============================================

our $INIT_CALLBACK   = undef;

sub     new
        {
	my $caller	= shift;
	my $class	= ref($caller) || $caller;
                # odf_element creation
        my $element     = $class->SUPER::new(@_);
                # possible subclassing according to the tag
        my $tag = $element->tag;
        bless $element, $CLASS{$tag} if $CLASS{$tag};
                # optional user-defined post-constructor function
        if ($INIT_CALLBACK && (caller() eq 'XML::Twig'))
                {
                &$INIT_CALLBACK($element);
                }
        return $element;
        }

sub     set_tag
        {
        my $self        = shift;
        my $tag         = shift;
        $self->_set_tag($tag);
        bless $self, $CLASS{$tag} || odf_element;
        return $tag;
        }

sub     set_class       {}

sub     check_tag
        {
        my $self        = shift;
        my $new_tag     = shift;
        my $old_tag     = $self->get_tag;
        return $old_tag unless $new_tag;
        unless ($new_tag eq $old_tag)
                {
                $self->set_tag($new_tag);
                }
        return $self->get_tag;
        }

sub     is
        {
        my $self        = shift;
        my $classname   = shift;
        unless (ref($classname))
                {
                return  (
                        $self->isa($classname) || $classname eq $self->tag
                        ) ? TRUE : FALSE;
                }
        if (ref($classname) eq 'Regexp')
                {
                my $tag = $self->tag;
                return ($tag =~ $classname) ? TRUE : FALSE;
                }
        else
                {
                alert("Wrong reference");
                return undef;
                }
        }

sub     set_id
        {
        my $self        = shift;
        return $self->set_attribute('id' => shift);
        }

sub     get_id
        {
        my $self        = shift;
        return $self->get_attribute('id');
        }

sub     is_child
        {
        my $self        = shift;
        my $ref_elt     = shift;
        my $parent = $self->parent;
        return ($parent && $parent == $ref_elt) ? TRUE : FALSE;
        }

sub     set_child
        {
        my $self        = shift;
        my $tag         = shift;
        my $text        = shift;
        my %attr        = @_;
        my $child =     $self->first_child($tag)
                                //
                        $self->insert_element($tag);
        $child->set_text($text);
        $child->set_attributes(%attr);
        return $child;
        }

sub     next
        {
        my $self        = shift;
        my $context     = shift;
        my $tag         = $self->get_tag;
        unless ($context)
                {
                return $self->next_sibling($tag);
                }
        return $self->next_elt($context, $tag);
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift;
        my $tag         = $self->get_tag;
        unless ($context)
                {
                return $self->previous_sibling($tag);
                }
        return $self->prev_elt($self, $tag);
        }

sub     get_class
        {
        my $self        = shift;
        return Scalar::Util::blessed($self);
        }

sub     get_ancestor
        {
        my $self        = shift;
        return $self->parent(@_);
        }

sub     get_children_elements
        {
        my $self        = shift;
        return $self->children(qr'^[^#]');
        }

sub     get_descendant_elements
        {
        my $self        = shift;
        return $self->descendants(qr'^[^#]');
        }

sub     group
        {
        my $self        = shift;
        my @elts        = @_;
        $_->move(last_child => $self) for @elts;
        }

sub     node_info
        {
        my $self        = shift;
        my %i           = ();
        $i{text}        = $self->_get_text;
        $i{size}        = length($i{text});
        $i{tag}         = $self->tag;
        $i{class}       = $self->get_class;
        $i{attributes}  = $self->get_attributes;
        return %i;
        }

sub     has_text
        {
        my $self        = shift;
        return $self->has_child(TEXT_SEGMENT) ? TRUE : FALSE;
        }

sub     is_text_container
        {
        my $self        = shift;
        my $name = $self->tag;
        return $name =~ /^text:(p|h|span)$/ ? TRUE : FALSE;
        }

sub     normalize_name
        {
        my $self        = shift;
        my $name        = shift // return undef;                        #/
        $name .= ' name' if $name eq 'style';
        if ($name && ! ref $name)
                {
                unless ($name =~ /[:#]/)
                        {
                        my $prefix = $self->ns_prefix;
                        $name = $prefix . ':' . $name   if $prefix;
                        }
                $name =~ s/[ _]/-/g;
                }
        return $name;
        }

sub     repeat
        {
        my $self        = shift;
        unless ($self->parent)
                {
                alert "Repeat not allowed for root elements";
                return FALSE;
                }
        my $r           = shift;
        unless (defined $r)
                {
                my $prefix      = $self->ns_prefix;
                if ($prefix && $prefix eq 'table')
                        {
                        $r = $self->get_repeated;
                        $self->set_repeated(undef);
                        }
                }
        my $count = 0;
        while ($r > 1)
                {
                my $elt = $self->copy;
                $elt->paste_after($self);
                $count++; $r--;
                }
        return $count;
        }

sub     set_lpod_mark
        {
        state $count    = 0;
        my $self        = shift;
        my %opt         = @_;

        my $id;
        if (defined $opt{id})
                {
                $id = $opt{id}; delete $opt{id};
                }
        else
                {
                $id = lpod_common->new_id;
                }

        my $e = $self->insert_element($ODF::lpOD::Common::LPOD_MARK, %opt);
        $e->set_attribute($ODF::lpOD::Common::LPOD_ID, $id);
        return $id;
        }

sub     get_lpod_mark
        {
        my $self        = shift;
        my $id          = shift;
        return $self->get_element
                (
                $ODF::lpOD::Common::LPOD_MARK,
                attribute       => $ODF::lpOD::Common::LPOD_ID,
                value           => $id
                );
        }

sub     remove_lpod_mark
        {
        my $self        = shift;
        my $mark        = $self->get_lpod_mark(shift);
        if ($mark)
                {
                $mark->delete; return TRUE;
                }
        return FALSE;
        }

sub     remove_lpod_marks
        {
        my $self        = shift;
        $_->delete()
                for $self->get_element_list($ODF::lpOD::Common::LPOD_MARK);
        }

sub     set_lpod_id
        {
        my $self        = shift;
        return $self->set_att($ODF::lpOD::Common::LPOD_ID, shift);
        }

sub     remove_lpod_id
        {
        my $self        = shift;
        return $self->del_att($ODF::lpOD::Common::LPOD_ID);
        }

sub     strip_lpod_id
        {
        my $self        = shift;
        return $self->strip_att($ODF::lpOD::Common::LPOD_ID);
        }

sub     lpod_part
        {
        my $self        = shift;
        my $part        = shift;
        if ($part)
                {
                return $self->set_att($ODF::lpOD::Common::LPOD_PART, $part);
                }
        else
                {
                return
                        $self->att($ODF::lpOD::Common::LPOD_PART)       ||
                        $self->root->att($ODF::lpOD::Common::LPOD_PART);
                }
        }

sub     document
        {
        my $self        = shift;
        my $part        = $self->lpod_part      or return undef;
        return $part->document;
        }

#-----------------------------------------------------------------------------

sub     text_segments
        {
        my $self        = shift;
        my %opt         =
                (
                deep    => FALSE,
                @_
                );
        return (is_true($opt{deep})) ?
                $self->descendants(TEXT_SEGMENT)   :
                $self->children(TEXT_SEGMENT);
        }

sub     search_in_text_segment
        {
        my $self        = shift;
        unless ($self->is_text)
                {
                alert("Not in text segment");
                return undef;
                }
        return search_string($self->get_text, @_);
        }

sub     replace_in_text_segment
        {
        my $self        = shift;
        my $expr        = shift;
        my $repl        = shift;

        my ($content, $change_count) = search_string
                        ($self->get_text, $expr, replace => $repl, @_);
        $self->set_text($content) if $change_count;
        return $change_count;
        }

#--- generic element retrieval method ----------------------------------------

sub     _get_elements
        {
        my $self        = shift;
        my $tag         = shift;
        if (ref $tag)
                {
                return $self->descendants($tag);
                }
        my %opt         =
                (
                content         => undef,
                attribute       => undef,
                position        => undef,
                @_
                );
        $tag = $self->normalize_name($tag);
        my $xpath = './/' . ($tag // "");                       #/

        if (defined $opt{content})
                {
                $xpath .=       '[string()=~/' .
                                input_conversion($opt{content}) .
                                '/]';
                }
        if (defined $opt{attribute})
                {
                my $a = $opt{attribute};
                my $v = input_conversion($opt{value});
                $a =~ s/[ _]/-/g;
                unless ($a =~ /:/)
                        {
                        $tag =~ /^(.*):/; $a = $1 . ':' . $a;
                        }
                $xpath .= '[@' . $a . '="' . $v . '"]';
                }

        return defined $opt{position} ?
                $self->get_xpath($xpath, $opt{position}) :
                $self->get_xpath($xpath);
        }

sub     get_element
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         =
                (
                position        => 0,
                @_
                );
        return $self->_get_elements($tag, %opt);
        }

sub     get_element_by_id
        {
        my $self        = shift;
        my $tag         = shift;
        return $self->get_element($tag, attribute => 'id', value => shift);
        }

sub     get_elements
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         = @_;
        delete $opt{position};
        return $self->_get_elements($tag, %opt);
        }

#--- specific unnamed element retrieval methods ------------------------------

sub     get_paragraph
        {
        my $self        = shift;
        my %opt         = @_;
        unless (defined $opt{style})
                {
                return $self->get_element('text:p', %opt);
                }
        else
                {
                return $self->get_element
                        (
                        'text:p',
                        attribute       => 'style name',
                        value           => $opt{style},
                        position        => $opt{position},
                        content         => $opt{content}
                        );
                }
        }

sub     get_paragraphs
        {
        my $self        = shift;
        my %opt         = @_;

        if ($opt{style})
                {
                $opt{attribute} = 'style name';
                $opt{value} = $opt{style};
                delete $opt{style};
                }
        return $self->get_element_list('text:p', %opt);
        }

sub     get_heading
        {
        my $self        = shift;
        my %opt         = @_;
        if (defined $opt{level})
                {
                $opt{attribute} = 'outline level';
                $opt{value} = $opt{level};
                delete $opt{level};
                }
        return $self->get_element('text:h', %opt);
        }

sub     get_headings
        {
        my $self        = shift;
        my %opt         = @_;
        if (defined $opt{level})
                {
                $opt{attribute} = 'outline level';
                $opt{value} = $opt{level};
                delete $opt{level};
                }
        return $self->get_element_list('text:h', %opt);
        }

sub     get_list
        {
        my $self        = shift;
        return $self->get_element('text:list', @_);
        }

sub     get_list_by_id
        {
        my $self        = shift;
        return $self->get_list(attribute => 'xml:id', value => shift);
        }

sub     get_lists
        {
        my $self        = shift;
        return $self->get_element_list('text:list', @_);
        }

#--- table retrieval ---------------------------------------------------------

sub     get_tables
        {
        my $self        = shift;
        return $self->get_element_list('table:table', @_);
        }

sub     get_table_by_name
        {
        my $self        = shift;
        my $name        = shift;
        unless (defined $name)
                {
                alert "Missing table name";
                return FALSE;
                }
        return $self->get_element
                ('table:table', attribute => 'name', value => $name);
        }

sub     get_table_by_position
        {
        my $self        = shift;
        my $position    = shift || 0;
        return $self->get_element('table:table', position => $position);
        }

sub     get_table_by_content
        {
        my $self        = shift;
        my $expr        = shift;
        unless (defined $expr)
                {
                alert "Missing search expression";
                return FALSE;
                }
        foreach my $t ($self->get_tables(@_))
                {
                foreach my $n ($t->descendants(TEXT_SEGMENT))
                        {
                        my $text = $n->get_text()       or next;
                        return $t;
                        }
                }
        return FALSE;
        }

#--- check & retrieval tools for bookmarks, index marks ----------------------

sub     get_position_mark
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift);
        my $name        = shift;
        my $role        = shift;
        unless ($name)
                {
                alert ("Name is mandatory for position mark retrieval");
                return FALSE;
                }
        my $attr = $tag =~ /bookmark/ ? 'text:name' : 'text:id';
        my %opt = (attribute => $attr, value => $name);
        given ($role)
                {
                when (undef)
                        {
                        my $single = $self->get_element($tag, %opt);
                        unless ($single)
                                {
                                my $start = $self->get_element
                                        ($tag . '-start', %opt);
                                my $end   = $self->get_element
                                        ($tag . '-end', %opt);
                                return wantarray ? ($start, $end) : $start;
                                }
                        return $single;
                        }
                when (/^(start|end)$/)
                        {
                        return $self->get_element($tag . '-' . $_, %opt);
                        }
                default
                        {
                        alert "Wrong role $role";
                        return FALSE;
                        }
                }
        }

sub     check_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my $name        = shift;

        my %opt = (attribute => 'text:name', value => $name);

        return TRUE if $self->get_element($tag, %opt);

        my $start = $self->get_position_mark($tag, $name, 'start')
                or return FALSE;
        my $end   = $self->get_position_mark($tag, $name, 'end')
                or return FALSE;
        return $start->before($end) ? TRUE : FALSE;
        }

sub     remove_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my $name        = shift;

        my %opt = (attribute => 'text:name', value => $name);

        my $single      = $self->get_element($tag, %opt);
        if ($single)
                {
                $single->delete;
                return TRUE;
                }

        my $start = $self->get_position_mark($tag, $name, 'start')
                or return FALSE;
        my $end   = $self->get_position_mark($tag, $name, 'end')
                or return FALSE;
        $start->delete;
        $end->delete;
        return TRUE;
        }

#--- text mark retrieval stuff -----------------------------------------------

sub     get_bookmark
        {
        my $self        = shift;
        return $self->get_position_mark('text:bookmark', shift);
        }

sub     get_bookmarks
        {
        my $self        = shift;
        return $self->get_elements(qr'bookmark$|bookmark-start$');
        }

sub     get_index_marks
        {
        my $self        = shift;
        my $type        = shift;

        my $filter;
        given ($type)
                {
                when (undef)
                        {
                        alert "Missing index mark type";
                        }
                when (["lexical", "alphabetical"])
                        {
                        $filter = 'alphabetical-index-mark';
                        }
                when ("toc")
                        {
                        $filter = 'toc-mark';
                        }
                when ("user")
                        {
                        $filter = 'user-index-mark';
                        }
                default
                        {
                        alert "Wrong index mark type";
                        }
                }
        return FALSE unless $filter;
        $filter = $filter . '$|' . $filter . '-start$';
        return $self->get_element_list(qr($filter));
        }

sub     clean_marks
        {
        my $self        = shift;
        my $count = 0;
        my ($tag, $start, $end, $att, $id);
        foreach $start ($self->get_element_list(qr'mark-start$'))
                {
                $tag = $start->get_tag;
                $att = $tag =~ /bookmark/ ? 'text:name' : 'text:id';
                $id = $start->get_attribute($att);
                unless ($id)
                        {
                        $start->delete; $count++;
                        next;
                        }
                $tag =~ s/start$/end/;
                $end = $self->get_element
                        ($tag, attribute => $att, value => $id);
                unless ($end)
                        {
                        $start->delete; $count++;
                        next;
                        }
                unless ($start->before($end))
                        {
                        $start->delete; $end->delete; $count += 2;
                        }
                }
        foreach $end ($self->get_element_list(qr'mark-end$'))
                {
                $tag = $end->get_tag;
                $att = $tag =~ /bookmark/ ? 'text:name' : 'text:id';
                $id = $end->get_attribute($att);
                unless ($id)
                        {
                        $end->delete; $count++;
                        next;
                        }
                $tag =~ s/end$/start/;
                $start = $self->get_element
                        ($tag, attribute => $att, value => $id);
                unless ($start)
                        {
                        $end->delete; $count++;
                        next;
                        }
                unless ($end->after($start))
                        {
                        $start->delete; $end->delete; $count += 2;
                        }
                }
        return $count;
        }

sub     remove_bookmark
        {
        my $self        = shift;
        return $self->remove_position_mark('text:bookmark', shift);
        }

sub     check_bookmark
        {
        my $self        = shift;
        return $self->check_position_mark('text:bookmark', shift);
        }

sub     get_element_by_bookmark
        {
        my $self        = shift;
        my $name        = shift;
        my %opt         = @_;

        my $bookmark = $self->get_position_mark
                ('text:bookmark', $name, $opt{role});
        unless ($bookmark)
                {
                alert("Bookmark not found"); return FALSE;
                }
        return $bookmark->parent;
        }

sub     get_paragraph_by_bookmark
        {
        my $self        = shift;
        my $elt         = $self->get_element_by_bookmark(@_)
                        or return FALSE;
        return $elt->isa(odf_paragraph) ?
                $elt : $elt->get_ancestor(qr'text:(p|h)');
        }

sub     get_bookmark_text
        {
        my $self        = shift;
        my ($start, $end) = $self->get_bookmark(shift);
        unless ($start && $end && $start->before($end))
                {
                alert "The required bookmark in not defined in the context";
                return undef;
                }
        my $text = "";
        my $n = $start->next_elt($self, TEXT_SEGMENT);
        while ($n && $n->before($end))
                {
                $text .= $n->get_text;
                $n = $n->next_elt($self, TEXT_SEGMENT);
                }
        return $text;
        }

sub     get_bibliography_marks
        {
        my $self        = shift;
        my $text        = shift;
        return defined $text ?
                $self->get_elements
                        (
                        'text:bibliography-mark',
                        attribute       => 'identifier',
                        value           => $text
                        )
                        :
                $self->get_elements('text:bibliography-mark');
        }

#--- note retrieval ----------------------------------------------------------

sub     get_note
        {
        my $self        = shift;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing note identifier"; return FALSE;
                }
        return $self->get_element(
                'text:note',
                attribute       => 'id',
                value           => $id
                );
        }

sub     get_notes
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $class       = $opt{class} || $opt{note_class};
        my $label       = $opt{label};
        my $citation    = $opt{citation};

        my $xp =        './/text:note';
        $xp .= '[@text:note-class="' . $class . '"]'    if defined $class;
        if (defined $label || defined $citation)
                {
                $xp .= '/text:note-citation';
                $xp .= '[@text:label="' . $label . '"]'
                                                        if defined $label;
                $xp .= '[string()="' . $citation . '"]'
                                                        if defined $citation;
                my @result = ();
                foreach my $n ($self->get_xpath($xp))
                        {
                        push @result, $n->parent;
                        }
                return @result;
                }
        return $self->get_xpath($xp);
        }

sub     get_annotations
        {
        my $self        = shift;
        my %opt         = @_;
        my $date        = $opt{date};
        my $author      = $opt{author};

        my $xp = './/office:annotation';
        $xp .= '[@dc:date="' . $date . '"]'             if $date;
        $xp .= '[@dc:creator="' . $author . '"]'        if $author;

        return $self->get_xpath($xp);
        }

#--- tracked change retrieval ------------------------------------------------

sub     get_changes
        {
        my $self        = shift;
        my %opt         = @_;
        my $context     = $self;

        unless ($opt{date} || $opt{author})
                {
                return $context->get_elements('text:changed-region');
                }

        my @r = ();
        foreach my $ci ($context->descendants('text:changed-region'))
                {
                my ($elt, $text);
                if ($opt{date})
                        {
                        $elt = $ci->first_descendant('dc:date') or next;
                        $text = $elt->get_text or next;
                        if (ref $opt{date})
                                {
                                my $start       = ${opt{date}}[0];
                                my $end         = ${opt{date}}[1];
                                next if $start  && ($text lt $start);
                                next if $end    && ($text gt $end);
                                }
                        else
                                {
                                next unless $text eq $opt{date};
                                }
                        }
                if ($opt{author})
                        {
                        $elt = $ci->first_descendant('dc:creator') or next;
                        $text = $elt->get_text;
                        next unless $text eq $opt{author};
                        }
                push @r, $ci;
                }
        return @r;
        }

sub     get_change
        {
        my $self        = shift;
        return $self->get_element(
                'text:changed-region',
                attribute       => 'id',
                value           => shift
                );
        }

#--- section retrieval -------------------------------------------------------

sub     get_section
        {
        my $self        = shift;
        return $self->get_element
                ('text:section', attribute => 'text:name', value => shift);
        }

sub     get_sections
        {
        my $self        = shift;
        return $self->get_elements('text:section', @_);
        }

#--- frame & draw page retrieval ---------------------------------------------

sub     get_shape
        {
        my $self        = shift;
        my $type        = shift;
        $type = 'draw:' . $type         unless $type =~ /:/;
        return $self->get_element(
                $type, attribute => 'draw:name', value => shift
                );
        }

sub     get_rectangle
        {
        my $self = shift; return $self->get_shape('rect', @_);
        }

sub     get_rectangles
        {
        my $self = shift; return $self->get_elements('draw:rect', @_);
        }

sub     get_ellipse
        {
        my $self = shift; return $self->get_shape('ellipse', @_);
        }

sub     get_ellipses
        {
        my $self = shift; return $self->get_elements('draw:ellipse', @_);
        }

sub     get_line
        {
        my $self = shift; return $self->get_shape('line', @_);
        }

sub     get_lines
        {
        my $self = shift; return $self->get_elements('draw:line', @_);
        }

sub     get_connector
        {
        my $self = shift; return $self->get_shape('connector', @_);
        }

sub     get_connectors
        {
        my $self = shift; return $self->get_elements('draw:connector', @_);
        }

sub     get_frame
        {
        my $self = shift; return $self->get_shape('frame', @_);
        }

sub     get_frames
        {
        my $self = shift; return $self->get_elements('draw:frame', @_);
        }

sub     get_draw_page_by_position
        {
        my $self        = shift;
        return $self->get_element('draw:page', position => shift);
        }

sub     get_draw_page_by_name
        {
        my $self        = shift;
        return $self->get_element(
                'draw:page', attribute => 'name', value => shift
                );
        }

sub     get_draw_page
        {
        my $self        = shift;
        my $arg         = shift;
        return $self->get_element(
                'draw:page', attribute => 'id', value => $arg
                )               ||
                $self->get_draw_page_by_name($arg);
        }

sub     get_draw_pages
        {
        my $self = shift; return $self->get_elements('draw:page', @_);
        }

#-----------------------------------------------------------------------------

sub     get_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        return output_conversion($self->att($name));
        }

sub     get_attributes
        {
        my $self        = shift;
        return undef unless $self->is_element;
        my $atts = $self->atts          or return undef;
        my %attr = %{$atts};
        my %result = ();
        $result{$_} = output_conversion($attr{$_}) for keys %attr;

        return wantarray ? %result : { %result };
        }

sub     set_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        my $value       = input_conversion(shift);
	return defined $value ?
                $self->set_att($name, $value) : $self->del_attribute($name);
        }

sub     set_boolean_attribute
        {
        my $self        = shift;
        my ($name, $value) = @_;
        $value = odf_boolean($value);
        return $self->set_attribute($name, $value);
        }

sub     get_boolean_attribute
        {
        my $self        = shift;
        my $value       = $self->get_attribute(shift);
        given ($value)
                {
                when (undef)
                        {
                        return undef;
                        }
                when ('true')
                        {
                        return TRUE;
                        }
                when ('false')
                        {
                        return FALSE;
                        }
                default
                        {
                        alert("Improper ODF boolean");
                        return undef;
                        }
                }
        }

sub     input_convert_attributes
        {
        my $self        = shift;
        my $in          = shift;
        my %out         = ();
        my $prefix      = $self->ns_prefix;
        foreach my $kin (keys %{$in})
                {
                my $kout = $kin;
                unless ($kout =~ /:/)
                        {
                        $kout = $prefix . ':' . $kout;
                        }
                $kout =~ s/ /-/g;
                $out{$kout} = input_conversion($in->{$kin});
                }
        return wantarray ? %out : { %out };
        }

sub     set_attributes
        {
        my $self        = shift;
        my $attr        = shift         or return undef;
        my %attr        = ref $attr ? %{$attr} : ($attr, @_);

        foreach my $k (keys %attr)
                {
                $self->set_attribute($k, $attr{$k});
                }
        return $self->get_attributes;
        }

sub     del_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        return $self->att($name) ? $self->del_att($name) : FALSE;
        }

sub     clear
        {
        my $self        = shift;
        return $self->_set_text('');
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = (recursive => FALSE, @_);
        my $text        = undef;
        if ($self->is_text)
                {
                $text = $self->text;
                }
        elsif (is_true($opt{recursive}))
                {
                foreach my $t ($self->descendants(TEXT_SEGMENT))
                        {
                        $text .= $t->text;
                        }
                }
        else
                {
                $text = $self->text_only;
                }
        return output_conversion($text);
        }

sub     set_text
        {
        my $self        = shift;
        my $text        = shift;
        return undef unless defined $text;
        return caller() ne 'XML::Twig::Elt' ?
                $self->_set_text(input_conversion($text))       :
                $self->_set_text($text);
        }

sub     get_text_content
        {
        my $self        = shift;
        my $t           = "";
        foreach my $p ($self->descendants('text:p'))
                {
                $t .= ($p->get_text(@_) // "");                   #/
                }
        return $t;
        }

sub     set_text_content
        {
        my $self        = shift;
        my $text        = shift;
        my %opt         = @_;

        my @paragraphs = $self->descendants('text:p');
        my $p = shift @paragraphs;
        unless (defined $p)
                {
                $p = create_element('text:p');
                $p->paste_first_child($self);
                }
        else
                {
                $_->delete() for @paragraphs;
                }
        $p->set_style($opt{style}) if $opt{style};
        return $p->set_text($text);
        }

sub     get_name
        {
        my $self        = shift;
        return $self->get_attribute('name');
        }

sub     get_family
        {
        my $self        = shift;
        return undef;
        }

sub     set_name
        {
        my $self        = shift;
        my $name        = shift;
        return undef unless defined $name;
        return caller() eq 'XML::Twig::Elt' ?
                $self->set_tag($name)           :
                $self->set_attribute('name' => $name);
        }

sub     get_style
        {
        my $self        = shift;
        return $self->get_attribute('style name');
        }

sub     set_style
        {
        my $self        = shift;
        return $self->set_attribute('style name', @_);
        }

sub     insert_element
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift) or return undef;
        my %opt         =
                        (
                        position        => 'FIRST_CHILD',
                        @_
                        );

        my $new_elt = ref $tag ? $tag : odf_create_element($tag);

        if (defined $opt{after})
                {
                return $new_elt->paste_after($opt{after});
                }
        elsif (defined $opt{before})
                {
                return $new_elt->paste_before($opt{before});
                }

        given($opt{position})
                {
                when (/^(FIRST_CHILD|LAST_CHILD)$/)
                        {
                        $new_elt->paste((lc $opt{position}) => $self);
                        }
                when ('NEXT_SIBLING')
                        {
                        $new_elt->paste_after($self);
                        }
                when ('PREV_SIBLING')
                        {
                        $new_elt->paste_before($self);
                        }
                when ('WITHIN')
                        {
                        if ($opt{offset})
                            {
                            $new_elt->paste_within($self, $opt{offset});
                            }
                        else
                            {
                            $new_elt->paste_first_child($self);
                            }
                        }
                default
                        {
                        alert("Wrong position");
                        return FALSE;
                        }
                }
        return $new_elt;
        }

sub     append_element
        {
        my $self        = shift;
        return $self->insert_element(shift, position => 'LAST_CHILD');
        }

sub     serialize
        {
        my $self        = shift;
        my %opt         = process_options
                (
                pretty          => FALSE,
                empty_tags      => EMPTY_TAGS,
                @_
                );

        $self->set_pretty_print(PRETTY_PRINT) if is_true($opt{pretty});
        $self->set_empty_tag_style($opt{empty_tags});
        delete @opt{qw(pretty empty_tags)};
        return $self->sprint(%opt);
        }

#=============================================================================

sub     _search_forward
        {
        my $self        = shift;
        my $expr        = shift;
        my %opt         = (@_);

        my $offset      = $opt{offset};

        my ($target_node, $n, $start_pos, $end_pos, $match);
        if ($self->is_text)
                {
                $n = $self;
                }
        elsif ($opt{start_mark})
                {
                if ($opt{start_mark}->is_text)
                        {
                        $n = $opt{start_mark};
                        }
                else
                        {
                        $n = $opt{start_mark}
                                        ->last_descendant
                                        ->next_elt($self, TEXT_SEGMENT);
                        }
                }
        else
                {
                $n = $self->first_descendant(TEXT_SEGMENT);
                }
        my %info = $n->node_info() if $n;
        if (defined $offset)
                {
                while ($n && $offset >= $info{size})
                        {
                        if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                                {
                                $n = undef; last;
                                }
                        $offset -= $info{size};
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        }
                }
        while ($n && !defined $start_pos)
                {
                if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                        {
                        $n = undef; last;
                        }
                unless (defined $expr)
                        {
                        $start_pos = $offset;
                        $match = defined $opt{range} ?
                                substr($info{text}, $start_pos, $opt{range}) :
                                substr($info{text}, $start_pos);
                        $end_pos = $start_pos + length($match);
                        }
                else
                        {
                        ($start_pos, $end_pos, $match) =
                                search_string
                                        (
                                        $info{text},
                                        $expr,
                                        offset  => $offset,
                                        range   => $opt{range}
                                        );
                        }
                if (defined $start_pos)
                        {
                        $target_node = $n;
                        }
                else
                        {
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        $offset = 0;
                        }
                }
        return wantarray ?
                ($target_node, $start_pos, $match, $end_pos)    :
                $start_pos;
        }

sub     _search_backward
        {
        my $self        = shift;
        my $expr        = shift;
        my %opt         = (@_);

        my $offset      = $opt{offset};
        if (defined $offset && $offset > 0)
                {
                $offset = -abs($offset);
                }
        my ($target_node, $n, $start_pos, $end_pos, $match);

        if ($self->is_text)
                {
                $n = $self;
                }
        elsif ($opt{start_mark})
                {
                unless ($opt{start_mark}->is_text)
                        {
                        $n = $opt{start_mark}->prev_elt($self, TEXT_SEGMENT);
                        }
                else
                        {
                        $n = $opt{start_mark};
                        }
                }
        else
                {
                $n = $self->last_descendant(TEXT_SEGMENT);
                }
        my %info = $n->node_info() if $n;
        if (defined $offset)
                {
                while ($n && abs($offset) >= $info{size})
                        {
                        if ($opt{end_mark} && ! $n->after($opt{end_mark}))
                                {
                                $n = undef; last;
                                }
                        $offset += $info{size};
                        $n = $n->prev_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        }
                }
        while ($n && !defined $start_pos)
                {
                if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                        {
                        $n = undef; last;
                        }
                unless (defined $expr)
                        {
                        $start_pos = $offset;
                        $match = defined $opt{range} ?
                                substr($info{text}, $start_pos, $opt{range}) :
                                substr($info{text}, $start_pos);
                        $end_pos = $start_pos + length($match);
                        }
                else
                        {
                        ($start_pos, $end_pos, $match) =
                                search_string
                                        (
                                        $info{text},
                                        $expr,
                                        offset  => $offset,
                                        range   => $opt{range}
                                        );
                        }
                if (defined $start_pos)
                        {
                        $target_node = $n;
                        }
                else
                        {
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        $offset = 0;
                        }
                }
        return wantarray ?
                ($target_node, $start_pos, $match, $end_pos)    :
                $start_pos;
        }

sub     search
        {
        my $self        = shift;
        my $expr        = input_conversion(shift);
        my %opt         = process_options
                (
                backward        => FALSE,
                start_mark      => undef,
                end_mark        => undef,
                offset          => undef,
                range           => undef,
                @_
                );
        unless (defined $expr || defined $opt{offset})
                {
                alert("Missing search argument");
                return undef;
                }

        my $backward = $opt{backward}; delete $opt{backward};
        if (defined $opt{offset} && $opt{offset} < 0)
                {
                $backward = TRUE;
                }
        my %r = ();
        my $match = undef;
        if(is_false($backward))
                {
                ($r{segment}, $r{offset}, $match, $r{end}) =
                        $self->_search_forward($expr, %opt);
                }
        else
                {
                ($r{segment}, $r{offset}, $match, $r{end}) =
                        $self->_search_backward($expr, %opt);
                }
        $r{match} = output_conversion($match);
        return %r;
        }

sub     replace
        {
        my $self        = shift;
        my $expr        = shift;
        my $repl        = shift;
        my %opt         =
                (
                deep    => TRUE,
                @_
                );

        my $deep = $opt{deep}; delete $opt{deep};
        my $count = 0;
        foreach my $segment ($self->text_segments(deep => $deep))
                {
                $count += $segment->replace_in_text_segment
                                                ($expr, $repl, %opt);
                }
        return $count;
        }

#=============================================================================

our     $AUTOLOAD;

sub     AUTOLOAD
        {
        $AUTOLOAD       =~ /(.*:)(.*)/;
        my $package     = $1;
        my $method      = $2;
        my $element     = shift;

        $method =~ /^([gs]et)_(.*)/;
        my $action      = $1;

        no strict;
        my $target = ${$package . "ATTRIBUTE"}{$2};
        use strict;
        unless ($action && $target)
                {
                alert "Unknown method $method @_";
                return undef;
                }
        my $name = $target->{attribute};
        my $type = $target->{type};

        given ($action)
                {
                when ('get')
                        {
                        return $element->get_attribute($name, @_);
                        }
                when ('set')
                        {
                        my $value = input_conversion(shift);
                        if ($type)
                                {
                                $value = check_odf_value($value, $type);
                                }
                        return defined $value ?
                                $element->set_att($name => $value) :
                                $element->del_attribute($name);
                        }
                default
                        {
                        alert "Unknown method $method @_";
                        }
                }

        return undef;
        }

sub     not_allowed
        {
        my $self        = shift;
        my $tag         = $self->get_tag;
        alert "Not allowed for this $tag elements";
        return undef;
        }

#=============================================================================
package ODF::lpOD::BibliographyMark;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-11T23:40:55';
#=============================================================================
package ODF::lpOD::Note;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-08-03T12:14:00';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_text               = *set_body;
        }

#-----------------------------------------------------------------------------

sub     create
        {
        my $id          = shift;
        unless ($id)
                {
                alert "Missing mandatory note identifier";
                return FALSE;
                }
        my %opt = process_options
                (
                class           => 'footnote',
                @_
                );
        my $note = odf_create_element('text:note');
        $note->set_id($id);
        $note->set_citation($opt{citation}, $opt{label});
        $note->{style}  = $opt{style};
        if ($opt{body})
                {
                $note->set_body(@{$opt{body}});
                }
        else
                {
                $note->set_body($opt{text});
                }

        return $note;
        }

#-----------------------------------------------------------------------------

sub     get_citation
        {
        my $self        = shift;
        my $c   = $self->first_child('text:note-citation')
                                or return undef;
        return $c->get_text;
        }

sub     set_citation
        {
        my $self        = shift;
        my $text        = shift;
        my $label       = shift;
        my $c = $self->set_child('text:note-citation');
        $c->set_attribute('label' => $label) if defined $label;
        $c->set_text($text);
        return $c;
        }

sub     set_label
        {
        my $self        = shift;
        my $label       = shift;
        my $c = $self->set_child('text:note-citation');
        $c->set_attribute('label' => $label) if defined $label;
        return $c;
        }

sub     get_label
        {
        my $self        = shift;
        my $c   = $self->first_child('text:note-citation')
                                or return undef;
        return $c->get_attribute('label');
        }

sub     get_body
        {
        my $self        = shift;
        return $self->first_child('text:note-body');
        }

sub     set_body
        {
        my $self        = shift;
        my $body =      $self->get_body();
        if ($body)
                {
                $body->cut_children;
                }
        else
                {
                $body = $self->append_element('text:note-body');
                }
        foreach my $arg (@_)
                {
                if (ref $arg)
                        {
                        $arg->paste_last_child($body);
                        }
                else
                        {
                        my $p = odf_create_paragraph(
                                text => $arg, style => $self->{style}
                                );
                        $p->paste_last_child($body);
                        }
                }
        return $body;
        }

#=============================================================================
package ODF::lpOD::Annotation;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-08-03T12:22:19';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_creator            = *set_author;
        *get_creator            = *get_author;
        }

#-----------------------------------------------------------------------------

sub     create
        {
        my %opt = @_;
        my $a   = odf_create_element('office:annotation');
        $a->set_date($opt{date});
        $a->set_author($opt{author});
        $a->set_style($opt{style});
        $a->set_content(@{$opt{content}})        if $opt{content};
        return $a;
        }

#-----------------------------------------------------------------------------

sub     set_date
        {
        my $self        = shift;
        my $date        = shift;
        my $elt = $self->set_child('dc:date');
        unless ($date)
                {
                return $elt->set_text(iso_date);
                }
        else
                {
                my $d = check_odf_value($date, 'date');
                unless ($d)
                        {
                        alert "Wrong date"; return undef;
                        }
                return $elt->set_text($d);
                }
        }

sub     get_date
        {
        my $self        = shift;
        my $elt = $self->first_child('dc:date')         or return undef;
        return $elt->get_text;
        }

sub     set_author
        {
        my $self        = shift;
        my $elt = $self->set_child('dc:creator');
        return $elt->set_text
                (
                shift
                        //
                (scalar getlogin())
                        //
                (scalar getpwuid($<))
                        //
                $<
                );
        }

sub     get_author
        {
        my $self        = shift;
        my $elt = $self->first_child('dc:creator')      or return undef;
        return $elt->get_text;
        }

sub     get_content
        {
        my $self        = shift;
        return $self->children;
        }

sub     set_content
        {
        my $self        = shift;
        $self->cut_children;
        foreach my $arg (@_)
                {
                if (ref $arg)
                        {
                        $arg->paste_last_child($self);
                        }
                else
                        {
                        my $p = odf_create_paragraph(
                                text => $arg, style => $self->{style}
                                );
                        $p->paste_last_child($self);
                        }
                }
        return $self->get_content;
        }

sub     set_style
        {
        my $self        = shift;
        return $self->{style} = shift;
        }

sub     get_style
        {
        my $self        = shift;
        return $self->{style};
        }

sub     set_text
        {
        my $self        = shift;
        return $self->set_content(@_);
        }

sub     get_text
        {
        my $self        = shift;
        return $self->get_text_content(@_);
        }

#=============================================================================
package ODF::lpOD::ChangedRegion;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-08-12T11:59:34';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_changed_context
        {
        my $self        = shift;
        my $tcr = $self->parent('text:tracked-changes');
        my $context = $tcr ? $tcr->parent() : undef;
        unless ($context)
                {
                alert "Unknown tracked change context";
                }
        return $context;
        }

sub     get_info
        {
        my $self        = shift;
        my $tag         = shift;
        $tag = 'dc:' . $tag unless $tag =~ /:/;
        my $info = $self->first_descendant($tag)        or return undef;
        return $info->get_text;
        }

sub     get_date
        {
        my $self        = shift;
        return $self->get_info('date');
        }

sub     get_author
        {
        my $self        = shift;
        return $self->get_info('creator');
        }

sub     get_type
        {
        my $self        = shift;
        my $t = $self->first_child      or return undef;
        my $type = $t->get_tag; $type =~ s/^text://;
        return $type;
        }

sub     get_deleted_content
        {
        my $self        = shift;
        my $deleted = $self->first_child('text:deletion') or return undef;
        my @content = ();
        foreach my $e ($deleted->children)
                {
                my $tag = $e->get_tag;
                push @content, $e unless $tag eq 'office:change-info';
                }
        return wantarray ? @content : [ @content ];
        }

sub     get_change_mark
        {
        my $self        = shift;
        my $id = $self->get_id;
        my $context = $self->get_changed_context        or return undef;
        my $type = $self->get_type();
        unless ($type)
                {
                alert "Unknown change type"; return undef;
                }
        my $tag = ($type eq 'deletion') ? 'text:change' : 'text:change-start';
        return $context->get_element(
                        $tag,
                        attribute       => 'change id',
                        value           => $id
                        );
        }

sub     get_insertion_marks
        {
        my $self        = shift;
        my $id = $self->get_id;
        my $context = $self->get_changed_context        or return undef;
        my $start = $context->get_element(
                        'text:change-start',
                        attribute       => 'change id',
                        value           => $id
                        );
        my $end   = $context->get_element(
                        'text:change-end',
                        attribute       => 'change id',
                        value           => $id
                        );
        return wantarray ? ($start, $end) : [ $start, $end ];
        }

#=============================================================================
package ODF::lpOD::FileEntry;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-07-21T09:35:55';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_text       = *not_allowed;
        *insert_element = *not_allowed;
        *append_element = *not_allowed;
        }

#-----------------------------------------------------------------------------

our     @ALLOWED_ATTRIBUTES = ('manifest:media-type', 'manifest:full-path');

sub     set_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        unless ($name ~~ [ @ALLOWED_ATTRIBUTES ])
                {
                alert "Attribute $name is not allowed";
                return FALSE;
                }
        return $self->SUPER::set_attribute($name, @_);
        }

sub     get_path
        {
        my $self        = shift;
        return $self->get_attribute('full path');
        }

sub     set_path
        {
        my $self        = shift;
        my $path        = shift;
        unless ($path)
                {
                alert "Missing or wrong path"; return FALSE;
                }
        my $old_path = $self->get_path;
        my $lpod_part = $self->lpod_part;
        my $other = $lpod_part ? $lpod_part->get_entry($path) : undef;
        if ($other)
                {
                if ($other == $self)
                        {
                        return TRUE;
                        }
                else
                        {
                        alert "Non unique entry path $path";
                        return FALSE;
                        }
                }
        $self->set_attribute('full path' => $path);
        if ($path =~ /.\/$/)
                {
                $self->set_attribute('media type' => "");
                }
        return TRUE;
        }

sub     get_type
        {
        my $self        = shift;
        return $self->get_attribute('media type');
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift // "";                                  #/
        return $self->set_attribute('media type' => $type);
        }

#=============================================================================
1;
