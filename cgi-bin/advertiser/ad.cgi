#!/usr/bin/perl

######################################################################
#  BEFORE TRYING TO EDIT THIS SCRIPT, READ THE README FILE
###################################################################### 
#
#     Dream Catchers CGI Scripts               Feel free to modify 
#     Advertiser                               this script to your 
#     Created by Seth Leonard                  needs, but please
#     for Dream Catchers Technologies, Inc.    keep this portion so
#                                              that I get credit.  
#     http://dreamcatchersweb.com/scripts      The same goes for 
#                                              distribution.
#
#     (c)1996/1997 Dream Catchers Technologies, Inc.,
#     All Rights Reserved
#
######################################################################
# ONLY EDIT THIS PART OF THE SCRIPT!!

$adcount = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/adcount.txt";
$ads_dir = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/ads";

$gotoad = "http://garcia.packetpushers.com/cgi-bin/advertiser/gotoad.cgi";

# DON'T EDIT BELOW THIS LINE!!
######################################################################

open (COUNT, "$adcount");
@lines = <COUNT>;
close (COUNT);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

$count = $lines[0];
$displayad = $lines[$count];

$count += 1;

if ($count > @lines - 1) {
	$count = 1;
}

$lines[0] = $count;

open (COUNT, ">$adcount");
foreach $line (@lines) {
	print COUNT ("$line\n");
}
close (COUNT);

open (DISPLAY, "$ads_dir/$displayad.txt");
@lines = <DISPLAY>;
close (DISPLAY);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

($maxshow, $shown, $visits, $image, $url, $wording, $size) = @lines;

print ("Content-type: text/html\n\n");

print ("<center><a href=\"$gotoad?$displayad\" target=\"_top\"><img 
src=\"$image\"></a><br>\n");
print ("<a href=\"$gotoad?$displayad\" target=\"_top\"><font size=$size>$wording");
print ("</font></a></center><br>\n");

$shown += 1;

open (DISPLAY, ">$ads_dir/$displayad.txt");
print DISPLAY ("$maxshow\n");
print DISPLAY ("$shown\n");
print DISPLAY ("$visits\n");
print DISPLAY ("$image\n");
print DISPLAY ("$url\n");
print DISPLAY ("$wording\n");
print DISPLAY ("$size");
close (DISPLAY);

exit;
