#!{PERL}
#*************************************************************************
#
#   Program:    APAT: Plasmit
#   File:       8plasmit.pl
#   
#   Version:    V1.0.1
#   Date:       13.05.05
#   Function:   APAT plug-in wrapper for PLASMIT
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
#   V1.0    13.05.05 Original
#   V1.0.1  26.05.05 New plug-ins
#
#*************************************************************************
use strict;
use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence);
my ($emailaddresstag, $emailaddress, @sqtest);


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
plasmit($sequence);


##############################################################################
##########                        PLASMIT                          ###########
sub plasmit
{
    my($seq) = @_;
    my($results,@lines);
    $results = RunPlasmit($seq,$origin);
    @lines = split(/\n/,$results);
    parse(@lines);
}


#*************************************************************************
sub RunPlasmit
{
    my($seq,$origin) = @_;
    my($webproxy, $url, $post, $ua, $req, $result, $orgtype);

    # Specify proxy server (with user/password) if required
    if(defined($ENV{WEBPROXY}))
    {
	$webproxy = $ENV{WEBPROXY};
    }
    else
    {
	$webproxy = '';
    }
	    
    # This is the URL for the CGI script we are accessing
    $url = "http://gecco.org.chemie.uni-frankfurt.de/cgi-bin/plasmit/runanalysis.cgi";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
    # NOTE! For some reason this server NEEDS the configfile to come first

    $orgtype = OrgType($origin);
    $post = "sequence=>$sequenceid\n$seq&output=long";

    $ua = CreateUserAgent($webproxy);
    $req = CreatePostRequest($url, $post);
    $result = GetContent($ua, $req);

    return($result);
}

########################################################################
sub GetContent
{
    my($ua, $req) = @_;
    my($res);

    $res = $ua->request($req);
    if($res->is_success)
    {
        return($res->content);
    }
    return(undef);
}

########################################################################
sub CreatePostRequest
{
    my($url, $params) = @_;
    my($req);
    $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
#    $req->content_type('multipart/form-data');
    $req->content($params);

    return($req);
}

########################################################################
sub CreateUserAgent
{                               
    my($webproxy) = @_;

    my($ua);
    $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0');
    if(length($webproxy))
    {
        $ua->proxy(['http', 'ftp'] => $webproxy);
    }
    return($ua);
}


#######################################################################
sub OrgType
{
    my($origin) = @_;
    my $orgtype;

    if($origin eq 'non-plant')
    {
	$orgtype = '2';
    }
    elsif($origin eq 'plant')
    {
	$orgtype = '1';
    }
    return $orgtype;
}


#######################################################################

sub parse
{
    my @data =@_;
    my($jury,$text,$reliability,$dt,@fields);
    
    $dt=`date`;
    $dt =~ s/\n//;
    
    $text = join(' ', @data);
    $text = "\U$text";
    $text =~ s/[\n\r]//g;
    $text =~ /JURY(.*?)\<\/TABLE\>/;
    $text = $1;
    $text =~ /\<TR\>(.*?)\<\/TR\>/;
    $text = $1;
    $text =~ s/\<\/TD\>//g;
    @fields = split(/\<TD\>/, $text);
    $text = $fields[8];
    $text =~ /(.*?)\((.*?)\)/;
    $jury = $1;
    $reliability = $2;

    $jury =~ s/MITO/MITOCHONDRIAL/;
    

    print <<__EOF;
    <result program='Plasmit' version='0'>
       <function>Prediction of mitochondrial transit peptides in Plasmodium falciparum</function>
       <run>
          <params>
             <param name = 'prediction only' value = 'Checked'/>
          </params>
	  <date>$dt</date>
       </run>
       <predictions>
       	  <perseq name = 'Jury'>
             <description>Mitochondrial transit peptide prediction</description>
                    <value-perseq highlight='1'>$jury</value-perseq>
      	  </perseq>
          <perseq name = 'Reliability score'>
             <description>Reliability score for the prediction</description>
                    <value-perseq highlight='0'>$reliability</value-perseq>  
          </perseq>
       </predictions>
    </result>   
__EOF
}    
