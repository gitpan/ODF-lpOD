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
use constant PACKAGE_DATE => '2010-06-19T19:23:38';
use ODF::lpOD::Common;
#=============================================================================

our $ROW_FILTER         = 'table:table-row';
our $COLUMN_FILTER      = 'table:table-column';

#-----------------------------------------------------------------------------

sub	translate_coordinates   # taken from OpenOffice::OODoc (Genicorp)
	{
	my $arg	= shift; return ($arg, @_) unless defined $arg;
	my $coord = uc $arg;
	return ($arg, @_) unless $coord =~ /[A-Z]/;

	$coord	=~ s/\s*//g;
	$coord	=~ /(^[A-Z]*)(\d*)/;
	my $c	= $1;
	my $r	= $2;
	return ($arg, @_) unless ($c && $r);

	my $rownum	= $r - 1;
	my @csplit	= split '', $c;
	my $colnum	= 0;
	foreach my $p (@csplit)
		{
		$colnum *= 26;
		$colnum	+= ((ord($p) - ord('A')) + 1);
		}
	$colnum--;

	return ($rownum, $colnum, @_);
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

#-----------------------------------------------------------------------------

sub     get_row
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $height      = $self->get_height;

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
        do      {
                my $next_elt = $row->next_sibling($ROW_FILTER);
                $p += $row->repeat(); $p++;
                $row = $next_elt;
                } until $p >= $position;
        return $self->child($position, $ROW_FILTER);
        }

sub     get_column
        {
        my $self        = shift;
        my $position    = shift || 0;
        my $width       = $self->get_column_count;
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
        do      {
                my $next_elt = $col->next_sibling($COLUMN_FILTER);
                $p += $col->repeat(); $p++;
                $col = $next_elt;
                } until $p >= $position;
        return $self->child($position, $COLUMN_FILTER);
        }

sub     get_cell
        {
        my $self        = shift;
        my ($r, $c) = ODF::lpOD::Table::translate_coordinates(@_);
        my $row = $self->get_row($r)    or return undef;
        return $row->get_cell($c);
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
        while ($row)
                {
                $height += $row->get_repeated;
                $row = $row->next_sibling($ROW_FILTER);
                }
        return $height;
        }

sub     get_column_count
        {
        my $self        = shift;
        my $count       = 0;
        my $col         = $self->first_child($COLUMN_FILTER);
        while ($col)
                {
                $count += $col->get_repeated;
                $col = $col->next_sibling($COLUMN_FILTER);
                }
        return $count;        
        }

sub     get_size
        {
        my $self        = shift;
        my $height      = 0;
        my $width       = 0;
        my $row         = $self->first_child($ROW_FILTER);
        while ($row)
                {
                $height += $row->get_repeated;
                my $row_width = $row->get_width;
                $width = $row_width if $row_width > $width;
                $row = $row->next_sibling($ROW_FILTER);
                }
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
use constant PACKAGE_DATE => '2010-06-10T12:38:06';
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

sub     get_repeated
        {
        my $self        = shift;
        return $self->get_attribute('table:number-columns-repeated') // 1;  #/
        }

sub     set_repeated
        {
        my $self        = shift;
        return $self->set_attribute('table:number-columns-repeated', shift);
        }

#=============================================================================
#       Table rows
#-----------------------------------------------------------------------------
package ODF::lpOD::Row;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-14T21:37:23';
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

sub     get_cell
        {
        my $self        = shift;
        my $position    = shift || 0;
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

        my $cell = $self->first_child($CELL_FILTER)
                or return undef;
        my $p = 0;
        do      {
                my $next_elt = $cell->next_sibling($CELL_FILTER);
                $p += $cell->repeat(); $p++;
                $cell = $next_elt;
                } until $p >= $position;
        return $self->child($position, $CELL_FILTER);
        }

sub     get_width
        {
        my $self        = shift;
        my $width       = 0;
        my $cell        = $self->first_child($CELL_FILTER);
        while ($cell)
                {
                $width += $cell->get_repeated;
                $cell = $cell->next_sibling($CELL_FILTER);
                }
        return $width;
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
        return $self->set_attribute('table:number-rows-repeated', shift);
        }

#=============================================================================
#       Table cells
#-----------------------------------------------------------------------------
package ODF::lpOD::Cell;
use base 'ODF::lpOD::Field';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-19T19:59:45';
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

sub     set_repeated
        {
        my $self        = shift;
        return $self->set_attribute('table:number-columns-repeated', shift);
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

