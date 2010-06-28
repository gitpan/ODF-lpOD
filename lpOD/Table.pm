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
package ODF::lpOD::Matrix;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-28T11:15:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

use constant    ROW_FILTER      => 'table:table-row';
use constant    COLUMN_FILTER   => 'table:table-column';
use constant    CELL_FILTER     => qr'table:(covered-|)table-cell';
use constant    TABLE_FILTER    => 'table:table';

#--- utility functions -------------------------------------------------------

sub     alpha_to_num
        {
        my $arg = shift         or return 0;
        $arg = shift if ref($arg) || $arg eq __PACKAGE__;
        my $alpha = uc $arg;
        unless ($alpha =~ /^[A-Z]*$/)
                {
                return $arg if $alpha =~ /^[0-9\-]*$/;
                alert "Wrong alpha value $arg: digits not allowed";
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
	my $arg	= shift // return undef;                                #/
        $arg = shift if ref($arg) || $arg eq __PACKAGE__;
	return ($arg, @_) unless defined $arg;
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
        my $arg = shift // return undef;                                #/
        $arg = shift if ref($arg) || $arg eq __PACKAGE__;
        return ($arg, @_) unless (defined $arg && $arg =~ /:/);
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
                        when (/^[0-9\-]*$/)
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
        my $elt1 = shift or return undef;
        $elt1 = shift if $elt1 eq __PACKAGE__;
        my ($pos, $limit) = @_;
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

#--- utility methods ---------------------------------------------------------

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
        $_->clean() for $self->children(ROW_FILTER);
        }

sub     all_rows
        {
        my $self        = shift;
        return $self->descendants(ROW_FILTER);
        }

sub     all_columns
        {
        my $self        = shift;
        return $self->descendants(COLUMN_FILTER);
        }

sub     all_cells
        {
        my $self        = shift;
        return $self->descendants(CELL_FILTER);
        }

#-----------------------------------------------------------------------------

sub     set_group
        {
        my $self        = shift;
        my $type        = shift;
        my $start       = shift;
        my $end         = shift;
        unless ($start && $end)
                {
                alert "Range not valid"; return FALSE;
                }
        unless ($start->before($end))
                {
                alert "Start element is not before end element";
                return FALSE;
                }
        unless ($start->is_child($self) && $end->is_child($self))
                {
                alert "Grouping not allowed"; return FALSE;
                }
        my $group = odf_element->new('table:table-' . $type . '-group');
        $group->paste_before($start);
        my @elts = (); my $e = $start;
        do      {
                push @elts, $e;
                $e = $e->next_sibling;
                }
                while ($e && ! $e->after($end));
        $group->group(@elts);
        my %opt         = @_;
        $group->set_attribute('display', odf_boolean($opt{display}));
        return $group;        
        }

sub     get_group
        {
        my $self        = shift;
        my $type        = shift;
        my $position    = shift;
        return $self->child($position, 'table:table-' . $type . '-group');
        }

#-----------------------------------------------------------------------------

sub     get_size
        {
        my $self        = shift;
        my $height      = 0;
        my $width       = 0;
        my $row         = $self->first_row;
        my $max_h       = $self->att('#lpod:h');
        my $max_w       = $self->att('#lpod:w');
        while ($row)
                {
                $height += $row->get_repeated;
                my $row_width = $row->get_width;
                $width = $row_width if $row_width > $width;
                $row = $row->next($self);
                }
        
        $height = $max_h if defined $max_h and $max_h < $height;
        return ($height, $width);
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
package ODF::lpOD::ColumnGroup;
use base 'ODF::lpOD::Matrix';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-28T16:26:04';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create { return odf_element->new('table:table-column-group', @_); }

#-----------------------------------------------------------------------------

sub     first_column
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'column')        or return undef;
        if      ($elt->isa(odf_column))         { return $elt; }
        elsif   ($elt->isa(odf_column_group))   { return $elt->first_column; }
        else                                    { return undef; }
        }

sub     last_column
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'column')         or return undef;
        if      ($elt->isa(odf_column))         { return $elt; }
        elsif   ($elt->isa(odf_column_group))   { return $elt->last_column; }
        else                                    { return undef; }
        }

sub     get_column_count
        {
        my $self        = shift;
        my $count       = 0;
        my $col         = $self->first_column;
        my $max_w       = $self->att('#lpod:w');
        while ($col)
                {
                $count += $col->get_repeated;
                $col = $col->next($self);
                }
        return (defined $max_w and $max_w < $count) ? $max_w : $count;        
        }

sub     get_position
        {
        my $self        = shift;
        my $start = $self->first_column;
        return $start ? $start->get_position : undef;
        }

sub     _get_column
        {
        my $self        = shift;
        my $position    = shift;
        my $col = $self->first_column   or return undef;
        for (my $i = 0 ; $i < $position ; $i++)
                {
                $col = $col->next($self) or return undef;
                }
        return $col;
        }

#-----------------------------------------------------------------------------

sub     get_column
        {
        my $self        = shift;
        my $position    = odf_matrix->alpha_to_num(shift) || 0;
        my $width       = $self->get_column_count;
        my $max_w       = $self->get_attribute('#lpod:w');
        my $filter      = odf_matrix->COLUMN_FILTER;
        if ($position < 0)
                {
                $position += $width;
                }
        if (($position >= $width) || ($position < 0))
                {
                alert "Column position $position out of range";
                return undef;
                }

        my $col = $self->first_column or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $col->next($self);
                $p = ODF::lpOD::Matrix::split_rep($col, $p, $max_w);
                $p++; $col = $next_elt;
                } until $p >= $position;
        $col = $self->_get_column($position); 
        ODF::lpOD::Matrix::split_rep($col, $p, $max_w);
        return $col;
        }

sub     get_column_list
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = odf_matrix->translate_range($arg, shift);
                }
        $start //= 0; $end //= -1;
        my @list = ();
        my $elt = $self->get_column($start);
        my $last_elt = $self->get_column($end);
        while ($elt && ! $elt->after($last_elt))
                {
                push @list, $elt;
                $elt = $elt->next($self);
                }
        return @list;
        }

sub     add_column
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                propagate       => TRUE,
                @_
                );
        my $ref_elt     = $opt{before} || $opt{after};
        my $expand      = $opt{expand};
        my $propagate   = $opt{propagate};
        my $position    = undef;
        my $col_filter  = odf_matrix->COLUMN_FILTER;
        my $row_filter  = odf_matrix->ROW_FILTER;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                $ref_elt = $self->get_column($ref_elt) unless ref $ref_elt;
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
        delete @opt{qw(number before after expand propagate)};
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child($col_filter);
                $elt = $proto ? $proto->copy() : odf_create_column(%opt);
                }
        else
                {
                $elt = $ref_elt->copy;
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if ($number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->set_repeated(undef);
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        else
                {
                $elt->set_repeated(undef);
                }
        if (is_true($propagate))
                {
                my $context = $self;
                my $hz_pos = $elt->get_position;
                unless ($self->isa(odf_table))
                        {
                        $context = $self->parent('table:table');
                        }
                foreach my $row ($context->descendants($row_filter))
                        {
                        my $ref_cell = $row->get_cell($hz_pos);
                        $row->add_cell(
                                number          => $number,
                                expand          => $expand,
                                $position       => $ref_cell
                                );
                        }
                }
        return $elt;
        }

sub     set_column_group
        {
        my $self        = shift;
        my ($start, $end) = odf_matrix->translate_range(shift, shift);
        my $e1 = $self->get_column($start);
        my $e2 = $self->get_column($end);
        return $self->set_group('column', $e1, $e2, @_);
        }

sub     get_column_group
        {
        my $self        = shift;
        return $self->get_group('column', @_);
        }

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_column_list;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility(undef) for $self->get_column_list;
        }

#=============================================================================
package ODF::lpOD::RowGroup;
use base 'ODF::lpOD::Matrix';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-28T15:16:06';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create { return odf_element->new('table:table-row-group', @_); }

#-----------------------------------------------------------------------------

sub     first_row
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'row')   or return undef;
        if      ($elt->isa(odf_row))            { return $elt; }
        elsif   ($elt->isa(odf_row_group))      { return $elt->first_row; }
        else                                    { return undef; }
        }

sub     last_row
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'row')    or return undef;
        if      ($elt->isa(odf_row))            { return $elt; }
        elsif   ($elt->isa(odf_row_group))      { return $elt->last_row; }
        else                                    { return undef; }
        }

sub     get_height
        {
        my $self        = shift;
        my $height      = 0;
        my $row         = $self->first_row;
        my $max_h       = $self->att('#lpod:h');
        while ($row)
                {
                $height += $row->get_repeated;
                $row = $row->next($self);
                }
        return (defined $max_h and $max_h < $height) ? $max_h : $height;
        }

sub     get_position
        {
        my $self        = shift;
        my $start = $self->first_row;
        return $start ? $start->get_position : undef;
        }

#-----------------------------------------------------------------------------

sub     _get_row
        {
        my $self        = shift;
        my $position    = shift;
        my $row = $self->first_row   or return undef;
        for (my $i = 0 ; $i < $position ; $i++)
                {
                $row = $row->next($self) or return undef;
                }
        return $row;
        }

sub     get_row
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $height      = $self->get_height;
        my $max_h       = $self->att('#lpod:h');
        unless (is_numeric($position))
                {
                $position = odf_matrix->alpha_to_num($position);
                }
        if ($position < 0)
                {
                $position += $height;
                }
        if (($position >= $height) || ($position < 0))
                {
                alert "Row position $position out of range";
                return undef;
                }

        my $row = $self->first_row or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $row->next($self);          
                $p = ODF::lpOD::Matrix::split_rep($row, $p, $max_h);
                $p++; $row = $next_elt;
                } until $p >= $position;
        $row = $self->_get_row($position);    
        ODF::lpOD::Matrix::split_rep($row, $p, $max_h);
        return $row;
        }

sub     get_row_list
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = odf_matrix->translate_range($arg, shift);
                }
        $start //= 0; $end //= -1;
        my @list = ();
        my $elt = $self->get_row($start);
        my $last_elt = $self->get_row($end);
        while ($elt && ! $elt->after($last_elt))
                {
                push @list, $elt;
                $elt = $elt->next($self);
                }
        return @list;
        }

sub     add_row
        {
        my $self        = shift;
        my %opt         =
                (
                number          => 1,
                expand          => TRUE,
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
                $ref_elt = $self->get_row($ref_elt) unless ref $ref_elt;
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
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child(odf_matrix->ROW_FILTER);
                $elt = $proto ? $proto->copy() : odf_create_row(%opt);
                }
        else
                {
                $elt = $ref_elt->copy;
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if ($number && $number > 1)
                {
                if (is_true($expand))
                        {
                        $elt->set_repeated(undef);
                        $elt->repeat($number);
                        }
                else
                        {
                        $elt->set_repeated($number);
                        }
                }
        else
                {
                $elt->set_repeated(undef);
                }
        return $elt;
        }

sub     set_row_group
        {
        my $self        = shift;
        my ($start, $end) = odf_matrix->translate_range(shift, shift);
        my $e1 = $self->get_row($start);
        my $e2 = $self->get_row($end);
        return $self->set_group('row', $e1, $e2, @_);
        }

sub     get_row_group
        {
        my $self        = shift;
        return $self->get_group('row', @_);
        }

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_row_list;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility('visible') for $self->get_row_list;
        }

#=============================================================================
#       Tables
#-----------------------------------------------------------------------------
package ODF::lpOD::Table;
use base ('ODF::lpOD::ColumnGroup', 'ODF::lpOD::RowGroup');
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-06-28T12:39:16';
use ODF::lpOD::Common;
#=============================================================================
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
        
        $t->add_column(number => $width, propagate => FALSE);
        my $r = $t->add_row(); $r->set_repeated($height);
        $r->add_cell()->set_repeated($width); 
        
        return $t;
        }

#=============================================================================
package ODF::lpOD::TableElement;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-28T11:51:27';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_repeated
        {
        my $self        = shift;
        my $class = $self->get_class;
        my $attr;
        if (($class eq odf_cell) or ($class eq odf_column))
                {
                $attr = 'table:number-columns-repeated';
                }
        elsif ($class eq odf_row)
                {
                $attr = 'table:number-rows-repeated';
                }
        else
                {
                alert "Unknown object"; return undef;
                } 
        my $result = $self->get_attribute($attr) // 1;                  #/
        if ($result < 1)
                {
                alert "Strange repeat property $result";
                }
        return $result;
        }

sub     set_repeated
        {
        my $self        = shift;
        my $class = $self->get_class;
        my $attr;
        if (($class eq odf_cell) or ($class eq odf_column))
                {
                $attr = 'table:number-columns-repeated';
                }
        elsif ($class eq odf_row)
                {
                $attr = 'table:number-rows-repeated';
                }
        else
                {
                alert "Unknown object"; return undef;
                } 
        my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute($attr, $rep);
        }

sub     repeat
        {
        my $self        = shift;
        my $reps        = shift || $self->get_repeated;
        $self->set_repeated(undef);
        return $self->SUPER::repeat($reps);
        }

#-----------------------------------------------------------------------------

sub     get_position
        {
        my $self        = shift;
        my $parent      = $self->parent(odf_matrix->TABLE_FILTER);
        unless ($parent)
                {
                alert "Missing or wrong attachment";
                return FALSE;
                }
        my $position = 0;
        my $elt = $self->previous($parent);
        while ($elt)
                {
                $position += $elt->get_repeated // 1;                   #/
                $elt = $elt->previous($parent);
                }
        return wantarray ? ($parent->get_name, $position) : $position;
        }

#=============================================================================
#       Table columns
#-----------------------------------------------------------------------------
package ODF::lpOD::Column;
use base 'ODF::lpOD::TableElement';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-06-27T02:38:16';
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

sub     next
        {
        my $self        = shift;
        my $context     = shift || $self->parent('table:table');
        my $filter      = shift || qr'column';
        my $elt = $self->next_elt($context, $filter);
        while ($elt)
                {              
                if      ($elt->isa(odf_column))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa(odf_column_group))
                        {
                        my $n = $elt->first_column;
                        return $n if $n;
                        }
                $elt = $self->next_elt($context, $filter);
                }
        return undef;
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->parent('table:table');
        my $filter      = shift || odf_matrix->COLUMN_FILTER;
        my $elt = $self->prev_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa(odf_column))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa(odf_column_group))
                        {
                        my $n = $elt->last_column();
                        return $n if $n;
                        }
                $elt = $elt->prev_elt($context, $filter);
                }
        return undef;
        }

#=============================================================================
#       Table rows
#-----------------------------------------------------------------------------
package ODF::lpOD::Row;
use base 'ODF::lpOD::TableElement';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-06-28T11:51:27';
use ODF::lpOD::Common;
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

sub     clean
        {
        my $self        = shift;
        my $cell        = $self->last_child(odf_matrix->CELL_FILTER)
                or return undef;
        $cell->set_repeated(undef);
        }

#-----------------------------------------------------------------------------

sub     get_cell
        {
        my $self        = shift;
        my $position    = odf_matrix->alpha_to_num(shift) || 0;
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

        my $cell = $self->first_child(odf_matrix->CELL_FILTER)
                or return undef;
        my $p = 0;
        my $next_elt;
        do      {
                $next_elt = $cell->next;
                $p = ODF::lpOD::Matrix::split_rep($cell, $p, $max_w);
                $p++; $cell = $next_elt;
                } until $p >= $position;
        $cell = $self->child($position, odf_matrix->CELL_FILTER);
        ODF::lpOD::Matrix::split_rep($cell, $p, $max_w);
        return $cell;
        }

sub     get_cell_list
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        unless ($arg)
                {
                $start = 0; $end = -1;
                }
        else
                {
                ($start, $end) = odf_matrix->translate_range($arg, shift);
                }
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

sub     get_cells
        {
        my $self        = shift;
        return $self->get_cell_list(@_);
        }

sub     get_width
        {
        my $self        = shift;
        my $width       = 0;
        my $cell        = $self->first_child(odf_matrix->CELL_FILTER);
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
        my $elt;
        unless ($ref_elt)
                {
                my $proto = $self->last_child(odf_matrix->CELL_FILTER);
                $elt = $proto ? $proto->copy() : odf_create_cell(%opt);
                }
        else
                {
                $elt = $ref_elt->copy;
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        if ($number && $number > 1)
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

sub     next
        {
        my $self        = shift;
        my $context     = shift || $self->parent('table:table');
        my $filter      = shift || qr'row';
        my $elt = $self->next_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa(odf_row))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa(odf_row_group))
                        {
                        my $n = $elt->first_row;
                        return $n if $n;
                        }
                $elt = $self->next_elt($context, $filter);
                }
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->parent('table:table');
        my $filter      = shift || odf_matrix->ROW_FILTER;
        my $elt = $self->prev_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa(odf_row))
                        {
                        return $elt;
                        }
                elsif   ($elt->isa(odf_row_group))
                        {
                        my $n = $elt->last_row();
                        return $n if $n;
                        }
                $elt = $elt->prev_elt($context, $filter);
                }
        return undef;
        }

#=============================================================================
package ODF::lpOD::Field;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-25T21:47:06';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my $tag = shift;
        unless ($tag)
                {
                alert "Missing element tag";
                return FALSE;
                }
        my %opt = process_options
                (
                type    => 'string',
                value   => undef,
                text    => undef,
                @_
                );

        my $field = odf_element->new($tag);
        unless ($field)
                {
                alert "Field $tag creation failure";
                return FALSE;
                }
        bless $field, __PACKAGE__;

        if (defined $opt{text})
                {
                $field->set_text($opt{text});
                delete $opt{text};
                }
        unless ($field->set_type($opt{type}))
                {
                alert "Type setting failure";
                $field->delete; return FALSE;
                }
        if (defined $opt{value})
                {
                unless ($field->set_value($opt{value}))
                        {
                        alert "Value setting failure";
                        $field->delete; return FALSE;
                        }
                }

        return $field;
        }

#-----------------------------------------------------------------------------

sub     get_type
        {
        my $self        = shift;
        return $self->att('office:value-type')
                        // 'string';
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift;
        unless ($type && $type ~~ @ODF::lpOD::Common::DATA_TYPES)
                {
                alert "Missing or wrong data type";
                return FALSE;
                }
        $self->del_attribute('office:currency') unless $type eq 'currency';
        return $self->set_att('office:value-type', $type);
        }

sub     get_currency
        {
        my $self        = shift;
        return $self->att('office:currency');
        }

sub     set_currency
        {
        my $self        = shift;
        my $currency    = shift;
        $self->set_type('currency') if $currency;
        return $self->set_att('office:currency', $currency);
        }

sub     get_value
        {
        my $self        = shift;
        my $type        = $self->get_type();
        given ($type)
                {
                when ('string')
                        {
                        return $self->get_text;
                        }
                when (['date', 'time'])
                        {
                        my $attr = 'office:' . $type . '-value';
                        return $self->att($attr);
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        return $self->att('office:value');
                        }
                when ('boolean')
                        {
                        my $v = $self->att('office:boolean-value');
                        return defined $v ? is_true($v) : undef;
                        }
                }
        }

sub     set_value
        {
        my $self        = shift;
        my $value       = shift         or return undef;
        my $type        = $self->get_type();

        given ($type)
                {
                when ('string')
                        {
                        $self->set_text($value);
                        }
                when ('date')
                        {
                        if (is_numeric($value))
                                {
                                $value = iso_date($value);
                                }
                        $self->set_att('office:date-value', $value);
                        }
                when ('time')
                        {
                        $self->set_att('office:time-value', $value);
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        $self->set_att('office:value', $value);
                        }
                when ('boolean')
                        {
                        $self->set_att(
                                'office:boolean-value',
                                odf_boolean($value)
                                );
                        }
                }
        return $self->get_value;
        }

#-----------------------------------------------------------------------------

sub     get_text
        {
        my $self        = shift;
        return $self->SUPER::get_text(recursive => TRUE);
        }

#=============================================================================
#       Table cells
#-----------------------------------------------------------------------------
package ODF::lpOD::Cell;
use base ('ODF::lpOD::TableElement', 'ODF::lpOD::Field');
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-25T21:46:36';
use ODF::lpOD::Common;

BEGIN   {
        *get_text               = *ODF::lpOD::Field::get_text;
        *get_type               = *ODF::lpOD::Field::get_type;
        }

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
        my $row = $self->parent(odf_matrix->ROW_FILTER);
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }
        return $self->next_elt($row, odf_matrix->CELL_FILTER);
        }

sub     previous
        {
        my $self        = shift;
        my $row = $self->parent(odf_matrix->ROW_FILTER);
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }        
        return $self->prev_elt($row, odf_matrix->CELL_FILTER);
        }

sub     get_position
        {
        my $self        = shift;
        my $row = $self->parent(odf_matrix->ROW_FILTER);
        unless ($row)
                {
                alert "Missing or wrong attachment";
                return FALSE;
                }
        my $position = 0;
        my $elt = $self->previous;
        while ($elt)
                {
                $position += $elt->get_repeated // 1;                   #/
                $elt = $elt->previous;
                }
        if (wantarray)
                {
                return  (
                        $row->get_position(),
                        $position
                        );
                }
        return $position;        
        }

#-----------------------------------------------------------------------------

sub     set_text
        {
        my $self        = shift;
        my $text        = shift;
        my %opt         =
                (
                style           => undef,
                @_
                );
        $self->cut_children;
        $self->append_element
                (odf_create_paragraph(text => $text, style => $opt{style}));
        }

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

