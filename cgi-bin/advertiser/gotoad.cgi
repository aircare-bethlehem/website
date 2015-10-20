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

$ads_dir = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/ads";

# DON'T EDIT BELOW THIS LINE!!
######################################################################

$displayad = $ENV{'QUERY_STRING'};

open (DISPLAY, "$ads_dir/$displayad.txt");
@lines = <DISPLAY>;
close (DISPLAY);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

$lines[2] += 1;

open (DISPLAY, ">$ads_dir/$displayad.txt");
foreach $line (@lines) {
	print DISPLAY ("$line\n");
}
close (DISPLAY);

print ("Location: $lines[4]\n\n");

exit;
