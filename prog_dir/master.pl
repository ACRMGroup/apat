#!{PERL} -s
#*************************************************************************
#
#   Program:    APAT: master
#   File:       master.pl
#   
#   Version:    V1.0
#   Date:       14.03.05
#   Function:   Runs each plug-in for APAT annotation
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

HelpDie() if(defined($::h));

my(@xmlin, $plugindir, @programs, $program, $xml, $xmlin);

$xmlin = shift (@ARGV);

# Get the plug-in directory
if(defined($::plugdir))
{
    $plugindir = $::plugdir;
}
else
{
    if(defined($ENV{PLUGINS}))
    {
        $plugindir = $ENV{PLUGINS};
    }
    else
    {
        $plugindir = "{SUBS2}";
    }
}

$ENV{'WEBPROXY'}="{SUBS1}";

# Get the list of available plugins
opendir(PLUGINS, "$plugindir") || die "Can't read directory $plugindir";
@programs = grep !/^\./, readdir PLUGINS;
closedir PLUGINS;

# Run each plugin and print the resulting XML
print "<results>\n";
foreach $program (sort @programs)
{
    $xml = `$plugindir/$program $xmlin`;
    print $xml;
}
print "</results>\n";

#*************************************************************************
# Print a help message
sub HelpDie
{
    print STDERR <<__EOF;

master.pl V1.0 (c) 2005, S.V.V.Deevi, University of Reading

Usage: ./master.pl -plugdir=dir in.xml >out.xml

Runs each APAT annotation wapper from a directory of plug-ins. This
directory can be specified with the environment variable 'PLUGINS'.
This can be overridden with the -plugdir run-type flag. If neither is
specified, then a sub-directory of the current directory called 'plug'
is assumed.

__EOF

    exit 0;
}
