#!{PERL}
#*************************************************************************
#
#   Program:    APAT: getseq
#   File:       0getseq.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   APAT plug-in wrapper for obtaining the sequence
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

use XML::DOM;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence);
my ($emailaddresstag, $emailaddress, $sequence, @rs, $i);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $origin  = $sequenceidtag->getAttribute('origin');
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;	
    $emailaddresstag = $input->getElementsByTagName("emailaddress")->item(0);
    $emailaddress = $emailaddresstag->getFirstChild->getNodeValue;
}

$sequence =~ s/\s+//g;
@rs = split(//,$sequence);

print "<input>\n   <seqid>$sequenceid</seqid>\n";
for($i=0;$i<=$#rs;$i++)
{
    print "   <seq>$rs[$i]</seq>\n"; 
}
print "</input>\n";


############################################################################

