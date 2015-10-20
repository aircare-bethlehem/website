#!/usr/bin/perl
##############################################################################
# Animation                     Version 1.2                                  #
# Copyright 1996 Matt Wright    mattw@worldwidemart.com                      #
# Created 9/28/95               Last Modified 11/21/95                       #
# Scripts Archive at:           http://www.worldwidemart.com/scripts/        #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# Animation may be used and modified free of charge by anyone so long as     #
# this copyright notice and the comments above remain intact.  By using this #
# code you agree to indemnify Matthew M. Wright from any liability that      #  
# might arise from it's use.                                                 #  
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.	In all cases copyright and header must remain intact #
##############################################################################
# Variables

$times = "1";
$basefile = "/home/web/g/garcia.packetpushers.com/htdocs/images/animation/";
@files = ("begin.gif","second.gif","third.gif","last.gif");
$con_type = "gif";

# Done
##############################################################################

# Unbuffer the output so it streams through faster and better

select (STDOUT);
$| = 1;

# Print out a HTTP/1.0 compatible header. Comment this line out if you 
# change the name to not have an nph in front of it.

print "HTTP/1.0 200 Okay\n";

# Start the multipart content

print "Content-Type: multipart/x-mixed-replace;boundary=myboundary\n\n";
print "--myboundary\n";

# For each file print the image out, and then loop back and print the next 
# image.  Do this for all images as many times as $times is defined as.

for ($num=1;$num<=$times;$num++) {
   foreach $file (@files) {
      print "Content-Type: image/$con_type\n\n";
      open(PIC,"$basefile$file");
      print <PIC>;
      close(PIC);
      print "\n--myboundary\n";
   }
}
