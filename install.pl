#!/usr/bin/perl 
#*************************************************************************
#
#   Program:    APAT: install
#   File:       install.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   Install the apat system
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2005
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   Phone:      +44 (0)171 679 7034
#   EMail:      andrew@bioinf.org.uk
#               martin@biochem.ucl.ac.uk
#   Web:        http://www.bioinf.org.uk/
#               
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
#   ./install.pl
#
#   All options/locations will be prompted for
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  14.03.05 Original
#*************************************************************************
use strict;

my($perl, $dohtml, $htmldir, $cgi, $cgiscript, $proxy, $htmltop, $apatdir, $plugdir, $docdir);
my($htmltmp, $psipreddir, $psscandir);

$|=1;

$perl = GetText("\nEnter the full path to your Perl executable. (For example: /usr/bin/perl): ");
$dohtml = GetYorN("Do you wish to create an APAT web server? (Y/N) [Y]: ");

if($dohtml)
{
   $htmldir = GetDirectory("\nEnter directory for your HTML file for the apat web page. (For example: /var/httpd/html/apat): ");

   $cgi     = GetDirectory("Enter directory where your CGI script for apat will live. (For example: /var/httpd/cgi-bin/apat): ");

   $cgiscript = GetText("Enter the URL for the CGI directory you just specified. (For example: http://www.myserver.com/cgi-bin/apat): ");

   $proxy = GetText("\nIf you are behind a firewall which requires a proxy server to be used to access the web, specify the proxy server URL here. (For example: http://user:password\@proxy.myserver.com:8080) [Press return for none]: ");
   $proxy =~ s/\s//g;
   $proxy = "BLANK" if($proxy eq "");

   $htmltop = GetText("\nEnter the directory name at the top of your HTML tree. (For example: /var/httpd/html): ");
   $htmltmp = CheckDir("$htmltop/tmp");
}

$apatdir = GetDirectory("Enter directory where you wish to store the apat scripts. (For example: /usr/local/apat/bin): ");
$plugdir = CheckDir("$apatdir/plug");

$docdir = GetDirectory("Enter the directory where you wish to place the APAT man pages. (For example: /usr/local/apat/man1): ");

$psipreddir = GetText("Enter the directory of your PSI-PRED installation (return for none): ");
$psscandir = GetText("Enter the directory from your ProSiteScan installation which contains the ps_scan.pl script and prosite.dat (return for none): ");

if($dohtml)
{
   print <<__EOF;

You must ensure that the directory '$htmltop/tmp' is writable by the
Apache web server user (typically the 'nobody' or 'apache' user). It is also
sensible to have a cron job that regularly removes files from that directory.
__EOF

   InstallFile("html_files/apat.html", "$htmldir/index.html", 0, "$cgiscript/apat.cgi", "", $perl);
   InstallFile("server_scripts/apat.cgi", "$cgi/apat.cgi", 1, $apatdir, "", $perl);
}

# Driver programs
InstallFile("prog_dir/master.pl", "$apatdir/master.pl", 1, $proxy, $plugdir, $perl);
InstallFile("prog_dir/mas-mas.pl", "$apatdir/mas-mas.pl", 1, $apatdir, "", $perl);
InstallFile("prog_dir/display.pl", "$apatdir/display.pl", 1, $htmltop, "", $perl);
InstallFile("prog_dir/mix.pl", "$apatdir/mix.pl", 1, $apatdir, "", $perl);

# Unconfigured plugins (web)
InstallFile("prog_dir/plug/00getseq.pl",     "$plugdir/00getseq.pl",      1, "", "", $perl);
InstallFile("prog_dir/plug/01netphos.pl",    "$plugdir/01netphos.pl",     1, "", "", $perl);
InstallFile("prog_dir/plug/02netoglyc.pl",   "$plugdir/02netoglyc.pl",    1, "", "", $perl);
InstallFile("prog_dir/plug/04dastmfilter.pl","$plugdir/04dastmfilter.pl", 1, "", "", $perl);
InstallFile("prog_dir/plug/05targetp.pl",    "$plugdir/05targetp.pl",     1, "", "", $perl);
InstallFile("prog_dir/plug/07tmhmm.pl",      "$plugdir/07tmhmm.pl",       1, "", "", $perl);
InstallFile("prog_dir/plug/08plasmit.pl",    "$plugdir/08plasmit.pl",     1, "", "", $perl);
InstallFile("prog_dir/plug/09chlorop.pl",    "$plugdir/09chlorop.pl",     1, "", "", $perl);
InstallFile("prog_dir/plug/10psort.pl",      "$plugdir/10psort.pl",       1, "", "", $perl);
InstallFile("prog_dir/plug/11subloc.pl",     "$plugdir/11subloc.pl",      1, "", "", $perl);

# Configured plugins (local)
InstallFile("prog_dir/plug/03psipred.pl",     "$plugdir/03psipred.pl",     1, $psipreddir, "", $perl) if($psipreddir ne "");
InstallFile("prog_dir/plug/06prositescan.pl", "$plugdir/06prositescan.pl", 1, $psscandir,  "", $perl) if($psscandir ne "");

# Documentation
InstallAllFiles("man", 0, $docdir, $perl);

#*************************************************************************
sub GetText
{
    my($prompt) = @_;
    my($text);

    print $prompt;
    $text = <>;
    chomp($text);
    return($text);
}

#*************************************************************************
sub GetYorN
{
    my($prompt) = @_;
    my($text);

    print $prompt;
    $text = <>;
    chomp($text);
    $text = "\U$text";
    return(1) if(($text eq "Y") || ($text eq ""));
    return(0);
}

#*************************************************************************
sub InstallFile
{
    my($in, $out, $exec, $patch1, $patch2, $perl) = @_;

    $patch1 = "" if($patch1 eq "BLANK");
    $patch2 = "" if($patch2 eq "BLANK");
    $in = `cat $in`;
    $in =~ s/\{PERL\}/$perl/g;
    $in =~ s/\{SUBS1\}/$patch1/g;
    $in =~ s/\{SUBS2\}/$patch2/g;
    open(OUT, ">$out") || die "Can't write $out";
    print OUT $in;
    close OUT;
    `chmod a+x $out` if($exec);
}


#*************************************************************************
sub GetDirectory
{
    my($prompt) = @_;
    my($dir);

    print $prompt;
    $dir = <>;
    chomp $dir;
    exit 0 if(!CheckDir($dir));

    return($dir);
}


#*************************************************************************
sub CheckDir
{
    my($dir) = @_;
    my($response);

    chomp($dir);
    chop($dir) if(substr($dir,length($dir)-1,1) eq "/");

    if(! -e $dir)
    {
        print "Directory '$dir' does not exist. Should I create it? (Y/N) [Y] ";
        $response = <>;
        $response = "\U$response";
        if($response =~ /^N/)
        {
            print "Create the directory by hand and re-run the install script\n";
            return(0);
        }
        `mkdir -p $dir`;
    }
    return($dir);
}

#*************************************************************************
sub InstallAllFiles
{
    my($indir, $exec, $outdir, $perl) = @_;
    my(@files, $file, $infile, $outfile);

    opendir(DIR, $indir) || die "Can't read directory $indir\n";
    @files = grep !/^\./, readdir(DIR);
    closedir(DIR);
    foreach $file (@files)
    {
        if($file =~ /.+\..+/)
        {
            $infile = $indir . "/" . $file;
            $outfile = $outdir . "/" . $file;
            InstallFile($infile, $outfile, $exec, "", "", $perl);
        }
    }
}

