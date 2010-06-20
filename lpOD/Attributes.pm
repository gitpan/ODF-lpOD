# Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#
# Author: Jean-Marie Gouarné <jean-marie.gouarne(at)arsaperta.com>
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
package ODF::lpOD::Attributes;
use constant PACKAGE_DATE => '2010-06-12T00:06:11';
#==============================================================================
# Generated from OpenDocument-schema-v1.1.rng
#------------------------------------------------------------------------------
%ODF::lpOD::Heading::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	cond_style_name                 =>
		{
		attribute => "text:cond-style-name",
		type      => "styleNameRef"
		},
	outline_level                   =>
		{
		attribute => "text:outline-level",
		type      => "positiveInteger"
		},
	restart_numbering               =>
		{
		attribute => "text:restart-numbering",
		type      => "boolean"
		},
	start_value                     =>
		{
		attribute => "text:start-value",
		type      => "nonNegativeInteger"
		},
	is_list_header                  =>
		{
		attribute => "text:is-list-header",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::List::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	continue_numbering              =>
		{
		attribute => "text:continue-numbering",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Row::ATTRIBUTE =
	(
	number_rows_repeated            =>
		{
		attribute => "table:number-rows-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	default_cell_style_name         =>
		{
		attribute => "table:default-cell-style-name",
		type      => "styleNameRef"
		},
	visibility                      =>
		{
		attribute => "table:visibility",
		type      => "table-visibility-value"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Paragraph::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	cond_style_name                 =>
		{
		attribute => "text:cond-style-name",
		type      => "styleNameRef"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::BibliographyMark::ATTRIBUTE =
	(
	bibliography_type               =>
		{
		attribute => "text:bibliography-type",
		type      => "text-bibliography-types"
		},
	identifier                      =>
		{
		attribute => "text:identifier",
		type      => "string"
		},
	address                         =>
		{
		attribute => "text:address",
		type      => "string"
		},
	annote                          =>
		{
		attribute => "text:annote",
		type      => "string"
		},
	author                          =>
		{
		attribute => "text:author",
		type      => "string"
		},
	booktitle                       =>
		{
		attribute => "text:booktitle",
		type      => "string"
		},
	chapter                         =>
		{
		attribute => "text:chapter",
		type      => "string"
		},
	edition                         =>
		{
		attribute => "text:edition",
		type      => "string"
		},
	editor                          =>
		{
		attribute => "text:editor",
		type      => "string"
		},
	howpublished                    =>
		{
		attribute => "text:howpublished",
		type      => "string"
		},
	institution                     =>
		{
		attribute => "text:institution",
		type      => "string"
		},
	journal                         =>
		{
		attribute => "text:journal",
		type      => "string"
		},
	month                           =>
		{
		attribute => "text:month",
		type      => "string"
		},
	note                            =>
		{
		attribute => "text:note",
		type      => "string"
		},
	number                          =>
		{
		attribute => "text:number",
		type      => "string"
		},
	organizations                   =>
		{
		attribute => "text:organizations",
		type      => "string"
		},
	pages                           =>
		{
		attribute => "text:pages",
		type      => "string"
		},
	publisher                       =>
		{
		attribute => "text:publisher",
		type      => "string"
		},
	school                          =>
		{
		attribute => "text:school",
		type      => "string"
		},
	series                          =>
		{
		attribute => "text:series",
		type      => "string"
		},
	title                           =>
		{
		attribute => "text:title",
		type      => "string"
		},
	report_type                     =>
		{
		attribute => "text:report-type",
		type      => "string"
		},
	volume                          =>
		{
		attribute => "text:volume",
		type      => "string"
		},
	year                            =>
		{
		attribute => "text:year",
		type      => "string"
		},
	url                             =>
		{
		attribute => "text:url",
		type      => "string"
		},
	custom1                         =>
		{
		attribute => "text:custom1",
		type      => "string"
		},
	custom2                         =>
		{
		attribute => "text:custom2",
		type      => "string"
		},
	custom3                         =>
		{
		attribute => "text:custom3",
		type      => "string"
		},
	custom4                         =>
		{
		attribute => "text:custom4",
		type      => "string"
		},
	custom5                         =>
		{
		attribute => "text:custom5",
		type      => "string"
		},
	isbn                            =>
		{
		attribute => "text:isbn",
		type      => "string"
		},
	issn                            =>
		{
		attribute => "text:issn",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Section::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	name                            =>
		{
		attribute => "text:name",
		type      => "string"
		},
	protected                       =>
		{
		attribute => "text:protected",
		type      => "boolean"
		},
	protection_key                  =>
		{
		attribute => "text:protection-key",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::TextElement::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Table::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "table:name",
		type      => "string"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	protected                       =>
		{
		attribute => "table:protected",
		type      => "boolean"
		},
	protection_key                  =>
		{
		attribute => "table:protection-key",
		type      => "Inconnu"
		},
	print                           =>
		{
		attribute => "table:print",
		type      => "boolean"
		},
	print_ranges                    =>
		{
		attribute => "table:print-ranges",
		type      => "cellRangeAddressList"
		},
	is_sub_table                    =>
		{
		attribute => "table:is-sub-table",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Column::ATTRIBUTE =
	(
	number_columns_repeated         =>
		{
		attribute => "table:number-columns-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	visibility                      =>
		{
		attribute => "table:visibility",
		type      => "table-visibility-value"
		},
	default_cell_style_name         =>
		{
		attribute => "table:default-cell-style-name",
		type      => "styleNameRef"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::DrawPage::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "draw:name",
		type      => "string"
		},
	style_name                      =>
		{
		attribute => "draw:style-name",
		type      => "styleNameRef"
		},
	master_page_name                =>
		{
		attribute => "draw:master-page-name",
		type      => "styleNameRef"
		},
	presentation_page_layout_name   =>
		{
		attribute => "presentation:presentation-page-layout-name",
		type      => "styleNameRef"
		},
	id                              =>
		{
		attribute => "draw:id",
		type      => "ID"
		},
	nav_order                       =>
		{
		attribute => "draw:nav-order",
		type      => "IDREFS"
		},
	use_header_name                 =>
		{
		attribute => "presentation:use-header-name",
		type      => "string"
		},
	use_footer_name                 =>
		{
		attribute => "presentation:use-footer-name",
		type      => "string"
		},
	use_date_time_name              =>
		{
		attribute => "presentation:use-date-time-name",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Cell::ATTRIBUTE =
	(
	number_columns_spanned          =>
		{
		attribute => "table:number-columns-spanned",
		type      => "positiveInteger"
		},
	number_rows_spanned             =>
		{
		attribute => "table:number-rows-spanned",
		type      => "positiveInteger"
		},
	number_matrix_columns_spanned   =>
		{
		attribute => "table:number-matrix-columns-spanned",
		type      => "positiveInteger"
		},
	number_matrix_rows_spanned      =>
		{
		attribute => "table:number-matrix-rows-spanned",
		type      => "positiveInteger"
		},
	number_columns_repeated         =>
		{
		attribute => "table:number-columns-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	content_validation_name         =>
		{
		attribute => "table:content-validation-name",
		type      => "string"
		},
	formula                         =>
		{
		attribute => "table:formula",
		type      => "string"
		},
	protect                         =>
		{
		attribute => "table:protect",
		type      => "boolean"
		},
	);
#==============================================================================
1;
