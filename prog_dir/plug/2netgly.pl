#!{PERL}
#*************************************************************************
#
#   Program:    APAT: netgly
#   File:       2netgly.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   APAT plug-in wrapper for NetGly
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
use LWP::UserAgent;


my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
my ($sequenceidtag, $sequenceid, $origin, $sequencetag, $sequence);
my ($emailaddresstag, $emailaddress, @sqtest);
my ($r, @residue, $dt, @lines);

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

for($r=0;$r<=$#sqtest;$r++)
{
    $residue[$r] = $sqtest[$r];
}

netoglyc($sequence);



##############################################################################
##########                        NETOGLYC                         ###########
sub netoglyc
{
    my($sq) = @_;
    my ($results, $i, $j, $k, $l, $npred, $m, @thrres, @predicted, $tr);
    my $dt = `date`;
    $dt =~ s/\n//;
    $results = RunNetOGlyc($sq);
    @lines = linebyline($results);
    my ($Gscore_ref,$Iscore_ref) = parse(@lines);

    print <<__EOF;
    <result program='NetOGlyc' version='3.1'>
        <function> Protein Glycosylation sites Prediction</function>
	<run>
	  <params>
	     <param name='Generate Graphics' value='Unchecked'/>
	     <param name='Run Signal Peptide Check' value='Unchecked'/>
          </params>
          <date>$dt</date>
        </run>
        <predictions>
	   <perres-number name='gscore' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
               for($i=0;$i<@$Gscore_ref;$i++)
	       {
		   $j=$i+1;
                   $$Gscore_ref[$i] = 0 if(!defined($$Gscore_ref[$i]));
		   printf "              <value-perres residue='$j'>%f</value-perres>\n",$$Gscore_ref[$i];
		   if($$Gscore_ref[$i]>0.500)
		   {
		       push(@thrres,$j);
		       $predicted[$j] = 1;
		   }
		   else
		   {
		       $predicted[$j] = 0;
		   }
	       }
               print <<__EOF;
           </perres-number>
	   <perres-number name='iscore' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
               for($k=0;$k<@$Iscore_ref;$k++)
	       {
		   $l=$k+1;
                   $$Iscore_ref[$k] = 0 if(!defined($$Iscore_ref[$k]));
		   printf "              <value-perres residue='$l'>%f</value-perres>\n",$$Iscore_ref[$k];
		   if($residue[$k] eq "T")
		   {
		       if(($$Iscore_ref[$k]>0.500) && ($$Gscore_ref[$k]<=0.500)) 
		       {
			   $npred = 0;
			   for($m=(max(0,$l-10));$m<=(min(scalar(@$Iscore_ref),$l+10));$m++)
			   {
			       $npred += $predicted[$m];
			   }
			   if($npred==0)
			   {
			      # printf "               <value-perres residue='$l'>%f</value-perres>\n",$$Iscore_ref[$k];
			       push(@thrres,$l);
			   }
		       }
		   }
	       }
               print <<__EOF;
           </perres-number>
	   <threshold>
	      <description>G-scores greaterthan 0.5 are predicted as positive predictions. However for threonines an additional score is used: if the G-score is less than 0.5 but the I-score greater than 0.5 and there are no predicted neighbouring sites (distance less than 10 residues) the residue is also predicted as glycosylated.
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


########################################################################
sub RunNetOGlyc
{
    my($seq) = @_;
    my($webproxy, $url, $post, $ua, $req, $result, @score);

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
    $post = "configfile=/usr/opt/www/pub/CBS/services/NetOGlyc-3.1/NetOGlyc.cf&seqpaste=$seq";

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
  my ($i,$in,@fields,@Gscore,@Iscore, @score);
  for($i=0; $i<@data; $i++)
  {
      $_ = $data[$i];
      
      if(/^Name\s+/)            # -w Causes a warning here
      {
	  $i++;
	  $in=1;
      }
      elsif(/^------/)
      {
	  $in=0;  
      }
      elsif($in)
      {
	  s/^\s+//;
	  if(length())
	  {
	      @fields=split();
	      $Gscore[$fields[2]-1]=$fields[3];
	      $Iscore[$fields[2]-1]=$fields[4];
	  }
      }
      elsif(($fields[2]-1 <= $#sqtest+1)) 
      {
          if(defined($fields[2]))
          {
              if(!$score[$fields[2]-1])
              {
                  $fields[2] = $#sqtest+1;
                  $Gscore[$fields[2]-1]=0;
                  $Iscore[$fields[2]-1]=0;
              }
          }
      }
  }
  return(\@Gscore,\@Iscore);
}


#################################################################
sub linebyline
{
    my($results) =@_;
    my @lines;
    @lines = split(/\n/,$results);
    return(@lines);
}
 
#################################################################
sub max
{
    my($x,$y) = @_;
    my($z);
    $z = ($x>$y)?$x:$y;
    return($z);
}

#################################################################
sub min
{
    my($x,$y) = @_;
    my($z);
    $z = ($x<$y)?$x:$y;
    return($z);
}
