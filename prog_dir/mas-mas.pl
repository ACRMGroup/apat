#!{PERL} -s
#*************************************************************************
#
#   Program:    APAT: mas-mas
#   File:       mas-mas.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   APAT master-master program - runs the master on each
#               file in a directory
#   
#   Copyright:  (c) University of Reading / S.V.V. Deevi 2005
#   Author:     S.V.V. Deevi
#   Address:    School of Animal and Microbial Sciences,
#               The University of Reading,
#               Whiteknights,
#               P.O. Box 228,
#               Reading RG6 6AJ.
#               England.
#   EMail:      s.v.v.deevi@reading.ac.uk
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  14.03.05 Original
#
#*************************************************************************
use strict;

HelpDie() if(defined($::h) || ($#ARGV < 1));

my $inputdirname = shift (@ARGV);
my $outputdirname = shift (@ARGV);

# Remove trailing / from directory names
$inputdirname =~ s/\/$//;
$outputdirname =~ s/\/$//;

# Check (and create) directories
if(! -d $inputdirname)
{
    print STDERR "Error: Input directory ($inputdirname) does not exist!\n";
    exit 1;
}
if(! -d $outputdirname)
{
    print STDERR "Warning: creating output directory ($outputdirname)\n";
    `mkdir $outputdirname`;
}

my(@files,$result_xml,$result_html,$file);

$::master = "{SUBS1}/master.pl";
$::display = "{SUBS1}/display.pl";

$::dirpath = $inputdirname;
$::dirpath =~ s/\/$//;
$::outputdir = $outputdirname;
$::outputdir =~ s/\/$//;
 
# Get list of files to process
@files = Extract($::dirpath);

foreach $file(@files)
{
    $::inputfilename = $file;
    $::inputfilename =~ s/\.xml//;
    $result_xml = Annotate($file);    
    WriteHTML($result_xml);
}
    

##############################################################################
# Gets the list of files to process
sub Extract
{
    my($inpdir) = @_;
    my(@fil);

    opendir(ID, $inpdir)|| die "can't open $inpdir";
    @fil = grep !/^\./, readdir(ID);
    closedir(ID);
    
    return(@fil); 
}

##############################################################################
# Runs the master program on a file
sub Annotate
{
    my($file) = @_;
    my($result,$xml_file);

    $result = `$::master $::dirpath/$file`;

    $xml_file = "$::outputdir/$::inputfilename-out.xml";

    open(XF,">$xml_file") or die "can't write to $xml_file";
    print XF $result; 
    close XF;
    
    return($xml_file);
}

##############################################################################
# Runs the display program on a file
sub WriteHTML
{
    my($file) = @_;

    `$::display -outdir=$::outputdir $file >$::outputdir/$::inputfilename-out.html`;
}


##############################################################################
# prints a help message and exits
sub HelpDie
{
    print STDERR <<__EOF;

mas-mas V1.0 (c) 2005, S.V.V.Deevi, University of Reading

Usage: ./mas-mas.pl in-directory out-directory

mas-mas takes a directory name containing one or more APAT input XML files
and runs the APAT master program to write an output XML file for each
input to the specified output directory. It aslo runs the display program
on each output XML file, writing the HTML into the same output directory.

__EOF
    exit 0;
}
