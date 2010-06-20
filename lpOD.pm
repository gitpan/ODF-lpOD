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
#       The main module for the lpOD Project
#-----------------------------------------------------------------------------
package ODF::lpOD;
our $VERSION    = 0.102;
use constant PACKAGE_DATE => '2010-06-12T00:08:57';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use ODF::lpOD::Document;

use base 'Exporter';
our @EXPORT     = ();
push @EXPORT,   @ODF::lpOD::Common::EXPORT;
#=============================================================================

BEGIN
        {
        my $lpod_pm_path = $INC{'ODF/lpOD.pm'};
        $lpod_pm_path =~ s/\.pm$//;
        $ODF::lpOD::Common::INSTALLATION_PATH = $lpod_pm_path;
        }

#=============================================================================
1;


