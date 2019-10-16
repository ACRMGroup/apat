#!{PERL} -s
#*************************************************************************
#
#   Program:    APAT: make-input-xml
#   File:       make-input-xml.pl
#   
#   Version:    V1.0
#   Date:       19.03.05
#   Function:   Create an XML input file for APAT from a FASTA file
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2005
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#               martin@biochem.ucl.ac.uk
#   Web:        http://www.bioinf.org.uk/
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
#   ./mix.pl -h
#   ./mix.pl -l
#   ./mix.pl [-d=file] -setdefaults email:andrew@bioinf.org.uk \
#            targetp:origin=non-plant psort:origin=animal%foo=bar
#   ./mix.pl [-d=file] [-f] [server:param=value[,param=value...]...] file.faa
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  14-19.03.05 Original
#
#*************************************************************************
use strict;
#*************************************************************************
# You will want to alter this to list all known servers with the options
# and values for all their parameters. Syntax is the server name as the
# hash key while the value is the option name= followed by a list of
# valid options separated with | symbols. A comma separates this from the
# next option and set of allowed values.
%::knownserver = ('psort' => 'origin=Gram-positive bacterium|Gram-negative bacterium|yeast|animal|plant',
                  'targetp' => 'origin=plant|non-plant');

#*************************************************************************
$::deffile = ((defined($::d))?($::d):("$ENV{'HOME'}/.apatrc"));
if(defined($::h))
{
    HelpDie();
}
elsif(defined($::setdefaults))
{
    SetDefaults();
    exit 0;
}
elsif(defined($::l))
{
    ListServersExit();
}
elsif($#ARGV == -1)
{
    Interactive();
}
else
{
    ReadDefaults();
    CommandLine();
}

CheckKnownServers() if(!defined($::f));
PrintXML();

#*************************************************************************
sub Interactive
{
    my($faa) = GetText("FASTA file: ");
    ($::sequence, $::seqid) = ReadFASTA($faa);

    $::email = GetText("EMail address: ");
    foreach my $server (keys %::knownserver)
    {
        print stderr "\nParameters for server: $server\n";
        my $kt = $::knownserver{$server};
        my (@knowntuples) = split(/\,/, $kt);
        my $tuplecount = 0;
        foreach my $tuple (@knowntuples)
        {
            my($option, $values) = split(/=/, $tuple);
            print stderr "Option: $option\n";
            print stderr "   Allowed values: ";
            my(@vals) = split(/\|/, $values);
            my($count) = 0;
            foreach my $val (@vals)
            {
                print stderr "                   " if($count++ > 0);
                print stderr "($count) $val\n";
            }
            my($opt) = GetText("Enter choice [1..$count]: ");
            if($tuplecount==0)
            {
                $::paramlist{$server} = "$option=$vals[$opt-1]";
            }
            else
            {
                $::paramlist{$server} .= ",$option=$vals[$opt-1]";
            }
            $tuplecount++;
        }
    }
}

#*************************************************************************
# Gets text from the keyboard
sub GetText
{
    my($prompt) = @_;
    my($text);
 
    print stderr $prompt;
    $text = <>;
    chomp($text);
    return($text);
}

#*************************************************************************
# Simply lists the known servers and their 
sub ListServersExit
{
    foreach my $server (keys %::knownserver)
    {
        print stderr "\nServer: $server\n";
        my $kt = $::knownserver{$server};
        my (@knowntuples) = split(/\,/, $kt);
        foreach my $tuple (@knowntuples)
        {
            my($option, $values) = split(/=/, $tuple);
            print stderr "Option: $option\n";
            print stderr "   Allowed values: ";
            my(@vals) = split(/\|/, $values);
            my($count) = 0;
            foreach my $val (@vals)
            {
                print "                   " if($count++ > 0);
                print "$val\n";
            }
        }
    }
    print "\n";
    exit 0;
}

#*************************************************************************
# This routine checks the parameters specified for known servers. It
# generates an error message for any illegal parameters and gives a
# warning about unknown servers
sub CheckKnownServers
{
    my($server, @knowntuples, @tuples, $tuple, $param, $knowntuple, $kval);
    my(@knownvalues, $knownparam, $knownvalue, $value, $ok);

    foreach $server (keys %::paramlist)
    {
        if(!defined($::knownserver{$server}))
        {
            print stderr "Warning: Server $server is unknown. Can't veryify parameters\n";
        }
        else
        {
            @knowntuples = split(/\,/,$::knownserver{$server});
            @tuples = split(/\,/,$::paramlist{$server});
            foreach $tuple (@tuples)
            {
                $ok = 0;
                ($param,$value) = split(/=/, $tuple);
                foreach $knowntuple (@knowntuples)
                {
                    ($knownparam,$kval) = split(/=/, $knowntuple);
                    if($param eq $knownparam)
                    {
                        (@knownvalues) = split(/\|/, $kval);
                        foreach $knownvalue (@knownvalues)
                        {
                            if($value eq $knownvalue)
                            {
                                $ok = 1;
                                last;
                            }
                        }
                    }
                }
                if(!$ok)
                {
                    print stderr "Illegal parameter/value for server $server: $param/$value\n";
                    exit 1;
                }
            }
        }
    }
}

#*************************************************************************
# this routine creates a ~/.apatrc file to contain the defaults you specify
# on the command line
sub SetDefaults
{
    my($arg, $server, $info, $param, $value, $ok);

    open(DEFFILE, ">$::deffile") || die "Can't write to $::deffile";
    $ok = 0;
    foreach $arg (@ARGV)
    {
        ($server,$info) = split(/:/, $arg);
        my(@knowntuples) = split(/\,/, $info);
        foreach my $tuple (@knowntuples)
        {
            if(($server ne "") && ($info ne ""))
            {
                if($server eq "email")
                {
                    $ok = 1;
                }
                else
                {
                    ($param, $value) = split(/=/, $info);
                    if(($param ne "") && ($value ne ""))
                    {
                        $ok = 1;
                    }
                    else
                    {
                        print STDERR "Syntax error in $arg\n";
                        exit 1;
                    }
                }
            }
            else
            {
                print STDERR "Syntax error in $arg\n";
                exit 1;
            }
        }
        print DEFFILE "$arg\n" if($ok);
    }
    close(DEFFILE);
}

#*************************************************************************
sub ReadDefaults
{
    my($arg, $server, $info, $param, $value);

    if(open(DEFFILE, "$::deffile"))
    {
        while(<DEFFILE>)
        {
            chomp;
#            $arg = "\L$_";
            ($server,$info) = split(/\:/, $_);
            if($server eq "email")
            {
                $::email = $info;
            }
            else
            {
                $::paramlist{$server} = $info;
            }
        }
        close(DEFFILE);
    }
}

#*************************************************************************
sub CommandLine
{
    my($arg, $server, $info, $param, $value);
    foreach $arg (@ARGV)
    {
        if($arg =~ /\S\S+:/)    # At least 2 non-spaces before the colon 
        {                       # (to cope with Windows filenames!)
            ($server,$info) = split(/:/, $arg);
            if($arg eq "")
            {
                ListServersExit();
            }
            else
            {
                if($server eq "email")
                {
                    $::email = $info;
                }
                else
                {
                    $::paramlist{$server} = $info;
                }
            }
        }
        else                    # this should be the fasta file
        {
            ($::sequence, $::seqid) = ReadFASTA($arg);
        }
    }
    if(!defined($::email))
    {
        print STDERR "You must provide an email address in the form email:me\@here.com\n";
        exit(1);
    }
}

#*************************************************************************
sub ReadFASTA
{
    my($file) = @_;
    my($id, $sequence);
    $id = "";
    open(FASTA, $file) || die "Can't read $file";
    while(<FASTA>)
    {
        chomp;
        if(/^>/)
        {
            last if($id ne "");
            $id = substr($_,1);
        }
        else
        {
            $sequence .= $_ if($id ne "");
        }
    }

    $sequence =~ s/\s//g;

    return($sequence, $id);
}

#*************************************************************************
sub PrintXML
{
    my($server, $param, $value);

    print <<__EOF;
<input>
   <sequenceid>$::seqid</sequenceid>
   <sequence>$::sequence</sequence>
   <emailaddress>$::email</emailaddress>
__EOF

   foreach $server (keys %::paramlist)
   {
       my @tuples = split(/\,/, $::paramlist{$server});
       foreach my $tuple (@tuples)
       {
           ($param, $value) = split(/=/, $tuple);
           print "   <parameter server='$server' param='$param' value='$value' />\n";
       }
   }

    print <<__EOF;
</input>
__EOF

}


#*************************************************************************
sub HelpDie
{
    print <<__EOF;

mix.pl V1.0 (c) 2005, Dr. Andrew C.R. Martin, UCL

Mix creates an input file for APAT from a FASTA file and associated 
required information.

Usage: 

./mix.pl -h
       Prints this help message.

./mix.pl -l
       Lists the known servers and their options and parameters.

./mix.pl -setdefaults [-d=file] email:email_address \
         [server:param=value[,param=value...]...] 
       Stores defaults to the file specified with -d or to ~/.apatrc
       if no file is specified. The file is over-written, so you must 
       specify defaults for all servers you want to use. If values contain
       spaces, each server: section must be contained in inverted commas.

./mix.pl [-f] [-d=file] [server:param=value[,param=value...]...] file.faa
       The normal mode of operation. Optionally allows you to override
       any defaults on the command line and reads a FASTA file generating
       an XML output file. Defaults may be read from a file specified
       with the -d option or from ~/.apatrc. For any servers mix knows about, 
       it checks that the options and values are valid. The -f flag overrides 
       this check. If values contain spaces, each server: section must be 
       contained in inverted commas.

./mix.pl
       The other normal mode of operation. No defaults are used, but 
       prompts for values for all servers/options which mix knows about.

__EOF
    exit 0;
}
