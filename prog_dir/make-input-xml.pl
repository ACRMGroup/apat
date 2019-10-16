#!{PERL} -s
#*************************************************************************
#
#   Program:    APAT: make-input-xml
#   File:       make-input-xml.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   Create an XML input file for APAT from a FASTA file
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

HelpMessage() if(defined($::h) || ($#ARGV != 2));

my($sequence,$type,$emailaddress,$outputfile,$seqid);
my($i) = 0;

#number of mandatory input parameters on command line - used to print error message
my $j = 3;


#Prompt the user for input fields
if($ARGV[0] eq '')
{
    $type = GetPlant("\n\n Please enter the origin of protein sequence - either plant or non-plant (P for plant and N for non-plant) [N]: ");    
    
    $sequence = GetText("\n\n Please enter the path and name of the input file containing a protein sequence in Fasta format : ");
    
    $emailaddress = GetText("\n\n Please enter your email address : "); 
    
    $outputfile = GetText("\n\n Please enter the name for the output XML file: ");   
}
else #Take the input from command line
{
    if(defined($::plant))
    {
        $type = 'plant';
    }
    else
    {
        $type = 'non-plant';
    }
    
    $sequence = shift @ARGV;
    $emailaddress = shift @ARGV;
    $emailaddress =~ s/\s+//g;
    $outputfile = shift @ARGV;
}

$sequence = ReadFile($sequence); 
if($sequence =~ m/^>(.*?)\n(.*)/s)
{
    $seqid = $1;
    $sequence = $2;
}

if($seqid eq '') 
{
    $seqid = "undefined";
}

$::xml_format = "<input>\n<sequenceid origin = '$type'>$seqid</sequenceid>\n<sequence>$sequence</sequence>\n<emailaddress>$emailaddress</emailaddress>\n</input>";

WriteFile($outputfile);


#######################################################################
# Writes an XML APAT input file 
sub WriteFile
{
    my($inputfile) = @_;

    open(XIP,">$inputfile") or die $!;
    print XIP $::xml_format; 
    close XIP;
}


#######################################################################
# Gets text from the keyboard
sub GetText
{
    my($prompt) = @_;
    my($text);

    print $prompt;
    $text = <>;
    chomp($text);
    return($text);
}


#######################################################################
sub GetPlant
{ 
    my($prompt) = @_;
    my($text);
    
    print $prompt;
    $text = <>;
    chomp($text);
    return('plant') if((substr($text,0,1) eq "P") ||
                       (substr($text,0,1) eq "p"));
    return('non-plant');
}


#######################################################################
# Reads a sequence data file
sub ReadFile
{
    my($inputfile) = @_;
    my $data;
  
    open(IP,"$inputfile") or die $!;
    while(<IP>)
    {
       $data .= $_;  
    }
    close IP; 

    return($data);
}


#######################################################################
# prints a help message and exits
sub HelpMessage
{
    print STDERR <<__EOF;

make-input-xml.pl  V1.0 (c)2005, S.V.V. Deevi, University of Reading. 

Syntax:
   ./make-input-xml.pl [[-plant] file.faa email out.xml]

   (defaults to non-plant)

   This program writes the XML input file required by the APAT master program.
   It takes a file containing a single sequence in FASTA format together with
   your EMail address and the output XML file to be written. You can also
   specify whether the sequence is of plant origin.

   You can choose between being prompted by the program for input fields or to 
   submit input parameters on the command line. 


__EOF

    exit 0;
}
