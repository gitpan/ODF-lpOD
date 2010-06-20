#-----------------------------------------------------------------------------
# lpOD Perl Installation test
#-----------------------------------------------------------------------------

use 5.010_000;

use Test;
BEGIN	{ plan tests => 6 }

use ODF::lpOD;
lpod->debug(TRUE);

my $test_file   = $ARGV[0] || 'lpod_test.odt';
my $generator   = "lpOD installation test";
my $test_date   = ODF::lpOD->PACKAGE_DATE;

#-----------------------------------------------------------------------------

my $doc = odf_new_document_from_type('text');
ok($doc);                                       # doc instance test

my $meta = $doc->get_meta;
ok($meta);                                      # meta instance test

my $content = $doc->get_content;
ok($content);                                   # content instance test

$meta->set_generator($generator);
my $current_date = time;
$meta->set_creation_date($current_date);
$meta->set_modification_date($current_date);

my $t = odf_create_table("TestTable", height => 5, width => 5);
ok($t);                                         # table creation test

my $cell = $t->get_cell("E5");
ok($cell);                                      # cell access test

$cell->set_type('date');
$cell->set_value($test_date);
$cell->set_text($test_date);
$content->get_body->append_element($t);

$content->store(pretty => TRUE);
$meta->store(pretty => TRUE);
$doc->save(target => $test_file);

if (-r -f -e $test_file)
        { ok(TRUE) } else { ok(FALSE) }         # file creation test

#-----------------------------------------------------------------------------

exit 0;

