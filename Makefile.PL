#------------------------------------------------------
# lpOD Perl - Packaging & installation - 2010-06-21
#------------------------------------------------------
use 5.10.0;
use ExtUtils::MakeMaker;
#------------------------------------------------------
WriteMakefile
	(
    	'NAME'		=> 'ODF::lpOD',
	'VERSION'	=> '0.111',
    	'AUTHOR'	=> 'Jean-Marie Gouarne <jean-marie.gouarne@arsaperta.com>',
	'LICENSE'	=> 'GPL',
    	'PREREQ_PM'	=>
    		{
		'XML::Twig'		=> '3.32',
		'Archive::Zip'		=> '1.30',
		'File::Temp'		=> '0.12',
		'File::Find'		=> '1.01',
		'Time::Local'		=> '1.07',
		'IO::File'		=> '1.14'
		},
	'EXE_FILES'	=>
		[
		]
	);
#------------------------------------------------------
