#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: TargetP
#   File:       5targetp.pl
#   
#   Version:    V1.1
#   Date:       17.06.05
#   Function:   APAT plug-in wrapper for TargetP
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
#   V1.1  17.06.05 Fixed to handle change in TargetP output format
#
#*************************************************************************
use strict;

use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence);
my ($emailaddresstag, $emailaddress);

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
targetp($sequence);


##############################################################################
##########                        TARGETP                          ###########
sub targetp
{
    my($seq) = @_;
    my ($results,$dt,@lines,$SP_ref,$other_ref,$Loc_ref,$mTP_ref);
    my ($RC_ref,$TPlen_ref,$cTP_ref,$i);

    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunTargetP($seq,$origin);
    @lines = split(/\n/,$results);
    if($origin eq 'non-plant')
    {
	($mTP_ref,$SP_ref,$other_ref,$Loc_ref,$RC_ref,$TPlen_ref) = parse(@lines);
    }
    elsif($origin eq 'plant')
    {
	($cTP_ref,$mTP_ref,$SP_ref,$other_ref,$Loc_ref,$RC_ref,$TPlen_ref) = parse(@lines);
    }
    print <<__EOF;
    <result program='TargetP' version='1.01'>
       <function>Protein subcellular location Prediction</function>
       <run>
          <params>
             <param name = 'non plant sequence' value = 'User defined'/>
             <param name = 'plant sequence' value = 'User defined'/>
	     <param name = 'cleavage sites' value = 'Checked'/>
	     <param name = 'no cutoffs' value = 'Checked'/>
          </params>
	  <date>$dt</date>
       </run>
       <predictions>
__EOF
          if($origin eq 'plant')
          {
	      print "	  <perseq name = 'cTP-pred'>\n";
	      print "        <description>Chloroplast transit peptide (cTP) prediction score</description>\n";
	      for($i=0;$i<@$cTP_ref;$i++)
	      { 
		  print "              <value-perseq highlight='0'>$$cTP_ref[$i]</value-perseq>\n";
	      }
	      print "	  </perseq>\n";
          }
         
          print <<__EOF;
	  <perseq name = 'mTP-pred'>
	     <description>Mitochondrial targeting peptide (mTP) prediction score</description>
__EOF
                for($i=0;$i<@$mTP_ref;$i++)
                { 
		    print "             <value-perseq highlight='0'>$$mTP_ref[$i]</value-perseq>\n";
		}
                print <<__EOF;
          </perseq>
	  <perseq name = 'SP-pred'> 
	     <description>Secretory pathway signal peptide (SP) prediction score</description>
__EOF
                for($i=0;$i<@$SP_ref;$i++)
                { 
		    print "             <value-perseq highlight='0'>$$SP_ref[$i]</value-perseq>\n";
		}
                print <<__EOF;
          </perseq>
	  <perseq name = 'other-pred'> 
	     <description>Other targeting peptide predictions score</description>
__EOF
                for($i=0;$i<@$other_ref;$i++)
                { 
		    print "             <value-perseq highlight='0'>$$other_ref[$i]</value-perseq>\n";
		}
                print <<__EOF;
          </perseq>
	  <perseq name = 'Loc-pred'>
	     <description>SUBCELLULAR LOCATION PREDICTION</description>
__EOF
                for($i=0;$i<@$Loc_ref;$i++)
                { 
		    if($$Loc_ref[$i] eq 'C')
		    {
			print "              <value-perseq highlight='1'>CHLOROPLAST, i.e. THE SEQUENCE CONTAINS A CHLOROPLAST TRANSIT PEPTIDE, cTP.</value-perseq>\n";
		    }
		    elsif($$Loc_ref[$i] eq 'M')
		    {
			print "              <value-perseq highlight='1'>MITOCHONDRION, i.e. THE SEQUENCE CONTAINS A MITOCHONDRIAL TARGETING PEPTIDE, mTP.</value-perseq>\n";
		    }
		    elsif($$Loc_ref[$i] eq 'S')
		    {
			print "              <value-perseq highlight='1'>SECRETORY PATHWAY, i.e. THE SEQUENCE CONTAINS A SIGNAL PEPTIDE,SP.</value-perseq>\n";
		    }
		    elsif($$Loc_ref[$i] eq '_')
		    {
			print "              <value-perseq highlight='1'>ANY OTHER LOCATION.</value-perseq>\n";
		    }
		    elsif($$Loc_ref[$i] eq '*')
		    {
			print "              <value-perseq highlight='1'>DONOT KNOW. THIS APPEARS IF CUTOFF RESTRICTIONS WERE DEMANDED AND THE WINNING NETWORK OUTPUT SCORE FOR A SEQUENCE WAS BELOW THE REQUESTED CUTOFF FOR THAT CATEGORY. THE MEANS THAT NO PREDICTION WAS DONE BY TARGETP(ALTHOUGH THE OUTPUT SCORES AND RCs ARE PRESENTED ALSO FOR THESE SEQUENCES).</value-perseq>\n";
		    }
		}
                print <<__EOF;
          </perseq>
	  <perseq name = 'RC-pred'> 
	     <description>Reliability class(RC) is a measure of the size of the difference(diff) between the highest(winning) and the second highest output scores. It ranges from 1 to 5 and the lower the value of RC, the better the prediction.
RC 1: difference greater than 0.800
RC 2: difference less than 0.800 and greater than 0.600
RC 3: difference less than 0.600 and greater than 0.400
RC 4: difference less than 0.400 and greater than 0.200
RC 5: difference less than 0.200</description>
__EOF
                for($i=0;$i<@$RC_ref;$i++)
                { 
		    print "              <value-perseq highlight='0'>$$RC_ref[$i]</value-perseq>\n";
		}
                print <<__EOF;
          </perseq>
	  <perseq name = 'TPlen-pred'> 
	     <description>Target peptide cleavage site prediction says about the predicted length of the presequence(if any was predicted). The actual cleavage site prediction is performed by SignalP for SPs, and by ChloroP for cTPs. The mTP cleavage site prediction, however, is a TargetP-unique feature.</description>
__EOF
                for($i=0;$i<@$TPlen_ref;$i++)
                { 
		    if($$TPlen_ref[$i] =~ /\d+/)
		    { 
			print "              <value-perseq highlight='0'>$$TPlen_ref[$i]</value-perseq>\n";
		    }
		    else
		    {
			print "              <value-perseq highlight='0'>no prediction</value-perseq>\n";
		    }
		}
                print <<__EOF;
          </perseq>   
       </predictions>
    </result>       
__EOF
}


#*************************************************************************
sub RunTargetP
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
    $url = "http://www.cbs.dtu.dk/cgi-bin/nph-webface";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
    # NOTE! For some reason this server NEEDS the configfile to come first

    $orgtype = OrgType($origin);
    $post = "configfile=/usr/opt/www/pub/CBS/services/TargetP/TargetP.cf&seq=$seq&orgtype=$orgtype&cleavsite=%20";

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
    my ($i,$in,@fields,@cTP,@mTP,@SP,@other,@Loc,@RC,@TPlen);
    for($i=0; $i<@data; $i++)
    {
	$_ = $data[$i];
	if(/^Name/)             # SVVD 16.06.05. No longer has leading #
	{
	    $i++;
	    $in=1;
	}
	elsif(/^------/)        # SVVD 16.06.05. No longer has leading #
	{
	    $in=0;  
	}
	elsif($in)
	{
	    s/^\s+//;
	    if(length())
	    {
		if($origin eq 'non-plant')
		{
		    @fields = split();
		    push(@mTP, $fields[2]);
		    push(@SP, $fields[3]);
		    push(@other, $fields[4]);
		    push(@Loc, $fields[5]);
		    push(@RC, $fields[6]);
		    push(@TPlen, $fields[7]);
		}
		if($origin eq 'plant')
		{
		    @fields = split();
		    push(@cTP, $fields[2]);
		    push(@mTP, $fields[3]);
		    push(@SP, $fields[4]);
		    push(@other, $fields[5]);
		    push(@Loc, $fields[6]);
		    push(@RC, $fields[7]);
		    push(@TPlen, $fields[8]);  
		}
	    }
	}
    }
    if($origin eq 'non-plant')
    {
	return(\@mTP,\@SP,\@other,\@Loc,\@RC,\@TPlen);
    }
    elsif($origin eq 'plant')
    {
	return(\@cTP,\@mTP,\@SP,\@other,\@Loc,\@RC,\@TPlen);
    }
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

