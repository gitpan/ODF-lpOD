# Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#
# Authors: Jean-Marie Gouarné <jean-marie.gouarne@arsaperta.com>
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
#=============================================================================
#       The ODF Document class definition
#-----------------------------------------------------------------------------
package ODF::lpOD::Document;
our     $VERSION    = 0.1;
use constant PACKAGE_DATE => '2010-06-17T12:55:43';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use ODF::lpOD::Container;
use ODF::lpOD::XMLPart;

BEGIN   {
        *container      = *get_container;
        }


#=============================================================================
#--- specific constructors ---------------------------------------------------

sub     get_from_uri
        {
        my $resource    = shift;
        unless ($resource)
                {
                alert "Missing source"; return FALSE;
                }
        my $container = odf_get_container($resource);
        return $container ?
                odf_document->new(container => $container)       :
                FALSE;
        }

sub     create_from_template
        {
        my $resource    = shift;
        unless ($resource)
                {
                alert "Missing template"; return FALSE;
                }

        my $container = odf_get_container_from_template($resource);
        return $container ?
                odf_document->new(container => $container)       :
                FALSE;        
        }

sub     create
        {
        my $type        = shift;
        unless ($type)
                {
                alert "Missing document type"; return FALSE;
                }
        my $container = odf_new_container_from_type($type);
        return $container ?
                odf_document->new(container => $container)       :
                FALSE;        
        }

#--- generic constructor & destructor ----------------------------------------

our $COUNT      = 0;

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                @_
                };
        bless $self, $class;
        $COUNT++;
        return $self;
        }

sub     DESTROY
        {
        $COUNT--;
        }

#--- document part accessors -------------------------------------------------

sub     get_container
        {
        my $self        = shift;
        return $self->{container};
        }

sub     get_xmlpart
        {
        my $self        = shift;

        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;
                }

        my $part_name   = shift         or return FALSE;

        unless ($self->{$part_name})
                {
                $self->{$part_name} = odf_get_xmlpart
                                        ($self->{container}, $part_name);
                }
        $self->{$part_name}->{document} = $self;
        return $self->{$part_name};
        }

sub     get_content
        {
        my $self        = shift;
        return $self->get_xmlpart('content');
        }

sub     get_styles
        {
        my $self        = shift;
        return $self->get_xmlpart('styles');
        }

sub     get_meta
        {
        my $self        = shift;
        return $self->get_xmlpart('meta');
        }

sub     get_manifest
        {
        my $self        = shift;
        return $self->get_xmlpart('manifest');
        }

sub     get_settings
        {
        my $self        = shift;
        return $self->get_xmlpart('settings');
        }

sub     get_part
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;                
                }
        my $part_name   = shift;
        unless ($self->{$part_name})
                {
                $self->{$part_name} = $self->{container}->get_part($part_name);
                }
        }

sub     get_mimetype
        {
        my $self        = shift;
        unless ($self->{mimetype})
                {
                $self->{mimetype} = $self->{container}->get_mimetype;
                }
        return $self->{mimetype};
        }

sub     set_mimetype
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;                
                }
        return $self->{container}->set_mimetype(shift);
        }

sub     get_type
        {
        my $self        = shift;
        my $mt = $self->get_mimetype    or return undef;
        $mt =~ s/.*opendocument\.//;
        return $mt;
        }

sub     save
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No associated container";
                return FALSE;
                }
        return $self->{container}->save(@_);
        }

#=============================================================================

#=============================================================================
1;


