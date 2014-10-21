#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2011 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean-marie.gouarne@online.fr>
#
#=============================================================================
use 5.010_000;
use strict;
#=============================================================================
#       The main module for the lpOD Project
#=============================================================================
package ODF::lpOD;
our $VERSION                    =       '1.121';
use constant PACKAGE_DATE       =>      "2012-06-08T22:51:35";
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use ODF::lpOD::Document;
use ODF::lpOD::TextElement;
use ODF::lpOD::Field;
use ODF::lpOD::StructuredContainer;
use ODF::lpOD::Table;
use ODF::lpOD::Style;
use ODF::lpOD::Attributes;
#-----------------------------------------------------------------------------
use base 'Exporter';
our @EXPORT     = ();
push @EXPORT,   @ODF::lpOD::Common::EXPORT;
#=============================================================================

BEGIN
        {
        my $lpod_pm_path = $INC{'ODF/lpOD.pm'} // "";
        $lpod_pm_path =~ s/\.pm$//;
        $ODF::lpOD::Common::INSTALLATION_PATH = $lpod_pm_path;
        load_color_map;
        }

#=============================================================================
1;
