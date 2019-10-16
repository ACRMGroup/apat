#!/usr/bin/perl -w
#*************************************************************************
#
#   Program:    APAT: SubLoc
#   File:       subloc.pl
#   
#   Version:    V1.0
#   Date:       03.02.06
#   Function:   APAT plug-in wrapper for SubLoc
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
#   V1.0  03.02.06 Original
#   
#*************************************************************************
use strict;

use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence, $link);
my ($emailaddresstag, $emailaddress, $parameter, $server);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;	

    foreach $parameter($input->getElementsByTagName("parameter"))
    {
        $server = $parameter->getAttribute('server');
        if($server eq 'subloc')
        {
            my($param) = $parameter->getAttribute('param');
            if($param eq 'origin')
            {
                $origin = $parameter->getAttribute('value');
            }
        }
    }
}

$sequence =~ s/\s+//g;
subloc($sequence);


##############################################################################
##########                        SUBLOC                          ###########
sub subloc
{
    my($seq) = @_;
    my ($results,$dt,@lines);
    my($pl,$loc,$ri,$ind,$ea,$acc);

    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunSubLoc($seq,$origin);
    @lines = split(/\n/,$results);
    ($pl,$loc,$ri,$ind,$ea,$acc) = Parse(@lines);	

    print <<__EOF;
    <result program='SubLoc' version='1.0'>
       <function>Protein subcellular localization Prediction</function>
       <info href='http://www.bioinfo.tsinghua.edu.cn/SubLoc/'>SubLoc Web Server</info>
       <run>
          <params>
             <param name = '$origin' value = 'Checked'/>
	  </params>
	  <date>$dt</date>
       </run>
       <predictions>
       <link href='$link'>Actual prediction(native, unparsed form)- available only for a limited time</link>
       
            <perseq name = '$pl'>\n";
                <description>Predicted subcellular Location of the protein</description>\n";
                <value-perseq highlight='1'>$loc</value-perseq>\n";
            </perseq>\n";
           
            <perseq name = '$ri'>
	        <description>Value of Reliability Index</description>
	        <value-perseq highlight='0'>$ind</value-perseq>\n";
            </perseq>
	    <perseq name = '$ea'> 
	        <description>Expected Accuracy in percentage</description>
	        <value-perseq highlight='0'>$acc</value-perseq>\n";
	    </perseq>
	</predictions>
    </result>       
__EOF
}



#*************************************************************************
sub RunSubLoc
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
    if($origin eq 'prokaryotic')
    {
        $url = "http://www.bioinfo.tsinghua.edu.cn/SubLoc/cgi-bin/pro_subloc.cgi";
    }
    elsif($origin eq 'eukaryotic')
    {
        $url = "http://www.bioinfo.tsinghua.edu.cn/SubLoc/cgi-bin/eu_subloc.cgi";
    }

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
    $post = "INPUT_SEQUENCE=$seq";

    $ua = CreateUserAgent($webproxy);
    $req = CreatePostRequest($url, $post);
    $result = GetContent($ua, $req);
    $link = $url;
       
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
sub Parse
{
    my (@data) = @_;
    my ($i,$pl,$loc,$ri,$ind,$ea,$acc,$res);
 
    $res = join(' ',@data);

    if($res)
    {   
	$_ = $res;
	if(/(Predicted Location): (.*)<\/font>.*(Reliability Index): RI = (\d).*Expected .*= (.*)<\/font>/)
	{
	    $pl  = $1;
	    $loc = $2;
	    $ri  = $3;  
	    $ind = $4;
	    $ea  = 'Expected Accuracy';
	    $acc = $5;
        }
    }
    return($pl,$loc,$ri,$ind,$ea,$acc);
}
