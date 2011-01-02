# Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#
# Author: Jean-Marie Gouarné <jean-marie.gouarne@arsaperta.com>
#
# This file is part of lpOD (see: http://lpod-project.org).
# lpOD is free software; you can redistribute it and/or modify it under
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
#       Text Element classes
#-----------------------------------------------------------------------------
package ODF::lpOD::TextElement;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-30T17:23:17';
use ODF::lpOD::Common;
#=============================================================================

BEGIN   {
        *set_link               = *set_hyperlink
        }

#-----------------------------------------------------------------------------

our     $RECURSIVE_EXPORT       = FALSE;

sub     set_recursive_export
        {
        my $caller      = shift;
        $RECURSIVE_EXPORT       = is_true(shift);
        }

#--- constructor -------------------------------------------------------------

sub     _create  { ODF::lpOD::TextElement->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt = process_options
                (
                tag     => undef,
                style   => undef,
                text    => undef,
                @_
                );
        my $tag = $opt{tag}; $tag = 'text:' . $tag unless $tag =~ /:/;
        my $e = ODF::lpOD::Element->create($tag) or return undef;
        if ($tag eq 'text:h')
                {
                $e->set_attribute('outline level', $opt{level} // 1);
                $e->set_attribute('restart numbering', 'true')
                                if is_true($opt{'restart_numbering'});
                $e->set_attribute('start value', $opt{start_value})
                                if defined $opt{start_value};
                $e->set_attribute('is list header', 'true')
                                if defined $opt{suppress_numbering};
                }
        $e->set_style($opt{style})
                        if defined $opt{style};
        $e->set_text($opt{text})
                        if defined $opt{text};

        return $e;
        }

#=== common tools ============================================================

sub     set_spaces
        {
        my $self        = shift;
        my $count       = shift         or return undef;
        my %opt         = @_;
        
        my $s = $self->insert_element('s', %opt);
        $s->set_attribute('c', $count);
        return $s;
        }

sub     set_line_break
        {
        my $self        = shift;
        return $self->insert_element('line break', @_);
        }

sub     set_tab_stop
        {
        my $self        = shift;
        return $self->insert_element('tab', @_);
        }

#--- split the content with new child elements -------------------------------

sub     split_content
        {
        my $self        = shift;
        my %opt         = process_options
                (
                tag             => undef,
                search          => undef,
                offset          => undef,
                length          => undef,
                content         => undef,
                insert          => undef,
                attributes      => {},
                @_
                );
        if (defined $opt{search} && defined $opt{length})
                {
                alert "Conflicting search and length parameters";
                return FALSE;
                }
        my $search      = $opt{search};
        $opt{repeat} //= (defined $search && ! defined $opt{offset});
        if (is_true($opt{repeat}))
                {
                delete $opt{repeat};
                my $start = $opt{start_mark};
                if ($opt{offset})
                        {
                        $start = $self->split_content(%opt);
                        }
                $opt{offset} = 0;
                my @elts = ();
                do      {
                        $opt{start_mark} = $start;
                        $start = $self->split_content(%opt);
                        push @elts, $start;
                        }
                while ($start);
                return wantarray ? @elts : $elts[0];
                }
        my $tag         = $self->normalize_name($opt{tag});
        if (defined $opt{start_mark} || defined $opt{end_mark})
                {
                $opt{offset} //= 0;
                }
        my $position = $opt{offset} || 0;
        if ($position eq 'end')
                {
                my $e = $self->append_element($tag);
                $e->set_attributes($opt{attributes});
                $e->set_text($opt{text});
                $e->set_class;
                return $e;
                }
        if ($position == 0 && ! defined $search)
                {
                my $e = $self->insert_element($tag);
                $e->set_attributes($opt{attributes});
                $e->set_text($opt{text});
                $e->set_class;
                return $e;
                }
        my $range = $opt{length};
        my %r = $self->search
                        (
                        $search,
                        offset          => $position,
                        range           => $range,
                        backward        => $opt{backward},
                        start_mark      => $opt{start_mark},
                        end_mark        => $opt{end_mark}
                        );
        if (defined $r{segment})
                {
                my $e = ODF::lpOD::Element->create($tag);
                unless ($opt{insert})
                        {
                        my $t = $r{segment}->_get_text;
                        $range = $r{end} - $r{offset}
                                        if defined $search;
                        if (defined $range)
                                {
                                substr($t, $r{offset}, $range, "")
                                }
                        else
                                {
                                $t = substr($t, 0, $r{offset});
                                }
                        $r{segment}->_set_text($t);
                        $e->set_text($opt{text} // $r{match});
                        if      (
                                        (
                                        defined $opt{offset}
                                                &&
                                        $opt{offset} >= 0
                                        )
                                        ||
                                        defined $search
                                )
                                {
                                $e->paste_within
                                        ($r{segment}, $r{offset});
                                }
                        else
                                {
                                if ($r{end} < 0)
                                        {
                                        $e->paste_within
                                                ($r{segment}, $r{end});
                                        }
                                else
                                        {
                                        $e->paste_after($r{segment});
                                        }
                                }

                        }
                else
                        {
                        my $p = $opt{insert} eq 'after' ?
                                $r{end} : $r{offset};
                        $e->paste_within($r{segment}, $p);
                        $e->set_text($opt{text});
                        }

                $e->set_attributes($opt{attributes});
                $e->set_class;
                return $e;
                }
        return undef;
        }

#--- lpOD-specific bookmark setting ------------------------------------------

sub     set_lpod_mark
        {
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
        $opt{tag}               = $ODF::lpOD::Common::LPOD_MARK;
        $opt{attributes}        =
                {
                $ODF::lpOD::Common::LPOD_ID     => $id
                };
        return $self->split_content(%opt);
        }

#--- common bookmark, index mark setting tool --------------------------------

sub     set_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         =
                (
                offset          => undef,
                before          => undef,
                after           => undef,
                @_
                );
        if (defined $opt{before} && defined $opt{after})
                {
                alert "Conflicting before and after parameters";
                return FALSE;
                }
        
        $opt{offset}  //= 0;
        $opt{search}    = $opt{before} // $opt{after};
        if      (defined $opt{after})   { $opt{insert} = 'after'  }
        else                            { $opt{insert} = 'before' }
        $opt{length}    = defined $opt{search} ? undef : 0;

        delete @opt{qw(before after)};
        $opt{tag} = $tag;
        return $self->split_content(%opt);
        }

sub     set_text_mark
        {
        my $self        = shift;
        my %opt         = @_;
        if (defined $opt{content} || ref $opt{offset})
                {
                my $content = $opt{content};
                my ($p1, $p2, $range_end);
                if (ref $opt{offset})
                        {
                        $p1 = $opt{offset}[0];
                        $p2 = $opt{offset}[1];
                        $range_end = $self->set_lpod_mark
                                        (offset => $p2, length => 0)
                                if defined $p2 && defined $opt{content};
                        $opt{end_mark} = $range_end if $range_end;
                        }
                else
                        {
                        $p1 = $opt{offset};
                        $p2 = $opt{offset};
                        }
                delete @opt{qw(content offset)};
                $opt{offset}  = $p1;
                $opt{before}    = $content      if defined $content;
                $opt{role}      = 'start';
                my $start = $self->set_text_mark(%opt)
                        or return FALSE;
                $opt{offset}  = $p2;
                if (defined $content)
                        {
                        $opt{after}     = $content;
                        delete $opt{before};
                        }
                $opt{role}      = 'end';
                my $end   = $self->set_text_mark(%opt)
                        or return FALSE;
                unless ($start->before($end))
                        {
                        $start->delete; $end->delete;
                        alert("Start is not before end");
                        return FALSE;
                        }
                if ($range_end)
                        {
                        $range_end->delete(); $self->normalize;
                        }
                return wantarray ? $start : ($start, $end);
                }

        my $tag;
        given ($opt{role})
                {
                when (undef)
                        {
                        $tag = $opt{tag};
                        }
                when (/^(start|end)$/)
                        {
                        $tag = $opt{tag} . '-' . $_;
                        delete $opt{role};
                        }
                default
                        {
                        alert("Wrong role = $_ option");
                        return undef;
                        }
                }
        
        delete $opt{tag};
        return $self->set_position_mark($tag, %opt);
        }

#=== text content handling ===================================================

sub     set_text
        {
        my $self        = shift;
        my $text        = shift;
        return $self->SUPER::set_text($text, @_)    unless $text;
        return $self->_set_text($text)  if caller() eq 'XML::Twig::Elt';
        
        $self->_set_text("");
        my @lines = split("\n", $text);
        while (@lines)
                {
                my $line = shift @lines;
                my @columns = split("\t", $line);
                while (@columns)
                        {
                        my $column = shift @columns;
                        my @words = split(/(\s\s+)/, $column);
                        foreach my $word (@words)
                                {
                                my $l = length($word);
                                if ($word =~ m/^ +$/)
                                        {
                                        $self->set_spaces
                                            ($l, position => 'LAST_CHILD');
                                        }
                                elsif ($l > 0)
                                        {
                                        my $n = $self->append_element
                                                        (TEXT_SEGMENT);
                                        $n->set_text($word);
                                        }
                                }
                        $self->append_element('tab') if @columns;
                        }
                $self->append_element('line break') if @lines;
                }
        $self->normalize;
        return TRUE;
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = @_;
        $opt{recursive} //= $RECURSIVE_EXPORT;
        
        unless (is_true($opt{recursive}))
                {
                return $self->SUPER::get_text;
                }

        my $text        = undef;
        foreach my $node ($self->children)
                {
                given ($node->get_tag)
                        {
                        when ('text:tab')
                                {
                                $text .= $ODF::lpOD::Common::TAB_STOP;
                                }
                        when ('text:line-break')
                                {
                                $text .= $ODF::lpOD::Common::LINE_BREAK;
                                }
                        when ('text:s')
                                {
                                my $c = $node->get_attribute('c') // 1; #/
                                $text .= " " while $c-- > 0;
                                }
                        default
                                {
                                my $t = $node->get_text(%opt);
                                $text .= $t if defined $t;
                                }
                        }
                }

        return $text;
        }

#=== text internal markup ===================================================

sub     set_span
        {
        my $self        = shift;
        my %opt         = @_;
        unless ($opt{style})
                {
                alert("Missing style name");
                return FALSE;
                }
        $opt{search} = $opt{filter} if exists $opt{filter};  
        $opt{attributes} = { 'style name' => $opt{style} };
        delete @opt{qw(filter style)};
        unless (defined $opt{length}) { $opt{search} //= ".*" }
        return $self->split_content(tag => 'span', %opt);
        }

sub	remove_spans
	{
	my $self	= shift;

        my $tmp = $self->clone;
        $self->delete_children;
        my $count       = 0;
        foreach my $e ($tmp->descendants)
                {
                unless ($e->is('text:span'))
                        {
                        $e->move(last_child => $self);
                        }
                else
                        {
                        $count++;
                        }
                }
        $tmp->delete;
        return $count;
	}

sub     set_hyperlink
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $url         = $opt{url};
        delete $opt{url};
        unless ($url)
                {
                alert("Missing URL"); return FALSE;
                }
        $opt{search} = $opt{filter} if exists $opt{filter};
        $opt{attributes} =
                {
                'xlink:href'            => $url,
                'office:name'           => $opt{name},
                'office:title'          => $opt{title},
                'style name'            => $opt{style},
                'visited style name'    => $opt{visited_style}
                };
        delete @opt{qw(filter name title style visited_style)};
        unless (defined $opt{length}) { $opt{search} //= ".*" }
        return $self->split_content(tag => 'a', %opt);
        }

sub     set_bookmark
        {
        my $self        = shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing bookmark name"; return FALSE;
                }

        return $self->set_text_mark
                (
                tag             => 'bookmark',
                attributes      =>
                        {
                        name            => $name
                        },
                @_
                );
        }

sub     set_index_mark
        {
        my $self        = shift;
        my $text        = shift;
        
        unless ($text)
                {
                alert "Missing index entry text";
                return FALSE;
                }
        
        my %opt         = process_options (@_);

        if ($opt{index_name})
                {
                $opt{type} ||= 'user';
                unless ($opt{type} eq 'user')
                        {
                        alert "Index mark type must be user";
                        return FALSE;
                        }
                }
        else
                {
                $opt{type} ||= 'lexical';
                }
        my $tag;
        my %attr = $opt{attributes} ? %{$opt{attributes}} : ();
        given ($opt{type})
                {
                when (["lexical", "alphabetical"])
                        {
                        $tag = 'alphabetical index mark';
                        }
                when ('toc')
                        {
                        $tag = 'toc mark';
                        $attr{'outline level'} = $opt{level} // 1;
                        }
                when ('user')
                        {
                        unless ($opt{index_name})
                                {
                                alert "Missing index name";
                                return FALSE;
                                }
                        $tag = 'user index mark';
                        $attr{'outline level'} = $opt{level} // 1;
                        }
                default
                        {
                        alert "Wrong index mark type ($opt{type})";
                        return FALSE
                        }
                }

        if (defined $opt{content} || ref $opt{offset} || $opt{role})
                {       # it's a range index mark
                $attr{'id'} = $text;
                }
        else
                {
                $attr{'string value'} = $text;
                }

        delete @opt{qw(type index_name level attributes)};
        $opt{attributes} = {%attr};
        return $self->set_text_mark(tag => $tag, %opt);
        }

sub     set_bibliography_mark
        {
        my $self        = shift;
        my %opt         = process_options(@_);

        my $type_ok;
        foreach my $k (keys %opt)
                {
                if (ref $opt{$k} || ($k ~~ ['content', 'role']))
                        {
                        alert "Not allowed option";
                        delete $opt{$k};
                        next;
                        }
                unless  (
                        $k ~~   [
                                'before', 'after', 'offset',
                                'start_mark', 'end_mark'
                                ]
                        )
                        {
                        if ($k eq 'type')
                                {
                                $type_ok = TRUE;
                                $k = 'bibliography type';
                                }
                        $opt{attributes}{$k} = $opt{$k};
                        delete $opt{$k};
                        }
                }
        alert "Missing type parameter" unless $type_ok;
        
        return $self->set_position_mark('bibliography mark', %opt);
        }

#=== text notes ==============================================================

sub     set_note
        {
        my $self        = shift;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing note identifier"; return FALSE;
                }
        my %opt         = process_options(@_);
        $opt{attributes} =
                {
                'id'            => $id,
                'note class'    => $opt{class}  || $opt{note_class}
                                                || 'footnote'
                };
        my $style       = $opt{style};
        my $text        = $opt{text};
        my $body        = $opt{body};
        my $citation    = $opt{citation};
        my $label       = $opt{label};
        delete @opt{qw(note_class style text body citation label)};

        my $note        = $self->set_position_mark('note', %opt);
        $note->set_citation($citation, $label);
        $note->{style}  = $opt{style};
        if ($body)
                {
                $note->set_body(@{$body});
                }
        else
                {
                $note->set_body($text);
                }

        return $note;
        }

sub     set_annotation
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $date        = $opt{date};
        my $author      = $opt{author};
        my $style       = $opt{style};
        my $content     = $opt{content};
        delete @opt{qw(date author style content)};
        my $a = $self->set_position_mark('office:annotation', %opt);
        $a->set_date($date);
        $a->set_author($author);
        $a->set_style($style);
        $a->set_content(@{$content})    if $content;
        return $a;
        }

#=== text fields =============================================================

sub	set_field
	{
	my $self	= shift;
        my $type        = shift;
        unless ($type)
                {
                alert "Missing field type"; return undef;
                }
	my %opt         = process_options(@_);
        $opt{search} //= $opt{replace}; delete $opt{replace};
        $type = 'user field get' if $type eq 'variable';
        if ($type =~ /^user field/)
                {
                unless ($opt{name})
                        {
                        alert "Missing associated variable name";
                        return undef;
                        }
                }
        else
                {
                unless (ODF::lpOD::TextField::check_type($type))
                        {
                        alert "Unsupported field type"; return undef;
                        }
                }
        OPTION: foreach my $k (keys %opt)
                {
                if (ref $opt{$k} || ($k eq 'role'))
                        {
                        delete $opt{$k};
                        next;
                        }
                unless  (
                        $k ~~   [
                                'before', 'after', 'offset', 'length',
                                'start_mark', 'end_mark', 'search'
                                ]
                        )
                        {
                        given ($k)
                                {
                                when ('fixed')
                                        {
                                        $opt{attributes}{$k} =
                                                odf_boolean($opt{$k});
                                        }
                                when ('style')
                                        {
                                        my $a = 'style:data-style-name';
                                        $opt{attributes}{$a} = $opt{$k};
                                        }
                                default
                                        {
                                        $opt{attributes}{$k} = $opt{$k};
                                        }
                                }
                        delete $opt{$k};
                        }
                }
        my $tag = 'text:' . $type;
        my $field;
        if (defined $opt{search} || defined $opt{length})
                {
                $opt{text} = '';
                $field = $self->split_content(tag => $tag, %opt);
                }
        else
                {
                $field = $self->set_position_mark($tag , %opt);
                }
        return $field;
	}

#=============================================================================
package ODF::lpOD::Paragraph;
use base 'ODF::lpOD::TextElement';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:28:58';
use ODF::lpOD::Common;
#--- constructor -------------------------------------------------------------

sub     _create { ODF::lpOD::Paragraph->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::TextElement->create(tag => 'p', @_);
        }

#=============================================================================
package ODF::lpOD::Heading;
use base 'ODF::lpOD::Paragraph';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:30:12';
use ODF::lpOD::Common;
#--- constructor -------------------------------------------------------------

sub     _create { ODF::lpOD::Heading->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::TextElement->create(tag => 'h', @_);
        }

#--- attribute accessors -----------------------------------------------------

sub     get_level
        {
        my $self        = shift;
        return $self->get_attribute('outline level');
        }

sub     set_level
        {
        my $self        = shift;
        return $self->set_attribute('outline level', @_);
        }

sub     get_suppress_numbering
        {
        my $self        = shift;
        return $self->get_boolean_attribute('is list header');
        }

sub     set_suppress_numbering
        {
        my $self        = shift;
        return $self->set_boolean_attribute('is list header', shift);
        }

sub     set_start_value
        {
        my $self        = shift;
        my $number      = shift;
        unless ($number >= 0)
                {
                alert('Wrong start value');
                return FALSE;
                }
        $self->set_attribute('restart numbering', TRUE);
        $self->set_attribute('start value', $number);
        }

#=============================================================================
1;
