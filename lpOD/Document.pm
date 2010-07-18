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
our     $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-07-18T17:57:37';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *container      = *get_container;
        }

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

        my $container = odf_new_container_from_template($resource);
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

#--- XML part detection ------------------------------------------------------

sub     is_xmlpart
        {
        my $name        = shift;
        return ODF::lpOD::XMLPart::class_of($name) ? TRUE : FALSE;
        }

#--- document part accessors -------------------------------------------------

sub     get_container
        {
        my $self        = shift;
        my %opt         = @_;
        my $container   = $self->{container};
        unless ($container || is_false($opt{warning}))
                {
                alert "No available container";
                }
        return $container;
        }

sub     get_xmlpart
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                or return FALSE; 

        my $part_name   = shift         or return FALSE;

        unless ($self->{$part_name})
                {
                $self->{$part_name} = odf_get_xmlpart($container, $part_name);
                $self->{$part_name}->{document} = $self;
                }
        return $self->{$part_name};
        }

sub     get_body
        {
        my $self        = shift;
        return $self->get_xmlpart(CONTENT)->get_body;
        }

sub     get_part
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        my $part_name   = shift;
        if (is_xmlpart($part_name))
                {
                return $self->get_xmlpart($part_name);
                }
        else
                {
                return $container->get_part($part_name);
                }
        }

sub     get_parts
        {
        my $self        = shift;
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        return $container->get_parts;
        }

sub     set_part
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;                
                }
        return $self->{container}->set_part(@_);
        }

sub     del_part
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;                
                }
        return $self->{container}->del_part(@_);
        }

sub     add_file
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No available container";
                return FALSE;                
                }
        return $self->{container}->add_file(@_);
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
        my $container   = $self->get_container(warning => TRUE)
                                or return FALSE;
        return $container->save(@_);
        }

#=============================================================================
package ODF::lpOD::Container;
our	$VERSION	= '0.102';
use constant PACKAGE_DATE => '2010-07-17T17:35:59';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use Archive::Zip        1.30    qw ( :DEFAULT :CONSTANTS :ERROR_CODES );
#=============================================================================

BEGIN   {
        *get_parts              = *parts;
        }

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
        return $self->set_part(
                MIMETYPE, shift, compress => FALSE, string => TRUE
                );
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

        my $compress = $opt{compress} // $COMPRESSION{$part_name} // FALSE;
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
                string          => FALSE,
                compress        => FALSE,
                @_
                );

        $self->{stored}{$part_name}{data}       = $data;
        $self->{stored}{$part_name}{string}     = $opt{string};
        $self->{stored}{$part_name}{compress}   = $opt{compress};
        
        $self->del_part($part_name);
        
        return $part_name;
        }

#-----------------------------------------------------------------------------

sub     add_file
        {
        my $self        = shift;
        my $path        = shift         or return undef;
        my $destination = shift;
        my %opt         =
                (
                string          => FALSE,
                @_
                );
        unless ($destination)
                {
                my $mimetype = file_type($path);
                my $filename = file_parse($path);
                if ($mimetype && $mimetype =~ /^image/)
                        {
                        $destination = 'Pictures/' . $filename;
                        $opt{compress} = FALSE;
                        }
                else
                        {
                        $destination = $filename;
                        $opt{compress} = TRUE;
                        }
                }
        return $self->set_part($destination, $path, %opt);
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
        my ($result, $status) =  $self->{'zip'}->contents($part_name);
        return $status == AZ_OK ? $result : undef;
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

#=============================================================================
package ODF::lpOD::XMLPart;
our     $VERSION    = '0.102';
use constant PACKAGE_DATE => '2010-07-14T13:40:05';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use ODF::lpOD::Element;
#=============================================================================

BEGIN   {
        *get_container  = *container;
        *get_document   = *document;
        *root           = *get_root;
        }

sub     class_of
        {
        my $part        = shift;
        given($part)
                {
                when (CONTENT)          { return odf_content   }
                when (STYLES)           { return odf_styles    }
                when (META)             { return odf_meta      }
                when (SETTINGS)         { return odf_settings  }
                when (MANIFEST)         { return odf_manifest  }
                default                 { return undef         }
                }
        }

our %CLASS      =
        (
        content         => odf_content,
        styles          => odf_styles,
        meta            => odf_meta,
        manifest        => odf_manifest,
        settings        => odf_settings
        );

#=== exported part ===========================================================

sub     get
        {
        my $container   = shift;
        unless (ref $container && $container->isa(odf_container))
                {
                alert "Missing or not valid container";
                return FALSE;
                }
        my $part_name   = shift;
        unless (class_of($part_name))
                {
                alert "Missing or unknown document part";
                return FALSE;
                }
        return odf_xmlpart->new
                (
                part            => $part_name,
                container       => $container,
                @_
                );
        }

#=== private part ============================================================

our $COUNT              = 0;

#--- constructor and associated utilities ------------------------------------

sub     new
        {
        my $class       = shift;
        my $self        =
                {
                container       => undef,
                part            => undef,
                load            => TRUE,
                elt_class       => odf_element,
                twig            => undef,
                context         => undef,
                @_
                };

        my $part_class = class_of($self->{part});
        unless ($class)
                {
                alert "Unknown ODF XML part"; return FALSE;
                }

        $self->{twig} //= XML::Twig->new        # twig init /
                                (
                                elt_class       => $self->{elt_class},
                                pretty_print    => $self->{pretty_print},
                                id              => $ODF::lpOD::Common::LPOD_ID
                                );
        $self->{twig}->set_output_encoding('UTF-8');

        bless $self, $part_class;
        if ($self->{load})
                {
                my $status = $self->load();
                unless (is_true($status))
                        {
                        alert("Part load failed");
                        return FALSE;
                        }
                }

        $COUNT++;
        return $self;
        }

sub     load
        {
        my $self        = shift;
        my $xml         = shift || $self->{container}->get_part($self->{part});

        unless (defined $xml)
                {
                alert("No content");
                return FALSE;
                }

        my $r = UNIVERSAL::isa($xml, 'IO::File') ?
                $self->{twig}->safe_parsefile($xml)     :
                $self->{twig}->safe_parse($xml);
        unless ($r)
                {
                alert "No valid XML content";
                return FALSE;
                }
        
        $self->{context} = $self->{twig}->root;
        $self->{context}->lpod_part($self);
        return TRUE;
        }

#--- destructor --------------------------------------------------------------

sub     DESTROY
        {
        my $self        = shift;
        $self->{context} &&
                $self->{context}->del_att($ODF::lpOD::Common::LPOD_PART);
        delete $self->{context};
        $self->{twig} && $self->{twig}->dispose;
        delete $self->{twig};
        delete $self->{container};
        delete $self->{part};
        $self = {};
        $COUNT--;
        }

#--- basic individual node selection -----------------------------------------

sub     find_node
        {
        my $self        = shift;
        my $tag         = shift;
        my $context     = shift || $self->{context};
        
        return $context->first_descendant($tag);
        }

#=== public part =============================================================
#--- general document management ---------------------------------------------

sub     get_root
        {
        my $self        = shift;
        return $self->{twig}->root;
        }

sub     get_body
        {
        my $self        = shift;
        my $root = $self->get_root;
        my $context = $root->get_xpath('//office:body', 0);
        return $context ?
                $context->first_child
                    (qr'office:(text|spreadsheet|presentation|drawing)')
                        :
                $root->first_child
                    (qr'office:(body|meta|master-styles|settings)');
        }

sub     container
        {
        my $self        = shift;
        return $self->{container};
        }

sub     document
        {
        my $self        = shift;
        return $self->{document};
        }

sub     serialize
        {
        my $self        = shift;
        my %opt         =
                (
                pretty          => FALSE,
                empty_tags      => EMPTY_TAGS,
                output          => undef,
                @_
                );
        $opt{pretty_print} = PRETTY_PRINT if is_true($opt{pretty});
        my $output = $opt{output};
        delete @opt{qw(pretty output)};
        return (defined $output) ?
                $self->{twig}->print($output, %opt)   :
                $self->{twig}->sprint(%opt);
        }

sub     store
        {
        my $self        = shift;
        unless ($self->{container})
                {
                alert "No associated container";
                return FALSE;
                }
        my %opt         = @_;
        my %storage     = ();
        if ($opt{storage})
                {
                %storage = %{$opt{storage}};
                delete $opt{storage};
                }
        else
                {
                %storage = (compress => TRUE, string => TRUE);
                }
        return
                $self->{container}->set_part
                        (
                        $self->{part},
                        $self->serialize(%opt),
                        %storage
                        );
        }

#--- general element management ----------------------------------------------

sub     get_element_list
        {
        my ($self, $xpath) = @_;
        return $self->{context}->get_xpath($xpath);
        }

sub     get_element
        {
        my $self        = shift;
        my $xpath       = shift;
        my $offset      = shift || 0;
        return $self->{context}->get_xpath($xpath, $offset);
        }

sub     append_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->append_element(@_);
        }

sub     insert_element
        {
        my $self        = shift;
        my $context     = $self->get_root;
        return $context->insert_element(@_);
        }

sub     delete_element
        {
        my ($self, $element) = @_;
        return $element->delete;      
        }

#=============================================================================
package ODF::lpOD::Content;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Styles;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Meta;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '0.101';
use constant PACKAGE_DATE => '2010-07-06T19:18:47';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %META =
        (
        creation_date           => 'meta:creation-date',
        creator                 => 'dc:creator',
        description             => 'dc:description',
        editing_cycles          => 'meta:editing-cycles',
        editing_duration        => 'meta:editing-duration',
        generator               => 'meta:generator',
        initial_creator         => 'meta:initial-creator',
        language                => 'dc:language',
        modification_date       => 'dc:date',
        printed_by              => 'meta:printed-by',
        print_date              => 'meta:print-date',
        subject                 => 'dc:subject',
        title                   => 'dc:title'
        );

#-----------------------------------------------------------------------------

sub     get_body
        {
        my $self        = shift;
        unless ($self->{body})
                {
                $self->{body} = $self->SUPER::get_element('//office:meta');
                }
        return $self->{body};
        }

sub     get_element
        {
        my $self        = shift;
        return $self->get_body->get_element(@_);
        }

sub     get_element_list
        {
        my $self        = shift;
        return $self->get_body->get_element_list(@_);        
        }

sub     append_element
        {
        my $self        = shift;
        return $self->get_body->append_element(@_);
        }

#-----------------------------------------------------------------------------

sub     get_statistics
        {
        my $self        = shift;
        my $stat        = $self->get_element('meta:document-statistic');
        return $stat ? $stat->get_attributes() : undef;
        }

sub     set_statistics
        {
        my $self        = shift;
        my $stat =      $self->get_element('meta:document-statistic') ||
                        $self->append_element('meta:document-statistic');
        return $stat->set_attributes(@_);
        }

#-----------------------------------------------------------------------------

sub     get_keyword_list
        {
        my $self        = shift;
        my $expr        = shift;
        return $self->get_element_list
                        ('meta:keyword', content => $expr);
        }

sub     get_keywords
        {
        my $self        = shift;
        my @kwl         = ();
        for ($self->get_keyword_list(@_))
                {
                push @kwl, $_->get_text;
                }
        return wantarray ? @kwl : join (', ', @kwl);
        }

sub     set_keyword
        {
        my $self        = shift;
        my $kw          = shift // return undef;                #/
        for ($self->get_keyword_list)
                {
                return FALSE if $_->get_text() eq $kw;
                }
        my $e = $self->append_element('meta:keyword');
        $e->set_text($kw);
        return $e;
        }

sub     set_keywords
        {
        my $self        = shift;
        my $input       = join(',', @_);
        foreach my $kw (split(',', $input))
                {
                $kw =~ s/^ *//; $kw =~ s/ *$//;
                $self->set_keyword($kw);
                }
        return $self->get_keywords;
        }

sub     check_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;

        return scalar $self->get_keyword_list($expr);
        }

sub     remove_keyword
        {
        my $self        = shift;
        my $expr        = shift         or return undef;
        my $count       = 0;
        for ($self->get_keyword_list($expr))
                {
                $_->delete; $count++;
                }
        return $count;
        }

#-----------------------------------------------------------------------------

sub     get_user_field
        {
        my $self        = shift;
        my $name        = shift         or return undef;
        my $e = ref $name ?
                        $name
                                :
                        $self->get_element
                                (
                                'meta:user-defined',
                                attribute       => 'name',
                                value           => $name
                                );
        return undef unless $e;
        return wantarray ?
                (
                        $e->get_text(),
                        $e->get_attribute('value type') || 'string'
                )
                :
                $e->get_text;
        }

sub     set_user_field
        {
        my $self        = shift;
        my $name        = shift;
        my $value       = shift;                          #/
        my $type        = shift || 'string';
        unless (is_odf_datatype($type))
                {
                alert "Wrong data type $type";
                return FALSE;
                }
        unless ($name)
                {
                alert "Missing user field name";
                return FALSE;
                }
        $value = check_odf_value($value, $type);
        my $e = $self->get_element
                        (
                        'meta:user-defined',
                        attribute       => 'name',
                        value           => $name
                        )
                        //
                $self->append_element('meta:user-defined');
        $e->set_attribute('name' => $name);
        $e->set_attribute('value type' => $type);
        $e->set_text($value);
        return wantarray ?
                ($e->get_text(), $e->get_attribute('value type'))
                        :
                $e->get_text;
        }

sub     get_user_fields
        {
        my $self        = shift;
        my @result      = ();
        foreach my $e ($self->get_element_list('meta:user-defined'))
                {
                my $f;
                $f->{name}      = $e->get_attribute('name');
                $f->{type}      = $e->get_attribute('value type') // 'string';
                $f->{value}     = $e->get_text() // "";
                push @result, $f;
                }
        return @result;
        }

#-----------------------------------------------------------------------------

our     $AUTOLOAD;
sub     AUTOLOAD
        {
        my $self        = shift;
        $AUTOLOAD       =~ /.*:(.*)/;
        my $method      = $1;
        $method =~ /^([gs]et)_(.*)/;
        my $action      = $1;
        my $object      = $META{$2};

        unless ($action && $object)
                {
                alert "Unsupported method $method";
                return undef;
                }

        my $e = $self->get_element($object);
        given ($action)
                {
                when (undef)
                        {
                        alert "Unsupported action";
                        }
                when ('get')
                        {
                        return $e ? $e->get_text() : undef;
                        }
                when ('set')
                        {
                        unless ($e)
                                {
                                my $body = $self->get_body;
                                $e = $body->append_element($object);
                                }
                        my $v = shift;
                        if ($object =~ /date$/)
                                {
                                $v = check_odf_value($v, 'date');
                                }
                        return $e->set_text($v);
                        }
                }
        return undef; 
        }

#-----------------------------------------------------------------------------

sub     store
        {
        my $self        = shift;
        my %opt         =
                (
                storage     => { compress => FALSE, string => TRUE }
                );
        return $self->SUPER::store(%opt);
        }

#=============================================================================
package ODF::lpOD::Settings;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Manifest;
use base 'ODF::lpOD::XMLPart';
our $VERSION    = '0.100';
use constant PACKAGE_DATE => '2010-06-24T21:30:36';
use ODF::lpOD::Common;
#=============================================================================
1;


