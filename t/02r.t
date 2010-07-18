#-----------------------------------------------------------------------------
# lpOD Perl Installation test
#-----------------------------------------------------------------------------

use 5.010_000;
use strict;

use Test;
BEGIN	{ plan tests => 9 }

use ODF::lpOD;
lpod->debug(TRUE);

my $test_file   = $ARGV[0] || 'lpod_test.odt';
my $generator   = "lpOD installation test";
my $test_date   = ODF::lpOD->PACKAGE_DATE;

#-----------------------------------------------------------------------------

my $doc = odf_get_document($test_file);
ok($doc);                                       # document instance check

my $content = $doc->get_part(CONTENT);
ok($content);                                   # content instance test

my $meta = $doc->get_part(META);
ok($meta);                                      # meta instance check

ok($meta->get_generator() eq $generator);       # generator value check

my $t = $content->get_body->get_table_by_name("TestTable");
ok($t);                                         # table instance check

my ($h, $w) = $t->get_size;
ok(($h == 5) && ($w == 5));                     # table size check

my $cell = $t->get_cell("E5");
ok($cell);                                      # cell retrieval check

ok($cell->get_type() eq 'date');                # cell type check

ok($cell->get_value() eq $test_date);           # cell content check;

#-----------------------------------------------------------------------------

exit 0;

