#-----------------------------------------------------------------------------
# lpOD Perl - Packaging & installation - 2010-12-29T21:57:14
#-----------------------------------------------------------------------------
use 5.010_000;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;
#-----------------------------------------------------------------------------

sub	default_version
	{
	'0.000'
	}

sub	default_author
	{
	'Jean-Marie Gouarne <jean-marie.gouarne@arsaperta.com>'
	}

sub	default_date
	{
	my @lt = localtime();
	return sprintf(
		"%04d-%02d-%02dT%02d:%02d:%02d",
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0]
		);
	}

GetOptions
	(
	'version=s'	=> \(my $version	= default_version),
	'date=s'	=> \(my $dist_date	= default_date),
	'author=s'	=> \(my $author		= default_author),
	'build'		=> \(my $build		= undef),
	);

#-----------------------------------------------------------------------------

if ($build)
	{
	require File::Copy;

	my $ok = "N";
	do	{
		$version	= prompt("Version number ?", $version);
		$dist_date	= prompt("Distribution date ?", $dist_date);
		$author		= prompt("Distribution author ?", $author);
		$ok		= prompt("OK ? (Y/N)", "Y");
		}
		until (uc($ok) eq "Y");

	File::Copy::copy("lpOD.pm", "lpOD.bak");
	open    LPOD, 	"<", "lpOD.pm";
	open	TMP,	">", "lpod.tmp";
	my @lpod = ();
	while (my $line = <LPOD>)
		{
		if	($line =~ /VERSION/) {
			$line =~ s/".*"/"$version"/;
			}
		elsif	($line =~ /PACKAGE_DATE/) {
			$line =~ s/".*"/"$dist_date"/;
			}

		print TMP $line;
		}
	close   LPOD;
	close	TMP;
	unlink("lpOD.pm"); rename("lpod.tmp", "lpOD.pm"); 
	}

#-----------------------------------------------------------------------------

WriteMakefile
	(
    	'NAME'		=> 'ODF::lpOD',
	'VERSION'	=> $version,
    	'AUTHOR'	=> $author,
	'LICENSE'	=> 'GPL',
    	'PREREQ_PM'	=>
    		{
		'XML::Twig'		=> '3.34',
		'Archive::Zip'		=> '1.30',
		'File::Temp'		=> '0.12',
		'File::Find'		=> '1.01',
		'Time::Local'		=> '1.07',
		'IO::File'		=> '1.14',
		'File::Basename'        => '2.76'
		},
	'EXE_FILES'	=>
		[
		]
	);

#-----------------------------------------------------------------------------
