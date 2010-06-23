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
#       Tables
#-----------------------------------------------------------------------------
package ODF::lpOD::Table;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-23T11:30:36';
use ODF::lpOD::Common;
#=============================================================================

our $ROW_FILTER         = 'table:table-row';
our $COLUMN_FILTER      = 'table:table-column';

#--- common utilities --------------------------------------------------------

sub     alpha_to_num
        {
        my $arg = shift         or return 0;
        my $alpha = uc $arg;
        unless ($alpha =~ /^[A-Z]*$/)
                {
                return $arg if $alpha =~ /^[0-9]*$/;
                alert "Wrong value $arg";
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
	my $arg	= shift; return ($arg, @_) unless defined $arg;
	my $coord = uc $arg;
	return ($arg, @_) unless $coord =~ /[A-Z]/;

	$coord	=~ s/\s*//g;
	$coord	=~ /(^[A-Z]*)(\d*)/;
	my $c	= $1;
	my $r	= $2;
	return ($arg, @_) unless ($c && $r);

	my $rownum = $r - 1;
	my $colnum = alpha_to_num($c);
	return ($rownum, $colnum, @_);
	}

sub     translate_range
        {
        my $arg = shift; return ($arg, @_) unless
                                (defined $arg && $arg =~ /:/);
        my $range = uc $arg;
        $range =~ s/\s*//g;
        my ($start, $end) = split(':', $range);
        my @r = ();
        for ($start, $end)
                {
                my $p = uc $_;
                given ($p)
                        {
                        when (undef)
                                {
                                push @r, 0;
                                }
                        when (/^[A-Z]*$/)
                                {
                                push @r, alpha_to_num($p);
                                }
                        when (/^[0-9]*$/)
                                {
                                push @r, ($p - 1);
                                }
                        default
                                {
                                alert "Wrong range end $p";
                                return undef;
                                }
                        }
                }
        return @r;
        }

sub     split_rep
        {
        my      ($elt1, $pos, $limit) = @_;
        
        my $reps = $elt1->get_repeated;
        if ($reps > 1 && defined $limit && ($pos + $reps) > $limit)
                {
                my $beyond = ($pos + $reps) - $limit;
                $reps -= $beyond;
                my $elt2 = $elt1->next;
                unless ($elt2)
                        {
                        $elt2 = $elt1->copy;
                        $elt2->set_repeated($beyond + 1);
                        $elt2->paste_after($elt1);
                        }
                else
                        {
                        $elt2->set_repeated($beyond + $elt2->get_repeated);
                        }
                }
        $pos += $elt1->repeat($reps);
        return $pos;
        }

#--- constructor -------------------------------------------------------------

sub     create
        {
        my $name        = shift;
        unless ($name)
                {
                alert "Missing table name";
                return FALSE;
                }

        my %opt = process_options
                (
                style           => undef,
                display         => undef,
                protected       => undef,
                key             => undef,
                @_
                );

        my $width       = $opt{width}   // 0;
        my $height      = $opt{height}  // 0;
        if ($width < 0 || $height < 0)
                {
                alert "Wrong table size ($height x $width)";
                return FALSE;
                }

        my $t = odf_element->new('table:table');
        $t->set_attribute('name', $name);
        $t->set_attribute('style name', $opt{style});
        $t->set_attribute('protected', odf_boolean($opt{protected}));
        $t->set_attribute('protection key', $opt{key});
        $t->set_attribute('display', odf_boolean($opt{display}));
        $t->set_attribute('print', odf_boolean($opt{print}));
        $t->set_attribute('print ranges', $opt{print_ranges});
        
        $t->add_column(number => $width);
        for (my $i = 0 ; $i < $height ; $i++)
                {
                my $r = $t->add_row();
                $r->add_cell(number => $width);
                }
        
        return $t;
        }

#--- internal method for row & cell repetiion limit --------------------------

sub     set_working_area
        {
        my $self        = shift;
        my ($h, $w)     = @_;
        $self->set_attribute('#lpod:h' => $h);
        $self->set_attribute('#lpod:w' => $w);
        }

sub     clean
        {
        my $self        = shift;
        $_->clean() for $self->children($ROW_FILTER);
        }

#-----------------------------------------------------------------------------

sub     get_row
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $height      = $self->get_height;
        my $max_h       = $self->att('#lpod:h');

        if ($position < 0)
                {
                $position += $height;
                }
        if (($position >= $height) || ($position < 0))
                {
                alert "Row position $position out of range";
                return undef;
                }

        my $row = $self->first_child($ROW_FILTER)
                or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $row->next;          
                $p = ODF::lpOD::Table::split_rep($row, $p, $max_h);
                $p++; $row = $next_elt;
                } until $p >= $position;
        $row = $self->child($position, $ROW_FILTER);     
        ODF::lpOD::Table::split_rep($row, $p, $max_h);
        return $row;
        }

sub     get_row_list
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= -1;
        my @list = ();
        my $elt = $self->get_row($start);
        my $last_elt = $self->get_row($end);
        while ($elt && ! $elt->after($last_elt))
                {
                push @list, $elt;
                $elt = $elt->next;
                }
        return @list;
        }

sub     get_column
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $width       = $self->get_column_count;
        my $max_w       = $self->get_attribute('#lpod:w');

        if ($position < 0)
                {
                $position += $width;
                }
        if (($position >= $width) || ($position < 0))
                {
                alert "Column position $position out of range";
                return undef;
                }

        my $col = $self->first_child($COLUMN_FILTER)
                or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $col->next_sibling($COLUMN_FILTER);
                $p = ODF::lpOD::Table::split_rep($col, $p, $max_w);
                $p++; $col = $next_elt;
                } until $p >= $position;
        $col = $self->child($position, $COLUMN_FILTER);
        ODF::lpOD::Table::split_rep($col, $p, $max_w);
        return $col;
        }

sub     get_column_list
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= -1;
        my @list = ();
        my $elt = $self->get_column($start);
        my $last_elt = $self->get_column($end);
        while ($elt && ! $elt->after($last_elt))
                {
                push @list, $elt;
                $elt = $elt->next;
                }
        return @list;
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = translate_coordinates(@_);
        my $row = $self->get_row($r)    or return undef;
        return $row->get_cell($c);
        }

sub     get_cells
        {
        my $self        = shift;
        my $arg         = shift;
        
        if (defined $arg)
                {
                $arg =~ s/ //g;
                $arg = $arg ? uc($arg) : undef;
                }

        my ($r1, $r2, $c1, $c2);
        given ($arg)
                {
                when (undef)
                        {
                        $r1 = 0; $r2 = -1; $c1 = 0; $c2 = -1;
                        }
                when (/[A-Z]/)
                        {
                        my ($a1, $a2) = split(':', $arg);
                        ($r1, $c1) = translate_coordinates($a1);
                        ($r2, $c2) = translate_coordinates($a2);
                        }
                when (/^[0-9]*$/)
                        {
                        $r1 = $arg; ($c1, $r2, $c2) = @_;
                        }
                default
                        {
                        alert "Wrong range definition syntax";
                        return FALSE;
                        }
                }

        my @t = ();
        for (my $i = $r1, my $r = 0 ; $i <= $r2 ; $i++, $r++)
                {
                my $row = $self->get_row($i);
                foreach (my $j = $c1, my $c = 0 ; $j <= $c2 ; $j++, $c++)
                        {
                        $t[$r][$c] = $row->get_cell($j);
                        }
                }

        return @t;
        }

sub     get_cell_list
        {
        my $self        = shift;
        return $self->get_cells(@_);
        }

sub     add_row
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                @_
                );
        my $ref_elt     = $opt{before} || $opt{after};
        my $expand      = $opt{expand};
        my $position    = undef;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                unless  (
                        $ref_elt->isa(odf_row)
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt{qw(number before after expand)};
        my $elt = odf_create_row(%opt);
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if (defined $number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        return $elt;
        }

sub     add_column
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                @_
                );
        my $ref_elt     = $opt{before} || $opt{after};
        my $expand      = $opt{expand};
        my $position    = undef;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                unless  (
                        $ref_elt->isa(odf_column)
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt{qw(number before after expand)};
        my $elt = odf_create_column(%opt);
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if (defined $number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        return $elt;
        }

#-----------------------------------------------------------------------------

sub     get_height
        {
        my $self        = shift;
        my $height      = 0;
        my $row         = $self->first_child($ROW_FILTER);
        my $max_h       = $self->att('#lpod:h');
        while ($row)
                {
                $height += $row->get_repeated;
                $row = $row->next;
                }
        return (defined $max_h and $max_h < $height) ? $max_h : $height;
        }

sub     get_column_count
        {
        my $self        = shift;
        my $count       = 0;
        my $col         = $self->first_child($COLUMN_FILTER);
        my $max_w       = $self->att('#lpod:w');
        while ($col)
                {
                $count += $col->get_repeated;
                $col = $col->next;
                }
        return (defined $max_w and $max_w < $count) ? $max_w : $count;        
        }

sub     get_size
        {
        my $self        = shift;
        my $height      = 0;
        my $width       = 0;
        my $row         = $self->first_child($ROW_FILTER);
        my $max_h       = $self->att('#lpod:h');
        my $max_w       = $self->att('#lpod:w');
        while ($row)
                {
                $height += $row->get_repeated;
                my $row_width = $row->get_width;
                $width = $row_width if $row_width > $width;
                $row = $row->next;
                }
        
        $height = $max_h if defined $max_h and $max_h < $height;
        return ($height, $width);
        }

sub     contains
        {
        my $self        = shift;
        my $expr        = shift;
        my $segment     = $self->first_descendant(TEXT_SEGMENT);
        while ($segment)
                {
                my %r = ();
                my $t = $segment->get_text;
                return $segment if $t =~ /$expr/;
                $segment = $segment->next_elt($self, TEXT_SEGMENT);
                }
        return FALSE;
        }

#=============================================================================
#       Table columns
#-----------------------------------------------------------------------------
package ODF::lpOD::Column;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-22T15:02:46';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my %opt = process_options
                (
                style   => undef,
                @_
                );

        my $col = odf_element->new('table:table-column') or return undef;
        $col->set_attribute('style name', $opt{style})
                        if defined $opt{style};
        delete $opt{style};
        foreach my $a (keys %opt)
                {
                $col->set_attribute($a, $opt{$a});    
                }
        return $col;
        }

#-----------------------------------------------------------------------------

sub     repeat
        {
        my $self        = shift;
        my $reps        = shift || $self->get_repeated;
        $self->set_repeated(undef);
        return $self->SUPER::repeat($reps);
        }

#-----------------------------------------------------------------------------

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-columns-repeated') // 1;  #/
        }

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-columns-repeated', $rep);
        }

#=============================================================================
#       Table rows
#-----------------------------------------------------------------------------
package ODF::lpOD::Row;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-22T19:24:38';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our     $CELL_FILTER    = qr'table:(covered-|)table-cell';

#-----------------------------------------------------------------------------

sub     create
        {
        my %opt = process_options
                (
                style   => undef,
                @_
                );

        my $row = odf_element->new('table:table-row') or return undef;
        $row->set_attribute('style name', $opt{style})
                        if defined $opt{style};
        delete $opt{style};
        foreach my $a (keys %opt)
                {
                $row->set_attribute($a, $opt{$a});    
                }
        return $row;
        }


#-----------------------------------------------------------------------------

sub     repeat
        {
        my $self        = shift;
        my $reps        = shift || $self->get_repeated;
        $self->set_repeated(undef);
        return $self->SUPER::repeat($reps);
        }

sub     clean
        {
        my $self        = shift;
        my $cell        = $self->last_child($CELL_FILTER)
                or return undef;
        $cell->set_repeated(undef);
        }

#-----------------------------------------------------------------------------

sub     get_cell
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $width       = $self->get_width;
        my $max_w       = $self->parent->get_attribute('#lpod:w');

        if ($position < 0)
                {
                $position += $width;
                }
        if (($position >= $width) || ($position < 0))
                {
                alert "Cell position $position out of range";
                return undef;
                }

        my $cell = $self->first_child($CELL_FILTER)
                or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $cell->next;
                $p = ODF::lpOD::Table::split_rep($cell, $p, $max_w);
                $p++; $cell = $next_elt;
                } until $p >= $position;
        $cell = $self->child($position, $CELL_FILTER);
        ODF::lpOD::Table::split_rep($cell, $p, $max_w);
        return $cell;
        }

sub     get_cell_list
        {
        my $self        = shift;
        my $arg         = shift;
        unless ($arg)
                {
                return $self->children($CELL_FILTER);
                }
        my ($start, $end) = ODF::lpOD::Table::translate_range($arg, shift);
        $start //= 0; $end //= -1;
        my @list = ();
        my $elt = $self->get_cell($start);
        my $last_elt = $self->get_cell($end);
        while ($elt && ! $elt->after($last_elt))
                {
                push @list, $elt;
                $elt = $elt->next;
                }
        return @list;
        }

sub     get_width
        {
        my $self        = shift;
        my $width       = 0;
        my $cell        = $self->first_child($CELL_FILTER);
        my $max_w       = $self->parent->att('#lpod:w');
        while ($cell)
                {
                $width += $cell->get_repeated;
                $cell = $cell->next;
                }
        return (defined $max_w and $max_w < $width) ? $max_w : $width;
        }

sub     add_cell
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                @_
                );
        my $ref_elt    = $opt{before} || $opt{after};
        my $expand      = $opt{expand};
        my $position    = undef;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                unless  (
                        $ref_elt->isa(odf_cell)
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        return undef unless $number && ($number > 0);
        delete @opt{qw(number before after expand)};
        my $elt = odf_create_cell(%opt);
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if (defined $number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        return $elt;
        }

#-----------------------------------------------------------------------------

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-rows-repeated') // 1;  #/
        }

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-rows-repeated', $rep);
        }

#=============================================================================
#       Table cells
#-----------------------------------------------------------------------------
package ODF::lpOD::Cell;
use base 'ODF::lpOD::Field';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-22T19:24:10';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
our     %ATTRIBUTE;
#-----------------------------------------------------------------------------

sub     create
        {
        my $cell = odf_create_field('table:table-cell', @_);
        return $cell ? bless($cell, __PACKAGE__) : undef;
        }

#-----------------------------------------------------------------------------

sub     is_covered
        {
        my $self        = shift;
        my $tag         = $self->get_tag;
        return $tag =~ /covered/ ? TRUE : FALSE;
        }

sub     next
        {
        my $self        = shift;
        return $self->next_sibling($ODF::lpOD::Row::CELL_FILTER);
        }

sub     previous
        {
        my $self        = shift;
        return $self->previous_sibling($ODF::lpOD::Row::CELL_FILTER);
        }

sub     repeat
        {
        my $self        = shift;
        my $reps        = shift || $self->get_repeated;
        $self->set_repeated(undef);
        return $self->SUPER::repeat($reps);
        }

#-----------------------------------------------------------------------------

sub     set_repeated
        {
        my $self        = shift;
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute('table:number-columns-repeated', $rep);
        }

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-columns-repeated') // 1;  #/
        }

#-----------------------------------------------------------------------------

sub     get_content
        {
        my $self        = shift;
        return $self->get_children_elements;
        }

sub     set_content
        {
        my $self        = shift;
        $self->clear;
        foreach my $elt (@_)
                {
                if (ref $elt && $elt->isa(odf_element))
                        {
                        $self->append_element($elt);
                        }
                }
        }

#=============================================================================
1;

