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
#-----------------------------------------------------------------------------
#       Level 0 - Physical container management module - Container class
#-----------------------------------------------------------------------------
package ODF::lpOD::Container;
our	$VERSION	= 0.1;
use constant PACKAGE_DATE => '2010-06-17T12:53:54';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use Archive::Zip        1.30    qw ( :DEFAULT :CONSTANTS :ERROR_CODES );
#=== parameters ==============================================================

our %ODF_PARTS  =
        (
        content         => CONTENT,
        styles          => STYLES,
        meta            => META,
        manifest        => MANIFEST,
        settings        => SETTINGS,
        mimetype        => MIMETYPE
        );

our %PARTS_ODF  = reverse %ODF_PARTS;

sub     translate_part_name
        {
        my $name        = shift         or return undef;
        return $ODF_PARTS{$name} ? $ODF_PARTS{$name} : $name;
        }

our     %COMPRESSION    =               # compression rule for some parts
        (
        MIMETYPE        => FALSE,
        META            => FALSE,
        CONTENT         => TRUE,
        STYLES          => TRUE,
        MANIFEST        => TRUE,
        SETTINGS        => TRUE
        );

#=============================================================================

sub     get_from_uri
        {
        return odf_container->new
                (
                uri             => shift,
                read_only       => FALSE,
                create          => FALSE,
                @_
                );
        }

#-----------------------------------------------------------------------------

sub     create_from_template
        {
        return odf_container->new
                (
                uri             => shift,
                read_only       => TRUE,
                create          => FALSE,
                @_
                );
        }

#-----------------------------------------------------------------------------

sub     create
        {
        return odf_container->new
                (
                uri             => ODF::lpOD::Common::template(shift),
                read_only       => TRUE,
                create          => TRUE,
                @_
                )
        }

#=== undocumented part =======================================================
our     $COUNT  = 0;
#-----------------------------------------------------------------------------

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                uri             => undef,
                read_only       => undef,
                zip             => undef,
                deleted         => [],
                stored          => {},
                @_
                };

        my $source = $self->{uri};
        my $zip = defined $self->{zip} ?
                $self->{zip} : Archive::Zip->new;

        if (UNIVERSAL::isa($source, 'IO::File'))
                {
                if ($zip->readFromFileHandle($source) != AZ_OK)
                        {
                        alert("Handle read error");
                        return FALSE;
                        }
                }
        else
                {
	        unless	(-r -f -e $source)
		        {
		        alert("Missing source");
		        return FALSE;
			}
	        if ($zip->read($source) != AZ_OK)
		        {
		        alert("File read error");
		        return FALSE;
		        }
                }
                
        $self->{zip} = $zip;
        bless $self, $class;
        $COUNT++;
        return $self;
        }

#-----------------------------------------------------------------------------

sub     DESTROY
        {
        my $self        = shift;
        undef $self->{zip};
        $self = {};
        $COUNT--;
        return TRUE;
        }

#-----------------------------------------------------------------------------

sub     get_mimetype
        {
        my $self        = shift;
        return $self->get_part(MIMETYPE);
        }

sub     set_mimetype
        {
        my $self        = shift;
        return $self->set_part(MIMETYPE, shift, compress => FALSE);
        }

#-----------------------------------------------------------------------------

sub     parts
        {
        my $self        = shift;
        return $self->{zip}->memberNames;
        }

#-----------------------------------------------------------------------------

sub     contains
        {
        my $self        = shift;
        my $part_name   = shift         or return FALSE;
        return (grep $_ eq $part_name, $self->parts) ? TRUE : FALSE;
        }

#-----------------------------------------------------------------------------

sub     raw_set_part
        {
        my $self        = shift;
        my $part_name   = shift;

        my $data        = shift;
        my %opt         =
                (
                string                  => TRUE,
                compress                => undef,
                compression_method      => COMPRESSION_DEFLATED,
                compression_level       => COMPRESSION_LEVEL_BEST_COMPRESSION,
                @_
                );

        my $compress = $opt{compress} // $COMPRESSION{$part_name} // TRUE;
        my $p   = $opt{string} ?
                        $self->{zip}->addString($data, $part_name)    :
                        $self->{zip}->addFileOrDirectory($data, $part_name);
        if ($p)
                {
                if (is_true($compress))
                        {
		        $p->desiredCompressionMethod($opt{compression_method});
		        $p->desiredCompressionLevel($opt{compression_level});
                        }
                else
                        {
                        $p->desiredCompressionMethod(COMPRESSION_STORED);
                        }
                return TRUE;
                }
        else
                {
                alert("Data storage error");
                return FALSE;
                }
        }

#-----------------------------------------------------------------------------

sub     raw_del_part
        {
        my $self        = shift;
        my $part_name   = shift;
        return FALSE unless $self->contains($part_name);

        my $status      = $self->{zip}->removeMember($part_name);
        unless ($status)
                {
                alert("$part_name removal failed");
                return FALSE;
                }
        return TRUE;
        }

#=== documented methods ======================================================

sub     clone
        {
        my $self        = shift;
        return not_implemented($self, 'clone');      
        }

#-----------------------------------------------------------------------------

sub     set_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift)    or return FALSE;
        my $data        = shift // "";                                  #/
        my %opt         =
                (
                string          => TRUE,
                compress        => undef,
                @_
                );

        unless (defined $opt{'compress'})
                {
                $opt{compress} = 
                        (($part_name eq META) or ($part_name eq MIMETYPE)) ?
                                FALSE : TRUE;
                }

        $self->{stored}{$part_name}{data}       = $data;
        $self->{stored}{$part_name}{string}     = $opt{string};
        $self->{stored}{$part_name}{compress}   = $opt{compress};
        
        $self->del_part($part_name);
        
        return $part_name;
        }

#-----------------------------------------------------------------------------

sub     get_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift);
        unless ($part_name)
                {
                alert "Missing part name";
                return FALSE
                }
        unless ($self->contains($part_name))
                {
                alert("Unknown part $part_name");
                return FALSE;
                }
        return $self->{'zip'}->contents($part_name);
        }

#-----------------------------------------------------------------------------

sub     del_part
        {
        my $self        = shift;
        my $part_name   = translate_part_name(shift)    or return FALSE;
        push @{$self->{deleted}}, $part_name;
        return TRUE;
        }

#-----------------------------------------------------------------------------

sub     save
        {
        my $self        = shift;
        my %opt         =
                        (
                        target          => undef,
                        packaging       => 'zip',
                        @_
                        );
        if (is_true($self->{read_only}))
                {
                unless  (
                                (defined $opt{target})          &&
                                $opt{target} ne $self->{uri}
                        )
                        {
                        alert("Read-only container");
                        return undef;
                        }
                }
        my $target      = $opt{target};
        my $packaging   = $opt{packaging};
        
        $self->raw_del_part($_) for @{$self->{deleted}};
      
        foreach my $part_name (keys %{$self->{stored}})
                {
                my $data        = $self->{stored}{$part_name}{data};
                my $compress    = $self->{stored}{$part_name}{compress};
                my $string      = $self->{stored}{$part_name}{string};
                $self->raw_del_part($part_name);
                $self->raw_set_part
                        (
                        $part_name, $data,
                        compress        => $compress,
                        string          => $string
                        );
                }

        my $status = undef;
        unless (defined $target)
                {
                $status = $self->{zip}->overwrite();
                }
        elsif (UNIVERSAL::isa($target, 'IO::File'))
                {
                $status = $self->{zip}->writeToFileHandle($target);
                }
        else
                {
                $status = $self->{zip}->writeToFileNamed($target);
                }

        unless ($status == AZ_OK)
                {
                alert("Zip I/O error");
                return FALSE;
                }

        $self->{deleted} = [];
        $self->{stored} = {};
        return TRUE;
        }

#-----------------------------------------------------------------------------
1;


