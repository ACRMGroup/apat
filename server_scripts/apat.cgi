#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: CGI server
#   File:       apat.cgi
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   APAT CGI scerver
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
use CGI;

$cgi = new CGI;
$pid = $$;

# Get parameters from the web page
$seqid = $cgi->param('SID1');
$sequence = $cgi->param('S1');
$type = $cgi->param('D1');
$emailaddress = $cgi->param('T1');

$type =~ s/\s+//g;
$emailaddress =~ s/\s+//g;

# Extract and split out the identifier and sequence
if($sequence =~ /^>(.*?)\n(.*)/s)
{
    $seqid = $1;
    $sequence = $2;
}
if($seqid eq '') 
{
    $seqid = "undefined";
}

#Build the XML
$xml_format = "<input>\n<sequenceid origin = '$type'>$seqid</sequenceid>\n<sequence>$sequence</sequence>\n<emailaddress>$emailaddress</emailaddress>\n</input>";


$prog_dir = "{SUBS1}";

# Write the input XML then run the master to create the output
$input_xml = WriteInputXML($xml_format);
$output_xml = WriteOutputXML($input_xml);

# Run the display program to create and print the HTML
PrintHTML($output_xml);

        
#*************************************************************************
# Simply writes the XML input file
sub WriteInputXML
{
    my($file) = @_;               
    my $xml_input = "/tmp/${pid}xmlinput.xml";
        
    open(XIP,">$xml_input") or die $!;
    print XIP $file; 
    close XIP;
    return($xml_input);
}


#*************************************************************************
# Runs the master program to generate the output APATML XML
sub WriteOutputXML
{
    my($file) = @_; 
    my($results,$xml_output);
          
    $results = `cd $prog_dir; ./master.pl $file`;

    $xml_output = "/tmp/${pid}xml_output.xml";

    open(XOP,">$xml_output") or die $!;     
    print XOP $results; 
    close XOP;
    return($xml_output);
}


#*************************************************************************
# Runs the display program to convert the APATML to HTML
sub PrintHTML
{
    my($file) = @_; 
    my $webpage;

    $webpage = `cd $prog_dir; ./display.pl -web $file`;

    print $cgi->header();   
    print "$webpage";
}

