#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: PSORT
#   File:       11psort.pl
#   
#   Version:    V1.2
#   Date:       15.08.05
#   Function:   APAT plug-in wrapper for PSORT
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
#   V1.0  05.07.05 Original
#   V1.1  20.07.05 - Copes with the modified input XML format
#   V1.2  15.08.05 - Produces additional tags called <info> and <link> 
#*************************************************************************
use strict;

use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence, $parameter, $server, $link);
my ($emailaddresstag, $emailaddress);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;      

    foreach $parameter($input->getElementsByTagName("parameter"))
    {
        $server = $parameter->getAttribute('server');
        if($server eq 'psort')
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

psort($sequence);


###########################################################################
##########################              PSORT              ################
sub psort
{
    my($sq) = @_;
    my ($results, $dt, @lines);
    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunPSORT($sq);

    @lines = split(/\n/,$results);
 
    print <<__EOF;
    <result program='PSORT' version='old version'>
       <function>prediction of protein localization sites</function>
       <info href='http://psort.nibb.ac.jp/form.html'>PSORT Web Server</info>
       <run>
          <params>
              <param name = '$origin' value = 'Checked'/>
          </params>
          <date>$dt</date>
       </run>
       <predictions>
           <link href='$link'>Actual prediction(native, unparsed form)- available only for a limited time</link>
__EOF

       parse(@lines);

       print <<__EOF; 
       </predictions>
   </result>
__EOF
}


###########################################################################
sub RunPSORT
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
    $url = "http://psort.nibb.ac.jp/cgi-bin/okumura.pl";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
   
    $post = "origin=$origin&sequence=$seq";

    $ua = CreateUserAgent($webproxy);
    $req = CreatePostRequest($url, $post);
    $result = GetContent($ua, $req);
    $link = "$url?origin=$origin&amp;title=&amp;sequence=$seq";

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

########################################################################
sub parse
{
    my @data =@_;
    my ($i,$in,@location,@score);
    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];
        if(/^----- Final Results -----/)
        {
            $i++;
            $in=1;
        }
        elsif(/^----- The End -----/)
        {
            $in=0;  
        }
        elsif($in)
        {
            s/^\s+//;
                        
            if(length())
            {
                s/\s\W+\s\w+=(.*) < succ>$//; 
                print <<__EOF;
                <perseq name='$_'>
                    <value-perseq highlight='1'>$1</value-perseq>
                </perseq>        
__EOF
            }
        }
    }
}
