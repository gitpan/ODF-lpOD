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
package ODF::lpOD::Field;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-23T08:52:04';
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
        my $type        = $self->get_type;
        given ($type)
                {
                when ('string')
                        {
                        return $self->set_text($value);
                        }
                when ('date')
                        {
                        if (is_numeric($value))
                                {
                                $value = iso_date($value);
                                }
                        return $self->set_att('office:date-value', $value);
                        }
                when ('time')
                        {
                        return $self->set_att('office:time-value', $value);
                        }
                when (['float', 'currency', 'percentage'])
                        {
                        return $self->set_att('office:value', $value);
                        }
                when ('boolean')
                        {
                        return $self->set_att
                                (
                                'office:boolean-value',
                                odf_boolean($value)
                                );
                        }
                }        
        }

#-----------------------------------------------------------------------------

sub     get_text
        {
        my $self        = shift;
        return $self->SUPER::get_text(recursive => TRUE);
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

#-----------------------------------------------------------------------------
1;





