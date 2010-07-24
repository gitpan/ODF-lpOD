#-----------------------------------------------------------------------------
# lpOD Perl Installation test
#-----------------------------------------------------------------------------

use 5.010_000;
use strict;

use Test;
BEGIN	{ plan tests => 6 }

use ODF::lpOD;
lpod->debug(TRUE);

my $test_file   = $ARGV[0] || 'lpod_test.odt';
my $generator   = scalar lpod->info;
my $test_date   = ODF::lpOD->PACKAGE_DATE;

#-----------------------------------------------------------------------------

my $doc = odf_new_document('text');
ok($doc);                                       # doc instance test

my $meta = $doc->get_part(META);
ok($meta);                                      # meta instance test

my $content = $doc->get_part(CONTENT);
ok($content);                                   # content instance test

$meta->set_generator($generator);

my $t = odf_create_table("TestTable", length => 5, width => 5);
ok($t);                                         # table creation test

my $cell = $t->get_cell("E5");
ok($cell);                                      # cell access test

$cell->set_type('date');
$cell->set_value($test_date);
$cell->set_text($test_date);
$content->get_body->append_element($t);

$doc->save(target => $test_file, pretty => TRUE);

if (-r -f -e $test_file)
        { ok(TRUE) } else { ok(FALSE) }         # file creation test

#-----------------------------------------------------------------------------

exit 0;

