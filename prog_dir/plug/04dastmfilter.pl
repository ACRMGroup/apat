#!/acrm/usr/local/bin/perl -w
#*************************************************************************
#
#   Program:    APAT: DAS-TMfilter
#   File:       04das.pl
#   
#   Version:    V1.3
#   Date:       27.02.06
#   Function:   APAT plug-in wrapper for DAS-TMfilter
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
#   V1.1  25.07.05 - tidied up version with removal of unwanted lines of code which also now prints the comment field correctly.
#   V1.2  15.08.05 - Produces additional tags called <info> and <link> 
#   V1.3  27.02.06 - Modified URL(broken) to which the data is being submitted. 
#*************************************************************************
use strict;

use XML::DOM;
use LWP::UserAgent;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile($ARGV[0]);
my ($sequenceidtag, $sequenceid, $sequencetag, $sequence);

foreach my $input ($doc->getElementsByTagName("input"))
{
    $sequenceidtag = $input->getElementsByTagName("sequenceid")->item(0);
    $sequenceid = $sequenceidtag->getFirstChild->getNodeValue;
    $sequencetag = $input->getElementsByTagName("sequence")->item(0);
    $sequence = $sequencetag->getFirstChild->getNodeValue;      
}

$sequence =~ s/\s+//g;

das($sequence);


###########################################################################
##########################         DAS                     ################
sub das
{
    my($sq) = @_;
    my ($results, $dt, $count, $i, $Score, $thrres, $tr, @thr, @lines);
    $dt=`date`;
    $dt =~ s/\n//;
    $results = RunDAS($sq);
    @lines = split(/\n/,$results);
    ($Score,$thrres) = parse(@lines);
 
    print <<__EOF;
    <result program='DAS-TM filter'>
       <function>Transmembrane protein predictions</function>
       <info href='http://mendel.imp.univie.ac.at/sat/DAS/DAS.html'>DAS-TMfilter Web Server</info>
       <run>
          <params>
             <param name = 'long output' value = 'Checked'/>
             <param name = 'unconditional evaluation' value = 'Checked'/>
             <param name = 'TM-library size 32' value = 'Checked'/>
          </params>
          <date>$dt</date>
       </run>
       <predictions>
           <perres-number name = 'Score' clrmin = '0.0' clrmax = '5.5' graph='1' graphtype='lines'>
__EOF
                $count = 0;
                for($i=0;$i<@$Score;$i++)
                {
                    $count++;

                    printf "              <value-perres residue='$count'>%f</value-perres>\n",$$Score[$i];
                }
                print <<__EOF;
           </perres-number>
                                  
__EOF
           print <<__EOF;
           <threshold>
              <description>Emperical cuttoff value is 2.5.The residues for which the Scores are higher than both the preceding and following residues are considered as TM helix predictions
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
sub RunDAS
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
    $url = "http://mendel.imp.ac.at/sat/DAS/cgi-bin/das.cgi";

    # These are the data to send to the CGI script, obtained by 
    # examining the submission web page
   
    $post = "LEN=-l&CON=-u&LIB=32&SEQ=$seq";

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

########################################################################
sub parse
{
    my @data =@_;
    my ($i,$in,@fields,@Score,@thr);
    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];
        if(/^===/)
        {
            $i++;
            $in=1;
        }
        elsif(/^<---/)
        {
            $in=0;  
        }
        elsif($in)
        {
            s/^\s+//;
                        
            if((length()) && (/^\d/))
            {
                @fields=split();
                $Score[$fields[0]-1]=$fields[1];
                             
                
                if($fields[1]>= 2.5)
                {
                    push(@thr, $fields[0]);
                } 
            }
        }
    }
    return(\@Score,\@thr);
}


#################################################################

sub perdom
{
    my @data =@_;
    my ($i,$in,@fields,$Score,$peak,$begin,$end,$comment,$Evalue,$highlight);
    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];
        if(/^===/)
        {
            $i++;
            $in=1;
        }
        elsif(/^<---/)
        {
            $in=0;  
        }
        elsif($in)
        {
            s/^\s+//;
            if((length()) && (/^\@/))
            {
                @fields = split();
                $peak=$fields[1];
                $Score=$fields[2];
                $begin=$fields[4];
                $end=$fields[6];
                $Evalue=$fields[7];
               #$comment=$fields[8];
                $comment = '';
                if(/(!!!.*)$/)
                {
                    $comment = $1;
                }

                $highlight=0;

                print <<__EOF;
                <perdom name='TM Helix' highlight='$highlight' rangemin='$begin' rangemax='$end'>
                    <value-perdom label='Peak'>
                    $peak
                    </value-perdom>
                    <value-perdom label='Score'>
                    $Score
                    </value-perdom>
                    <value-perdom label='E-value'>
                    $Evalue
                    </value-perdom>
__EOF
                if($comment)
                {
                    print <<__EOF; 
                    <value-perdom label='Comment'>
                    $comment
                    </value-perdom>
__EOF
                }            
                print <<__EOF;
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
    my ($i,$Qscore,$description,$highlight);
    for($i=0; $i<@data; $i++)
    {
        $_ = $data[$i];
        s/^\s+//;
        if(/^\#.*Q:\s+(.*)$/)
        {
            $Qscore = $1;
            chomp($Qscore);
            print <<__EOF;
            <perseq name='Q-Score(Quality)'>
                <description>Q-score is quality score for an entry of the query against a library of known TM-proteins and is used to judge whether the entry is a TM-protein or not.The value of the score is a real number between 0 and 1 (the higher the better)</description> 
                          <value-perseq highlight='1'>$Qscore</value-perseq>
            </perseq>
__EOF
        }
    }
}





