#!{PERL} 
#*************************************************************************
#
#   Program:    APAT: chloroP
#   File:       1netpho.pl
#   
#   Version:    V1.0.1
#   Date:       09.05.05
#   Function:   APAT plug-in wrapper for CHLOROP
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
#   V1.0    09.05.05 Original
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
@sqtest = split(//,$sequence);

ChloroP($sequence);


##############################################################################
##########                        CHLOROP                          ###########
sub ChloroP
{
    my($sq) = @_;
    my ($results, $dt, @lines, $Score, $cTP, $CSscore, $cTPlength, $i);
    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunChloroP($sq);
    
    @lines = split(/\n/,$results);

    ($Score, $cTP, $CSscore, $cTPlength) = parse(@lines);

    print <<__EOF;
    <result program='ChloroP' version='1.1'>
       <function>prediction of the presence of chloroplast transit peptides (cTP) in protein sequences and the location of potential cTP cleavage sites</function>
       <run>
          <params>
              <param name = 'Detailed output' value = 'Unchecked'/>
          </params>
	  <date>$dt</date>
       </run>
       <predictions>
          <perseq name = 'Score'>
             <description>It is the output score from the second step network. The prediction cTP/no cTP is based solely on this score.</description>
             <value-perseq highlight='0'>$Score</value-perseq>
          </perseq>
            
          <perseq name = 'cTP'>
	     <description>It tells whether or not this is predicted as a cTP-containing sequence.</description>
             <value-perseq highlight='1'>$cTP</value-perseq>
          </perseq>

          <perseq name = 'CS-score'> 
	     <description>It is the MEME scoring matrix score for the suggested cleavage site.</description>
             <value-perseq highlight='0'>$CSscore</value-perseq>
          </perseq>
                 
          <perseq name = 'cTPlength'>
             <description>It is the predicted length of the presequence (Please note that the prediction of the transit peptide length is carried out and presented even if its presence is not predicted).</description>
             <value-perseq highlight='0'>$cTPlength</value-perseq>
          </perseq>
       </predictions>       
    </result>
__EOF
}

######################################################################
sub RunChloroP
{
    my($seq) = @_;
    my($webproxy, $url, $post, $ua, $req, $result);

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
    $url = "http://www.cbs.dtu.dk/cgi-bin/nph-webface";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
    # NOTE! For some reason this server NEEDS the configfile to come first
    $post = "configfile=/usr/opt/www/pub/CBS/services/ChloroP-1.1/chlorop.cf&seqpaste=$seq";

    $ua = CreateUserAgent($webproxy);
    $req = CreatePostRequest($url, $post);
    $result = GetContent($ua, $req);

    # $result now contains the redirect page - grab the URL for that page
    $url = GrabRedirect($result);
    
    # Iterate while the URL contains 'wait'
    do
    {
        $req = CreateGetRequest($url);
        $result = GetContent($ua, $req);
        $url = GrabRedirect($result);
        sleep 1;
    }   while($url =~ /wait/);

    # The URL is now the one for the results page
    $req = CreateGetRequest($url);
    $result = GetContent($ua, $req);

    return($result);
}

########################################################################
sub GrabRedirect
{
    my($html) = @_;

    $html =~ /location\.replace\(\"(.*?)\"\)/;
    return($1);
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
sub CreateGetRequest
{
    my($url) = @_;
    my($req);
    $req = HTTP::Request->new('GET',$url);
    return($req);
}

########################################################################
sub CreatePostRequest
{
    my($url, $params) = @_;
    my($req);
    $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
#   $req->content_type('multipart/form-data');
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

########################################################################
sub parse
{
    my @data =@_;
    my ($i,$in,@fields,$Score,$cTP,$CSscore,$cTPlength);
    $in =0;
    for($i=0; $i<@data; $i++)
    {
	$_ = $data[$i];
        
        if($in)
        {
            @fields = split;
            last;
        }
        else
        {
            $in = 1 if(/---/);
        }              
    }
    $Score = $fields[2];
    $cTP = $fields[3];
    $CSscore = $fields[4];
    $cTPlength = $fields[5];
    
    $cTP =~ s/Y/Chloroplast Transit Peptide/;
    $cTP =~ s/-/Non-Chloroplast Transit Peptide/;

    return($Score,$cTP,$CSscore,$cTPlength);
}
