#!{PERL} 
#*************************************************************************
#
#   Program:    APAT: netpho
#   File:       1netpho.pl
#   
#   Version:    V1.1
#   Date:       21.04.05
#   Function:   APAT plug-in wrapper for NETPHOS
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
#   V1.1  21.04.05 Reverted to a pre-release piece of code
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

netphos($sequence);


##############################################################################
##########                        NETPHOS                          ###########
sub netphos
{
    my($sq) = @_;
    my ($results, $dt, @lines, @score, $count, $k, $val, @thrres, $tr);
    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunNetPhos($sq);
    @lines = split(/\n/,$results);
    @score = parse(@lines);

    print <<__EOF;
    <result program='NetPhos' version='2.0'>
       <function>Protein Phosphorylation sites Prediction</function>
       <run>
          <params>
             <param name = 'Serine' value = 'Checked'/>
	     <param name = 'Threonine' value = 'Checked'/>
	     <param name = 'Tyrosine' value = 'Checked'/>
	     <param name = 'Generate Graphics' value = 'unChecked'/>
	     <param name = 'Threshold' value = '0.500'/>
          </params>
	  <date>$dt</date>
       </run>
       <predictions>
          <perres-number name = 'P-score' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
                $count=1;
                foreach $val(@score)
                { 
	            $k = $count;
                    $val = 0 if(!defined($val));
		    printf "              <value-perres residue='$k'>%f</value-perres>\n",$val;
		    if($val>0.500)
		    {
			push(@thrres,$k);
		    }
	            $count++;
                }
                print <<__EOF;
          </perres-number>
	  <threshold>
	     <description>P-scores greater than 0.5 are considered as positive predictions
	     </description>
__EOF
                foreach $tr(@thrres)
	        {  
		    print "              <thr-res>$tr</thr-res>\n";
		}
                print <<__EOF;
	  </threshold>    
       </predictions>
    </result>       
__EOF
}


######################################################################
sub RunNetPhos
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
    $post = "configfile=/usr/opt/www/pub/CBS/services/NetPhos-2.0/NetPhos.cf&seqpaste=$seq&tyrosine=ps&serine=ps&threonine=ps";

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
    my ($i,$in,@fields,@score);
    for($i=0; $i<@data; $i++)
    {
	$_ = $data[$i];
	if(/^Name/)             # -w causes a warning here
	{
	    $i++;
	    $in=1;
	}
	elsif(/^______/)
	{
	    $in=0;  
	}
	elsif($in)
	{
	    s/^\s+//;
	    if(length())
	    {
		@fields=split();
		$score[$fields[1]-1]=$fields[3];
	    }
	}
        elsif(($fields[1]-1 <= $#sqtest+1)) 
	{
            # Fixed for V1.1
            if(!defined($fields[1]) || !$score[$fields[1]-1])
 	    {
 		$fields[1] = $#sqtest+1;
 		$score[$fields[1]-1]=0;
 	    }
	}
    }
    return(@score);
}
