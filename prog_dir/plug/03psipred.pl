#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: psipred
#   File:       3psipre.pl
#   
#   Version:    V1.2
#   Date:       15.08.05
#   Function:   APAT plug-in wrapper for PSIPred
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

$::progdir = "/home/sri/psipred"; 

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
psipred($sequence);


##############################################################################
sub psipred
{ 
    my($ipf) =@_;
    my($inputfile,$progdir,$output,$dt,$horizfile,$result);
    my(@lines,$j,$k,$conf_ref,$pred_ref,$tmpdir);

    $tmpdir = "/tmp/psipred_$$";
    `mkdir $tmpdir`;
    $inputfile = "$tmpdir/inputfile"; 

    open(FILE,">$inputfile") || die "Can't write $inputfile";
    print FILE $ipf;
    close FILE;
    
    
    #$output = `$::progdir/runpsipred $inputfile`;
    $output = `cd $tmpdir; $::progdir/runpsipred $inputfile `;
    $dt = `date`;

    $horizfile = "inputfile.horiz";	    

    if($output =~ /$horizfile/)
    {  
        open(HZ,"$tmpdir/$horizfile") || die "can't open $tmpdir/$horizfile\n";
	while(<HZ>)
	{
	    $result .= $_;
	}
	close(HZ);
	@lines = linebyline($result);
	($conf_ref,$pred_ref) = parse(@lines);
	
	
	print <<__EOF;
	<result program='PsiPred' version='2.4'>
	<function> Secondary Structure Prediction</function>
           <info>PSIPRED Local Server</info>
	   <run>
	      <params>
	        <param name = 'Predict Secondary Structure' value = 'Checked'/>
		<param name = 'Predict Transmembrane Topology (MEMSAT)' value = 'Unchecked'/>
		<param name = 'Fold Recognition(GenTHREADER - quick)' value = 'Unchecked'/>
                <param name = 'Fold Recognition' value = 'Unchecked'/> 
		<param name = 'Mask low complexity regions' value = 'Checked'/>
		<param name = 'Mask transmembrane helices' value = 'Unchecked'/>
		<param name = 'Mask coiled-coil regions' value = 'Unchecked'/>
             </params>
             <date>$dt</date>
             </run>
          <predictions> 
	     <perres-number name = 'ssscore' clrmin = '0' clrmax = '9' graph='1' graphtype='lines'>
__EOF
                for($j=0;$j<@$conf_ref;$j++)
                { 
	            $k = $j+1;
	            print "                <value-perres residue='$k'>$$conf_ref[$j]</value-perres>\n";
                }
                print <<__EOF;
             </perres-number>
             <perres-character name='sspred'>
__EOF
                for($j=0;$j<@$pred_ref;$j++)
                { 
	            $k = $j+1;
	            print "                <value-perres residue='$k'>$$pred_ref[$j]</value-perres>\n";
                }
                print <<__EOF;
             </perres-character>
	     <threshold>
	        <description>No specific threshold exists. Instead a confidence level ranging from 0 to 9 is used for the predictions. Higher the value, higher is the confidence.
		</description>
	     </threshold>
          </predictions>
       </result>       
__EOF
    }  
    else
    {
	print " \nCan't find .horiz file - Error has occured while running\n";
    }

    `rm -rf $tmpdir`;
}

################################################################
sub parse
{
    my @data = @_;
    my($i,$cf,$pd,@conf,@pred);
    for($i=0; $i<@data; $i++)
    {
	$_ = $data[$i];
	if(/^Conf:/)
	{
	    s/Conf:\s+//g;
	    $cf.=$_;
	}
	if(/^Pred:/)
	{
	    s/Pred:\s+//g;
	    $pd.=$_;
	}
    }
    $cf =~ s/\s+//g;   	
    $pd =~ s/\s+//g;
    @conf = split('',$cf);
    @pred = split('',$pd);
    return(\@conf,\@pred);
}



#################################################################
sub linebyline
{
    my($results) =@_;
    my @lines;
    @lines = split(/\n/,$results);
    return(@lines);
}
 
