#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: ProSiteScan
#   File:       6prositescan.pl
#   
#   Version:    V1.2
#   Date:       15.08.05
#   Function:   APAT plug-in wrapper for ProSiteScan
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
#   V1.1  21.07.05 - tidied up version with removal of unwanted lines of code.
#   V1.2  15.08.05 - Produces additional tag called <info>
#*************************************************************************
use strict; 

use XML::DOM;

$::prositedir = "/home/sri/prosite/ps_scan";

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $sequencetag, $sequence);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;	
}

$sequence =~ s/\s+//g;
prositescan($sequenceid,$sequence);


##############################################################################
sub prositescan
{ 
    my($identifier,$ipf) =@_;
    my($inputfile,$output,$path,$dt,@lines,$tmpdir);
   
    #Set to the directory where all prosite documents exist. Place even prosite.dat in this directory.

    $tmpdir = "/tmp/prositescan_$$";
    `mkdir $tmpdir`;
    $inputfile = "$tmpdir/inputfile"; 

    open(FILE,">$inputfile") || die "Can't write $inputfile";
    print FILE ">$identifier\n$ipf";
    close FILE;
    
    chomp($dt = `date`);

    $ENV{'PATH'} .= ":$::prositedir";

    $output = `cd $::prositedir; ./ps_scan.pl -o gff $inputfile`;
    `rm -rf $tmpdir`;
    @lines = linebyline($output);
    
    print <<__EOF;
    <result program='PrositeScan' version='1.20'>
       <function>Protein profiles and motifs Prediction</function>
       <info>Local Prositescan Server</info>
       <run>
          <params>
             <param name = 'skip frequently matching patterns' value = 'Unchecked'/>
	     <param name = 'Show low level score' value = 'Unchecked'/>
	     <param name = 'Do not scan profiles' value = 'Unchecked'/>
	     <param name = 'Output format:gff' value = 'Checked'/>
          </params>
	  <date>$dt</date>
       </run>
       <predictions>
__EOF
    
    parse(@lines);
     
    print <<__EOF;
	</predictions>
    </result>
__EOF
}


##############################################################################
sub parse
{
    my @data = @_;
    my($pattern,$begin,$end,$score,$name,$sequence,$highlight,$i,@fields);
    for($i=0; $i<@data; $i++)
    {
	$_ = $data[$i];
        s/^\s+//;
        if(length())
        {
            @fields=split();
            $pattern=$fields[2];
            $begin  =$fields[3];
            $end    =$fields[4];
            $score  =$fields[5] if($fields[5] ne ".");
            if(/Name\s\"(\w+)\"/)
            {
                $name = $1;
            }
            if(/Sequence\s\"([\w-]+)\"/)
            {
                $sequence = $1;
            }

            $highlight = 1;
            $highlight = 0 if(/SkipFlag/);
           
            print <<__EOF;
            <perdom name = '$name' highlight='$highlight' rangemin='$begin' rangemax='$end'>
               <value-perdom label='Pattern'>
               $pattern
               </value-perdom>
               <value-perdom label='Match'>
               $sequence
               </value-perdom>
__EOF
            if($score)
            {
               print <<__EOF;  
               <value-perdom label='Score'>
               $score
               </value-perdom>
__EOF
            }
            print <<__EOF;
            </perdom>
__EOF
        }
    }
}



#################################################################
sub linebyline
{
    my($results) =@_;
    my @lines;
    @lines = split(/\n/,$results);
    return(@lines);
}
 
