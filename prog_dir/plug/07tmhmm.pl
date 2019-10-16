#!{PERL} -w
#*************************************************************************
#
#   Program:    APAT: TMHMM
#   File:       7TMHMM.pl
#   
#   Version:    V1.3
#   Date:       17.08.05
#   Function:   APAT plug-in wrapper for TMHMM
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
#   V1.1  25.07.05 - tidied up version with removal of unwanted lines of code.
#   V1.2  15.08.05 - Produces additional tags called <info> and <link>
#   V1.3  17.08.05 - Prints threshold description.
#*************************************************************************
use strict;

use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile($ARGV[0]);
my ($sequenceidtag, $sequenceid, $sequencetag, $sequence, $link);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;      
}

$sequence =~ s/\s+//g;

TMHMM($sequence);


###########################################################################
##########################         TMHMM                     ################
sub TMHMM
{
    my($sq) = @_;
    my ($results, $dt, $count, $i, $j, $inscore_ref, $memscore_ref, $outscore_ref, $thrres, $tr, @lines);
    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunTMHMM($sq);
    @lines = linebyline($results);
       
   ($inscore_ref,$memscore_ref,$outscore_ref,$thrres) = parse(@lines);

    print <<__EOF;
    <result program='TMHMM' version='2.0'>
        <function>predictions of transmembrane helices in protein</function>
        <info href='http://www.cbs.dtu.dk/services/TMHMM/'>TMHMM Web Server</info>
        <run>
           <params>
              <param name = 'Extensive, with graphics' value = 'Checked'/>
              <param name = 'Use old model(version 1)' value = 'Unchecked'/>
           </params>
           <date>$dt</date>
        </run>
        <predictions>
           <link href='$link'>Actual prediction(native, unparsed form)- available only for a limited time</link>
	   <perres-number name='inscore' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
               for($i=0;$i<@$inscore_ref;$i++)
	       {
		   $j=$i+1;
                   printf "              <value-perres residue='$j'>%f</value-perres>\n",$$inscore_ref[$i];
	       }
               print <<__EOF;
           </perres-number>
	   <perres-number name='memscore' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
               for($i=0;$i<@$memscore_ref;$i++)
	       {
		   $j=$i+1;
                   printf "              <value-perres residue='$j'>%f</value-perres>\n",$$memscore_ref[$i];
               }
               print <<__EOF;
           </perres-number>
           <perres-number name='outscore' clrmin = '0.0' clrmax = '1.0' graph='1' graphtype='bars'>
__EOF
               for($i=0;$i<@$outscore_ref;$i++)
	       {
		   $j=$i+1;
                   printf "              <value-perres residue='$j'>%f</value-perres>\n",$$outscore_ref[$i];
               }
               print <<__EOF;
           </perres-number>
	   <threshold>
	      <description>If memscore is the highest among the three, then it is shown as positive prediction.
	      </description>
__EOF
              foreach $tr(@$thrres)
              {  
                  print "              <thr-res>$tr</thr-res>\n";
              }
           print <<__EOF;
           </threshold>
__EOF
           perdom(@lines);
           perseq(@lines);
        print <<__EOF;
        </predictions>
     </result>
__EOF
}

###########################################################################
sub RunTMHMM
{
    my($seq) = @_;
    my($url, $post, $ua, $req, $result);
    $::webproxy=0;
    # Specify proxy server (with user/password) if required
    if(defined($ENV{WEBPROXY}))
    {
        $::webproxy = $ENV{WEBPROXY};
    }
    else
    {
        $::webproxy = '';
    }
    # This is the URL for the CGI script we are accessing
    $url = "http://www.cbs.dtu.dk/cgi-bin/nph-webface";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
    # NOTE! For some reason this server NEEDS the configfile to come first
    $post = "configfile=/usr/opt/www/pub/CBS/services/TMHMM-2.0/TMHMM2.cf&SEQ=$seq&outform=-noshort";

    $ua = CreateUserAgent($::webproxy);
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
    $link = $url;
    $link =~ s/&/&amp;/g;

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

#################################################################

sub perdom
{
    my @data =@_;
    my ($i,$in,@fields,$begin,$end,$orientation,$highlight);
    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];
        if(/^<pre>/)
        {
            $i++;
            $in=1;
        }
        elsif(/^<\/pre>/)
        {
            $in=0;  
        }
        elsif($in)
        {
            s/^\s+//;
            if((length()) && (!(/^\#/)))
            {
                @fields = split();
                $orientation=$fields[2];
                $begin=$fields[3];
                $end=$fields[4];
                
                $highlight=0;

                print <<__EOF;
                <perdom name='TM Helix' highlight='$highlight' rangemin='$begin' rangemax='$end'>
                    <value-perdom label='Orientation'>
                    $orientation
                    </value-perdom>                    
                </perdom>
__EOF
            }
        } 
    }
}


#################################################################

sub perseq
{
    my @data =@_;
    my ($i,$score,$description,$highlight);


    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];

        s/^\s*//;

        if(/^\#.* Number of predicted TMHs:\s+(.*)$/)
        {
            $score = $1;
            chomp($score);
            print <<__EOF;
            <perseq name='Number of predicted TMHs'>
                <description>It tells about the number of Transmembrane helices found for the query protein sequence</description> 
                          <value-perseq highlight='1'>$score</value-perseq>
            </perseq>
__EOF
        }
        if(/^\#.* Exp number of AAs in TMHs:\s+(.*)$/)
        {
            $score = $1;
            chomp($score);
            print <<__EOF;
            <perseq name='Exp number of AAs in TMHs'>
                <description>It tells about the expected number of amino acids in Transmembrane helices. If this number is larger than 18 it is very likely to be a transmembrane protein (OR have a signal peptide). </description> 
                          <value-perseq highlight='0'>$score</value-perseq>
            </perseq>
__EOF
        }
        if(/^\#.* Exp number, first 60 AAs:\s+(.*)$/)
        {
            $score = $1;
            chomp($score);
            print <<__EOF;
            <perseq name='Exp number, first 60 AAs'>
                <description>It tells about the expected number of aminoacids in  Transmembrane helices in the first 60 amino acids of the protein. If this number more than a few, you should be warned that a predicted transmembrane helix in the N-term could be a signal peptide. </description> 
                          <value-perseq highlight='0'>$score</value-perseq>
            </perseq>
__EOF
        } 
        if(/^\#.* Total prob of N-in:\s+(.*)$/)
        {
            $score = $1;
            chomp($score);
            print <<__EOF;
            <perseq name='Total prob of N-in'>
                <description>It tells about the the total probability that the N-term is on the cytoplasmic side of the membrane.</description> 
                          <value-perseq highlight='1'>$score</value-perseq>
            </perseq>
__EOF
        } 
        if(/^\#.* (POSSIBLE N-term signal sequence)/)
        {
            $score = $1;
            chomp($score);
            print <<__EOF;
            <perseq name='Warning'>
                <description>It is a warning that is produced when Exp number, first 60 AAs is larger than 10.
</description> 
                          <value-perseq highlight='0'>$score</value-perseq>
            </perseq>
__EOF
        } 
    }
}

########################################################################
sub parse
{
  my @data =@_;
  my ($i,$in,$url,$ua,$req,$result,@thr,@fields,@inscore,@memscore, @outscore,@lines);
  $url = "http://www.cbs.dtu.dk";
  for($i=0; $i<@data; $i++)
  {
      $_ = $data[$i];
      
      if(/^<A HREF="(.*.plp)">data/)            # -w Causes a warning here
      {          
          $url .= $1;
      }
  }
  
  $ua = CreateUserAgent($::webproxy);
  $req = CreateGetRequest($url);
  $result = GetContent($ua, $req);

  @lines = linebyline($result);
  
  for($i=0; $i<@lines; $i++)
  {
      $_ = $lines[$i];
      
      if(/^\d/)
      {
          @fields=split();
          $inscore[$fields[0]-1]=$fields[2];
          $memscore[$fields[0]-1]=$fields[3];
          $outscore[$fields[0]-1]=$fields[4];
          

          if(($fields[3]>$fields[2])&&($fields[3]>$fields[4]))
          {
              push(@thr, $fields[0]);
          } 
      }
  }
  return(\@inscore,\@memscore,\@outscore,\@thr);
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
