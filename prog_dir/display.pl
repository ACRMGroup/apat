#!{PERL} -s
#*************************************************************************
#
#   Program:    APAT: display
#   File:       display.pl
#   
#   Version:    V1.1
#   Date:       15.06.05
#   Function:   APAT display program
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
#   V1.1  15.06.05 Now checks that a value-perseq was returned correctly
#                  and indicates if there is no prediction in the output
#
#*************************************************************************
use CGI ':standard';
use GD::Graph::lines;
use GD::Graph::bars;
use strict;
use XML::DOM;

HelpDie() if(defined($::h));

if(defined($::outdir))
{
    HelpDie() if(defined($::web));
}

$::htmltop = "";
$::htmltop = "{SUBS1}" if(defined($::web));
$::counter=0;
$::progname = 0;
$::progvers = 0;
$::function = 0;

my ($seqid, @seq, $rescount);
my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($ARGV[0]);
$rescount = 0;


PrintHTMLHeader();

foreach my $input ($doc->getElementsByTagName("input"))
{
    $seqid = $input->getElementsByTagName("seqid")->item(0);
    foreach my $seqtag ($input->getElementsByTagName("seq"))
    {
        push @seq, $seqtag->getFirstChild->getNodeValue;
        $rescount++;
    }
}


# Step through each result set
foreach my $results ($doc->getElementsByTagName("result"))
{
    print "<div class='results'>\n";
    HandleCommonData($results); 
   

    # Now extract the predictions - there should only be one of these
    # so we use ->item(0) rather than loop around each
    my $prediction = $results->getElementsByTagName("predictions")->item(0);

    
    HandlePerRes($prediction);

    HandlePerDom($prediction);

    HandlePerSeq($prediction);


    print "</div>\n";

    print "<p><br /><br /></p><hr /><p><br /><br /></p>\n";
}
print "</body>\n</html>\n"; 

# Avoid memory leaks - cleanup circular references for garbage collection
$doc->dispose;



#############################################################################
sub HandleCommonData
{
    my($results) = @_;

    # Grab and print the program name, version and function
    $::progname = $results->getAttribute('program');
    $::progvers = $results->getAttribute('version');
    my $fc = $results->getElementsByTagName("function")->item(0);
    $::function = $fc->getFirstChild->getNodeValue;

    # Print a title
    print "<h1>Analysis results from program: $::progname</h1>\n";

    if($::progvers eq "")
    {
        print "<h2>Running $::progname</h2>\n";
    }
    else
    {
        print "<h2>Running $::progname Version $::progvers</h2>\n";
    }
    
    print "<h3>Function : $::function</h3>\n";
}



##############################################################################
sub HandlePerRes
{
    my($prediction) = @_;

    my (@array_names, @values, @thrres, @clrmin, @clrmax, $arraycount, $resnum, $doPrintTable, $threshold, $thrdesctag, $thrdesc, $plotgraph, @dograph, @graphtype);
    my($filename) = "";
    $arraycount = 0;
    $doPrintTable = 0;
    $plotgraph = 0;             # ACRM
    
        
    # Get each number array from the predictions
    foreach my $numarray ($prediction->getElementsByTagName("perres-number"))
    {
        my $valuetype = $numarray->getAttribute('name');
        push @array_names, $valuetype;

        $doPrintTable = 1;

        # Blank our array
        for (my $i=0; $i<$rescount; $i++)
        {
            $values[$arraycount][$i] = '-';
        }

        # now stuff the residue numbers and values into a pair of arrays and print them
        foreach my $value ($numarray->getElementsByTagName("value-perres"))
        {
            $resnum = $value->getAttribute('residue');
            $values[$arraycount][$resnum-1] = $value->getFirstChild->getNodeValue;
	}

	# Get the minimun and maximum values for setting colour 
	my $clrmintag = $numarray->getAttribute('clrmin');
	$clrmin[$arraycount] = $clrmintag;
	my $clrmaxtag = $numarray->getAttribute('clrmax');
	$clrmax[$arraycount] = $clrmaxtag;
	
	if(my $graphtag = $numarray->getAttribute('graph'))
	{
            $plotgraph = 1;
            $dograph[$arraycount] = 1; # ACRM
	}
        else
        {
            $dograph[$arraycount] = 0; # ACRM
        }
        
        if(my $graphtypetag = $numarray->getAttribute('graphtype'))
        {
            $graphtype[$arraycount] = $graphtypetag;
        }
        else
        {
            $graphtype[$arraycount] = 0; 
        }    
        $arraycount++;
    }

    if($plotgraph)
    {
        $filename = Graph($::progname,$rescount, \@seq, \@array_names, \@dograph, \@graphtype, @values);
    }


    if($threshold = $prediction->getElementsByTagName("threshold")->item(0))
    {
	$thrdesctag = $threshold->getElementsByTagName("description")->item(0);
	$thrdesc = $thrdesctag->getFirstChild->getNodeValue;
	
	for(my $i=0; $i<$rescount; $i++)
	{
	    $thrres[$i] = 0;
	}
	foreach my $thrrestag ($threshold->getElementsByTagName("thr-res"))
	{ 
	    my $thrcheck =  $thrrestag->getFirstChild->getNodeValue;
	    $thrres[$thrcheck-1] = 1;
	}
    }
    
    # Get each character array from the predictions
    foreach my $chararray ($prediction->getElementsByTagName("perres-character"))
    {
        my $valuetype = $chararray->getAttribute('name');
        push @array_names, $valuetype;

        $doPrintTable = 1;
        
        # Blank our array
        for (my $i=0; $i<$rescount; $i++)
        {
            $values[$arraycount][$i] = '-';
        }

        # now stuff the residue numbers and values into a pair of arrays and print them
        foreach my $value ($chararray->getElementsByTagName("value-perres"))
        {
            $resnum = $value->getAttribute('residue');
            $values[$arraycount][$resnum-1] = $value->getFirstChild->getNodeValue;
	}

          
        $clrmin[$arraycount] = $clrmax[$arraycount] = 0;
        
        $arraycount++;
    }
  
    if($doPrintTable)
    {
	# pass values to PrintTable sub routine
        PrintTable($::progname, 15, 30, \@clrmin, \@clrmax, \@thrres, \@seq, \@array_names, @values);
    }

    if($thrdesc)
    {
	print "<h4>Threshold description : $thrdesc</h4>\n";
    }

        
    if($filename ne "")
    {
        print "<p><br /><br /></p><hr /><p><br /><br /></p>\n";
        print "<h3>Graphical Output :</h3> <img src='$filename' alt='annotation results graph'/>\n";
    }
    
}



##############################################################################
sub HandlePerDom
{
    my($prediction) = @_;
    my($gotPerdom) = 0;

    foreach my $perdom ($prediction->getElementsByTagName("perdom"))
    {
        if($gotPerdom == 0)
        {
            print "<table border='1'>\n";
            print "<tr><th>Residue range</th><th>Domain Name</th><th>Annotation types ............</th></tr>\n";
            $gotPerdom = 1;
        }

        my $class = $perdom->getAttribute('class');
        my $name  = $perdom->getAttribute('name');

        my $classname = "(undefined)";
        if($name ne "")
        {
            if($class ne "")
            {
                $classname = "$class : $name";
            }
            else
            {
                $classname = "$name";
            }
        }
        
        my $rangemin = $perdom->getAttribute('rangemin');
	my $rangemax = $perdom->getAttribute('rangemax');
        my $highlight = $perdom->getAttribute('highlight');
        if($highlight)
        {
            print "<tr class='highlight'><td>$rangemin - $rangemax</td><td>$classname</td>";
        }
        else
        {
            print "<tr><td>$rangemin - $rangemax</td><td>$classname</td>";
        }
        
        foreach my $value ($perdom->getElementsByTagName("value-perdom"))
        {
            my $label = $value->getAttribute('label');
            my $txt = $value->getFirstChild->getNodeValue;
            
            print "<td>$label : $txt</td>";
        }
        
        print "</tr>\n";
    }
    print "</table>\n"  if($gotPerdom);
    
    
    foreach my $perdom_desc ($prediction->getElementsByTagName("perdom-description"))
    {
        my $class = $perdom_desc->getAttribute('class');
        my $name  = $perdom_desc->getAttribute('name');
        my $classname = $name;
        $classname = "$class : $name" if($class ne "");

        print "<h4>$classname</h4>\n";
        my $txt = $perdom_desc->getFirstChild->getNodeValue;
        print "<p>\n$txt\n</p>\n";
    }
}




##############################################################################
sub HandlePerSeq
{
    my($prediction) = @_;

    my (@array_names, $arraycount, $doPrintValues, @valnames, @description, $desc, $val, @value, @valuehglt);
    $arraycount = 0;
    $doPrintValues = 0;
    

    foreach my $perseq ($prediction->getElementsByTagName("perseq"))
    {
        my $valuetype = $perseq->getAttribute('name');
    	push @valnames, $valuetype;
        
        $doPrintValues = 1;
        
        # SVVD 16.06.05
        # ACRM Corrected syntax 17.06.05
    	my $descriptiontag = $perseq->getElementsByTagName("description")->item(0);
        if($descriptiontag)
        {
            $desc = $descriptiontag->getFirstChild->getNodeValue;
            push @description, $desc;
        }     

        # SVVD 16.06.05
        # ACRM 17.06.05 - went back to old style for clarity
    	my $valuetag = $perseq->getElementsByTagName("value-perseq")->item(0);
        if($valuetag) # ACRM 15.06.05
        {
            my $valuehl = $valuetag->getAttribute('highlight');
            push @valuehglt, $valuehl;
            $val = $valuetag->getFirstChild->getNodeValue;
            push @value, $val;
        }
    }

    if($doPrintValues)
    {
    	PrintValues(\@valnames, \@description, \@valuehglt, \@value);
    }
}



##############################################################################
sub PrintTable
{
    my($progname, $resPerRow, $width, $clrmin_p, $clrmax_p, $thrres_p, $seq_p, $valname_p, @value_ptrs) = @_;
    my($seqlen, $nvalues, $i, $j, $start, @clrkey);
    $seqlen = @$seq_p;
    $nvalues = @$valname_p;
    
    for($start=0; $start<$seqlen; $start+=$resPerRow)
    {
	print "<p></p><table border='1'>\n";

        # PRINT THE RESIDUE NAMES
        print "<tr><td colspan='2'>Residue</td>";
        for($i=$start; $i<$start+$resPerRow && $i<$seqlen; $i++)
        {
	    # print threshold passed residues in Red
            if($$thrres_p[$i])
            {
		print "<td width='$width' bgcolor='red'>$$seq_p[$i]</td>";	
	    }
	    else
	    {
		print "<td width='$width'>$$seq_p[$i]</td>";
	    }
	}
        print "</tr>\n";
	
        # PRINT THE RESIDUE NUMBERS
	print "<tr><td colspan='2'>Number</td>";
	for($i=$start; $i<$start+$resPerRow && $i<$seqlen; $i++)
	{
	    # print threshold passed residue numbers in Red 
	    if($$thrres_p[$i])
	    {
		printf "<td width='$width' bgcolor='red'>%d</td>", $i+1;		
	    }
	    else
	    {
		printf "<td width='$width'>%d</td>", $i+1;		
	    }
	}
        print "</tr>\n";

        print "<tr><td rowspan='$nvalues'>$progname</td>";
        for($j=0; $j<$nvalues; $j++)
        {
            my ($array_p, $color);
            print "<tr>" if($j);
            print "<td>$$valname_p[$j]</td>";
            $array_p = $value_ptrs[$j];
            for($i=$start; $i<$start+$resPerRow && $i<$seqlen; $i++)
            {
                # pass values to SetColour Subroutine
		if($$array_p[$i] =~ /^[\d\.]+$/)           
		{
		    $color=SetColour($$array_p[$i], $$clrmin_p[$j], $$clrmax_p[$j]);
		    printf "<td width='$width' bgcolor='$color'>%0.5s</td>", $$array_p[$i];
		}
		else
		{
		    $color=SetColour($$array_p[$i], $$clrmin_p[$j], $$clrmax_p[$j]);
		    printf "<td width='$width' bgcolor='$color'>%s</td>", $$array_p[$i];
		}
	    }
            print "</tr>\n";
        }
        print "</table>\n";
    }
}



############################################################################################
sub PrintValues
{
    my($valnames_p, $description_p, $valuehglt_p, $value_p) = @_;
    my($i);
    
    for($i=0;$i<@$valnames_p;$i++)
    {
        #$$value_p[$i] =~ s/%_%/<font face="times" size="5"><em>/g;
        #$$value_p[$i] =~ s/%=%/<\/em><\/font>/g;  

        # ACRM 15.06.05 Check there is a prediction and indicate if not
        if($$valuehglt_p[$i]) 
        {
            printf "<p><b>%s</b> :<font face=\"times\" size=\"5\"><em>%s<\/em><\/font></p>\n", 
               $$valnames_p[$i], 
               (defined($$value_p[$i])?$$value_p[$i]:"No prediction");
        }
        else
        {
            printf "<p><b>%s</b> : %s</p>\n", 
               $$valnames_p[$i], 
               (defined($$value_p[$i])?$$value_p[$i]:"No prediction");
        }
	$$description_p[$i] =~ s/\n/<br \/>/g; 
	#$$description_p[$i] =~ s/%_%/<font face="times" size="5"><big>/g; 
        #$$description_p[$i] =~ s/%=%/<\/big><\/font>/g; 
        printf "<blockquote>%s</blockquote>\n",  $$description_p[$i];
    }
}



#######################################################################
# $colour = SetColour($value, $min, $max)
# Obtain a colour (coded in hex) such that a $value in the range $min
# to $max gives a colour ranging from blue through to red. Values outside
# the range give a colour of purple.
sub SetColour
{
    my($value, $min, $max) = @_;
    my($hue, $rising, $falling, $InvSat, $sixth, $saturation, $luminance);
    my($red, $green, $blue);

    return("\#FFFFFF") if($min == $max);
    return("\#FFFFFF") if(!($value =~ /\d/));

    $saturation = 1.0;
    $luminance  = 1.0;

    if(($value > $max) || ($value < $min))
    {
        $hue = 0.9;
    }
    else
    {
        $hue = ($value - $min) / ($max - $min);
        $hue *= 0.7;            # End at 0.7 rather than 1.0 so we don't cycle back
        $hue = 0.7 - $hue;      # Invert the scale so we start at blue rather than red
    }
  
    # Find which sixth of the hue spectrum we are in
    $sixth   = int(6.0 * $hue);
    
    $rising  = ($hue - ($sixth / 6.0)) * 6.0;
    $falling = 1.0 - $rising;

    $InvSat  = 1.0 - $saturation;

    if(($sixth == 0) || ($sixth == 6))
    {
        $red   = 1.0;
        $green = $rising;
        $blue  = 0.0;
    }
    elsif($sixth == 1)
    {
        $red   = $falling;
        $green = 1.0;
        $blue  = 0.0;
    }
    elsif($sixth == 2)
    {
        $red   = 0.0;
        $green = 1.0;
        $blue  = $rising;
    }
    elsif($sixth == 3)
    {
        $red   = 0.0;
        $green = $falling;
        $blue  = 1.0;
    }
    elsif($sixth == 4)
    {
        $red   = $rising;
        $green = 0.0;
        $blue  = 1.0;
    }
    elsif($sixth == 5)
    {
        $red   = 1.0;
        $green = 0.0;
        $blue  = $falling;
    }

    $red   *= $luminance;
    $green *= $luminance;
    $blue  *= $luminance;

    $red   += (($luminance-($red))   * $InvSat);
    $green += (($luminance-($green)) * $InvSat);
    $blue  += (($luminance-($blue))  * $InvSat);

    $red   *= 255;
    $green *= 255;
    $blue  *= 255;

    $red   = sprintf "%02lx", $red;
    $green = sprintf "%02lx", $green;
    $blue  = sprintf "%02lx", $blue;
    
    return("\#$red$green$blue");
}



##################################################################################
sub Graph
{
    my($progname,$seqlen, $seq_p, $valname_p, $dograph_p, $graphtype_p, @value_ptrs) = @_;
    my($pid) = $$;
    my($filename, @seq, @val, $s, $t, $vl, @val2, $array_p, @data, $i, $ylabel,
       @legend_keys, @graphtypename, $g, $gb, $gl, $ib, $il, $inserttype,$gtn,
       $mygraph,$tickvalue,$retname);    
    
    for($i=0; $i<@$seq_p; $i++)
    {
        push(@seq, $i+1);
    }
    push @data, [@seq];
    $ylabel = "";
 
    for($i=0; $i<@$dograph_p; $i++)
    {
        if($$dograph_p[$i])
        {
            push @data, $value_ptrs[$i];   
            $ylabel .= " / " if($ylabel ne "");
            $ylabel .= $$valname_p[$i];
            push @legend_keys, $$valname_p[$i];
        }
    }
        
    for($i=0; $i<@$graphtype_p; $i++)
    {
        if($$graphtype_p[$i])
        {
            push @graphtypename, $$graphtype_p[$i];
        }
    }


    if($seqlen<=200)
    {
        $tickvalue = 10,
    }
    elsif($seqlen<=400)
    {
        $tickvalue = 20,
    }
    else
    {
        $tickvalue = 30,
    }


    ($ib,$il) =0;
    foreach $g(@graphtypename)
    {
        if($g eq 'bars') 
        {
            $ib++;
        } 
        if($g eq 'lines')
        {
            $il++;
        } 
    }

    if($ib == @graphtypename)
    {
        $inserttype = 'bars';
    }
    elsif($il == @graphtypename)
    {
        $inserttype = 'lines';
    }
        

    if($inserttype eq 'bars')
    {   
        $mygraph = GD::Graph::bars->new(1500, 500);
    }
    else
    {
        $mygraph = GD::Graph::lines->new(1500, 500);
    }
    $mygraph->set(
                  x_label     => 'Residue Number',
                  y_label     => $ylabel,
                  title       => $progname,
                  
                  #bar_width   => 3,
                  #bar_spacing => 4,
                  
                  x_long_ticks  => 0,
                  y_long_ticks  => 1,
                  x_label_skip => $tickvalue,
                  line_width => 3,
                  #show_values => 1,
                  fgclr => 'cyan'
                  ) or warn $mygraph->error;

    #$mygraph->set_legend_font(GD::gdMediumBoldFont);
    $mygraph->set_legend_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_title_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_x_label_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_y_label_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_x_axis_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_y_axis_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
    $mygraph->set_values_font(['helvetica','arial',GD::gdMediumBoldFont], 12);
        
        
    $mygraph->set_legend(@legend_keys);
    my $myimage = $mygraph->plot(\@data) or die $mygraph->error;
        
    $::counter++;

    if(defined($::web))
    {
        $retname  = "/tmp/${pid}graph${main::counter}.gif";
        $filename = "$::htmltop/tmp/${pid}graph${main::counter}.gif";
    }
    elsif(defined($::outdir))
    {
        $retname  = "${pid}graph${main::counter}.gif";
        $filename = "$::outdir/${pid}graph${main::counter}.gif";
    }
    else
    {
        $retname = $filename = "${pid}graph${main::counter}.gif";
    }

    open(IMG, ">$filename") or die $!;
    binmode IMG;
    print IMG $myimage->gif;
    close IMG;
                
    return($retname);
}
    


##########################################################################
sub PrintHTMLHeader
{
    print <<__EOF;
<html>
<head>
    <title>Automated Protein Annotation Tool</title>
    <style type="text/css">
    <!--
    .header {font: bold 32pt Arial,Helvetica,sans-serif;
             text-align: center;
             color: orange;
             padding: 2px 0px 1em 0px;
            }
    .highlight {
                background: orange;
               }
    .results {
              background: #ffffff;
              border: thin solid black;
              color: #000000;
              margin: 20px;
              padding: 0px 0px 10px 0px;
             }
    h1 {font: 18pt Arial,Helvetica,sans-serif;
        text-align: left;
        color: white; 
        background: #336699;
        padding: 4px;
        margin: 0px;
       }
    h2 { padding: 2px 4px 4px 4px;
         margin: 0px;
       }
    h3 { padding: 2px 4px 4px 10px;
         margin: 0px;
       }
    h4 { padding: 2px 4px 4px 10px;
         margin: 0px;
       }
    p  { padding: 0px 4px 4px 24px;
         margin: 0px;
       }
    table { margin: 2px 10px 2px 10px;
       }
    -->
    </style>
</head>
<body bgcolor="white">
<p class="header">Automated Protein Annotation Tool</p>
__EOF
}


##########################################################################
sub HelpDie
{
    print STDERR <<__EOF;

display V1.0 (c) 2005, S.V.V.Deevi, University of Reading

Usage: ./display.pl [-web | -outdir=directory] apat.xml >apat.html

This program takes the XML output from the APAT system and converts
it into HTML for display.

If run normally, image files will be written to the current directory.

If run with -web, image files are written into $::htmltop/tmp/ such
that the HTML references them from /tmp

If run with -outdir, image files are written to the specified 
directory. They are still referenced as being in the current directory
from the HTML, so this is used when you are redirecting the HTML to
another directory.

__EOF
    exit 0;
}
