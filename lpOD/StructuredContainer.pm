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
#       Structured containers : Sections, lists, draw pages
#-----------------------------------------------------------------------------
package ODF::lpOD::StructuredContainer;
use base 'ODF::lpOD::Element';
our $VERSION    = '0.000';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
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
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-02T21:44:39';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::DrawPage;
use base 'ODF::lpOD::Element';
our $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-02T21:44:39';
use ODF::lpOD::Common;
#=============================================================================
1;
