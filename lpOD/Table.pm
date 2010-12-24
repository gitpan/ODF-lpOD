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
#=============================================================================
use     5.010_000;
use     strict;
#=============================================================================
#	Tables and table components (columns, rows, cells, row/col groups)
#=============================================================================
package ODF::lpOD::Matrix;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:41:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

use constant    ROW_FILTER      => 'table:table-row';
use constant    COLUMN_FILTER   => 'table:table-column';
use constant    CELL_FILTER     => qr'table:(covered-|)table-cell';
use constant    TABLE_FILTER    => 'table:table';

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
        my $tag = ($type ~~ ['column', 'row']) ?
                        'table:table-' . $type . '-group'       :
                        'table:table-' . $type;
        my $group = odf_element->new($tag);
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
		if (wantarray)
			{
			my $row_width = $row->get_width;
			$width = $row_width if $row_width > $width;
			}
		last if ((defined $max_h) and ($height >= $max_h));
                $row = $row->next($self);
                }
        $height = $max_h if defined $max_h and $max_h < $height;
        return wantarray ? ($height, $width) : $height;
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
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:41:56';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create { return odf_element->new('table:table-column-group', @_); }

#-----------------------------------------------------------------------------

sub     all_columns
        {
        my $self        = shift;
        return $self->descendants(odf_matrix->COLUMN_FILTER);
        }

sub     first_column
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'(column$|column-group)')
                                        or return undef;
        if      ($elt->isa(odf_column))         { return $elt; }
        elsif   ($elt->isa(odf_column_group))   { return $elt->first_column; }
        else                                    { return undef; }
        }

sub     last_column
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'(column$|column-group)')
                                        or return undef;
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
        my $position    = alpha_to_num(shift) || 0;
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

	my $p = $position;
	my $r = $col->get_repeated;
	while ($p >= $r)
		{
		$p -= $r;
		$col = $col->next($self);
		$r = $col->get_repeated;
		}
	if ($self->rw and $col->repeat($r, $p))
		{
		$col = $self->get_column($position);
		}

        return $col;
        }

sub     get_columns
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_size() - 1;
        my @list = ();

	if ($self->ro)
		{
		my $col = $self->get_column($start);
		my $n = $end - $start;
		while ($n >= 0)
			{
			my $r = $col->get_repeated;
			while ($r > 0 && $n >= 0)
				{
				push @list, $col;
				$r--; $n--;
				}
			$col = $col->next($self);
			}
		}
	else
		{
		for (my $i = $start ; $i <= $end ; $i++)
			{
			push @list, $self->get_column($i);
			}
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
        my ($start, $end) = translate_range(shift, shift);
        my $e1 = $self->get_column($start);
        my $e2 = $self->get_column($end);
        return $self->set_group('column', $e1, $e2, @_);
        }

sub     get_column_group
        {
        my $self        = shift;
        return $self->get_group('column', @_);
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = translate_coordinates(@_);
        my $col = $self->get_column($c)    or return undef;
        return $col->get_cell($r);
        }

sub	get_cells
	{
	my $self	= shift;
	my ($r1, $c1, $r2, $c2) = translate_range(@_);
	my @cells = (); my $i = 0;

	foreach my $col ($self->get_columns($c1, $c2))
		{
		@{$cells[$i]} = $col->get_cells($c1, $c2); $i++;
		}
	return @cells;
	}

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_columns;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility(undef) for $self->get_columns;
        }

sub	set_default_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_default_cell_style($style) for $self->all_columns;
	}

#=============================================================================
package ODF::lpOD::RowGroup;
use base 'ODF::lpOD::Matrix';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:42:14';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create { return odf_element->new('table:table-row-group', @_); }

#-----------------------------------------------------------------------------

sub     all_rows
        {
        my $self        = shift;
        return $self->descendants(odf_matrix->ROW_FILTER);
        }

sub     all_cells
        {
        my $self        = shift;
        return $self->descendants(odf_matrix->CELL_FILTER);
        }

sub     clean
        {
        my $self        = shift;
        $_->clean() for $self->descendants(odf_matrix->ROW_FILTER);
        }

sub     first_row
        {
        my $self        = shift;
        my $elt = $self->first_child(qr'(row$|row-group)') or return undef;
        if      ($elt->isa(odf_row))            { return $elt; }
        elsif   ($elt->isa(odf_row_group))      { return $elt->first_row; }
        else                                    { return undef; }
        }

sub     last_row
        {
        my $self        = shift;
        my $elt = $self->last_child(qr'(row$|row-group)') or return undef;
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
                $position = alpha_to_num($position);
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
	my $p = $position;
	my $r = $row->get_repeated;
	while ($p >= $r)
		{
		$p -= $r;
		$row = $row->next($self);
		$r = $row->get_repeated;
		}
	if ($self->rw and $row->repeat($r, $p))
		{
		$row = $self->get_row($position);
		}

        return $row;
        }

sub     get_rows
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        if ($arg)
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_size() - 1;
        my @list = ();

	if ($self->ro)
		{
		my $row = $self->get_row($start);
		my $n = $end - $start;
		while ($n >= 0)
			{
			my $r = $row->get_repeated;
			while ($r > 0 && $n >= 0)
				{
				push @list, $row;
				$r--; $n--;
				}
			$row = $row->next($self);
			}
		}
	else
		{
		for (my $i = $start ; $i <= $end ; $i++)
			{
			push @list, $self->get_row($i);
			}
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
        my ($start, $end) = translate_range(shift, shift);
        my $e1 = $self->get_row($start);
        my $e2 = $self->get_row($end);
        return $self->set_group('row', $e1, $e2, @_);
        }

sub     get_row_group
        {
        my $self        = shift;
        return $self->get_group('row', @_);
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = translate_coordinates(@_);
        my $row = $self->get_row($r)    or return undef;
        return $row->get_cell($c);
        }

sub	get_cells
	{
	my $self	= shift;
	my ($r1, $c1, $r2, $c2) = translate_range(@_);
	my @cells = (); my $i = 0;
	foreach my $row ($self->get_rows($r1, $r2))
		{
		@{$cells[$i]} = $row->get_cells($c1, $c2); $i++;
		}
	return @cells;
	}	

sub     collapse
        {
        my $self        = shift;
        $_->set_visibility('collapse') for $self->get_rows;
        }

sub     uncollapse
        {
        my $self        = shift;
        $_->set_visibility('visible') for $self->get_rows;
        }

sub	set_default_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_default_cell_style($style) for $self->all_rows;
	}

#=============================================================================
#       Tables
#-----------------------------------------------------------------------------
package ODF::lpOD::Table;
use base ('ODF::lpOD::RowGroup', 'ODF::lpOD::ColumnGroup');
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:42:32';
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

        my $width       = $opt{width};
        my $height      = $opt{length} // $opt{height};
	unless (defined $width && defined $height)
		{
		($height, $width) = input_2d_value($opt{size}, "");
		}
	$width  // 0; $height // 0;
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
        
        $t->add_column(
                number          => $width,
                expand          => $opt{expand},
                propagate => FALSE
                );
        my $r = $t->add_row;
        unless (is_true($opt{expand}))
                {
                $r->add_cell()->set_repeated($width);
                $r->set_repeated($height);
                }
        else
                {
                $r->add_cell(number => $width, expand => TRUE);
                $r->repeat($height);
                }

	$t->set_default_cell_style($opt{cell_style}) if ($opt{cell_style});

        return $t;
        }

#--- special optimization ----------------------------------------------------

sub	read_optimize
	{
	my $self	= shift;
	return $self->ro(shift);
	}

sub     set_working_area
        {
        my $self        = shift;
        my ($h, $w)     = @_;
        $self->set_attribute('#lpod:h' => $h);
        $self->set_attribute('#lpod:w' => $w);
        }

#-----------------------------------------------------------------------------

sub     set_column_header
        {
        my $self        = shift;
        if ($self->get_column_header)
                {
                alert "Column header already defined for this table";
                return FALSE;
                }
        my $number      = shift || 1;
        my $start       = $self->get_row(0);
        my $end         = $self->get_row($number > 1 ? $number-1 : 0);
        return $self->set_group('header-rows', $start, $end);
        }

sub     get_column_header
        {
        my $self        = shift;
        return $self->first_child('table:table-header-rows');
        }

sub     set_row_header
        {
        my $self        = shift;
        if ($self->get_row_header)
                {
                alert "Row header already defined for this table";
                return FALSE;
                }
        my $number      = shift || 1;
        my $start       = $self->get_column(0);
        my $end         = $self->get_column($number > 1 ? $number-1 : 0);
        return $self->set_group('header-columns', $start, $end);
        }

sub     get_row_header
        {
        my $self        = shift;
        return $self->first_child('table:table-header-columns');
        }

sub	set_default_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_default_cell_style($style)
		for ($self->all_rows, $self->all_columns);
	}

#=============================================================================
package ODF::lpOD::TableElement;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:42:49';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub	table
	{
	my $self	= shift;
	return $self->get_ancestor('table:table');
	}

sub	tro
	{
	my $self	= shift;
	my $table = $self->table or return FALSE;
	return is_true($table->ro);
	}

sub	trw
	{
	my $self	= shift;
	my $table = $self->table or return TRUE;
	return is_false($table->ro);
	}

sub     repeat
        {
        my $self        = shift;
        my $r		= shift // $self->get_repeated;
	return undef unless $r > 1;
	my $p		= shift;
	unless (defined $p)
		{
		$self->set_repeated(undef);
		return $self->SUPER::repeat($r);
		}
	else
		{
		if (($p < 0) or ($p >= $r))
			{
			return undef;
			}
		elsif ($p == 0)
			{
			$self->set_repeated(undef);
			my $c1 = $self->clone; $c1->paste_after($self);
			$c1->set_repeated($r - 1);
			}
		else
			{
			$self->set_repeated($p);
			my $c1 = $self->clone; $c1->paste_after($self);
			$c1->set_repeated(undef); $p++;
			if ($p < $r)
				{
				my $c2 = $c1->clone; $c2->paste_after($c1);
				$c2->set_repeated($r - $p);
				}
			}
			
		return TRUE;
		}
        }

#-----------------------------------------------------------------------------

sub     get_repeated
        {
        my $self        = shift;
        my $attr;
        if ($self->isa(odf_cell) or $self->isa(odf_column))
                {
                $attr = 'table:number-columns-repeated';
                }
        elsif ($self->isa(odf_row))
                {
                $attr = 'table:number-rows-repeated';
                }
        else
                {
                alert "Unknown object"; return undef;
                } 
        my $result = $self->get_attribute($attr) // 1;
        if ($result < 1)
                {
                alert "Strange repeat property $result";
                }
        return $result;
        }

sub     set_repeated
        {
        my $self        = shift;
	my $attr;
        if ($self->isa(odf_cell) or $self->isa(odf_column))
                {
                $attr = 'table:number-columns-repeated';
                }
        elsif ($self->isa(odf_row))
                {
                $attr = 'table:number-rows-repeated';
                }
        else
                {
                alert "Unknown object"; return undef;
                }
	my $rep         = shift;
        $rep = undef unless $rep && $rep > 1;
        return $self->set_attribute($attr => $rep);
        }

sub	set_default_cell_style
	{
	my $self	= shift;
	$self->set_attribute('table:default-cell-style-name' => shift);
	}

#-----------------------------------------------------------------------------

sub     get_position
        {
        my $self        = shift;
        my $parent      = $self->table;
        unless ($parent)
                {
                alert "Missing or wrong table attachment";
                return undef;
                }
        my $position = 0;
        my $elt = $self->previous($parent);
        while ($elt)
                {
                $position += ($elt->get_repeated() // 1);
                $elt = $elt->previous($parent);
                }
        return wantarray ? ($parent->get_name, $position) : $position;
        }

#=============================================================================
#       Table columns
#-----------------------------------------------------------------------------
package ODF::lpOD::Column;
use base 'ODF::lpOD::TableElement';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:43:05';
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
	$col->set_default_cell_style($opt{cell_style})
			if defined $opt{cell_style};
	delete @opt{qw(style cell_style)};
        foreach my $a (keys %opt)
                {
                $col->set_attribute($a, $opt{$a});    
                }
        return $col;
        }

#-----------------------------------------------------------------------------

sub	get_length
	{
	my $self	= shift;
	my $parent = $self->parent;
	unless ($parent && $parent->isa(odf_row_group))
		{
		alert "No defined length for a non attached column";
		return undef;
		}
	return scalar $parent->get_size;
	}

sub     next
        {
        my $self        = shift;
        my $context     = shift || $self->table;
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
                $elt = $elt->next_elt($context, $filter);
                }
        return undef;
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->table;
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

sub	set_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_style($style) for $self->get_cells;
	}

#-----------------------------------------------------------------------------

sub	get_cell
	{
	my $self	= shift;
	my $table	= $self->table;
	unless ($table)
		{
		alert "Not in table"; return undef;		
		}
	my $col_num = $self->get_position;
	my $row_num = shift // 0;
	return $table->get_cell($row_num, $col_num);
	}

sub	get_cells
	{
	my $self	= shift;
        my $arg         = shift;
        my ($start, $end);
        unless ($arg)
                {
                $start = 0; $end = $self->get_length() - 1;
                }
        else
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_length() - 1;
        my @cells = ();
	for (my $i = $start ; $i <= $end ; $i++)
		{
		push @cells, $self->get_cell($i);
		}
	return @cells;
	}

#=============================================================================
#       Table rows
#-----------------------------------------------------------------------------
package ODF::lpOD::Row;
use base 'ODF::lpOD::TableElement';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:43:23';
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
	$row->set_default_cell_style($opt{cell_style})
			if defined $opt{cell_style};
	delete @opt{qw(style cell_style)};

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

sub	all_cells
	{
	my $self	= shift;
	return $self->ODF::lpOD::Matrix::all_cells;
	}

sub	set_cell_style
	{
	my $self	= shift;
	my $style	= shift;
	$_->set_style($style) for $self->all_cells;
	}

#-----------------------------------------------------------------------------

sub     get_cell
        {
        my $self        = shift;
        my $position    = alpha_to_num(shift) || 0;
        my $width       = $self->get_width;
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

	my $p = $position;
	my $r = $cell->get_repeated;
	while ($p >= $r)
		{
		$p -= $r;
		$cell = $cell->next($self);
		$r = $cell->get_repeated;
		}
	if ($self->trw and $cell->repeat($r, $p))
		{
		$cell = $self->get_cell($position);
		}

	return $cell;
        }

sub     get_cells
        {
        my $self        = shift;
        my $arg         = shift;
        my ($start, $end);
        unless ($arg)
                {
                $start = 0; $end = $self->get_width() - 1;
                }
        else
                {
                ($start, $end) = translate_range($arg, shift);
                }
        $start //= 0; $end //= $self->get_width() - 1;
        my @list = ();
	
	if ($self->tro)
		{
		my $cell = $self->get_cell($start);
		my $n = $end - $start;
		while ($n >= 0)
			{
			my $r = $cell->get_repeated;
			while ($r > 0 && $n >= 0)
				{
				push @list, $cell;
				$r--; $n--;
				}
			$cell = $cell->next($self, odf_matrix->CELL_FILTER);
			}
		}
	else
		{
		for (my $i = $start ; $i <= $end ; $i++)
			{
			push @list, $self->get_cell($i);
			}
		}

        return @list;
        }

sub     get_width
        {
        my $self        = shift;
        my $width       = 0;
        my $cell        = $self->first_child(odf_matrix->CELL_FILTER);
	my $tbl		= $self->table;
        my $max_w       = $tbl ? $tbl->att('#lpod:w') : undef;
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
        my $context     = shift || $self->table;
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
                $elt = $elt->next_elt($context, $filter);
                }
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift || $self->table;
        my $filter      = shift || odf_matrix->ROW_FILTER;
        my $elt = $self->prev_elt($context, $filter);
        while ($elt)
                {
                if      ($elt->isa(odf_row))
                        {
                        if ($elt->parent->is('table:table-header-rows'))
                                {
                                return undef unless $self
                                        ->parent
                                        ->is('table:table-header-rows');
                                }
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
#       Table cells
#-----------------------------------------------------------------------------
package ODF::lpOD::Cell;
use base ('ODF::lpOD::Field', 'ODF::lpOD::TableElement');
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:43:41';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN	{
	*repeat			= *ODF::lpOD::TableElement::repeat;
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

sub	row
	{
	my $self	= shift;
	return $self->parent('table:table-row');
	}

sub	column
	{
	my $self	= shift;
	my $t = $self->table;
	unless ($t)
		{
		alert "Not in table"; return undef;
		}
	my $pos = $self->get_position	or return undef;
	return $t->get_column($pos);
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
        my $row = $self->row;
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }
        return $self->next_elt($row, odf_matrix->CELL_FILTER);
        }

sub     previous
        {
        my $self        = shift;
        my $row = $self->row;
        unless ($row)
                {
                alert "Wrong context"; return FALSE;
                }        
        return $self->prev_elt($row, odf_matrix->CELL_FILTER);
        }

sub     get_position
        {
        my $self        = shift;
        my $row = $self->row;
        unless ($row)
                {
                alert "Missing or wrong attachment";
                return FALSE;
                }
        my $position = 0;
        my $elt = $self->previous;
        while ($elt)
                {
                $position += $elt->get_repeated // 1;
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

sub     get_text
        {
        my $self        = shift;
        return $self->ODF::lpOD::Element::get_text(recursive => TRUE);
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

sub     remove_span
        {
        my $self        = shift;
        my $hspan = $self->get_attribute('number columns spanned') || 1;
        my $vspan = $self->get_attribute('number rows spanned') || 1;
        $self->del_attribute('number columns spanned');
        $self->del_attribute('number rows spanned');
        my $row = $self->parent(odf_matrix->ROW_FILTER);
        my $table = $self->parent(odf_matrix->TABLE_FILTER);
        my $vpos = $row->get_position;
        my $hpos = $self->get_position;
	my $vend = $vpos + $vspan - 1;
	my $hend = $hpos + $hspan - 1;
        ROW: for (my $i = $vpos ; $i <= $vend ; $i++)
                {
                my $cr = $table->get_row($i) or last ROW;
                CELL: for (my $j = $hpos ; $j <= $hend ; $j++)
                        {
                        my $covered = $cr->get_cell($j) or last CELL;
                        next CELL if $covered == $self;
                        $covered->set_tag('table:table-cell');
                        $covered->set_atts($self->atts);
                        }
                }
        return ($hspan, $vspan);
        }

sub     set_span
        {
        my $self        = shift;
        if ($self->is_covered)
                {
                alert "Span expansion is not allowed for covered cells";
                return FALSE;
                }
        my %opt         = @_;
        my $hspan = $opt{columns}       // 1;
        my $vspan = $opt{rows}          // 1;
        my $old_hspan = $self->get_attribute('number columns spanned') || 1;
        my $old_vspan = $self->get_attribute('number rows spanned') || 1;
        unless  (($hspan > 1) || ($vspan > 1))
                {
                return $self->remove_span;
                } 
        unless  (($hspan != $old_hspan) || ($vspan != $old_vspan))
                {
                return ($old_vspan, $old_hspan);
                }
        $self->remove_span;
	$hspan	= $old_hspan unless $hspan;
	$vspan	= $old_vspan unless $vspan;
        my $row = $self->parent(odf_matrix->ROW_FILTER);
        my $table = $self->parent(odf_matrix->TABLE_FILTER);
        my $vpos = $row->get_position;
        my $hpos = $self->get_position;
	my $vend = $vpos + $vspan - 1;
	my $hend = $hpos + $hspan - 1;
	$self->set_attribute('number columns spanned', $hspan);
	$self->set_attribute('number rows spanned', $vspan);
        ROW: for (my $i = $vpos ; $i <= $vend ; $i++)
                {
                my $cr = $table->get_row($i) or last ROW;
                CELL: for (my $j = $hpos ; $j <= $hend ; $j++)
                        {
                        my $covered = $cr->get_cell($j) or last CELL;
                        next CELL if $covered == $self;
                        $_->move(last_child => $self)
                                for $covered->get_content;
                        $covered->remove_span;
                        $covered->set_tag('table:covered-table-cell');
                        }
                }
        return ($hspan, $vspan);
        }

sub     get_span
        {
        my $self        = shift;
        return  (
                $self->get_attribute('number rows spanned') // 1,
                $self->get_attribute('number columns spanned') // 1
                );
        }

#=============================================================================
1;
